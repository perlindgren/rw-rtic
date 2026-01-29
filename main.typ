#import "@preview/charged-ieee:0.1.4": ieee

#show: ieee.with(
  title: [Zero Cost Reader-Writer Locks for the RTIC Framework],
  abstract: [
    The RTIC framework provides and executable model for concurrent applications as a set of static priority, run-to-completion tasks with local and shared resources. At run-time the system is scheduled in compliance to the Stack Resource Policy (SRP), which brings guarantees for race-and deadlock-free execution of systems with shared resources. While the original work on SRP allows for multi-unit resources, the RTIC framework restricts the model to single-unit resources.

    In this paper we explore multiple-reader, single writer resources in context of the SRP model and the Rust aliasing invariants. We show that Reader-Writer resources can be implemented in RTIC with Zero Cost, while improving schedulability of the application. In the paper, we review the theoretical background and layout the statical analysis and code generation implementation in RTIC for the ARM Cortex-M v7m architecture. Finally, we evaluate the implementation with a set of benchmarks and real world applications.
  ],
  authors: (
    (
      name: "Anonymous Authors for review",
      department: [Anonymous],
      organization: [Anonymous],
      location: [Anonymous],
      email: "anonymous@example.com",
    ),
    (
      name: "Anonymous Authors for review",
      department: [Anonymous],
      organization: [Anonymous],
      location: [Anonymous],
      email: "anonymous@example.com",
    ),
    (
      name: "Anonymous Authors for review",
      department: [Anonymous],
      organization: [Anonymous],
      location: [Anonymous],
      email: "anonymous@example.com",
    ),
    (
      name: "Anonymous Authors for review",
      department: [Anonymous],
      organization: [Anonymous],
      location: [Anonymous],
      email: "anonymous@example.com",
    ),
  ),
  index-terms: ("Real-Time Systems", "Stack Resource Policy", "Reader Writer Locks", "RTIC", "Rust"),
  bibliography: bibliography("refs.bib"),
  figure-supplement: [Fig.],
)

= Introduction
Extend on: The RTIC framework provides and executable model for concurrent applications as a set of static priority, run-to-completion tasks with local and shared resources. At run-time the system is scheduled in compliance to the Stack Resource Policy (SRP), which brings guarantees for race-and deadlock-free access to shared resources. While the original work@baker1991stack on SRP allows for multi-unit resources, the RTIC framework restricts the model to single-unit resources.

In this paper we explore multiple-reader, single writer resources in context of the SRP model and the Rust aliasing invariants. We show that Reader-Writer resources can be implemented in RTIC with Zero Cost, while improving schedulability of the application. In the paper, we review the theoretical background and layout the statical analysis and code generation implementation in RTIC for the ARM Cortex-M v7m architecture.

Finally, we evaluate the implementation with a set of benchmarks and real world applications.

#box[
  Key contributions of this paper include:
  - Declarative model for Reader-Writer resources
  - Static analysis for Reader-Writer resources
  - Code generation for Reader-Writer resources in RTIC
  - Evaluation of Reader-Writer resources in RTIC with benchmarks and real world applications
]
== Background

In this section we review prior work on RTIC and underpinning theory. The term _task_ is used interchangeably with _job_ as defined in @baker1991stack.

In SRP, a task will preempt another if its _preemption level_ is higher than the _system ceiling_ and highest of any pending task, including the running task.

The preemption level of a task, $pi(t)$, is defined as any static function that satisfies

