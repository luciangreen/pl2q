%% test_optimisation.pl
%% Tests for circuit optimisation.

:- use_module('../prolog/quantum_optimise').

:- initialization(run_optimisation_tests, main).

run_optimisation_tests :-
    format("=== Optimisation Tests ===~n"),
    test_inverse_cancellation,
    test_identity_removal,
    test_rotation_combination,
    test_circuit_metrics,
    format("All optimisation tests passed.~n").

test_inverse_cancellation :-
    format("Testing inverse gate cancellation...~n"),
    %% x x = []
    cancel_inverses([x(q0), x(q0)], R1),
    R1 = [],
    format("  PASS: x x cancels~n"),
    %% h h = []
    cancel_inverses([h(q0), h(q0)], R2),
    R2 = [],
    format("  PASS: h h cancels~n"),
    %% t tdg = []
    cancel_inverses([t(q0), tdg(q0)], R3),
    R3 = [],
    format("  PASS: t tdg cancels~n"),
    %% x y does not cancel
    cancel_inverses([x(q0), y(q0)], R4),
    R4 = [x(q0), y(q0)],
    format("  PASS: x y does not cancel~n").

test_identity_removal :-
    format("Testing identity gate removal...~n"),
    remove_identities([id(q0), x(q1), i(q2)], R),
    R = [x(q1)],
    format("  PASS: id and i gates removed~n"),
    remove_identities([rx(0,q0), h(q1)], R2),
    R2 = [h(q1)],
    format("  PASS: rx(0) identity removed~n").

test_rotation_combination :-
    format("Testing rotation merging...~n"),
    combine_rotations([rx(0.5,q0), rx(0.3,q0)], R),
    R = [rx(0.8,q0)],
    format("  PASS: rx rotations combined~n"),
    combine_rotations([rz(1.0,q0), rz(2.0,q0)], R2),
    R2 = [rz(3.0,q0)],
    format("  PASS: rz rotations combined~n").

test_circuit_metrics :-
    format("Testing circuit metrics...~n"),
    C = circuit([q0,q1],[],[h(q0), cx(q0,q1), measure(q0,c0)]),
    circuit_metrics(C, Metrics),
    Metrics = metrics(qubits(2), classical_bits(0), gate_count(3), depth(_), two_qubit_gate_count(1), entangling_gate_count(1), measurement_count(1)),
    format("  PASS: circuit metrics computed~n").
