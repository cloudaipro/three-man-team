# Codex Skill — Porting Notes

Where the Codex port **intentionally diverges** from the Claude build of Three Man Team, and
why. Read this before "syncing" the two: the wording is not always parallel, and copying the
Claude text into the Codex skill can be wrong rather than helpful.

The model-agnostic v2.0.0 wins — Context Budget (cap ~90K, checkpoint, spawn a fresh role from the
handoff, ephemeral command output, per-step `Cost:` line) and the "what you carry, not what you
load" reframe — port verbatim and are already in the Codex role templates, `SKILL.md`, and
`references/token-optimization.md`.

The two sections below are where the builds differ. Codex can request a model override for a
sub-agent, but an individual runtime can expose fewer model choices. Cache behavior remains
runtime-managed by Codex; do not copy a configuration instruction from the Claude build into this
skill.

---

## 1. Model routing — fixed Codex child overrides

**What the Codex skill does.** It requests a model override in `spawn_agent` and routes roles by
their preferred tier:

| Role | Codex tier | Claude build |
|---|---|---|
| Architect | **Sol** (`gpt-5.6-sol`) — orchestration, planning, judgment, deploy gate | Claude equivalent: Opus |
| Builder | **Luna/Max** (`gpt-5.6-luna`, `reasoning_effort: "max"`) — bounded execution against a written brief | Claude equivalent: Sonnet |
| Reviewer | **Luna/Max** (`gpt-5.6-luna`, `reasoning_effort: "max"`) — bounded, gate-backed review of a small listed diff | Claude equivalent: Haiku |

Architect routing remains Sol. Every Builder and Reviewer spawn uses Luna/Max with
`fork_turns: "none"`; there is no alternate child route. If Luna is unavailable, Architect does
not substitute another model or effort level and reports the blocker to the Product Owner.

---

## 2. One-hour prompt cache (`ENABLE_PROMPT_CACHING_1H`) — Claude Code only

**Claude build:** setting `ENABLE_PROMPT_CACHING_1H=1` in `~/.claude/settings.json` switches the
prompt cache from a 5-minute to a 1-hour TTL, so Three Man Team's handoff gaps (5–60 min: brief
review, Monitor waits, diff reads) do not expire the cache and re-bill the whole context at write
price. On a measured session those cold rewrites were ~$25 of a ~$156 CAD day.

**Why it does not port:** `ENABLE_PROMPT_CACHING_1H` is a Claude Code environment variable. It has
no effect under Codex, whose runtime manages caching itself. Presenting it as a Codex setup step
would be false.

**What the Codex skill does instead:** `references/token-optimization.md` states only the Codex
fact: runtime caching is managed by Codex, so this skill provides no cache-TTL setup step.

**Open item:** if Codex adds a user-facing cache-TTL control, add the analog here and in the token
guidance. Until then, do not add a cache setup step to the Codex skill.

---

*Origin: v2.0.0 ("context is the cost"); §1 converged at v2.1.0 when GPT-5.6 gave Codex per-tier
model selection. The Claude build's role files carry the literal Opus / Sonnet / Haiku routing and
the `ENABLE_PROMPT_CACHING_1H` install step; the Codex build carries Architect Sol plus
unconditional Builder/Reviewer Luna/Max routing (§1), but still omits the cache step (§2). This
file records why — so the remaining divergence stays a deliberate choice rather than a drift
someone "fixes" later.*

---

## 3. v2.3.0 context engineering — ported in full, with one scaffolder gap fixed after

v2.3.0 applied Anthropic's Claude 5 context-engineering guidance to the framework. Every
part of it ported to the Codex build, because none of it depends on a Claude-only feature:

| v2.3.0 change | Codex status |
|---|---|
| `scripts/check-handoff.sh` | ported — `templates/project/scripts/`, byte-identical to the Claude copy |
| RULES.md gate row + call-site table | ported — `templates/project/RULES.md` is in the identical-copy set |
| Token Rules block → cost model + gotchas | ported — `SKILL.md` and `templates/project/AGENTS.md` |
| token-optimizer de-duplication | intentionally divergent — Codex keeps runtime-specific guidance; Claude copies remain identical to each other |
| Pre-Flight eighth line | ported — `references/playbooks/PLANNING.md`, `references/role-templates/ARCHITECT.md` |
| Builder/Reviewer call sites | ported — `references/role-templates/BUILDER.md`, `REVIEWER.md` |

**The gap this section exists to record.** v2.3.0 shipped with the Codex *scaffolder* still
unaware of any of it: `scripts/setup-project.sh` installed `RULES.md` — which now carries a
gate row calling `scripts/check-handoff.sh` — but never installed the script. Every fresh
Codex install got a Mechanical Gate that fails on every step, and a failing gate blocks every
review request. The role-template and reference edits were all correct; only the installer
was behind.

This is the **manifest.md bug of v1.9.0, exactly repeated**: the scaffolder installed the file
that references a thing without installing the thing. Both times the referencing file was
`RULES.md` or its neighbours, both times nothing consumed the missing file until a user hit it.

By the framework's own rule — a lesson that lands twice becomes a check, not a third manual
fix — `scripts/check-consistency.sh` now asserts that `setup-project.sh` installs every project
file its other installed files reference by name. A third repetition should be impossible.

The scaffolder also now copies the **structured** handoff templates rather than writing
two-line stubs. `check-handoff.sh` asserts a brief carries Decisions, Out of Scope, Flags, and a
Definition of Done with a runnable command; a stub gives the Architect nothing to fill in and
the check nothing to find.

**Status:** methodology parity is preserved; runtime-specific instructions intentionally differ.
