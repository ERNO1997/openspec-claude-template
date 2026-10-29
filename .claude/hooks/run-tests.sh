#!/bin/bash
# QA outside the LLM: runs the tests when Claude finishes responding.
# - Only acts if you launched Claude Code with RUN_QA=1 (for example, only during Apply).
# - If the tests fail, it hands the last lines back to Claude (exit 2) so it can fix them.
# Requires `jq`. Set TEST_CMD to your project's real test command.

TEST_CMD="${TEST_CMD:-npm test}"

INPUT=$(cat)

# Prevent an infinite loop: if Claude is already retrying after a previous Stop, let it through.
if [ "$(echo "$INPUT" | jq -r '.stop_hook_active')" = "true" ]; then
  exit 0
fi

# Only with RUN_QA=1
[ "$RUN_QA" = "1" ] || exit 0

if ! OUTPUT=$(bash -c "$TEST_CMD" 2>&1); then
  echo "Tests failing:" >&2
  echo "$OUTPUT" | tail -n 40 >&2
  exit 2
fi
exit 0
