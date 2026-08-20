%% quantum_matrix.pl
%% Matrix operations for quantum computing.
%% Matrices are represented as lists of rows, each row a list of c(Re,Im) values.

:- module(quantum_matrix, [
    matrix_dims/3,
    matrix_get/4,
    matrix_row/3,
    matrix_col/3,
    matrix_mul/3,
    matrix_add/3,
    matrix_scalar_mul/3,
    matrix_transpose/2,
    matrix_conj_transpose/2,
    matrix_identity/2,
    matrix_zero/3,
    matrix_tensor/3,
    matrix_trace/2,
    matrix_is_unitary/2,
    matrix_is_hermitian/2,
    matrix_equal/3,
    matrix_apply/3,
    matrix_from_list/2,
    matrix_to_list/2,
    inner_product/3,
    outer_product/3,
    vector_norm/2,
    vector_normalise/2
]).

:- use_module(quantum_complex).

%% matrix_dims(+Matrix, ?Rows, ?Cols)
matrix_dims(Matrix, Rows, Cols) :-
    length(Matrix, Rows),
    ( Rows > 0
    -> Matrix = [Row|_], length(Row, Cols)
    ;  Cols = 0
    ).

%% matrix_get(+Matrix, +R, +C, ?Val)  (0-indexed)
matrix_get(Matrix, R, C, Val) :-
    nth0(R, Matrix, Row),
    nth0(C, Row, Val).

matrix_row(Matrix, R, Row) :-
    nth0(R, Matrix, Row).

matrix_col(Matrix, C, Col) :-
    maplist(nth0(C), Matrix, Col).

%% matrix_mul(+A, +B, ?C)
matrix_mul(A, B, C) :-
    matrix_dims(A, RA, CA),
    matrix_dims(B, RB, CB),
    CA =:= RB,
    matrix_transpose(B, BT),
    numlist(0, RA-1, RowIdxs),
    maplist(mul_row(A, BT, CB), RowIdxs, C).

mul_row(A, BT, CB, RI, Row) :-
    nth0(RI, A, ARow),
    numlist(0, CB-1, ColIdxs),
    maplist(dot_product(ARow, BT), ColIdxs, Row).

dot_product(ARow, BT, CI, Val) :-
    nth0(CI, BT, BCol),
    maplist([A,B,P]>>(complex_mul(A,B,P)), ARow, BCol, Prods),
    foldl([P, Acc, NAcc]>>(complex_add(P, Acc, NAcc)), Prods, c(0,0), Val).

%% matrix_add(+A, +B, ?C)
matrix_add(A, B, C) :-
    maplist([RA, RB, RC]>>(maplist([A1,B1,C1]>>(complex_add(A1,B1,C1)), RA, RB, RC)), A, B, C).

%% matrix_scalar_mul(+S, +M, ?R)
matrix_scalar_mul(S, M, R) :-
    maplist([Row, RRow]>>(maplist([E, RE]>>(complex_mul(S, E, RE)), Row, RRow)), M, R).

%% matrix_transpose(+M, ?T)
matrix_transpose([], []).
matrix_transpose([[]|_], []) :- !.
matrix_transpose(M, [Row|Rest]) :-
    maplist(nth0(0), M, Row),
    maplist([R, T]>>(R = [_|T]), M, M2),
    matrix_transpose(M2, Rest).

%% matrix_conj_transpose(+M, ?CT)  (Hermitian conjugate / dagger)
matrix_conj_transpose(M, CT) :-
    matrix_transpose(M, T),
    maplist([Row, CRow]>>(maplist([E, CE]>>(complex_conj(E, CE)), Row, CRow)), T, CT).

%% matrix_identity(+N, ?I)
matrix_identity(N, I) :-
    numlist(0, N-1, Idxs),
    maplist([RI, Row]>>(
        numlist(0, N-1, CIdxs),
        maplist([CI, E]>>(
            ( RI =:= CI -> E = c(1,0) ; E = c(0,0) )
        ), CIdxs, Row)
    ), Idxs, I).

