%% qft.pl
%% Quantum Fourier Transform example.

:- use_module('../prolog/quantum').
:- use_module('../prolog/quantum_decompose').

:- initialization(qft_example, main).

qft_example :-
    format("=== Quantum Fourier Transform Example ===~n"),

    %% 3-qubit QFT
    qft_circuit([q0,q1,q2], QFT),
    format("3-qubit QFT circuit (~w gates):~n", [_]),
    length(QFT, N),
    format("Total gates: ~w~n", [N]),
    maplist([G]>>(format("  ~w~n", [G])), QFT),

    %% Inverse QFT
    inverse_qft_circuit([q0,q1,q2], IQFT),
    format("~nInverse QFT (~w gates):~n", [_]),
    length(IQFT, N2),
    format("Total gates: ~w~n", [N2]).
