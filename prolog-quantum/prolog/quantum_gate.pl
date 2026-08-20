%% quantum_gate.pl
%% Gate operations, validation, inverse, power, and user-defined gates.

:- module(quantum_gate, [
    gate_apply/3,
    gate_validate/1,
    gate_normalise/2,
    gate_inverse_gate/2,
    gate_power/3,
    gate_controlled/3,
    decompose_gate/3,
    gate_definition/3,
    define_gate/3,
    detect_recursive_definition/1
]).

:- use_module(quantum_complex).
:- use_module(quantum_matrix).
:- use_module(quantum_gate_registry).
:- use_module(quantum_errors).

:- dynamic user_gate_definition/3.

%% gate_normalise(+Gate, ?NormGate)
gate_normalise(cnot(C,T), cx(C,T)) :- !.
gate_normalise(toffoli(A,B,T), ccx(A,B,T)) :- !.
gate_normalise(fredkin(C,A,B), cswap(C,A,B)) :- !.
gate_normalise(phase(Theta,Q), p(Theta,Q)) :- !.
gate_normalise(cphase(Theta,C,T), cp(Theta,C,T)) :- !.
gate_normalise(c3x(A,B,C,T), mcx([A,B,C],T)) :- !.
gate_normalise(c4x(A,B,C,D,T), mcx([A,B,C,D],T)) :- !.
gate_normalise(u1(Theta,Q), p(Theta,Q)) :- !.
gate_normalise(u2(Phi,Lambda,Q), u(1.5707963267948966,Phi,Lambda,Q)) :- !.
gate_normalise(u3(Theta,Phi,Lambda,Q), u(Theta,Phi,Lambda,Q)) :- !.
gate_normalise(sqrt_x(Q), sx(Q)) :- !.
gate_normalise(sqrt_x_dg(Q), sxdg(Q)) :- !.
gate_normalise(G, G).

%% gate_validate(+Gate)
gate_validate(Gate) :-
    gate_normalise(Gate, NG),
    functor(NG, Name, _),
    ( quantum_gate_registry:is_registered_gate(Name)
    -> true
    ;  check_is_user_gate(Name, NG)
    ).

check_is_user_gate(Name, Gate) :-
    ( user_gate_definition(Name, _, _)
    -> true
    ;  format(atom(Msg), "Unknown gate ~w", [Name]),
       quantum_error(unknown_gate, Gate, Name, Msg)
    ).

%% gate_inverse_gate(+Gate, ?Inv)
gate_inverse_gate(Gate, Inv) :-
    functor(Gate, Name, _),
    ( quantum_gate_registry:gate_inverse(Name, InvName)
    -> ( atom(InvName) -> Inv =.. [InvName|Args], Gate =.. [_|Args]
       ;  Inv = InvName
       )
    ;  gate_inverse_from_matrix(Gate, Inv)
    ).
gate_inverse_gate(inverse(G), G) :- !.

gate_inverse_from_matrix(Gate, inverse(Gate)).

%% gate_power(+Gate, +Exp, ?Result)
gate_power(x(Q),   1/2, sx(Q))  :- !.
gate_power(z(Q),   1/4, t(Q))   :- !.
gate_power(z(Q),   1/2, s(Q))   :- !.
gate_power(Gate, Exp, power(Gate, Exp)).

%% gate_controlled(+Gate, +Controls, ?Controlled)
gate_controlled(x(T), [C], cx(C,T))   :- !.
gate_controlled(y(T), [C], cy(C,T))   :- !.
gate_controlled(z(T), [C], cz(C,T))   :- !.
gate_controlled(h(T), [C], ch(C,T))   :- !.
gate_controlled(s(T), [C], cs(C,T))   :- !.
gate_controlled(sdg(T),[C], csdg(C,T)) :- !.
gate_controlled(t(T), [C], ct(C,T))   :- !.
gate_controlled(tdg(T),[C], ctdg(C,T)) :- !.
gate_controlled(x(T), [C1,C2], ccx(C1,C2,T)) :- !.
gate_controlled(x(T), Cs, mcx(Cs,T))  :- !.
gate_controlled(Gate, Cs, controlled(Gate, Cs, Ts)) :-
    gate_qubit_args(Gate, Ts).

gate_qubit_args(Gate, Ts) :-
    Gate =.. [_|Args],
    include(atom, Args, Ts).

%% gate_apply(+Gate, +StateIn, ?StateOut)
%% Applies a single gate to a statevector.
gate_apply(Gate, StateIn, StateOut) :-
    gate_matrix_for(Gate, M),
    !,
    quantum_matrix:matrix_apply(M, StateIn, StateOut).

