%% quantum_decompose.pl
%% Gate decomposition into target universal gate bases.

:- module(quantum_decompose, [
    quantum_decompose/3,
    decompose_gate/3,
    decompose_circuit/3,
    solovay_kitaev_approx/3,
    qft_circuit/2,
    inverse_qft_circuit/2,
    quantum_phase_estimation/4,
    grover_oracle/2,
    grover_diffusion/2,
    grover_iteration/3
]).

:- use_module(quantum_gate).
:- use_module(quantum_gate_registry).
:- use_module(quantum_errors).

%% quantum_decompose(+Circuit, +Basis, ?Decomposed)
quantum_decompose(circuit(Q,C,Gates), Basis, circuit(Q,C,Decomposed)) :-
    maplist([G, DGs]>>(decompose_gate_basis(G, Basis, DGs)), Gates, DGLists),
    flatten(DGLists, Decomposed).

decompose_gate_basis(Gate, Basis, Decomposed) :-
    gate_normalise(Gate, NG),
    functor(NG, Name, _),
    ( member(Name, Basis)
    -> Decomposed = [Gate]
    ;  decompose_to_basis_rules(NG, Basis, Decomposed)
    ).

decompose_to_basis_rules(ccx(A,B,T), Basis, D) :-
    ( ( member(h,Basis), member(t,Basis), member(tdg,Basis), member(cx,Basis) )
    -> ccx_standard_decomp(A, B, T, D)
    ;  D = [ccx(A,B,T)]
    ).

decompose_to_basis_rules(swap(A,B), Basis, D) :-
    ( member(cx, Basis)
    -> D = [cx(A,B), cx(B,A), cx(A,B)]
    ;  D = [swap(A,B)]
    ).

decompose_to_basis_rules(cswap(C,A,B), Basis, D) :-
    ( member(cx, Basis)
    -> D = [cx(B,A), ccx(C,A,B), cx(B,A)]
    ;  D = [cswap(C,A,B)]
    ).

decompose_to_basis_rules(mcx([C1,C2|Cs], T), Basis, D) :-
    ( Cs = []
    -> decompose_to_basis_rules(ccx(C1,C2,T), Basis, D)
    ;  %% Multi-controlled X decomposition using ancilla (Barenco et al.)
       D = [mcx([C1,C2|Cs], T)]  % symbolic for now
    ).

decompose_to_basis_rules(h(Q), Basis, D) :-
    ( member(ry, Basis), member(rz, Basis)
    -> D = [ry(1.5707963267948966, Q), rz(3.141592653589793, Q)]
    ;  D = [h(Q)]
    ).

decompose_to_basis_rules(u(Theta,Phi,Lambda,Q), Basis, D) :-
    ( member(rz, Basis), member(ry, Basis)
    -> D = [rz(Lambda, Q), ry(Theta, Q), rz(Phi, Q)]
    ;  member(rz, Basis), member(sx, Basis)
    -> D = [rz(Lambda + 1.5707963267948966, Q), sx(Q), rz(Theta + 3.141592653589793, Q), sx(Q), rz(Phi + 1.5707963267948966, Q)]
    ;  D = [u(Theta,Phi,Lambda,Q)]
    ).

decompose_to_basis_rules(s(Q), Basis, D) :-
    ( member(t, Basis)
    -> D = [t(Q), t(Q)]
    ;  member(rz, Basis)
    -> D = [rz(1.5707963267948966, Q)]
    ;  D = [s(Q)]
    ).

decompose_to_basis_rules(t(Q), Basis, D) :-
    ( member(rz, Basis)
    -> D = [rz(0.7853981633974483, Q)]
    ;  D = [t(Q)]
    ).

decompose_to_basis_rules(sdg(Q), Basis, D) :-
    ( member(rz, Basis)
    -> D = [rz(-1.5707963267948966, Q)]
    ;  D = [sdg(Q)]
    ).

decompose_to_basis_rules(tdg(Q), Basis, D) :-
    ( member(rz, Basis)
    -> D = [rz(-0.7853981633974483, Q)]
    ;  D = [tdg(Q)]
    ).

decompose_to_basis_rules(p(Theta,Q), Basis, D) :-
    ( member(rz, Basis)
    -> D = [rz(Theta, Q)]
    ;  D = [p(Theta,Q)]
    ).

decompose_to_basis_rules(Gate, _, [Gate]).

ccx_standard_decomp(A, B, T, [
    h(T),
    cx(B,T), tdg(T),
    cx(A,T), t(T),
    cx(B,T), tdg(T),
    cx(A,T), t(T),
    h(T),
    t(B), cx(A,B),
    t(A), tdg(B),
    cx(A,B)
]).

%% decompose_gate(+Gate, +Basis, ?Decomposed)
decompose_gate(Gate, Basis, Decomposed) :-
    decompose_gate_basis(Gate, Basis, Decomposed).

