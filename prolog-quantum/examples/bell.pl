%% bell.pl
%% Bell state (EPR pair) example.

:- use_module('../prolog/quantum').
:- use_module('../prolog/quantum_entanglement').
:- use_module('../prolog/quantum_state').

:- initialization(bell_example, main).

bell_example :-
    format("=== Bell State Example ===~n"),

    %% Create Bell pair via entanglement
    quantum_entangle([q0,q1], bell(phi_plus), Circuit),
    format("Bell Phi+ circuit: ~w~n", [Circuit]),

    %% Run simulation
    quantum(circuit([q0,q1],[],Circuit), [simulate(true)], Result),
    format("Simulation result: ~w~n", [Result]),

    %% Verify state
    bell_phi_plus(Expected),
    format("Expected state: ~w~n", [Expected]),

    %% Export QASM
    quantum(circuit([q0,q1],[c0,c1], [h(q0),cx(q0,q1),measure(q0,c0),measure(q1,c1)]),
            [export(qasm)],
            QASM),
    format("QASM output:~n~w~n", [QASM]),

    %% Entanglement detection
    entangled(Expected, R),
    format("Bell Phi+ is entangled: ~w~n", [R]),

    %% Report
    entanglement_report(Expected, Report),
    format("Entanglement report: ~w~n", [Report]).
