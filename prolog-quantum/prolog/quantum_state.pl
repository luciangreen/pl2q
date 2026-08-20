%% quantum_state.pl
%% Quantum state representation and manipulation.

:- module(quantum_state, [
    basis_state/2,
    ket/2,
    bra/2,
    amplitude/3,
    state_vector/2,
    state_from_amplitudes/2,
    state_norm/2,
    state_normalise/2,
    state_inner_product/3,
    state_is_normalised/2,
    state_tensor/3,
    state_project/3,
    zero_state/2,
    plus_state/1,
    minus_state/1,
    bell_phi_plus/1,
    bell_phi_minus/1,
    bell_psi_plus/1,
    bell_psi_minus/1,
    ghz_state/2
]).

:- use_module(quantum_complex).
:- use_module(quantum_matrix).
:- use_module(quantum_tensor).

%% basis_state(+N, ?V): N-qubit computational basis |0...0>
basis_state(N, V) :-
    Dim is 2^N,
    length(V, Dim),
    nth0(0, V, c(1,0)),
    numlist(1, Dim-1, Idxs),
    maplist([I]>>(nth0(I, V, c(0,0))), Idxs).

%% ket(+Label, ?V): named ket state
ket(0, [c(1,0), c(0,0)]).
ket(1, [c(0,0), c(1,0)]).
ket('0', [c(1,0), c(0,0)]).
ket('1', [c(0,0), c(1,0)]).

%% bra(+Label, ?B): row vector (complex conjugate of ket)
bra(L, B) :-
    ket(L, K),
    maplist([E, CE]>>(complex_conj(E, CE)), K, B).

%% amplitude(+State, +Basis, ?Amp)
amplitude(State, BasisIdx, Amp) :-
    nth0(BasisIdx, State, Amp).

%% state_vector(+State, ?V)
state_vector(state(V), V).
state_vector(V, V) :- is_list(V).

%% state_from_amplitudes(+Amps, ?State)
%% Amps: list of amplitude(BasisStr, c(R,I))
state_from_amplitudes(Amps, State) :-
    length(Amps, Len),
    Dim is round(2^(round(log(Len)/log(2)))),
    ( Dim =:= Len -> true ; throw(error(invalid_state_dimension, state_from_amplitudes/2)) ),
    maplist([amplitude(_, A), A]>>true, Amps, State).

%% state_norm(+State, ?N)
state_norm(State, N) :-
    state_vector(State, V),
    vector_norm(V, N).

%% state_normalise(+State, ?NS)
state_normalise(State, NState) :-
    state_vector(State, V),
    vector_normalise(V, NV),
    NState = NV.

%% state_is_normalised(+State, +Tol)
state_is_normalised(State, Tol) :-
    state_norm(State, N),
    abs(N - 1.0) =< Tol.

%% state_inner_product(+S1, +S2, ?IP)
state_inner_product(S1, S2, IP) :-
    state_vector(S1, V1),
    state_vector(S2, V2),
    inner_product(V1, V2, IP).

%% state_tensor(+S1, +S2, ?S)
state_tensor(S1, S2, S) :-
    state_vector(S1, V1),
    state_vector(S2, V2),
    tensor_product(V1, V2, V),
    S = V.

%% state_project(+State, +Subspace, ?Prob)
state_project(State, Subspace, Prob) :-
    state_inner_product(State, Subspace, IP),
    complex_abs_sq(IP, Prob).

%% zero_state(+N, ?S)
zero_state(N, S) :-
    Dim is 2^N,
    length(S, Dim),
    nth0(0, S, c(1,0)),
    numlist(1, Dim-1, Idxs),
    maplist([I]>>(nth0(I, S, c(0,0))), Idxs).

%% Single-qubit standard states
plus_state([c(H, 0), c(H, 0)]) :- H is 1/sqrt(2).
minus_state([c(H, 0), c(NH, 0)]) :- H is 1/sqrt(2), NH is -H.

%% Bell states (2-qubit)
bell_phi_plus([c(H,0), c(0,0), c(0,0), c(H,0)]) :- H is 1/sqrt(2).
bell_phi_minus([c(H,0), c(0,0), c(0,0), c(NH,0)]) :- H is 1/sqrt(2), NH is -H.
bell_psi_plus([c(0,0), c(H,0), c(H,0), c(0,0)]) :- H is 1/sqrt(2).
bell_psi_minus([c(0,0), c(H,0), c(NH,0), c(0,0)]) :- H is 1/sqrt(2), NH is -H.

%% GHZ state for N qubits: (|00..0> + |11..1>)/sqrt(2)
ghz_state(N, S) :-
    Dim is 2^N,
    length(S, Dim),
    H is 1/sqrt(2),
    Last is Dim - 1,
    nth0(0, S, c(H,0)),
    nth0(Last, S, c(H,0)),
    numlist(1, Last-1, MiddleIdxs),
    maplist([I]>>(nth0(I, S, c(0,0))), MiddleIdxs).
