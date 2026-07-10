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
  if git tag -l "$v" | grep -q .; then
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

echo ""
echo "— Template-set parity (project-folder ↔ generic)"

# Framework-owned files that must exist in both template sets
PARITY_FILES="RULES.md
playbooks/PLANNING.md
playbooks/DIAGNOSIS.md
playbooks/BRIEF-EXAMPLES.md
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
PLANNING.md:templates/project-folder/playbooks/PLANNING.md templates/generic/playbooks/PLANNING.md codex-skill/references/playbooks/PLANNING.md
DIAGNOSIS.md:templates/project-folder/playbooks/DIAGNOSIS.md templates/generic/playbooks/DIAGNOSIS.md codex-skill/references/playbooks/DIAGNOSIS.md
BRIEF-EXAMPLES.md:templates/project-folder/playbooks/BRIEF-EXAMPLES.md templates/generic/playbooks/BRIEF-EXAMPLES.md codex-skill/references/playbooks/BRIEF-EXAMPLES.md
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
echo "— Upgrade tool sources"

# Every file the upgrade tool copies out of templates/project-folder must exist
UPGRADE_SOURCES="playbooks/PLANNING.md
playbooks/DIAGNOSIS.md
playbooks/BRIEF-EXAMPLES.md
.claude/commands/architect.md
.claude/commands/tmt-setup.md
.claude/skills/token-optimization.md
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

echo ""
if [ "$FAIL" = 1 ]; then
  echo "Self-audit FAILED — fix the problems above before releasing."
  exit 1
fi
echo "Self-audit clean."