gate_apply(measure(Q,_), S, S) :- !.  % measurement handled by simulator
gate_apply(reset(_), S, S) :- !.
gate_apply(barrier(_), S, S) :- !.
gate_apply(delay(_,_), S, S) :- !.
gate_apply(global_phase(Phi), S, S2) :-
    !,
    quantum_complex:complex_exp(c(0,Phi), E),
    maplist([V,R]>>(quantum_complex:complex_mul(E,V,R)), S, S2).

%% gate_matrix_for(+Gate, ?M)
gate_matrix_for(i(_), M) :- quantum_gate_registry:gate_matrix(i, M), !.
gate_matrix_for(id(_), M) :- quantum_gate_registry:gate_matrix(id, M), !.
gate_matrix_for(x(_), M) :- quantum_gate_registry:gate_matrix(x, M), !.
gate_matrix_for(y(_), M) :- quantum_gate_registry:gate_matrix(y, M), !.
gate_matrix_for(z(_), M) :- quantum_gate_registry:gate_matrix(z, M), !.
gate_matrix_for(h(_), M) :- quantum_gate_registry:gate_matrix(h, M), !.
gate_matrix_for(s(_), M) :- quantum_gate_registry:gate_matrix(s, M), !.
gate_matrix_for(sdg(_), M) :- quantum_gate_registry:gate_matrix(sdg, M), !.
gate_matrix_for(t(_), M) :- quantum_gate_registry:gate_matrix(t, M), !.
gate_matrix_for(tdg(_), M) :- quantum_gate_registry:gate_matrix(tdg, M), !.
gate_matrix_for(sx(_), M) :- quantum_gate_registry:gate_matrix(sx, M), !.
gate_matrix_for(sxdg(_), M) :- quantum_gate_registry:gate_matrix(sxdg, M), !.
gate_matrix_for(rx(T,_), M) :- quantum_gate_registry:gate_matrix(rx(T), M), !.
gate_matrix_for(ry(T,_), M) :- quantum_gate_registry:gate_matrix(ry(T), M), !.
gate_matrix_for(rz(T,_), M) :- quantum_gate_registry:gate_matrix(rz(T), M), !.
gate_matrix_for(p(T,_), M) :- quantum_gate_registry:gate_matrix(p(T), M), !.
gate_matrix_for(u(Th,Ph,La,_), M) :- quantum_gate_registry:gate_matrix(u(Th,Ph,La), M), !.
gate_matrix_for(cx(_,_), M) :- quantum_gate_registry:gate_matrix(cx, M), !.
gate_matrix_for(cnot(_,_), M) :- quantum_gate_registry:gate_matrix(cx, M), !.
gate_matrix_for(cz(_,_), M) :- quantum_gate_registry:gate_matrix(cz, M), !.
gate_matrix_for(swap(_,_), M) :- quantum_gate_registry:gate_matrix(swap, M), !.
gate_matrix_for(ccx(_,_,_), M) :- quantum_gate_registry:gate_matrix(ccx, M), !.

%% decompose_gate(+Gate, +Basis, ?Decomposed)
decompose_gate(Gate, Basis, Decomposed) :-
    functor(Gate, Name, _),
    ( member(Name, Basis)
    -> Decomposed = [Gate]
    ;  decompose_to_basis(Gate, Basis, Decomposed)
    ).

decompose_to_basis(ccx(A,B,T), Basis, D) :-
    ( submember([h,t,tdg,cx], Basis)
    -> ccx_decomposition(A, B, T, D)
    ;  D = [ccx(A,B,T)]
    ).
decompose_to_basis(swap(A,B), _, D) :-
    D = [cx(A,B), cx(B,A), cx(A,B)].
decompose_to_basis(cswap(C,A,B), _, D) :-
    D = [cx(B,A), ccx(C,A,B), cx(B,A)].
decompose_to_basis(Gate, _, [Gate]).

ccx_decomposition(A, B, T, [
    h(T),
    cx(B,T), tdg(T),
    cx(A,T), t(T),
    cx(B,T), tdg(T),
    cx(A,T), t(B), t(T), h(T),
    cx(A,B), t(A), tdg(B),
    cx(A,B)
]).

submember(Required, Basis) :-
    maplist([R]>>(member(R, Basis)), Required).

%% define_gate(+Name, +Qubits, +Body)
define_gate(Name, Qubits, Body) :-
    detect_recursive_definition(Name),
    retractall(user_gate_definition(Name, _, _)),
    assertz(user_gate_definition(Name, Qubits, Body)).

detect_recursive_definition(Name) :-
    ( user_gate_definition(Name, _, _)
    -> true  % replacing is allowed
    ;  true
    ).
    % Full recursive cycle detection would require graph analysis.

%% gate_definition/3 - user-defined gates
gate_definition(Name, Qubits, Body) :-
    user_gate_definition(Name, Qubits, Body).
