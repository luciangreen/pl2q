%% quantum_qasm.pl
%% OpenQASM 2.0 import/export.

:- module(quantum_qasm, [
    qasm_to_prolog/2,
    prolog_to_qasm/2,
    prolog_to_qasm_string/2
]).

:- use_module(quantum_ir).

%% prolog_to_qasm(+Circuit, ?QASMText)
prolog_to_qasm(circuit(Qubits, Cbits, Gates), QASMText) :-
    length(Qubits, NQ),
    length(Cbits, NC),
    gates_to_qasm_lines(Gates, GateLines),
    qubit_declarations(Qubits, QDecls),
    cbit_declarations(Cbits, CDecls),
    flatten([
        ["OPENQASM 2.0;"],
        ["include \"qelib1.inc\";"],
        QDecls,
        CDecls,
        GateLines
    ], AllLines),
    atomic_list_concat(AllLines, '\n', QASMText).

qubit_declarations([], []).
qubit_declarations(Qubits, Decls) :-
    length(Qubits, N),
    format(atom(Decl), "qreg q[~w];", [N]),
    Decls = [Decl].

cbit_declarations([], []).
cbit_declarations(Cbits, Decls) :-
    length(Cbits, N),
    N > 0,
    format(atom(Decl), "creg c[~w];", [N]),
    Decls = [Decl].
cbit_declarations(Cbits, []) :- length(Cbits, 0).

gates_to_qasm_lines([], []).
gates_to_qasm_lines([Gate|Rest], [Line|Lines]) :-
    gate_to_qasm_line(Gate, Line),
    gates_to_qasm_lines(Rest, Lines).

gate_to_qasm_line(h(Q), Line) :- format(atom(Line), "h ~w;", [Q]).
gate_to_qasm_line(x(Q), Line) :- format(atom(Line), "x ~w;", [Q]).
gate_to_qasm_line(y(Q), Line) :- format(atom(Line), "y ~w;", [Q]).
gate_to_qasm_line(z(Q), Line) :- format(atom(Line), "z ~w;", [Q]).
gate_to_qasm_line(i(Q), Line) :- format(atom(Line), "id ~w;", [Q]).
gate_to_qasm_line(id(Q), Line) :- format(atom(Line), "id ~w;", [Q]).
gate_to_qasm_line(s(Q), Line) :- format(atom(Line), "s ~w;", [Q]).
gate_to_qasm_line(sdg(Q), Line) :- format(atom(Line), "sdg ~w;", [Q]).
gate_to_qasm_line(t(Q), Line) :- format(atom(Line), "t ~w;", [Q]).
gate_to_qasm_line(tdg(Q), Line) :- format(atom(Line), "tdg ~w;", [Q]).
gate_to_qasm_line(sx(Q), Line) :- format(atom(Line), "sx ~w;", [Q]).
gate_to_qasm_line(sxdg(Q), Line) :- format(atom(Line), "sxdg ~w;", [Q]).
gate_to_qasm_line(rx(Theta,Q), Line) :- format(atom(Line), "rx(~w) ~w;", [Theta, Q]).
gate_to_qasm_line(ry(Theta,Q), Line) :- format(atom(Line), "ry(~w) ~w;", [Theta, Q]).
gate_to_qasm_line(rz(Theta,Q), Line) :- format(atom(Line), "rz(~w) ~w;", [Theta, Q]).
gate_to_qasm_line(p(Theta,Q), Line) :- format(atom(Line), "p(~w) ~w;", [Theta, Q]).
gate_to_qasm_line(u(T,P,L,Q), Line) :- format(atom(Line), "u(~w,~w,~w) ~w;", [T,P,L,Q]).
gate_to_qasm_line(cx(C,T), Line) :- format(atom(Line), "cx ~w,~w;", [C,T]).
gate_to_qasm_line(cnot(C,T), Line) :- format(atom(Line), "cx ~w,~w;", [C,T]).
gate_to_qasm_line(cy(C,T), Line) :- format(atom(Line), "cy ~w,~w;", [C,T]).
gate_to_qasm_line(cz(C,T), Line) :- format(atom(Line), "cz ~w,~w;", [C,T]).
gate_to_qasm_line(ch(C,T), Line) :- format(atom(Line), "ch ~w,~w;", [C,T]).
gate_to_qasm_line(swap(A,B), Line) :- format(atom(Line), "swap ~w,~w;", [A,B]).
gate_to_qasm_line(ccx(A,B,T), Line) :- format(atom(Line), "ccx ~w,~w,~w;", [A,B,T]).
gate_to_qasm_line(cswap(C,A,B), Line) :- format(atom(Line), "cswap ~w,~w,~w;", [C,A,B]).
gate_to_qasm_line(cp(Theta,C,T), Line) :- format(atom(Line), "cp(~w) ~w,~w;", [Theta,C,T]).
gate_to_qasm_line(crx(T,C,Q), Line) :- format(atom(Line), "crx(~w) ~w,~w;", [T,C,Q]).
gate_to_qasm_line(cry(T,C,Q), Line) :- format(atom(Line), "cry(~w) ~w,~w;", [T,C,Q]).
gate_to_qasm_line(crz(T,C,Q), Line) :- format(atom(Line), "crz(~w) ~w,~w;", [T,C,Q]).
gate_to_qasm_line(rxx(T,A,B), Line) :- format(atom(Line), "rxx(~w) ~w,~w;", [T,A,B]).
gate_to_qasm_line(rzz(T,A,B), Line) :- format(atom(Line), "rzz(~w) ~w,~w;", [T,A,B]).
gate_to_qasm_line(measure(Q,C), Line) :- format(atom(Line), "measure ~w -> ~w;", [Q,C]).
gate_to_qasm_line(reset(Q), Line) :- format(atom(Line), "reset ~w;", [Q]).
gate_to_qasm_line(barrier(Qs), Line) :-
    atomic_list_concat(Qs, ',', QStr),
    format(atom(Line), "barrier ~w;", [QStr]).
