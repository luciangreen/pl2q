%% quantum_entanglement.pl
%% Entanglement detection, analysis, and creation.

:- module(quantum_entanglement, [
    entangled/2,
    entanglement_report/2,
    partial_trace/3,
    density_matrix/2,
    entanglement_entropy/3,
    schmidt_decomposition/4,
    quantum_entangle/3,
    quantum_disentangle/3,
    bell_pair/3,
    ghz/2,
    w_state/2,
    entangle/2,
    entanglement_graph/3,
    teleport/4,
    superdense_encode/2,
    superdense_decode/2
]).

:- use_module(quantum_complex).
:- use_module(quantum_matrix).
:- use_module(quantum_tensor).
:- use_module(quantum_state).

%% entangled(+State, ?Result)
%% Result = true | false | unknown
entangled(State, Result) :-
    ( is_list(State)
    -> check_separability(State, Result)
    ;  Result = unknown
    ).

check_separability(State, Result) :-
    length(State, Dim),
    ( Dim < 2
    -> Result = false
    ;  N is round(log(Dim) / log(2)),
       N >= 2
    -> try_bipartite_separability(State, N, Result)
    ;  Result = unknown
    ).

try_bipartite_separability(State, N, Result) :-
    %% Try all bipartitions [0..k-1 | k..N-1] for k=1..N-1
    Max is N - 1,
    ( forall(
        ( between(1, Max, K),
          bipartition_separable(State, K, N)
        ),
        true
      )
    -> Result = false
    ;  Result = true
    ).

%% bipartition_separable(+State, +K, +N)
%% Returns true if the bipartition at K is separable (product state)
bipartition_separable(State, K, N) :-
    DimA is 2^K,
    DimB is 2^(N-K),
    %% Compute reduced density matrix of subsystem A
    reduced_density_matrix(State, DimA, DimB, RhoA),
    %% State is separable across this cut iff Tr(RhoA^2) = 1 (pure reduced state)
    trace_square(RhoA, T),
    abs(T - 1.0) < 1.0e-9.

reduced_density_matrix(State, DimA, DimB, RhoA) :-
    %% RhoA[i,j] = sum_k State[i*DimB+k] * conj(State[j*DimB+k])
    numlist(0, DimA-1, Is),
    numlist(0, DimA-1, Js),
    maplist([I, Row]>>(
        maplist([J, Elem]>>(
            numlist(0, DimB-1, Ks),
            maplist([K, P]>>(
                IK is I * DimB + K,
                JK is J * DimB + K,
                nth0(IK, State, AmpI),
                nth0(JK, State, AmpJ),
                complex_conj(AmpJ, CAmpJ),
                complex_mul(AmpI, CAmpJ, P)
            ), Ks, Prods),
            foldl([P, Acc, NAcc]>>(complex_add(P, Acc, NAcc)), Prods, c(0,0), Elem)
        ), Js, Row)
    ), Is, RhoA).

trace_square(Rho, T) :-
    quantum_matrix:matrix_mul(Rho, Rho, Rho2),
    quantum_matrix:matrix_trace(Rho2, TC),
    complex_re(TC, T).

%% entanglement_report(+State, ?Report)
entanglement_report(State, Report) :-
    entangled(State, Sep),
    ( Sep = true
    -> Separable = false
    ;  Separable = true
    ),
    length(State, Dim),
    N is round(log(Dim) / log(2)),
    ( N >= 2
    -> entanglement_entropy(State, [0], Entropy)
    ;  Entropy = 0
    ),
    Report = report(
        qubits(N),
        separable(Separable),
        entanglement(Sep),
        entropy(Entropy)
    ).

%% partial_trace(+State, +RemovedQubits, ?ReducedState)
partial_trace(State, RemovedQubits, ReducedRho) :-
    length(State, Dim),
    N is round(log(Dim) / log(2)),
    length(RemovedQubits, NR),
    NK is N - NR,
    DimK is 2^NK,
    DimR is 2^NR,
    %% Build density matrix
    outer_product(State, State, Rho),
    %% Trace over removed qubits
    partial_trace_dm(Rho, N, RemovedQubits, DimK, DimR, ReducedRho).

