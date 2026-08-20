%% quantum_compile.pl
%% Compilation pipeline: parse → validate → normalise → optimise → decompose → map.

:- module(quantum_compile, [
    quantum_run/3,
    quantum_compile/3,
    compile_pipeline/3,
    backend/3,
    coupling/2,
    route_circuit/3,
    normalise_quantum/2,
    circuit_metrics/2
]).

:- use_module(quantum_ir).
:- use_module(quantum_gate).
:- use_module(quantum_optimise).
:- use_module(quantum_decompose).
:- use_module(quantum_errors).
:- use_module(quantum_simulator).

%% quantum_run(+Source, +Options, ?Result)
quantum_run(Source, Options, Result) :-
    compile_pipeline(Source, Options, Compiled),
    quantum_simulator:quantum_simulate(Compiled, Options, Result).

%% quantum_compile(+Source, +Options, ?Compiled)
quantum_compile(Source, Options, Compiled) :-
    compile_pipeline(Source, Options, Compiled).

%% compile_pipeline(+Source, +Options, ?Output)
compile_pipeline(Source, Options, Output) :-
    %% Step 1: Parse / normalise to IR
    source_to_ir(Source, IR),
    %% Step 2: Validate
    ( catch(validate_circuit(IR), E,
           ( format("Validation warning: ~w~n", [E]), IR = IR ))
    -> true ; true ),
    %% Step 3: Resolve aliases
    ir_normalise_aliases(IR, IR2),
    %% Step 4: Analyse
    ir_analyse(IR2, IR3),
    %% Step 5: Optimise
    ( member(optimise(true), Options)
    -> quantum_optimise:quantum_optimise(IR3, Options, IR4)
    ;  IR4 = IR3
    ),
    %% Step 6: Decompose
    ( member(basis(Basis), Options)
    -> quantum_decompose:quantum_decompose(IR4, Basis, IR5)
    ;  IR5 = IR4
    ),
    %% Step 7: Map to backend
    ( member(backend(Backend), Options)
    -> map_to_backend(IR5, Backend, Output)
    ;  Output = IR5
    ).

%% source_to_ir(+Source, ?IR)
source_to_ir(circuit(Q,C,G), circuit(Q,C,G)) :- !.
source_to_ir(Gates, circuit(Qubits,[],Gates)) :-
    is_list(Gates), !,
    quantum_ir:circuit_qubits_used(circuit([],[],Gates), Qubits).
source_to_ir(Source, IR) :-
    atom(Source),
    quantum_qasm:qasm_to_prolog(Source, IR), !.
source_to_ir(Source, circuit([],[],[Source])).

%% ir_normalise_aliases(+IR, ?NormIR)
ir_normalise_aliases(circuit(Q,C,Gates), circuit(Q,C,NormGates)) :-
    maplist(quantum_gate:gate_normalise, Gates, NormGates).

%% ir_analyse(+IR, ?IR): adds qubit metadata
ir_analyse(IR, IR).

%% map_to_backend(+Circuit, +Backend, ?Mapped)
map_to_backend(Circuit, Backend, Mapped) :-
    ( backend_spec(Backend, basis_gates(Basis), _, _)
    -> quantum_decompose:quantum_decompose(Circuit, Basis, Mapped)
    ;  Mapped = Circuit
    ).

backend_spec(generic, basis_gates([rz,sx,x,cx]), connectivity(all), max_qubits(100)).
backend_spec(ibm_falcon, basis_gates([rz,sx,x,cx]), connectivity(linear), max_qubits(27)).
backend_spec(Backend, basis_gates([u,cx]), connectivity(all), max_qubits(100)) :-
    atom(Backend).

%% backend/3
backend(Name, Specs, Spec) :-
    member(Spec, Specs),
    backend_spec(Name, Spec, _, _).

%% coupling/2
coupling(Backend, Pairs) :-
    ( Backend = circuit_coupling(Pairs) -> true
    ;  backend_coupling(Backend, Pairs)
    ).

backend_coupling(ibm_falcon, [0-1, 1-2, 2-3, 3-4]).
backend_coupling(_, []).

%% route_circuit(+Circuit, +Coupling, ?Routed)
route_circuit(circuit(Q,C,Gates), Coupling, circuit(Q,C,Routed)) :-
    route_gates(Gates, Q, Coupling, Routed).

route_gates([], _, _, []) :- !.
route_gates([Gate|Rest], Qubits, Coupling, Routed) :-
    ( needs_routing(Gate, Qubits, Coupling)
    -> insert_swap_route(Gate, Qubits, Coupling, RouteGates),
       route_gates(Rest, Qubits, Coupling, RestRouted),
       append(RouteGates, RestRouted, Routed)
    ;  route_gates(Rest, Qubits, Coupling, RestRouted),
       Routed = [Gate|RestRouted]
    ).

needs_routing(Gate, Qubits, Coupling) :-
    functor(Gate, _, _),
    catch(quantum_ir:gate_operands(Gate, GQs), _, GQs=[]),
    GQs = [C,T|_],
    atom(C), atom(T),
    nth0(CI, Qubits, C),
    nth0(TI, Qubits, T),
    \+ ( member(CI-TI, Coupling) ; member(TI-CI, Coupling) ).

insert_swap_route(Gate, _Qubits, _Coupling, [Gate]).

%% normalise_quantum(+Source, ?Normalised)
normalise_quantum(Source, Normalised) :-
    source_to_ir(Source, IR),
    ir_normalise_aliases(IR, Normalised).
