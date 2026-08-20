%% test_converter.pl
%% Tests for Prolog-to-quantum and quantum-to-Prolog conversion.

:- use_module('../prolog/quantum_reversible').
:- use_module('../prolog/quantum_oracle').

:- initialization(run_converter_tests, main).

run_converter_tests :-
    format("=== Converter Tests ===~n"),
    test_reversibility_analysis,
    test_oracle_conversion,
    test_quantum_to_prolog,
    format("All converter tests passed.~n").

test_reversibility_analysis :-
    format("Testing reversibility analysis...~n"),
    reversibility_analysis(write(hello), R1),
    R1 = effectful,
    format("  PASS: write/1 is effectful~n"),
    reversibility_analysis(_ = _, R2),
    R2 = reversible,
    format("  PASS: unification is reversible~n").

test_oracle_conversion :-
    format("Testing oracle conversion...~n"),
    predicate_to_oracle(f(_, _), [bit, bit], OC),
    format("  PASS: oracle circuit: ~w~n", [OC]).

test_quantum_to_prolog :-
    format("Testing quantum-to-Prolog conversion...~n"),
    quantum_to_prolog(circuit([q0,q1],[],[h(q0),cx(q0,q1)]), Code),
    format("  PASS: generated code: ~w~n", [Code]).
