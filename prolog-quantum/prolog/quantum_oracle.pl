%% quantum_oracle.pl
%% Quantum oracle construction and Prolog-to-quantum conversion.

:- module(quantum_oracle, [
    predicate_to_oracle/3,
    quantum_to_prolog/2,
    inspect_symbolically/2,
    hybrid/2
]).

:- use_module(quantum_errors).
:- use_module(quantum_reversible).

%% predicate_to_oracle(+Pred, +Domain, ?Circuit)
predicate_to_oracle(Pred, Domain, Circuit) :-
    quantum_reversible:predicate_to_oracle(Pred, Domain, Circuit).

%% quantum_to_prolog(+Circuit, ?PrologRepresentation)
quantum_to_prolog(circuit(Qubits,Cbits,Gates), PrologCode) :-
    gates_to_prolog_calls(Gates, Calls),
    format(atom(PrologCode),
           ":- use_module(prolog_quantum).\nrun :-\n~w\n",
           [Calls]).
quantum_to_prolog(Gates, PrologCode) :-
    is_list(Gates),
    gates_to_prolog_calls(Gates, Calls),
    PrologCode = Calls.

gates_to_prolog_calls([], '') :- !.
gates_to_prolog_calls(Gates, Code) :-
    maplist(gate_to_prolog_call, Gates, Lines),
    atomic_list_concat(Lines, ',\n    ', Code).

gate_to_prolog_call(h(Q), Call) :- format(atom(Call), "q_h(~w)", [Q]).
gate_to_prolog_call(x(Q), Call) :- format(atom(Call), "q_x(~w)", [Q]).
gate_to_prolog_call(y(Q), Call) :- format(atom(Call), "q_y(~w)", [Q]).
gate_to_prolog_call(z(Q), Call) :- format(atom(Call), "q_z(~w)", [Q]).
gate_to_prolog_call(cx(C,T), Call) :- format(atom(Call), "q_cx(~w,~w)", [C,T]).
gate_to_prolog_call(measure(Q,C), Call) :- format(atom(Call), "q_measure(~w,~w)", [Q,C]).
gate_to_prolog_call(rx(T,Q), Call) :- format(atom(Call), "q_rx(~w,~w)", [T,Q]).
gate_to_prolog_call(ry(T,Q), Call) :- format(atom(Call), "q_ry(~w,~w)", [T,Q]).
gate_to_prolog_call(rz(T,Q), Call) :- format(atom(Call), "q_rz(~w,~w)", [T,Q]).
gate_to_prolog_call(Gate, Call) :-
    format(atom(Call), "q_gate(~w)", [Gate]).

%% inspect_symbolically(+State, ?Description)
%% Symbolic inspection of statevector (does NOT collapse - only valid in simulation)
inspect_symbolically(State, desc(State)) :-
    is_list(State),
    !.
inspect_symbolically(circuit(_,_,_) = State, desc(State)) :- !.
inspect_symbolically(X, desc(X)).

%% hybrid(+Program, ?Analysis)
hybrid(hybrid(Steps), analysis(Steps)) :-
    maplist(analyse_hybrid_step, Steps, _).

analyse_hybrid_step(classical(Goal), classical(Goal)) :- !.
analyse_hybrid_step(quantum(Circuit), quantum(Circuit)) :- !.
analyse_hybrid_step(measurement(R), measurement(R)) :- !.
analyse_hybrid_step(Step, unknown(Step)).
