%% test_decomposition.pl
%% Tests for gate decomposition.

:- use_module('../prolog/quantum_decompose').

:- initialization(run_decomposition_tests, main).

run_decomposition_tests :-
    format("=== Decomposition Tests ===~n"),
    test_ccx_decomposition,
    test_swap_decomposition,
    test_basis_decomposition,
    test_qft,
    format("All decomposition tests passed.~n").

test_ccx_decomposition :-
    format("Testing CCX (Toffoli) decomposition...~n"),
    decompose_gate(ccx(a,b,t), [h,t,tdg,cx], D),
    is_list(D),
    length(D, N),
    N > 5,
    format("  PASS: CCX decomposes to ~w gates~n", [N]).

test_swap_decomposition :-
    format("Testing SWAP decomposition...~n"),
    decompose_gate(swap(a,b), [cx], D),
    D = [cx(a,b), cx(b,a), cx(a,b)],
    format("  PASS: SWAP = CX CX CX~n").

test_basis_decomposition :-
    format("Testing basis decomposition...~n"),
    decompose_gate(h(q0), [ry,rz], D),
    is_list(D),
    format("  PASS: H decomposes in Ry,Rz basis: ~w~n", [D]).

test_qft :-
    format("Testing QFT circuit generation...~n"),
    qft_circuit([q0,q1,q2], QFT),
    is_list(QFT),
    length(QFT, N),
    N > 0,
    format("  PASS: QFT has ~w gates~n", [N]),
    inverse_qft_circuit([q0,q1,q2], IQFT),
    is_list(IQFT),
    format("  PASS: Inverse QFT generated~n").
