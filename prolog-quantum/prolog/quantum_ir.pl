%% quantum_ir.pl
%% Canonical Prolog Quantum Intermediate Representation.

:- module(quantum_ir, [
    circuit/3,
    make_circuit/4,
    circuit_qubits/2,
    circuit_cbits/2,
    circuit_gates/2,
    circuit_add_gate/3,
    circuit_gate_count/2,
    circuit_qubit_count/2,
    circuit_cbit_count/2,
    normalise_gate/2,
    validate_circuit/1,
    validate_gate/2,
    circuit_qubits_used/2,
    circuit_append/3
]).

:- use_module(quantum_errors).

%% circuit(Qubits, Cbits, Gates) - the canonical IR term

%% make_circuit(+Qubits, +Cbits, +Gates, ?Circuit)
make_circuit(Qubits, Cbits, Gates, circuit(Qubits, Cbits, Gates)).

circuit_qubits(circuit(Q,_,_), Q).
circuit_cbits(circuit(_,C,_), C).
circuit_gates(circuit(_,_,G), G).

circuit_add_gate(circuit(Q,C,G), Gate, circuit(Q,C,NG)) :-
    append(G, [Gate], NG).

circuit_gate_count(circuit(_,_,G), N) :- length(G, N).
circuit_qubit_count(circuit(Q,_,_), N) :- length(Q, N).
circuit_cbit_count(circuit(_,C,_), N) :- length(C, N).

%% circuit_qubits_used(+Circuit, ?Qubits): collect all qubit names used in gates
circuit_qubits_used(circuit(_,_,Gates), Qubits) :-
    maplist(gate_qubits_list, Gates, QLists),
    flatten(QLists, AllQ),
    list_to_set(AllQ, Qubits).

gate_qubits_list(Gate, Qs) :-
    gate_operands(Gate, Qs), !.
gate_qubits_list(_, []).

%% gate_operands(+Gate, ?Qubits)
gate_operands(h(Q), [Q]).
gate_operands(x(Q), [Q]).
gate_operands(y(Q), [Q]).
gate_operands(z(Q), [Q]).
gate_operands(i(Q), [Q]).
gate_operands(id(Q), [Q]).
gate_operands(s(Q), [Q]).
gate_operands(sdg(Q), [Q]).
gate_operands(t(Q), [Q]).
gate_operands(tdg(Q), [Q]).
gate_operands(sx(Q), [Q]).
gate_operands(sxdg(Q), [Q]).
gate_operands(sqrt_x(Q), [Q]).
gate_operands(sqrt_x_dg(Q), [Q]).
gate_operands(p(_,Q), [Q]).
gate_operands(phase(_,Q), [Q]).
gate_operands(rx(_,Q), [Q]).
gate_operands(ry(_,Q), [Q]).
gate_operands(rz(_,Q), [Q]).
gate_operands(r(_,_,Q), [Q]).
gate_operands(u(_,_,_,Q), [Q]).
gate_operands(u1(_,Q), [Q]).
gate_operands(u2(_,_,Q), [Q]).
gate_operands(u3(_,_,_,Q), [Q]).
gate_operands(cx(C,T), [C,T]).
gate_operands(cnot(C,T), [C,T]).
gate_operands(cy(C,T), [C,T]).
gate_operands(cz(C,T), [C,T]).
gate_operands(ch(C,T), [C,T]).
gate_operands(cs(C,T), [C,T]).
gate_operands(csdg(C,T), [C,T]).
gate_operands(ct(C,T), [C,T]).
gate_operands(ctdg(C,T), [C,T]).
gate_operands(cp(_,C,T), [C,T]).
gate_operands(cphase(_,C,T), [C,T]).
gate_operands(crx(_,C,T), [C,T]).
gate_operands(cry(_,C,T), [C,T]).
gate_operands(crz(_,C,T), [C,T]).
gate_operands(cu(_,_,_,_,C,T), [C,T]).
gate_operands(swap(A,B), [A,B]).
gate_operands(iswap(A,B), [A,B]).
gate_operands(iswap_dg(A,B), [A,B]).
gate_operands(dcx(A,B), [A,B]).
gate_operands(ccx(A,B,T), [A,B,T]).
gate_operands(toffoli(A,B,T), [A,B,T]).
gate_operands(cswap(C,A,B), [C,A,B]).
gate_operands(fredkin(C,A,B), [C,A,B]).
gate_operands(rccx(A,B,T), [A,B,T]).
gate_operands(rc3x(A,B,C,T), [A,B,C,T]).
gate_operands(mcx(Cs,T), Qs) :- flatten([Cs,[T]], Qs).
gate_operands(c3x(A,B,C,T), [A,B,C,T]).
gate_operands(c4x(A,B,C,D,T), [A,B,C,D,T]).
gate_operands(rxx(_,A,B), [A,B]).
gate_operands(ryy(_,A,B), [A,B]).
gate_operands(rzz(_,A,B), [A,B]).
gate_operands(rzx(_,A,B), [A,B]).
gate_operands(xx_plus_yy(_,_,A,B), [A,B]).
gate_operands(xx_minus_yy(_,_,A,B), [A,B]).
gate_operands(ecr(A,B), [A,B]).
gate_operands(measure(Q,_), [Q]).
gate_operands(reset(Q), [Q]).
gate_operands(barrier(Qs), Qs).
gate_operands(delay(_,Q), [Q]).
gate_operands(if_bit(_,_,G), Qs) :- gate_operands(G, Qs).
gate_operands(controlled(G,Cs,Ts), Qs) :-
    ( is_list(G) -> GQs = [] ; gate_operands(G, GQs) ; GQs = [] ),
    flatten([Cs, Ts, GQs], Qs).
