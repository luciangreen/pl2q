%% quantum_gate_registry.pl
%% Central gate registry for all quantum gates.

:- module(quantum_gate_registry, [
    quantum_gate/5,
    gate_property/2,
    all_quantum_gates/1,
    register_quantum_gate/2,
    gate_matrix/2,
    gate_inverse/2,
    gate_qubits/2,
    gate_definition/3,
    is_registered_gate/1
]).

:- use_module(quantum_complex).
:- use_module(quantum_matrix).

:- dynamic quantum_gate/5.
:- dynamic gate_definition/3.
:- dynamic user_gate/2.

%% quantum_gate(Name, Arity, Parameters, Properties, MatrixOrDefinition)

%% ===== Identity and Pauli Gates =====

quantum_gate(i,   1, [],      [unitary,hermitian,pauli,self_inverse,diagonal], id_matrix).
quantum_gate(id,  1, [],      [unitary,hermitian,pauli,self_inverse,diagonal], id_matrix).
quantum_gate(x,   1, [],      [unitary,hermitian,pauli,self_inverse,clifford], x_matrix).
quantum_gate(y,   1, [],      [unitary,hermitian,pauli,self_inverse,clifford], y_matrix).
quantum_gate(z,   1, [],      [unitary,hermitian,pauli,self_inverse,clifford,diagonal], z_matrix).

%% ===== Hadamard =====

quantum_gate(h,   1, [],      [unitary,hermitian,self_inverse,clifford], h_matrix).

%% ===== Phase Gates =====

quantum_gate(s,   1, [],      [unitary,clifford,diagonal,phase],   s_matrix).
quantum_gate(sdg, 1, [],      [unitary,clifford,diagonal,phase],   sdg_matrix).
quantum_gate(t,   1, [],      [unitary,diagonal,phase],             t_matrix).
quantum_gate(tdg, 1, [],      [unitary,diagonal,phase],             tdg_matrix).
quantum_gate(p,   1, [theta], [unitary,diagonal,phase,parameterised], p_matrix).
quantum_gate(phase, 1, [theta], [unitary,diagonal,phase,parameterised], p_matrix).

%% ===== Square-Root Gates =====

quantum_gate(sx,   1, [],    [unitary,clifford], sx_matrix).
quantum_gate(sxdg, 1, [],    [unitary,clifford], sxdg_matrix).

%% ===== Rotation Gates =====

quantum_gate(rx,  1, [theta], [unitary,rotation,parameterised], rx_matrix).
quantum_gate(ry,  1, [theta], [unitary,rotation,parameterised], ry_matrix).
quantum_gate(rz,  1, [theta], [unitary,diagonal,rotation,parameterised], rz_matrix).
quantum_gate(r,   1, [theta,phi], [unitary,rotation,parameterised], r_matrix).

%% ===== General Single-Qubit Unitary =====

quantum_gate(u,   1, [theta,phi,lambda], [unitary,parameterised], u_matrix).
quantum_gate(u1,  1, [theta],            [unitary,parameterised,diagonal], p_matrix).
quantum_gate(u2,  1, [phi,lambda],       [unitary,parameterised], u2_matrix).
quantum_gate(u3,  1, [theta,phi,lambda], [unitary,parameterised], u_matrix).

%% ===== Controlled Pauli/Hadamard =====

quantum_gate(cx,   2, [], [unitary,controlled,entangling,clifford,self_inverse], cx_matrix).
quantum_gate(cnot, 2, [], [unitary,controlled,entangling,clifford,self_inverse], cx_matrix).
quantum_gate(cy,   2, [], [unitary,controlled,entangling,clifford], cy_matrix).
quantum_gate(cz,   2, [], [unitary,controlled,entangling,clifford,diagonal,self_inverse], cz_matrix).
quantum_gate(ch,   2, [], [unitary,controlled,entangling,clifford], ch_matrix).

%% ===== Controlled Phase Gates =====

quantum_gate(cs,    2, [],      [unitary,controlled,entangling,clifford,diagonal], cs_matrix).
quantum_gate(csdg,  2, [],      [unitary,controlled,entangling,clifford,diagonal], csdg_matrix).
quantum_gate(ct,    2, [],      [unitary,controlled,entangling,diagonal], ct_matrix).
quantum_gate(ctdg,  2, [],      [unitary,controlled,entangling,diagonal], ctdg_matrix).
quantum_gate(cp,    2, [theta], [unitary,controlled,entangling,diagonal,parameterised], cp_matrix).
quantum_gate(cphase,2, [theta], [unitary,controlled,entangling,diagonal,parameterised], cp_matrix).

