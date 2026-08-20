GitHub Agent Prolog Program Requirements

Prolog Quantum and Quantum Entanglement Converter

1. Purpose

Build a SWI-Prolog program for representing, converting, analysing, optimising, simulating, and exporting quantum programs, with particular support for:

* ordinary quantum circuits;
* quantum superposition;
* quantum entanglement;
* controlled and multiply controlled computation;
* reversible computation;
* quantum measurement;
* classical/quantum hybrid computation;
* conversion between Prolog structures and quantum-circuit structures;
* decomposition of arbitrary gates into supported primitive gate sets;
* detection and analysis of entanglement;
* creation of entangled states from declarative Prolog specifications;
* conversion of suitable logical/reversible Prolog computations into quantum circuits.

The implementation should treat a quantum program as a symbolic mathematical object that Prolog can inspect and transform, rather than merely emitting strings for another quantum language.

The gate architecture must be extensible rather than based on a permanently fixed enumeration. Current Qiskit, for example, distinguishes standard gates from arbitrary unitary operations and exposes a standard-gate mapping; arbitrary unitary matrices can also be represented as gates. (IBM Quantum)

⸻

2. Main Program

Provide a principal module such as:

:- module(prolog_quantum, [
    quantum/2,
    quantum/3,
    quantum_convert/3,
    quantum_run/3,
    quantum_simulate/3,
    quantum_compile/3,
    quantum_decompose/3,
    quantum_optimise/3,
    quantum_entangle/3,
    quantum_disentangle/3,
    entangled/2,
    entanglement_report/2
]).

A simple first interface should permit:

?- quantum(Source, Result).

and a configurable interface:

?- quantum(Source, Options, Result).

Example:

?- quantum(
       [
           h(q0),
           cx(q0,q1),
           measure(q0,c0),
           measure(q1,c1)
       ],
       [simulate(true)],
       Result).

⸻

3. Core Quantum Intermediate Representation

Define a canonical Prolog quantum IR.

Example:

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

Every input language must first be normalised to this representation.

Every output language must be generated from this representation.

Do not make Qiskit, OpenQASM, Python, or a particular quantum computer the internal representation.

⸻

4. Quantum State Representation

Support representations for:

basis(0).
basis(1).
ket([0]).
ket([1]).
amplitude(Basis, ComplexAmplitude).
state([
    amplitude('00', A),
    amplitude('01', B),
    amplitude('10', C),
    amplitude('11', D)
]).

Support exact symbolic values where practical:

1/sqrt(2)
-i/sqrt(2)
exp(i*pi/4)

and numerical complex values where symbolic evaluation is unavailable.

⸻

5. Required Gate Architecture

The system must support all finite-dimensional unitary gates in principle by providing:

unitary(Matrix, Qubits)

plus automatic validation and decomposition.

Therefore “all quantum gates” means:

1. every built-in named gate supported by the converter;
2. arbitrary user-defined unitary gates;
3. arbitrary controlled forms;
4. arbitrary inverse forms;
5. arbitrary powers where mathematically meaningful;
6. arbitrary multi-controlled versions;
7. decomposition into a target universal basis.

Quantum-circuit systems commonly synthesize unitary operations into a chosen gate basis, so this decomposition layer is essential rather than attempting to enumerate every mathematically possible gate. (IBM Quantum)

⸻

6. Identity and Pauli Gates

Implement:

i(Q).
id(Q).
x(Q).
y(Q).
z(Q).

Matrices must be available through:

gate_matrix(x, Matrix).

and equivalent predicates.

⸻

7. Hadamard Gate

Implement:

h(Q).

Required transformation:

|0> → (|0> + |1>)/sqrt(2)
|1> → (|0> - |1>)/sqrt(2)

This gate must be usable as the normal first stage of Bell-state generation.

⸻

8. Phase Gates

Implement:

s(Q).
sdg(Q).
t(Q).
tdg(Q).
p(Theta,Q).
phase(Theta,Q).

Also support arbitrary phase operations.

