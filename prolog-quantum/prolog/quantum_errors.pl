%% quantum_errors.pl
%% Error handling and diagnostics for the quantum converter.

:- module(quantum_errors, [
    quantum_error/4,
    quantum_warning/4,
    unsupported/1,
    unsupported/2,
    check_unitary/2,
    check_gate_exists/1,
    check_qubit_count/3,
    check_matrix_dims/2,
    check_no_clone/1
]).

%% quantum_error(+Category, +Gate, +Detail, +Message)
quantum_error(Category, Gate, Detail, Message) :-
    format(atom(Msg), "Quantum Error [~w]: ~w\n  Gate: ~w\n  Detail: ~w",
           [Category, Message, Gate, Detail]),
    throw(error(quantum_error(Category, Gate, Detail), Msg)).

%% quantum_warning(+Category, +Gate, +Detail, +Message)
quantum_warning(Category, Gate, Detail, Message) :-
    format("Quantum Warning [~w]: ~w~n  Gate: ~w~n  Detail: ~w~n",
           [Category, Message, Gate, Detail]).

%% unsupported(+Reason)
unsupported(Reason) :-
    throw(error(unsupported(Reason), Reason)).

unsupported(Reason, Detail) :-
    throw(error(unsupported(Reason, Detail), Reason)).

%% check_unitary(+Matrix, +Tol)
check_unitary(Matrix, Tol) :-
    ( catch(
        ( use_module(quantum_matrix),
          quantum_matrix:matrix_is_unitary(Matrix, Tol)
        ), _, fail)
    -> true
    ;  quantum_error(non_unitary, matrix, Matrix,
                    "Non-unitary transformation cannot be inserted as a quantum gate")
    ).

%% check_gate_exists(+Gate)
check_gate_exists(Gate) :-
    functor(Gate, Name, Arity),
    ( catch(quantum_gate_registry:quantum_gate(Name, Arity, _, _, _), _, fail)
    -> true
    ;  format(atom(Msg), "Unknown gate ~w/~w", [Name, Arity]),
       quantum_error(unknown_gate, Gate, Name/Arity, Msg)
    ).

%% check_qubit_count(+Gate, +Expected, +Actual)
check_qubit_count(Gate, Expected, Actual) :-
    ( Expected =:= Actual
    -> true
    ;  format(atom(Msg), "Gate ~w expects ~w qubits, got ~w", [Gate, Expected, Actual]),
       quantum_error(wrong_qubit_count, Gate, got(Actual)/expected(Expected), Msg)
    ).

%% check_matrix_dims(+Matrix, +ExpectedDim)
check_matrix_dims(Matrix, N) :-
    length(Matrix, Rows),
    ( Rows =:= N
    -> maplist([Row]>>(length(Row, Cols), Cols =:= N), Matrix)
    ;  format(atom(Msg), "Gate matrix has dimension ~wx?, qubit gates require dimension 2^n", [Rows]),
       quantum_error(invalid_matrix_dims, matrix, rows(Rows)/expected(N), Msg)
    ).

%% check_no_clone(+Op)
check_no_clone(copy(_,_)) :-
    quantum_error(no_cloning, copy, copy,
                 "Quantum no-cloning theorem: cannot copy an arbitrary quantum state").
check_no_clone(_).
