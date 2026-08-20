%% quantum_optimise.pl
%% Circuit optimisation passes.

:- module(quantum_optimise, [
    quantum_optimise/3,
    optimise_circuit/3,
    cancel_inverses/2,
    remove_identities/2,
    combine_rotations/2,
    equivalent_quantum_circuits/3,
    circuit_metrics/2,
    entanglement_graph/2,
    dependency_dag/2,
    circuit_layers/2
]).

:- use_module(quantum_gate_registry).
:- use_module(quantum_gate).
:- use_module(quantum_ir).

%% quantum_optimise(+Circuit, +Options, ?Optimised)
quantum_optimise(circuit(Q,C,Gates), Options, circuit(Q,C,OptGates)) :-
    ( member(ignore_barriers(true), Options) -> true ; true ),
    optimise_passes(Gates, OptGates).

optimise_passes(Gates, Result) :-
    cancel_inverses(Gates, G1),
    remove_identities(G1, G2),
    combine_rotations(G2, G3),
    remove_redundant_swaps(G3, Result).

%% cancel_inverses(+Gates, ?Optimised)
%% Cancels adjacent gate pairs that are each other's inverse (e.g., x x = [], h h = [])
cancel_inverses([], []) :- !.
cancel_inverses([G], [G]) :- !.
cancel_inverses([G1,G2|Rest], Result) :-
    ( gates_cancel(G1, G2)
    -> cancel_inverses(Rest, Result)
    ;  cancel_inverses([G2|Rest], RestOpt),
       Result = [G1|RestOpt]
    ).

gates_cancel(G1, G2) :-
    functor(G1, N1, _),
    functor(G2, N2, _),
    quantum_gate_registry:gate_inverse(N1, InvN1),
    N2 == InvN1,
    G1 =.. [N1|Args1],
    G2 =.. [N2|Args2],
    Args1 == Args2.

%% Same gate applied twice cancels for self-inverse gates
gates_cancel(G1, G2) :-
    functor(G1, Name, _),
    functor(G2, Name, _),
    gate_property(Name, self_inverse),
    G1 =.. [Name|Args],
    G2 =.. [Name|Args].

%% remove_identities(+Gates, ?Result)
remove_identities(Gates, Result) :-
    exclude(is_identity_gate, Gates, Result).

is_identity_gate(i(_)) :- !.
is_identity_gate(id(_)) :- !.
is_identity_gate(global_phase(0)) :- !.
is_identity_gate(rx(0,_)) :- !.
is_identity_gate(ry(0,_)) :- !.
is_identity_gate(rz(0,_)) :- !.
is_identity_gate(p(0,_)) :- !.

%% combine_rotations(+Gates, ?Result)
%% Merge adjacent rotations on same qubit and axis
combine_rotations([], []) :- !.
combine_rotations([G], [G]) :- !.
combine_rotations([G1,G2|Rest], Result) :-
    ( combine_rotation_pair(G1, G2, Combined)
    -> combine_rotations([Combined|Rest], Result)
    ;  combine_rotations([G2|Rest], RestOpt),
       Result = [G1|RestOpt]
    ).

combine_rotation_pair(rx(T1,Q), rx(T2,Q), rx(T,Q)) :- T is T1+T2, !.
combine_rotation_pair(ry(T1,Q), ry(T2,Q), ry(T,Q)) :- T is T1+T2, !.
combine_rotation_pair(rz(T1,Q), rz(T2,Q), rz(T,Q)) :- T is T1+T2, !.
combine_rotation_pair(p(T1,Q),  p(T2,Q),  p(T,Q))  :- T is T1+T2, !.
combine_rotation_pair(s(Q), s(Q), z(Q)) :- !.
combine_rotation_pair(t(Q), t(Q), s(Q)) :- !.

%% remove_redundant_swaps(+Gates, ?Result)
remove_redundant_swaps(Gates, Result) :-
    cancel_inverses(Gates, Result).

%% optimise_circuit/3: alias
optimise_circuit(Circuit, Options, Opt) :-
    quantum_optimise(Circuit, Options, Opt).

%% equivalent_quantum_circuits(+A, +B, ?Result)
equivalent_quantum_circuits(A, B, Result) :-
    ( A == B
    -> Result = true
    ;  %% Try to normalise and compare
       circuit_gates(A, GA), circuit_gates(B, GB),
       normalise_gates(GA, NGA), normalise_gates(GB, NGB),
       ( NGA == NGB
       -> Result = true
       ;  Result = unknown  % would need full matrix comparison
       )
    ).

normalise_gates(Gates, Norm) :-
    maplist(gate_normalise, Gates, Norm).

circuit_gates(circuit(_,_,G), G) :- !.
circuit_gates(G, G) :- is_list(G).

%% circuit_metrics(+Circuit, ?Metrics)
circuit_metrics(circuit(Qubits, Cbits, Gates), Metrics) :-
    length(Qubits, NQ),
    length(Cbits, NC),
    length(Gates, Total),
    include(is_two_qubit_gate, Gates, TwoQ),
    length(TwoQ, TwoQCount),
    include(is_entangling_gate, Gates, Ent),
    length(Ent, EntCount),
    include(is_measurement_gate, Gates, Meas),
    length(Meas, MeasCount),
    circuit_depth(Gates, Qubits, Depth),
    Metrics = metrics(
        qubits(NQ),
        classical_bits(NC),
        gate_count(Total),
        depth(Depth),
        two_qubit_gate_count(TwoQCount),
        entangling_gate_count(EntCount),
        measurement_count(MeasCount)
    ).

