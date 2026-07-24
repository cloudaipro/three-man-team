# Codex Skill — Porting Notes

Where the Codex port **intentionally diverges** from the Claude build of Three Man Team, and
why. Read this before "syncing" the two: two of the v2.0.0 cost optimizations do not translate
literally, and copying the Claude wording into the Codex skill would be wrong, not helpful.

The model-agnostic v2.0.0 wins — Context Budget (cap ~90K, checkpoint, spawn a fresh role from the
handoff, ephemeral command output, per-step `Cost:` line) and the "what you carry, not what you
load" reframe — port verbatim and are already in the Codex role templates, `SKILL.md`, and
`references/token-optimization.md`. The two below do not.

---

## 1. Model routing (Sonnet / Haiku) — does not exist on Codex

**Claude build:** the Architect spins up the Builder on `"sonnet"` and the Reviewer on `"haiku"`
by default (passing the `model` alias to the Agent tool), keeping Opus for its own orchestration.
Bounded execution against a written brief runs cheaper; judgment stays on the top tier.

**Why it does not port:** Codex has no Sonnet/Haiku. It spawns sub-agents by `agent_type`
(`"worker"` for the Builder, `"default"` for the Reviewer) and its cost/quality knob is reasoning
effort, not a Claude model alias. Hardcoding `model: "sonnet"` into the Codex skill would be a
dead instruction.

**What the Codex skill does instead:** frames the principle as *match effort to the role* — spawn
the Builder and Reviewer at the working profile / reasoning effort their bounded, gate-backed task
needs, and reserve the highest effort for irreversible or load-bearing steps. The Sonnet / Haiku /
Opus tiers are named only as the Claude build's *expression* of the same idea, not as a Codex
setting. Lives in `references/role-templates/ARCHITECT.md` (Context Budget), `SKILL.md` (Job 2),
and `references/token-optimization.md` (lever 2).

**Open item:** if the Codex CLI exposes explicit per-sub-agent model or reasoning-effort selection,
tighten the guidance to name the exact parameter instead of the generic "working profile / effort".

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

*Origin: v2.0.0 ("context is the cost"). The Claude build's role files carry the literal Sonnet /
Haiku routing and the `ENABLE_PROMPT_CACHING_1H` install step; this file records why the Codex port
does not, so the divergence stays a deliberate choice rather than a drift someone "fixes" later.*
