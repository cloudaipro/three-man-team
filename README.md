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

## What's New — v2.5.0

**Critical release checkpoint.** v2.5.0 is the current release. The registry marks it critical, so the Architect must walk [the v2.5.0 release record](releases/v2.5.0.json) with the Product Owner before acknowledging it. Fresh Codex projects now use lean local role deltas; existing customized roles change only via `./upgrade codex --migrate-role-files <project>`, which creates timestamped backups. The aggregate-only local usage audit reports no prompts or responses. Every active Codex Builder and Reviewer spawn uses Luna/Max with fresh context; if Luna is unavailable, Architect reports the blocker instead of substituting another child configuration.

## v2.3.1 — Codex scaffolder repair

**The installer was behind the instructions.** v2.3.0 added a `scripts/check-handoff.sh` row to `RULES.md`'s Mechanical Gate, but the Codex scaffolder never installed the script — so every Codex project set up on v2.3.0 carries a gate command that fails on every step, and a failing gate blocks every review request. The Claude build was unaffected. **If you are on Codex, this patch is the fix**, and your install cannot find it on its own: a project stamped `v2.3.0` matches the old registry, so the version check stays silent.

The same bug shape as v1.9.0's `manifest.md` gap — the scaffolder installing the file that references a thing without installing the thing. Per the framework's own rule that a lesson landing twice becomes a standing check, `check-consistency.sh` now asserts the scaffolder installs every project file its other files reference.

---

## v2.3.0 — an accuracy bug is a token bug

**An accuracy bug is a token bug.** Anthropic's [new rules of context engineering](https://claude.com/blog/the-new-rules-of-context-engineering-for-claude-5-generation-models) (2026-07-24) removed over 80% of Claude Code's system prompt with no measurable eval loss, naming overconstraint and *conflicting instructions across layers* as the cause of the bloat. Combined with v2.0.0's finding that 94.6% of a real session's bill was re-processing accumulated context, the conclusion is that trimming a role file is a rounding error — the prelude caches — while a **bounced step** re-runs the whole loop and re-bills every agent's context. So this release spends its effort on making handoffs mechanically checkable and deleting instructions that conflict.

- **`scripts/check-handoff.sh`** — asserts a brief or review request is structurally complete before anyone builds or reviews against it: sections present, no unfilled placeholders, and a Definition of Done that carries a runnable command. Wired into the Mechanical Gate, the Architect's Pre-Flight, and both subagents' session starts. *A criterion you cannot express as a command means the step is not specified sharply enough to build* — surfaced at brief time for one line instead of at review time for a whole loop
- **The token-optimizer skill your agents load was stale** — drifted off the docs copy and missing the cost model, the cache setting, and the model routing table, while `CLAUDE.md` told every role to load it first. Now one source, three identical copies, guarded by the repo self-audit
- **The five-rule Token Rules block is gone**, replaced by the cost model and a Gotchas section. Two of the five were harmful, not just redundant: "trust it, skip the file read" tells an agent to act on possibly-stale memory, and the 20-line subagent threshold sits below the cost of spawning one. This reverses a deliberate v2.2.0 call — see the CHANGELOG for why the reasoning changed
- **`REVIEWER.md`'s checklists were deliberately left intact** — "judgment over rules" is a current-generation finding, and the `haiku` alias resolves to a smaller, older-generation model

**v2.2.0** trimmed the floor the busiest agents carry — subagents stopped loading the full token-optimizer essay, and the Architect's model-routing policy was stated once instead of three times. **v2.1.0** converged model routing — the Codex build now routes Sol / Terra / Luna, the analog of Opus / Sonnet / Haiku. **v2.0.0** made *context the cost* — per-role context budgets, model-tier routing, and the 1-hour prompt cache. **v1.9.0** made BUILD-LOG size a mechanical gate. **v1.7.0** added the `RULES.md` quality contract. **v1.6.0** added the Codex skill (`codex-skill/`).

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

The expensive thing in a multi-agent build is not what an agent loads — it is what it
**carries**. Context accumulates and is re-billed on every following turn, so cost grows with
the square of how long an agent runs. Measured on a real multi-hour session: 94.6% of the bill
was re-processing accumulated context, and every file read combined was 0.1%.

So the framework optimizes the things that actually move that number:

- **Bounded role context** — a cap per role, then checkpoint and respawn instead of continuing
  a swollen context
