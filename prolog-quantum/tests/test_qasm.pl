%% test_qasm.pl
%% Tests for QASM import/export.

:- use_module('../prolog/quantum_qasm').
:- use_module('../prolog/quantum_qiskit').

:- initialization(run_qasm_tests, main).

run_qasm_tests :-
    format("=== QASM Tests ===~n"),
    test_qasm_export,
    test_qiskit_export,
    format("All QASM tests passed.~n").

test_qasm_export :-
    format("Testing QASM export...~n"),
    Circuit = circuit([q0,q1],[c0,c1],[h(q0), cx(q0,q1), measure(q0,c0), measure(q1,c1)]),
    prolog_to_qasm(Circuit, QASM),
    atom(QASM),
    atom_contains(QASM, 'OPENQASM'),
    atom_contains(QASM, 'h q0'),
    atom_contains(QASM, 'cx q0,q1'),
    format("  PASS: QASM export contains correct gates~n"),
    format("  QASM:~n~w~n", [QASM]).

atom_contains(Atom, Sub) :-
    atom_string(Atom, Str),
    atom_string(Sub, SubStr),
    string_concat(_, Suffix, Str),
    string_concat(SubStr, _, Suffix), !.

test_qiskit_export :-
    format("Testing Qiskit/Python export...~n"),
    Circuit = circuit([q0,q1],[],[h(q0), cx(q0,q1)]),
    prolog_to_qiskit(Circuit, Python),
    atom(Python),
    atom_contains(Python, 'QuantumCircuit'),
    atom_contains(Python, 'qc.h'),
    atom_contains(Python, 'qc.cx'),
    format("  PASS: Qiskit export contains correct code~n").
