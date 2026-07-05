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

## What's New — v1.5.0

- New: slash commands — start every session by typing `/architect` (optionally with your first request: `/architect fix the login bug`). First-time setup is `/tmt-setup`. No more pasting boot prompts; the classic prompts remain as fallback.
- The commands are role-neutral — they read `manifest.md` to find your role files, so renamed teams need no edits.

**v1.4.0** added `playbooks/` — the Architect's planning discipline as on-demand files: `PLANNING.md` (problem framing, step cutting, the seven-question Pre-Flight Check that gates every build), `DIAGNOSIS.md` (read-don't-recall debugging, the two-strikes rule), `BRIEF-EXAMPLES.md` (annotated weak-vs-strong briefs) — plus Out of Scope in every brief, a Lessons section in BUILD-LOG, and a Builder that refuses incomplete briefs.

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

Update your clone, then run the upgrade tool against your project:

```bash
git -C ~/.claude/skills/three-man-team pull
~/.claude/skills/three-man-team/upgrade /path/to/your/project
```

(Per-project installs: the clone lives at `.claude/skills/three-man-team` inside the project.)

The tool installs everything additive — `playbooks/`, the `/architect` and `/tmt-setup`
commands, the token-optimizer skill — points your version check at this repo, backs up
every file it edits, and never touches your live `handoff/` data, team names, or personas.
Then start your next session with `/architect`: Arch walks the remaining role-file upgrades
with you interactively.

Never renamed or customized your team? Add `--replace-role-files` to bring ARCHITECT.md,
BUILDER.md, and REVIEWER.md fully current in one shot (the tool refuses this flag on
customized installs). Preview any run with `--dry-run`.

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