- **A warm cache across handoffs** — the 1-hour prompt cache TTL, because every handoff gap is
  longer than the 5-minute default
- **Model tiers matched to the job** — Architect on Opus, Builder on Sonnet, Reviewer on Haiku
- **Fewer bounced steps** — a rejected step re-runs the whole loop and re-bills every agent's
  context, which makes the Mechanical Gate and `scripts/check-handoff.sh` token optimizations
  as much as quality controls

The token-optimizer skill ships with every install and auto-loads via CLAUDE.md — no manual
setup required. Full reasoning: [docs/token-optimization.md](docs/token-optimization.md).

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
| `--migrate-role-files` | codex only | Explicitly back up existing local role files, then replace them with lean project deltas. Normal upgrades never do this |
| `TMT_CODEX_SKILL_DIR=<dir>` (env) | codex only | Override the exact skill directory to refresh. Normally unnecessary: the tool detects repository-scoped, personal, and existing `$CODEX_HOME/skills` installs |

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

Using the Codex skill instead? From the repository checkout, use the same tool with
one word different:

```bash
./upgrade codex /path/to/your/project
```

The codex upgrade refreshes the repository-scoped skill when the project has one;
otherwise it refreshes the personal skill at `~/.agents/skills/three-man-team`. It also
recognizes an existing `$CODEX_HOME/skills/three-man-team` install. Framework files
— playbooks, role templates, and the bundled version registry — live inside the skill,
and the previous version is kept outside Codex's scanned `skills/` directory under the
installation scope's `skill-backups/` directory. The tool then adds newly
introduced project files (like `RULES.md`) without overwriting anything of yours. Your
next Codex session's version check sees the refreshed registry and walks the changes with
you. Use `TMT_CODEX_SKILL_DIR` only when you need to select a different installation
explicitly.

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