is_two_qubit_gate(Gate) :-
    functor(Gate, Name, _),
    quantum_gate_registry:gate_qubits(Name, N),
    N =:= 2.
is_two_qubit_gate(cx(_,_)).
is_two_qubit_gate(cy(_,_)).
is_two_qubit_gate(cz(_,_)).
is_two_qubit_gate(swap(_,_)).

is_entangling_gate(Gate) :-
    functor(Gate, Name, _),
    catch(gate_property(Name, entangling), _, fail).

is_measurement_gate(measure(_,_)).

circuit_depth(Gates, Qubits, Depth) :-
    foldl([Gate, Slots, NSlots]>>(
        gate_qubits_in_circuit(Gate, Qubits, QIdxs),
        max_slot(Slots, QIdxs, MaxSlot),
        NewSlot is MaxSlot + 1,
        update_slots(Slots, QIdxs, NewSlot, NSlots)
    ), Gates, [], FinalSlots),
    ( FinalSlots = []
    -> Depth = 0
    ;  max_list(FinalSlots, Depth)
    ).

gate_qubits_in_circuit(Gate, Qubits, Idxs) :-
    catch(quantum_ir:gate_operands(Gate, GQs), _, GQs = []),
    include(atom, GQs, AQs),
    maplist([Q, I]>>(nth0(I, Qubits, Q)), AQs, Idxs).

max_slot(Slots, Idxs, Max) :-
    maplist([I, S]>>(
        ( nth0(I, Slots, S) -> true ; S = 0 )
    ), Idxs, Ss),
    ( Ss = [] -> Max = 0 ; max_list(Ss, Max) ).

update_slots(Slots, [], _, Slots) :- !.
update_slots(Slots, [I|Is], Val, Result) :-
    length(Slots, Len),
    ( I < Len
    -> nth0(I, Slots, _, NewSlots, Val)
    ;  % extend
       Needed is I - Len,
       length(Zeros, Needed),
       maplist(=(0), Zeros),
       append(Slots, Zeros, Slots2),
       append(Slots2, [Val], NewSlots)
    ),
    update_slots(NewSlots, Is, Val, Result).

nth0(I, List, Old, NewList, New) :-
    nth0(I, List, Old),
    length(Prefix, I),
    append(Prefix, [Old|Suffix], List),
    append(Prefix, [New|Suffix], NewList).

%% entanglement_graph(+Circuit, ?Graph)
entanglement_graph(circuit(_,_,Gates), graph(Nodes, Edges)) :-
    include(is_entangling_gate, Gates, EntGates),
    maplist([G, edge(G)]>>true, EntGates, Edges),
    flatten_qubits(EntGates, Nodes).

flatten_qubits(Gates, Qubits) :-
    maplist([G, Qs]>>(catch(quantum_ir:gate_operands(G, Qs), _, Qs=[])), Gates, QLists),
    flatten(QLists, AllQ),
    include(atom, AllQ, AtomQ),
    list_to_set(AtomQ, Qubits).

%% dependency_dag(+Circuit, ?DAG)
dependency_dag(circuit(Q,_,Gates), dag(Nodes, Edges)) :-
    numlist(0, _-1, Idxs),
    length(Gates, N),
    N1 is N - 1,
    numlist(0, N1, Idxs),
    findall(I-J, (
        member(I, Idxs),
        member(J, Idxs),
        I < J,
        gates_depend(Gates, Q, I, J)
    ), Edges),
    Nodes = Gates.

gates_depend(Gates, Qubits, I, J) :-
    nth0(I, Gates, GI),
    nth0(J, Gates, GJ),
    catch(quantum_ir:gate_operands(GI, QI), _, QI=[]),
    catch(quantum_ir:gate_operands(GJ, QJ), _, QJ=[]),
    intersection(QI, QJ, Common),
    Common \= [].

%% circuit_layers(+Circuit, ?Layers)
%% Group non-dependent gates into parallel layers
circuit_layers(circuit(Q,_,Gates), Layers) :-
    build_layers(Gates, Q, [], Layers).

build_layers([], _, _, []) :- !.
build_layers(Gates, Qubits, UsedQ, [Layer|Rest]) :-
    select_independent_layer(Gates, Qubits, UsedQ, Layer, Remaining),
    gate_qubits_used_in_layer(Layer, Qubits, LayerQs),
    append(UsedQ, LayerQs, UsedQ2),
    build_layers(Remaining, Qubits, UsedQ2, Rest).

select_independent_layer([], _, _, [], []) :- !.
select_independent_layer([G|Gs], Qubits, UsedQ, Layer, Remaining) :-
    catch(quantum_ir:gate_operands(G, GQs), _, GQs=[]),
    include(atom, GQs, AQs),
    ( intersection(AQs, UsedQ, [])  % no conflict
    -> Layer = [G|LayerRest],
       append(UsedQ, AQs, UsedQ2),
       select_independent_layer(Gs, Qubits, UsedQ2, LayerRest, Remaining)
    ;  Remaining = [G|RemRest],
       select_independent_layer(Gs, Qubits, UsedQ, Layer, RemRest)
    ).

gate_qubits_used_in_layer(Layer, Qubits, Qs) :-
    maplist([G, GQs]>>(catch(quantum_ir:gate_operands(G, GQs), _, GQs=[])), Layer, QLists),
    flatten(QLists, AllQ),
    include(atom, AllQ, AtomQ),
    intersection(AtomQ, Qubits, Qs).
