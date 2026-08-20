%% ghz.pl
%% GHZ state example for 3 and N qubits.

:- use_module('../prolog/quantum').
:- use_module('../prolog/quantum_entanglement').
:- use_module('../prolog/quantum_state').

:- initialization(ghz_example, main).

ghz_example :-
    format("=== GHZ State Example ===~n"),

    %% 3-qubit GHZ
    quantum_entangle([q0,q1,q2], ghz, Circuit3),
    format("3-qubit GHZ circuit: ~w~n", [Circuit3]),

    %% Verify via ghz/2
    ghz([q0,q1,q2], C2),
    format("ghz/2 circuit: ~w~n", [C2]),

    %% Simulate
    quantum(circuit([q0,q1,q2],[],C2), [simulate(true)], Sim),
    format("Simulation: ~w~n", [Sim]),

    %% GHZ state vector
    ghz_state(3, S),
    format("GHZ statevector: ~w~n", [S]),
    length(S, Dim),
    format("Dimension: ~w (2^3=8)~n", [Dim]),

    %% Entanglement
    entangled(S, R),
    format("GHZ state entangled: ~w~n", [R]),

    %% 5-qubit GHZ
    quantum_entangle([q0,q1,q2,q3,q4], ghz, Circuit5),
    format("5-qubit GHZ circuit: ~w~n", [Circuit5]).
