# Installing Three Man Team

**How the team runs:** Three Man Team uses one Claude Code session. Arch is your main agent. Bob and Richard are subagents — Arch spins them up via Claude Code's Agent tool. You don't need three separate windows.

For the full quick start, see [README.md](README.md).

---

## Per-Project Install

Clone into your project folder, then run setup:

```bash
git clone https://github.com/cloudaipro/three-man-team.git .claude/skills/three-man-team
cd .claude/skills/three-man-team && ./setup
```

Setup handles the rest — follow what it prints.

---

## Global Install

Install once, use in any project:

```bash
git clone https://github.com/cloudaipro/three-man-team.git ~/.claude/skills/three-man-team
cd ~/.claude/skills/three-man-team && ./setup
```

Then for each project:

```bash
cp -r ~/.claude/skills/three-man-team/templates/project-folder/. /path/to/your/project/
cd /path/to/your/project
```

Open Claude Code and type:

```
/tmt-setup
```

(or paste: *You are the Architect on this project. Please read new-setup.md.*)

After setup, every session starts with just `/architect`.

---

## Upgrading an Existing Project

```bash
git -C ~/.claude/skills/three-man-team pull
~/.claude/skills/three-man-team/upgrade /path/to/your/project
```

Safe by default: additive installs only, backups of everything it edits, live `handoff/`
data and custom personas untouched — your next `/architect` session finishes the role-file
wiring interactively. Stock installs can add `--replace-role-files` for a one-shot upgrade;
`--dry-run` previews any run.

---

## Recommended: Turn On the 1-Hour Prompt Cache

Three Man Team runs on handoffs — Architect briefs, you review, Builder waits, Reviewer reads.
Claude Code's default 5-minute cache TTL expires in those gaps and re-bills the whole context at
write price on the next call. Switch to the 1-hour TTL once, in `~/.claude/settings.json`:

```json
{ "env": { "ENABLE_PROMPT_CACHING_1H": "1" } }
```

This is the single cheapest cost win for this methodology. See [docs/token-optimization.md](docs/token-optimization.md).

---

## Requirements

- Claude Code CLI — install at https://claude.ai/code
- Git

### Windows

Three Man Team's setup script requires bash. On Windows, use Git Bash or WSL — the script will not run in PowerShell or Command Prompt.

Manual setup alternative: copy the files from `templates/project-folder/` into your project directory yourself, then open Claude Code and type `/tmt-setup` (or paste):

```
You are the Architect on this project. Please read new-setup.md.
```

RTK is not currently supported on Windows. Skip the RTK setup step.

## Critical: Always Run Builder and Reviewer in the Foreground

**Do not run Builder or Reviewer as background agents.**

Background agents cannot receive tool approval prompts. The first time Builder tries to
write a file, it will stall with nobody to approve it. If Builder or Reviewer seems to
never run or stops silently — this is why.

When using the Agent tool: leave `run_in_background` unset (defaults to foreground).
When using manual paste: the fresh conversation is inherently foreground.
