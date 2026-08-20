%% quantum.pl
%% Principal module for the Prolog Quantum and Quantum Entanglement Converter.
%%
%% Usage:
%%   ?- quantum(Source, Result).
%%   ?- quantum(Source, Options, Result).
%%
%% Example:
%%   ?- quantum(
%%          [h(q0), cx(q0,q1), measure(q0,c0), measure(q1,c1)],
%%          [simulate(true)],
%%          Result).

:- module(prolog_quantum, [
    quantum/2,
    quantum/3,
    quantum_convert/3,
    quantum_run/3,
    quantum_simulate/3,
    quantum_compile/3,
    quantum_decompose/3,
    quantum_optimise/3,
    quantum_entangle/3,
    quantum_disentangle/3,
    entangled/2,
    entanglement_report/2
]).

:- use_module(quantum_ir).
:- use_module(quantum_gate).
:- use_module(quantum_gate_registry).
:- use_module(quantum_complex).
:- use_module(quantum_matrix).
:- use_module(quantum_tensor).
:- use_module(quantum_state).
:- use_module(quantum_simulator).
:- use_module(quantum_measure).
:- use_module(quantum_entanglement).
:- use_module(quantum_decompose).
:- use_module(quantum_optimise).
:- use_module(quantum_reversible).
:- use_module(quantum_oracle).
:- use_module(quantum_compile).
:- use_module(quantum_qasm).
:- use_module(quantum_qiskit).
:- use_module(quantum_errors).

%% quantum(+Source, ?Result)
quantum(Source, Result) :-
    quantum(Source, [], Result).

%% quantum(+Source, +Options, ?Result)
quantum(Source, Options, Result) :-
    ( member(explain(true), Options)
    -> quantum_explain(Source, Options, Result)
    ;  quantum_compile:compile_pipeline(Source, Options, Compiled),
       dispatch_quantum(Compiled, Options, Result)
    ).

dispatch_quantum(Circuit, Options, Result) :-
    ( member(simulate(true), Options)
    -> quantum_simulator:quantum_simulate(Circuit, Options, Result)
    ; member(export(qasm), Options)
    -> quantum_qasm:prolog_to_qasm(Circuit, Result)
    ; member(export(qiskit), Options)
    -> quantum_qiskit:prolog_to_qiskit(Circuit, Result)
    ; member(decompose(Basis), Options)
    -> quantum_decompose:quantum_decompose(Circuit, Basis, Result)
    ; member(optimise(true), Options)
    -> quantum_optimise:quantum_optimise(Circuit, Options, Result)
    ;  Result = Circuit
    ).

%% quantum_explain(+Source, +Options, ?Result)
quantum_explain(Source, Options, explained(Steps, Result)) :-
    step(1, Source, "Input received"),
    quantum_compile:source_to_ir(Source, IR),
    step(2, IR, "Normalised to canonical IR"),
    quantum_ir:ir_normalise_aliases(IR, IR2),
    step(3, IR2, "Aliases resolved"),
    dispatch_quantum(IR2, Options, Result),
    step(4, Result, "Result produced"),
    Steps = [input, ir_construction, alias_resolution, output].

step(N, _Term, Msg) :-
    format("~w. ~w~n", [N, Msg]).

%% quantum_convert(+Source, +Format, ?Result)
quantum_convert(Source, qasm, QASM) :-
    quantum(Source, [export(qasm)], QASM).
quantum_convert(Source, qiskit, Python) :-
    quantum(Source, [export(qiskit)], Python).
quantum_convert(Source, ir, IR) :-
    quantum_compile:source_to_ir(Source, IR).

%% quantum_run(+Source, +Options, ?Result)
quantum_run(Source, Options, Result) :-
    quantum_compile:quantum_run(Source, Options, Result).

%% quantum_simulate(+Source, +Options, ?Result)
quantum_simulate(Source, Options, Result) :-
    quantum(Source, [simulate(true)|Options], Result).

%% quantum_compile(+Source, +Options, ?Result)
quantum_compile(Source, Options, Result) :-
    quantum_compile:quantum_compile(Source, Options, Result).

%% quantum_decompose(+Circuit, +Basis, ?Result)
quantum_decompose(Circuit, Basis, Result) :-
    quantum_decompose:quantum_decompose(Circuit, Basis, Result).

%% quantum_optimise(+Circuit, +Options, ?Result)
quantum_optimise(Circuit, Options, Result) :-
    quantum_optimise:quantum_optimise(Circuit, Options, Result).

%% quantum_entangle(+Input, +Spec, ?Output)
quantum_entangle(Input, Spec, Output) :-
    quantum_entanglement:quantum_entangle(Input, Spec, Output).

%% quantum_disentangle(+State, +Options, ?Circuit)
quantum_disentangle(State, Options, Circuit) :-
    quantum_entanglement:quantum_disentangle(State, Options, Circuit).

%% entangled(+State, ?Result)
entangled(State, Result) :-
    quantum_entanglement:entangled(State, Result).

%% entanglement_report(+State, ?Report)
entanglement_report(State, Report) :-
    quantum_entanglement:entanglement_report(State, Report).
