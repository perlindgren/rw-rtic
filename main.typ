#import "preamble.typ": *
#show: doc => preamble(doc)

#import "@preview/charged-ieee:0.1.4": ieee

// Local overrides
#set figure(placement: top)
#show "readers-write": "readers\u{2011}write"
#show "readers-writer": "readers\u{2011}writer"
#show "single-processor": "single\u{2011}processor"
#show "compiler-verified": "compiler\u{2011}verified"
#show "RISC-V": "RISC\u{2011}V"
#show "Cortex-v7m": "Cortex\u{2011}v7m"
#show "Cortex-M": "Cortex\u{2011}M"
#show "interrupt-specific": "interrupt\u{2011}specific"

#show: ieee.with(
  title: [Work in Progress: Zero-cost Readers-Writer Locks for the RTIC Framework],
  abstract: [
    The RTIC framework provides an executable model for concurrent applications as a set of static priority, run-to-completion jobs with shared resources. At run-time, the system is scheduled in compliance with Stack Resource Policy (SRP), which guarantees race- and deadlock-free execution for single-processor systems. While the original work on SRP allows for multi-unit resources, the RTIC framework uses a model that is constrained to single-unit resources.

    In this paper we explore multi-unit resources that model readers-writer locks in the context of SRP and Rust aliasing invariants. We show that readers-writer resources can be implemented in RTIC at zero cost, while relaxing the constraints of the worst-case-blocking-time-based schedulability test. In the paper, we review the theory/* and lay out the static analysis#heksa[What is meant by 'static analysis'?]*/ and code generation implementations in RTIC for the ARM Cortex-M and RISC-V architectures. // Finally, we evaluate the implementation with a set of benchmarks and real world applications. #heksa[left for ECRTS]
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
  ),
  index-terms: ("Real-Time Systems", "Stack Resource Policy", "Readers-Writer Locks", "RTIC", "Rust"),
  bibliography: bibliography("refs.bib"),
  figure-supplement: [Figure],
)

/* # RTAS notes

  Aiming for "Work in Progress" track

  The WiP sub-track welcomes ongoing and unpublished work, discussing early
  ideas about problems with existing solutions or open problems, new research
  directions, or trends in practice. The review will focus on originality and
  potential impact. Solutions and experimental validation are not necessary. WiP
  papers should not exceed 4 pages and must include “Work in Progress” in the
  title (i.e., Work in Progress: Title of the Paper). Shorter submissions than
  the page limit will not be penalized.
*/

= Introduction

// Motivation, introduce the problem at hand and in brief: RTIC only implements
// binary semaphores, based on a simplified model.
The RTIC framework provides a Rust-language executable model for concurrent applications as a set of static priority, preemptive, run-to-completion jobs with shared resources. At run-time, the system is scheduled in compliance with Stack Resource Policy~#box[(SRP)@baker1990srp-1]---an extension#todo[improvement?] to Priority Ceiling Protocol (PCP)#ref(<sha1987pcp>)---which guarantees a number of desirable features for single-processor scheduling. Features of SRP include race- and deadlock-free execution, bounded, single-context-switch-per-job blocking, prevention of multiple priority inversion, and simple, efficient, single-shared-stack execution.

The original theory for SRP@baker1990srp-1 describes a scheduling policy for a system with multi-unit resources that can be used to implement binary semaphores, readers-writer locks, and general semaphores. RTIC---_however_---only implements a mutex based on the binary semaphore.
// The question then: why does RTIC only implement binary semaphores.
Replacing the binary semaphore with a readers-writer lock lowers the estimate for blocking time, when applicable, meaning that when using scheduling tests including worst-case blocking factors#footnote[E.g., the recurrent worst-case response time test~@audsley1993-applying or the RM specific utilization factor test @sha1989pcpmode for schedulability.], more systems will pass the test.

The rationale for the current constrained implementation of RTIC is that a binary semaphore is sufficient to provide safe access to shared resources/*, and can be implemented in a straightforward, efficient way on most hardware*/. Furthermore, in read-write situations where the highest priority contender for a resource is a job of the writing type, a binary semaphore already provides optimal schedulability under SRP.