Three Man Team ships as a [Codex skill](https://learn.chatgpt.com/docs/build-skills) — the full methodology adapted for Codex's architecture. The skill runs in any Codex session: you are the Architect, and you spawn Builder and Reviewer as sub-agents using Codex's `spawn_agent` function.

### What's in the skill

Installed at `codex-skill/` in this repo:

| Component | Path | Purpose |
|---|---|---|
| `SKILL.md` | `codex-skill/SKILL.md` | Trigger description + full methodology adapted for Codex's `spawn_agent` model |
| **Playbooks** | `codex-skill/references/playbooks/` | PLANNING.md (Pre-Flight Check, step cutting), DIAGNOSIS.md (debugging protocol), BRIEF-EXAMPLES.md (annotated briefs) |
| **Role templates** | `codex-skill/references/role-templates/` | ARCHITECT.md, BUILDER.md, REVIEWER.md — full Codex role templates |
| **Token optimizer** | `codex-skill/references/token-optimization.md` | Codex-specific context, routing, and handoff discipline |
| **Setup script** | `codex-skill/scripts/setup-project.sh` | Scaffolds AGENTS.md, full role templates, and handoff templates into a project |
| **Version checker** | `codex-skill/scripts/check-version.py` | Offline update walk plus explicit acknowledgement against bundled release files |
| **Project templates** | `codex-skill/templates/project/` | AGENTS.md (session router), manifest.md (version tracking) |

### Key adaptations for Codex

| Dimension | Claude Code TMT | Codex TMT Skill |
|---|---|---|
| **Session boot** | Slash commands (`/architect`) | `$three-man-team` or automatic description matching |
| **Builder spawn** | Claude Code Agent tool | `spawn_agent` with Luna/Max only; unavailable Luna blocks the spawn |
| **Reviewer spawn** | Claude Code Agent tool | `spawn_agent` with Luna/Max only; unavailable Luna blocks the spawn |
| **Session router** | CLAUDE.md | AGENTS.md |
| **Version check** | curl to GitHub API | `check-version.py` (local, sandbox-safe) |
| **Playbook paths** | `playbooks/` | `references/playbooks/` (inside skill dir) |

### Per-project install (recommended)

Use this when only one repository should carry the Three Man Team skill. From a checkout of this repository:

```bash
mkdir -p /path/to/your/project/.agents/skills
cp -R codex-skill /path/to/your/project/.agents/skills/three-man-team

# Add AGENTS.md, lean project role deltas, and handoff templates
/path/to/your/project/.agents/skills/three-man-team/scripts/setup-project.sh /path/to/your/project
```

Codex detects repository-scoped skills automatically; if the skill does not appear, restart Codex from that project. It can trigger for structured software development, planning, multi-step builds, review, or Three Man Team role names.

### Global install (all projects)

Use this when you want the skill available in every repository:

```bash
mkdir -p ~/.agents/skills
cp -R codex-skill ~/.agents/skills/three-man-team
```

Codex detects personal skills automatically; if the skill does not appear, restart Codex. To upgrade an existing install later, pull the repository and run the upgrade from its checkout:

```bash
cd /path/to/three-man-team
git pull --ff-only origin main

# Preview the global-skill and project changes
TMT_CODEX_SKILL_DIR="$HOME/.agents/skills/three-man-team" \
  ./upgrade codex /path/to/your/project --dry-run

# Apply the update
TMT_CODEX_SKILL_DIR="$HOME/.agents/skills/three-man-team" \
  ./upgrade codex /path/to/your/project
```

`TMT_CODEX_SKILL_DIR` explicitly selects the global install even when the target project also
has a repository-scoped copy. The upgrade keeps the previous global skill under
`~/.agents/skill-backups/` and adds newly introduced project files without overwriting existing
customizations or live handoff data. Do not repeat `cp -R codex-skill
~/.agents/skills/three-man-team` over an existing install: depending on the local `cp`
implementation, that can merge stale files or create a nested `codex-skill/` directory.

To replace legacy full project role files with v2.5's lean role deltas, opt in once with
`--migrate-role-files`. The upgrader creates a separate timestamped backup before replacing
them; normal global updates leave role files untouched.

#### Remove the standalone global install

Close active Codex sessions, then run the uninstaller from the repository checkout. Preview the
exact target first:

```bash
./scripts/uninstall-global-codex-skill.sh --dry-run
./scripts/uninstall-global-codex-skill.sh --yes
```

This permanently deletes `~/.agents/skills/three-man-team`; it does **not** create or move the
skill to a backup. Without `--yes`, the script asks for interactive confirmation. It verifies
the exact directory shape and the Three Man Team `SKILL.md` marker before deleting anything.
Restart Codex after removal.

The script removes only the standalone global skill. It does not remove repository-scoped
copies, project files such as `AGENTS.md` or `handoff/`, existing backup directories, or a
separately registered Codex plugin.

The setup script scaffolds project files and optionally registers the Codex plugin:

```bash
# Project files only (AGENTS.md, lean role deltas, handoff templates)
~/.agents/skills/three-man-team/scripts/setup-project.sh /path/to/your/project

# Project files + installable Three Man Team Codex plugin
~/.agents/skills/three-man-team/scripts/setup-project.sh /path/to/your/project --plugin

# Codex plugin only
~/.agents/skills/three-man-team/scripts/setup-project.sh --plugin-only
```

Project files: `AGENTS.md` (session router), lean role deltas, and a full set of `handoff/` templates. Customize the role files with your team's names and project-specific constraints; the installed skill remains the canonical workflow source.

The `--plugin` flag stages a skills-only plugin at `~/plugins/three-man-team/`, registers it in the personal marketplace at `~/.agents/plugins/marketplace.json`, then runs `codex plugin add`. On a replacement install it applies a Codex build-metadata cachebuster before reinstalling, so the CLI cannot reuse stale skill content. It reports failure if Codex cannot install it. The `--plugin-only` flag skips project files and performs that same plugin workflow. A legacy payload under `~/.agents/plugins/plugins/three-man-team/` is left untouched because Codex resolves `./plugins/three-man-team` to `~/plugins/three-man-team/`.

### How to trigger in Codex

**Explicit skill invocation** — use Codex's `$skill-name` syntax with either the standalone skill or the installed plugin's bundled skill:

```text
$three-man-team I need to build a login feature; plan it out
$three-man-team let's add email validation to the registration endpoint
```

After installing the plugin, start a new Codex session before invoking its bundled skill.

**Description matching** — Codex can also activate the skill automatically when the task matches its description:

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
  → Deploy gate: report, commit, push/deploy, confirm, log, write SESSION-CHECKPOINT
```

Every step follows the same disciplined path — the skill delivers the methodology, Codex provides the agent infrastructure.

See `codex-skill/SKILL.md` for the full methodology body.