$
p(t') > p(t) "and p' arrives later" => pi(t') > pi(t).
$

In RTIC, the chosen function is $pi(t) = p(t)$, where $p(t)$ is a programmer selected, static priority for the task.

The system ceiling, $macron(Pi)$, is defined as a maximum of current _resource ceilings_, which are values assigned to each resource that depend on its current availability. Formally,

$
macron(pi) = max({ceil(R_i) mid(|) R "is a resource"}).
$<eq:system-ceiling>

Notice that $macron(pi)$ changes only when a resource is locked or unlocked.

RTIC uses the same definition for $ceil(R)$ as one of the example implementations in @baker1991stack: the resource ceiling is the maximum of zero and the highest priority of a job that could be blocked because of the current locks on $R$. Formally,

$
ceil(R) = max({0} union { p(y) mid(|) v_R < mu_R (y)}),
$<eq:resource-ceiling>
where $v_R$ is the current availability of $R$ and $mu_R(J)$ is $t$'s maximum need for $R$.

RTIC leverages the underlying hardware's prioritized interrupts for near zero-cost scheduling by compiling the programmer defined tasks to interrupt handlers. SRP compliant preemption prevention is implemented by interrupt masking, e.g., using NVIC BASEPRI register and PRIMASK. Each lock operation is compiled to code that updates the system ceiling (sets the interrupt masks) and pushes the new ceiling value to stack. With each unlock, the previous value is restored.

The current version of RTIC uses only single-unit resources. For a single-unit resource $R$, after each lock operation, $R$ has zero availability, so the system ceiling is always set to the same value based on @eq:system-ceiling and @eq:resource-ceiling. For this reason, the system ceiling is defined only by the set of locked resources, and RTIC is able to reduce the formula for $macron(pi)$ to

$
macron(pi) = max({0} union {p(t) | t "uses a locked resource"}).
$

The key contribution of this paper is to show that with multi-unit resources of the read-write type, there is still a compile-time known number that the system ceiling needs to be raised to with each lock operation.



=== The RTIC Framework

- Declarative task/resource model in Rust
- Compile time analysis and code generation
- Zero Cost abstractions for implementing the concurrency model

==== RTIC Evoluition

The RTIC framework is a Rust-first open source development rooted in research on modelling and implementation of (hard) real-time systems. Over the last decade RTIC has reached wide adoption (with a million downloads). However, the underlying code base is largerly monolithic, hampering community contributions and evolvability. To this end, a modular re-implementation (RTIC-eVo in the following) has recently been proposed/*@mrtic2025*/. While still experimental, it serves the purpose of prototyping new features and concepts for RTIC.

RTIC-eVo provides a set of compilation passes, gradually lowering the Domain Specific Language (DSL) model towards a plain Rust executable (thus RTIC can be seen as an executable model). The user facing DSL is defined by a distribution, which composes a selected set of compilation passes and their target specific backend implementations. The framework is highly flexible, as new passes (and their backends) can be developed and tested in isolation before being integrated into a distribution. The only requirement is that the output DSL of each pass, conforms to the input DSL of subsequent passes.

In Section @sec:rw-pass we will leverage this modularity to sketch the implementation of Reader-Writer resources in RTIC-eVo.

=== The Stack Resource Policy

Here we should review the Baker SRP stuff with a focus on multi-unit resources.

== Reader-Writer Resources

Reader-Writer resources are a special case of multi-unit resources, where an infinite number of readers is allowed, but only a single write at any time. This model coincides well with the Rust aliasing invariants, which allow for any number of immutable references (&T), but only a single mutable reference (&mut T) at any time.

=== Single-Unit Resources
@fig:single-unit-example[Figure] shows an example system with some shared single-unit resource $R$ between the tasks $t_1,..t_5$ with priorities $1,..5$ respectively. Tasks $t_1, t_4$ and $t_5$ are only reading the shared  while tasks $t_3$ and $t_4$ writes the resource. Under the single-unit model, with each lock, the system ceiling is raised to $ceil(R)_0 = 5$ after each lock operation on the read-write resource (the maximum priority of any task accessing the shared resource, $5$ in this case). Arrows in the figure indicate the arrival of requests for task execution.

Filled color indicates the task execution. The dashed line indicates the current system ceiling $macron(pi)$. A closed lock symbol indicates a lock being taken, and an open lock symbol indicates a lock being released. Hatched color indicates a task being blocked, and a cross-hatched color indicates the blocking is due to a higher priority task.

Notice under SRP tasks may only be blocked from being dispatched; once executing, they run to completion free of blocking.

Here we can see that the tasks $t_4$ and $t_5$ are exposed to unnecessary blocking due to the locks held by tasks $t_1$ and $t_3$.


#figure(
  caption: [Example: Single-Unit Resource Sharing],
  // placement: top,
  image("single_unit.png", width: 100%),
) <fig:single-unit-example>

=== Reduced Blocking with Reader-Writer Resources

@fig:rw-example[Figure] shows an example system with a reader/writer resource shared between the tasks $t_1,..t_5$, the rest of the example remains the same as previous section. The dark lock symbols indicate a write lock and the light lock symbols indicate a read lock.

Now, with each write lock, the system ceiling is raised to $ceil(R)_w$, the maximum priority of any task _accessing_ the resource, and with each read lock, to $ceil(R)_r$, the maximum priority of any task _writing_ the resource. In this case $ceil(R)_w = 5$ and $ceil(R)_r = 3$.

