# pl2q
Prolog to Quantum and Quantum Entanglement

## Example Commands

### Run the built-in examples

```bash
cd prolog-quantum/examples
swipl -g halt bell.pl
swipl -g halt ghz.pl
swipl -g halt teleportation.pl
swipl -g halt superdense.pl
swipl -g halt qft.pl
swipl -g halt grover.pl
```

### Interactive usage in SWI-Prolog

```prolog
:- use_module('prolog-quantum/prolog/quantum').
:- use_module('prolog-quantum/prolog/quantum_entanglement').

% Simulate a Bell (EPR) pair
?- quantum([h(q0), cx(q0,q1)], [simulate(true)], Result).

% Create and inspect a Bell Phi+ entangled state
?- quantum_entangle([q0,q1], bell(phi_plus), Circuit).

% Create a 3-qubit GHZ state
?- quantum_entangle([q0,q1,q2], ghz, Circuit).

% Export a Bell circuit to OpenQASM
?- quantum(
       circuit([q0,q1],[c0,c1],[h(q0),cx(q0,q1),measure(q0,c0),measure(q1,c1)]),
       [export(qasm)],
       QASM).

% Detect whether a state vector is entangled
?- entangled([c(0.707,0), c(0,0), c(0,0), c(0.707,0)], Result).

% Decompose a Toffoli gate into a primitive gate set
?- quantum_decompose(
       circuit([q0,q1,q2],[],[ccx(q0,q1,q2)]),
       [rz,sx,cx],
       Decomposed).

% Query gate properties
?- gate_matrix(h, M).
?- gate_inverse(t, Inv).
?- gate_property(cx, entangling).
```

### Run the test suite

```bash
cd prolog-quantum/tests
swipl -g halt test_gates.pl
swipl -g halt test_unitary.pl
swipl -g halt test_entanglement.pl
swipl -g halt test_simulator.pl
```