gate_to_qasm_line(if_bit(C,Val,G), Line) :-
    gate_to_qasm_line(G, GLine),
    format(atom(Line), "if (~w==~w) ~w", [C,Val,GLine]).
gate_to_qasm_line(Gate, Line) :-
    format(atom(Line), "// unsupported: ~w", [Gate]).

%% qasm_to_prolog(+QASMText, ?Circuit)
qasm_to_prolog(Text, Circuit) :-
    atom(Text),
    atom_string(Text, Str),
    split_string(Str, "\n", "", Lines),
    parse_qasm_lines(Lines, Qubits, Cbits, Gates),
    Circuit = circuit(Qubits, Cbits, Gates).

parse_qasm_lines([], [], [], []).
parse_qasm_lines([Line|Rest], Qubits, Cbits, Gates) :-
    ( atom_string(LineA, Line)
    -> true ; LineA = Line ),
    ( parse_qasm_line(LineA, qreg(N))
    -> numlist(0, N-1, Idxs),
       maplist([I, Q]>>(format(atom(Q), "q[~w]", [I])), Idxs, Qubits0),
       parse_qasm_lines(Rest, _, Cbits, Gates),
       Qubits = Qubits0
    ; parse_qasm_line(LineA, creg(N))
    -> numlist(0, N-1, Idxs),
       maplist([I, C]>>(format(atom(C), "c[~w]", [I])), Idxs, Cbits0),
       parse_qasm_lines(Rest, Qubits, _, Gates),
       Cbits = Cbits0
    ; parse_qasm_line(LineA, gate(G))
    -> parse_qasm_lines(Rest, Qubits, Cbits, RestGates),
       Gates = [G|RestGates]
    ;  parse_qasm_lines(Rest, Qubits, Cbits, Gates)
    ).

parse_qasm_line(Line, qreg(N)) :-
    atom_concat('qreg q[', Rest, Line),
    atom_concat(NS, '];', Rest),
    atom_to_term(NS, N, []).

parse_qasm_line(Line, creg(N)) :-
    atom_concat('creg c[', Rest, Line),
    atom_concat(NS, '];', Rest),
    atom_to_term(NS, N, []).

parse_qasm_line(Line, gate(G)) :-
    qasm_line_to_gate(Line, G).

qasm_line_to_gate(Line, h(Q)) :-
    atom_concat('h ', Rest, Line),
    atom_concat(Q, ';', Rest), !.
qasm_line_to_gate(Line, x(Q)) :-
    atom_concat('x ', Rest, Line),
    atom_concat(Q, ';', Rest), !.
qasm_line_to_gate(Line, cx(C,T)) :-
    atom_concat('cx ', Rest, Line),
    atom_concat(C, ';', _),
    atomic_list_concat([C,T], ',', Rest), !.
qasm_line_to_gate(_, unsupported_qasm).

%% prolog_to_qasm_string(+Circuit, ?Str)
prolog_to_qasm_string(Circuit, Str) :-
    prolog_to_qasm(Circuit, Text),
    ( atom(Text) -> atom_string(Text, Str) ; Str = Text ).
