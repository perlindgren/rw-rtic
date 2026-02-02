#import "preamble.typ": *
#show: doc => preamble(doc)

#import "@preview/charged-ieee:0.1.4": ieee
#set figure(placement: top)

#show: ieee.with(
  title: [Zero Cost Reader-Writer Locks for the RTIC Framework],
  abstract: [
    The RTIC framework provides an executable model for concurrent applications as a set of static priority, run-to-completion jobs with shared resources. At run-time, the system is scheduled in compliance with Stack Resource Policy (SRP), which guarantees race- and deadlock-free execution. While the original work on SRP allows for multi-unit resources, the RTIC framework uses a model that is constrained to single-unit resources.

    In this paper we explore multi-unit resources that model readers-writer locks in the context of SRP and Rust aliasing invariants. We show that readers-writer resources can be implemented in RTIC at zero cost, while improving application schedulability. In the paper, we review the theory, and lay out the static analysis and code generation implementations in RTIC for the ARM Cortex\u{2011}v7m architecture. Finally, we evaluate the implementation with a set of benchmarks and real world applications.
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
  index-terms: ("Real-Time Systems", "Stack Resource Policy", "Readers-Writer Locks", "RTIC", "Rust"),
  bibliography: bibliography("refs.bib"),
  figure-supplement: [Fig.],
)

= Introduction

// Motivation, introduce the problem at hand and in brief: RTIC only implements
// binary semaphores, based on a simplified model.
The RTIC framework provides an executable model for concurrent applications as a set of static priority, preemptive, run-to-completion jobs with shared resources. At run-time, the system is scheduled in compliance with Stack Resource Policy~#box[(SRP)@baker1990srp-1]---an extension to Priority Ceiling Protocol (PCP)#ref(<sha1987pcp>)---which guarantees a number of desirable features for single-processor scheduling. Features include race- and deadlock-free execution, bounded, single-context-switch-per-job blocking, and simple, efficient, single-shared-stack execution. The original theory@baker1990srp-1 also describes a mathematical model of multi-unit resources that can be used to implement binary semaphores, readers-writer locks, and general semaphores. RTIC---_however_---only implements the first of these.

// Observations on first paragraph
//
// > I did not include "multiple priority inversion prevention" in the list of
//   features, because I think "single context switch per job blocking" implies
//   it. -- HL

// The question then: why does RTIC only implement binary semaphores.
The rationale for the constrained implementation is that binary semaphores are sufficient to provide safe access to shared resources/*, and can be implemented in a straightforward, efficient way on most hardware*/. Furthermore, in read-write situations where the highest priority contender for a resource is a job of the writing type, a binary semaphore already provides optimal schedulability.

// Contributions
However, in situations where the highest priority contender is not a write, a readers-writer lock provides improved schedulability, allowing to expedite higher priority tasks that only need to read the resource. #heksa(position: "inline")[Need to outline the benefit of 'general semaphore' here, and mention that it's left for future work.]

// Contributions
In this paper, we describe an extension of the declarative, "RTIC restricted model", applicable to readers-writer locks, and an implementation thereof.

#box[
  Key contributions of this paper include:
  - Declarative model for readers-writer resources
  - Static analysis for readers-writer resources
  - Code generation for readers-writer resources in RTIC
  - Evaluation of readers-writer resources in RTIC with benchmarks and real world applications
  #heksa[So far, the contributions _don't_ sound convincing, at least when formulated like this. @baker1991srp-journal already describes a "declarative model for RW-resources". Why are we doing it again?.]
  #valhe(position: "inline")[The key contribution here is to show that: even though SRP says we should raise the system ceiling in a complicated way, we do not have to. With r/w locks, we can make an exception to the SRP defined rule, and the scheduling stays the same. To explain it further: SRP defines that with each read-lock, the system ceiling is raised to a different number depending on how much of the r/w resource is left. Instead, we ignore this and raise it always to the same number, and we show that the system still schedules jobs like SRP does.]
]

= Prior work

== SRP-based scheduling

