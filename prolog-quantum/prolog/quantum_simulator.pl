%% quantum_simulator.pl
%% Statevector simulation for quantum circuits.

:- module(quantum_simulator, [
    statevector/2,
    statevector/3,
    quantum_simulate/3,
    probabilities/2,
    sample/3,
    apply_circuit/4,
    apply_gate_to_statevector/4,
    circuit_unitary/2
]).

:- use_module(quantum_complex).
:- use_module(quantum_matrix).
:- use_module(quantum_tensor).
:- use_module(quantum_state).
:- use_module(quantum_gate_registry).
:- use_module(quantum_errors).
:- use_module(quantum_ir, []).
:- use_module(library(apply)).
:- use_module(library(lists)).
:- use_module(library(random)).
:- use_module(library(yall)).

%% statevector(+Circuit, ?State)
statevector(circuit(Qubits,_,Gates), State) :-
    length(Qubits, N),
    N > 0,
    Dim is 2^N,
    ( Dim > 1024
    -> quantum_warning(performance, simulation, N,
                      "Statevector simulation exceeds 1024 dimensions")
    ;  true
    ),
    quantum_state:zero_state(N, Init),
    apply_circuit(Gates, Qubits, Init, State).
statevector(Gates, State) :-
    is_list(Gates),
    collect_qubits(Gates, Qubits),
    length(Qubits, N),
    N > 0,
    quantum_state:zero_state(N, Init),
    apply_circuit(Gates, Qubits, Init, State).

statevector(Circuit, Options, State) :-
    ( member(initial_state(Init), Options)
    -> true
    ;  circuit_qubits_opt(Circuit, Qubits),
       length(Qubits, N),
       quantum_state:zero_state(N, Init)
    ),
    ( member(precision(_), Options) -> true ; true ),
    circuit_gates_opt(Circuit, Gates),
    circuit_qubits_opt(Circuit, Qs),
    apply_circuit(Gates, Qs, Init, State).

circuit_qubits_opt(circuit(Q,_,_), Q) :- !.
circuit_qubits_opt(_, []).

circuit_gates_opt(circuit(_,_,G), G) :- !.
circuit_gates_opt(G, G) :- is_list(G).

%% apply_circuit(+Gates, +Qubits, +StateIn, ?StateOut)
apply_circuit([], _, S, S).
apply_circuit([Gate|Rest], Qubits, S0, Sf) :-
    apply_gate_to_statevector(Gate, Qubits, S0, S1),
    apply_circuit(Rest, Qubits, S1, Sf).

%% apply_gate_to_statevector(+Gate, +Qubits, +S, ?S2)
apply_gate_to_statevector(measure(_,_), _, S, S) :- !.
apply_gate_to_statevector(reset(Q), Qubits, S, S2) :-
    !,
    nth0(Idx, Qubits, Q),
    length(Qubits, N),
    apply_reset(Idx, N, S, S2).
apply_gate_to_statevector(barrier(_), _, S, S) :- !.
apply_gate_to_statevector(delay(_,_), _, S, S) :- !.
apply_gate_to_statevector(if_bit(C,Val,SubGate), Qubits, S, S2) :-
    !,
    % For simulation: apply SubGate (classical condition not evaluated in pure simulation)
    apply_gate_to_statevector(SubGate, Qubits, S, S2).
apply_gate_to_statevector(global_phase(Phi), _, S, S2) :-
    !,
    quantum_complex:complex_exp(c(0,Phi), E),
    maplist({E}/[V,R]>>(quantum_complex:complex_mul(E,V,R)), S, S2).
apply_gate_to_statevector(Gate, Qubits, S, S2) :-
    gate_operator(Gate, GateQs, GateM),
    maplist(qubit_index(Qubits), GateQs, Indices),
    length(Qubits, N),
    apply_local_operator(GateM, Indices, N, S, S2).

qubit_index(Qubits, Qubit, Index) :-
    nth0(Index, Qubits, Qubit).