partial_trace_dm(Rho, _N, _Removed, DimK, DimR, ReducedRho) :-
    numlist(0, DimK-1, Is),
    numlist(0, DimK-1, Js),
    maplist([I, Row]>>(
        maplist([J, Elem]>>(
            numlist(0, DimR-1, Ks),
            maplist([K, E]>>(
                RI is I * DimR + K,
                CI is J * DimR + K,
                quantum_matrix:matrix_get(Rho, RI, CI, E)
            ), Ks, Elems),
            foldl([E2, Acc, NAcc]>>(complex_add(E2, Acc, NAcc)), Elems, c(0,0), Elem)
        ), Js, Row)
    ), Is, ReducedRho).

%% density_matrix(+State, ?Rho)
density_matrix(State, Rho) :-
    outer_product(State, State, Rho).

%% entanglement_entropy(+State, +Partition, ?Entropy)
entanglement_entropy(State, Partition, Entropy) :-
    length(State, Dim),
    N is round(log(Dim) / log(2)),
    length(Partition, K),
    NK is N - K,
    DimA is 2^K,
    DimB is 2^NK,
    reduced_density_matrix(State, DimA, DimB, RhoA),
    von_neumann_entropy(RhoA, Entropy).

von_neumann_entropy(Rho, Entropy) :-
    %% Approximate eigenvalues via trace operations
    %% For 2x2 case: eigenvalues from characteristic polynomial
    quantum_matrix:matrix_dims(Rho, N, N),
    ( N =:= 2
    -> rho2x2_entropy(Rho, Entropy)
    ;  Entropy = 0.0  %% placeholder for larger matrices
    ).

rho2x2_entropy(Rho, Entropy) :-
    quantum_matrix:matrix_get(Rho, 0, 0, c(R00,_)),
    quantum_matrix:matrix_get(Rho, 1, 1, c(R11,_)),
    quantum_matrix:matrix_get(Rho, 0, 1, c(R01r, R01i)),
    Det is R00*R11 - (R01r*R01r + R01i*R01i),
    Tr is R00 + R11,
    Disc is max(0, Tr*Tr/4 - Det),
    L1 is Tr/2 + sqrt(Disc),
    L2 is Tr/2 - sqrt(Disc),
    H1 is ( L1 > 1.0e-15 -> -L1 * log(L1) / log(2) ; 0 ),
    H2 is ( L2 > 1.0e-15 -> -L2 * log(L2) / log(2) ; 0 ),
    Entropy is H1 + H2.

%% schmidt_decomposition(+State, +A, +B, ?Result)
schmidt_decomposition(State, SubA, SubB, Result) :-
    length(State, Dim),
    N is round(log(Dim) / log(2)),
    length(SubA, NA),
    length(SubB, NB),
    NA + NB =:= N,
    DimA is 2^NA,
    DimB is 2^NB,
    %% Build matrix M[i,j] = State[i*DimB+j]
    numlist(0, DimA-1, Is),
    numlist(0, DimB-1, Js),
    maplist([I, Row]>>(
        maplist([J, E]>>(
            IJ is I * DimB + J,
            nth0(IJ, State, E)
        ), Js, Row)
    ), Is, M),
    Result = schmidt_matrix(M).

%% quantum_entangle(+Qubits, +Spec, ?Circuit)
quantum_entangle([A,B], bell(phi_plus), [h(A), cx(A,B)]) :- !.
quantum_entangle([A,B], bell(phi_minus), [h(A), cx(A,B), z(A)]) :- !.
quantum_entangle([A,B], bell(psi_plus), [x(B), h(A), cx(A,B)]) :- !.
quantum_entangle([A,B], bell(psi_minus), [x(B), h(A), cx(A,B), z(A)]) :- !.
quantum_entangle(Qubits, ghz, Circuit) :-
    ghz(Qubits, Circuit), !.