gate_operands(mcgate(_,Cs,Ts), Qs) :- flatten([Cs,Ts], Qs).
gate_operands(unitary(_,Qs), Qs).
gate_operands(inverse(G), Qs) :- gate_operands(G, Qs).
gate_operands(power(G,_), Qs) :- gate_operands(G, Qs).
gate_operands(global_phase(_), []).
gate_operands(native_gate(_,_,Qs), Qs).
gate_operands(qchoice(_), []).

%% normalise_gate(+G, ?NG): resolve aliases
normalise_gate(cnot(C,T), cx(C,T)) :- !.
normalise_gate(toffoli(A,B,T), ccx(A,B,T)) :- !.
normalise_gate(fredkin(C,A,B), cswap(C,A,B)) :- !.
normalise_gate(sqrt_x(Q), sx(Q)) :- !.
normalise_gate(sqrt_x_dg(Q), sxdg(Q)) :- !.
normalise_gate(c3x(A,B,C,T), mcx([A,B,C],T)) :- !.
normalise_gate(c4x(A,B,C,D,T), mcx([A,B,C,D],T)) :- !.
normalise_gate(phase(Theta,Q), p(Theta,Q)) :- !.
normalise_gate(cphase(Theta,C,T), cp(Theta,C,T)) :- !.
normalise_gate(u1(Theta,Q), p(Theta,Q)) :- !.
normalise_gate(u2(Phi,Lambda,Q), u(pi/2,Phi,Lambda,Q)) :- !.
normalise_gate(u3(Theta,Phi,Lambda,Q), u(Theta,Phi,Lambda,Q)) :- !.
normalise_gate(G, G).

%% validate_circuit(+Circuit)
validate_circuit(circuit(Qubits, Cbits, Gates)) :-
    is_list(Qubits),
    is_list(Cbits),
    is_list(Gates),
    list_to_set(Qubits, Qubits),  % no duplicate qubit names
    maplist(validate_gate(Qubits), Gates).

%% validate_gate(+Qubits, +Gate)
validate_gate(Qubits, Gate) :-
    gate_operands(Gate, GateQubits),
    maplist([Q]>>(
        ( \+ atom(Q) -> true  % could be a variable/expression
        ; ( member(Q, Qubits) -> true
          ; quantum_error(unknown_qubit, Gate, Q, "Qubit not declared in circuit")
          )
        )
    ), GateQubits),
    % check no qubit appears twice as target unless allowed
    ( has_duplicate_targets(Gate)
    -> quantum_error(duplicate_target, Gate, Gate, "Qubit appears as both control and target")
    ;  true
    ).

has_duplicate_targets(cx(C,T)) :- C == T.
has_duplicate_targets(cy(C,T)) :- C == T.
has_duplicate_targets(cz(C,T)) :- C == T.
has_duplicate_targets(ccx(A,B,T)) :- ( A == T ; B == T ; A == B ).
has_duplicate_targets(controlled(_,Cs,Ts)) :-
    flatten([Cs,Ts], All),
    \+ ( list_to_set(All, Set), length(All, L), length(Set, L) ).

%% circuit_append(+C1, +C2, ?C)
circuit_append(circuit(Q,C,G1), circuit(Q,C,G2), circuit(Q,C,G)) :-
    append(G1, G2, G).