%% matrix_zero(+R, +C, ?Z)
matrix_zero(Rows, Cols, Z) :-
    numlist(1, Rows, _),
    numlist(1, Cols, _),
    length(ZeroRow, Cols),
    maplist(=(c(0,0)), ZeroRow),
    length(Z, Rows),
    maplist(=(ZeroRow), Z).

%% matrix_tensor(+A, +B, ?T)  Kronecker product
matrix_tensor(A, B, T) :-
    matrix_dims(A, RA, CA),
    matrix_dims(B, RB, CB),
    RowsT is RA * RB,
    ColsT is CA * CB,
    numlist(0, RowsT-1, RowIdxs),
    maplist(tensor_row(A, B, RB, CB), RowIdxs, T).

tensor_row(A, B, RB, CB, RI, Row) :-
    AIR is RI // RB,
    BIR is RI mod RB,
    matrix_dims(A, _, CA),
    ColsT is CA * CB,
    numlist(0, ColsT-1, ColIdxs),
    maplist(tensor_elem(A, B, AIR, BIR, CB), ColIdxs, Row).

tensor_elem(A, B, AIR, BIR, CB, CI, Val) :-
    AIC is CI // CB,
    BIC is CI mod CB,
    matrix_get(A, AIR, AIC, AVal),
    matrix_get(B, BIR, BIC, BVal),
    complex_mul(AVal, BVal, Val).

%% matrix_trace(+M, ?T)
matrix_trace(M, T) :-
    matrix_dims(M, N, N),
    numlist(0, N-1, Idxs),
    maplist([I, E]>>(matrix_get(M, I, I, E)), Idxs, Diag),
    foldl([E, Acc, NAcc]>>(complex_add(E, Acc, NAcc)), Diag, c(0,0), T).

%% matrix_is_unitary(+M, +Tol)
matrix_is_unitary(M, Tol) :-
    matrix_dims(M, N, N),
    matrix_conj_transpose(M, Md),
    matrix_mul(Md, M, P),
    matrix_identity(N, I),
    matrix_equal(P, I, Tol).

%% matrix_is_hermitian(+M, +Tol)
matrix_is_hermitian(M, Tol) :-
    matrix_conj_transpose(M, Md),
    matrix_equal(M, Md, Tol).

%% matrix_equal(+A, +B, +Tol)
matrix_equal(A, B, Tol) :-
    maplist([RA, RB]>>(
        maplist([E1, E2]>>(complex_equal(E1, E2, Tol)), RA, RB)
    ), A, B).

%% matrix_apply(+M, +Vec, ?Out)  Vec and Out are column vectors as lists
matrix_apply(M, Vec, Out) :-
    maplist([Row, Val]>>(
        maplist([E, V, P]>>(complex_mul(E, V, P)), Row, Vec, Prods),
        foldl([P, Acc, NAcc]>>(complex_add(P, Acc, NAcc)), Prods, c(0,0), Val)
    ), M, Out).

%% matrix_from_list(+List, ?M): List is a flat list of rows each a list
matrix_from_list(List, List).

matrix_to_list(M, M).

%% inner_product(+V1, +V2, ?IP):  <V1|V2> = sum_i conj(V1_i)*V2_i
inner_product(V1, V2, IP) :-
    maplist([A, B, P]>>(complex_conj(A, CA), complex_mul(CA, B, P)), V1, V2, Prods),
    foldl([P, Acc, NAcc]>>(complex_add(P, Acc, NAcc)), Prods, c(0,0), IP).

%% outer_product(+V1, +V2, ?M):  |V1><V2|
outer_product(V1, V2, M) :-
    maplist([A, Row]>>(
        maplist([B, E]>>(complex_conj(B, CB), complex_mul(A, CB, E)), V2, Row)
    ), V1, M).

%% vector_norm(+V, ?N)
vector_norm(V, N) :-
    inner_product(V, V, IP),
    complex_re(IP, R),
    N is sqrt(R).

%% vector_normalise(+V, ?NV)
vector_normalise(V, NV) :-
    vector_norm(V, N),
    N > 0,
    maplist([E, NE]>>(complex_div(E, c(N,0), NE)), V, NV).
