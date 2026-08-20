# Prolog Quantum and Quantum Entanglement Converter

A comprehensive SWI-Prolog library for representing, converting, analysing, optimising, simulating, and exporting quantum programs.

## Overview

This library treats quantum programs as symbolic mathematical objects that Prolog can inspect and transform. It supports:

- Ordinary quantum circuits
- Quantum superposition and entanglement
- Controlled and multiply-controlled computation
- Reversible computation
- Quantum measurement
- Classical/quantum hybrid computation
- Conversion between Prolog structures and quantum-circuit structures
- Decomposition of arbitrary gates into supported primitive gate sets
- Detection and analysis of entanglement
- Creation of entangled states from declarative Prolog specifications
- Conversion of suitable logical/reversible Prolog computations into quantum circuits

## Project Structure

```
prolog-quantum/
├── README.md
├── PROGRAM_REQUIREMENTS.md
├── LICENSE
├── prolog/
│   ├── quantum.pl                  % Principal module
│   ├── quantum_ir.pl               % Canonical Quantum IR
│   ├── quantum_gate.pl             % Gate operations
│   ├── quantum_gate_registry.pl    % Gate registry
│   ├── quantum_matrix.pl           % Matrix operations
│   ├── quantum_complex.pl          % Complex arithmetic
│   ├── quantum_tensor.pl           % Tensor products
│   ├── quantum_state.pl            % Quantum states
│   ├── quantum_entanglement.pl     % Entanglement analysis
│   ├── quantum_simulator.pl        % Statevector simulation
│   ├── quantum_measure.pl          % Measurement operations
│   ├── quantum_oracle.pl           % Oracle construction
│   ├── quantum_reversible.pl       % Reversibility analysis
│   ├── quantum_decompose.pl        % Gate decomposition
│   ├── quantum_optimise.pl         % Circuit optimisation
│   ├── quantum_compile.pl          % Compilation pipeline
│   ├── quantum_qasm.pl             % OpenQASM import/export
│   ├── quantum_qiskit.pl           % Qiskit/Python export
│   └── quantum_errors.pl           % Error handling
├── tests/
│   ├── test_gates.pl
│   ├── test_unitary.pl
│   ├── test_entanglement.pl
│   ├── test_simulator.pl
│   ├── test_converter.pl
│   ├── test_decomposition.pl
│   ├── test_optimisation.pl
│   └── test_qasm.pl
└── examples/
    ├── bell.pl
    ├── ghz.pl
    ├── teleportation.pl
    ├── superdense.pl
    ├── qft.pl
    └── grover.pl
```

## Requirements

- SWI-Prolog 8.x or later

## Usage

### Basic interface

```prolog
:- use_module('prolog/quantum').

% Simple simulation
?- quantum([h(q0), cx(q0,q1)], [simulate(true)], Result).

% With options
?- quantum(
       [h(q0), cx(q0,q1), measure(q0,c0), measure(q1,c1)],
       [simulate(true)],
       Result).

% QASM export
?- quantum(circuit([q0,q1],[c0,c1],[h(q0),cx(q0,q1)]),
           [export(qasm)],
           QASM).
```

### Entanglement

```prolog
:- use_module('prolog/quantum').

% Create Bell pair
?- quantum_entangle([q0,q1], bell(phi_plus), Circuit).

% Detect entanglement
?- entangled([c(0.707,0), c(0,0), c(0,0), c(0.707,0)], Result).
% Result = true

% Entanglement report
?- entanglement_report(State, Report).
```

### Gate information

```prolog
?- gate_matrix(h, M).
?- gate_inverse(t, Inv).
?- gate_property(cx, entangling).
?- gate_qubits(toffoli, N).
?- decompose_gate(toffoli, [h,t,tdg,cx], Circuit).
?- all_quantum_gates(Gates).
```

### QFT and Phase Estimation

```prolog
:- use_module('prolog/quantum_decompose').

?- qft_circuit([q0,q1,q2], Circuit).
?- inverse_qft_circuit([q0,q1,q2], IQFT).
?- quantum_phase_estimation(u(theta,0,0), [p0,p1,p2], [s0], QPE).
```

### Decomposition

```prolog
:- use_module('prolog/quantum_decompose').

% Decompose into universal basis
?- quantum_decompose(
       circuit([q0,q1,q2],[],[ccx(q0,q1,q2)]),
       [rz,sx,cx],
       Decomposed).
```

### Prolog-to-Quantum Conversion

```prolog
:- use_module('prolog/quantum_reversible').

% Analyse reversibility
?- reversibility_analysis(f(X,Y) :- Y is X xor 1, Analysis).

% Convert to oracle
?- predicate_to_oracle(even/1, [bit], Oracle).
```

## Canonical IR

All quantum programs are normalised to the canonical form:

```prolog
circuit(
    qubits([q0,q1]),
    cbits([c0,c1]),
    gates([
        h(q0),
        cx(q0,q1),
        measure(q0,c0),
        measure(q1,c1)
    ])
).
```

## Running Tests

```bash
cd tests
swipl -g halt test_gates.pl
swipl -g halt test_unitary.pl
swipl -g halt test_entanglement.pl
swipl -g halt test_simulator.pl
```

## Running Examples

```bash
cd examples
swipl -g halt bell.pl
swipl -g halt ghz.pl
swipl -g halt teleportation.pl
swipl -g halt qft.pl
```

## Design Principles

1. **Canonical IR**: All input languages are normalised to the Prolog quantum IR before processing.
2. **Extensible gate architecture**: The gate registry supports arbitrary user-defined gates.
3. **No quantum mimicry**: Prolog nondeterminism is never confused with quantum superposition.
4. **No-cloning enforcement**: Copying arbitrary quantum states is explicitly rejected.
5. **Symbolic mathematics**: Exact values like `1/sqrt(2)` are preserved where possible.
6. **Separation of concerns**: QASM/Qiskit are output backends, not semantic dependencies.

## Development Stages (Section 105)

| Stage | Description | Status |
|-------|-------------|--------|
| 1 | Mathematical complex/matrix layer | ✅ |
| 2 | Quantum IR | ✅ |
| 3 | Single-qubit gates | ✅ |
| 4 | Controlled and multi-qubit gates | ✅ |
| 5 | Arbitrary unitary gates | ✅ |
| 6 | Statevector simulator | ✅ |
| 7 | Measurements | ✅ |
| 8 | Entanglement | ✅ |
| 9 | Decomposition | ✅ |
| 10 | Optimisation | ✅ |
| 11 | Reversible Prolog analysis | ✅ |
| 12 | Prolog-to-quantum converter | ✅ |
| 13 | Quantum-to-Prolog converter | ✅ |
| 14 | QASM/Qiskit exporters | ✅ |
| 15 | Backend mapping | ✅ |
| 16 | Integration tests | ✅ |
