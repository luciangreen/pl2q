%% quantum_measure.pl
%% Quantum measurement operations.

:- module(quantum_measure, [
    measure_statevector/4,
    measure_all/2,
    measurement_probabilities/3,
    post_measurement_state/4,
    measure_qubit/4,
    shot_sample/3
]).

:- use_module(quantum_complex).
:- use_module(quantum_state).

%% measure_statevector(+State, +QubitIdx, +N, ?Results)
%% Results: list of (outcome(0 or 1), probability, post_state)
measure_statevector(State, QIdx, N, Results) :-
    length(State, Dim),
    Dim =:= 2^N,
    numlist(0, Dim-1, Idxs),
    %% Probability of outcome 0
    include([I]>>( B is (I >> (N - QIdx - 1)) /\ 1, B =:= 0 ), Idxs, Idxs0),
    include([I]>>( B is (I >> (N - QIdx - 1)) /\ 1, B =:= 1 ), Idxs, Idxs1),
    sum_probs(State, Idxs0, P0),
    sum_probs(State, Idxs1, P1),
    post_collapse(State, Idxs0, P0, Post0),
    post_collapse(State, Idxs1, P1, Post1),
    Results = [outcome(0, P0, Post0), outcome(1, P1, Post1)].

sum_probs(State, Idxs, P) :-
    maplist([I, Prob]>>(nth0(I, State, Amp), complex_abs_sq(Amp, Prob)), Idxs, Probs),
    sumlist(Probs, P).

post_collapse(State, KeepIdxs, Prob, Post) :-
    length(State, Dim),
    numlist(0, Dim-1, AllIdxs),
    maplist([I, E]>>(
        ( member(I, KeepIdxs), Prob > 0
        -> nth0(I, State, Amp),
           NormFactor is 1/sqrt(Prob),
           complex_mul(Amp, c(NormFactor,0), E)
        ;  E = c(0,0)
        )
    ), AllIdxs, Post).

%% measure_all(+State, ?Outcome)
measure_all(State, Outcome) :-
    length(State, Dim),
    N is round(log(Dim) / log(2)),
    numlist(0, Dim-1, Idxs),
    maplist([I, I-P]>>(nth0(I, State, A), complex_abs_sq(A, P)), Idxs, Probs),
    random_outcome(Probs, Outcome).

random_outcome(Probs, Outcome) :-
    random(R),
    select_outcome(Probs, R, 0.0, Outcome).

select_outcome([I-P|_], R, Acc, I) :-
    NewAcc is Acc + P,
    R =< NewAcc, !.
select_outcome([_|Rest], R, Acc, I) :-
    Rest \= [],
    select_outcome(Rest, R, Acc, I).

%% measurement_probabilities(+State, +QIdx, +N, ?Probs)
measurement_probabilities(State, QIdx, N, probs(P0, P1)) :-
    length(State, Dim),
    Dim =:= 2^N,
    numlist(0, Dim-1, Idxs),
    include([I]>>(B is (I >> (N-QIdx-1)) /\ 1, B =:= 0), Idxs, Idxs0),
    include([I]>>(B is (I >> (N-QIdx-1)) /\ 1, B =:= 1), Idxs, Idxs1),
    sum_probs(State, Idxs0, P0),
    sum_probs(State, Idxs1, P1).

%% post_measurement_state(+State, +QIdx, +N, +Outcome, ?PostState)
post_measurement_state(State, QIdx, N, Outcome, PostState) :-
    length(State, Dim),
    Dim =:= 2^N,
    numlist(0, Dim-1, Idxs),
    include([I]>>(B is (I >> (N-QIdx-1)) /\ 1, B =:= Outcome), Idxs, KeepIdxs),
    sum_probs(State, KeepIdxs, Prob),
    post_collapse(State, KeepIdxs, Prob, PostState).

%% measure_qubit(+State, +QIdx, +N, ?result(Outcome, PostState))
measure_qubit(State, QIdx, N, result(Outcome, PostState)) :-
    measure_statevector(State, QIdx, N, Results),
    maplist([outcome(O,P,_), O-P]>>true, Results, Outcomes),
    random_outcome(Outcomes, Outcome),
    post_measurement_state(State, QIdx, N, Outcome, PostState).

%% shot_sample(+Circuit, +N, ?Counts)
shot_sample(Circuit, N, Counts) :-
    quantum_simulator:sample(Circuit, N, Counts).