quantum_entangle(Qubits, w, Circuit) :-
    w_state(Qubits, Circuit), !.
quantum_entangle(Qubits, _, Circuit) :-
    bell_pair_from_list(Qubits, Circuit).

bell_pair_from_list([A,B|_], [h(A), cx(A,B)]).

%% quantum_disentangle(+State, +Options, ?Circuit)
quantum_disentangle(State, _Options, Circuit) :-
    entangled(State, Entangled),
    ( Entangled = false
    -> Circuit = []  % already separable
    ;  Circuit = disentangle(State)  % symbolic - requires specific circuit synthesis
    ).

%% bell_pair(+A, +B, ?Circuit)
bell_pair(A, B, [h(A), cx(A,B)]).

%% ghz(+Qubits, ?Circuit)
ghz([Q|Qs], Circuit) :-
    maplist([Qi, cx(Q,Qi)]>>true, Qs, CNOTs),
    Circuit = [h(Q)|CNOTs].

%% w_state(+Qubits, ?Circuit)
%% W state: (|100> + |010> + |001>)/sqrt(3)
w_state([Q1,Q2,Q3], Circuit) :-
    Theta1 is 2 * acos(sqrt(2/3)),
    Theta2 is pi/4,  % ry(pi/2) on second qubit
    Circuit = [
        ry(Theta1, Q1),
        cx(Q1, Q2),
        ry(Theta2, Q2),
        cx(Q2, Q3),
        cx(Q1, Q2),
        x(Q3)
    ].
w_state(Qs, Circuit) :-
    length(Qs, N),
    N > 3,
    w_state_general(Qs, Circuit).

w_state_general([Q|Qs], Circuit) :-
    w_state_general_help([Q|Qs], 1, Circuit).

w_state_general_help([Q], _, [ry(theta_r, Q)]) :- !.
w_state_general_help([Q|Qs], K, [ry(Theta,Q)|Rest]) :-
    length([Q|Qs], N),
    Theta is 2 * acos(sqrt((N-K)/(N-K+1))),
    K2 is K + 1,
    w_state_general_help(Qs, K2, RestOps),
    maplist([Qi, cx(Q,Qi)]>>true, Qs, CNOTs),
    append(RestOps, CNOTs, Rest).

%% entangle(+Pairs, ?Circuit)
%% entangle([q0-q1, q1-q2]) - entangle by Bell pair for each
entangle([], []).
entangle([A-B|Rest], Circuit) :-
    entangle(Rest, RestC),
    append([h(A), cx(A,B)], RestC, Circuit).

%% entanglement_graph(+Qubits, +Edges, ?Circuit)
entanglement_graph(_, Edges, Circuit) :-
    maplist([edge(A,B), [h(A),cx(A,B)]]>>true, Edges, Parts),
    flatten(Parts, Circuit).

%% teleport(+Source, +Alice, +Bob, ?Circuit)
teleport(Source, Alice, Bob, Circuit) :-
    Circuit = [
        %% Create Bell pair between Alice and Bob
        h(Alice),
        cx(Alice, Bob),
        %% Alice's operations
        cx(Source, Alice),
        h(Source),
        %% Measurements
        measure(Source, c0),
        measure(Alice, c1),
        %% Classical corrections
        if_bit(c1, 1, x(Bob)),
        if_bit(c0, 1, z(Bob))
    ].

%% superdense_encode(+Bits, ?Circuit)
superdense_encode([0,0], [id(q0)]) :- !.
superdense_encode([0,1], [x(q0)]) :- !.
superdense_encode([1,0], [z(q0)]) :- !.
superdense_encode([1,1], [x(q0), z(q0)]) :- !.
superdense_encode(Bits, Circuit) :-
    superdense_encode(Bits, Circuit).

%% superdense_decode(+Circuit, ?Result)
superdense_decode(_Circuit, result(decoded)) :-
    %% Full decoding would need simulation
    true.
