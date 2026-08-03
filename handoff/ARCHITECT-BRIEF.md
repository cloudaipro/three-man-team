# Architect Brief

## Step 2 — Unconditional Luna Max child routing

### Decisions

- Keep Architect routing unchanged: preferred Sol model and reasoning effort controlled by the main Codex session.
- Set Builder default to `model: "gpt-5.6-luna"` with `reasoning_effort: "max"`.
- Set Reviewer default to `model: "gpt-5.6-luna"` with `reasoning_effort: "max"`.
- Preserve `fork_turns: "none"` for every child route.
- Define exactly one spawn configuration for Builder and one for Reviewer: Luna with `reasoning_effort: "max"`.
- Remove Terra fallback, main-session inheritance, critical-child classification, and every alternate child model/effort route.
- If Luna is unavailable, Architect must not spawn the role on another configuration; report the unavailable required model to the Product Owner.
- Update all active Codex instructions, current v2.5 documentation/release text, and executable consistency/tests. Do not rewrite historical release records.

### Build Order

1. Update canonical Codex skill and Architect role routing.
2. Synchronize token guidance, porting notes, README, changelog, and v2.5 release copies.
3. Strengthen tests and consistency assertions for both Luna/Max defaults and Terra/Max fallback.
4. Run the complete mechanical gate and prepare review evidence.

### Out of Scope

- Do not change Architect's model or reasoning-effort policy.
- Do not change the Claude build's Opus, Sonnet, or Haiku routing.
- Do not modify historical release records such as v2.1.0.
- Do not alter context thresholds, caching behavior, role responsibilities, project code, logs, or global installations.
- Do not commit, push, tag, publish, or deploy.

### Flags

- The current runtime cannot instantiate Luna, so no Builder or Reviewer may be spawned for this correction. Architect implements and verifies it directly.
- `max` is the literal supported `reasoning_effort` value requested by the Product Owner; do not substitute `high`, `xhigh`, or `ultra`.
- `critical` remains a release-registry concept only; it is not a child-agent routing concept.
- Synthetic usage-audit fixtures mentioning Terra are test data, not role-routing policy, and need not change.

### Cost Budget

- Architect: warning 85K / fresh-session checkpoint 100K; Builder: 75K / 90K; Reviewer: 50K / 60K.
- No child agents are authorized because the required Luna model is unavailable in this runtime.
- Preserve concise command output and record the unavailable-model limitation in the review request.

### Owner Validation Batch

- Disposition: no device-only validation is required; automated contract tests and diff review form the validation batch.

### Definition of Done

- [ ] `rg -n 'gpt-5.6-luna.*reasoning_effort: "max"' codex-skill/SKILL.md` finds both active spawn examples.
- [ ] `python3 -B -m unittest discover -s codex-skill/tests -v` exits zero.
- [ ] `bash scripts/check-consistency.sh` exits zero.
- [ ] `git diff --check` exits zero.
- [ ] Active Codex instructions define only Luna/Max for Builder and Reviewer, no alternate child route, and unchanged Architect routing.
- [ ] README, porting notes, changelog, v2.5 release copies, tests, and consistency assertions agree.

## Builder Plan

Remove every alternate child model/effort route, synchronize active/current v2.5 surfaces and exact regression assertions around unconditional Luna/Max, run the full gate, and produce a concise handoff.

Architect approval: YES

## Pre-Flight Check

- Cause or symptom: the framework invented fallback and critical-child branches that contradict the Product Owner's single Luna/Max child configuration.
- Verified vs assumed: verified with repository-wide `rg` plus `codex-skill/SKILL.md`, Architect template, token guide, porting notes, consistency script, and spawn tests.
- Risk placement: the main risk is partial routing drift; exact cross-file assertions test it in this single step.
- Boundary: Arch, Claude routing, historical releases, thresholds, logs, installs, and deployment are explicitly out of scope.
- Guessing surface: there is none—both roles always request Luna/Max; unavailable Luna blocks spawning.
- Verification: exact routing grep, full unit suite, consistency audit, and whitespace check.
- Silent product decisions: Bob and Richard can no longer spawn on Terra or main-session settings when Luna is unavailable.
- Mechanical preflight: `scripts/check-handoff.sh brief` must pass before Builder spawn.
