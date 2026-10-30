#!/usr/bin/env bash
# Copies the template into a project without overwriting anything.
# If a file already exists in the target, the template version is left next to it with a
# ".template" suffix so you can merge it by hand (for example openspec/config.yaml,
# which `openspec init` already creates).
#
# Usage: ./install.sh /path/to/project [--with-audit]
set -euo pipefail

TARGET="${1:-}"
if [ -z "$TARGET" ] || [ ! -d "$TARGET" ]; then
  echo "Usage: ./install.sh /path/to/project [--with-audit]" >&2
  exit 1
fi

HERE="$(cd "$(dirname "$0")" && pwd)"

copy() {
  local rel="$1"
  local dest="$TARGET/$rel"
  if [ -e "$dest" ]; then
    dest="$dest.template"
    echo "= already exists, leaving the template at: $rel.template"
  else
    echo "+ copied: $rel"
  fi
  mkdir -p "$(dirname "$dest")"
  cp -p "$HERE/$rel" "$dest"
}

copy openspec/config.yaml
copy .claude/settings.json
copy .claude/hooks/run-tests.sh
copy .claude/agents/test-runner.md
copy explore/_TEMPLATE/notes.md

# Optional audit briefing for existing projects. Pass --with-audit to include it.
if [ "${2:-}" = "--with-audit" ]; then
  copy read-before-delete.md
fi

chmod +x "$TARGET/.claude/hooks/run-tests.sh" 2>/dev/null || true
[ -f "$TARGET/.claude/hooks/run-tests.sh.template" ] && chmod +x "$TARGET/.claude/hooks/run-tests.sh.template" || true

if ! command -v jq >/dev/null 2>&1; then
  echo "! 'jq' is missing (the QA hook uses it). Install it before using RUN_QA=1." >&2
fi

if [ -f "$TARGET/.gitignore" ]; then
  grep -qx '.claude/settings.local.json' "$TARGET/.gitignore" || echo '.claude/settings.local.json' >> "$TARGET/.gitignore"
else
  cp "$HERE/.gitignore" "$TARGET/.gitignore"
fi

if [ -f "$TARGET/.claude/settings.json.template" ]; then
  echo
  echo "! .claude/settings.json already existed. To preview a merge (your values win), run:"
  echo "    jq -s '.[0] * .[1]' $TARGET/.claude/settings.json.template $TARGET/.claude/settings.json"
  echo "  Arrays (such as hooks.Stop) are replaced by yours, so add the template's Stop hook by hand if missing."
fi

echo
echo "Done. Next steps:"
echo "  1. Edit 'context' in openspec/config.yaml and the test command (TEST_CMD) in the hook."
echo "  2. Reopen Claude Code in the project and check the hook with /hooks."
echo "  3. Merge each *.template file by hand, then delete it."
echo "  4. Per Claude account (each CLAUDE_CONFIG_DIR): see claude-user-settings.example.json."