// Contributions
However, in situations where the highest priority contender is not a write, a readers-writer lock would improve the response time of the highest priority reader/*, allowing to expedite higher priority tasks that only need to read the resource*/. Therefore, inclusion of the readers-writer lock in RTIC's supported lock types would extend RTIC's applicability across real-time systems with high-priority readers/* requiring priority-ordered preemption among readers of shared resources*/. //Examples include systems with high-priority protection or control tasks that read shared state concurrently with lower-priority monitoring or diagnostic readers, as found in automotive, avionics, and robotic controllers. #valhe[Per, Heksa: please review this claim.]
This paper describes a declarative model of SRP-compliant readers-write locks that can be implemented in RTIC at no additional cost, when compared to a mutex based on a binary semaphore. General multi-unit resources are also of interest. However, an overhead-free implementation has not been identified, and is therefore left for future work.

/* RTAS 2024 FAQ:
 * > The paper should clearly state the research problem, together with
 * > information about the key contributions.
 */
// Contributions
//In this paper, we describe an extension of the declarative, "RTIC restricted model" that adds readers-writer locks.

Key contributions of this paper are:
- We make the key observation and prove that for each lock-operation, we can compute a distinct ceiling value at compile time.
- We show that this allows us to implement RW-SRP compliant resource protection in constant time.
- Declarative model for the implementation of a readers-writer lock in RTIC with no additional overhead when compared to the binary semaphore based mutex. //The system still schedules jobs identically to SRP.#valhe[Should it be mentioned here, that the deviation allows us to raise the system ceiling to a compile-time known constant with each lock operation?]
- The observation that the implementation aligns the SRP compliant readers-writer lock with the Rust aliasing model, allowing lock APIs to integrate seamlessly with Rust's reference semantics.
//- Static analysis for readers-writer resources#heksa[What is meant by 'static analysis'?]#heksa[Left for ECRTS.]
- Description of target-independent code generation for readers-writer resources in RTIC.
//- Evaluation of readers-writer resources in RTIC with benchmarks and real world applications #heksa(position: "inline")[Left for ECRTS]

= Prior work

== SRP-based scheduling

PCP describes a locking protocol for binary semaphores, for which priority inversion is bounded by execution time of the longest critical section of a lower-priority job. @sha1987pcp PCP has been extended to apply to readers-writer resources@sha1989pcpmode,#valhe[I don't find a mention of readers-write resources on this paper.] and multi-processor systems @rajkumar1988multi.#valhe[SRP is defined to single-core only. Why is multi-processor mentioned here?] SRP extends PCP and allows the use of both static and dynamic priority assignments, and multi-unit resources.~@baker1991srp-journal/* EDF, RM, deadline-monotonic scheduling policies @baker1991srp-journal and static LST policies @baker1990srp-1.#valhe[If we keep the mention of multicore PCP, we need to specify that SRP is for single-core.]*/ PCP and SRP-based methods remain of interest for hard real-time scheduling, as conventional OSes cannot provide bounded blocking suitable for real-time schedulability analysis.~@baker1991srp-journal @buttazzo2011-hard

== Rust aliasing guarantees

The Rust rules regarding _place_ and _move_ expressions#footnote[@rust-ref[[expr.place-value.value-expr-kinds], [expr.move]]], and _pointer_#footnote[@rust-ref[[type.pointer.reference]]] types require that any memory location referenced by the program is either shared for reading, or only accessible for writing from _one_ code location concurrently, in absence of _interior mutability_ and _raw pointer dereferences_#footnote[@rust-ref[[interior-mut], [type.pointer.raw.safety]]]. To access the exceptions, an explicit, `unsafe` code block is always required. The alias rules can be extended to apply to other kinds of resources including hardware peripherals by modeling them as #box[Zero-Sized] Types~(ZSTs).

