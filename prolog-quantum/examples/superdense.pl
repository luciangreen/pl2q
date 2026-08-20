%% superdense.pl
%% Superdense coding example.

:- use_module('../prolog/quantum').
:- use_module('../prolog/quantum_entanglement').

:- initialization(superdense_example, main).

superdense_example :-
    format("=== Superdense Coding Example ===~n"),

    %% Encode all four 2-bit messages
    forall(
        member(Bits, [[0,0],[0,1],[1,0],[1,1]]),
        (
            superdense_encode(Bits, EncCircuit),
            format("Bits ~w encoding: ~w~n", [Bits, EncCircuit])
        )
    ),

    %% Full superdense coding: share Bell pair, encode, decode
    format("~nFull superdense protocol for bits [1,0]:~n"),
    %% 1. Create Bell pair between sender and receiver
    bell_pair_circuit([h(q0), cx(q0, q1)]),
    format("  Bell pair: [h(q0), cx(q0,q1)]~n"),
    %% 2. Sender encodes [1,0] → Z gate
    superdense_encode([1,0], EncGates),
    format("  Encoding gates: ~w~n", [EncGates]),
    %% 3. Receiver decodes
    format("  Decoding: cx(q0,q1), h(q0), measure~n").

bell_pair_circuit([h(q0),cx(q0,q1)]).