⸻

9. Square-Root Gates

Implement at minimum:

sx(Q).
sxdg(Q).
sqrt_x(Q).
sqrt_x_dg(Q).

The representation should permit:

power(x, 1/2, Q).

where decomposition is available.

⸻

10. Rotation Gates

Implement:

rx(Theta,Q).
ry(Theta,Q).
rz(Theta,Q).
r(Theta,Phi,Q).

Angles may be:

pi
pi/2
pi/4
Theta
Expression

Symbolic parameters must remain symbolic until binding or numerical evaluation is necessary.

⸻

11. General Single-Qubit Unitary Gate

Implement:

u(Theta,Phi,Lambda,Q).

Support aliases/import compatibility for:

u1(...)
u2(...)
u3(...)

but normalise them to the canonical representation.

Qiskit’s current UGate, for example, represents a generic single-qubit rotation using three Euler-angle parameters. (IBM Quantum)

⸻

12. Controlled Pauli and Hadamard Gates

Implement:

cx(Control,Target).
cnot(Control,Target).
cy(Control,Target).
cz(Control,Target).
ch(Control,Target).

cnot/2 and cx/2 must normalise to one canonical gate.

⸻

13. Controlled Phase Gates

Implement:

cs(C,T).
csdg(C,T).
ct(C,T).
ctdg(C,T).
cp(Theta,C,T).
cphase(Theta,C,T).

⸻

14. Controlled Rotation Gates

Implement:

crx(Theta,C,T).
cry(Theta,C,T).
crz(Theta,C,T).
cu(Theta,Phi,Lambda,Gamma,C,T).

Also support generic:

controlled(Gate, Controls, Targets).

Example:

controlled(
    ry(theta),
    [q0,q1,q2],
    [q3]
).

⸻

15. SWAP Family

Implement:

swap(A,B).
iswap(A,B).
iswap_dg(A,B).
dcx(A,B).

Where useful, support square-root or powered SWAP operations through the generic unitary/power mechanism.

⸻

16. Three-Qubit Gates

Implement:

ccx(A,B,T).
toffoli(A,B,T).
cswap(C,A,B).
fredkin(C,A,B).

Aliases must normalise to one internal representation.

⸻

17. Relative-Phase Toffoli Gates

Support useful relative-phase multi-qubit gates including:

rccx(A,B,T).
rc3x(A,B,C,T).

and equivalent target-library constructs when importing them.

⸻

18. Arbitrary Multi-Controlled X

Implement:

mcx(Controls,Target).

Example:

mcx([q0,q1,q2,q3],q4).

Do not hard-code a maximum number of controls except where imposed by the selected backend.

Support compatibility names such as:

c3x(...)
c4x(...)

by converting them to mcx/2.

⸻

19. Arbitrary Multi-Controlled Gates

Generalise beyond X:

mcgate(Gate,Controls,Targets).

For example:

mcgate(
    rz(theta),
    [q0,q1,q2],
    [q3]
).

The compiler must automatically decompose these gates where required.

⸻

20. Two-Qubit Interaction Gates

Support interaction/entangling gates including:

rxx(Theta,A,B).
ryy(Theta,A,B).
rzz(Theta,A,B).
rzx(Theta,A,B).
xx_plus_yy(Theta,Beta,A,B).
xx_minus_yy(Theta,Beta,A,B).

The architecture must permit additional Hamiltonian-derived interaction gates without compiler changes.

⸻

21. Hardware-Specific Entangling Gates

Provide representations for gates such as:

ecr(A,B).

and permit backend-defined native operations.

Use:

native_gate(Name, Parameters, Qubits).

for gates unknown to the generic compiler.

⸻

22. Arbitrary Matrix Gates

Support:

unitary(Matrix,Qubits).

Example:

unitary(
    [
        [1,0],
        [0,exp(i*pi/3)]
    ],
    [q0]
).

Before accepting it:

* verify dimensions;
* verify square matrix;
* verify dimension equals 2^N;
* verify unitarity;
* determine affected qubit count.