/*
It's useful to observe#heksa[It's unclear whether this _is_ or _should_ be observed in SRP theory. Rust may allow enforcing of exclusivity requirements "beyond" the theory.] that for the purposes of behavioral non-interference, memory and hardware behave differently. Unlike memory, hardware may change its internal state on reads. To properly integrate with the Rust aliasing rules, this _can_ and _should_ be modeled at the hardware abstraction layer. The problem and its solution are well-demonstrated by the `Read` trait in the `embedded-io` community library, presented in @lst:embedded-io-read.

#figure(
  caption: [`embedded_io::Read`#footnote[https://docs.rs/embedded-io/latest/embedded_io/trait.Read.html] trait (truncated) is used to retrieve bytes from a hardware peripheral. As a result, the hardware-internal buffer is typically flushed.],
  ```rust
  pub trait Read {
    // `&mut self`: caller is required to
    // use a mutable reference to call this
    // method.
    fn read(&mut self, buf: &mut [u8])
      -> Result<usize, _>;
  }
  ```,
)<lst:embedded-io-read>
*/

Rust's alias rules coincide with the semantics of readers-writer locks. In other words, the interfaces of the lock may grant shared references to readers, while mutable references can be granted to writers, all the while conforming to Rust's notion of safety. Both kinds of references should be scoped to match the duration of the lock.

== RTIC//, RTIC v2, RTIC eVo / MRTIC

The RTIC framework is a Rust-first, free-and-open-source, real-time framework, rooted in research on modeling and implementation of (hard) real-time systems. Over the last decade, the first two major versions of RTIC---cortex-m-rtic and RTIC v2---have gained wide adoption with a combined download count of more than a million on crates.io.
For the developer, RTIC provides a declarative, SRP-compliant, tasks-and-resources model as a thin, integrated DSL in the form of attributes applied on _items_#footnote[@rust-ref[[items]]] in Rust code. RTIC also provides facilities for compile time analysis, code generation, and the zero-cost abstractions for implementing the concurrency model.

Supplemental to the mainline RTIC, a research prototype@mrtic2025 of the framework has been developed to study---in a modular way---implementations of features including syntax extensions and extended source code analysis.
//However, the underlying code base is largerly monolithic, hampering community contributions and evolvability. To this end, a modular re-implementation (RTIC-eVo in the following) has recently been proposed@mrtic2025. While still experimental, it serves the purpose of prototyping new features and concepts for RTIC.
In the research prototype/*RTIC-eVo*/, the compilation process is separated into a set of subsequent passes that gradually lower the /*Domain Specific Language*/ DSL-augmented source artifact towards a plain Rust implementation, and then further into an executable/* (thus RTIC can be seen as an executable model)*/. /*The user facing DSL is defined by a distribution, which composes a selected set of compilation passes and their target-specific backend implementations. The framework is highly flexible, as new passes (and their backends) can be developed and tested in isolation before being integrated into a distribution. The only requirement is that the output DSL of each pass conforms to the input DSL of subsequent passes.*/
In @sec:rw-pass, the modular research prototype is leveraged to sketch out the implementation of readers-writer resources/* in RTIC-eVo*/.

= Baseline model (SRP) /* "Existing theory */

SRP assumes a fixed number of run-to-completion jobs running on a single core, sharing a fixed number of multi-unit resources. The maximum resource needs are assumed to be known _a priori_. Jobs are assumed to request anything from zero to the full amount of a multi-unit resource.

In SRP, a job#footnote({
  set text(hyphenate: true)
  [The original theory distinguishes a job $J$ and it's execution or request $cal(J)$. However, in this paper, only $J$ is used, ass with static priority jobs, this distinction is not necessary.]
}) $J$ will preempt another if its _preemption level_ $pi(J)$ is higher than the _system ceiling_ $macron(Pi)$ and it's the oldest and highest priority of any pending job. The preemption level of a job $pi(J)$ is defined as any static function that satisfies