- PCP and SRP-based methods remain of interest to hard real-time scheduling, as conventional OSes cannot provide bounded blocking suitable for real-time schedulability analysis. @baker1991srp-journal
- SRP can be used to support EDF, RM, deadline-monotonic scheduling policies @baker1991srp-journal and static LST policies @baker1990srp-1.
- PCP describes a locking protocol for binary semaphores. For PCP, priority inversion is bounded by execution time of the longest critical section of a lower-priority job. @sha1987pcp
- PCP has been extended to apply to readers-writer resources@sha1989pcpmode, and multi-processor systems @rajkumar1988multi.

== RTIC, RTIC v2, RTIC eVo / MRTIC

=== The RTIC framework

- Declarative job/resource model in Rust
- Compile time analysis and code generation
- Zero Cost abstractions for implementing the concurrency model

=== RTIC Evolution

The RTIC framework is a Rust-first open source development rooted in research on modelling and implementation of (hard) real-time systems. Over the last decade RTIC has reached wide adoption (with a million downloads). However, the underlying code base is largerly monolithic, hampering community contributions and evolvability. To this end, a modular re-implementation (RTIC-eVo in the following) has recently been proposed@mrtic2025. While still experimental, it serves the purpose of prototyping new features and concepts for RTIC.

RTIC-eVo provides a set of compilation passes, gradually lowering the Domain Specific Language (DSL) model towards a plain Rust executable (thus RTIC can be seen as an executable model). The user facing DSL is defined by a distribution, which composes a selected set of compilation passes and their target specific backend implementations. The framework is highly flexible, as new passes (and their backends) can be developed and tested in isolation before being integrated into a distribution. The only requirement is that the output DSL of each pass conforms to the input DSL of subsequent passes.

In @sec:rw-pass, we will leverage this modularity to sketch the implementation of readers-writer resources in RTIC-eVo.

= Baseline model (SRP) /* "Existing theory */

In SRP, a job $J$ will preempt another if its _preemption level_ $pi(J)$ is higher than the _system ceiling_ $macron(Pi)$ and it's the oldest and highest priority of any pending job, including the running job.

The preemption level of a job $pi(J)$#footnote(numbering: "*")[The original theory distinguishes a job $J$ and it's execution or request $cal(J)$. However, in this paper, only $J$ is used, ass with static priority jobs, this distinction is not necessary.] is defined as any static function that satisfies