Reject invalid matrices with an explanatory diagnostic.

⸻

23. User-Defined Gates

Support:

gate_definition(
    my_gate(Theta),
    [A,B],
    [
        h(A),
        cp(Theta,A,B),
        h(A)
    ]
).

Use:

my_gate(pi/4,q0,q1).

Gate definitions must permit nesting.

Detect recursive definitions that cannot terminate.

⸻

24. Inverse Gates

Support:

inverse(Gate).

Example:

inverse(t(q0)).

which can normalise to:

tdg(q0).

For compound gates, reverse operation order and invert each operation.

⸻

25. Gate Powers

Support:

power(Gate,Exponent).

Examples:

power(x(q0),1/2).
power(z(q0),1/4).

Use matrix exponentiation or recognised closed-form gates where possible.

⸻

26. Global Phase

Represent global phase explicitly:

global_phase(Phi).

Do not silently treat global phase as relative phase.

Optimisation may discard global phase only when the requested semantics permit it.

⸻

27. Quantum Measurement

Implement:

measure(Qubit,Cbit).
measure(Qubits,Cbits).
measure_all.

Simulation must implement measurement probabilities according to amplitudes.

Support:

shots(1000)

and return frequency distributions.

⸻

28. Reset

Implement:

reset(Q).

Reset is an operation and must not be incorrectly treated as a unitary gate.

⸻

29. Barriers and Scheduling Directives

Represent:

barrier(Qubits).
delay(Duration,Q).

Preserve barriers when requested.

Allow optimiser to ignore barriers only under an explicit option.

⸻

30. Classical Conditions

Implement conditional quantum operations:

if_bit(C,1,Gate).

Example:

if_bit(c0,1,x(q1)).

Support classical predicates where backend capability allows.

⸻

31. Bell-State Construction

Provide:

bell_pair(A,B,Circuit).

Canonical generation:

[
    h(A),
    cx(A,B)
]

Support all four Bell states.

⸻

32. GHZ States

Implement:

ghz(Qubits,Circuit).

Example:

ghz([q0,q1,q2],Circuit).

should generate the equivalent of:

[
    h(q0),
    cx(q0,q1),
    cx(q0,q2)
]

⸻

33. W States

Provide:

w_state(Qubits,Circuit).

Generation may use a synthesised circuit.

Verify resulting amplitudes.

⸻

34. Arbitrary Entanglement Specification

Provide a declarative form:

entangle([
    q0-q1,
    q1-q2
]).

and:

entanglement_graph(
    [q0,q1,q2],
    [
        edge(q0,q1),
        edge(q1,q2)
    ]
).

Compile an entanglement graph into an appropriate circuit where possible.

⸻

35. Entanglement Detection

Implement:

entangled(State,Result).

Examples:

Result = true.
Result = false.
Result = unknown.

For pure states, analyse separability across relevant bipartitions.

Do not merely claim that qubits are entangled because a CNOT occurs in the circuit.

⸻

36. Entanglement Reporting

Provide:

entanglement_report(State,Report).

Report may contain:

report(
    qubits([q0,q1,q2]),
    separable(false),
    partitions([...]),
    entropy([...]),
    correlations([...])
).

⸻

37. Partial Trace

Implement:

partial_trace(State,RemovedQubits,ReducedState).

This is required for rigorous subsystem and entanglement analysis.

⸻

38. Density Matrices

Support:

density_matrix(Matrix,Qubits).

At minimum implement:

* pure-state to density-matrix conversion;
* reduced density matrices;
* mixed-state representation;
* partial trace.

⸻

39. Entanglement Entropy

Provide:

entanglement_entropy(State,Partition,Entropy).

Use reduced-state von Neumann entropy where appropriate.

⸻

40. Schmidt Decomposition

Provide:

schmidt_decomposition(State,A,B,Result).

Use it for bipartite pure-state separability and entanglement analysis.

⸻

41. Entanglement Creation

Implement:

quantum_entangle(Input,Specification,Output).

