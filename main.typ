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
Extend on: The RTIC framework provides and executable model for concurrent applications as a set of static priority, run-to-completion tasks with local and shared resources. At run-time the system is scheduled in compliance to the Stack Resource Policy (SRP), which brings guarantees for race-and deadlock-free access to shared resources. While the original work on SRP allows for multi-unit resources, the RTIC framework restricts the model to single-unit resources.

In this paper we explore multiple-reader, single writer resources in context of the SRP model and the Rust aliasing invariants. We show that Reader-Writer resources can be implemented in RTIC with Zero Cost, while improving schedulability of the application. In the paper, we review the theoretical background and layout the statical analysis and code generation implementation in RTIC for the ARM Cortex-M v7m architecture.

Finally, we evaluate the implementation with a set of benchmarks and real world applications.

Key contributions of this paper include:
- Declarative model for Reader-Writer resources
- Static analysis for Reader-Writer resources
- Code generation for Reader-Writer resources in RTIC
- Evaluation of Reader-Writer resources in RTIC with benchmarks and real world applications

== Background

In this section we review prior work on RTIC and underpinning theory.

=== The RTIC Framework

- Declarative task/resource model in Rust
- Compile time analysis and code generation
- Zero Cost abstractions for implementing the concurrency model


=== The Stack Resource Policy

Here we should review the Baker SRP stuff with a focus on multi-unit resources.

== Reader-Writer Resources

Reader-Writer resources are an edge case of multi-unit resources, where we are allowed to have an infinite number of readers, but only a single write at any time. This model coincides well with the Rust aliasing invariants, which allow for any number of immutable references (&T), but only a single mutable reference (&mut T) at any time.

=== Single-Unit Resources
Figure @fig:single-unit-example shows an example system with a shared single-unit resource between the tasks $t_1,..t_5$ with priorities $1,..5$ respectively. Tasks $t_1, t_4$ and $t_5$ are only reading the shared  while tasks $t_3$ and $t_4$ writes the resource. Under the single-unit model, the ceiling is $π$ is $5$ (the maximum priority of any task accessing the shared resource, $5$ in this case). Arrows in the figure indicate the arrival of requests for task execution.

Filled color indicates the task execution. Height changes indicate that the task has claimed (locked) the shared resource, and the system ceiling being raised accordingly. Hatched color indicates a task being preempted by a higher priority task.

Boxes indicates task blocking due to resource unavailability, notice under SRP tasks may only be blocked from being dispatched, once executing they run to completion free of blocking.

Here we can see that the task $t_4$ is exposed to excessive blocking due to the long-running lock held by tasks $t_1$. $t_5$ is also blocked by $t_4$.


#figure(
  caption: [Example: Single-Unit Resource Sharing],
  // placement: top,
  image("single_unit.drawio.svg", width: 90%),
) <fig:single-unit-example>

=== Reduced Blocking with Reader-Writer Resources

Figure @fig:rw-example shows an example system with a reader/writer resource shared between the tasks $t_1,..t_5$, the rest of the example remains the some as previous section.

We now have two ceilings, $π_w$ (being the maximum priority of any task accessing the resource), and $π_r$ (being the maximum priority of any task writing the resource). In this case $π_w = 5$ and $π_r = 3$.

When $t_1$ claims the shared resource for read access, the system ceiling is only raised to $π_r = 3$, allowing task $t_4$ to be directly executed (without being blocked). Similarly, when $t_4$ claims the resource, the system ceiling is only raised to $π_r = 3$, allowing task $t_5$ to be directly executed (without being blocked). Notice here, the reader ceiling $π_r = 3$ is sufficient to ensure that $t_2$ will execute with exclusive access to the shared resource. This since other competing tasks ($t_4$ and $t_5$) have higher priority than $t_2$, and thus if already executing will prevent $t_2$ from being dispatched. The writer ceiling $π_w = 5$ ensures that when $t_2$ (or $t_3$) requests write access to the resource, both $t_4$ and $t_5$ are blocked from executing, thus race free execution is guaranteed.


#figure(
  caption: [Example: Reader-Writer resource sharing ],
  // placement: top,
  image("rw.drawio.svg", width: 90%),
) <fig:rw-example>

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
