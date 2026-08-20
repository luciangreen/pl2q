%% test_unitary.pl
%% Tests for unitary matrix handling.

:- use_module('../prolog/quantum_complex').
:- use_module('../prolog/quantum_matrix').
:- use_module('../prolog/quantum_gate_registry').

:- initialization(run_unitary_tests, main).

run_unitary_tests :-
    format("=== Unitary Tests ===~n"),
    test_standard_gate_unitarity,
    test_custom_unitary,
    test_matrix_validation,
    format("All unitary tests passed.~n").

test_standard_gate_unitarity :-
    format("Testing all standard gates are unitary...~n"),
    Tol = 1.0e-9,
    forall(
        member(Name, [i, id, x, y, z, h, s, sdg, t, tdg, sx, sxdg, cx, cz, swap]),
        (
            gate_matrix(Name, M),
            ( matrix_is_unitary(M, Tol)
            -> format("  PASS: ~w is unitary~n", [Name])
            ;  format("  FAIL: ~w is NOT unitary~n", [Name]), fail
            )
        )
    ).

test_custom_unitary :-
    format("Testing custom unitary gate...~n"),
    %% Valid 2x2 unitary: X gate
    M = [[c(0,0),c(1,0)],[c(1,0),c(0,0)]],
    ( matrix_is_unitary(M, 1.0e-9)
    -> format("  PASS: custom unitary accepted~n")
    ;  format("  FAIL: custom unitary rejected~n"), fail
    ),
    %% Invalid: non-unitary 2x2
    MBad = [[c(1,0),c(1,0)],[c(0,0),c(0,0)]],
    ( \+ matrix_is_unitary(MBad, 1.0e-9)
    -> format("  PASS: non-unitary matrix rejected~n")
    ;  format("  FAIL: non-unitary matrix accepted~n"), fail
    ).

test_matrix_validation :-
    format("Testing matrix dimension validation...~n"),
    M2x2 = [[c(1,0),c(0,0)],[c(0,0),c(1,0)]],
    matrix_dims(M2x2, 2, 2),
    format("  PASS: 2x2 identity dimensions correct~n"),
    M4x4 = [[c(1,0),c(0,0),c(0,0),c(0,0)],
            [c(0,0),c(1,0),c(0,0),c(0,0)],
            [c(0,0),c(0,0),c(1,0),c(0,0)],
            [c(0,0),c(0,0),c(0,0),c(1,0)]],
    matrix_dims(M4x4, 4, 4),
    format("  PASS: 4x4 identity dimensions correct~n").