When $t_1$ claims the shared resource for read access, the system ceiling raised to $ceil(R)_r = 3$, allowing task $t_4$ to be directly executed (without being blocked). Similarly, when $t_4$ claims the resource, the system ceiling is raised to $max(macron(pi)_"cur", ceil(R)_r) = max(4, 3) = 4$. Notice that in RTIC, it is enough to raise the system ceiling to $ceil(R)_r = 3$, as tasks with lower priority than the current tasks are not allowed to preempt due to interrupt priority order.

When $t_2$ takes a write lock on the resource, the ceiling is raised to $ceil(R)_w = 5$, guaranteeing an exclusive access to the resource and preventing a race condition.

#figure(
  caption: [Example: Reader-Writer resource sharing ],
  // placement: top,
  image("rw.png", width: 90%),
) <fig:rw-example>

== Reader-Writer Resource Implementation in RTIC-eVo <sec:rw-pass>

As discussed earlier, we need to treat reader and writer accesses differently. In effect, we need to determine two ceilings per resource $r$:

- Reader ceiling $ceil(R)_r$: Maximum priority among tasks with _write access_ to the resource.
- Writer ceiling $ceil(R)_w$: Maximum priority among tasks with _read_ or _write access_ to the resource.

The `core-pass` (last in the compilation pipeline) takes a DSL with write access to shared resources. That is the core-pass will compute $pi(t)$ of any task $t$ with shared access to the resource $R$.

Assume an upstream `rw-pass` to:

- Identify all tasks with access to each resource $R$ and compute $ceil(R)_w$ correspondingly.
- Transform the DSL read accesses to write accesses.

The `core-pass` will now take into account all accesses (both read and write) when computing the ceiling $ceil(R)_w$.

The backend for the `rw-pass` will introduce a new `read_lock(Fn(&T)->R)` API, which will internally call the existing `lock` API (with ceiling set to $ceil(R)_r$), and pass on an immutable reference to the underlying data structure to the closure argument.

In this way, no additional target specific code generation is required, as the target specific `lock` implementation will be reused.

Notice however, that the `core-pass` will generate write access code for resources marked as reader only. From a safety perspective this is perfectly sound, as the computed ceiling value $ceil(R)$ takes all accesses into account. However, from a modelling perspective rejecting write accesses to tasks with read only priviliges would be preferable. Strengthening the model is out of scope for this paper and left as future work.

At this point, we have defined the `rw-pass` contract at high level, in the following we will further detail how the pass may be implemented leveraging the modularity of RTIC-eVo.

=== Implementation sketch

Each pass first parses the input DSL into an interal abstract syntax tree (AST) representation, later used for analysis and DSL transformation. For the purpose of this paper, we make the assumption that *all* shared resources may be accessible for reader-writer access. (In case a resource absctracts underlying hardware, reads may have side effects, thus in a future work we will return to distinguishing such resources from pure data structures.)

The `core-pass` DSL models the system in terms of tasks with local and shared resources. The model is declarative, where each task definition is attributed with the set of shared resources accessible (e.g., `shared = [A, B, C]`, indicates that the task is given access to the shared resources `A`, `B` and `C`).

The `rw-pass` will extend the DSL to allow indicating reader access. For sake of demonstration, we adopt `read_shared = [A, C]` to indicate that the task has read access to resources `A` and `E`.

The `rw-pass` will then perform the following steps:

- Collect the set of reader and writer resources per task.
- Compute the reader and writer ceilings per resource.
- Generate code for reader access, per task.
- Transform the DSL merging `read_shared` into `shared` resources.

In this way, given a valid input model, the `rw-pass` will lower the DSL into a valid `core-pass` model.







//  table(
//     // Table styling is not mandated by the IEEE. Feel free to adjust these
//     // settings and potentially move them into a set rule.
//     columns: (6em, auto),
//     align: (left, right),
//     inset: (x: 8pt, y: 4pt),
//     stroke: (x, y) => if y <= 1 { (top: 0.5pt) },
//     fill: (x, y) => if y > 0 and calc.rem(y, 2) == 0 { rgb("#efefef") },

//     table.header[Planet][Distance (million km)],
//     [Mercury], [57.9],
//     [Venus], [108.2],
//     [Earth], [149.6],
//     [Mars], [227.9],
//     [Jupiter], [778.6],
//     [Saturn], [1,433.5],
//     [Uranus], [2,872.5],
//     [Neptune], [4,495.1],
//   ),
