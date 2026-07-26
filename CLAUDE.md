# Three Man Team — Session Router

## What Costs Money Here

Context you accumulate is re-billed on every following turn. Cost grows with the square of how
long an agent runs — not with how many files it opened. On a measured session, 94.6% of the
bill was re-processing accumulated context; every file read combined was 0.1%. The single most
expensive event is a **bounced step**: it re-runs the whole loop and re-bills every agent's
accumulated context.

Read what changes a decision. Grep before Read. Bound how long you run, and checkpoint and
respawn rather than continuing a swollen context. Reasoning: `docs/token-optimization.md`.

## Gotchas

- Handoff files are the record. A decision that lives only in chat does not exist.
- Skills and memories are pointers, not proof — verify `file:line` before acting on one.
- The gate's `awk 'END{exit (NR>400)}'` form is deliberate. `test "$(wc -l < f)"` exits 0 on a
  missing file under zsh and reports a green gate for a file that is not there.
- The framework ships three forks of the same files — `templates/project-folder/`,
  `templates/generic/`, `codex-skill/`. Edit one, copy to the rest, then run
  `scripts/check-consistency.sh`. Skipping that is how the token-optimizer skill went stale.

---

## Session Start — Every Role

1. Load your token-optimizer skill if you have one — first, before anything else.
2. Check `SESSION-CHECKPOINT.md` — if active and recent, read it. That is your state.
3. Load your role file — copied to project root → `ARCHITECT.md` · `BUILDER.md` · `REVIEWER.md`
4. If no checkpoint — Architect reads `BUILD-LOG.md` + `ARCHITECT-BRIEF.md` only.

**Project Owner role is set by the human. Do not ask.**

---

## Reference Files — On Demand Only

| File | Load when |
|---|---|
| Project spec | Architect needs it; checkpoint doesn't cover it |
| ARCHITECT-BRIEF.md | Builder and Reviewer load at task start |
| BUILD-LOG.md | Architect checks status; Builder updates when done |
| REVIEW-REQUEST.md | Reviewer loads at review start |
| REVIEW-FEEDBACK.md | Builder loads after Reviewer signals done |
| playbooks/PLANNING.md | Architect enters Direction mode — before any brief |
| playbooks/DIAGNOSIS.md | Architect enters Diagnose mode |
| playbooks/BRIEF-EXAMPLES.md | First brief · after a bounced step · multi-step feature |