gate_operator(unitary(Matrix, Qubits), Qubits, ComplexMatrix) :-
    ground(Matrix),
    !,
    length(Qubits, N),
    Dim is 2^N,
    ( normalise_complex_matrix(Matrix, ComplexMatrix),
      quantum_matrix:matrix_dims(ComplexMatrix, Dim, Dim),
      quantum_matrix:matrix_is_unitary(ComplexMatrix, 1.0e-9)
    -> true
    ;  throw(error(domain_error(unitary_matrix, Matrix), _))
    ).
gate_operator(Gate, [Qubit], Matrix) :-
    Gate =.. [Name, Qubit],
    memberchk(Name, [i,id,x,y,z,h,s,sdg,t,tdg,sx,sxdg,sqrt_x,sqrt_x_dg]),
    !,
    normalise_matrix_gate(Name, Matrix).
gate_operator(Gate, [Qubit], Matrix) :-
    Gate =.. [Name, Parameter, Qubit],
    memberchk(Name, [rx,ry,rz,p,phase]),
    !,
    normalise_matrix_gate(Name, Parameter, Matrix).
gate_operator(u(Theta, Phi, Lambda, Qubit), [Qubit], Matrix) :-
    !,
    quantum_gate_registry:gate_matrix(u(Theta, Phi, Lambda), Matrix).
gate_operator(Gate, Qubits, Matrix) :-
    quantum_ir:gate_operands(Gate, Qubits),
    Gate =.. [Name|_],
    ( memberchk(Name, [cnot,toffoli,fredkin,cphase])
    -> quantum_ir:normalise_gate(Gate, Normalised),
       gate_operator(Normalised, Qubits, Matrix)
    ;  quantum_gate_registry:gate_matrix(Name, Matrix)
    ),
    !.
gate_operator(Gate, _, _) :-
    quantum_errors:unsupported(simulation, Gate).

normalise_matrix_gate(sqrt_x, Matrix) :-
    quantum_gate_registry:gate_matrix(sx, Matrix).
normalise_matrix_gate(sqrt_x_dg, Matrix) :-
    quantum_gate_registry:gate_matrix(sxdg, Matrix).
normalise_matrix_gate(Name, Matrix) :-
    quantum_gate_registry:gate_matrix(Name, Matrix).
normalise_matrix_gate(phase, Parameter, Matrix) :-
    quantum_gate_registry:gate_matrix(p(Parameter), Matrix).
normalise_matrix_gate(Name, Parameter, Matrix) :-
    Gate =.. [Name, Parameter],
    quantum_gate_registry:gate_matrix(Gate, Matrix).

normalise_complex_matrix(Matrix, ComplexMatrix) :-
    is_list(Matrix),
    Matrix \= [],
    maplist(normalise_complex_row, Matrix, ComplexMatrix).

normalise_complex_row(Row, ComplexRow) :-
    is_list(Row),
    maplist(normalise_complex_entry, Row, ComplexRow).

normalise_complex_entry(c(Real, Imaginary), c(Real, Imaginary)) :-
    number(Real),
    number(Imaginary).
normalise_complex_entry(Real, c(Real, 0)) :-
    number(Real).

gate_qubit_indices(Gate, Qubits, Indices) :-
    quantum_ir:gate_operands(Gate, GateQubits),
    maplist(qubit_index(Qubits), GateQubits, Indices).

%% Apply a local operator while retaining the qubit order in its operand list.
apply_local_operator(GateM, Indices, N, S, S2) :-
    length(Indices, GateQubits),
    GateDim is 2^GateQubits,
    quantum_matrix:matrix_dims(GateM, GateDim, GateDim),
    length(S, Dim),
    Dim =:= 2^N,
    sort(Indices, UniqueIndices),
    length(UniqueIndices, GateQubits),
    Last is Dim - 1,
    numlist(0, Last, OutputIndices),
    maplist(local_output_amplitude(GateM, Indices, N, S, GateDim),
           OutputIndices, S2).

