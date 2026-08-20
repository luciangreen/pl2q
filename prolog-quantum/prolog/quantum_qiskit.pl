%% quantum_qiskit.pl
%% Qiskit/Python export backend.

:- module(quantum_qiskit, [
    prolog_to_qiskit/2,
    circuit_to_python/2
]).

:- use_module(quantum_ir).

%% prolog_to_qiskit(+Circuit, ?PythonCode)
prolog_to_qiskit(circuit(Qubits, Cbits, Gates), PythonCode) :-
    length(Qubits, NQ),
    length(Cbits, NC),
    gates_to_qiskit_lines(Gates, GateLines),
    ( NC > 0
    -> format(atom(CircuitDecl), "qc = QuantumCircuit(~w, ~w)", [NQ, NC])
    ;  format(atom(CircuitDecl), "qc = QuantumCircuit(~w)", [NQ])
    ),
    flatten([
        ["from qiskit import QuantumCircuit"],
        ["from qiskit.quantum_info import Statevector"],
        [""],
        [CircuitDecl],
        GateLines,
        [""],
        ["# Run simulation"],
        ["sv = Statevector(qc)"],
        ["print(sv)"]
    ], AllLines),
    atomic_list_concat(AllLines, '\n', PythonCode).

prolog_to_qiskit(Gates, PythonCode) :-
    is_list(Gates), !,
    quantum_ir:circuit_qubits_used(circuit([],[],Gates), Qubits),
    prolog_to_qiskit(circuit(Qubits,[],Gates), PythonCode).

gates_to_qiskit_lines([], []).
gates_to_qiskit_lines([Gate|Rest], [Line|Lines]) :-
    gate_to_qiskit_line(Gate, Line),
    gates_to_qiskit_lines(Rest, Lines).

%% Convert qubit names to indices
qubit_index(Q, Idx) :-
    ( atom(Q) ->
        ( atom_concat('q', IdxAtom, Q) -> atom_to_term(IdxAtom, Idx, [])
        ; atom_concat('q[', Rest, Q), atom_concat(IdxAtom, ']', Rest),
          atom_to_term(IdxAtom, Idx, [])
        ; Idx = 0
        )
    ; integer(Q) -> Idx = Q
    ; Idx = 0
    ).

gate_to_qiskit_line(h(Q), Line) :-
    qubit_index(Q, I),
    format(atom(Line), "qc.h(~w)", [I]).
gate_to_qiskit_line(x(Q), Line) :-
    qubit_index(Q, I),
    format(atom(Line), "qc.x(~w)", [I]).
gate_to_qiskit_line(y(Q), Line) :-
    qubit_index(Q, I),
    format(atom(Line), "qc.y(~w)", [I]).
gate_to_qiskit_line(z(Q), Line) :-
    qubit_index(Q, I),
    format(atom(Line), "qc.z(~w)", [I]).
gate_to_qiskit_line(s(Q), Line) :-
    qubit_index(Q, I),
    format(atom(Line), "qc.s(~w)", [I]).
gate_to_qiskit_line(sdg(Q), Line) :-
    qubit_index(Q, I),
    format(atom(Line), "qc.sdg(~w)", [I]).
gate_to_qiskit_line(t(Q), Line) :-
    qubit_index(Q, I),
    format(atom(Line), "qc.t(~w)", [I]).
gate_to_qiskit_line(tdg(Q), Line) :-
    qubit_index(Q, I),
    format(atom(Line), "qc.tdg(~w)", [I]).
gate_to_qiskit_line(sx(Q), Line) :-
    qubit_index(Q, I),
    format(atom(Line), "qc.sx(~w)", [I]).
gate_to_qiskit_line(rx(T,Q), Line) :-
    qubit_index(Q, I),
    format(atom(Line), "qc.rx(~w, ~w)", [T, I]).
gate_to_qiskit_line(ry(T,Q), Line) :-
    qubit_index(Q, I),
    format(atom(Line), "qc.ry(~w, ~w)", [T, I]).
gate_to_qiskit_line(rz(T,Q), Line) :-
    qubit_index(Q, I),
    format(atom(Line), "qc.rz(~w, ~w)", [T, I]).
gate_to_qiskit_line(p(T,Q), Line) :-
    qubit_index(Q, I),
    format(atom(Line), "qc.p(~w, ~w)", [T, I]).
gate_to_qiskit_line(u(T,Ph,La,Q), Line) :-
    qubit_index(Q, I),
    format(atom(Line), "qc.u(~w, ~w, ~w, ~w)", [T, Ph, La, I]).
gate_to_qiskit_line(cx(C,T), Line) :-
    qubit_index(C, CI), qubit_index(T, TI),
    format(atom(Line), "qc.cx(~w, ~w)", [CI, TI]).
gate_to_qiskit_line(cnot(C,T), Line) :-
    qubit_index(C, CI), qubit_index(T, TI),
    format(atom(Line), "qc.cx(~w, ~w)", [CI, TI]).
gate_to_qiskit_line(cy(C,T), Line) :-
    qubit_index(C, CI), qubit_index(T, TI),
    format(atom(Line), "qc.cy(~w, ~w)", [CI, TI]).
gate_to_qiskit_line(cz(C,T), Line) :-
    qubit_index(C, CI), qubit_index(T, TI),
    format(atom(Line), "qc.cz(~w, ~w)", [CI, TI]).
gate_to_qiskit_line(ch(C,T), Line) :-
    qubit_index(C, CI), qubit_index(T, TI),
    format(atom(Line), "qc.ch(~w, ~w)", [CI, TI]).
gate_to_qiskit_line(swap(A,B), Line) :-
    qubit_index(A, AI), qubit_index(B, BI),
    format(atom(Line), "qc.swap(~w, ~w)", [AI, BI]).
gate_to_qiskit_line(ccx(A,B,T), Line) :-
    qubit_index(A, AI), qubit_index(B, BI), qubit_index(T, TI),
    format(atom(Line), "qc.ccx(~w, ~w, ~w)", [AI, BI, TI]).
gate_to_qiskit_line(cswap(C,A,B), Line) :-
    qubit_index(C, CI), qubit_index(A, AI), qubit_index(B, BI),
    format(atom(Line), "qc.cswap(~w, ~w, ~w)", [CI, AI, BI]).
gate_to_qiskit_line(measure(Q,_C), Line) :-
    qubit_index(Q, QI),
    format(atom(Line), "qc.measure(~w, ~w)", [QI, QI]).
gate_to_qiskit_line(barrier(Qs), Line) :-
    maplist(qubit_index, Qs, Is),
    format(atom(Line), "qc.barrier(~w)", [Is]).
gate_to_qiskit_line(reset(Q), Line) :-
    qubit_index(Q, I),
    format(atom(Line), "qc.reset(~w)", [I]).
gate_to_qiskit_line(Gate, Line) :-
    format(atom(Line), "# unsupported: ~w", [Gate]).

%% circuit_to_python/2: alias
circuit_to_python(Circuit, Python) :-
    prolog_to_qiskit(Circuit, Python).