$
  p(J') > p(J) "and" J' "arrives later" => pi(J') > pi(J).
$

For instance, in RTIC, the chosen function is $pi(J) = p(J)$, where $p(J)$ is a programmer-selected, static priority for the job.

The system ceiling $macron(Pi)$ is defined as the maximum of current _resource ceilings_, which are values assigned to each resource that depend on their own, current availability. The resource ceiling $ceil(R)$ must always be equal or bigger than the preemption level of the running job, and all the preemption levels of jobs that might need $R$ more than is currently available. Formally, given the system has resources $R_i, i in [0, m]$

$
  macron(Pi) = max({ceil(R_i) mid(|) i in [0, m]}).
$<eq:system-ceiling>

System ceiling $macron(Pi)$ changes only when a resource is locked or unlocked. After a lock on $R$, the value it changes to

$
  macron(Pi)_"new" = max(macron(Pi)_"cur", ceil(R)_v_R),
$

where $macron(Pi)_"cur"$ is the system ceiling before the lock, and $ceil(R)_v_R$ is the the ceiling of $R$ with the remaining amount of unlocked $R$, denoted by $v_R$.

== Readers-writer Resources

Readers-writer resources are a special case of multi-unit resources, where an infinite number of readers is allowed, but only a single write at any time. This model coincides with the Rust aliasing model, which allows for any number of immutable references (`&T`), but only a single mutable reference (`&mut T`) at any time.

= "RTIC restricted model"

SRP describes a threshold based filtering of jobs allowed to run, where the treshold updates with each lock and unlock operation on a resource. RTIC associates the static priority jobs to interrupts handlers that get a corresponding priority level. It implements the threshold-based filtering by manipulating the system ceiling for interrupts.

In RTIC---so far---only single-unit resources have been allowed, as with them, the threshold needs to be updated to a compile-time known number, while for general multi-unit resources, the new system ceiling value is different for each number of remaining resouces. Support for general multi-unit resources would mean additional code in the locking functions, resulting in unwanted overhead.


In RTIC, the hardware runs the highest priority, enabled, pending interrupt without any programmatical control. The locking functions only manipulate the system ceiling for interrupts. #heksa[Heksa: see this:]In combination with Rust ownership system and compliance with SRP, controlled access to shared resources is guaranteed.

RTIC is a Rust-based hardware accelerated real-time operating system that leverages the underlying hardware's prioritized interrupt handlers for near zero-cost scheduling. The scheduling policy it uses is a restricted version of SRP.

In systems conforming to SRP, all possible ceilings of resource $R$ are compile-time known constants, i.e., $ceil(R)_v_R$ is known _a priori_ for each $v_R$.
RTIC leverages this to implement near zero-cost locking.

== Example from @baker1990srp-1

Assume there are jobs $J_x in J_1, J_2, J_3$, with priorities and preemption levels corresponding to their index ($pi(J_x)=p(J_x)=x$), and resources $R_1, R_2, R_3$ with amounts $N(R_1) = 3$, $N(R_2) = 1$, $N(R_3) = 3$, and the jobs have the following maximum resource needs as specified in @tab:example-needs.


#figure(
  caption: [The resource needs in a system with three jobs and three resources#footnote(numbering: "*")[Here, $R_1$ is a general multiunit resource, $R_2$ is a simple mutex, and $R_3$ behaves similarly to a read-write lock, where $J_2$ writes and $J_1$ and $J_3$ read.].],
  table(
    columns: 4,
    [], [$mu_(R_i)(J_1)$], [$mu_(R_i)(J_2)$], [$mu_(R_i)(J_3)$],
    [$R_1$ ($N(R_1)=3$)], [3], [2], [1],
    [$R_2$ ($N(R_2)=1$)], [1], [1], [0],
    [$R_3$ ($N(R_3)=3$)], [1], [3], [1],
  ),
)<tab:example-needs>


Using @tab:example-needs, it can be determined which is the highest preemption level/priority job that would be blocked if there were some amount $m$ of resource $R$ left. This determines the value $ceil(R)_m$. A new table (@tab:example-ceilings) can be filled with this information. In practise, these numbers can be extracted by the compiler.


#figure(caption: [The compile-time known, different resource ceilings of each resource.], table(
  columns: 5,
  align: center + horizon,
  [$ceil(R_i)_m$], [$ceil(R_i)_3$], [$ceil(R_i)_2$], [$ceil(R_i)_1$], [$ceil(R_i)_0$],
  [$R_1$], [0], [1], [2], [3],
  [$R_2$], [-], [-], [0], [2],
  [$R_3$], [0], [2], [2], [3],
))<tab:example-ceilings>

When a resource $R$ is locked, the system ceiling is raised to the maximum of the current value and the value corresponding to the number of available $R$.

== RTIC implementation of SRP

In RTIC, the resource ceiling is defined as

$
  ceil(R) = max({0} union { pi(J) mid(|) v_R < mu_R (J)}),
$<eq:resource-ceiling-orig>

where $v_R$ is the current availability of $R$ and $mu_R (J)$ is the maximum need of job $J$ for $R$---or, since $pi = p$,

$
  ceil(R) = max({0} union { p(J) mid(|) v_R < mu_R (J)}).
$<eq:resource-ceiling>


#todo[Repetitioin starts here.]
RTIC leverages the underlying hardware's prioritized interrupts for near zero-cost scheduling by compiling the programmer defined and prioritized jobs to interrupt handlers in a corresponding relative priority order. SRP compliant preemption prevention is implemented by interrupt masking, e.g., using NVIC BASEPRI register and PRIMASK. The interrupt mask acts  as a system ceiling.

