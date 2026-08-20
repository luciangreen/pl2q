%% quantum_complex.pl
%% Complex number arithmetic for quantum computing.
%% Complex numbers are represented as c(Re, Im) where Re and Im are real numbers.

:- module(quantum_complex, [
    c/2,
    complex_add/3,
    complex_sub/3,
    complex_mul/3,
    complex_div/3,
    complex_neg/2,
    complex_conj/2,
    complex_abs/2,
    complex_abs_sq/2,
    complex_norm/2,
    complex_zero/1,
    complex_one/1,
    complex_i/1,
    complex_equal/3,
    complex_from_real/2,
    complex_from_polar/3,
    complex_to_polar/3,
    complex_exp/2,
    complex_sqrt/2,
    complex_phase/2,
    complex_re/2,
    complex_im/2,
    complex_print/1
]).

:- use_module(library(apply)).

%% c(Re, Im) is already the representation.
%% This predicate just validates/constructs.
c(Re, Im) :- number(Re), number(Im).

complex_re(c(Re, _), Re).
complex_im(c(_, Im), Im).

complex_zero(c(0, 0)).
complex_one(c(1, 0)).
complex_i(c(0, 1)).

complex_from_real(R, c(R, 0)) :- number(R).

complex_from_polar(R, Theta, c(Re, Im)) :-
    number(R), number(Theta),
    Re is R * cos(Theta),
    Im is R * sin(Theta).

complex_to_polar(c(Re, Im), R, Theta) :-
    R is sqrt(Re*Re + Im*Im),
    Theta is atan2(Im, Re).

complex_add(c(R1,I1), c(R2,I2), c(R,I)) :-
    R is R1 + R2,
    I is I1 + I2.

complex_sub(c(R1,I1), c(R2,I2), c(R,I)) :-
    R is R1 - R2,
    I is I1 - I2.

complex_mul(c(R1,I1), c(R2,I2), c(R,I)) :-
    R is R1*R2 - I1*I2,
    I is R1*I2 + I1*R2.

complex_div(c(R1,I1), c(R2,I2), c(R,I)) :-
    D is R2*R2 + I2*I2,
    D =\= 0,
    R is (R1*R2 + I1*I2) / D,
    I is (I1*R2 - R1*I2) / D.

complex_neg(c(R,I), c(NR, NI)) :-
    NR is -R,
    NI is -I.

complex_conj(c(R,I), c(R, NI)) :-
    NI is -I.

complex_abs_sq(c(R,I), Abs2) :-
    Abs2 is R*R + I*I.

complex_abs(C, Abs) :-
    complex_abs_sq(C, Abs2),
    Abs is sqrt(Abs2).

complex_norm(C, N) :- complex_abs(C, N).

complex_phase(c(R,I), Theta) :-
    Theta is atan2(I, R).

complex_equal(C1, C2, Tol) :-
    complex_sub(C1, C2, Diff),
    complex_abs(Diff, Abs),
    Abs =< Tol.

%% complex_exp(C, Exp): Exp = e^C
complex_exp(c(R,I), c(ER, EI)) :-
    EM is exp(R),
    ER is EM * cos(I),
    EI is EM * sin(I).

%% complex_sqrt(C, S): S = sqrt(C)
complex_sqrt(c(R,I), c(SR, SI)) :-
    Mod is sqrt(sqrt(R*R + I*I)),
    Arg is atan2(I, R),
    SR is Mod * cos(Arg/2),
    SI is Mod * sin(Arg/2).

complex_print(c(R, I)) :-
    ( I >= 0
    -> format("~w+~wi", [R, I])
    ;  format("~w~wi", [R, I])
    ).
