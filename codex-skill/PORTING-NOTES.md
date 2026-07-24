# Codex Skill — Porting Notes

Where the Codex port **intentionally diverges** from the Claude build of Three Man Team, and
why. Read this before "syncing" the two: the wording is not always parallel, and copying the
Claude text into the Codex skill can be wrong rather than helpful.

The model-agnostic v2.0.0 wins — Context Budget (cap ~90K, checkpoint, spawn a fresh role from the
handoff, ephemeral command output, per-step `Cost:` line) and the "what you carry, not what you
load" reframe — port verbatim and are already in the Codex role templates, `SKILL.md`, and
`references/token-optimization.md`.

The two sections below are where the builds differ. **§1 (model routing) has since converged** —
v2.0.0 documented it as "does not exist on Codex," but GPT-5.6 (GA 2026-07-09) gave Codex a real
per-tier knob, so v2.1.0 wires the same Architect / Builder / Reviewer routing the Claude build
has; the section is kept as the record of *how* it converged, so no one re-opens it. **§2 (the
1-hour prompt cache) is still Claude-Code-only** and remains a live divergence.

---

## 1. Model routing — converged in v2.1.0 (GPT-5.6 Sol / Terra / Luna)

**History.** At v2.0.0 this was a hard divergence. The Claude build routes by model alias — Builder
on `"sonnet"`, Reviewer on `"haiku"`, Architect on Opus — and Codex had no equivalent: it spawned
sub-agents by `agent_type` and its only cost/quality knob was reasoning effort. Hardcoding
`model: "sonnet"` would have been a dead instruction, so the skill framed the principle as *match
effort to the role* and named the Sonnet / Haiku / Opus tiers only as the Claude build's expression
of it. The section carried an Open item: *if the Codex CLI ever exposes per-sub-agent model
selection, name the exact parameter.*

**What changed.** GPT-5.6 (GA 2026-07-09) is that parameter. It ships three durable capability
tiers you select per model — **Sol** (`gpt-5.6-sol`, flagship reasoning ceiling), **Terra**
(`gpt-5.6-terra`, balanced everyday agentic coding, ~2× cheaper), **Luna** (`gpt-5.6-luna`, fastest
and cheapest) — set in `~/.codex/config.toml` via `model` / `model_reasoning_effort`, plus a real
per-sub-agent override. That maps one-to-one onto the Claude build's Opus / Sonnet / Haiku.

**What the Codex skill does now.** Routes the three roles by tier, the direct analog of the Claude
build:

| Role | Codex tier | Claude build |
|---|---|---|
| Architect | **Sol** (`gpt-5.6-sol`) — orchestration, planning, judgment, deploy gate | Opus |
| Builder | **Terra** (`gpt-5.6-terra`) — bounded execution against a written brief | Sonnet |
| Reviewer | **Luna** (`gpt-5.6-luna`) — bounded, gate-backed review of a small listed diff | Haiku |

Reasoning effort is the *within-tier* knob: keep the highest effort (`xhigh` / `max`, or Sol's
`ultra` mode) for irreversible steps and load-bearing decisions, and run gate-backed routine work
at the effort its tier already covers. Lives in `references/role-templates/ARCHITECT.md` (Context
Budget + spawn instructions), `SKILL.md` (Job 2), and `references/token-optimization.md` (lever 2).

**Routing caveat (real).** A Sol parent does **not** delegate to cheaper tiers by default — spawned
sub-agents inherit the parent's model unless multi-agent routing is enabled (Codex issue #31814;
set the `features.multi_agent_v2` routing fields, e.g. `hide_spawn_agent_metadata = false`, or use a
per-role model override such as `review_model`). Without it the Terra / Luna spawns silently run as
Sol and the routing saving is lost. Verify a spawned sub-agent's actual model once per environment.

**Open item:** the exact per-sub-agent routing field is still settling in the Codex CLI. The tier
*assignment* above is durable; if the override syntax changes, update the caveat, not the routing.

---

## 2. One-hour prompt cache (`ENABLE_PROMPT_CACHING_1H`) — Claude Code only

**Claude build:** setting `ENABLE_PROMPT_CACHING_1H=1` in `~/.claude/settings.json` switches the
prompt cache from a 5-minute to a 1-hour TTL, so Three Man Team's handoff gaps (5–60 min: brief
review, Monitor waits, diff reads) do not expire the cache and re-bill the whole context at write
price. On a measured session those cold rewrites were ~$25 of a ~$156 CAD day.

**Why it does not port:** `ENABLE_PROMPT_CACHING_1H` is a Claude Code environment variable. It has
no effect under Codex, whose runtime manages caching itself. Presenting it as a Codex setup step
would be false.

**What the Codex skill does instead:** `references/token-optimization.md` (lever 3) documents it
as a *Claude-Code-only* option ("if you run this team under Claude Code, set …; under Codex the
runtime manages caching for you"). It is deliberately absent from any Codex setup / install step.

**Open item:** if Codex adds a user-facing cache-TTL control, add the analog here and in the token
guidance. Until then, do not add a cache setup step to the Codex skill.

---

*Origin: v2.0.0 ("context is the cost"); §1 converged at v2.1.0 when GPT-5.6 gave Codex per-tier
model selection. The Claude build's role files carry the literal Opus / Sonnet / Haiku routing and
the `ENABLE_PROMPT_CACHING_1H` install step; the Codex build now carries the Sol / Terra / Luna
analog (§1) but still omits the cache step (§2). This file records why — so the remaining
divergence stays a deliberate choice rather than a drift someone "fixes" later.*
