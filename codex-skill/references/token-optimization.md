# Token Optimization

## Why This Matters

Token waste compounds. A session that reads 5 files unnecessarily at startup costs
those tokens on every single session for the life of the project. Over 100 sessions
that is a significant drain on daily limits and a meaningful cost in paid plans.

Three Man Team addresses token waste structurally — the rules are in CLAUDE.md so they
fire automatically, not as a reminder you might follow.

## The Five Rules

Built into every Three Man Team session router:

```
Is this in a skill or memory?   → Trust it. Skip the file read.
Is this speculative?            → Kill the tool call.
Can calls run in parallel?      → Parallelize them.
Output > 20 lines you won't use → Route to subagent.
About to restate what user said → Delete it.
```

## The Bigger Lever: What You Carry, Not What You Load

The five rules above cut what a session **loads** — a one-time saving per file. The larger cost
in a real build is what each agent **carries**: every command result, file read, and diff stays
in context and is re-sent on every following turn. A long-lived agent's cost grows with the
*square* of its lifetime, not the number of files it opened.

Measured on a real multi-hour session: ~94.6% of the bill was re-processed context (cache reads
plus cold cache rewrites at handoffs), output was ~5.3%, and all file reads combined were about
0.1%. Loading discipline was fighting a rounding error while unbounded context ran up the tab.

Three levers move the 94.6%, in order of impact:

1. **Bound each role's context** — cap at ~90K tokens, then checkpoint and spawn a fresh role
   from the handoff instead of continuing the swollen context (see Context Budget in the role
   templates). This is the dominant term.
2. **Match effort to the role** — the Architect plans; the Builder and Reviewer execute against a
   brief and a gate, so spawn them at the working profile / reasoning effort their bounded task
   needs and reserve the top effort for irreversible or load-bearing steps. (The Claude build of
   this framework expresses the same idea as a model tier — Builder on Sonnet, Reviewer on Haiku,
   Architect on Opus.)
3. **Keep the harness cache warm** — if you run this team under Claude Code, set
   `ENABLE_PROMPT_CACHING_1H=1` so handoff gaps in the 5-to-60-minute band don't re-bill the whole
   context at write price; under Codex the runtime manages caching for you.

Reducing what you load saves once. Reducing what you carry saves that amount times every remaining
turn in the session.

## RTK — Bash Output Compression

Token optimizer controls how the team thinks, reads, and responds. RTK handles what
comes back from bash commands.

[RTK](https://github.com/rtk-ai/rtk) is a separate tool that compresses bash command
output before it hits Claude's context window. Tools like `find`, `ls`, and `grep` can
return hundreds of lines Claude doesn't need — RTK intercepts that output and compresses
it, often cutting 50-70% of bash output tokens automatically.

RTK is not part of Three Man Team and we don't manage it. Install it separately if you
use Claude Code CLI heavily. The combination of RTK (bash layer) + token-optimizer
(behavior layer) is where the real savings compound.

Install: https://github.com/rtk-ai/rtk

## Grep Before Read

Never read an entire file to find one thing. Grep for the exact string or line number
first. If you need context around it, use offset and limit on the Read. This single
rule has the highest impact in active build sessions.

## Role-Scoped Loading

Each role loads only what their job requires:
- Architect: checkpoint + BUILD-LOG + ARCHITECT-BRIEF, plus the playbook for the current mode (PLANNING at brief time, DIAGNOSIS at debug time) — at mode entry, never at session start
- Builder: ARCHITECT-BRIEF + relevant reference files only
- Reviewer: REVIEW-REQUEST + specific files Builder listed

The full project spec, schema, and flow docs stay on disk until explicitly needed.

## Checkpoint-First

SESSION-CHECKPOINT.md replaces reading BUILD-LOG and the full spec when it is current.
Architect writes it at the end of every session. It should cover: where we stopped,
what was decided, what is open, and the exact resume prompt.

## CLAUDE.md as Router

CLAUDE.md should never exceed ~50 lines. It is a routing file, not a knowledge base.
Every byte in CLAUDE.md costs tokens on every session. Keep it lean.
