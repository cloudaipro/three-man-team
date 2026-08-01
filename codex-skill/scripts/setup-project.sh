#!/bin/bash
# Three Man Team — Codex project setup
# Scaffolds handoff templates, full role templates, AGENTS.md into a project directory,
# and optionally stages and installs the Three Man Team Codex plugin.
#
# Usage:
#   ./setup-project.sh /path/to/your/project             # project files only
#   ./setup-project.sh /path/to/your/project --plugin    # project files + Codex plugin
#   ./setup-project.sh --plugin-only                     # Codex plugin only

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TPL="$SCRIPT_DIR/templates"
DEST="${1:-}"
MODE="project"
PLUGIN_STATUS="not requested"

# --- arg parsing ---
for arg in "$@"; do
  case "$arg" in
    --plugin)     MODE="both" ;;
    --plugin-only) MODE="plugin-only" ;;
    --help|-h)
      echo "Usage:"
      echo "  ./setup-project.sh /path/to/your/project          project files only"
      echo "  ./setup-project.sh /path/to/your/project --plugin project + Codex plugin"
      echo "  ./setup-project.sh --plugin-only                   Codex plugin only"
      exit 0
      ;;
  esac
done

# --- plugin install ---
install_plugin() {
  local marketplace_dir="${TMT_MARKETPLACE_DIR:-$HOME/.agents/plugins}"
  # Codex resolves ./plugins/three-man-team in the personal marketplace to
  # $HOME/plugins/three-man-team, not relative to marketplace.json. Keep the
  # metadata directory and source root separate; both variables are injectable
  # so tests never write to a live marketplace or plugin source.
  local plugin_root="${TMT_PLUGIN_ROOT:-$HOME/plugins}"
  local plugin_dir="$plugin_root/three-man-team"
  local legacy_plugin_dir="$marketplace_dir/plugins/three-man-team"
  local staged_dir="$plugin_dir.staging-$$"
  local backup_dir=""
  local replacing=0
  local cachebuster=""
  local marketplace
  local marketplace_name

  echo ""
  echo "--- Codex Plugin ---"

  if [ -d "$legacy_plugin_dir" ] && [ "$legacy_plugin_dir" != "$plugin_dir" ]; then
    echo "  ⚠ Legacy plugin payload remains at $legacy_plugin_dir (not modified)."
    echo "    Codex uses $plugin_dir for ./plugins/three-man-team."
  fi
  [ -d "$plugin_dir" ] && replacing=1

  # A skill must be a directory below skills/, not a loose SKILL.md. Stage a
  # complete replacement before swapping it into place so a failed copy never
  # leaves the marketplace pointing at a half-built plugin.
  rm -rf "$staged_dir"
  mkdir -p "$staged_dir/.codex-plugin" "$staged_dir/skills/three-man-team"
  cp "$TPL/plugin/.codex-plugin/plugin.json" "$staged_dir/.codex-plugin/plugin.json"
  cp "$SCRIPT_DIR/SKILL.md" "$staged_dir/skills/three-man-team/SKILL.md"
  for source_dir in agents references releases scripts templates; do
    cp -R "$SCRIPT_DIR/$source_dir" "$staged_dir/skills/three-man-team/$source_dir"
  done

  # A replacement install receives a Codex build-metadata cachebuster before
  # `codex plugin add`, following the documented update/reinstall policy. New
  # installs keep the release version exactly; tests may supply a stable suffix.
  if [ "$replacing" = 1 ]; then
    cachebuster="${TMT_PLUGIN_CACHEBUSTER:-local-$(date -u +%Y%m%d-%H%M%S)}"
    if ! python3 - "$staged_dir/.codex-plugin/plugin.json" "$cachebuster" <<'PY'
import json
import sys

path, cachebuster = sys.argv[1:]
with open(path, encoding="utf-8") as handle:
    manifest = json.load(handle)
base_version = manifest["version"].split("+", 1)[0]
manifest["version"] = base_version + "+codex." + cachebuster
with open(path, "w", encoding="utf-8") as handle:
    json.dump(manifest, handle, indent=2)
    handle.write("\n")
PY
    then
      echo "  ✗ Could not apply plugin cachebuster during replacement staging"
      rm -rf "$staged_dir"
      return 1
    fi
  fi

  if [ -d "$plugin_dir" ]; then
    backup_dir="$plugin_dir.backup-$(date +%Y%m%d-%H%M%S)"
    mv "$plugin_dir" "$backup_dir" || {
      echo "  ✗ Could not back up existing plugin at $plugin_dir"
      rm -rf "$staged_dir"
      return 1
    }
  fi
  mv "$staged_dir" "$plugin_dir" || {
    echo "  ✗ Could not stage plugin at $plugin_dir"
    [ -n "$backup_dir" ] && mv "$backup_dir" "$plugin_dir"
    return 1
  }

  # Create or update marketplace entry
  mkdir -p "$marketplace_dir"
  marketplace="$marketplace_dir/marketplace.json"
  if ! python3 - "$marketplace" <<'PY'
import json
import os
import sys

path = sys.argv[1]
entry = {
    "name": "three-man-team",
    "source": {"source": "local", "path": "./plugins/three-man-team"},
    "policy": {"installation": "AVAILABLE", "authentication": "ON_INSTALL"},
    "category": "Productivity",
}
if os.path.exists(path):
    with open(path, encoding="utf-8") as handle:
        marketplace = json.load(handle)
else:
    marketplace = {"name": "personal", "interface": {"displayName": "Personal"}, "plugins": []}
marketplace.setdefault("interface", {}).setdefault("displayName", "Personal")
plugins = marketplace.setdefault("plugins", [])
for index, plugin in enumerate(plugins):
    if plugin.get("name") == "three-man-team":
        plugins[index] = entry
        break
else:
    plugins.append(entry)
with open(path, "w", encoding="utf-8") as handle:
    json.dump(marketplace, handle, indent=2)
    handle.write("\n")
print(marketplace["name"])
PY
  then
    echo "  ✗ Could not update marketplace entry at $marketplace"
    return 1
  fi
  marketplace_name="$(python3 - "$marketplace" <<'PY'
import json
import sys
with open(sys.argv[1], encoding="utf-8") as handle:
    print(json.load(handle)["name"])
PY
)" || return 1

  echo "  ✓ Staged plugin at $plugin_dir"
  [ "$replacing" = 1 ] && echo "  ✓ Applied plugin cachebuster: $cachebuster"
  echo "  ✓ Updated marketplace entry at $marketplace"
  if [ "${TMT_SKIP_PLUGIN_ADD:-0}" = "1" ]; then
    PLUGIN_STATUS="staged only (plugin add skipped by TMT_SKIP_PLUGIN_ADD=1)"
    echo "  ✓ Plugin staged; Codex install intentionally skipped for test mode"
    return 0
  fi

  if "${TMT_CODEX_BIN:-codex}" plugin add "three-man-team@$marketplace_name"; then
    PLUGIN_STATUS="installed"
    echo '  ✓ Plugin installed in Codex — use $three-man-team to trigger the skill'
  else
    PLUGIN_STATUS="staged but not installed"
    echo "  ✗ Codex plugin add failed; plugin was staged but is not installed."
    return 1
  fi
}

