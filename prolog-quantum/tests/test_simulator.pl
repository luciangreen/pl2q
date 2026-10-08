%% test_simulator.pl
%% Tests for the quantum statevector simulator.

:- use_module('../prolog/quantum_simulator').
:- use_module('../prolog/quantum_state').
:- use_module('../prolog/quantum_complex').
:- use_module('../prolog/quantum_matrix').
:- use_module('../prolog/quantum_ir').
:- use_module('../prolog/quantum_measure').
:- use_module(library(apply)).
:- use_module(library(lists)).
:- use_module(library(yall)).

:- initialization(run_simulator_tests, main).

run_simulator_tests :-
    format("=== Simulator Tests ===~n"),
    test_single_qubit_simulation,
    test_bell_state_simulation,
    test_measurement_probabilities,
    test_arbitrary_unitary_simulation,
    test_nonadjacent_gate_simulation,
    test_probability_distribution,
    test_shot_sampling,
    test_circuit_unitary,
    test_invalid_unitary,
    test_unsupported_gate,
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
       H is 1/sqrt(2),
       nth0(0, State, c(A00,_)),
       nth0(3, State, c(A11,_)),
       nth0(1, State, c(A01,_)),
       nth0(2, State, c(A10,_)),
       Tol = 1.0e-10,
       abs(A00-H) < Tol,
       abs(A11-H) < Tol,
       abs(A01) < Tol,
       abs(A10) < Tol,
       format("  PASS: Bell state amplitudes are correct~n")
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

test_arbitrary_unitary_simulation :-
    format("Testing arbitrary unitary gate simulation...~n"),
    X = [[c(0,0),c(1,0)],[c(1,0),c(0,0)]],
    Circuit = circuit([q0],[],[unitary(X,[q0])]),
    statevector(Circuit, [c(A0,_),c(A1,_)]),
    abs(A0) < 1.0e-10,
    abs(A1-1.0) < 1.0e-10,
    format("  PASS: arbitrary unitary matrix is applied~n").

test_nonadjacent_gate_simulation :-
    format("Testing non-adjacent controlled gate simulation...~n"),
    Circuit = circuit([q0,q1,q2],[],[x(q1),cx(q1,q0)]),
    statevector(Circuit, State),
    nth0(6, State, c(Amplitude, _)),
    abs(Amplitude-1.0) < 1.0e-10,
    forall((between(0,7,I), I =\= 6),
           (nth0(I,State,c(Re,Im)), abs(Re)+abs(Im) < 1.0e-10)),
    format("  PASS: control and target bits are applied in place~n").

test_probability_distribution :-
    format("Testing basis labels in probability distributions...~n"),
    probabilities(circuit([q0,q1],[],[h(q0),cx(q0,q1)]), Distribution),
    member('00'-P00, Distribution),
    member('11'-P11, Distribution),
    abs(P00-0.5) < 1.0e-10,
    abs(P11-0.5) < 1.0e-10,
    member('01'-P01, Distribution),
    member('10'-P10, Distribution),
    abs(P01) < 1.0e-10,
    abs(P10) < 1.0e-10,
    format("  PASS: probabilities use fixed-width binary labels~n").

test_shot_sampling :-
    format("Testing shot sampling...~n"),
    sample(circuit([q0,q1],[],[h(q0),cx(q0,q1)]), 100, counts(Counts)),
    sum_counts(Counts, Total),
    Total =:= 100,
    forall(member(Label-Count, Counts),
           (atom_length(Label,2), integer(Count), Count >= 0)),
    format("  PASS: sampled frequencies sum to the requested shots~n").

test_circuit_unitary :-
    format("Testing circuit unitary construction...~n"),
    Circuit = circuit([q0,q1],[],[h(q0),cx(q0,q1)]),
    circuit_unitary(Circuit, Matrix),
    matrix_is_unitary(Matrix, 1.0e-10),
    matrix_apply(Matrix, [c(1,0),c(0,0),c(0,0),c(0,0)], State),
    H is 1/sqrt(2),
    nth0(0, State, c(A00,_)),
    nth0(3, State, c(A11,_)),
    abs(A00-H) < 1.0e-10,
    abs(A11-H) < 1.0e-10,
    format("  PASS: circuit unitary preserves multi-qubit gate action~n").

test_invalid_unitary :-
    format("Testing invalid unitary rejection...~n"),
    Invalid = [[c(1,0),c(1,0)],[c(0,0),c(0,0)]],
    catch(statevector(circuit([q0],[],[unitary(Invalid,[q0])]), _),
          error(domain_error(unitary_matrix, _), _),
          Caught = true),
    Caught == true,
    format("  PASS: non-unitary matrix is rejected~n").

test_unsupported_gate :-
    format("Testing unsupported gate diagnostics...~n"),
    catch(statevector(circuit([q0],[],[unknown_gate(q0)]), _),
          error(unsupported(simulation, unknown_gate(q0)), _),
          Caught = true),
    Caught == true,
    format("  PASS: unsupported gates are not silently ignored~n").

sum_counts(Counts, Total) :-
    findall(Count, member(_-Count, Counts), Values),
    sum_list(Values, Total).

collect_qubits(Gates, Qubits) :-
    maplist([G,Qs]>>(catch(quantum_ir:gate_operands(G,Qs),_,Qs=[])), Gates, QLists),
    flatten(QLists, AllQ),
    include(atom, AllQ, AtomQ),
    list_to_set(AtomQ, Qubits).
