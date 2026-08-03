# Changelog

## v2.5.0 — 2026-08-02

- **Critical**: Fresh Codex projects now create lean role-delta files; the installed skill is the only canonical workflow source. `./upgrade codex --migrate-role-files <project>` is the explicit, timestamped-backup-producing route for existing custom files, while ordinary upgrades preserve them.
- **Feature**: `scripts/codex-usage-audit.py` reads local Codex JSONL defensively and reports only final cumulative token usage once per session, conservative role totals, and labelled cost-estimate availability. It never emits prompt or response content; synthetic tests cover changing event shapes and privacy.
- **Improve**: fresh-context/model routing is executable and unconditional: every Builder and Reviewer spawn uses Luna/Max with `fork_turns: "none"`. There is no fallback, inheritance, or critical-child route; unavailable Luna blocks the spawn and is reported to the Product Owner. Role warning/handoff budgets are Architect 85K/100K, Builder 75K/90K, Reviewer 50K/60K. Handoff templates now carry checkpoints, aggregate cost evidence, and one-batch owner-validation guidance.

## v2.4.0 — 2026-08-01

- **Critical**: The release registry now marks v2.4.0 as the current mandatory checkpoint. Projects must walk this release before acknowledging it.

## v2.3.1 — 2026-07-26

The theme: *the installer was behind the instructions*. v2.3.0's content ported to the Codex build correctly — role templates, playbooks, `RULES.md`, `AGENTS.md`, `SKILL.md`, `token-optimization.md` all carried the changes. The Codex **scaffolder** did not. `codex-skill/scripts/setup-project.sh` installed `RULES.md`, which now carries a Mechanical Gate row calling `scripts/check-handoff.sh`, but never installed the script. Every Codex project set up or upgraded on v2.3.0 carries a gate command that fails on every step — and because a failing gate is an Iron Rule bounce, no review request can pass until it is fixed. The Claude build was unaffected: its `upgrade` tool shipped the script from the start.

- **Fix**: `setup-project.sh` installs `scripts/check-handoff.sh`, always refreshed rather than skipped-if-present. This one file breaks the scaffolder's additive-only rule deliberately — it holds no project content, and a stale copy standing against a current `RULES.md` gate row is precisely the failure being fixed
- **Fix**: the scaffolder copies the **structured** handoff templates instead of writing two-line stubs. `check-handoff.sh` asserts a brief carries Decisions, Out of Scope, Flags, and a Definition of Done with a runnable command; a stub gave the Architect nothing to fill in and the check nothing to find. `codex-skill/templates/project/handoff/` is added to the bundle, byte-identical to the Claude set and now under the identical-copy audit
- **Fix**: the Codex `BUILDER.md` gains the `scripts/check-handoff.sh review-request` step its Claude counterpart received in v2.3.0
- **Tooling**: this is the **v1.9.0 `manifest.md` bug repeated exactly** — the scaffolder installing the file that references a thing without installing the thing. v1.9.0 fixed that instance by hand and added an assertion for *that* file; the class went unchecked. By the framework's own rule that a Lesson landing twice becomes a standing Rule, `scripts/check-consistency.sh` now asserts that `setup-project.sh` installs every project file its other installed files reference by name, and that the Codex bundle carries the full handoff template set. Both assertions were negative-tested — they fire when the install line is removed and pass when it is restored
- **Docs**: `codex-skill/PORTING-NOTES.md` gains §3 — the v2.3.0 parity table, this gap and why it recurred, and an explicit *Open: nothing* on the two builds' parity
- **Critical**: Codex installs cannot self-heal into this fix. A project stamped `v2.3.0` matches the old registry `latest`, so the version check stays silent and the broken gate persists indefinitely. Publishing this version is the mechanism that reaches them

## v2.3.0 — 2026-07-26