local_output_amplitude(Matrix, Indices, N, State, GateDim, OutputIndex, Amplitude) :-
    local_basis_index(OutputIndex, Indices, N, LocalOutput),
    LastLocal is GateDim - 1,
    numlist(0, LastLocal, LocalInputs),
    maplist(local_input_product(Matrix, Indices, N, State, OutputIndex,
                               LocalOutput),
           LocalInputs, Products),
    foldl([Product, Acc, Sum]>>(
       quantum_complex:complex_add(Product, Acc, Sum)
    ), Products, c(0,0), Amplitude).

local_input_product(Matrix, Indices, N, State, OutputIndex, LocalOutput,
                   LocalInput, Product) :-
    replace_local_bits(OutputIndex, LocalInput, Indices, N, InputIndex),
    quantum_matrix:matrix_get(Matrix, LocalOutput, LocalInput, Entry),
    nth0(InputIndex, State, InputAmplitude),
    quantum_complex:complex_mul(Entry, InputAmplitude, Product).

local_basis_index(GlobalIndex, Indices, N, LocalIndex) :-
    local_basis_bits(GlobalIndex, Indices, N, 0, LocalIndex).

local_basis_bits(_, [], _, Index, Index).
local_basis_bits(GlobalIndex, [QubitIndex|Rest], N, Acc, LocalIndex) :-
    Shift is N - QubitIndex - 1,
    Bit is (GlobalIndex >> Shift) /\ 1,
    Next is (Acc << 1) \/ Bit,
    local_basis_bits(GlobalIndex, Rest, N, Next, LocalIndex).

replace_local_bits(Index, _, [], _, Index).
replace_local_bits(Index, LocalIndex, [QubitIndex|Rest], N, Result) :-
    length(Rest, RestLength),
    LocalShift is RestLength,
    Shift is N - QubitIndex - 1,
    Bit is (LocalIndex >> LocalShift) /\ 1,
    Mask is 1 << Shift,
    Cleared is Index /\ (\ Mask),
    Updated is Cleared \/ (Bit << Shift),
    replace_local_bits(Updated, LocalIndex, Rest, N, Result).

%% apply_reset: collapse qubit to |0>
apply_reset(Idx, N, S, S2) :-
    length(S, Dim),
    Last is Dim - 1,
    numlist(0, Last, Idxs),
    maplist({N,Idx}/[I, V, NV]>>(
        ( I >> (N - Idx - 1) /\ 1 =:= 0
        -> NV = V
        ;  NV = c(0,0)
        )
    ), Idxs, S, S2Pre),
    quantum_state:state_normalise(S2Pre, S2).

%% collect_qubits from a gate list
collect_qubits(Gates, Qubits) :-
    maplist([G, Qs]>>(quantum_ir:gate_operands(G, Qs)), Gates, QLists),
    flatten(QLists, AllQ),
    include(atom, AllQ, AtomQ),
    list_to_set(AtomQ, Qubits).

%% quantum_simulate(+Circuit, +Options, ?Result)
quantum_simulate(Circuit, Options, Result) :-
    ( member(shots(N), Options)
    -> sample(Circuit, N, Result)
    ;  statevector(Circuit, Options, State),
       Result = statevector(State)
    ).

%% probabilities(+Circuit, ?Distribution)
probabilities(Circuit, Distribution) :-
    statevector(Circuit, State),
    length(State, Dim),
    state_qubit_count(Dim, N),
    Last is Dim - 1,
    numlist(0, Last, Idxs),
    maplist({State,N}/[I, Label-Prob]>>(
        nth0(I, State, Amp),
        quantum_complex:complex_abs_sq(Amp, Prob),
        bits_to_label(I, N, Label)
    ), Idxs, Distribution).

state_qubit_count(Dim, N) :-
    Dim > 0,
    state_qubit_count(Dim, 1, 0, N).

