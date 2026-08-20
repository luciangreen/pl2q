%% test_gates.pl
%% Tests for all quantum gates.

:- use_module('../prolog/quantum_gate_registry').
:- use_module('../prolog/quantum_complex').
:- use_module('../prolog/quantum_matrix').

:- initialization(run_gate_tests, main).

run_gate_tests :-
    format("=== Gate Tests ===~n"),
    test_gate_exists,
    test_gate_matrices,
    test_gate_inverses,
    test_gate_properties,
    format("All gate tests passed.~n").

test_gate_exists :-
    format("Testing gate registry...~n"),
    all_quantum_gates(Gates),
    length(Gates, N),
    format("  ~w gates registered~n", [N]),
    N > 10,
    format("  PASS: gate registry non-empty~n").

test_gate_matrices :-
    format("Testing gate matrices...~n"),
    gate_matrix(x, XM),
    gate_matrix(z, ZM),
    gate_matrix(h, HM),
    matrix_dims(XM, 2, 2),
    matrix_dims(ZM, 2, 2),
    matrix_dims(HM, 2, 2),
    Tol = 1.0e-10,
    matrix_is_unitary(XM, Tol),
    matrix_is_unitary(ZM, Tol),
    matrix_is_unitary(HM, Tol),
    format("  PASS: X, Z, H matrices are 2x2 unitary~n"),
    gate_matrix(cx, CXM),
    matrix_dims(CXM, 4, 4),
    matrix_is_unitary(CXM, Tol),
    format("  PASS: CX matrix is 4x4 unitary~n"),
    gate_matrix(ccx, CCXM),
    matrix_dims(CCXM, 8, 8),
    matrix_is_unitary(CCXM, Tol),
    format("  PASS: CCX matrix is 8x8 unitary~n").

test_gate_inverses :-
    format("Testing gate inverses...~n"),
    gate_inverse(s, sdg),
    gate_inverse(sdg, s),
    gate_inverse(t, tdg),
    gate_inverse(tdg, t),
    gate_inverse(h, h),
    gate_inverse(x, x),
    format("  PASS: gate inverses correct~n").

test_gate_properties :-
    format("Testing gate properties...~n"),
    gate_property(x, pauli),
    gate_property(h, clifford),
    gate_property(cx, entangling),
    gate_property(cx, controlled),
    gate_property(t, phase),
    gate_property(z, diagonal),
    format("  PASS: gate properties correct~n").

%% Test mathematical identities
test_gate_identities :-
    format("Testing gate identities (H H = I, X X = I, ...)~n"),
    Tol = 1.0e-10,
    gate_matrix(h, H),
    matrix_mul(H, H, HH),
    matrix_identity(2, I2),
    matrix_equal(HH, I2, Tol),
    format("  PASS: H*H = I~n"),
    gate_matrix(x, X),
    matrix_mul(X, X, XX),
    matrix_equal(XX, I2, Tol),
    format("  PASS: X*X = I~n"),
    gate_matrix(y, Y),
    matrix_mul(Y, Y, YY),
    matrix_equal(YY, I2, Tol),
    format("  PASS: Y*Y = I~n"),
    gate_matrix(z, Z),
    matrix_mul(Z, Z, ZZ),
    matrix_equal(ZZ, I2, Tol),
    format("  PASS: Z*Z = I~n"),
    gate_matrix(s, S),
    matrix_mul(S, S, SS),
    matrix_equal(SS, Z, Tol),
    format("  PASS: S*S = Z~n"),
    gate_matrix(t, T),
    matrix_mul(T, T, TT),
    matrix_equal(TT, S, Tol),
    format("  PASS: T*T = S~n"),
    gate_matrix(cx, CX),
    matrix_mul(CX, CX, CXCX),
    matrix_identity(4, I4),
    matrix_equal(CXCX, I4, Tol),
    format("  PASS: CX*CX = I~n"),
    gate_matrix(swap, SW),
    matrix_mul(SW, SW, SWSW),
    matrix_equal(SWSW, I4, Tol),
    format("  PASS: SWAP*SWAP = I~n").