%% ===== Controlled Rotation Gates =====

quantum_gate(crx,  2, [theta],               [unitary,controlled,rotation,parameterised,entangling], crx_matrix).
quantum_gate(cry,  2, [theta],               [unitary,controlled,rotation,parameterised,entangling], cry_matrix).
quantum_gate(crz,  2, [theta],               [unitary,controlled,diagonal,rotation,parameterised,entangling], crz_matrix).
quantum_gate(cu,   2, [theta,phi,lambda,gamma],[unitary,controlled,parameterised,entangling], cu_matrix).

%% ===== SWAP Family =====

quantum_gate(swap,    2, [], [unitary,permutation,self_inverse,entangling], swap_matrix).
quantum_gate(iswap,   2, [], [unitary,entangling], iswap_matrix).
quantum_gate(iswap_dg,2, [], [unitary,entangling], iswap_dg_matrix).
quantum_gate(dcx,     2, [], [unitary,entangling], dcx_matrix).

%% ===== Three-Qubit Gates =====

quantum_gate(ccx,     3, [], [unitary,controlled,multi_controlled,entangling,clifford,self_inverse], ccx_matrix).
quantum_gate(toffoli, 3, [], [unitary,controlled,multi_controlled,entangling,clifford,self_inverse], ccx_matrix).
quantum_gate(cswap,   3, [], [unitary,controlled,multi_controlled,entangling,self_inverse],   cswap_matrix).
quantum_gate(fredkin, 3, [], [unitary,controlled,multi_controlled,entangling,self_inverse],   cswap_matrix).

%% ===== Relative Phase Toffoli =====

quantum_gate(rccx,  3, [], [unitary,controlled], rccx_matrix).
quantum_gate(rc3x,  4, [], [unitary,controlled], rc3x_matrix).

%% ===== Interaction Gates =====

quantum_gate(rxx,         2, [theta], [unitary,rotation,parameterised,entangling], rxx_matrix).
quantum_gate(ryy,         2, [theta], [unitary,rotation,parameterised,entangling], ryy_matrix).
quantum_gate(rzz,         2, [theta], [unitary,diagonal,rotation,parameterised,entangling], rzz_matrix).
quantum_gate(rzx,         2, [theta], [unitary,rotation,parameterised,entangling], rzx_matrix).
quantum_gate(xx_plus_yy,  2, [theta,beta],[unitary,rotation,parameterised,entangling], xx_plus_yy_matrix).
quantum_gate(xx_minus_yy, 2, [theta,beta],[unitary,rotation,parameterised,entangling], xx_minus_yy_matrix).

%% ===== Hardware-Specific =====

quantum_gate(ecr, 2, [], [unitary,native,entangling], ecr_matrix).

%% ===== Measurement, Reset, Barrier =====
quantum_gate(measure, 1, [cbit], [non_unitary,measurement], none).
quantum_gate(reset,   1, [],     [non_unitary,reset], none).
quantum_gate(barrier, 0, [qubits],[scheduling_directive], none).

%% ===== gate_property/2 =====
gate_property(Name, Prop) :-
    ( quantum_gate(Name, _, _, Props, _)
    -> member(Prop, Props)
    ;  fail
    ).

%% ===== gate_matrix/2 =====
%% Numerical matrices (computed via helper predicates)

gate_matrix(i,  [[c(1,0),c(0,0)],[c(0,0),c(1,0)]]).
gate_matrix(id, [[c(1,0),c(0,0)],[c(0,0),c(1,0)]]).
gate_matrix(x,  [[c(0,0),c(1,0)],[c(1,0),c(0,0)]]).
gate_matrix(y,  [[c(0,0),c(0,-1)],[c(0,1),c(0,0)]]).
gate_matrix(z,  [[c(1,0),c(0,0)],[c(0,0),c(-1,0)]]).

gate_matrix(h, M) :-
    H is 1/sqrt(2),
    M = [[c(H,0),c(H,0)],[c(H,0),c(-H,0)]].  % note: h|1> = (|0>-|1>)/sqrt(2) so [H,-H]

