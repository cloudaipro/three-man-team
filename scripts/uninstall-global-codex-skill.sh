#!/bin/bash
# Permanently remove the standalone global Three Man Team Codex skill.
#
# Usage:
#   scripts/uninstall-global-codex-skill.sh --dry-run
#   scripts/uninstall-global-codex-skill.sh --yes

set -u

DRY_RUN=0
ASSUME_YES=0

usage() {
  cat <<'EOF'
Usage: scripts/uninstall-global-codex-skill.sh [--dry-run] [--yes]

Permanently deletes ~/.agents/skills/three-man-team without creating a backup.

  --dry-run  verify and print the exact target without deleting it
  --yes      skip the interactive confirmation
  -h, --help show this help
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --yes) ASSUME_YES=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

# The override exists for isolated automated tests and non-default agents roots.
# The deletion target is still fixed to the skills/three-man-team child.
AGENTS_ROOT="${TMT_UNINSTALL_AGENTS_ROOT:-$HOME/.agents}"

if [ ! -d "$AGENTS_ROOT" ]; then
  echo "Three Man Team global skill is not installed under: $AGENTS_ROOT"
  exit 0
fi

AGENTS_ROOT="$(cd "$AGENTS_ROOT" 2>/dev/null && pwd -P)" || {
  echo "Cannot resolve agents directory: $AGENTS_ROOT" >&2
  exit 1
}

case "$AGENTS_ROOT" in
  ""|/|"$HOME")
    echo "Refusing unsafe agents directory: $AGENTS_ROOT" >&2
    exit 1
    ;;
esac

SKILL_DIR="$AGENTS_ROOT/skills/three-man-team"
SKILL_MARKER="$SKILL_DIR/SKILL.md"

if [ ! -e "$SKILL_DIR" ] && [ ! -L "$SKILL_DIR" ]; then
  echo "Three Man Team global skill is not installed at: $SKILL_DIR"
  exit 0
fi

if [ ! -f "$SKILL_MARKER" ] || ! grep -qE '^name: *"?three-man-team"? *$' "$SKILL_MARKER"; then
  echo "Refusing to delete unrecognized directory: $SKILL_DIR" >&2
  echo "Expected a SKILL.md marker with name: three-man-team." >&2
  exit 1
fi

if [ "$DRY_RUN" = 1 ]; then
  echo "Dry run: would permanently delete $SKILL_DIR"
  echo "No backup would be created."
  exit 0
fi

if [ "$ASSUME_YES" != 1 ]; then
  if [ ! -t 0 ]; then
    echo "Refusing non-interactive deletion without --yes." >&2
    exit 2
  fi
  printf 'Permanently delete %s without a backup? [y/N] ' "$SKILL_DIR"
  read -r reply
  case "$reply" in
    y|Y|yes|YES) ;;
    *) echo "Uninstall cancelled."; exit 0 ;;
  esac
fi

rm -rf "$SKILL_DIR"

if [ -e "$SKILL_DIR" ] || [ -L "$SKILL_DIR" ]; then
  echo "Uninstall failed; target still exists: $SKILL_DIR" >&2
  exit 1
fi

echo "Three Man Team global skill permanently removed: $SKILL_DIR"
echo "Restart Codex to refresh skill discovery."
