#!/usr/bin/env bash
# Starts a new project from scratch with this template:
#   git init  ->  install.sh  ->  openspec init --tools claude  ->  fill in context and TEST_CMD
#   ->  copy kickoff.md (disposable briefing for the first Claude session)
# It does not commit anything. No LLM involved.
#
# Usage: ./new-project.sh <path> [--about "what it is"] [--stack "TS, Next.js, Postgres"] [--test "npm test"]
# Values you leave out are asked for (if running in a terminal) or left as TODO for kickoff.md to fill in.
set -euo pipefail

usage() {
  echo "Usage: ./new-project.sh <path> [--about \"...\"] [--stack \"...\"] [--test \"...\"]" >&2
  exit 1
}

TARGET="${1:-}"
[ -n "$TARGET" ] || usage
case "$TARGET" in -*) usage ;; esac
shift

ABOUT="" STACK="" TEST=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --about) ABOUT="${2:?--about needs a value}"; shift 2 ;;
    --stack) STACK="${2:?--stack needs a value}"; shift 2 ;;
    --test)  TEST="${2:?--test needs a value}";  shift 2 ;;
    *) usage ;;
  esac
done

for tool in git openspec; do
  command -v "$tool" >/dev/null 2>&1 || { echo "! '$tool' is not installed." >&2; exit 1; }
done

# Only an empty (or missing) folder: for existing projects use install.sh --with-audit.
if [ -e "$TARGET" ] && [ -n "$(ls -A "$TARGET" 2>/dev/null)" ]; then
  echo "! $TARGET is not empty. For an existing project use: ./install.sh $TARGET --with-audit" >&2
  exit 1
fi

if [ -t 0 ]; then
  [ -n "$ABOUT" ] || read -r -p "What is it (1-2 lines, Enter to leave TODO): " ABOUT
  [ -n "$STACK" ] || read -r -p "Stack (Enter to leave TODO): " STACK
  [ -n "$TEST" ]  || read -r -p "Test command (Enter to leave TODO): " TEST
fi

HERE="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$TARGET"
TARGET="$(cd "$TARGET" && pwd)"

git -C "$TARGET" init -q
echo "+ git init (no commit)"

"$HERE/install.sh" "$TARGET" >/dev/null
echo "+ template installed"

# Runs after install.sh on purpose: openspec init keeps an existing openspec/config.yaml.
if ! LOG=$(cd "$TARGET" && openspec init --tools claude --no-animation </dev/null 2>&1); then
  echo "$LOG" >&2
  exit 1
fi
echo "+ openspec init --tools claude"

cp -p "$HERE/kickoff.md" "$TARGET/kickoff.md"
echo "+ copied: kickoff.md"

# Replaces the line that starts with PREFIX (after indentation) by NEW, keeping the indentation.
# awk with ENVIRON avoids sed escaping problems with arbitrary values.
replace_line() {
  local file="$1"
  PREFIX="$2" NEW="$3" awk '
    !done && index($0, ENVIRON["PREFIX"]) {
      match($0, /^[ \t]*/)
      if (substr($0, RLENGTH + 1, length(ENVIRON["PREFIX"])) == ENVIRON["PREFIX"]) {
        print substr($0, 1, RLENGTH) ENVIRON["NEW"]; done = 1; next
      }
    }
    { print }
  ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
}

CONFIG="$TARGET/openspec/config.yaml"
HOOK="$TARGET/.claude/hooks/run-tests.sh"

[ -z "$ABOUT" ] || replace_line "$CONFIG" "Project:" "Project: $ABOUT"
[ -z "$STACK" ] || replace_line "$CONFIG" "Stack:" "Stack: $STACK"
if [ -n "$TEST" ]; then
  replace_line "$CONFIG" "Tests:" "Tests: run with \`$TEST\`   # keep it the same as TEST_CMD in .claude/hooks/run-tests.sh"
  # Escape for a double-quoted bash string.
  ESCAPED=$(printf '%s' "$TEST" | sed -e 's/[\\"$`]/\\&/g')
  replace_line "$HOOK" 'TEST_CMD=' "TEST_CMD=\"\${TEST_CMD:-$ESCAPED}\""
  chmod +x "$HOOK"
fi

echo
echo "Done: $TARGET (nothing committed)."
echo "Next:"
echo "  cd $TARGET"
echo "  claude --model opus --effort medium"
echo "  > Read kickoff.md and follow it."
grep -q 'TODO' "$CONFIG" && echo "  (openspec/config.yaml still has TODOs: kickoff.md fills them in with you.)"
exit 0
