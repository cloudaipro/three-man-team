# Three-Man-Team Repository Rules

## Mechanical Gate

| Command | Proves |
|---|---|
| `awk 'END{exit (NR>400)}' handoff/BUILD-LOG.md` | The active build log remains a compact handoff |
| `scripts/check-handoff.sh brief` | The active brief is structurally complete |
| `bash scripts/check-consistency.sh` | Release, templates, and setup contracts remain synchronized |
| `python3 -m unittest discover -s codex-skill/tests -v` | Codex setup, upgrade, and workflow behavior pass regression tests |
| `git diff --check` | Changed text has no whitespace errors |

## Standing Rules

| # | Rule | Source | Fixable by | Status |
|---|---|---|---|---|
| R1 | Preserve unrelated log-file changes already present in the worktree byte-for-byte: do not restore, stage, edit, or delete them. | Initial repository inspection | builder | blocking |
| R2 | Generated project role files contain project deltas only; canonical workflow remains in the installed skill. | Usage audit finding | builder | blocking |
| R3 | Existing customized role files are replaced only through an explicit, backup-producing migration option. | Upgrade safety contract | builder | blocking |
| R4 | Child agents always use fresh context; model fallback must never change `fork_turns` to `all`. | Usage audit finding | builder | blocking |

## Iron Rules

1. The Builder never edits `handoff/REVIEW-FEEDBACK.md`; the Reviewer never edits code.
2. A failing Mechanical Gate never reaches the Reviewer.
3. Nothing is published or deployed without owner approval.
4. Out-of-scope work is logged, not added to this step.
5. Handoff files are the record.
