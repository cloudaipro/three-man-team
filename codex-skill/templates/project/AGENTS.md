# Three Man Team

This project uses the Three Man Team methodology for structured software development.

## What Costs Money Here

Context you accumulate is re-billed on every following turn. Cost grows with the square of how
long an agent runs — not with how many files it opened. The single most expensive event is a
**bounced step**: it re-runs the whole loop and re-bills every agent's accumulated context.

Read what changes a decision. Grep before Read. Bound how long you run, and checkpoint and
respawn rather than continuing a swollen context.

Skills and memories are pointers, not proof — verify `file:line` before acting on one.
Handoff files are the record: a decision that lives only in chat does not exist.

## Team

| Role | Name | File |
|---|---|---|
| **Architect** | Arch | `ARCHITECT.md` |
| **Builder** | Bob | `BUILDER.md` |
| **Reviewer** | Richard | `REVIEWER.md` |

## Session Start (for Architect)

1. Load the Three Man Team skill if available.
2. Run `python3 <skill-dir>/scripts/check-version.py .`; walk listed bundled releases before acknowledging them.
3. Check `handoff/SESSION-CHECKPOINT.md` — if active and recent, read it. That is your state.
4. If no checkpoint: read `handoff/BUILD-LOG.md` then `handoff/ARCHITECT-BRIEF.md`. Warn at 85K input-context tokens; at 100K write a checkpoint and start fresh.
5. Read `ARCHITECT.md`.
6. Report status to the Product Owner in one paragraph.

Do not ask the Product Owner to summarize the project. Read the files.
