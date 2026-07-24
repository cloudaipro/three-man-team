<p align="center">
  <img src="assets/banner.png" alt="Three Man Team" width="100%">
</p>

<p align="center">
  <a href="https://russellenvy.github.io/three-man-team/">russellenvy.github.io/three-man-team</a>
</p>

<p align="center">
  By <a href="https://russellenvy.com">RUSSΞLL AARØN</a>
</p>

---

## What's New — v2.1.0

**The divergence converged.** v2.0.0 routed the Claude build by model tier — Builder on Sonnet, Reviewer on Haiku, Architect on Opus — but the Codex port could not follow: Codex had no tier knob, only reasoning effort, so `codex-skill/PORTING-NOTES.md` recorded model routing as the one v2.0.0 win that did not port. GPT-5.6's **Sol / Terra / Luna** tiers (GA 2026-07-09) are that missing knob. This release wires the Codex build's three roles to the three tiers, the direct analog of the Claude routing.

- **Codex model-tier routing** — Architect on **Sol** (`gpt-5.6-sol`), Builder on **Terra** (`gpt-5.6-terra`), Reviewer on **Luna** (`gpt-5.6-luna`): flagship judgment on top, bounded execution against a written brief one tier down, gate-backed review at the cheapest. Reasoning effort is the within-tier knob, top effort (`xhigh` / `max`, or Sol's `ultra`) held for irreversible steps.
- **Porting notes, converged** — `PORTING-NOTES.md` §1 goes from "does not exist on Codex" to "converged in v2.1.0," keeping the history so no one re-opens it, plus the real caveat: a Sol parent runs its sub-agents as Sol unless multi-agent routing is enabled (Codex issue #31814).
- **Claude build unchanged** — content changes are confined to `codex-skill/`; Opus / Sonnet / Haiku routing and the 1-hour prompt cache (§2, still Claude-Code-only) are untouched.

**v2.0.0** made *context the cost* — per-role context budgets, model-tier routing, and the 1-hour prompt cache. **v1.9.0** made BUILD-LOG size a mechanical gate. **v1.8.0** made BUILD-LOG rotation a rule and moved the version check into an on-demand playbook. **v1.7.0** added the `RULES.md` quality contract. **v1.6.0** added the Codex skill (`codex-skill/`).

See [all releases →](https://github.com/cloudaipro/three-man-team/releases)

---

## Three Man Team Pro

Pre-built teams for developers, marketers, content creators, and more — install in minutes, start working immediately.

[Join the waitlist →](https://russellenvy.com/tool/three-man-team/)

---

## The Problem With AI Coding Tools

AI coding tools are powerful but undisciplined. They read entire codebases when they
need one function. They add features nobody asked for. They drift mid-task. They burn
tokens on every session doing work that didn't need to happen.

The solution isn't a better prompt. It's a process.

Three Man Team gives you three agents with distinct jobs, clear handoffs, and rules that prevent the most expensive failure modes. The Architect plans and deploys. The Builder builds exactly what the brief says. The Reviewer doesn't pass work that isn't right.

---

## Why Three Agents

Three is not arbitrary. Solo agents drift — there's no one to catch a wrong turn. Large
teams generate coordination overhead that eats the productivity gain. Three is the minimum
for meaningful review and the maximum before the team starts managing itself instead of
the work.

The roles map to how real software ships:
- Someone who understands the whole system and owns the deploy
- Someone who builds fast and clean
- Someone who catches what the builder missed

---

## Quick Start

**How the team runs:** Three Man Team uses one Claude Code session. Arch is your main agent. When work is ready to build, Arch spins up Bob as a subagent via Claude Code's Agent tool. When Bob is done, Arch spins up Richard the same way. You don't open three windows — everything runs inside your single session.

Choose your install type:

---

### Per-project install (recommended)

One project, one install. Clone directly into your project folder.

**Step 1 — Navigate to your project folder and clone**

```bash
git clone https://github.com/cloudaipro/three-man-team.git .claude/skills/three-man-team
```

**Step 2 — Run setup and follow the instructions**

```bash
cd .claude/skills/three-man-team && ./setup
```

Setup takes over from here. It will give you the exact commands to run and the prompt to paste into Claude to get started. Follow what it prints.

---

### Global install (all projects)

Install once, use in any project.

**Step 1 — Clone to your global Claude skills folder**

```bash
git clone https://github.com/cloudaipro/three-man-team.git ~/.claude/skills/three-man-team
cd ~/.claude/skills/three-man-team && ./setup
```

That's the one-time install. Setup will confirm everything is in place.

---

**For each project you want to use Three Man Team on:**

**Step 2 — Copy agent files into your project, then spin up Claude**

```bash
cp -r ~/.claude/skills/three-man-team/templates/project-folder/. /path/to/your/project/
cd /path/to/your/project
```

Open Claude Code and type:

```
/tmt-setup
```

(or paste: *You are the Architect on this project. Please read new-setup.md.*)

Arch will handle the rest — project context file, team names, and from then on every
session starts with just `/architect`.

---

## The Workflow

<p align="center">
  <img src="assets/workflow.png" alt="Three Man Team Workflow" width="100%">
</p>

Every unit of work follows the same path. Architect plans and writes the brief. Builder reads it, shows a plan, builds, and hands off to Reviewer. Reviewer clears it or sends it back. Architect deploys with the Project Owner's go-ahead. Nothing skips a step.

See a complete example from problem to deploy → [`examples/sprint-walkthrough.md`](examples/sprint-walkthrough.md)

---

## The Quality Contract

Human review is expensive — so nothing reaches it that a command could have caught. `RULES.md` holds the project's quality contract, drafted by Arch from the project's *own* docs and tooling, never invented:

| Section | What it holds | Who acts on it |
|---|---|---|
| **Mechanical Gate** | The project's runnable checks — lint, tests, build | Builder runs it before every review request; Reviewer bounces anything without a passing gate |
| **Standing Rules** | Project rules with sources — advisory first, blocking once proven | Reviewer checks them every step, by rule number |
| **Iron Rules** | Framework process invariants | Everyone; a violation is a process bug and gets a Lesson |

The loop closes through BUILD-LOG's Lessons: a mistake becomes a lesson, a repeated lesson becomes a Standing Rule, and a rule nobody's flags survive gets retired. The team gets stricter exactly where it has been burned.

---

## The Team

<p align="center">
  <img src="assets/role-cards-cropped.png" alt="Arch, Bob and Richard" width="100%">
</p>

Three agents. Three distinct jobs. Built to work together.

Architect, Builder, Reviewer are the defaults. Rename them to anything — Arch will handle it during setup.

---

## Token Optimization

Every session starts with five rules baked into CLAUDE.md:

```
Is this in a skill or memory?   → Trust it. Skip the file read.
Is this speculative?            → Kill the tool call.
Can calls run in parallel?      → Parallelize them.
Output > 20 lines you won't use → Route to subagent.
About to restate what user said → Delete it.
```

The token-optimizer skill ships with every install and auto-loads via CLAUDE.md — no manual setup required.

For bash output compression on top of these rules, see [RTK](https://github.com/rtk-ai/rtk) —
a separate tool that compresses `find`, `ls`, `grep` output before it reaches Claude's context.
Not required, but recommended for heavy Claude Code CLI users. The combination of RTK (bash layer)
+ token-optimizer (behavior layer) is where real savings compound.

See `docs/token-optimization.md` for the full discipline.

---

## Auto-Update

At the start of every session, Arch fetches `releases/latest.json` — a small version registry that lists every release with a critical or non-critical flag. If you're behind, Arch walks you through the updates before anything else.

Critical updates are mandatory checkpoints — they ship structural changes (like `manifest.md`) that later updates depend on. Non-critical updates are optional. Arch reads your actual files to determine what applies to your setup before suggesting anything.

> "There is an update available — version 1.3.0. Before we get into today's work, I want to walk through what changed. I will look at your actual files and tell you exactly what applies to you."

You decide what to apply and when. Nothing changes without your confirmation.

See [releases](https://github.com/cloudaipro/three-man-team/releases) for what's changed.

---

## Upgrading an Existing Project

```
Usage:
  ./upgrade claude /path/to/your/project    upgrade a Claude Code install (default)
  ./upgrade codex  /path/to/your/project    upgrade a Codex install (skill + project)
  ./upgrade /path/to/your/project           same as: ./upgrade claude <project>
```

| Option | Applies to | What it does |
|---|---|---|
| `--dry-run` | both | Show what would change, change nothing |
| `--replace-role-files` | claude only | Also replace ARCHITECT.md, BUILDER.md, REVIEWER.md — refused on renamed or customized installs. Codex installs don't need it: the full role templates live inside the skill, which the codex upgrade already refreshes |
| `CODEX_HOME=<dir>` (env) | codex only | Where the skill lives, if your Codex directory is not `~/.codex` |

Both paths back up everything they edit, never touch your live `handoff/` data, team
names, or personas, and deliberately leave your version markers alone — your next
session's version check walks the remaining role-file upgrades with you. Run
`./upgrade --help` for the full reference.

Update your clone, then run the upgrade tool against your project. The first argument
picks the CLI your install runs under — `claude` (the default) or `codex`:

```bash
cd ~/.claude/skills/three-man-team
git pull --ff-only origin main
./upgrade /path/to/your/project
```

`--ff-only` is deliberate: the clone is meant to track this repo untouched, so a pull that
cannot fast-forward means something edited it locally. Better to stop and look than to
merge. If it refuses, `git status` and `git log --oneline origin/main..HEAD` show what
diverged.

(Per-project installs: the clone lives at `.claude/skills/three-man-team` inside the
project. `./upgrade /path/to/your/project` without the CLI argument means `claude`.)

The claude upgrade installs everything additive — `playbooks/`, the `RULES.md`
quality-contract skeleton, the `/architect` and `/tmt-setup` commands, the token-optimizer
skill — points your version check at this repo, backs up every file it edits, and never
touches your live `handoff/` data, team names, or personas. Then start your next session
with `/architect`: Arch walks the remaining role-file upgrades with you interactively.

Using the Codex skill instead? Same tool, one word different:

```bash
~/.claude/skills/three-man-team/upgrade codex /path/to/your/project
```

The codex upgrade refreshes the installed skill at `~/.codex/skills/three-man-team`
(framework files — playbooks, role templates, the bundled version registry — live inside
the skill, and the previous version is kept as a backup next to it), then adds any newly
introduced project files (like `RULES.md`) without overwriting anything of yours. Your
next Codex session's version check sees the refreshed registry and walks the changes with
you. Set `CODEX_HOME` if your Codex directory is not `~/.codex`.

---

## Templates

- `templates/project-folder/` — **Start here.** Named personas (Arch, Bob, Richard), fully written and ready to use. Customize the Who You Are sections and rename to fit your team.
- `templates/generic/` — Blank slate with `[CUSTOMIZE]` placeholders. Use this if you want to build your own personas from scratch or install globally across all projects.

Arch handles renaming during setup — just tell it the new names.

---

## License

MIT. Free forever.

---

## Built By

Russell Aaron — 20+ years building and supporting software the right way. He built this team
in production shipping a real SaaS platform. It works because it was used before it was
published, fine tuned, and will continue to get better over time as AI models and tools evolve.

---

## Codex Integration

Three Man Team ships as a [Codex skill](https://github.com/openai/skills) — the full methodology adapted for Codex's architecture. The skill runs in any Codex session: you are the Architect, and you spawn Builder and Reviewer as sub-agents using Codex's `spawn_agent` function.

### What's in the skill

Installed at `codex-skill/` in this repo:

| Component | Path | Purpose |
|---|---|---|
| `SKILL.md` | `codex-skill/SKILL.md` | Trigger description + full methodology adapted for Codex's `spawn_agent` model |
| **Playbooks** | `codex-skill/references/playbooks/` | PLANNING.md (Pre-Flight Check, step cutting), DIAGNOSIS.md (debugging protocol), BRIEF-EXAMPLES.md (annotated briefs) |
| **Role templates** | `codex-skill/references/role-templates/` | ARCHITECT.md, BUILDER.md, REVIEWER.md — adapted for Codex's worker/default agent types |
| **Token optimizer** | `codex-skill/references/token-optimization.md` | Five token-discipline rules + grep-before-read |
| **Setup script** | `codex-skill/scripts/setup-project.sh` | Scaffolds AGENTS.md, role stubs, handoff templates into a project |
| **Version checker** | `codex-skill/scripts/check-version.py` | Compares local manifest against bundled release registry (no network needed) |
| **Project templates** | `codex-skill/templates/project/` | AGENTS.md (session router), manifest.md (version tracking) |

### Key adaptations for Codex

| Dimension | Claude Code TMT | Codex TMT Skill |
|---|---|---|
| **Session boot** | Slash commands (`/architect`) | Skill triggers on structured work keywords |
| **Builder spawn** | Claude Code Agent tool | `spawn_agent(agent_type: "worker")` |
| **Reviewer spawn** | Claude Code Agent tool | `spawn_agent(agent_type: "default")` |
| **Session router** | CLAUDE.md | AGENTS.md |
| **Version check** | curl to GitHub API | `check-version.py` (local, sandbox-safe) |
| **Playbook paths** | `playbooks/` | `references/playbooks/` (inside skill dir) |

### Install the skill

The skill is pre-installed in this repo. To use it in your Codex environment:

```bash
# Copy the skill into your Codex skills directory
cp -R codex-skill ~/.codex/skills/three-man-team
```

To upgrade an existing install later, pull the repo and run `./upgrade codex
/path/to/your/project` — it refreshes the skill (backup kept) and adds any newly
introduced project files without touching your customizations.

Restart Codex to pick up the new skill. It will trigger automatically when your task involves structured software development, planning, multi-step builds, or review — or when you mention "three man team", "TMT", or any role name.

### Set up a project

The setup script scaffolds project files and optionally registers the Codex plugin:

```bash
# Project files only (AGENTS.md, role stubs, handoff templates)
~/.codex/skills/three-man-team/scripts/setup-project.sh /path/to/your/project

# Project files + @three-man-team Codex plugin
~/.codex/skills/three-man-team/scripts/setup-project.sh /path/to/your/project --plugin

# Codex plugin only (adds @three-man-team mention to Codex CLI)
~/.codex/skills/three-man-team/scripts/setup-project.sh --plugin-only
```

Project files: `AGENTS.md` (session router), role stubs, and a full set of `handoff/` templates. Customize the role files with your team's names and personas.

The `--plugin` flag installs a Codex plugin at `~/.agents/plugins/plugins/three-man-team/` with an App definition, enabling `@three-man-team` mention in any Codex CLI session. The `--plugin-only` flag skips project files and only registers the plugin — useful if your project is already set up.

### How to trigger in Codex CLI

**`@three-man-team` mention** — the fastest way. Installed as a Codex plugin with App definition:

```
@three-man-team I need to build a login feature, plan it out
@three-man-team let's add email validation to the registration endpoint
```

**Description matching** — the skill also activates automatically when you mention structured work:

```
Use Three Man Team to plan this feature
Be the Architect and help me design this
```

### How the workflow looks in Codex

```
You describe a problem
  → Architect (you) loads playbooks, writes brief to handoff/ARCHITECT-BRIEF.md
  → Spawn Builder: implement Step N, update BUILD-LOG, write REVIEW-REQUEST
  → Spawn Reviewer: read REVIEW-REQUEST, review the diff, write REVIEW-FEEDBACK
  → Deploy gate: report, commit, log, write SESSION-CHECKPOINT
```

Every step follows the same disciplined path — the skill delivers the methodology, Codex provides the agent infrastructure.

See `codex-skill/SKILL.md` for the full methodology body.
