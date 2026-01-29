#import "preamble.typ": *
#show: doc => preamble(doc)

#import "@preview/charged-ieee:0.1.4": ieee

#show: ieee.with(
  title: [Zero Cost Reader-Writer Locks for the RTIC Framework],
  abstract: [
    The RTIC framework provides an executable model for concurrent applications as a set of static priority, run-to-completion tasks with shared resources. At run-time, the system is scheduled in compliance with Stack Resource Policy (SRP), which guarantees race-and deadlock-free execution. While the original work on SRP allows for multi-unit resources, the RTIC framework uses a model that is constrained to single-unit resources.

    In this paper we explore multiple-readers/single-writer resources in context of SRP and Rust aliasing invariants. We show that readers-writer resources can be implemented in RTIC at zero cost, while improving application schedulability. In the paper, we review the theory, and lay out the static analysis and code generation implementations in RTIC for the ARM Cortex\u{2011}v7m architecture. Finally, we evaluate the implementation with a set of benchmarks and real world applications.
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
#todo(position: "inline", [Extend / copied from abstract:
  The RTIC framework provides an executable model for concurrent applications as a set of static priority, run-to-completion tasks with shared resources. At run-time, the system is scheduled in compliance with Stack Resource Policy (SRP), which guarantees race-and deadlock-free execution. While the original work@baker1991stack on SRP allows for multi-unit resources, the RTIC framework uses a model that is constrained to single-unit resources.

  In this paper we explore multiple-readers/single-writer resources in context of SRP and Rust aliasing invariants. We show that readers-writer resources can be implemented in RTIC at zero cost, while improving application schedulability. In the paper, we review the theory, and lay out the static analysis and code generation implementations in RTIC for the ARM Cortex\u{2011}v7m architecture.

  Finally, we evaluate the implementation with a set of benchmarks and real world applications.
])

#box[
  Key contributions of this paper include:
  - Declarative model for readers-writer resources
  - Static analysis for readers-writer resources
  - Code generation for readers-writer resources in RTIC
  - Evaluation of readers-writer resources in RTIC with benchmarks and real world applications
]

== Background

In this section we review prior work on RTIC and underpinning theory. The term _task_ is used interchangeably with _job_, _job request_ or _job execution_ as defined in @baker1991stack.

In SRP, a task will preempt another if its _preemption level_ is higher than the _system ceiling_ and it's the oldest and highest priority of any pending task, including the running task.

The preemption level of a task $pi(t)$ is defined as any static function that satisfies