gate_matrix(s,   [[c(1,0),c(0,0)],[c(0,0),c(0,1)]]).
gate_matrix(sdg, [[c(1,0),c(0,0)],[c(0,0),c(0,-1)]]).
gate_matrix(t,   M) :- V is 1/sqrt(2), M = [[c(1,0),c(0,0)],[c(0,0),c(V,V)]].
gate_matrix(tdg, M) :- V is 1/sqrt(2), M = [[c(1,0),c(0,0)],[c(0,0),c(V,-V)]].

gate_matrix(sx,  M) :- M = [[c(0.5,0.5),c(0.5,-0.5)],[c(0.5,-0.5),c(0.5,0.5)]].
gate_matrix(sxdg,M) :- M = [[c(0.5,-0.5),c(0.5,0.5)],[c(0.5,0.5),c(0.5,-0.5)]].

gate_matrix(p(Theta), M) :-
    E is exp(1), C is cos(Theta), S is sin(Theta),
    _ = E,
    M = [[c(1,0),c(0,0)],[c(0,0),c(C,S)]].

gate_matrix(rx(Theta), M) :-
    C is cos(Theta/2), S is sin(Theta/2),
    M = [[c(C,0),c(0,-S)],[c(0,-S),c(C,0)]].

gate_matrix(ry(Theta), M) :-
    C is cos(Theta/2), S is sin(Theta/2),
    M = [[c(C,0),c(-S,0)],[c(S,0),c(C,0)]].

gate_matrix(rz(Theta), M) :-
    CR is cos(Theta/2), SR is sin(Theta/2),
    M = [[c(CR,-SR),c(0,0)],[c(0,0),c(CR,SR)]].

gate_matrix(u(Theta,Phi,Lambda), M) :-
    C is cos(Theta/2), S is sin(Theta/2),
    CosP is cos(Phi), SinP is sin(Phi),
    CosL is cos(Lambda), SinL is sin(Lambda),
    CosML is cos(-Lambda), SinML is sin(-Lambda),
    M = [[c(C,0),
          c(S*(-CosML),S*(-SinML))],
         [c(S*CosP, S*SinP),
          c(C*cos(Phi+Lambda), C*sin(Phi+Lambda))]].

gate_matrix(cx, [[c(1,0),c(0,0),c(0,0),c(0,0)],
                  [c(0,0),c(1,0),c(0,0),c(0,0)],
                  [c(0,0),c(0,0),c(0,0),c(1,0)],
                  [c(0,0),c(0,0),c(1,0),c(0,0)]]).

gate_matrix(cz, [[c(1,0),c(0,0),c(0,0),c(0,0)],
                  [c(0,0),c(1,0),c(0,0),c(0,0)],
                  [c(0,0),c(0,0),c(1,0),c(0,0)],
                  [c(0,0),c(0,0),c(0,0),c(-1,0)]]).

gate_matrix(swap, [[c(1,0),c(0,0),c(0,0),c(0,0)],
                    [c(0,0),c(0,0),c(1,0),c(0,0)],
                    [c(0,0),c(1,0),c(0,0),c(0,0)],
                    [c(0,0),c(0,0),c(0,0),c(1,0)]]).

gate_matrix(ccx, M) :-
    M = [
        [c(1,0),c(0,0),c(0,0),c(0,0),c(0,0),c(0,0),c(0,0),c(0,0)],
        [c(0,0),c(1,0),c(0,0),c(0,0),c(0,0),c(0,0),c(0,0),c(0,0)],
        [c(0,0),c(0,0),c(1,0),c(0,0),c(0,0),c(0,0),c(0,0),c(0,0)],
        [c(0,0),c(0,0),c(0,0),c(1,0),c(0,0),c(0,0),c(0,0),c(0,0)],
        [c(0,0),c(0,0),c(0,0),c(0,0),c(1,0),c(0,0),c(0,0),c(0,0)],
        [c(0,0),c(0,0),c(0,0),c(0,0),c(0,0),c(1,0),c(0,0),c(0,0)],
        [c(0,0),c(0,0),c(0,0),c(0,0),c(0,0),c(0,0),c(0,0),c(1,0)],
        [c(0,0),c(0,0),c(0,0),c(0,0),c(0,0),c(0,0),c(1,0),c(0,0)]
    ].

