%% quantum_reversible.pl
%% Reversibility analysis for Prolog predicates.

:- module(quantum_reversible, [
    reversibility_analysis/2,
    is_reversible/1,
    prolog_to_quantum/3,
    predicate_to_oracle/3,
    analyse_predicate/3,
    qchoice/1,
    ancilla/1,
    uncompute/2
]).

:- use_module(quantum_errors).

%% Reversibility categories
%% reversible | injective | many_to_one | nondeterministic | effectful | unknown

%% reversibility_analysis(+Goal, ?Analysis)
reversibility_analysis(Goal, Analysis) :-
    ( catch(analyse_goal(Goal, Analysis), _, Analysis = unknown)
    -> true
    ;  Analysis = unknown
    ).

analyse_goal(Goal, reversible) :-
    is_pure_structural(Goal), !.
analyse_goal(_+_,   reversible) :- !.  % arithmetic - reversible in principle
analyse_goal(_-_,   reversible) :- !.
analyse_goal(_*_,   reversible) :- !.
analyse_goal(xor(_,_,_), reversible) :- !.
analyse_goal(not_gate(_,_), reversible) :- !.
analyse_goal(Goal, effectful) :-
    functor(Goal, Name, _),
    member(Name, [write, nl, read, assert, retract, format, open, close]), !.
analyse_goal(Goal, nondeterministic) :-
    functor(Goal, Name, Arity),
    predicate_property(Goal, nondeterministic), !.
analyse_goal(Goal, many_to_one) :-
    functor(Goal, Name, Arity),
    member(Name/Arity, [is/2, =:=/2, </2, >/2, =</2, >=/2]), !.
analyse_goal(_, unknown).

is_pure_structural(A = B) :- !.
is_pure_structural(A \= B) :- !.
is_pure_structural(true) :- !.
is_pure_structural(false) :- !.

%% is_reversible(+Goal)
is_reversible(Goal) :-
    reversibility_analysis(Goal, Analysis),
    member(Analysis, [reversible, injective]).

%% prolog_to_quantum(+PrologGoal, +Options, ?Circuit)
prolog_to_quantum(Goal, Options, Circuit) :-
    reversibility_analysis(Goal, Analysis),
    ( Analysis = reversible
    -> convert_reversible_to_quantum(Goal, Options, Circuit)
    ; Analysis = effectful
    -> quantum_error(effectful_predicate, Goal, Goal,
                    "Effectful predicate cannot be converted to quantum circuit")
    ; Analysis = many_to_one
    -> convert_with_ancilla(Goal, Options, Circuit)
    ; Analysis = nondeterministic
    -> convert_nondeterministic(Goal, Options, Circuit)
    ;  Circuit = unsupported(cannot_convert(Goal, Analysis))
    ).

convert_reversible_to_quantum(X xor Y, _, circuit([X,Y,Out],[],[cx(X,Out), cx(Y,Out)])) :- !.
convert_reversible_to_quantum(not(X), _, circuit([X],[],[x(X)])) :- !.
convert_reversible_to_quantum(Goal, _, unsupported(Goal)).

convert_with_ancilla(Goal, Options, Circuit) :-
    %% Add ancilla output to make reversible
    functor(Goal, Name, Arity),
    format(atom(AncillaName), "anc_~w", [Name]),
    Circuit = oracle_with_ancilla(Goal, AncillaName).

convert_nondeterministic(Goal, Options, Circuit) :-
    %% Check if finite domain - could become superposition oracle
    Circuit = superposition_oracle(Goal).

%% predicate_to_oracle(+Predicate, +Domain, ?OracleCircuit)
predicate_to_oracle(Pred, Domain, OracleCircuit) :-
    functor(Pred, Name, Arity),
    ( is_finite_boolean_function(Pred, Domain)
    -> build_boolean_oracle(Pred, Domain, OracleCircuit)
    ;  quantum_error(non_boolean_oracle, Pred, Pred,
                    "Cannot convert non-boolean predicate to quantum oracle")
    ).

is_finite_boolean_function(Pred, Domain) :-
    is_list(Domain),
    maplist([D]>>(atom(D) ; D = bit), Domain).

build_boolean_oracle(Pred, Domain, circuit(Qubits, [ancilla], Gates)) :-
    length(Domain, N),
    numlist(1, N, Idxs),
    maplist([I, Q]>>(format(atom(Q), "q~w", [I])), Idxs, Qubits),
    Gates = [oracle_gate(Pred, Qubits, ancilla)].

%% qchoice/1 - quantum superposition choice
qchoice(Choices) :-
    ( is_list(Choices) -> true
    ;  quantum_error(invalid_qchoice, qchoice, Choices,
                    "qchoice requires a list of amplitude/probability alternatives")
    ).

%% ancilla(+A): declare ancilla qubit
ancilla(_).

%% uncompute(+ComputeGates, ?CircuitWithUncompute)
uncompute(ComputeGates, CircuitWithUncompute) :-
    reverse(ComputeGates, RevGates),
    maplist([G, InvG]>>(invert_gate_for_uncompute(G, InvG)), RevGates, InvGates),
    append(ComputeGates, InvGates, CircuitWithUncompute).

invert_gate_for_uncompute(h(Q), h(Q)) :- !.
invert_gate_for_uncompute(cx(C,T), cx(C,T)) :- !.
invert_gate_for_uncompute(x(Q), x(Q)) :- !.
invert_gate_for_uncompute(t(Q), tdg(Q)) :- !.
invert_gate_for_uncompute(tdg(Q), t(Q)) :- !.
invert_gate_for_uncompute(s(Q), sdg(Q)) :- !.
invert_gate_for_uncompute(sdg(Q), s(Q)) :- !.
invert_gate_for_uncompute(rx(T,Q), rx(NT,Q)) :- NT is -T, !.
invert_gate_for_uncompute(ry(T,Q), ry(NT,Q)) :- NT is -T, !.
invert_gate_for_uncompute(rz(T,Q), rz(NT,Q)) :- NT is -T, !.
invert_gate_for_uncompute(G, inverse(G)).

%% analyse_predicate(+Pred, +Options, ?Analysis)
analyse_predicate(Pred, _Options, Analysis) :-
    reversibility_analysis(Pred, RevAnalysis),
    functor(Pred, _Name, Arity),
    Analysis = analysis(
        predicate(Pred),
        reversibility(RevAnalysis),
        arity(Arity),
        quantum_convertible(RevAnalysis \= effectful)
    ).
