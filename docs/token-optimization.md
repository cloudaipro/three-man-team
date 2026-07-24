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

The five rules above cut what a session **loads**. That is a one-time saving per file. The
larger cost in a real build is what each agent **carries** — every bash result, file read, and
diff stays in context and is re-sent, and re-billed, on every following turn. A long-lived
agent's cost grows with the *square* of its lifetime, not the number of files it opened.

Measured on a real multi-hour session: 94.6% of the bill was re-processing accumulated context
(cache reads + cache writes); output was 5.3%; all file reads combined were about 0.1%. Loading
discipline was fighting over a rounding error while the context nobody bounded ran up the tab.

Three levers move the 94.6%, in order of impact:

1. **Bound each role's context** — cap and respawn (see Context Budget in the role files).
2. **Keep the cache warm across handoffs** — the 1-hour TTL (below).
3. **Run execution roles on cheaper tiers** — Builder on Sonnet, Reviewer on Haiku (below).

## Cache TTL — Keep It Warm Across Handoffs

Claude Code's prompt cache defaults to a **5-minute** TTL. Three Man Team's whole loop runs on
gaps longer than that — Architect writes a brief, you review it, Builder waits on a Monitor,
Reviewer reads a diff. Every handoff pause lets the cache expire, and the next call re-uploads
the entire accumulated prompt at **1.25× input price**. On a real session those cold rewrites
alone were $25 of a $114 day.

Turn on the 1-hour cache. One line in `~/.claude/settings.json`:

```json
{ "env": { "ENABLE_PROMPT_CACHING_1H": "1" } }
```

The 1-hour write costs 2× instead of 1.25×, so it pays for itself by the third read — and TMT
sessions average hundreds of reads per stream. For this methodology specifically it is pure
profit, because the handoff gaps are exactly the 5-to-60-minute window the short TTL misses.

## Model Routing — Match the Tier to the Job

The Architect makes the decisions that are expensive to get wrong; Builder and Reviewer execute
against a written brief. Route accordingly:

| Role | Model | Why |
|---|---|---|
| Architect | `opus` | judgment, planning, deploy sign-off — never lower |
| Builder | `sonnet` | bounded execution against a brief; ~40% cheaper on every axis, gate-backed |
| Reviewer | `haiku` | fast judgment over a small listed diff the gate already vetted |

Raise a tier for the floors — irreversible steps (migration, deletion, external side effect)
run Builder on `opus`; security-sensitive or architecturally load-bearing diffs raise Reviewer.
Full policy lives in `ARCHITECT.md` → Model Allocation.

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