%% ===== gate_inverse/2 =====
gate_inverse(x, x).
gate_inverse(y, y).
gate_inverse(z, z).
gate_inverse(h, h).
gate_inverse(s, sdg).
gate_inverse(sdg, s).
gate_inverse(t, tdg).
gate_inverse(tdg, t).
gate_inverse(sx, sxdg).
gate_inverse(sxdg, sx).
gate_inverse(cx, cx).
gate_inverse(cz, cz).
gate_inverse(swap, swap).
gate_inverse(ccx, ccx).
gate_inverse(cswap, cswap).
gate_inverse(rx(Theta), rx(NTheta)) :- NTheta is -Theta.
gate_inverse(ry(Theta), ry(NTheta)) :- NTheta is -Theta.
gate_inverse(rz(Theta), rz(NTheta)) :- NTheta is -Theta.
gate_inverse(p(Theta), p(NTheta)) :- NTheta is -Theta.
gate_inverse(u(Theta,Phi,Lambda), u(NTheta, NLambda, NPhi)) :-
    NTheta is -Theta, NLambda is -Lambda, NPhi is -Phi.
gate_inverse(iswap, iswap_dg).
gate_inverse(iswap_dg, iswap).
gate_inverse(i, i).
gate_inverse(id, id).
gate_inverse(inverse(G), G).

%% ===== gate_qubits/2 =====
gate_qubits(i,   1).
gate_qubits(id,  1).
gate_qubits(x,   1).
gate_qubits(y,   1).
gate_qubits(z,   1).
gate_qubits(h,   1).
gate_qubits(s,   1).
gate_qubits(sdg, 1).
gate_qubits(t,   1).
gate_qubits(tdg, 1).
gate_qubits(sx,  1).
gate_qubits(sxdg,1).
gate_qubits(rx(_),1).
gate_qubits(ry(_),1).
gate_qubits(rz(_),1).
gate_qubits(p(_), 1).
gate_qubits(u(_,_,_), 1).
gate_qubits(cx,  2).
gate_qubits(cnot,2).
gate_qubits(cy,  2).
gate_qubits(cz,  2).
gate_qubits(ch,  2).
gate_qubits(swap,2).
gate_qubits(iswap,2).
gate_qubits(iswap_dg,2).
gate_qubits(dcx, 2).
gate_qubits(ccx, 3).
gate_qubits(toffoli,3).
gate_qubits(cswap,3).
gate_qubits(fredkin,3).
gate_qubits(rccx,3).
gate_qubits(rc3x,4).
gate_qubits(mcx(Cs,_), N) :- length(Cs, NC), N is NC + 1.

%% ===== all_quantum_gates/1 =====
all_quantum_gates(Gates) :-
    findall(Name/Arity, quantum_gate(Name, Arity, _, _, _), Gates).

%% ===== register_quantum_gate/2 =====
register_quantum_gate(Name, Definition) :-
    ( quantum_gate(Name, _, _, _, _)
    -> true  % already registered; allow re-registration
    ;  true
    ),
    assertz(user_gate(Name, Definition)).

%% ===== is_registered_gate/1 =====
is_registered_gate(Name) :-
    quantum_gate(Name, _, _, _, _).
is_registered_gate(Name) :-
    user_gate(Name, _).

%% Placeholder matrix identifiers (the actual computation is in gate_matrix/2 above)
id_matrix.
x_matrix.
y_matrix.
z_matrix.
h_matrix.
s_matrix.
sdg_matrix.
t_matrix.
tdg_matrix.
p_matrix.
sx_matrix.
sxdg_matrix.
rx_matrix.
ry_matrix.
rz_matrix.
r_matrix.
u_matrix.
u2_matrix.
cx_matrix.
cy_matrix.
cz_matrix.
ch_matrix.
cs_matrix.
csdg_matrix.
ct_matrix.
ctdg_matrix.
cp_matrix.
crx_matrix.
cry_matrix.
crz_matrix.
cu_matrix.
swap_matrix.
iswap_matrix.
iswap_dg_matrix.
dcx_matrix.
ccx_matrix.
cswap_matrix.
rccx_matrix.
rc3x_matrix.
rxx_matrix.
ryy_matrix.
rzz_matrix.
rzx_matrix.
xx_plus_yy_matrix.
xx_minus_yy_matrix.
ecr_matrix.
