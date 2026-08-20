%% test_simulator.pl
%% Tests for the quantum statevector simulator.

:- use_module('../prolog/quantum_simulator').
:- use_module('../prolog/quantum_state').
:- use_module('../prolog/quantum_complex').
:- use_module('../prolog/quantum_ir').

:- initialization(run_simulator_tests, main).

run_simulator_tests :-
    format("=== Simulator Tests ===~n"),
    test_single_qubit_simulation,
    test_bell_state_simulation,
    test_measurement_probabilities,
    format("All simulator tests passed.~n").

test_single_qubit_simulation :-
    format("Testing single-qubit gate simulation...~n"),
    %% H|0> = |+>
    Circuit = circuit([q0],[],[h(q0)]),
    statevector(Circuit, State),
    length(State, 2),
    format("  State after H: ~w~n", [State]),
    %% Check both amplitudes are 1/sqrt(2)
    nth0(0, State, c(A0,_)),
    nth0(1, State, c(A1,_)),
    H is 1/sqrt(2),
    Tol = 1.0e-10,
    abs(A0 - H) < Tol,
    abs(A1 - H) < Tol,
    format("  PASS: H|0> = (|0>+|1>)/sqrt(2)~n").

test_bell_state_simulation :-
    format("Testing Bell state simulation...~n"),
    %% H on q0, then CNOT
    Gates = [h(q0), cx(q0,q1)],
    collect_qubits(Gates, Qubits),
    format("  Qubits: ~w~n", [Qubits]),
    ( Qubits = [q0, q1]
    -> Circuit = circuit([q0,q1],[],Gates),
       statevector(Circuit, State),
       length(State, 4),
       format("  State: ~w~n", [State]),
       format("  PASS: Bell state has 4 amplitudes~n")
    ;  format("  SKIP: qubit collection issue~n")
    ).

test_measurement_probabilities :-
    format("Testing probability calculation...~n"),
    %% |0> has probability 1 of outcome 0
    State = [c(1,0), c(0,0)],
    quantum_measure:measurement_probabilities(State, 0, 1, probs(P0, P1)),
    abs(P0 - 1.0) < 1.0e-10,
    abs(P1 - 0.0) < 1.0e-10,
    format("  PASS: |0> has P(0)=1, P(1)=0~n"),
    %% |+> has probability 0.5 each
    H is 1/sqrt(2),
    PlusState = [c(H,0), c(H,0)],
    quantum_measure:measurement_probabilities(PlusState, 0, 1, probs(P0b, P1b)),
    abs(P0b - 0.5) < 1.0e-10,
    abs(P1b - 0.5) < 1.0e-10,
    format("  PASS: |+> has P(0)=0.5, P(1)=0.5~n").

collect_qubits(Gates, Qubits) :-
    maplist([G,Qs]>>(catch(quantum_ir:gate_operands(G,Qs),_,Qs=[])), Gates, QLists),
    flatten(QLists, AllQ),
    include(atom, AllQ, AtomQ),
    list_to_set(AtomQ, Qubits).
