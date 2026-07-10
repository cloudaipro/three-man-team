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