Example:

?- quantum_entangle(
       [q0,q1],
       bell(phi_plus),
       Circuit).

⸻

42. Disentanglement

Implement:

quantum_disentangle(State,Options,Circuit).

This means finding a unitary transformation that maps a known entangled pure state to a separable state where such a transformation is specified/constructible.

Do not imply that an arbitrary unknown entangled state can simply be locally “turned off.”

⸻

43. Teleportation Circuit

Include a built-in quantum teleportation construction:

teleport(Source,Alice,Bob,Circuit).

Use it as both:

* demonstration;
* integration test of entanglement, measurement, and classically controlled operations.

⸻

44. Superdense Coding

Provide:

superdense_encode(Bits,Circuit).
superdense_decode(Circuit,Result).

Use as an entanglement test.

⸻

45. Quantum Fourier Transform

Support:

qft(Qubits,Circuit).
inverse_qft(Qubits,Circuit).

Prefer a decomposable implementation rather than depending upon a particular external QFT class. Current Qiskit documentation, for example, has changed its preferred QFT interfaces, demonstrating why the Prolog IR should remain independent of library-specific class names. (IBM Quantum)

⸻

46. Phase Estimation

Implement a circuit constructor for:

quantum_phase_estimation(Unitary,PrecisionQubits,StateQubits,Circuit).

⸻

47. Grover Components

Support reusable components:

oracle(...)
diffusion(...)
grover_iteration(...)

The converter does not need to solve arbitrary problems automatically to satisfy the first version.

⸻

48. Reversible Classical Logic

Implement quantum/reversible equivalents of:

* NOT;
* controlled NOT;
* AND with ancilla;
* XOR;
* reversible OR constructions;
* equality;
* controlled conditional operations;
* reversible arithmetic primitives.

Do not directly convert irreversible logical destruction into a unitary operation.

⸻

49. Prolog-to-Quantum Conversion

Provide:

prolog_to_quantum(PrologGoal,Options,Circuit).

The converter should analyse whether a Prolog operation can safely be mapped to:

1. reversible quantum logic;
2. an oracle;
3. a quantum search operation;
4. classical preprocessing plus a quantum circuit;
5. classical postprocessing;
6. no meaningful quantum conversion.

⸻

50. Reversibility Analysis

Before conversion analyse predicates for:

reversible
injective
many_to_one
nondeterministic
effectful
unknown

Irreversible predicates must not silently become unitary gates.

⸻

51. Logical Choice and Superposition

Support an explicit construct such as:

qchoice([
    probability(1/2,A),
    probability(1/2,B)
]).

or amplitude-based:

qchoice([
    amplitude(Amp1,A),
    amplitude(Amp2,B)
]).

This must be distinguished from ordinary Prolog nondeterminism.

⸻

52. Prolog Nondeterminism Is Not Quantum Superposition

The program must explicitly enforce:

Prolog choice point ≠ quantum superposition

A converter may transform a finite search domain into a superposition only when the transformation is mathematically defined.

Do not describe ordinary backtracking as physical quantum computation.

⸻

53. Quantum Oracle Conversion

Provide:

predicate_to_oracle(Predicate,Domain,OracleCircuit).

For suitable finite deterministic predicates.

For example:

good(X) :-
    X =:= 5.

may become an oracle over an explicitly bounded binary domain.

⸻

54. Ancilla Management

Automatically allocate:

ancilla(A).

Track:

* clean ancillas;
* dirty ancillas;
* temporary ancillas;
* required initial values.

Ancillas should be uncomputed where required.

⸻

55. Uncomputation

Provide automatic reversible cleanup.

For:

[
    Compute,
    Use,
    inverse(Compute)
]

detect possible compute/uncompute structures.

Optimise safely without leaving garbage entangled with outputs.

⸻

56. Quantum-to-Prolog Conversion

Provide:

quantum_to_prolog(Circuit,PrologRepresentation).

This should generate symbolic Prolog operations rather than pretend that a quantum circuit is equivalent to a conventional deterministic predicate.