$
  p(J') > p(J) "and" J' "arrives later" => pi(J') > pi(J).
$

For instance, in RTIC, the chosen function is $pi(J) = p(J)$, where $p(J)$ is a programmer-selected, static priority for the job.

The system ceiling $macron(Pi)$ is defined as the maximum of current _resource ceilings_, which are values assigned to each resource that depend on their own, current availability. The resource ceiling $ceil(R)$ must always be equal or bigger than the preemption level of the running job, and all the preemption levels of jobs that might need $R$ more than what is currently available. Formally, given the system has resources $R_i, i in {0, ..., m}$

$
  macron(Pi) = max({ceil(R_i) mid(|) i in {0, ..., m}}).
$<eq:system-ceiling>

From the definition, it follows that the system ceiling $macron(Pi)$ changes only when a resource is locked or unlocked. When a lock on $R$ is obtained, the system ceiling is updated to

$
  macron(Pi)_"new" = max(macron(Pi)_"cur", ceil(R)_v_R),
$<eq:new-ceiling>

where $macron(Pi)_"cur"$ is the prior system ceiling, and $ceil(R)_v_R$ is the the ceiling of $R$ corresponding to the remaining amount of unlocked $R$, denoted by $v_R$.

== Readers-writer Resources

Readers-writer resources are a special case of multi-unit resources. In the SRP context, they can be modeled as an abstract resource with a count equaling the number of jobs accessing the resource, and writers consuming all units of the resource, while readers consume only one unit. This allows multiple readers but only one writer at a time.

Generally, an infinite number of readers is allowed, but only a single write at any time. This model coincides with the Rust aliasing model, which allows for any number of immutable references (`&T`), but only a single #box[mutable reference (`&mut T`)] at any time.

= RTIC restricted model

RTIC compiles the static priority, programmer-defined jobs to interrupt handlers that get a corresponding, relative priority level. The jobs---now ISRs---are run in priority order by the hardware. The targets supported by RTIC must have prioritized interrupts and support for interrupt masking. The interrupt masking is used to create a hardware implementation of the SRP defined system ceiling.

In RTIC so far, only single-unit resources have been allowed, as with them, the system ceiling needs to be updated to a single, compile-time known number for each resource. RTIC leverages this to implement near zero-cost locking. With each lock operation on a resource, the interrupts with a lower priority than the compile-time known number are disabled. The means of disabling the appropriate interrupts depend on the implementation target.

Formally, in RTIC, the preemption levels equal the priority: $pi = p$, and the resource ceiling is defined as

$
  ceil(R) = max({0} union { p(J) mid(|) v_R < mu_R (J)}),
$<eq:resource-ceiling>

where $v_R$ is the current availability of $R$ and $mu_R (J)$ is the maximum need of job $J$ for $R$.

With this set-up and using only single-unit resources, HW implements SRP compliant scheduling when each lock operation on $R$ raises the system ceiling to

$
  macron(Pi)_"new" = max(macron(Pi)_"cur", R_0)
$<eq:rtic-new-ceiling>

and restores the old value upon unlock. In combination with the Rust ownership system and compliance with SRP, controlled access to shared, single-unit resources is guaranteed.

== ARM Cortex-M

/*Cortex-M family of microcontrollers implement a set of prioritized exception handlers and between 32 to 480 external interrupt lines.*/ On Cortex-M, external interrupts can be controlled and configured with the Nested Vectored Interrupt Controller (NVIC). Registers called `NVIC_IPR` control the priorities of the external interrupts.

/*Pending interrupts are dispatched in priority order, and a higher priority interrupt handler will preempt a lower priority one.*/ The context of an preempted ISR is pushed to stack and restored automatically by the hardware. An ISR can be preempted safely while it is saving the context, increasing the responsiveness of high priority ISRs.

Depending on the MCU, interrupts can be masked either using the `BASEPRI` register, or if it's not implemented, the `NVIC_ISER` and `NVIC_ICER` registers. The `BASEPRI` register blocks interrupts of lower or equal priority than its value, but it can not block interrupts with maximum possible priority. /*When RTIC needs to prevent other maximum priority interrupts from preempting the currently running one, interrupts are disabled globally. */The `NVIC_ISER` and `NVIC_ICER` registers enable or disable individual interrupts, each bit in the registers corresponding to a specific interrupt.

== RISC-V

The base RISC-V ISA@riscv-unprivileged-spec does not require a sufficient mechanism for individually configurable preemption levels or threshold-based interrupt filtering. Instead, this /*domain-specific */mechanism is typically supplied through an interrupt controller specification. For instance, the CLIC@riscv-clic-spec defines an adjustable interrupt threshold register (`mintthresh`) that can be used to filter interrupts by preemption level. For interrupt-specific priority and preemption controls, the CLIC defines the `clicintctl` register. On RISC-V, when multiple lines are pended, priority is used to determine which interrupt handler is to be dispatched first, while preemption level is used control preemptability.~@lindgren2023hw-support //Finally, individually configurable interrupt priorities can be emulated on unsupported platforms. @cardenas2025slic#heksa[RTIC can be emulated on any RISC-V (SLIC)]

/*
= Example of determining the resource ceilings from @baker1990srp-1
#heksa[Left for ECRTS]

Assume there are jobs $J_x in J_1, J_2, J_3$, with priorities and preemption levels corresponding to their index ($pi(J_x)=p(J_x)=x$), and resources $R_1, R_2, R_3$ with amounts $N(R_1) = 3$, $N(R_2) = 1$, $N(R_3) = 3$, and the jobs have the maximum resource needs as specified in @tab:example-needs.


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
*/

= SRP compliant readers-writer lock<sect:proof>

As already discussed, the current version of RTIC uses only single-unit resources. The key contribution of this paper is to show that with multi-unit resources of the readers-writer type, there is still a single compile-time known number that the system ceiling needs to be raised to with each lock operation---just like in @eq:rtic-new-ceiling, but with a distinction of whether the lock is a read or a write lock. /*For this reason, no extra overhead is introduced to RTIC when implementing the readers-writer locks.*/ A formalization and a proof of the statements follows:

*Theorem*

Assuming @eq:resource-ceiling and $pi = p$, /*when a lock is taken on a readers/writer resource $R$, the system ceiling can be raised to a compile-time known constant, $ceil(R)_r$ for read and $ceil(R)_w$ for write, and the system is still compliant to SRP.

                                            Formally,*/ SRP compliance is maintained when:

+ upon taking a read-lock of resource $R$ is taken, the system ceiling $macron(Pi)$ is updated to
  $ macron(Pi) = max(macron(Pi)_"cur", ceil(R)_r) $<eq:rw-lock-ceil-r>

  where $ceil(R)_r$ is the highest preemption level of jobs with write-access to $R$, and
+ upon taking a write-lock of resource $R$, the system ceiling $macron(Pi)$ changes to
  $ macron(Pi) = max(macron(Pi)_"cur", ceil(R)_w), $<eq:rw-lock-ceil-w>

  where $ceil(R)_w$ is the highest preemption level of jobs that need $R$.

*Proof*

Assume the system has resources $R_1, ..., R_n$ and their availability is $v_R_1, ... v_R_n$ before taking the lock. /*Now, by definition @eq:system-ceiling, the system ceiling is
                                                                                                                     $
                                                                                                                       macron(Pi)_"cur" & = max {ceil(R_i)_v_R_i mid(|) i in {1, ..., n}}
                                                                                                                     $<eq:proof0>*/
Assume the read or write lock operation concerns resource $R_m$, $m in 1, ..., n$.
/*
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
  ceil(R_m)_v_(R_m)^' >= ceil(R_m)_v_(R_m),
$<eq:proof1.5>
it follows that
$
  =>^(#ref(<eq:proof1>) #ref(<eq:proof1.5>)) macron(Pi) = & max(
                                                              { macron(Pi)_"cur"} \
                                                                                  & union max{pi(J) mid(|) v'_R_m < mu_R_m (J)}
                                                            ).
$<eq:proof2>
*/
It can be shown that after the locking, the system ceiling is
$
  macron(Pi) = & max(
                   { macron(Pi)_"cur"} \
                                       & union max{pi(J) mid(|) v'_R_m < mu_R_m (J)}
                 ),
$<eq:proof2>
where $v_(R_m)^'$ is the new availability of resource $R_m$.

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

In the former case, the condition $v'_R_m < mu_R_m (J)$ in @eq:proof2 corresponds to $J$ having write access to $R_m$, proving @eq:rw-lock-ceil-r.

/*In the latter case, the condition $v'_R_m < mu_R_m (J)$ corresponds $J$ having access to $R_m$ in general, as both reading and writing jobs are blocked when there is zero $R_m$, i.e.

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
$<eq:proof4>*/

In the latter case, @eq:proof2 can be expanded to
$
  macron(Pi)
  = max(
          & { macron(Pi)_"cur"} \
    union & {pi(J) mid(|) J "has read access to" R_m} \
    union & {pi(J) mid(|) J "has write access to" R_m}
  ).
$<eq:proof4>

Assuming the same job does not take several nested read locks, for there to be zero $R_m$ after a read lock, the job must have preempted all other jobs that only read $R_m$ while they were holding a lock on resource $R_m$. For that to be possible, the job has to be the highest priority job with read access to $R_m$, i.e.,
$
  pi(t_"cur") = max{pi(J) mid(|) J "has read access to" R_m}
$<eq:proof5>
Continuing from @eq:proof4,
$
  =>^(#ref(<eq:proof5>)) macron(Pi) = max(
                                                     & { macron(Pi)_"cur"} union {pi(t_"cur")} \
    union {pi(J) mid(|) J "has write access to" R_m}
  )\
  =^(macron(Pi) >= pi(J_"cur")) max(
    { macron(Pi)_"cur"} \
    union {pi(J) mid(|) J "has write access to" R_m}
  ) \
  = max(macron(Pi)_"cur", ceil(R)_r),
$
which proves @eq:rw-lock-ceil-r.


*Proof for @eq:rw-lock-ceil-w (write-lock):*

If the lock was a write-lock, $v'_R_m = 0$. Continuing from~@eq:proof2
$
  => macron(Pi) = & max({ macron(Pi)_"cur"} union {pi(J) mid(|) 0 < mu_R_m (J)}) \
                = & max({ macron(Pi)_"cur"} union {pi(J) mid(|) J "needs" R_m}) \
                = & max(macron(Pi)_"cur", ceil(R)_w),
$
proving @eq:rw-lock-ceil-w.

/*
= Some title here

Implementing readers-writers locks improves schedulability when the implementation introduces no overhead.#valhe[Incorrect. Update.]

#todo[Figures have incorrect arrival label. A $t_1$ should be $t_5$.]
@fig:example[Figure] shows an example system with some shared single-unit resource $R$ between the jobs $J_1,..J_5$ with priorities $1,..5$ respectively. Tasks $J_1, J_4$ and $J_5$ are only reading the shared  while jobs $J_3$ and $J_4$ writes the resource. Under the single-unit model, with each lock, the system ceiling is raised to $ceil(R)_0 = 5$ after each lock operation on the read-write resource (the maximum priority of any job accessing the shared resource, $5$ in this case). Arrows in the figure indicate the arrival of requests for job execution.

Filled color indicates the job execution. The bold black line indicates the current system ceiling $macron(Pi)$. A closed lock symbol indicates a lock being taken, and an open lock symbol indicates a lock being released. Hatched color indicates a job being blocked, and a cross-hatched color indicates the blocking is due to a higher priority job.#todo[Needs to be updated.]

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

=== Behavior difference between mutex locks and readers-writers locks

@fig:example[Figure] Bottom, shows an example system with a reader/writer resource shared between the jobs $J_1,..J_5$; the rest of the example remains the same as previous section. The dark lock symbols indicate a write lock and the light lock symbols indicate a read lock.

Now, with each write lock, the system ceiling is raised to $ceil(R)_w$, the maximum priority of any job _accessing_ the resource, and with each read lock, to $ceil(R)_r$, the maximum priority of any job _writing_ the resource. In this case $ceil(R)_w = 5$ and $ceil(R)_r = 3$.

When $J_1$ claims the shared resource for read access, the system ceiling raised to $ceil(R)_r = 3$, allowing job $J_4$ to be directly executed (without being blocked). Similarly, when $J_4$ claims the resource, the system ceiling is raised to $ceil(R)_r = 3$.

Notice that  if the last possible read-lock was taken, leaving the availability of $R$ to zero, the system ceiling should be raised to $5$ according to @eq:system-ceiling. This seems to mean that an implementation of the readers-writer lock needs to keep count of $R$ availability, but the proof in @sect:proof shows it's not necessary.

When $J_2$ takes a write lock on the resource, the ceiling is raised to $ceil(R)_w = 5$, guaranteeing an exclusive access to the resource and preventing a race condition.
*/

= Readers-writer lock implementation in RTIC/*#box[RTIC-eVo]*/<sec:rw-pass>

Read and write accesses need to be treated as distinct from each other.  In effect, two ceilings per resource $R$ are required:

- reader ceiling $ceil(R)_r$: maximum priority among jobs with _write access_ to the resource, and
- writer ceiling $ceil(R)_w$: maximum priority among jobs with _read or write access_ to the resource.

The protocol bindings and necessary analysis can be provided by a module ("`rw-pass`") implementing the read-lock API and a pre-compilation pass. As the API, a #box[`read_lock(Fn(&T)->R)`] method should be provided, which should call the pre-existing `lock` API---with the ceiling set to $ceil(R)_r$---and pass a shared, immutable reference to the underlying data structure as the closure argument. Then, during pre-compilation `rw-pass` should:

- identify all jobs with access to each resource $R$ and compute $ceil(R)_w$ correspondingly, and
- transform all DSL read accesses to write accesses to conform to the conventional model.

The main DSL compilation pass /*`core-pass`*/ takes as input the DSL with knowledge of all write accesses to shared resources. Then, the $pi(J)$ of any job $J$ with shared access to the resource $R$ is computed.
The implementation /*`core-pass`*/ will now take into account all accesses (both read and write) when computing the ceiling $ceil(R)_w$.
In this way, no additional target specific code generation is required, as the target specific `lock` implementation can be reused.

At this point, we have defined the `rw-pass` contract at high level. In the following, we will further detail how the pass may be implemented leveraging the modularity of RTIC-eVo.

/*
== Implementation sketch

Each pass first parses the input DSL into an internal abstract syntax tree (AST) representation, later used for analysis and DSL transformation. For the purpose of this paper, we make the assumption that *all* shared resources may be accessible for reader-writer access. (In case a resource abstracts underlying hardware, reads may have side effects, thus in a future work we will return to distinguishing such resources from pure data structures.)

The final pass /*`core-pass`*/ DSL models the system in terms of jobs with local and shared resources. The model is declarative, where each job definition is attributed with the set of shared resources accessible (e.g., `shared = [A, B, C]`, indicates that the job is given access to the shared resources `A`, `B` and `C`).

The `rw-pass` will extend the DSL to allow indicating reader access. For sake of demonstration, we adopt `read_shared = [A, C]` to indicate that the job has read access to resources `A` and `C`.

The `rw-pass` will then perform the following steps:

- Collect the set of reader and writer resources per job.
- Compute the reader and writer ceilings per resource.
- Generate code for reader access, per job.
- Transform the DSL merging `read_shared` into `shared` resources.

In this way, given a valid input model, the `rw-pass` will lower the DSL into a valid model in the final pass/*`core-pass`*/.
*/
/*
= Cool use cases
#heksa[Left for ECRTs.]
- Update set point in low-priority. Execute read algorithm / motor control in high priority.
*/

= Future work

#todo(position: "inline")[Future work: actual code]

With the current implementation, write access code will be generated for resources that are technically read-only. From a safety perspective this is perfectly sound, as the computed ceiling value $ceil(R)$ does not differentiate between access kind. However, from a modeling perspective rejecting write accesses to jobs with read only privileges would be preferable. Strengthening the model is out of scope for this paper and left as future work.

For general multi-unit resources, the new system ceiling value is different for each number of remaining resources. An overhead-free implementation has not been identified, and the viability of general multi-resource support for RTIC is left for future work.

= Conclusion

We have shown that the declarative lock behavior described in SRP can be relaxed for readable-writable resources, and a readers-write lock can be implemented in RTIC at similar cost to the corresponding single-unit/mutex lock. The declarative model can be enforced using Rust ownership rules. The readers-write lock can be implemented as compiler pass in RTIC eVo.


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