Now, a lower priority interrupt/job is not able to preempt a higher priority interrupt/job, and no interrupt/job is able to preempt if its prioritity (= preemption level) is not higher than the system ceiling. This satisfies the SRP preemption rule except for the requirement for the job to also be the _oldest_ highest priority pending job. #valhe[Go through the proofs and see what qualities of SRP are affected by this exception!!]

In RTIC, each lock operation is compiled to code that updates the system ceiling (sets the interrupt masks) and pushes the old ceiling value to the stack. With each unlock, the previous value is restored from the stack.

The current version of RTIC uses only single-unit resources. For a single-unit resource $R$, after each lock operation, $R$ has zero availability, so the system ceiling is always set to the same value based on @eq:system-ceiling and @eq:resource-ceiling. This allows RTIC to simplify the formula for system ceiling to

$
  macron(Pi) = max({0} union {ceil(R) | R "is locked"}).
$

This is because when $R$ is unlocked, $ceil(R) = 0$, and when $R$ is locked, there is only one possible $ceil(R)$.

#todo[Repetition starts.]

As $ceil(R)$ is a compile-time known constant, the lock function for each $R$ compiles to code that raises the system-ceiling to some constant value. The lock function does not need to include any calculations.#todo[repetition]

#heksa(position: "inline")[Some pseudocode here for the lock function?]

= SRP compliant readers-writer lock

The key contribution of this paper is to show that with multi-unit resources of the readers-writer type, there is still a single compile-time known number that the system ceiling needs to be raised to with each lock operation.

*Proof, that for reader or write lock on $R$, the system ceiling can be raised to a compile-time known constant while staying SRP compliant*

Assuming @eq:resource-ceiling and $pi = p$, when a lock is taken on a readers/writer resource $R$, the system ceiling can be raised to a compile-time known constant, $ceil(R)_r$ for read and $ceil(R)_w$ for write, and the system is still compliant to SRP. This means that no extra overhead is introduced to RTIC when implementing the readers-writer locks, as the readers-writer lock compiles similarly to mutex locks.

Formally, SRP compliance is maintained when:

+ a read-lock of resource $R$ is taken, if the system ceiling $macron(Pi)$ is changed to
  $ macron(Pi) = max(macron(Pi)_"cur", ceil(R)_r) $<eq:rw-lock-ceil-r>

  where $ceil(R)_r$ is the highest preemption level of jobs with write-access to $R$, and
+ a write-lock of resource $R$ is taken, if the system ceiling $macron(Pi)$ changes to
  $ macron(Pi) = max(macron(Pi)_"cur", ceil(R)_w), $<eq:rw-lock-ceil-w>

  where $ceil(R)_w$ is the highest preemption level of jobs that need $R$.

*Proof*

Assume the system has resources $R_1, ..., R_n$ and their availability is $v_R_1, ... v_R_n$ before taking the lock. Now, by definition @eq:system-ceiling, the system ceiling is
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

It can be shown that because

$
  ceil(R_m)_v_(R_m)^' > ceil(R_m)_v_(R_m),