$
  p(t') > p(t) "and" t' "arrives later" => pi(t') > pi(t).
$

In RTIC, the chosen function is $pi(t) = p(t)$, where $p(t)$ is a programmer selected static priority for the task.

The system ceiling, $macron(Pi)$, is defined as a maximum of current _resource ceilings_, which are values assigned to each resource that depend on its own, current availability. Formally,

$
  macron(Pi) = max({ceil(R_i) mid(|) R_i "is a resource"}).
$<eq:system-ceiling>

Notice that $macron(Pi)$ changes only when a resource is locked or unlocked.

RTIC uses the same definition for $ceil(R)$ as one of the example implementations in @baker1991stack: the resource ceiling is the maximum of zero and the highest priority of a task that could be blocked because of the current locks on $R$. Formally,

$
  ceil(R) = max({0} union { pi(t) mid(|) v_R < mu_R (t)}),
$<eq:resource-ceiling-orig>

or as $pi = p$,

$
  ceil(R) = max({0} union { p(t) mid(|) v_R < mu_R (t)}),
$<eq:resource-ceiling>

where $v_R$ is the current availability of $R$ and $mu_R (t)$ is the task $t$'s maximum need for $R$.

RTIC leverages the underlying hardware's prioritized interrupts for near zero-cost scheduling by compiling the programmer defined and prioritized tasks to interrupt handlers in a corresponding relative priority order. SRP compliant preemption prevention is implemented by interrupt masking, e.g., using NVIC BASEPRI register and PRIMASK. The interrupt mask acts  as a system ceiling.

Now, a lower priority interrupt/task is not able to preempt a higher priority interrupt/task, and no interrupt/task is able to preempt if its prioritity (= preemption level) is not higher than the system ceiling. This satisfies the SRP preemption rule except for the requirement for the task to also be the _oldest_ highest priority pending task. This exception does not affect most of the qualities of SRP proven in @baker1991stack.

In RTIC, each lock operation is compiled to code that updates the system ceiling (sets the interrupt masks) and pushes the old ceiling value to stack. With each unlock, the previous value is restored. This is possible, as with SRP scheduling, the tasks are able to share a single stack in general.

The current version of RTIC uses only single-unit resources. For a single-unit resource $R$, after each lock operation, $R$ has zero availability, so the system ceiling is always set to the same value based on @eq:system-ceiling and @eq:resource-ceiling. In systems conforming to SRP, this number is a compile-time known constant.

// For this reason, the system ceiling is defined only by the set of locked resources.

// From @eq:system-ceiling and @eq:resource-ceiling and assuming single-unit resources, the following formula can be derived for $macron(Pi)$:

// $
// macron(Pi) = max({0} union {p(t) | t "needs a locked resource"}),
// $

// where, "t accesses a locked resource" means the same as "$t$'s maximum needs for resources exceed the currently available resources".

The key contribution of this paper is to show that with multi-unit resources of the readers-writer type, there is still a compile-time known number that the system ceiling needs to be raised to with each lock operation.



=== The RTIC Framework

- Declarative task/resource model in Rust
- Compile time analysis and code generation
- Zero Cost abstractions for implementing the concurrency model

==== RTIC Evolution

The RTIC framework is a Rust-first open source development rooted in research on modelling and implementation of (hard) real-time systems. Over the last decade RTIC has reached wide adoption (with a million downloads). However, the underlying code base is largerly monolithic, hampering community contributions and evolvability. To this end, a modular re-implementation (RTIC-eVo in the following) has recently been proposed@mrtic2025. While still experimental, it serves the purpose of prototyping new features and concepts for RTIC.

RTIC-eVo provides a set of compilation passes, gradually lowering the Domain Specific Language (DSL) model towards a plain Rust executable (thus RTIC can be seen as an executable model). The user facing DSL is defined by a distribution, which composes a selected set of compilation passes and their target specific backend implementations. The framework is highly flexible, as new passes (and their backends) can be developed and tested in isolation before being integrated into a distribution. The only requirement is that the output DSL of each pass conforms to the input DSL of subsequent passes.

In @sec:rw-pass, we will leverage this modularity to sketch the implementation of readers-writer resources in RTIC-eVo.

=== The Stack Resource Policy

#todo(position: "inline")[Here we should review the Baker SRP stuff with a focus on multi-unit resources.]

== Readers-writer Resources

Readers-writer resources are a special case of multi-unit resources, where an infinite number of readers is allowed, but only a single write at any time. This model coincides with the Rust aliasing model, which allows for any number of immutable references (`&T`), but only a single mutable reference (`&mut T`) at any time.

Assuming @eq:resource-ceiling and $pi = p$, when a lock is taken on a readers/writer resource $R$, the system ceiling can be raised to a compile-time known constant, $ceil(R)_r$ for read and $ceil(R)_w$ for write, and the system is still compliant to SRP. This means that no extra overhead is introduced to RTIC when implementing the readers-writer locks, as the readers-writer lock compiles similarly to mutex locks.

Formally, SRP compliance is maintained when:

+ a read-lock of resource $R$ is taken, if the system ceiling $macron(Pi)$ is changed to
  $ macron(Pi) = max(macron(Pi)_"cur", ceil(R)_r) $<eq:rw-lock-ceil-r>

  where $ceil(R)_r$ is the highest preemption level of tasks with write-access to $R$, and
+ a write-lock of resource $R$ is taken, if the system ceiling $macron(Pi)$ changes to
  $ macron(Pi) = max(macron(Pi)_"cur", ceil(R)_w), $<eq:rw-lock-ceil-w>

  where $ceil(R)_w$ is the highest preemption level of tasks that need $R$.

*Proof*

Assume the system has resources $R_1, ..., R_n$ and their availability is $v_R_1, ... v_R_n$ before taking the lock. Now, by definition @eq:resource-ceiling-orig, the system ceiling is
$
  macron(Pi)_"cur" & = max {ceil(R_i)_v_R_i mid(|) i in {1, ..., n}}
$<eq:proof0>
Assume the read or write lock operation concerns resource $R_m$, $m in 1, ..., n$.
After the locking, the system ceiling is, by definition,
$
  macron(Pi) = max(
    {ceil(R_i)_v_R_i mid(|) i in {1, ..., n} "and" i in.not {m}} \
    union {ceil(R_m)_v_(R_m)^'}
  ),
$<eq:proof1>
where $v_(R_m)^'$ is the new availability of resource $R_m$.

The new resource ceiling of $R_m$ must be higher or equal than the previous, i.e., $ceil(R_m)_v_R_m <= ceil(R_m)_v_(R_m)^'$, because $v_R_m > v_(R_m)^'$.

#box[From this, it follows that we can add the lower value inside the maximum:

  #math.equation(
    $
      =>^(#ref(<eq:proof1>)) & macron(Pi) = & max(
                                                & {ceil(R_i)_v_R_i mid(|) i in {1, ..., m} "and" i in.not {m}} \
                                                &                                                              & union & {ceil(R_m)_v_R_m} union {ceil(R_m)_v_(R_m)^'}
                                              ) \
                         <=> & macron(Pi) = & max(
                                                & {ceil(R_i)_v_R_i mid(|) i in {1, ..., m}} \
                                                &                                           & union & {ceil(R_m)_v_m^'}
                                              ) \
                         <=> & macron(Pi) = & max(
                                                & max({ceil(R_i)_v_R_i mid(|) i in {1, ..., m}}) \
                                                &                                                & union & {ceil(R_m)_v_(R_m)^'}
                                              ) \
       <=>^#ref(<eq:proof0>) & macron(Pi) = & max(&mid({ macron(Pi)_"cur"}) union {ceil(R_m)_v'_(R_m)}),
    $,
  )
  where the last term can be expanded to its definition:
  $
    <=>^#ref(<eq:resource-ceiling-orig>) & macron(Pi) = & max(
      & { macron(Pi)_"cur"} \
      &                     & union & {max({0} union {pi(J) mid(|) v'_R_m < mu_R_m (t)})}
    ) \
    <=> & macron(Pi) = & max(
      & { macron(Pi)_"cur"} union {0} \
      &                               & union & max{pi(J) mid(|) v'_R_m < mu_R_m (t)}
    ) \
    <=>^(pi>=0) & macron(Pi) = & max(&{ macron(Pi)_"cur"} union max{pi(t) mid(|) v'_R_m < mu_R_m (t)}).
  $<eq:proof2>
]

*Proof for @eq:rw-lock-ceil-r (read-lock):*

After locking, either $v'_R_m in {1, ..., n-1}$ or $v_R_m = 0$.

In the former case, the condition $v'_R_m < mu_R_m (t)$ in @eq:proof2 corresponds to $t$ having write access to $R_m$, proving @eq:rw-lock-ceil-r for that case.

In the latter case, the condition $v'_R_m < mu_R_m (t)$ corresponds $t$ having access to $R_m$ in general, as both reading and writing tasks are blocked when there is zero $R_m$, i.e.

$
  =>^#ref(<eq:proof2>) macron(Pi) = & max({ macron(Pi)_"cur"} union {pi(t) mid(|) t "needs" R_m})
$<eq:proof3>

It can be expanded to
$
  =>^#ref(<eq:proof3>) macron(Pi)
  = max(
          & { macron(Pi)_"cur"} \
    union & {pi(t) mid(|) t "has read access to" R_m} \
    union & {pi(t) mid(|) t "has write access to" R_m}
  )
$<eq:proof4>

For there to be zero $R_m$ after a read lock, the task must have preempted all other tasks that only read $R_m$ while they were holding a lock on resource $R_m$. For that to be possible, the task has to be the highest priority task with read access to $R_m$, i.e.,
$
  pi(t_"cur") = max{pi(t) mid(|) t "has read access to" R_m}
$<eq:proof5>
Continuing from @eq:proof4,
$
  =>^(#ref(<eq:proof5>)) macron(Pi) = max(
          & { macron(Pi)_"cur"} union {pi(t_"cur")} \
    union & {pi(t) mid(|) t "has write access to" R_m}
  )
$
However, in SRP, as a task is not allowed to preempt the currently executing task unless it has a higher priority, so it is enough to limit the system ceiling to
$
  =>^(#ref(<eq:proof5>)) macron(Pi) & = max(
                                        { macron(Pi)_"cur"} \
                                                            & union {pi(t) mid(|) t "has write access to" R_m}
                                      ) \
                                    & = max(macron(Pi)_"cur", ceil(R)_r),
$
which proves @eq:rw-lock-ceil-r.


*Proof for @eq:rw-lock-ceil-w (write-lock):*

If the lock was a write-lock, $v'_R_m = 0$. Continuing from @eq:proof2
$
  => macron(Pi) = & max({ macron(Pi)_"cur"} union {pi(J) mid(|) 0 < mu_R_m (t)}) \
                = & max({ macron(Pi)_"cur"} union {pi(t) mid(|) t "needs" R_m}) \
                = & max(macron(Pi)_"cur", ceil(R)_w),
$
proving @eq:rw-lock-ceil-w.

=== Example or read/write with Single-Unit Resources
@fig:example[Figure] shows an example system with some shared single-unit resource $R$ between the tasks $t_1,..t_5$ with priorities $1,..5$ respectively. Tasks $t_1, t_4$ and $t_5$ are only reading the shared  while tasks $t_3$ and $t_4$ writes the resource. Under the single-unit model, with each lock, the system ceiling is raised to $ceil(R)_0 = 5$ after each lock operation on the read-write resource (the maximum priority of any task accessing the shared resource, $5$ in this case). Arrows in the figure indicate the arrival of requests for task execution.

Filled color indicates the task execution. The dashed line indicates the current system ceiling $macron(Pi)$. A closed lock symbol indicates a lock being taken, and an open lock symbol indicates a lock being released. Hatched color indicates a task being blocked, and a cross-hatched color indicates the blocking is due to a higher priority task.

Notice under SRP tasks may only be blocked from being dispatched; once executing, they run to completion free of blocking.

Here we can see that the tasks $t_4$ and $t_5$ are exposed to unnecessary blocking due to the locks held by tasks $t_1$ and $t_3$.


// #figure(
//   caption: [Example: Single-Unit Resource Sharing],
//   // placement: top,
//   image("single_unit.png", width: 100%),
// ) <fig:single-unit-example>

#place(top + center, scope: "parent", float: true)[

  #figure(
    caption: [Examples: Top, Single-Unit Resource Sharing. Bottom, Reader-Writer Resource Sharing ],

    image("single-unit-and-rw.drawio.svg", width: 100%),
  ) <fig:example>

]
=== Reduced Blocking with Reader-Writer Resources

@fig:example[Figure] Bottom, shows an example system with a reader/writer resource shared between the tasks $t_1,..t_5$, the rest of the example remains the same as previous section. The dark lock symbols indicate a write lock and the light lock symbols indicate a read lock.

Now, with each write lock, the system ceiling is raised to $ceil(R)_w$, the maximum priority of any task _accessing_ the resource, and with each read lock, to $ceil(R)_r$, the maximum priority of any task _writing_ the resource. In this case $ceil(R)_w = 5$ and $ceil(R)_r = 3$.

When $t_1$ claims the shared resource for read access, the system ceiling raised to $ceil(R)_r = 3$, allowing task $t_4$ to be directly executed (without being blocked). Similarly, when $t_4$ claims the resource, the system ceiling is raised to $ceil(R)_r = 3$.

Notice that  if the last possible read-lock was taken, leaving the availability of $R$ to zero, the system ceiling should be raised to $5$ according to @eq:system-ceiling. This seems to mean that an implementation of the read-write lock needs to keep count of $R$ availability, but a later proof will show it is not necessary.

When $t_2$ takes a write lock on the resource, the ceiling is raised to $ceil(R)_w = 5$, guaranteeing an exclusive access to the resource and preventing a race condition.


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

Notice however, that the `core-pass` will generate write access code for resources marked as reader only. From a safety perspective this is perfectly sound, as the computed ceiling value $ceil(R)$ takes all accesses into account. However, from a modelling perspective rejecting write accesses to tasks with read only privileges would be preferable. Strengthening the model is out of scope for this paper and left as future work.

At this point, we have defined the `rw-pass` contract at high level, in the following we will further detail how the pass may be implemented leveraging the modularity of RTIC-eVo.

=== Implementation sketch

Each pass first parses the input DSL into an internal abstract syntax tree (AST) representation, later used for analysis and DSL transformation. For the purpose of this paper, we make the assumption that *all* shared resources may be accessible for reader-writer access. (In case a resource abstracts underlying hardware, reads may have side effects, thus in a future work we will return to distinguishing such resources from pure data structures.)

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