Possible output:

run :-
    q_h(q0),
    q_cx(q0,q1),
    q_measure(q0,c0),
    q_measure(q1,c1).

⸻

57. OpenQASM Import and Export

Support at least:

qasm_to_prolog(Text,Circuit).
prolog_to_qasm(Circuit,Text).

Keep this module separate from the core representation.

⸻

58. Qiskit Export

Optionally generate Python/Qiskit from the canonical IR:

prolog_to_qiskit(Circuit,Python).

Qiskit should be treated as an output backend, not a semantic dependency.

⸻

59. Gate Registry

Implement a central registry such as:

quantum_gate(
    Name,
    Arity,
    Parameters,
    Properties,
    MatrixOrDefinition
).

Example:

quantum_gate(
    cx,
    2,
    [],
    [unitary,controlled,entangling,self_inverse],
    Matrix
).

⸻

60. Gate Properties

Permit queries such as:

gate_property(h,self_inverse).
gate_property(cx,entangling).
gate_property(t,phase).
gate_property(x,pauli).

Properties may include:

unitary
hermitian
clifford
pauli
rotation
controlled
multi_controlled
entangling
diagonal
permutation
self_inverse
parameterised
native
composite

⸻

61. Gate Discovery

Provide:

all_quantum_gates(Gates).

This must query the registry dynamically.

Do not maintain several duplicated hand-written gate lists.

⸻

62. Custom Gate Registration

Allow:

register_quantum_gate(Name,Definition).

so newly introduced gates can be supported without modifying the converter architecture.

⸻

63. Gate Validation

For every gate invocation verify:

* gate exists;
* number of qubits;
* valid parameters;
* no invalid duplicate target qubits;
* matrix dimensions;
* unitary property where required.

⸻

64. Gate Decomposition

Provide:

quantum_decompose(Circuit,Basis,Decomposed).

Example:

?- quantum_decompose(
       Circuit,
       [rz,sx,cx],
       Result).

⸻

65. Universal Gate Bases

Support configurable bases such as:

[h,t,cx]
[rx,ry,rz,cx]
[u,cx]
[rz,sx,x,cx]

No particular basis should be hardwired into the semantic layer.

⸻

66. Native Hardware Basis

Backend specification:

backend(
    Name,
    [
        basis_gates([...]),
        connectivity(...),
        max_qubits(N)
    ]
).

Compile generic circuits to backend constraints.

⸻

67. Qubit Connectivity

Represent coupling graphs:

coupling([
    q0-q1,
    q1-q2,
    q2-q3
]).

When an interaction is unavailable directly, insert routing/SWAP operations.

⸻

68. Circuit Optimisation

Implement safe passes including:

* adjacent inverse cancellation;
* self-inverse pair cancellation;
* rotation combination;
* phase combination;
* identity removal;
* redundant SWAP removal;
* controlled-gate simplification;
* dead operation elimination where valid;
* gate commutation where proven;
* decomposition;
* re-synthesis.

Example:

[
    x(q0),
    x(q0)
]

may reduce to:

[]

⸻

69. Entanglement-Aware Optimisation

Optimisation must track whether transformations alter:

* relative phases;
* correlations;
* entanglement;
* measurement statistics.

Do not optimise gates independently when their quantum correlations make that unsound.

⸻

70. Global Circuit Equivalence

Provide:

equivalent_quantum_circuits(A,B,Result).

For manageable circuits compare unitary matrices up to configurable global phase.

For measured circuits compare observable semantics where feasible.

⸻

71. Statevector Simulation

Implement:

statevector(Circuit,State).

for small circuits.

Apply gates by matrix action to appropriate tensor-product components.

⸻

72. Symbolic Simulation

Where possible retain expressions such as:

1/sqrt(2)
exp(i*theta)
cos(theta/2)
sin(theta/2)

instead of immediately converting everything to floating point.

⸻

73. Numerical Simulation

Provide configurable precision and complex-number handling.

Example:

quantum_simulate(
    Circuit,
    [precision(1.0e-12)],
    Result).

⸻

74. Measurement Simulation

Implement:

sample(Circuit,Shots,Counts).

Example result:

counts([
    '00'-503,
    '11'-497
]).

for a Bell-state experiment.

⸻

75. Deterministic Probability Mode

Also provide exact/no-sampling result:

probabilities(Circuit,Distribution).

Example:

[
    '00'-0.5,
    '11'-0.5
]

⸻

76. Circuit Metrics

Provide:

circuit_metrics(Circuit,Metrics).

including:

qubits
classical_bits
gate_count
depth
two_qubit_gate_count
entangling_gate_count
measurement_count
ancilla_count

⸻

77. Entanglement Graph

Analyse a circuit into:

entanglement_graph(Circuit,Graph).

Distinguish:

* gates capable of entanglement;
* actual entanglement for a known state;
* possible entanglement where the state is unknown.

⸻

78. Quantum Dependency Graph

Build a dependency DAG for circuit operations.

Use it for:

* depth calculation;
* parallel scheduling;
* optimisation;
* visualisation;
* hardware mapping.

⸻

79. Parallel Quantum Gates

Detect gates operating on disjoint qubits which may occupy the same logical circuit layer:

layer([
    h(q0),
    x(q3),
    rz(theta,q6)
]).

⸻

80. Circuit Normal Form

Create canonical circuit normalization:

normalise_quantum(Source,Normalised).

Resolve:

* aliases;
* gate syntax;
* control representation;
* parameter expressions;
* inverse notation;
* qubit declarations.

⸻

81. Conversion Pipeline

Required pipeline:

Input
 ↓
Parse
 ↓
Validate syntax
 ↓
Construct quantum IR
 ↓
Resolve aliases
 ↓
Analyse qubits/classical bits
 ↓
Analyse reversibility
 ↓
Analyse unitary/non-unitary operations
 ↓
Analyse superposition
 ↓
Analyse possible entanglement
 ↓
Normalise gates
 ↓
Optimise
 ↓
Decompose
 ↓
Map to target gate basis
 ↓
Map to hardware topology if requested
 ↓
Verify
 ↓
Simulate and/or export

⸻

82. Quantum Entanglement Conversion Pipeline

For entanglement requests:

Declarative relation
 ↓
Required entangled state
 ↓
State/correlation constraints
 ↓
Candidate preparation circuit
 ↓
Gate synthesis
 ↓
Entanglement verification
 ↓
Optimisation
 ↓
Output circuit

⸻

83. Quantum Mathematics Module

Implement separately:

quantum_matrix.pl
quantum_complex.pl
quantum_tensor.pl
quantum_state.pl

Required operations include:

* complex addition/multiplication;
* conjugate;
* conjugate transpose;
* matrix multiplication;
* tensor/Kronecker product;
* inner product;
* outer product;
* normalisation;
* trace;
* partial trace;
* eigenvalue support where required;
* matrix equality within tolerance;
* unitarity checking.

⸻

84. Dirac Notation

Optionally parse convenient terms such as:

ket(0).
ket(1).
ket('00').
bra(0).

Internally these must reduce to rigorous state representations.

⸻

85. No-Cloning Constraint

The compiler must not translate:

copy(Q,Q2)

into a universal arbitrary-state copying operation.

If a requested operation violates fundamental quantum constraints, report it explicitly rather than emitting a misleading circuit.

⸻

86. Measurement Versus Logical Reading

Distinguish:

inspect_symbolically(...)

from:

measure(...)

Simulation may inspect an internal statevector, but generated physical circuits cannot read arbitrary amplitudes without measurement.

⸻

87. Hybrid Classical/Quantum Programs

Support an IR such as:

hybrid([
    classical(prepare_data(X)),
    quantum(Circuit),
    measurement(Result),
    classical(process(Result))
]).

⸻

88. Error Handling

Diagnostics must identify:

source location
operation
qubits involved
error category
explanation
suggested replacement

Examples:

Non-unitary transformation cannot be inserted as a quantum gate.
Gate matrix has dimension 3x3; qubit gates require dimension 2^n.
Qubit q1 appears as both control and target.
Unknown gate foo/2.
Cannot prove that this Prolog predicate is reversible.

⸻

89. Unsupported Constructs

Do not fabricate quantum behaviour.

Return:

unsupported(Reason)

or a structured diagnostic when conversion is not mathematically justified.

⸻

90. Explain Mode

Provide:

quantum(Source,[explain(true)],Result).

Generate transformation traces such as:

1. Predicate contains a finite Boolean function.
2. Function is irreversible.
3. Added ancilla output.
4. Converted Boolean function to reversible oracle.
5. Decomposed Toffoli operation.
6. Optimised inverse gate pairs.

⸻

91. Gate Information Queries

Support interactive Prolog queries:

?- gate_matrix(h,M).
?- gate_inverse(t,Inv).
?- gate_property(cx,entangling).
?- gate_qubits(toffoli,N).
?- decompose_gate(toffoli,[h,t,tdg,cx],Circuit).

⸻

92. Example: Bell Pair

Input:

?- quantum_entangle(
       [q0,q1],
       bell(phi_plus),
       Circuit).

Expected conceptual result:

Circuit = [
    h(q0),
    cx(q0,q1)
].

Verification should establish:

state([
    amplitude('00',1/sqrt(2)),
    amplitude('11',1/sqrt(2))
]).

⸻

93. Example: Arbitrary Controlled Gate

Input:

controlled(
    unitary(Matrix,[q3]),
    [q0,q1,q2],
    [q3]
).

The compiler must accept this conceptually even if the selected target backend requires decomposition.

⸻

94. Example: Quantum Oracle

Input:

even_bit(X,Y) :-
    Y is 1 xor X.

Requested conversion:

?- predicate_to_oracle(even_bit/2,[bit,bit],Circuit).

The converter must first determine a reversible representation rather than literally executing is/2 quantum mechanically.

⸻

95. Required Source Files

Suggested layout:

prolog-quantum/
├── README.md
├── PROGRAM_REQUIREMENTS.md
├── LICENSE
├── prolog/
│   ├── quantum.pl
│   ├── quantum_ir.pl
│   ├── quantum_gate.pl
│   ├── quantum_gate_registry.pl
│   ├── quantum_matrix.pl
│   ├── quantum_complex.pl
│   ├── quantum_tensor.pl
│   ├── quantum_state.pl
│   ├── quantum_entanglement.pl
│   ├── quantum_simulator.pl
│   ├── quantum_measure.pl
│   ├── quantum_oracle.pl
│   ├── quantum_reversible.pl
│   ├── quantum_decompose.pl
│   ├── quantum_optimise.pl
│   ├── quantum_compile.pl
│   ├── quantum_qasm.pl
│   ├── quantum_qiskit.pl
│   └── quantum_errors.pl
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

⸻

96. Testing Every Gate

Each registered gate requires tests for:

* valid syntax;
* matrix dimensions;
* unitarity;
* inverse;
* expected action on basis states;
* decomposition;
* reconstruction from decomposition;
* controlled form where supported;
* export/import round trip.

⸻

97. Entanglement Tests

Mandatory tests:

|00>                    → separable
H(q0)                   → separable
H(q0), CX(q0,q1)        → entangled
Bell Φ+                 → entangled
Bell Φ−                 → entangled
Bell Ψ+                 → entangled
Bell Ψ−                 → entangled
GHZ                     → multipartite entangled
product of |+>|+>       → separable

Do not use the presence of an entangling gate alone as the test oracle.

⸻

98. Mathematical Verification Tests

Automatically verify identities such as:

H H = I
X X = I
Y Y = I
Z Z = I
S S = Z
T T = S
T T T T = Z
CX CX = I
SWAP SWAP = I

allowing equivalence up to global phase where appropriate.

⸻

99. Property-Based Testing

Generate random:

* one-qubit states;
* normalised statevectors;
* valid unitary matrices;
* small circuits;
* inverse circuits.

Check invariants such as:

norm(U|ψ>) = norm(|ψ>)
U†U = I
inverse(C) ○ C = I

within numerical tolerance.

⸻

100. External Validation

Where practical, compare generated circuit results against a recognised quantum SDK during tests.

External SDKs are validation tools only.

The Prolog implementation must remain independently testable.

⸻

101. Performance

Statevector simulation has exponential state size and must not hide that fact.

Before simulation estimate required state dimension:

2^N

Warn or refuse when configured resource limits would be exceeded.

⸻

102. Large-Circuit Operation

For large circuits allow conversion, optimisation, decomposition and structural analysis without requiring full statevector simulation.

⸻

103. Lazy Symbolic Transformations

Do not eagerly construct enormous matrices for every multi-qubit operation.

Represent gates structurally and apply specialised transformations where practical.

⸻

104. GitHub Agent Development Process

The GitHub Agent must implement the project incrementally.

For every stage:

1. implement functionality;
2. write tests;
3. run tests;
4. correct failures;
5. inspect mathematical correctness;
6. update documentation;
7. continue only when the stage passes.

⸻

105. Required Development Stages

Use approximately:

Stage 1  – mathematical complex/matrix layer
Stage 2  – quantum IR
Stage 3  – single-qubit gates
Stage 4  – controlled and multi-qubit gates
Stage 5  – arbitrary unitary gates
Stage 6  – statevector simulator
Stage 7  – measurements
Stage 8  – entanglement
Stage 9  – decomposition
Stage 10 – optimisation
Stage 11 – reversible Prolog analysis
Stage 12 – Prolog-to-quantum converter
Stage 13 – quantum-to-Prolog converter
Stage 14 – QASM/Qiskit exporters
Stage 15 – backend mapping
Stage 16 – complete integration tests

⸻

106. Definition of “All Quantum Gates”

The project must not claim that a finite handwritten list literally enumerates every possible quantum gate.

Instead the requirement is satisfied when the system supports:

named standard gates
+
parameterised gates
+
arbitrary unitary matrices
+
generic controlled gates
+
arbitrary numbers of controls
+
inverse gates
+
gate powers
+
composite gates
+
user-defined gates
+
backend-defined gates
+
decomposition into universal gate bases

Because arbitrary unitary gates can be represented and then synthesized/decomposed, this provides a mathematically general gate mechanism rather than merely a long catalogue. (IBM Quantum)

⸻

107. First-Release Acceptance Criteria

The first release is complete when:

* it runs under SWI-Prolog;
* the canonical quantum IR works;
* all principal standard one-, two-, and three-qubit gate families above work;
* arbitrary unitary matrices work;
* generic controlled and multi-controlled gates work;
* inverse and power operations work;
* Bell and GHZ entanglement work;
* separability/entanglement analysis works for small pure states;
* statevector simulation works;
* measurement probabilities and shot simulation work;
* gate decomposition works;
* basic circuit optimisation works;
* reversible Boolean predicates can be converted to quantum oracle structures;
* Prolog-to-quantum and quantum-to-Prolog representations work;
* QASM export works;
* all examples and tests pass;
* incorrect or unjustified “quantum conversions” produce explicit errors rather than fabricated output.

⸻

108. Final Design Principle

The program should implement:

Prolog specification
        ↓
logical/reversibility analysis
        ↓
quantum symbolic representation
        ↓
superposition / control / entanglement structure
        ↓
gate synthesis
        ↓
gate decomposition
        ↓
quantum optimisation
        ↓
verification
        ↓
simulation or hardware-oriented export

The central idea is that Prolog supplies declarative symbolic reasoning about the computation, while the quantum layer supplies rigorous amplitudes, unitary transformations, entanglement, measurement and quantum-circuit semantics.

It must never obtain apparent “quantum computation” merely by renaming Prolog nondeterminism, backtracking, parallelism, or randomness as superposition or entanglement.
