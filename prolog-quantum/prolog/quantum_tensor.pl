%% quantum_tensor.pl
%% Tensor product operations for quantum states and operators.

:- module(quantum_tensor, [
    tensor_product/3,
    tensor_product_list/2,
    tensor_state/3,
    state_dims/2
]).

:- use_module(quantum_complex).
:- use_module(quantum_matrix).

%% tensor_product(+V1, +V2, ?V): tensor product of two state vectors
tensor_product(V1, V2, V) :-
    maplist([A, Row]>>(
        maplist([B, P]>>(complex_mul(A, B, P)), V2, Row)
    ), V1, Rows),
    flatten(Rows, V).

%% tensor_product_list(+Vs, ?V): tensor product of a list of state vectors
tensor_product_list([V], V) :- !.
tensor_product_list([V|Vs], Result) :-
    tensor_product_list(Vs, VRest),
    tensor_product(V, VRest, Result).

%% tensor_state(+S1, +S2, ?S): tensor product of two quantum states
tensor_state(state(V1), state(V2), state(V)) :-
    tensor_product(V1, V2, V).

%% state_dims(+State, ?N): N is the number of qubits in a state vector of length 2^N
state_dims(V, N) :-
    length(V, Len),
    N is round(log(Len) / log(2)),
    Len =:= 2^N.
