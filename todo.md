TODO

- please citations consistently at the end of the sentence
- Capitalize section headings correctly
- p. 2 consider adding a citation for the "more than a million on crates.io"
- p. 2 Sec. III-A - not sure a subsection label is needed here with only one subsection
- p. 3 consider making footnote 7 a citation instead
- heksa: p. 3 consider no indent formatting for Theorem and Proof (possibly starting following text on the same line as well)

- Address this: "The authors should provide a motivational example to explain the benefits of rw locks in this case (the introduction only mentions "would" two times)."
- Address this: "Also, to me, the novelty w.r.t. related work is not clear. I was under the impression that a priority ceiling could be already computed offline."

- Address this: "It seems that the chosen approach will allow "read" access by allowing an ongoing read to be preempted by another read, but that the mechanism to achieve this would allow write access to either job in this scenario, which seems to lose some of the benefits of using a Rust-based framework"

- Address this: "the limitations of the approach could be more clearly presented"

- heksa/per: Address this: "For a more general real-time audience, it may be helpful to give a bit more explanation about the Rust aliasing guarantees.  This may also help to give more context about the modeling choices made."

- Address this: "Additional guidance to the reader about the proposed approach could improve the presentation.  For example, early in Sec. IV, (or maybe Sec. V), there could be an explanation that the following work will describe how to take the fundamental components of the SRP and compute the priority ceiling in a way that is consistent with the desired behavior in the RTIC framework."

- The term "lock closures" would benefit from explanation.

- In the theorem, the naming of R_r and R_w initially seems backwards; this could benefit from additional explanation.

- In Sec. VI, clarify if the module rw-pass is a new module that is being presented by this paper or an existing module that can be used.

- Address this: "Only in Sec. VII does it become clear that the manner in which read access is being supported is to redefine the priority ceiling to allow read preemptions, but that this is implemented overall with a write lock.  It would strengthen the paper to have this context described more clearly earlier in the paper."

- Address this misunderstanding: "The paper extends the Stack-based resource protocol (SRP) to
reader-writer locks."

- Address this: I asked myself, if source masking, which RTIC has to use for some Cortex-M machines, is actually race free. Couldn't it be the case that an IRQ is in flight while you mask its source? Then IRQ delivery, in absence of a BASEPRI register, would be racy. I didn't take a look at the NVIC manual but at least for distributed IRQ systems (CLINT+PLIC, GiC, IO/LAPIC) this could be the case, or?

- Address this: If we assume that source masking is synchroneous and fine, couldn't we just mask out only the writer jobs? In your proposed model, a low-priority (L) reader would block a medium-priority (M) reader if a writer with p(J)>p(M) exists. With a more selective model, this could be done in a more fine-grained fashion. Of course, then we are leaving SRP land, but it might be a road worth investigating.

- Check out, if relevant and should be addressed: "Also, I want to point to the Sloth-series of papers (https://www4.cs.fau.de/Research/Sloth/). They are essentially also mapping task systems to interrupt controllers."