The theme: *an accuracy bug is a token bug*. Anthropic published ["The New Rules of Context Engineering for Claude 5 Generation Models"](https://claude.com/blog/the-new-rules-of-context-engineering-for-claude-5-generation-models) on 2026-07-24 — over 80% of Claude Code's system prompt deleted with no measurable loss on coding evals, and the named cause of the bloat was overconstraint plus *conflicting instructions across layers*. Read against v2.0.0's finding that 94.6% of a real session's bill was re-processing accumulated context, the two combine into one conclusion this release acts on: byte-trimming a role file is a rounding error, because the prelude is a stable cached prefix — but a **bounced step** re-runs the Reviewer, the Builder fix, and the Architect re-brief, re-billing every agent's accumulated context across the whole loop. Ambiguity is what costs money here, so this release spends its effort on making handoffs mechanically checkable and on deleting instructions that conflict.

- **Feature**: `scripts/check-handoff.sh brief|review-request|review-feedback` — framework-owned, shipped in both template sets and the Codex build. Asserts the handoff file has its sections, carries no unfilled template placeholders, and — for a brief — that the Definition of Done contains a runnable command. `RULES.md`'s Mechanical Gate gains a `scripts/check-handoff.sh brief` row; the Architect runs it as the eighth and last line of the Pre-Flight Check, the Builder at session start before writing code, the Reviewer as their first act before reading anything. The `ARCHITECT-BRIEF.md` Definition of Done now requires a command in backticks: **a criterion you cannot express as a command, a click-path, or a diff assertion means the step is not specified sharply enough to build.** This replaces the brief contract that was prose asserted in three drifting places (`BUILDER.md`, the `ARCHITECT.md` template, `playbooks/BRIEF-EXAMPLES.md`) and enforced nowhere — the article's "design interfaces, don't describe them," applied with the mechanism this framework already had
- **Fix**: the token-optimizer skill your agents actually load had drifted off `docs/token-optimization.md` and was missing three sections — the 94.6% cost model, the `ENABLE_PROMPT_CACHING_1H` cache setting, and the model routing table. `CLAUDE.md` instructs every role to load that skill *first, before anything else*, so since v2.0.0 the framework's highest-value guidance sat in the one file nobody was told to read. The three copies are now byte-identical and guarded by `scripts/check-consistency.sh`'s identical-copy audit, the same mechanism that already covers RULES.md and the playbooks
- **Improve**: the five-rule **Token Rules** block is removed from every instruction file and replaced by the cost model it was standing in for, plus a `## Gotchas` section. Two of the five were not merely redundant: *"Is this in a skill or memory? → Trust it. Skip the file read."* instructs an agent to act on state that may be stale, directly contradicting the memory system's own contract that memories are point-in-time observations — a correctness bug dressed as a token saving; and *"Output > 20 lines you won't use → Route to subagent"* sets a threshold well below the cost of spawning a subagent, so following it literally **raises** spend. The rest describe behavior current models already exhibit. What survives is written as reasons rather than commands, stated once
- **Reversal**: the point above reverses a call v2.2.0 made deliberately. v2.2.0 duplicated the rule block inline into each subagent's role file and recorded that "the one change that would have collided with the prompt-repetition accuracy finding (dropping rule duplication wholesale) was deliberately **not** made." For Claude 5 generation models that finding is superseded — repetition across layers is now the named defect, and the internal failure Anthropic cites is conflicting instructions in exactly this shape. This repo had already produced that failure: see the drifted skill above. v2.2.0's *second* justification still holds — a subagent whose skill is uninstalled should still have its discipline — so each subagent keeps its **context cap** inline in its own role file; only the redundant and harmful rules left
- **Improve**: `METHODOLOGY.md`'s Token Discipline section rewritten off the load axis onto the carry axis, and it now states the auto-memory boundary explicitly: **anything a subagent must know cannot live in auto-memory**, because subagents do not inherit it. Cross-agent state belongs in the handoff files — which is what makes them the record. The README's Token Optimization section follows
- **Improve**: the model routing table gains the caveat that "let the model use judgment instead of giving it rules" is a *current-generation* finding, while the `haiku` alias resolves to a smaller, older-generation model. The explicit checklists in `REVIEWER.md` are load-bearing at that tier and were deliberately left intact — deconstrain a role only when the tier it runs on justifies it
- **Tooling**: `scripts/check-consistency.sh` gains three assertions — the token-optimizer three-way identical set, the `check-handoff.sh` three-way identical set, and an executable-bit check on the shipped scripts (a script that lands without `+x` presents as a broken gate, not a broken install). CI syntax-checks and shellchecks the new script alongside the existing ones
- **Critical**: `RULES.md` carries a gate row calling `scripts/check-handoff.sh` and all three role files instruct running it. Installing the role files or RULES.md without the script leaves a gate command that fails on every step — and a failing gate blocks every review request. The script and the files that call it must land together

## v2.2.0 — 2026-07-24

The theme: *trim the floor the busiest agents carry*. A framework whose thesis is "context is the cost" was making every spawned Builder and Reviewer load the full ~668-token token-optimizer essay first thing — of which only the five-rule decision block and grep-before-read are execution-relevant to a subagent. On the v2.0.0 respawn-heavy design (a fresh Builder at each ~90K checkpoint) that essay is re-loaded per respawn and then re-sent every turn of the subagent's life — the O(N²) carry axis, not a one-time load. This release cuts what the subagents carry and de-duplicates the model-routing policy the Architect carries. Both changes were checked against 2026 published practice on agent token economics; the one change that would have collided with the prompt-repetition accuracy finding (dropping rule duplication wholesale) was deliberately **not** made.

- **Improve**: subagents stop loading the full token-optimizer essay. Bob and Richard (both template sets) now carry a compact **Token Rules** block inline in their own role file — the five-rule decision table plus grep-before-read — and the Architect's spin-up prompts no longer tell them to load the skill. The full essay stays the Architect's reference (it alone acts on Role-Scoped Loading, Checkpoint-First, CLAUDE.md-as-Router). Net **~578 tokens removed from each Builder/Reviewer's permanent context floor**, re-sent every turn and every respawn. The inline block is deliberate point-of-use repetition — the rules now travel in the file the subagent acts from, which also closes the reliability gap where a subagent with the skill uninstalled ran with no token discipline at all
- **Improve**: model-routing policy stated once, not three times. The Claude `ARCHITECT.md` (both sets) restated the sonnet/haiku defaults and alias guidance in the Bob spin-up, the Richard spin-up, and the Model Allocation table. The spin-ups now carry a one-line `model:` default plus a pointer; **Model Allocation** is the single source for defaults, floors, aliases, and raise-a-tier policy. Removes a three-way drift surface from the longest-lived agent's always-carried role file
- **Scope**: Claude-build only. The Codex build's subagents already carry inline token discipline and never loaded the essay, and its `ARCHITECT.md` states routing tersely — no change needed there; the v2.1.0 Sol/Terra/Luna routing is untouched. The version bump is repo-wide because the release registry is shared

## v2.1.0 — 2026-07-24

The theme: *the divergence converged*. v2.0.0 routed the Claude build by model tier — Builder on Sonnet, Reviewer on Haiku, Architect on Opus — and `codex-skill/PORTING-NOTES.md` recorded model routing as the one v2.0.0 win that could **not** port: Codex had no tier knob, only reasoning effort, so the skill framed the principle as "match effort to the role" and named the Claude tiers only as an analogy. It carried an Open item — *if the Codex CLI ever exposes per-sub-agent model selection, name the exact parameter.* GPT-5.6 (**Sol / Terra / Luna**, GA 2026-07-09) is that parameter. This release wires the Codex build's three roles to the three tiers, the direct analog of the Claude routing.

- **Feature**: Codex model-tier routing — the Architect runs on **Sol** (`gpt-5.6-sol`), spawns the Builder on **Terra** (`gpt-5.6-terra`), and the Reviewer on **Luna** (`gpt-5.6-luna`): flagship judgment on top, bounded execution against a written brief one tier down, gate-backed review of a small listed diff at the cheapest. Lands in `codex-skill/SKILL.md` (role table + both spawn instructions + Job 2 Context Budget), `codex-skill/references/role-templates/ARCHITECT.md` (spawn instructions + Context Budget), and `codex-skill/references/token-optimization.md` (lever 2). Reasoning effort becomes the within-tier knob, with the top effort (`xhigh` / `max`, or Sol's `ultra` mode) reserved for irreversible and load-bearing steps
- **Improve**: `codex-skill/PORTING-NOTES.md` §1 rewritten from "does not exist on Codex" to "converged in v2.1.0" — it keeps the history (why it did not port at v2.0.0) so the section still stops a future "fix," documents the config (`~/.codex/config.toml` `model` / `model_reasoning_effort`), and adds the real routing caveat: a Sol parent inherits its model to spawned sub-agents unless multi-agent routing is enabled (Codex issue #31814), so without it the Terra/Luna spawns silently run as Sol and the routing saving is lost
- **Scope**: content changes are confined to `codex-skill/`; the version bump is repo-wide because the release registry is shared. The Claude build's Opus / Sonnet / Haiku routing is unchanged, and §2 (the `ENABLE_PROMPT_CACHING_1H` 1-hour cache) stays a live Claude-Code-only divergence — under Codex the runtime manages caching itself

## v2.0.0 — 2026-07-23

The theme: *context is the cost*. Every token-optimization rule this framework shipped through v1.9 cut what a session **loads** — grep before read, role-scoped loading, a lean CLAUDE.md. Measured against a real multi-hour session that cost ~$156 CAD, all file reads combined were roughly **0.1%** of the bill. **94.6%** went to re-processing context that was assembled once and then re-sent, and re-billed, on every following turn (cache reads + cold cache rewrites); output was **5.3%**. One general-purpose Builder subagent ran 383 calls over six hours, context climbing 21,011 → 347,455 tokens, never reset — **52% of the entire day** for 31,716 output tokens. This release optimizes the axis that holds the money: what each agent **carries**.

- **Feature**: every role gets a `## Context Budget`. Builder caps at ~90K tokens, then checkpoints (where it stopped, what's next, which files matter, open decisions) and lets the Architect respawn a fresh Builder from that handoff instead of continuing the swollen context. Reviewer caps at ~60K and bounces oversized diffs. Architect scopes briefs to fit one budget, prefers sequential short-lived Builders over one long-lived Builder, and logs a one-line `Cost:` per BUILD-LOG step. Replayed against the real trace, the expensive Builder drops from **$58.87 to $8.96**
- **Improve**: model-tier routing — the Architect spins up Builder on `sonnet` and Reviewer on `haiku` by default, keeping Opus for its own orchestration. Building is bounded execution against a written brief (~40% cheaper on every axis, gate-backed); review is fast judgment over a small listed diff the Mechanical Gate already vetted. Named floors raise the tier for irreversible steps (Builder → Opus) and security-sensitive or architecturally load-bearing diffs (Reviewer up). On the measured project every subagent ran Opus doing mechanical work — 239 Bash, 69 Read, 38 Edit — at 60% of spend
- **Improve**: `docs/token-optimization.md` reframed onto the axis that holds the cost — a "Bigger Lever: What You Carry, Not What You Load" section (with the 94.6% / 5.3% / 0.1% split), plus Cache TTL and Model Routing sections. The existing input-loading rules stay as the last, smallest term
- **Improve**: the 1-hour prompt cache is documented as the cheapest setup win — `ENABLE_PROMPT_CACHING_1H=1` in settings.json. TMT's loop runs on handoff gaps in the 5-to-60-minute band, exactly where the default 5-minute cache expires and re-bills the whole context at write price. On the measured session, 18 cold rewrites cost **$25** for zero new information. Not a universal win — continuous sub-5-minute traffic overpays — but pure profit for a handoff-driven workflow
- **Critical**: the Builder and Architect Context Budget sections are two halves of one mechanism — the Builder checkpoints and hands off, the Architect respawns a fresh Builder from that handoff. Updating BUILDER.md without the matching ARCHITECT.md leaves the handoff instruction with no receiver and builds stall at the first checkpoint. The two must land together

## v1.9.0 — 2026-07-19

The theme: *the writer never held the rule* — v1.8.0 gave the Architect a BUILD-LOG rotation rule, but the Builder writes BUILD-LOG, and a Builder subagent starts with fresh context that never contains the Architect's role file. Measured on the same real project: across 23 subagents that touched BUILD-LOG (61 writes, nearly all Builder), **zero** had the rotation rule in context. The log reached 1185 lines before the Architect noticed — while idle waiting for the Reviewer — and its own note read "overdue since last session". Notably this was *not* context loss: those sessions never compacted once. Fresh subagent context is not degraded context; it is context the rule was never in.

- **Feature**: the Mechanical Gate ships with one pre-filled row — `awk 'END{exit (NR>400)}' handoff/BUILD-LOG.md` — the only gate command the framework provides, every other row still drafted from the project's own tooling. The Builder runs the gate before every review request, so the size ceiling is enforced once per step by the same role that writes the file. v1.8.0's "when the file passes ~300 lines" trigger required someone to decide to run `wc -l`; nothing ever computed it
- **Improve**: BUILDER.md sets a **60-line target** for the BUILD-LOG step entry and states that proof transcripts, command output, and gate evidence go in REVIEW-REQUEST.md. This is the dominant term — measured entries ran 150–207 lines, and at ~180 lines/step against a 300-line threshold the file crosses the line every ~1.7 steps, a cadence no rotation rule can hold
- **Improve**: rotation now aims at a target — *keep moving entries out until BUILD-LOG is under 200 lines* — instead of moving the oldest entry. The rotation performed on the measured project was executed correctly and still finished at 385 lines, over threshold on completion, then regrew to 752 within twelve hours
- **Improve**: write-once rule for Known Gaps and Lessons — a gap is written once in the Known Gaps section and referenced by id from step entries, never restated. Duplicated gap text was ~1.4KB of the measured file
- **Fix**: the shipped size check is `awk`, not `test "$(wc -l < …)"`. Tested against a missing BUILD-LOG the `wc` form exits 2 under bash and sh but **0 under zsh** — the empty command substitution compares as an integer — reporting a green gate for a handoff log that is not there. The `awk` form exits non-zero for oversized, missing, and unreadable alike; the reasoning is written into RULES.md so it does not get "simplified" back. This is L-1's own rule applied to the framework's own gate command
- **Fix**: the Codex version check never worked. `setup-project.sh` scaffolded AGENTS.md, role stubs, RULES.md and the handoff set but never installed `manifest.md`, so `check-version.py` reported `unknown (no manifest.md)` on every Codex install — and told the user to run the very script that doesn't create it. The template it should have installed had meanwhile drifted to v1.5.0, unnoticed across four releases, precisely because nothing consumed it. Now installed and **stamped from the bundled registry at install time**, never from the template's own text
- **Tooling**: `scripts/check-consistency.sh` asserts the Codex project manifest template matches the registry latest. This is the third registry-drift bug in `codex-skill/` (v1.7.0 and v1.8.0 each fixed one by hand) — by the framework's own rule that a lesson landing twice becomes a standing check, it gets an assertion rather than a fourth manual fix
- **Critical**: the gate row lives in RULES.md while the rotation rule lives in the Architect role file — updating role files without installing the RULES.md row leaves the rotation rule with no mechanical trigger, which is exactly the failure this release fixes. The two must land together

## v1.8.0 — 2026-07-17

The theme: *the log must not grow forever* — token-usage fixes measured on a real project (a four-step build had grown BUILD-LOG to 38KB ≈ 10K tokens per read, and every session start paid ~500 tokens for version-check instructions it almost never used).

- Improve: version check extracted to `playbooks/VERSION-CHECK.md` — the Architect role file's Session Start step 2 shrinks to a three-line pre-check (read `version_notified`, fetch `latest.json`, skip silently on match or network failure); the full update walk-through loads on demand only when an update exists. Ships in both template sets; `./upgrade` installs it with the other playbooks. **Critical**: role files updated without the new playbook reference a file that doesn't exist — the two changes must land together
- Improve: BUILD-LOG rotation — new Anti-Drift rule in the Architect role file (both template sets and the Codex skill): when a step clears, or the file passes ~300 lines, completed-step details, closed Known Gaps, and full Lesson text move to `handoff/archive/BUILD-LOG-<YYYY-MM>.md`; BUILD-LOG keeps Current Status, the active step, open gaps, one-line lessons, and pointers. Nothing is deleted — history moves where it's read on demand instead of on every fallback load
- Fix: stale `templates/project-folder/_temp/ARCHITECT.md` removed — an unreferenced ~6KB duplicate of an old role file that installs carried as an accidental-read hazard
- Fix: codex-skill's bundled `releases/latest.json` had drifted from the repo registry again (v1.7.0 marked non-critical in the codex copy) — re-synced; the self-audit already fails on this drift
- Tooling: `scripts/check-consistency.sh` parity lists now cover `playbooks/VERSION-CHECK.md` in both template sets, its byte-identical role-neutral copies, and its presence as an upgrade-tool source

## v1.7.0 — 2026-07-10

The theme: *machines check what machines can check* — verification, allocation, and learning patterns adapted from [agent-steward](https://github.com/michaelchen73092/agent-steward)'s quality-gate/spend-audit loop, rebuilt as markdown process (no runtime dependency added).

- Feature: `RULES.md` — the project's quality contract, shipped in both template sets and the Codex skill. Three sections: **Mechanical Gate** (the project's own runnable checks — lint, tests, build — that must pass before any review request; drafted by the Architect from the project's own tooling, never invented), **Standing Rules** (project-specific rules the Reviewer checks every step — each carries its source and an advisory/blocking status; advisory first, promoted only after proving itself), and **Iron Rules** (framework process invariants — violating one is a process bug that gets a Lesson)
- Feature: gate-first review — BUILDER.md "When You Are Done" now starts with running the Mechanical Gate and recording results in a new REVIEW-REQUEST.md `## Mechanical Gate` section; REVIEWER.md checks that section before reading any code and bounces missing/failing gates with "Gate first" — and no longer re-verifies what the gate already proved. Review attention is spent only on judgment: spec fit, drift, security, logic
- Feature: Lessons graduate into rules — PLANNING.md §8 and the Architect Anti-Drift rules: the second time the same shape of Lesson lands in BUILD-LOG, it gets promoted to a Standing Rule in RULES.md (advisory, with the Lesson as its source); a rule whose flags keep getting waved through gets reworded or retired
- Feature: model allocation policy — ARCHITECT.md gains a Model Allocation section: floors (no-undo steps and one-way doors never run below the session default), gate-covered routine steps as the safe place to try one tier down, and evidence-based movement (a bounce sends that work back up a tier and gets a Lesson). Cheapest at the same quality, never cheapest at any quality
- Improve: the deploy-gate report leads with "what needs you" — decisions first (unspecced product calls, no-undo confirmations; "nothing needs you" is the usual answer), evidence second
- Improve: new-setup.md gains a "Draft the Mechanical Gate" step — the Architect drafts the gate from the project's own tooling at first-time setup and explains the deal to the Project Owner in one sentence
- Improve: `./upgrade` installs the RULES.md skeleton additively (never overwrites a drafted one); codex-skill `setup-project.sh` scaffolds RULES.md the same way; codex-skill role templates and SKILL.md carry the gate protocol
- Tooling: `./upgrade` now serves both CLIs — `./upgrade claude <project>` (the default; bare `./upgrade <project>` still works) runs the existing Claude Code flow, and `./upgrade codex <project>` refreshes the installed Codex skill at `$CODEX_HOME/skills/three-man-team` (previous version kept as a backup next to it, path shape guarded before replacement) and re-runs the skill's `setup-project.sh`, which only adds files the project is missing. Both paths leave version markers alone so the next session's version check walks role-file changes interactively; `--replace-role-files` is refused under codex
- Fix: codex-skill's bundled `releases/latest.json` (used by its offline version checker) had drifted behind the repo registry — synced, and the self-audit now fails if the two ever differ
- Tooling: `scripts/check-consistency.sh` — the repo now audits its own release machinery: manifest/registry version agreement, a JSON file per registry version, a changelog entry for the latest release, changelog ordering, template-set parity, and upgrade-tool source files. Run by CI (`.github/workflows/ci.yml`) alongside shell syntax checks
- Fix: release-registry drift — repo manifest said v1.6.0 while `releases/latest.json` still said v1.5.0, `releases/v1.6.0.json` did not exist (installed projects were never told about v1.6.0), and the v1.6.0 changelog entry was misfiled below v1.0.0. All three corrected; the new consistency check makes this class of drift a CI failure

## v1.6.0 — 2026-07-07

- Feature: Codex skill integration (`codex-skill/`) — full Three Man Team methodology adapted as a Codex skill package. Includes SKILL.md with description-triggered invocation, playbooks as reference files, role templates adapted for Codex's `spawn_agent` (Builder → worker, Reviewer → default), token-optimization reference, project scaffolding script, and local version checker
- Feature: `scripts/setup-project.sh` — scaffolds AGENTS.md (Codex session router), role file stubs, and the full handoff template set into any project directory; sets up .gitignore for handoff files
- Feature: `scripts/check-version.py` — lightweight local version checker comparing manifest.md against bundled releases registry (sandbox-safe, no network calls)
- Improve: README.md — added Codex Integration section with component table, adaptation guide, install instructions, and workflow overview
- New asset: `codex-skill/agents/openai.yaml` — UI metadata for skill discovery in Codex
- New asset: `codex-skill/templates/project/AGENTS.md` — Codex-compatible session router with token rules and team table
- Feature: `setup-project.sh` now supports `--plugin` flag to register `@three-man-team` Codex plugin, and `--plugin-only` flag for plugin-only installs — enables `@three-man-team` mention trigger in any Codex CLI session
- New asset: `templates/plugin/.codex-plugin/plugin.json` and `templates/plugin/.app.json` — plugin manifest and App definition for `@three-man-team` mention support
- Improve: README.md — updated setup docs for `--plugin`/`--plugin-only` flags, added "How to trigger in Codex CLI" section documenting `@three-man-team` mention and description matching

## v1.5.0 — 2026-07-05

- Feature: slash commands ship in `.claude/commands/` (both template sets) — `/architect` starts or resumes the Architect session and optionally takes your first request as an argument (`/architect fix the login bug`); `/tmt-setup` runs first-time setup. Commands are role-neutral: `/architect` reads manifest.md to find renamed role files, so renamed teams need no edits
- Improve: setup script, README, INSTALL.md, examples/session-start.md, new-setup closing message, and the checkpoint Resume Prompt all lead with the commands — classic paste prompts remain as manual fallback
- Improve: new-setup CLAUDE.md snippet now includes "Start sessions with /architect" so the command stays discoverable in every future session
- Fix: `.gitignore` — `templates/generic/.claude/` was swallowed by the global `.claude/` ignore rule; added override so generic-template command files actually ship
- Fix: briefing sections and new-setup no longer hardcode dated model IDs — replaced with the version-stable aliases `opus` / `sonnet` / `haiku`, which always resolve to the newest model of each tier
- Change: distribution source — all version-check and raw-fetch URLs in shipped files (ARCHITECT.md ×2, new-setup.md ×2, /architect command ×2, releases v1.4.0/v1.5.0 how_to_assess) now point at `cloudaipro/three-man-team`; this fork is the release registry going forward (historical release docs left unchanged); README/INSTALL/setup clone commands follow
- Tooling: `./upgrade` script — upgrades an existing project install to the clone's version. Safe by default (additive installs, backups, live handoff data and personas untouched, version markers left stale so the next session's update walk finishes role-file wiring interactively); `--replace-role-files` for stock installs (refused on renamed/customized ones); `--dry-run` to preview

## v1.4.0 — 2026-07-05

- Feature: `playbooks/` introduced — the Architect's planning judgment distilled into three on-demand files, shipped in both template sets. `PLANNING.md`: problem framing, verify-before-plan, two-options rule, risk-first step cutting, and the seven-question Pre-Flight Check that gates every Builder spin-up. `DIAGNOSIS.md`: read-don't-recall debugging protocol, second-cause check, two-strikes rule. `BRIEF-EXAMPLES.md`: annotated weak-vs-strong brief pair and horizontal-vs-vertical step cutting. Loaded at mode entry, never at session start — planning quality goes up, session cost doesn't. Files are role-neutral: renaming the team never touches them.
- Improve: ARCHITECT.md (both templates) wired to the playbooks — load-trigger table, written Pre-Flight Check required before spinning up Builder, two-strikes rule added to Anti-Drift, deploy gate now requires knowing the undo before the push (and saying so when there is none)
- Improve: ARCHITECT-BRIEF.md template gains an Out of Scope section; Definition of Done placeholders now require criteria checkable by a command, a click, or a diff
- Improve: BUILD-LOG.md template gains a Lessons section — one line per bounced step, read before each new brief; Architecture Decisions entries now record the why alongside the decision
- Improve: BUILDER.md (both templates) — complete-brief checklist added; Builder stops and signals the Architect when the brief is missing Out of Scope or an observable Definition of Done, instead of filling gaps by guessing — the planning discipline is enforced from both sides
- Improve: ARCHITECT.md Job 1 modes now name the playbook to load (Diagnose → DIAGNOSIS.md, Direction → PLANNING.md); token rule amended to "never skip planning, writing, or reviewing code"
- Improve: new-setup.md — manifest gains `playbooks_dir`; rename instructions note that playbooks never need renaming
- Docs: token-optimization.md documents playbook loading as part of role-scoped loading; sprint-walkthrough example updated to show Out of Scope and the Pre-Flight Check in action

## v1.3.0 — 2026-06-04

- Feature: manifest.md introduced — new-setup.md now generates manifest.md at first-time setup capturing team names, role filenames, handoff dir, repo, and installed version
- Improve: version check upgraded — reads manifest.md instead of VERSION file, fetches releases/latest.json directly (no API dependency, no jq required for initial check)
- Improve: release JSON schema updated — how_to_assess and user_decision fields replace migration_steps; Arch reads user's actual files before walking through any change
- Improve: two-file fetch strategy — releases/latest.json fetched every session (tiny); releases/v{version}.json fetched only when update needed
- Improve: Anti-Drift rule added to both ARCHITECT.md files — rename any role file, update manifest.md immediately
- Remove: VERSION file retired from templates/project-folder/ — version now tracked in manifest.md
- Fix: SESSION-CHECKPOINT.md templates — version_notified now blank at install time (filled by new-setup.md); project-folder template was missing Version Check section entirely

## v1.2.5 — 2026-06-04

- Fix: RICHARD.md → REVIEWER.md in Richard spinup prompt — Richard was told to read a file that doesn't exist
- Fix: BOB.md → BUILDER.md in root-level template — v1.2.4 fix missed this install path
- Fix: version check upgraded to full procedure — tracks version_notified, fetches release notes, walks migration steps conversationally
- Fix: removed fabricated DeepMind citation from METHODOLOGY.md, README.md, and index.html — replaced with first-principles reasoning
- Improve: ARCHITECT.md Job 1 now documents Diagnose vs Direction modes
- Improve: BUILDER.md REVIEW-REQUEST.md format is now explicit with sub-bullets
- Improve: REVIEWER.md section title simplified
- Improve: CLAUDE.md redundant handoff file list removed
- Docs: star count updated to 813, benchmark placeholder removed from index.html

## v1.2.4 — 2026-05-27

- Fixed: version check tag extraction was silently broken for all v1.2.3 installs ([#8](https://github.com/russelleNVy/three-man-team/issues/8))
- Fixed: typo in Bob spinup prompt (BOB.md → BUILDER.md)

## v1.2.3 — 2026-05-03

- Auto-update check: Arch now checks the GitHub releases API at session start and notifies the Project Owner if a newer version is available
- Added `VERSION` file to `templates/project-folder/` — tracks installed version for comparison

## v1.2.2 — 2026-05-03

- Fix: token-optimization.md now ships with every install — added to `templates/project-folder/.claude/skills/` so the `@` auto-load reference works out of the box
- Fix: CLAUDE.md creation instructions in `new-setup.md` now include `@.claude/skills/token-optimization.md` for both new and existing project context files
- Fix: install `cp` command changed from `*` to `.` in setup script, README, and INSTALL.md — hidden directories (`.claude/`) are now copied correctly
- Docs: added "one session, three roles" callout to README Quick Start and INSTALL.md — clarifies that Bob and Richard are subagents within a single Claude Code session, not separate windows
- Docs: `new-setup.md` now shows the "one session" model explanation to the Project Owner during first-time setup

## v1.2.0 — 2026-04-20

- RTK install block: dropped curl command, now links to github.com/rtk-ai/rtk README (fixes private fork URL)
- Windows support: added Windows section to INSTALL.md — Git Bash/WSL for setup script, manual copy fallback, RTK not supported on Windows
- RTK install note in new-setup.md clarifies macOS/Linux only; Windows users can skip
- handoff/ paths: all agent files now reference handoff/ARCHITECT-BRIEF.md, handoff/REVIEW-REQUEST.md, etc. — prevents files landing in project root
- BUILD-LOG discipline: added Anti-Drift rule requiring BUILD-LOG updates immediately on any decision, not only at deploy
- Model assignment: new-setup.md adds 4th setup question for per-agent model selection; ARCHITECT.md briefing sections now document the `model` parameter with available Claude model IDs

## v1.1.0 — 2026-04-03

- Added `new-setup.md` — guided first-session onboarding handled by Arch: team naming, project context file, RTK install
- Architect now spins up Builder and Reviewer via Agent tool (foreground only) — documented in ARCHITECT.md and INSTALL.md
- Foreground-only requirement documented — background agents stall on Edit approval
- Reviewer protocol upgraded: APPROVED / APPROVED WITH CONDITIONS / REJECTED replaces Must Fix / Should Fix
- Reviewer now runs `git diff` first — diff is primary source of truth, not REVIEW-REQUEST
- Builder self-review and linting gate added before handing off to Reviewer
- Setup script rewritten as guided walkthrough — detects global vs per-project, prints tailored instructions
- `handoff/` folder added to both templates so `cp` command includes it
- `CLAUDE.md` removed from templates — setup script is the only source of truth for that step
- `team.yml.example` removed — renaming handled by Arch during setup
- Stale docs removed: `customizing-your-team.md`, `project-setup.md`
- README Quick Start restructured — two clearly labeled install paths
- Path mismatch in `CLAUDE.md` session router resolved

## v1.0.0 — 2026-03-31

Initial public release.

- Three-agent team: Architect, Builder, Reviewer
- Generic agents in `agents/` with customizable personas and [CUSTOMIZE] placeholders
- Named persona template in `templates/project-folder/` (Arch, Bob, Richard)
- Generic clean-slate template in `templates/generic/`
- Structured handoff files: ARCHITECT-BRIEF, REVIEW-REQUEST, REVIEW-FEEDBACK, BUILD-LOG, SESSION-CHECKPOINT
- Token optimization rules baked into every session router
- RTK integration guidance in docs/token-optimization.md
- Setup script with CLAUDE.md instructions printed on install
- Full documentation suite
