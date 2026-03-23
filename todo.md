# TODO

## To be addressed

- (see formatting todo's below) please citations consistently at the end of the sentence
- heksa: p. 3 consider no indent formatting for Theorem and Proof (possibly starting following text on the same line as well)

- heksa: Address this: "The authors should provide a motivational example to explain the benefits of rw locks in this case (the introduction only mentions "would" two times)."
- valhe: Address this: "Also, to me, the novelty w.r.t. related work is not clear. I was under the impression that a priority ceiling could be already computed offline."





- Address this: I asked myself, if source masking, which RTIC has to use for some Cortex-M machines, is actually race free. Couldn't it be the case that an IRQ is in flight while you mask its source? Then IRQ delivery, in absence of a BASEPRI register, would be racy. I didn't take a look at the NVIC manual but at least for distributed IRQ systems (CLINT+PLIC, GiC, IO/LAPIC) this could be the case, or?

- Check out, if relevant and should be addressed: "Also, I want to point to the Sloth-series of papers (https://www4.cs.fau.de/Research/Sloth/). They are essentially also mapping task systems to interrupt controllers."

## IEEE formatting stuff

- [x] heksa: "Some articles do not conform to an outline style for theorems and proofs that is easily transformed into the normal heading sequence. The preferred style is to set the head giving the theorem number as a tertiary heading (no Arabic numeral preceding) and the proof head as a quaternary head"

- Example of acceptable way to cite in text: "According to [1]; as demonstrated in [2]; as shown by Brown [4], [5]; as mentioned earlier [2], [4], [5], [6], [7], [9]; Smith [4] and Brown and Jones [5]; Wood et al. [7]"

- "IEEE publications must list names of all authors, up to six names. If there are more than six names listed, use the primary author’s name followed by “et al.” For non-IEEE publications, “et al.” may be used if additional names are not provided."

- Add date of publication for all refs. If not known, use this format: "BAR50 Series Infineon PIN Diode Datasheet. (n.d.). [Online]. Available: http://www.infineon.com"


## Willingly ignored

- Address this: "Only in Sec. VII does it become clear that the manner in which read access is being supported is to redefine the priority ceiling to allow read preemptions, but that this is implemented overall with a write lock.  It would strengthen the paper to have this context described more clearly earlier in the paper."
  - Ignored due to: it is not relevant how we implement this. This is only an example implementation.

- Address this: "Additional guidance to the reader about the proposed approach could improve the presentation.  For example, early in Sec. IV, (or maybe Sec. V), there could be an explanation that the following work will describe how to take the fundamental components of the SRP and compute the priority ceiling in a way that is consistent with the desired behavior in the RTIC framework."
  - Ignored due to: ... Too vague. It should be clear already. And, what does this comment even mean.

- Address this: If we assume that source masking is synchroneous and fine, couldn't we just mask out only the writer jobs? In your proposed model, a low-priority (L) reader would block a medium-priority (M) reader if a writer with p(J)>p(M) exists. With a more selective model, this could be done in a more fine-grained fashion. Of course, then we are leaving SRP land, but it might be a road worth investigating.
  - Ignored due to: We would indeed leave SRP land, lol. And maybe get deadlocks etc.

- Address this misunderstanding: "The paper extends the Stack-based resource protocol (SRP) to
reader-writer locks."
  - Ignored due to: we clearly state in the introduction that SRP had rw resources already. Maybe this commenter said SRP instead of RTIC accidentally.