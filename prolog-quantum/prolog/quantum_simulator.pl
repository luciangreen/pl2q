%% quantum_simulator.pl
%% Statevector simulation for quantum circuits.

:- module(quantum_simulator, [
    statevector/2,
    statevector/3,
    quantum_simulate/3,
    probabilities/2,
    sample/3,
    apply_circuit/3,
    apply_gate_to_statevector/4,
    circuit_unitary/2
]).

:- use_module(quantum_complex).
:- use_module(quantum_matrix).
:- use_module(quantum_tensor).
:- use_module(quantum_state).
:- use_module(quantum_gate).
:- use_module(quantum_gate_registry).
:- use_module(quantum_errors).

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
    maplist([V,R]>>(quantum_complex:complex_mul(E,V,R)), S, S2).
apply_gate_to_statevector(Gate, Qubits, S, S2) :-
    gate_qubit_indices(Gate, Qubits, Indices),
    length(Qubits, N),
    ( gate_single_qubit_matrix(Gate, GateM)
    -> apply_single_qubit_gate(GateM, Indices, N, S, S2)
    ;  gate_two_qubit_matrix(Gate, GateM)
    -> apply_two_qubit_gate(GateM, Indices, N, S, S2)
    ;  apply_general_gate(Gate, Qubits, Indices, N, S, S2)
    ).

gate_qubit_indices(Gate, Qubits, Indices) :-
    quantum_ir:gate_operands(Gate, GateQs),
    maplist([Q, I]>>(nth0(I, Qubits, Q)), GateQs, Indices).

gate_single_qubit_matrix(Gate, M) :-
    Gate =.. [Name|Args],
    length(Args, 1),   % one qubit argument
    ( member(Name, [i,id,x,y,z,h,s,sdg,t,tdg,sx,sxdg]) ->
        quantum_gate_registry:gate_matrix(Name, M)
    ; member(Name, [rx,ry,rz,p,phase]) ->
        Args = [Param,_],
        quantum_gate_registry:gate_matrix(..(Name,[Param]), M)
    ; Name = u ->
        Args = [Th,Ph,La,_],
        quantum_gate_registry:gate_matrix(u(Th,Ph,La), M)
    ; fail
    ).

gate_two_qubit_matrix(Gate, M) :-
    Gate =.. [Name|_],
    member(Name, [cx,cnot,cy,cz,ch,swap,cs,csdg,ct,ctdg,iswap,iswap_dg,dcx]),
    quantum_gate_registry:gate_matrix(Name, M).

%% apply_single_qubit_gate(+GateM, +[QubitIdx], +N, +S, ?S2)
apply_single_qubit_gate(GateM, [QIdx], N, S, S2) :-
    length(S, Dim),
    Dim =:= 2^N,
    %% Build full N-qubit operator: I^{QIdx} ⊗ GateM ⊗ I^{N-QIdx-1}
    build_single_qubit_operator(GateM, QIdx, N, BigM),
    quantum_matrix:matrix_apply(BigM, S, S2).

build_single_qubit_operator(GateM, QIdx, N, BigM) :-
    matrix_identity_2x2(I2),
    Before is QIdx,
    After is N - QIdx - 1,
    build_identity(Before, IBefore),
    build_identity(After, IAfter),
    tensor_sequence([IBefore, GateM, IAfter], BigM).

matrix_identity_2x2([[c(1,0),c(0,0)],[c(0,0),c(1,0)]]).

build_identity(0, nil) :- !.
build_identity(N, M) :-
    N > 0,
    Dim is 2^N,
    quantum_matrix:matrix_identity(Dim, M).

tensor_sequence([nil], nil) :- !.
tensor_sequence([nil, M], M) :- !.
tensor_sequence([M, nil], M) :- !.
tensor_sequence([M], M) :- !.
tensor_sequence([M1, M2|Rest], Result) :-
    ( M1 = nil -> M12 = M2
    ; M2 = nil -> M12 = M1
    ;  quantum_matrix:matrix_tensor(M1, M2, M12)
    ),
    tensor_sequence([M12|Rest], Result).

%% apply_two_qubit_gate(+GateM, +[C,T], +N, +S, ?S2)
apply_two_qubit_gate(GateM, [C, T], N, S, S2) :-
    build_two_qubit_operator(GateM, C, T, N, BigM),
    quantum_matrix:matrix_apply(BigM, S, S2).

