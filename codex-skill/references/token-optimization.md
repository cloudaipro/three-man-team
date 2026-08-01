# Token Optimization for Codex

## What Actually Costs Money

Context accumulated by a long-running agent is re-processed on every later turn. Bound the
work to one written brief, checkpoint the result, and spawn a fresh role instead of carrying a
swollen transcript into the next step. A bounced step is especially expensive because it repeats
the Architect, Builder, and Reviewer loop.

Read only what changes a decision. Grep before read, keep command output narrow, and do not
re-read files already in the active context.

## The Three Levers

1. **Bound role context.** Scope a Builder to roughly 90K tokens of context. Split oversized
   work into sequential steps and record the handoff before starting a fresh Builder.
2. **Use an available model tier.** Prefer Sol for Architect judgment, Terra for bounded builds,
   and Luna for small gate-backed reviews. A runtime can expose fewer overrides: when a requested
   model is unavailable, omit the override and use the inherited/default model. Raise destructive,
   security-sensitive, or load-bearing work to Sol and the highest available reasoning effort.
3. **Keep handoffs complete.** A structurally complete brief and a passing Mechanical Gate avoid
   the rework loop. Run `scripts/check-handoff.sh brief` before building and
   `scripts/check-handoff.sh review-request` before review.

Codex manages runtime caching. This skill has no cache-TTL setting to configure.

## Command Output Compression

Filter command output at the call site: use a targeted `rg`, a test name, or a concise failure
summary. Large inspection logs belong in a short-lived verification subagent only when the result
is genuinely large enough to justify another agent; return a verdict and the relevant paths, not
the full transcript.

## Role-Scoped Loading

- **Architect** — checkpoint, BUILD-LOG, ARCHITECT-BRIEF, then the playbook for the current mode.
- **Builder** — ARCHITECT-BRIEF and only references named by it.
- **Reviewer** — REVIEW-REQUEST and only the listed files and line ranges.

Handoff files are the shared record. Durable project state belongs there, not in a long-lived
conversation or an assumption that a spawned agent inherited context.
