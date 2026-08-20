%% teleportation.pl
%% Quantum teleportation protocol example.

:- use_module('../prolog/quantum').
:- use_module('../prolog/quantum_entanglement').

:- initialization(teleportation_example, main).

teleportation_example :-
    format("=== Quantum Teleportation Example ===~n"),

    %% Build teleportation circuit
    teleport(source, alice, bob, Circuit),
    format("Teleportation circuit:~n"),
    maplist([G]>>(format("  ~w~n", [G])), Circuit),

    %% Export to QASM
    quantum(circuit([source,alice,bob],[c0,c1], Circuit), [export(qasm)], QASM),
    format("~nQASM:~n~w~n", [QASM]).
