#!/bin/bash
# Three Man Team — repo self-audit
#
# The framework tells its users "lessons become rules, machines check what
# machines can check." This script is the repo taking its own advice: every
# release-machinery invariant that has drifted before (or could) is a check
# here, not a memory. Run it locally or in CI; exit 0 = clean.
#
# Usage: scripts/check-consistency.sh

set -u
cd "$(dirname "$0")/.."

FAIL=0
problem() { echo "✗ $*"; FAIL=1; }
ok()      { echo "  ✓ $*"; }

echo "— Release registry"

MANIFEST_V="$(sed -n 's/^version: *//p' manifest.md | head -1)"
LATEST_V="$(sed -n 's/.*"latest": *"\([^"]*\)".*/\1/p' releases/latest.json | head -1)"

if [ -z "$MANIFEST_V" ]; then
  problem "manifest.md has no version: line"
elif [ "$MANIFEST_V" != "$LATEST_V" ]; then
  problem "version drift: manifest.md says $MANIFEST_V but releases/latest.json says $LATEST_V"
else
  ok "manifest.md and releases/latest.json agree on $LATEST_V"
fi

# The Codex skill bundles a copy of the registry for its offline version
# checker (scripts/check-version.py) — it must match the real one
if ! cmp -s releases/latest.json codex-skill/releases/latest.json; then
  problem "codex-skill/releases/latest.json is out of sync with releases/latest.json — the Codex offline version check will report a stale 'latest'"
else
  ok "codex-skill bundled registry matches releases/latest.json"
fi

# An update walk needs the detailed release files, not only the registry. The
# plugin and standalone Codex skill work offline, so every registry release
# must be bundled with its matching JSON document.
CODEX_RELEASES_OK=1
for v in $(grep -o '"version": *"[^"]*"' releases/latest.json | cut -d'"' -f4); do
  if [ ! -f "codex-skill/releases/$v.json" ]; then
    problem "codex-skill/releases/$v.json is missing — Codex cannot walk that bundled update"
    CODEX_RELEASES_OK=0
  elif ! cmp -s "releases/$v.json" "codex-skill/releases/$v.json"; then
    problem "codex-skill/releases/$v.json differs from releases/$v.json"
    CODEX_RELEASES_OK=0
  fi
done
[ "$CODEX_RELEASES_OK" = 1 ] && ok "Codex bundles every detailed release file"

# The Codex project manifest template carries the version a fresh install is
# stamped with. It drifted to v1.5.0 across four releases because nothing
# installed it and nothing checked it — assert it here so that cannot recur.
CODEX_TPL_MANIFEST="codex-skill/templates/project/manifest.md"
if [ ! -f "$CODEX_TPL_MANIFEST" ]; then
  problem "$CODEX_TPL_MANIFEST is missing — Codex installs have no version marker"
else
  CODEX_TPL_V="$(sed -n 's/^version: *//p' "$CODEX_TPL_MANIFEST" | head -1)"
  if [ "$CODEX_TPL_V" != "$LATEST_V" ]; then
    problem "$CODEX_TPL_MANIFEST says $CODEX_TPL_V but the registry latest is $LATEST_V — fresh Codex installs would be stamped stale"
  else
    ok "Codex project manifest template matches the registry latest"
  fi
fi

# Every version listed in the registry must have its release file
MISSING_JSON=0
for v in $(grep -o '"version": *"[^"]*"' releases/latest.json | cut -d'"' -f4); do
  if [ ! -f "releases/$v.json" ]; then
    problem "releases/latest.json lists $v but releases/$v.json does not exist"
    MISSING_JSON=1
  fi
done
[ "$MISSING_JSON" = 0 ] && ok "every registry version has a release file"

echo ""
echo "— Git tags & GitHub releases"

# Fork convention starts at v1.6.0 — earlier versions shipped from upstream
# without tags on this fork, and fabricating history helps nobody.
TAG_FLOOR="v1.6.0"

# A tag counts if the local clone has it, or — for clones fetched without
# tags (shallow CI checkouts, --no-tags clones) — if the remote has it.
tag_exists() {
  git tag -l "$1" | grep -q . && return 0
  git ls-remote --exit-code --tags origin "refs/tags/$1" >/dev/null 2>&1
}

# The latest version is warned about, not failed: CI runs on the release
# commit BEFORE it gets tagged, so a hard fail would deadlock every release.
# A forgotten tag turns into a hard failure the moment the next version
# enters the registry and the untagged one is no longer latest.
TAGS_OK=1
for v in $(grep -o '"version": *"[^"]*"' releases/latest.json | cut -d'"' -f4); do
  # skip versions older than the floor
  if [ "$v" != "$TAG_FLOOR" ] && \
     [ "$(printf '%s\n%s\n' "$v" "$TAG_FLOOR" | sort -V | head -1)" = "$v" ]; then
    continue
  fi
  if tag_exists "$v"; then
    continue
  fi
  if [ "$v" = "$LATEST_V" ]; then
    echo "  ⚠ $v (latest) is not tagged yet — finish the release: git tag $v && git push origin $v && gh release create $v"
  else
    problem "$v is in the registry but has no git tag — releases must be tagged"
    TAGS_OK=0
  fi
done
[ "$TAGS_OK" = 1 ] && ok "every released registry version ($TAG_FLOOR+) has a git tag"

# GitHub releases: same rule, checked only when gh is available and authed
# (CI passes GH_TOKEN; offline local runs skip without failing)
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  REL_OK=1
  for v in $(grep -o '"version": *"[^"]*"' releases/latest.json | cut -d'"' -f4); do
    if [ "$v" != "$TAG_FLOOR" ] && \
       [ "$(printf '%s\n%s\n' "$v" "$TAG_FLOOR" | sort -V | head -1)" = "$v" ]; then
      continue
    fi
    if gh release view "$v" >/dev/null 2>&1; then
      continue
    fi
    if [ "$v" = "$LATEST_V" ]; then
      echo "  ⚠ $v (latest) has no GitHub release yet — gh release create $v"
    else
      problem "$v is in the registry but has no GitHub release"
      REL_OK=0
    fi
  done
  [ "$REL_OK" = 1 ] && ok "every released registry version ($TAG_FLOOR+) has a GitHub release"
else
  say "gh unavailable or unauthenticated — GitHub release check skipped (runs in CI)"
fi

echo ""
echo "— Changelog"

if ! grep -q "^## $LATEST_V " CHANGELOG.md; then
  problem "CHANGELOG.md has no entry for $LATEST_V"
else
  ok "CHANGELOG.md has an entry for $LATEST_V"
fi

FIRST_ENTRY="$(grep -o '^## v[0-9.]*' CHANGELOG.md | head -1 | sed 's/^## //')"
if [ "$FIRST_ENTRY" != "$LATEST_V" ]; then
  problem "CHANGELOG.md top entry is $FIRST_ENTRY, expected $LATEST_V (entries must be newest-first)"
else
  ok "CHANGELOG.md leads with $LATEST_V"
fi

# The README's "What's New" heading is the first thing a visitor reads. It sat at
# v1.7.0 while v1.9.0 was tagged, because nothing checked it.
README_V="$(sed -n 's/^## What.s New — *\(v[0-9.]*\).*/\1/p' README.md | head -1)"
if [ -z "$README_V" ]; then
  problem "README.md has no '## What's New — vX.Y.Z' heading to check"
elif [ "$README_V" != "$LATEST_V" ]; then
  problem "README.md What's New says $README_V but the registry latest is $LATEST_V — the landing page advertises a stale release"
else
  ok "README.md What's New matches $LATEST_V"
fi

echo ""
echo "— Template-set parity (project-folder ↔ generic)"

# Framework-owned files that must exist in both template sets
PARITY_FILES="RULES.md
scripts/check-handoff.sh
playbooks/PLANNING.md
playbooks/DIAGNOSIS.md
playbooks/BRIEF-EXAMPLES.md
playbooks/VERSION-CHECK.md
.claude/commands/architect.md
.claude/commands/tmt-setup.md
handoff/ARCHITECT-BRIEF.md
handoff/BUILD-LOG.md
handoff/REVIEW-REQUEST.md
handoff/REVIEW-FEEDBACK.md
handoff/SESSION-CHECKPOINT.md
ARCHITECT.md
BUILDER.md
REVIEWER.md
new-setup.md"

PARITY_OK=1
while IFS= read -r f; do
  for set in project-folder generic; do
    if [ ! -f "templates/$set/$f" ]; then
      problem "templates/$set/$f is missing"
      PARITY_OK=0
    fi
  done
done <<< "$PARITY_FILES"
[ "$PARITY_OK" = 1 ] && ok "both template sets carry the full framework file set"

# Role-neutral files must be byte-identical everywhere they ship
IDENTICAL_SETS="RULES.md:templates/project-folder/RULES.md templates/generic/RULES.md codex-skill/templates/project/RULES.md
check-handoff.sh:templates/project-folder/scripts/check-handoff.sh templates/generic/scripts/check-handoff.sh codex-skill/templates/project/scripts/check-handoff.sh
ARCHITECT-BRIEF.md:templates/project-folder/handoff/ARCHITECT-BRIEF.md templates/generic/handoff/ARCHITECT-BRIEF.md codex-skill/templates/project/handoff/ARCHITECT-BRIEF.md
BUILD-LOG.md:templates/project-folder/handoff/BUILD-LOG.md templates/generic/handoff/BUILD-LOG.md codex-skill/templates/project/handoff/BUILD-LOG.md
REVIEW-REQUEST.md:templates/project-folder/handoff/REVIEW-REQUEST.md templates/generic/handoff/REVIEW-REQUEST.md codex-skill/templates/project/handoff/REVIEW-REQUEST.md
REVIEW-FEEDBACK.md:templates/project-folder/handoff/REVIEW-FEEDBACK.md templates/generic/handoff/REVIEW-FEEDBACK.md codex-skill/templates/project/handoff/REVIEW-FEEDBACK.md
SESSION-CHECKPOINT.md:templates/project-folder/handoff/SESSION-CHECKPOINT.md templates/generic/handoff/SESSION-CHECKPOINT.md
token-optimization.md:docs/token-optimization.md templates/project-folder/.claude/skills/token-optimization.md
PLANNING.md:templates/project-folder/playbooks/PLANNING.md templates/generic/playbooks/PLANNING.md codex-skill/references/playbooks/PLANNING.md
DIAGNOSIS.md:templates/project-folder/playbooks/DIAGNOSIS.md templates/generic/playbooks/DIAGNOSIS.md codex-skill/references/playbooks/DIAGNOSIS.md
BRIEF-EXAMPLES.md:templates/project-folder/playbooks/BRIEF-EXAMPLES.md templates/generic/playbooks/BRIEF-EXAMPLES.md codex-skill/references/playbooks/BRIEF-EXAMPLES.md
VERSION-CHECK.md:templates/project-folder/playbooks/VERSION-CHECK.md templates/generic/playbooks/VERSION-CHECK.md
architect.md:templates/project-folder/.claude/commands/architect.md templates/generic/.claude/commands/architect.md
tmt-setup.md:templates/project-folder/.claude/commands/tmt-setup.md templates/generic/.claude/commands/tmt-setup.md"

IDENTICAL_OK=1
while IFS= read -r line; do
  name="${line%%:*}"
  files="${line#*:}"
  ref=""
  for f in $files; do
    if [ ! -f "$f" ]; then
      problem "$f is missing (identical-copy set: $name)"
      IDENTICAL_OK=0
      continue
    fi
    if [ -z "$ref" ]; then
      ref="$f"
    elif ! cmp -s "$ref" "$f"; then
      problem "$f differs from $ref — role-neutral copies must be identical (edit one, copy to the rest)"
      IDENTICAL_OK=0
    fi
  done
done <<< "$IDENTICAL_SETS"
[ "$IDENTICAL_OK" = 1 ] && ok "role-neutral copies are byte-identical across their locations"

echo ""
echo "— Codex-specific contracts"

# The Claude copies intentionally retain Claude setup guidance. The Codex copy
# must instead describe only Codex runtime behavior; byte identity here would
# reintroduce the exact cross-platform drift this check is meant to prevent.
CODEX_TOKEN="codex-skill/references/token-optimization.md"
if grep -qE 'ENABLE_PROMPT_CACHING_1H|~/.claude|\bopus\b|\bsonnet\b|\bhaiku\b' "$CODEX_TOKEN"; then
  problem "$CODEX_TOKEN contains active Claude-only configuration or routing guidance"
else
  ok "Codex token guidance is runtime-specific"
fi

for f in codex-skill/SKILL.md codex-skill/references/role-templates/ARCHITECT.md codex-skill/templates/project/AGENTS.md; do
  if ! grep -q 'check-version.py' "$f"; then
    problem "$f does not wire the Codex version check into session start"
  fi
done
if grep -q 'agent_type' codex-skill/SKILL.md README.md; then
  problem "active Codex instructions still use unsupported agent_type routing"
else
  ok "Codex spawn documentation uses current arguments"
fi

if grep -q 'features\.multi_agent_v2' codex-skill/PORTING-NOTES.md; then
  problem "PORTING-NOTES.md retains obsolete multi-agent routing configuration"
else
  ok "Codex routing notes use capability-aware fallback"
fi

if grep -q 'Type `/architect`' codex-skill/templates/project/handoff/SESSION-CHECKPOINT.md; then
  problem "Codex checkpoint template contains a Claude slash-command resume instruction"
else
  ok "Codex checkpoint resume instruction is native"
fi

PLUGIN_MANIFEST="codex-skill/templates/plugin/.codex-plugin/plugin.json"
PLUGIN_CONTRACT="scripts/check-codex-plugin.py"
if [ ! -f "$PLUGIN_MANIFEST" ]; then
  problem "$PLUGIN_MANIFEST is missing"
elif [ -f "codex-skill/templates/plugin/.app.json" ]; then
  problem "Codex skills-only plugin still ships .app.json"
elif ! python3 "$PLUGIN_CONTRACT" "$PLUGIN_MANIFEST" "$LATEST_V"
then
  problem "Codex plugin manifest violates its release-bound skills-only contract"
else
  ok "Codex plugin template matches the latest release and skills-only contract"
fi

for obsolete in three-man-team/.app.json three-man-team/.codex-plugin/plugin.json; do
  if [ -e "$obsolete" ]; then
    problem "obsolete root plugin artifact remains: $obsolete"
  fi
done

CODEX_SETUP="codex-skill/scripts/setup-project.sh"
for needle in 'local plugin_root="${TMT_PLUGIN_ROOT:-$HOME/plugins}"' 'skills/three-man-team/SKILL.md' 'plugin add' 'TMT_SKIP_PLUGIN_ADD' 'references/role-templates/${role}.md'; do
  if ! grep -Fq "$needle" "$CODEX_SETUP"; then
    problem "$CODEX_SETUP is missing required plugin/project setup behavior: $needle"
  fi
done
for f in codex-skill/SKILL.md codex-skill/references/role-templates/ARCHITECT.md; do
  for needle in 'fork_turns: "none"' 'references/role-templates/BUILDER.md' 'references/role-templates/REVIEWER.md' 'builder_step_${step}_attempt_${attempt}' 'reviewer_step_${step}_attempt_${attempt}'; do
    if ! grep -Fq "$needle" "$f"; then
      problem "$f is missing fresh-agent spawn contract: $needle"
    fi
  done
  if grep -Fq 'builder-step-${step}-attempt-${attempt}' "$f" || grep -Fq 'reviewer-step-${step}-attempt-${attempt}' "$f"; then
    problem "$f contains a hyphenated task_name that violates the spawn_agent schema"
  fi
done

echo ""
echo "— Upgrade tool sources"

# Every file the upgrade tool copies out of templates/project-folder must exist
UPGRADE_SOURCES="playbooks/PLANNING.md
playbooks/DIAGNOSIS.md
playbooks/BRIEF-EXAMPLES.md
playbooks/VERSION-CHECK.md
.claude/commands/architect.md
.claude/commands/tmt-setup.md
.claude/skills/token-optimization.md
scripts/check-handoff.sh
RULES.md
ARCHITECT.md
BUILDER.md
REVIEWER.md"

UPG_OK=1
while IFS= read -r f; do
  if [ ! -f "templates/project-folder/$f" ]; then
    problem "upgrade tool source templates/project-folder/$f is missing"
    UPG_OK=0
  fi
done <<< "$UPGRADE_SOURCES"
[ "$UPG_OK" = 1 ] && ok "every file the upgrade tool ships exists in the clone"

# A shipped script that lands without its executable bit is a gate command that fails on
# every project that installs it — and the failure looks like a broken gate, not a broken
# install. git tracks the mode, so assert it here.
EXEC_OK=1
for f in templates/project-folder/scripts/check-handoff.sh \
         templates/generic/scripts/check-handoff.sh \
         codex-skill/templates/project/scripts/check-handoff.sh; do
  if [ ! -x "$f" ]; then
    problem "$f is not executable — projects that install it get a failing gate command"
    EXEC_OK=0
  fi
done
[ "$EXEC_OK" = 1 ] && ok "shipped handoff-check scripts are executable"

# The Codex scaffolder must install every project file that another installed file
# references by name. v1.9.0 fixed this once — setup-project.sh scaffolded RULES.md
# and the handoff set but never manifest.md, so the version check reported "unknown"
# on every Codex install. v2.3.0 reproduced it exactly: RULES.md's gate row calls
# scripts/check-handoff.sh, and the scaffolder did not install the script. Second
# occurrence of one lesson, so by the framework's own rule it becomes a check.
CODEX_SETUP="codex-skill/scripts/setup-project.sh"
SCAFFOLD_OK=1
for needle in "project/scripts/check-handoff.sh" "project/handoff/" "project/manifest.md" "project/RULES.md"; do
  if ! grep -q "$needle" "$CODEX_SETUP"; then
    problem "$CODEX_SETUP never installs $needle — a Codex project would carry files that reference it without having it"
    SCAFFOLD_OK=0
  fi
done
[ "$SCAFFOLD_OK" = 1 ] && ok "Codex scaffolder installs every file its other files reference"

# The Codex bundle must carry the handoff templates the scaffolder copies from
CODEX_HANDOFF_OK=1
for hf in ARCHITECT-BRIEF.md BUILD-LOG.md REVIEW-REQUEST.md REVIEW-FEEDBACK.md SESSION-CHECKPOINT.md; do
  if [ ! -f "codex-skill/templates/project/handoff/$hf" ]; then
    problem "codex-skill/templates/project/handoff/$hf is missing — Codex installs fall back to a bare stub the handoff check cannot validate"
    CODEX_HANDOFF_OK=0
  fi
done
[ "$CODEX_HANDOFF_OK" = 1 ] && ok "Codex bundle carries the full handoff template set"

echo ""
if [ "$FAIL" = 1 ]; then
  echo "Self-audit FAILED — fix the problems above before releasing."
  exit 1
fi
echo "Self-audit clean."
