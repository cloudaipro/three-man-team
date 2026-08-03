# Build Log

## Current Status

**Active step:** 2 — Await Luna Reviewer
**Last cleared:** Step 1 — 2026-08-02
**Pending deploy:** NO

## Step History

### Step 2 — Luna Max child routing — READY FOR REVIEW, LUNA UNAVAILABLE

Files changed:
- Active Codex routing, Architect template, token guide, porting notes, README, and current v2.5 release records now agree on Luna/Max defaults, Terra/Max fallback, and main-session inheritance for critical child work.
- `test_spawn_contract.py` and `scripts/check-consistency.sh` now bound normal Luna/Max and Terra/Max assertions to distinct Builder and Reviewer blocks, require each role's task name, reject the opposite role's task name, and retain the critical inheritance assertions.

Decisions made:
- Architect routing remains Sol; no Claude routing, historical release record, version, critical flag, deployment state, or global installation changed.
- Runtime fallback used for this attempt: a fresh Terra/Max Builder because Luna is unavailable; `fork_turns: "none"` remains required.
- Critical child work now inherits the main session's model and effort without inheriting its conversation; it does not hardcode a model or effort level.

Gate: PASS — build-log size, brief check, consistency audit, 29 unit tests, current-release parity, and whitespace check passed.
Cost: Builder context below the 75K warning; aggregate audit scanned 56,506 event records but found 0 finalized session/call records and no authoritative price card.
Reviewer findings: role-specific normal-route proof was added; fresh final review cleared all routing and scope checks.
Product Owner correction: critical child work must inherit the main-session model and reasoning effort, not hardcode an escalation model or effort.
Final Product Owner correction: there is no critical-child or fallback branch; every Bob and Richard spawn must explicitly use Luna/Max, otherwise Arch does not spawn it.
Architect verification: 28 tests, consistency, JSON parity, and whitespace checks pass; no child was spawned because Luna is unavailable.
Deploy: not requested.

### Step 1 — Token-efficiency release — CLEARED

Files changed:
- `codex-skill/`, `upgrade`, `scripts/` — lean role deltas, explicit backed-up migration, aggregate audit, routing/budget contracts, tests.
- Release/docs/templates — v2.5.0 registry, handoff evidence/checkpoint templates, consistency checks.

Decisions made:
- Normal Codex upgrades remain additive; `--migrate-role-files` alone authorizes replacement after timestamped backup.
- Audit reports metadata aggregates only; local output: 107 sessions, 13,524 usage-event calls, 7,337,710 input, 6,771,712 cached, 50,728 output, peak 235,748 input; cost is unavailable without an authoritative price card.
- Review corrections: audit accepts only top-level event-envelope metadata and skips malformed token candidates; role migration atomically reserves a unique backup directory and restores originals if replacement fails; the active root handoff checker is now byte-identical to every portable template, rejects empty feedback/checkpoint sections, and has active/template regression coverage.

Gate: PASS — consistency, 25 unit tests, shell syntax, whitespace, and all active handoff modes passed.
Cost: 7 tool calls; Builder context below warning threshold.
Reviewer findings: all Must Fix and Should Fix corrections applied; fresh final review cleared.
Deploy: not requested.

## Known Gaps

- None recorded.

## Lessons

- L-1 — Inherited full chat context can silently override model-cost intent; fresh context is an invariant, not a preference — 2026-08-02.

## Architecture Decisions

- Canonical workflow instructions live in the installed skill; project role files contain only deltas — reduces repeated prompt input while retaining customization — 2026-08-02.
