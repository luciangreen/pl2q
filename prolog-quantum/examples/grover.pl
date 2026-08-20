%% grover.pl
%% Grover's search algorithm components example.

:- use_module('../prolog/quantum').
:- use_module('../prolog/quantum_decompose').

:- initialization(grover_example, main).

grover_example :-
    format("=== Grover's Search Example ===~n"),

    Qubits = [q0,q1,q2],

    %% Diffusion operator
    grover_diffusion(Qubits, Diffusion),
    format("Diffusion operator (~w gates):~n", [_]),
    length(Diffusion, ND),
    format("Total gates: ~w~n", [ND]),

    %% Oracle (abstract)
    grover_oracle(my_predicate/1, Oracle),
    format("Oracle: ~w~n", [Oracle]),

    %% One Grover iteration
    grover_iteration(Oracle, Diffusion, Iteration),
    format("Grover iteration: ~w~n", [Iteration]),

    %% Phase estimation (bonus)
    PrecQubits = [p0,p1,p2],
    StateQubits = [s0],
    quantum_phase_estimation(u(1.0,0,0), PrecQubits, StateQubits, QPE),
    format("~nPhase estimation circuit (~w gates):~n", [_]),
    length(QPE, NQPE),
    format("Total gates: ~w~n", [NQPE]).