%% decompose_circuit(+Circuit, +Basis, ?Decomposed)
decompose_circuit(Circuit, Basis, Decomposed) :-
    quantum_decompose(Circuit, Basis, Decomposed).

%% solovay_kitaev_approx(+U, +Basis, ?Approx)
solovay_kitaev_approx(U, _Basis, approx(U)) :-
    %% Full Solovay-Kitaev requires significant computation
    %% This is a placeholder that returns the gate symbolically
    true.

%% qft_circuit(+Qubits, ?Circuit)
qft_circuit(Qubits, Circuit) :-
    length(Qubits, N),
    qft_gates(Qubits, N, 0, Gates),
    append(Gates, SwapGates, Circuit),
    qft_swaps(Qubits, SwapGates).

qft_gates(_, N, N, []) :- !.
qft_gates(Qubits, N, I, Gates) :-
    I < N,
    nth0(I, Qubits, Q),
    gates_for_qubit(Qubits, N, I, I, [h(Q)], QGates),
    I2 is I + 1,
    qft_gates(Qubits, N, I2, RestGates),
    append(QGates, RestGates, Gates).

gates_for_qubit(_, N, _, N, Acc, Acc) :- !.
gates_for_qubit(Qubits, N, QI, J, Acc, Result) :-
    J < N,
    JI is J - QI + 1,
    ( JI > 1
    -> nth0(J, Qubits, QJ),
       nth0(QI, Qubits, QQI),
       K is JI,
       Theta is 2 * 3.141592653589793 / (2^K),
       append(Acc, [cp(Theta, QJ, QQI)], Acc2)
    ;  Acc2 = Acc
    ),
    J2 is J + 1,
    gates_for_qubit(Qubits, N, QI, J2, Acc2, Result).

qft_swaps(Qubits, Swaps) :-
    length(Qubits, N),
    Last is N - 1,
    findall(swap(Qi,Qj), (
        between(0, Last, I),
        J is N - 1 - I,
        I < J,
        nth0(I, Qubits, Qi),
        nth0(J, Qubits, Qj)
    ), Swaps).

%% inverse_qft_circuit(+Qubits, ?Circuit)
inverse_qft_circuit(Qubits, Circuit) :-
    qft_circuit(Qubits, QFT),
    reverse(QFT, RevQFT),
    maplist(invert_gate, RevQFT, Circuit).

invert_gate(h(Q), h(Q)) :- !.
invert_gate(swap(A,B), swap(A,B)) :- !.
invert_gate(cp(Theta,C,T), cp(NTheta,C,T)) :- NTheta is -Theta, !.
invert_gate(G, G).

%% quantum_phase_estimation(+Unitary, +PrecisionQubits, +StateQubits, ?Circuit)
quantum_phase_estimation(Unitary, PrecQubits, StateQubits, Circuit) :-
    length(PrecQubits, M),
    %% Step 1: Hadamard on all precision qubits
    maplist([Q, h(Q)]>>true, PrecQubits, HGates),
    %% Step 2: Controlled-U^(2^k) operations
    numlist(0, M-1, Idxs),
    maplist([I, CGates]>>(
        nth0(I, PrecQubits, PQ),
        Reps is 2^I,
        controlled_unitary_reps(Unitary, PQ, StateQubits, Reps, CGates)
    ), Idxs, CUGatesList),
    flatten(CUGatesList, CUGates),
    %% Step 3: Inverse QFT on precision qubits
    inverse_qft_circuit(PrecQubits, IQFTGates),
    append(HGates, CUGates, Temp),
    append(Temp, IQFTGates, Circuit).

controlled_unitary_reps(U, Control, Targets, Reps, Gates) :-
    findall(controlled(U,[Control],Targets), between(1, Reps, _), Gates).

%% grover_oracle(+Predicate, ?Circuit)
grover_oracle(Pred, oracle(Pred)).

%% grover_diffusion(+Qubits, ?Circuit)
grover_diffusion(Qubits, Circuit) :-
    maplist([Q, h(Q)]>>true, Qubits, H1),
    maplist([Q, x(Q)]>>true, Qubits, X1),
    Qubits = [Q1|QRest],
    last(Qubits, QN),
    %% Multi-controlled Z equivalent
    maplist([Q, x(Q)]>>true, Qubits, X2),
    maplist([Q, h(Q)]>>true, Qubits, H2),
    MCZ = controlled(z(QN), QRest, [QN]),
    flatten([H1, X1, [MCZ], X2, H2], Circuit).

%% grover_iteration(+Oracle, +Diffusion, ?GroverOp)
grover_iteration(Oracle, Diffusion, Iteration) :-
    ( is_list(Oracle), is_list(Diffusion)
    -> append(Oracle, Diffusion, Iteration)
    ;  Iteration = grover_step(Oracle, Diffusion)
    ).
