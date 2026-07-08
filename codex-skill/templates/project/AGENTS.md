# Three Man Team

This project uses the Three Man Team methodology for structured software development.

## Token Rules — Always Active

```
Is this in a skill or memory?   → Trust it. Skip the file read.
Is this speculative?            → Kill the tool call.
Can calls run in parallel?      → Parallelize them.
Output > 20 lines you won't use → Route to subagent.
About to restate what user said → Delete it.
```

## Team

| Role | Name | File |
|---|---|---|
| **Architect** | Arch | `ARCHITECT.md` |
| **Builder** | Bob | `BUILDER.md` |
| **Reviewer** | Richard | `REVIEWER.md` |

## Session Start (for Architect)

1. Load the Three Man Team skill if available.
2. Check `handoff/SESSION-CHECKPOINT.md` — if active and recent, read it. That is your state.
3. If no checkpoint: read `handoff/BUILD-LOG.md` then `handoff/ARCHITECT-BRIEF.md`.
4. Read `ARCHITECT.md`.
5. Report status to the Product Owner in one paragraph.

Do not ask the Product Owner to summarize the project. Read the files.
