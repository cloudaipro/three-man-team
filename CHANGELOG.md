# Changelog

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