build_two_qubit_operator(GateM, C, T, N, BigM) :-
    %% Simple case: adjacent qubits in natural order
    ( T =:= C + 1
    -> Before is C,
       After is N - C - 2,
       build_identity(Before, IBefore),
       build_identity(After, IAfter),
       tensor_sequence([IBefore, GateM, IAfter], BigM)
    ;  %% General case: build via permutation
       build_permuted_operator(GateM, C, T, N, BigM)
    ).

build_permuted_operator(GateM, C, T, N, BigM) :-
    %% Fall back to explicit expansion
    Dim is 2^N,
    quantum_matrix:matrix_zero(Dim, Dim, Zero),
    numlist(0, Dim-1, BasisIdxs),
    foldl([I, Acc, NAcc]>>(
        expand_two_qubit_action(GateM, C, T, N, I, Col),
        set_matrix_col(Acc, I, Col, NAcc)
    ), BasisIdxs, Zero, BigM).

expand_two_qubit_action(GateM, C, T, N, ColIdx, Col) :-
    Dim is 2^N,
    length(Col, Dim),
    maplist(=(c(0,0)), Col),
    numlist(0, Dim-1, RowIdxs),
    maplist([RI, Entry]>>(
        compute_matrix_entry(GateM, C, T, N, RI, ColIdx, Entry)
    ), RowIdxs, Col).

compute_matrix_entry(GateM, C, T, N, RI, CI, Entry) :-
    extract_two_qubit_bits(CI, C, T, N, CB, TB),
    extract_two_qubit_bits(RI, C, T, N, RB, RTB),
    TwoCI is CB * 2 + TB,
    TwoRI is RB * 2 + RTB,
    quantum_matrix:matrix_get(GateM, TwoRI, TwoCI, GEntry),
    rest_bits_match(RI, CI, C, T, N),
    Entry = GEntry.
compute_matrix_entry(_, _, _, _, _, _, c(0,0)).

extract_two_qubit_bits(Idx, C, T, N, CB, TB) :-
    CB is (Idx >> (N-C-1)) /\ 1,
    TB is (Idx >> (N-T-1)) /\ 1.

rest_bits_match(RI, CI, C, T, N) :-
    RMask is RI /\ (\( (1 << (N-C-1)) \/ (1 << (N-T-1)) )),
    CMask is CI /\ (\( (1 << (N-C-1)) \/ (1 << (N-T-1)) )),
    RMask =:= CMask.

set_matrix_col(M, _ColIdx, _Col, M).  %% Simplified - returns M unchanged for now

%% apply_general_gate: fallback
apply_general_gate(_, _, _, _, S, S).

%% apply_reset: collapse qubit to |0>
apply_reset(Idx, N, S, S2) :-
    length(S, Dim),
    numlist(0, Dim-1, Idxs),
    maplist([I, V, NV]>>(
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
    numlist(0, Dim-1, Idxs),
    maplist([I, Label-Prob]>>(
        quantum_complex:complex_abs_sq(State+I, Prob),  %% FIXME: proper indexing
        format(atom(Label), "~`0t~*|", [Dim]),  %% binary label
        nth0(I, State, Amp),
        quantum_complex:complex_abs_sq(Amp, Prob),
        bits_to_label(I, Dim, Label)
    ), Idxs, Distribution).

bits_to_label(I, Dim, Label) :-
    N is round(log(Dim) / log(2)),
    format(atom(Label), "~`0t~*|~d", [N, I]).  % not quite right but placeholder

%% sample(+Circuit, +Shots, ?Counts)
sample(Circuit, Shots, counts(Counts)) :-
    statevector(Circuit, State),
    length(State, Dim),
    numlist(0, Dim-1, Idxs),
    maplist([I, I-P]>>(
        nth0(I, State, Amp),
        quantum_complex:complex_abs_sq(Amp, P)
    ), Idxs, Probs),
    draw_samples(Probs, Shots, Counts).

draw_samples(Probs, Shots, Counts) :-
    maplist([I-P, I-N]>>(N is round(P * Shots)), Probs, Counts).

%% circuit_unitary(+Circuit, ?U)
circuit_unitary(circuit(Qubits,_,Gates), U) :-
    length(Qubits, N),
    Dim is 2^N,
    quantum_matrix:matrix_identity(Dim, I),
    foldl([Gate, Acc, NAcc]>>(
        ( gate_single_qubit_matrix(Gate, GM)
        -> gate_qubit_indices(Gate, Qubits, Idxs),
           build_single_qubit_operator(GM, Idxs, N, BigM),
           quantum_matrix:matrix_mul(BigM, Acc, NAcc)
        ;  NAcc = Acc  % simplified
        )
    ), Gates, I, U).
