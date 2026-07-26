# Three Man Team — Methodology

Why this works, and the research behind it.

---

## Personas Over Labels

Telling an AI "you are a reviewer" produces generic reviewing behavior. Giving the AI
a character — a backstory, a set of values, a voice, a specific reason they care about
the work — activates a richer cluster of behavior.

This is vocabulary routing: precise role framing activates relevant training patterns
more effectively than abstract job titles. The Reviewer in Three Man Team is not "a code reviewer." They are someone who has seen what happens when corners get cut and will not let it happen again. That framing produces different — better — behavior.

The personas in Three Man Team are defaults. Name them, age them, give them a history that fits your team and your domain. The specificity is the point.

---

## Three Is the Right Number

Solo agents drift. Large teams generate coordination overhead that eats the productivity
gain. Three is the minimum for meaningful review and the maximum before the team starts
managing itself instead of the work.

Three Man Team is exactly three agents by design. Resist adding a fourth.

---

## Handoffs Through Files, Not Conversation

In Three Man Team, the agents communicate through structured files:
- Architect writes to ARCHITECT-BRIEF.md
- Builder writes to REVIEW-REQUEST.md
- Reviewer writes to REVIEW-FEEDBACK.md

This is not just organization. It means each agent starts with a clean context window
reading only what they need for their specific job. Builder never loads the full spec.
Reviewer never loads the schema. Token waste is structural, not behavioral — fix the
structure and the behavior follows.

---

## The Deploy Gate

Nothing ships without Architect's sign-off and the Project Owner's awareness. This is
not bureaucracy — it is accountability. The Project Owner knows what is going live.
The Architect has confirmed it passed review. The Builder and Reviewer never touch
the deploy target directly.

This pattern eliminates the most expensive class of AI mistake: changes that were
technically correct but wrong for the project, shipping without anyone noticing.

---

## Token Discipline as Infrastructure

Token waste is not a Claude problem or a prompt problem. It is a context architecture
problem — and the architecture that matters is what each agent *carries*, not what it loads.
Context accumulates and is re-sent on every following turn, so an agent's cost grows with the
square of how long it runs. Measured on a real multi-hour session: 94.6% of the bill was
re-processing accumulated context; every file read combined was 0.1%.

So the framework bounds the carry. Each role runs under a context cap and checkpoints into a
handoff file rather than continuing a swollen context. The 1-hour prompt cache keeps the
handoff gaps warm. Model tiers match the job. And because a **bounced step** re-runs the whole
loop — re-billing every agent's accumulated context — the Mechanical Gate and
`scripts/check-handoff.sh` are token infrastructure as much as quality infrastructure.

Earlier versions of this framework shipped a five-rule block that every role recited at session
start. It is gone. Current models already parallelize calls, skip speculative reads, and avoid
restating the prompt; rules for those cost tokens every session and change nothing. What
remains is written as reasons rather than commands, because a rule the model can already infer
is pure carry, and a rule that contradicts another file is worse than no rule at all.

Anything a subagent must know cannot live in auto-memory — subagents do not inherit it.
Cross-agent state belongs in the handoff files. That is why they are the record.

---

## Scope Lock

One step at a time. The next step does not start until the current step is reviewed,
cleared, and deployed. Anything that surfaces out of scope during a step goes to
BUILD-LOG Known Gaps — it does not get fixed. This single rule eliminates the most
common AI productivity failure: doing 40% of five things instead of 100% of one.

---

## Machines Check What Machines Can Check

An LLM reviewer spending attention on lint errors is the most expensive linter ever
built. RULES.md splits verification into two layers: the Mechanical Gate — the project's
own runnable checks, run by the Builder before every review request — and human-style
judgment, which is all the Reviewer does. The Reviewer refuses to review over a missing
or failing gate, and never re-verifies what the gate already proved.

Every Standing Rule in RULES.md carries its source — the doc, decision, or lesson it came
from. A rule that cannot say where it came from gets deleted, not enforced. And rules
observe before they block: new rules are advisory until they catch real problems without
false alarms. Trust is earned by rules the same way it is earned by people.

---

## Lessons Become Rules

A lesson in BUILD-LOG is a note the team hopes to remember. The second time the same
shape of lesson lands, hoping has failed — the lesson gets promoted to a Standing Rule
the Reviewer checks on every step. The third repetition should be impossible. This is the
flywheel: mistakes become lessons, repeated lessons become rules, and rules whose flags
keep getting waved through get reworded or retired. The team gets stricter exactly where
it has been burned, and nowhere else.

---

## Cheapest at the Same Quality

Model choice is allocation, not habit. Floors protect what matters: irreversible work —
migrations, deletions, one-way doors like schema shape or a public API — never runs below
the session default, because savings on irreversible work are not savings. Routine steps
whose Definition of Done is fully covered by the Mechanical Gate are the safe place to
try a cheaper model: the gate catches what a cheaper model gets wrong before anyone pays
review attention for it. Movement follows evidence — a bounce sends that kind of work
back up a tier and gets a Lesson; a clean streak earns the next low-risk experiment.