# --- project scaffolding ---
install_project() {
  local dest="$1"

  echo ""
  echo "--- Project Files ---"
  echo "Installing into: $dest"

  # AGENTS.md
  if [ -f "$dest/AGENTS.md" ]; then
    echo "  ✓ AGENTS.md already exists — not overwriting"
  else
    if [ -f "$TPL/project/AGENTS.md" ]; then
      cp "$TPL/project/AGENTS.md" "$dest/AGENTS.md"
    else
      cat > "$dest/AGENTS.md" << 'AGENTS_EOF'
# Three Man Team

This project uses the Three Man Team methodology for structured software development.

## Token Rules — Always Active

```
Is this in a skill or memory?   → Trust it. Skip the file read.
Is this speculative?            → Kill the tool call.
Can calls run in parallel?      → Parallelize them.
Output > 20 lines you won't use → Route to subagent.
About to restate what user said → Delete it.
```

## Team

| Role | Name | File |
|---|---|---|
| **Architect** | Arch | `ARCHITECT.md` |
| **Builder** | Bob | `BUILDER.md` |
| **Reviewer** | Richard | `REVIEWER.md` |

## Session Start (for Architect)

1. Load the Three Man Team skill if available.
2. Run `python3 <skill-dir>/scripts/check-version.py .`; walk listed bundled releases before acknowledging them.
3. Check `handoff/SESSION-CHECKPOINT.md` — if active and recent, read it.
4. If no checkpoint: read `handoff/BUILD-LOG.md` then `handoff/ARCHITECT-BRIEF.md`.
5. Read `ARCHITECT.md`.
6. Report status to the Product Owner in one paragraph.
AGENTS_EOF
    fi
    echo "  ✓ Created AGENTS.md"
  fi

  # Full role templates. Existing project-specific personas are never overwritten.
  for role in ARCHITECT BUILDER REVIEWER; do
    dest_file="$dest/${role}.md"
    if [ -f "$dest_file" ]; then
      echo "  ✓ ${role}.md already exists — not overwriting"
    else
      cp "$SCRIPT_DIR/references/role-templates/${role}.md" "$dest_file"
      echo "  ✓ Created ${role}.md (full framework template — customize if desired)"
    fi
  done

  # RULES.md quality contract (skeleton — never overwrites a drafted one)
  if [ -f "$dest/RULES.md" ]; then
    echo "  ✓ RULES.md already exists — not overwriting"
  else
    cp "$TPL/project/RULES.md" "$dest/RULES.md"
    echo "  ✓ Created RULES.md (Architect drafts the gate at first brief)"
  fi

  # scripts/check-handoff.sh — framework-owned, always refreshed, never skipped.
  # This one breaks the additive-only rule on purpose: RULES.md's Mechanical Gate
  # calls it by name, so a project carrying the gate row without a current copy of
  # the script has a gate command that fails on every step. It holds no project
  # content, so there is nothing to preserve. This is the manifest.md lesson of
  # v1.9.0 a second time — installing the file that calls a thing but not the thing.
  mkdir -p "$dest/scripts"
  cp "$TPL/project/scripts/check-handoff.sh" "$dest/scripts/check-handoff.sh"
  chmod +x "$dest/scripts/check-handoff.sh"
  echo "  ✓ Installed scripts/check-handoff.sh (framework-owned — refreshed every run)"

  # manifest.md — version marker the skill's version check reads.
  # Stamped from the bundled registry, never from the template's own text: a
  # hardcoded version in the template drifts silently every release (it sat at
  # v1.5.0 through four of them, unnoticed, because nothing installed it).
  if [ -f "$dest/manifest.md" ]; then
    echo "  ✓ manifest.md already exists — not overwriting"
  else
    ver="$(grep -o '"latest": *"[^"]*"' "$SCRIPT_DIR/releases/latest.json" 2>/dev/null | cut -d'"' -f4)"
    if [ -z "$ver" ]; then
      echo "  ✗ could not read a version from $SCRIPT_DIR/releases/latest.json — manifest.md not created"
      echo "    (the skill's version check needs it; re-run once the bundled registry is readable)"
    else
      sed "s/^version:.*/version: $ver/; s/^installed:.*/installed: $(date +%Y-%m-%d)/" \
        "$TPL/project/manifest.md" > "$dest/manifest.md"
      echo "  ✓ Created manifest.md ($ver)"
    fi
  fi

  # Handoff templates — the structured ones, not bare stubs. scripts/check-handoff.sh
  # asserts these files carry their sections (Decisions, Out of Scope, Flags, a
  # Definition of Done with a runnable command), so a two-line stub gives the
  # Architect nothing to fill in and the check nothing to find.
  mkdir -p "$dest/handoff"
  for hf in ARCHITECT-BRIEF.md BUILD-LOG.md REVIEW-REQUEST.md REVIEW-FEEDBACK.md SESSION-CHECKPOINT.md; do
    if [ -f "$dest/handoff/$hf" ]; then
      echo "  ✓ handoff/$hf already exists — not overwriting"
    elif [ -f "$TPL/project/handoff/$hf" ]; then
      cp "$TPL/project/handoff/$hf" "$dest/handoff/$hf"
      echo "  ✓ Created handoff/$hf"
    else
      echo "# $hf" > "$dest/handoff/$hf"
      echo "*Three Man Team handoff file.*" >> "$dest/handoff/$hf"
      cat >> "$dest/handoff/$hf" << 'EOF'

---
EOF
      echo "  ✓ Created handoff/$hf (stub — template missing from the bundle)"
    fi
  done

  # .gitignore
  if [ -f "$dest/.gitignore" ]; then
    if ! grep -q "handoff/BUILD-LOG.md" "$dest/.gitignore" 2>/dev/null; then
      cat >> "$dest/.gitignore" << 'EOF'

# Three Man Team handoff files
handoff/BUILD-LOG.md
handoff/SESSION-CHECKPOINT.md
EOF
      echo "  ✓ Updated .gitignore"
    else
      echo "  ✓ .gitignore already has TMT entries"
    fi
  else
    cat > "$dest/.gitignore" << 'EOF'
# Three Man Team handoff files
handoff/BUILD-LOG.md
handoff/SESSION-CHECKPOINT.md
EOF
    echo "  ✓ Created .gitignore"
  fi
}

# --- main ---
echo ""
echo "========================================="
echo "  Three Man Team — Setup"
echo "========================================="
echo ""

case "$MODE" in
  plugin-only)
    install_plugin || exit 1
    ;;
  both)
    if [ -z "$DEST" ] || [ "$DEST" = "--plugin" ]; then
      echo "✗ Project directory required when using --plugin"
      echo "  Usage: ./setup-project.sh /path/to/project --plugin"
      exit 1
    fi
    DEST="$(cd "$DEST" 2>/dev/null && pwd)" || { echo "✗ Project folder not found: $DEST"; exit 1; }
    install_project "$DEST"
    install_plugin || exit 1
    ;;
  project)
    if [ -z "$DEST" ] || [ "${DEST:0:1}" = "-" ]; then
      echo "✗ Project directory required"
      echo "  Usage: ./setup-project.sh /path/to/your/project"
      echo "  Or:    ./setup-project.sh /path/to/your/project --plugin"
      echo "  Or:    ./setup-project.sh --plugin-only"
      exit 1
    fi
    DEST="$(cd "$DEST" 2>/dev/null && pwd)" || { echo "✗ Project folder not found: $DEST"; exit 1; }
    install_project "$DEST"
    ;;
esac

echo ""
echo "========================================="
echo "  Setup complete!"
echo ""
if [ "$MODE" = "project" ] || [ "$MODE" = "both" ]; then
  echo "  Project files in: $DEST"
  echo "    - AGENTS.md (session router)"
  echo "    - ARCHITECT.md, BUILDER.md, REVIEWER.md (full role templates)"
  echo "    - handoff/ (brief, review, build-log, checkpoint)"
  echo ""
fi
if [ "$MODE" = "plugin-only" ] || [ "$MODE" = "both" ]; then
  echo "  Codex plugin: $PLUGIN_STATUS"
fi
echo ""
echo "  Next steps:"
echo "    1. Review the role files and customize team names/personas if needed"
echo "    2. Start a Codex session and invoke the Three Man Team skill"
echo "========================================="
echo ""