$<eq:proof1.5>
it follows that
$
  =>^(#ref(<eq:proof1>) #ref(<eq:proof1.5>)) macron(Pi) = & max(
                                                              { macron(Pi)_"cur"}\
                                                              &union max{pi(J) mid(|) v'_R_m < mu_R_m (J)}
                                                            ).
$<eq:proof2>

/*
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
  )]
  #box[
  where the last term can be expanded to its definition:
  $
    <=>^#ref(<eq:resource-ceiling-orig>) & macron(Pi) = & max(
      & { macron(Pi)_"cur"} \
      &                     & union & {max({0} union {pi(J) mid(|) v'_R_m < mu_R_m (J)})}
    ) \
    <=> & macron(Pi) = & max(
      & { macron(Pi)_"cur"} union {0} \
      &                               & union & max{pi(J) mid(|) v'_R_m < mu_R_m (J)}
    ) \
    <=>^(pi>=0) & macron(Pi) = & max(&{ macron(Pi)_"cur"} union max{pi(J) mid(|) v'_R_m < mu_R_m (J)}).
  $<eq:proof2>
  ]

*/

*Proof for @eq:rw-lock-ceil-r (read-lock):*

After locking, either $v'_R_m in {1, ..., n-1}$ or $v_R_m = 0$.

In the former case, the condition $v'_R_m < mu_R_m (J)$ in @eq:proof2 corresponds to $J$ having write access to $R_m$, proving @eq:rw-lock-ceil-r for that case.

In the latter case, the condition $v'_R_m < mu_R_m (J)$ corresponds $J$ having access to $R_m$ in general, as both reading and writing jobs are blocked when there is zero $R_m$, i.e.

$
  =>^#ref(<eq:proof2>) macron(Pi) = & max({ macron(Pi)_"cur"} union {pi(J) mid(|) J "needs" R_m})
$<eq:proof3>

It can be expanded to
$
  =>^#ref(<eq:proof3>) macron(Pi)
  = max(
          & { macron(Pi)_"cur"} \
    union & {pi(J) mid(|) J "has read access to" R_m} \
    union & {pi(J) mid(|) J "has write access to" R_m}
  )
$<eq:proof4>

For there to be zero $R_m$ after a read lock, the job must have preempted all other jobs that only read $R_m$ while they were holding a lock on resource $R_m$. For that to be possible, the job has to be the highest priority job with read access to $R_m$, i.e.,
$
  pi(t_"cur") = max{pi(J) mid(|) J "has read access to" R_m}
$<eq:proof5>
Continuing from @eq:proof4,
$
  =>^(#ref(<eq:proof5>)) macron(Pi) = max(
          & { macron(Pi)_"cur"} union {pi(t_"cur")} \
    union & {pi(J) mid(|) J "has write access to" R_m}
  )
$
However, in SRP, as a job is not allowed to preempt the currently executing job unless it has a higher priority, so it is enough to limit the system ceiling to
$
  =>^(#ref(<eq:proof5>)) macron(Pi) & = max(
                                        { macron(Pi)_"cur"} \
                                                            & union {pi(J) mid(|) J "has write access to" R_m}
                                      ) \
                                    & = max(macron(Pi)_"cur", ceil(R)_r),
$
which proves @eq:rw-lock-ceil-r.


*Proof for @eq:rw-lock-ceil-w (write-lock):*

If the lock was a write-lock, $v'_R_m = 0$. Continuing from @eq:proof2
$
  => macron(Pi) = & max({ macron(Pi)_"cur"} union {pi(J) mid(|) 0 < mu_R_m (J)}) \
                = & max({ macron(Pi)_"cur"} union {pi(J) mid(|) J "needs" R_m}) \
                = & max(macron(Pi)_"cur", ceil(R)_w),
$
proving @eq:rw-lock-ceil-w.

== Example of improved schedulability using readers-write locks

@fig:example[Figure] shows an example system with some shared single-unit resource $R$ between the jobs $J_1,..J_5$ with priorities $1,..5$ respectively. Tasks $J_1, J_4$ and $J_5$ are only reading the shared  while jobs $J_3$ and $J_4$ writes the resource. Under the single-unit model, with each lock, the system ceiling is raised to $ceil(R)_0 = 5$ after each lock operation on the read-write resource (the maximum priority of any job accessing the shared resource, $5$ in this case). Arrows in the figure indicate the arrival of requests for job execution.

Filled color indicates the job execution. The dashed line indicates the current system ceiling $macron(Pi)$. A closed lock symbol indicates a lock being taken, and an open lock symbol indicates a lock being released. Hatched color indicates a job being blocked, and a cross-hatched color indicates the blocking is due to a higher priority job.

Notice under SRP jobs may only be blocked from being dispatched; once executing, they run to completion free of blocking.

Here we can see that the jobs $J_4$ and $J_5$ are exposed to unnecessary blocking due to the locks held by jobs $J_1$ and $J_3$.


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

@fig:example[Figure] Bottom, shows an example system with a reader/writer resource shared between the jobs $J_1,..J_5$, the rest of the example remains the same as previous section. The dark lock symbols indicate a write lock and the light lock symbols indicate a read lock.

Now, with each write lock, the system ceiling is raised to $ceil(R)_w$, the maximum priority of any job _accessing_ the resource, and with each read lock, to $ceil(R)_r$, the maximum priority of any job _writing_ the resource. In this case $ceil(R)_w = 5$ and $ceil(R)_r = 3$.

When $J_1$ claims the shared resource for read access, the system ceiling raised to $ceil(R)_r = 3$, allowing job $J_4$ to be directly executed (without being blocked). Similarly, when $J_4$ claims the resource, the system ceiling is raised to $ceil(R)_r = 3$.

Notice that  if the last possible read-lock was taken, leaving the availability of $R$ to zero, the system ceiling should be raised to $5$ according to @eq:system-ceiling. This seems to mean that an implementation of the read-write lock needs to keep count of $R$ availability, but a later proof will show it is not necessary.

When $J_2$ takes a write lock on the resource, the ceiling is raised to $ceil(R)_w = 5$, guaranteeing an exclusive access to the resource and preventing a race condition.


= Readers-writer lock implementation in #box[RTIC-eVo] <sec:rw-pass>

As discussed earlier, we need to treat reader and writer accesses differently. In effect, we need to determine two ceilings per resource $R$:

- Reader ceiling $ceil(R)_r$: maximum priority among jobs with _write access_ to the resource.
- Writer ceiling $ceil(R)_w$: maximum priority among jobs with _read_ or _write access_ to the resource.

The `core-pass` (last in the compilation pipeline) takes a DSL with write access to shared resources. That is the core-pass will compute $pi(J)$ of any job $J$ with shared access to the resource $R$.

Assume an upstream `rw-pass` to:

- Identify all jobs with access to each resource $R$ and compute $ceil(R)_w$ correspondingly.
- Transform the DSL read accesses to write accesses.

The `core-pass` will now take into account all accesses (both read and write) when computing the ceiling $ceil(R)_w$.

The backend for the `rw-pass` will introduce a new `read_lock(Fn(&T)->R)` API, which will internally call the existing `lock` API (with ceiling set to $ceil(R)_r$), and pass on an immutable reference to the underlying data structure to the closure argument.

In this way, no additional target specific code generation is required, as the target specific `lock` implementation will be reused.

Notice however, that the `core-pass` will generate write access code for resources marked as reader only. From a safety perspective this is perfectly sound, as the computed ceiling value $ceil(R)$ takes all accesses into account. However, from a modelling perspective rejecting write accesses to jobs with read only privileges would be preferable. Strengthening the model is out of scope for this paper and left as future work.

At this point, we have defined the `rw-pass` contract at high level, in the following we will further detail how the pass may be implemented leveraging the modularity of RTIC-eVo.

=== Implementation sketch

Each pass first parses the input DSL into an internal abstract syntax tree (AST) representation, later used for analysis and DSL transformation. For the purpose of this paper, we make the assumption that *all* shared resources may be accessible for reader-writer access. (In case a resource abstracts underlying hardware, reads may have side effects, thus in a future work we will return to distinguishing such resources from pure data structures.)

The `core-pass` DSL models the system in terms of jobs with local and shared resources. The model is declarative, where each job definition is attributed with the set of shared resources accessible (e.g., `shared = [A, B, C]`, indicates that the job is given access to the shared resources `A`, `B` and `C`).

The `rw-pass` will extend the DSL to allow indicating reader access. For sake of demonstration, we adopt `read_shared = [A, C]` to indicate that the job has read access to resources `A` and `E`.

The `rw-pass` will then perform the following steps:

- Collect the set of reader and writer resources per job.
- Compute the reader and writer ceilings per resource.
- Generate code for reader access, per job.
- Transform the DSL merging `read_shared` into `shared` resources.

In this way, given a valid input model, the `rw-pass` will lower the DSL into a valid `core-pass` model.

= Conclusion

We have shown that SRP compliant readers-write lock can be implemented in RTIC at similar cost to the corresponding single-unit/mutex lock. The declarative model can be enforced using Rust ownership rules. The readers-write lock can be implemented as compiler pass in RTIC eVo.



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