state_qubit_count(Dim, Power, N0, N) :-
    ( Power =:= Dim
    -> N = N0
    ;  Power < Dim,
       NextPower is Power * 2,
       NextN is N0 + 1,
       state_qubit_count(Dim, NextPower, NextN, N)
    ).

bits_to_label(Index, N, Label) :-
    Last is N - 1,
    numlist(0, Last, Positions),
    maplist({Index,N}/[Position, Char]>>(
        Shift is N - Position - 1,
        Bit is (Index >> Shift) /\ 1,
        ( Bit =:= 0 -> Char = '0' ; Char = '1' )
    ), Positions, Chars),
    atom_chars(Label, Chars).

%% sample(+Circuit, +Shots, ?Counts)
sample(Circuit, Shots, counts(Counts)) :-
    integer(Shots),
    Shots > 0,
    statevector(Circuit, State),
    length(State, Dim),
    state_qubit_count(Dim, N),
    Last is Dim - 1,
    numlist(0, Last, Idxs),
    maplist({State}/[I, I-P]>>(
        nth0(I, State, Amp),
        quantum_complex:complex_abs_sq(Amp, P)
    ), Idxs, Probs),
    length(CountsByIndex, Dim),
    maplist(=(0), CountsByIndex),
    draw_samples(Probs, Shots, CountsByIndex, SampledCounts),
    maplist({N}/[I, Count, Label-Count]>>bits_to_label(I, N, Label),
            Idxs, SampledCounts, Counts).

draw_samples(_, 0, Counts, Counts) :- !.
draw_samples(Probs, Shots, Counts0, Counts) :-
    random_weighted_index(Probs, Index),
    nth0(Index, Counts0, OldCount),
    NewCount is OldCount + 1,
    replace_nth0(Index, Counts0, NewCount, Counts1),
    Remaining is Shots - 1,
    draw_samples(Probs, Remaining, Counts1, Counts).

random_weighted_index(Probs, Index) :-
    maplist([_-P, P]>>true, Probs, Weights),
    sum_list(Weights, Total),
    Total > 0,
    random(Random),
    Threshold is Random * Total,
    select_weighted_index(Probs, Threshold, 0.0, Index).

select_weighted_index([Index-Probability|_], Threshold, Acc, Index) :-
    Threshold < Acc + Probability,
    !.
select_weighted_index([_-Probability|Rest], Threshold, Acc, Index) :-
    Rest \= [],
    NextAcc is Acc + Probability,
    select_weighted_index(Rest, Threshold, NextAcc, Index).
select_weighted_index([Index-_|[]], _, _, Index).

replace_nth0(0, [_|Rest], Value, [Value|Rest]) :- !.
replace_nth0(Index, [Head|Rest], Value, [Head|Updated]) :-
    Index > 0,
    Next is Index - 1,
    replace_nth0(Next, Rest, Value, Updated).

%% circuit_unitary(+Circuit, ?U)
circuit_unitary(circuit(Qubits,_,Gates), U) :-
    length(Qubits, N),
    Dim is 2^N,
    ( member(Gate, Gates), memberchk(Gate, [measure(_,_), reset(_)])
    -> quantum_errors:unsupported(unitary_of_nonunitary_circuit, Gate)
    ;  true
    ),
    Last is Dim - 1,
    numlist(0, Last, BasisIndices),
    maplist(circuit_unitary_column(Gates, Qubits, Dim), BasisIndices, Columns),
    quantum_matrix:matrix_transpose(Columns, U).

circuit_unitary_column(Gates, Qubits, Dim, BasisIndex, Column) :-
    Last is Dim - 1,
    numlist(0, Last, Indices),
    maplist({BasisIndex}/[Index, Amplitude]>>(
        ( Index =:= BasisIndex -> Amplitude = c(1,0) ; Amplitude = c(0,0) )
    ), Indices, BasisState),
    apply_circuit(Gates, Qubits, BasisState, Column).
