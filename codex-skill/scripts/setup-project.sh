#!/bin/bash
# Three Man Team — Codex project setup
# Scaffolds handoff templates, role file stubs, AGENTS.md into a project directory,
# and optionally registers the @three-man-team Codex plugin.
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
  local marketplace_dir="$HOME/.agents/plugins"
  local plugin_dir="$marketplace_dir/plugins/three-man-team"

  echo ""
  echo "--- Codex Plugin ---"

  # Create directory structure
  mkdir -p "$plugin_dir/.codex-plugin"
  mkdir -p "$plugin_dir/skills"

  # Copy plugin manifest and app definition
  cp "$TPL/plugin/.codex-plugin/plugin.json" "$plugin_dir/.codex-plugin/plugin.json"
  cp "$TPL/plugin/.app.json" "$plugin_dir/.app.json"

  # Copy the full skill contents into the plugin's skills/ directory
  cp -R "$SCRIPT_DIR/SKILL.md" "$plugin_dir/skills/"
  cp -R "$SCRIPT_DIR/agents" "$plugin_dir/skills/" 2>/dev/null
  cp -R "$SCRIPT_DIR/references" "$plugin_dir/skills/" 2>/dev/null
  cp -R "$SCRIPT_DIR/releases" "$plugin_dir/skills/" 2>/dev/null
  cp -R "$SCRIPT_DIR/scripts" "$plugin_dir/skills/" 2>/dev/null
  cp -R "$SCRIPT_DIR/templates" "$plugin_dir/skills/" 2>/dev/null

  # Create or update marketplace entry
  mkdir -p "$marketplace_dir"
  local marketplace="$marketplace_dir/marketplace.json"

  if [ -f "$marketplace" ]; then
    # Update existing entry or append
    python3 -c "
import json, sys
path = '$marketplace'
with open(path) as f:
    d = json.load(f)
entry = {
    'name': 'three-man-team',
    'source': {'source': 'local', 'path': './plugins/three-man-team'},
    'policy': {'installation': 'AVAILABLE', 'authentication': 'ON_INSTALL'},
    'category': 'Productivity'
}
plugins = d.get('plugins', [])
existing = [i for i, p in enumerate(plugins) if p.get('name') == 'three-man-team']
if existing:
    plugins[existing[0]] = entry
else:
    plugins.append(entry)
d['plugins'] = plugins
with open(path, 'w') as f:
    json.dump(d, f, indent=2)
print('✓ Updated marketplace entry')
" 2>/dev/null || echo "  ⚠ Could not update marketplace entry"
  else
    cat > "$marketplace" << 'MARKETPLACE_EOF'
{
  "name": "personal",
  "interface": {
    "displayName": "Personal"
  },
  "plugins": [
    {
      "name": "three-man-team",
      "source": {
        "source": "local",
        "path": "./plugins/three-man-team"
      },
      "policy": {
        "installation": "AVAILABLE",
        "authentication": "ON_INSTALL"
      },
      "category": "Productivity"
    }
  ]
}
MARKETPLACE_EOF
    echo "  ✓ Created marketplace at $marketplace"
  fi

  echo "  ✓ Plugin installed at $plugin_dir"
  echo "  ✓ Use @three-man-team in Codex CLI to trigger the skill"
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
2. Check `handoff/SESSION-CHECKPOINT.md` — if active and recent, read it.
3. If no checkpoint: read `handoff/BUILD-LOG.md` then `handoff/ARCHITECT-BRIEF.md`.
4. Read `ARCHITECT.md`.
5. Report status to the Product Owner in one paragraph.
AGENTS_EOF
    fi
    echo "  ✓ Created AGENTS.md"
  fi

  # Role stubs
  for role in ARCHITECT BUILDER REVIEWER; do
    dest_file="$dest/${role}.md"
    if [ -f "$dest_file" ]; then
      echo "  ✓ ${role}.md already exists — not overwriting"
    else
      cat > "$dest_file" << ROLEEOF
# ${role} — Three Man Team
*Customize: replace with the role's name and persona. See references/role-templates/${role}.md for the full template.*

## Session Start
1. Read handoff files as described in AGENTS.md.

## Role
[Describe who this agent is and their responsibilities.]
ROLEEOF
      echo "  ✓ Created ${role}.md (stub — customize the persona)"
    fi
  done

  # RULES.md quality contract (skeleton — never overwrites a drafted one)
  if [ -f "$dest/RULES.md" ]; then
    echo "  ✓ RULES.md already exists — not overwriting"
  else
    cp "$TPL/project/RULES.md" "$dest/RULES.md"
    echo "  ✓ Created RULES.md (Architect drafts the gate at first brief)"
  fi

  # Handoff templates
  mkdir -p "$dest/handoff"
  for hf in ARCHITECT-BRIEF.md BUILD-LOG.md REVIEW-REQUEST.md REVIEW-FEEDBACK.md SESSION-CHECKPOINT.md; do
    if [ -f "$dest/handoff/$hf" ]; then
      echo "  ✓ handoff/$hf already exists — not overwriting"
    else
      echo "# $hf" > "$dest/handoff/$hf"
      echo "*Three Man Team handoff file.*" >> "$dest/handoff/$hf"
      cat >> "$dest/handoff/$hf" << 'EOF'

---
EOF
      echo "  ✓ Created handoff/$hf"
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
    install_plugin
    ;;
  both)
    if [ -z "$DEST" ] || [ "$DEST" = "--plugin" ]; then
      echo "✗ Project directory required when using --plugin"
      echo "  Usage: ./setup-project.sh /path/to/project --plugin"
      exit 1
    fi
    DEST="$(cd "$DEST" 2>/dev/null && pwd)" || { echo "✗ Project folder not found: $DEST"; exit 1; }
    install_project "$DEST"
    install_plugin
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
  echo "    - ARCHITECT.md, BUILDER.md, REVIEWER.md (role stubs)"
  echo "    - handoff/ (brief, review, build-log, checkpoint)"
  echo ""
fi
if [ "$MODE" = "plugin-only" ] || [ "$MODE" = "both" ]; then
  echo "  Codex plugin installed — use @three-man-team in Codex CLI"
fi
echo ""
echo "  Next steps:"
echo "    1. Customize the role files with your team's names and personas"
echo "    2. Start a Codex session and type @three-man-team"
echo "========================================="
echo ""
