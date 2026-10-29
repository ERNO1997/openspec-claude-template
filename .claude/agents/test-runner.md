---
name: test-runner
description: Runs the test suite and returns only a summary of the failures. Use it after finishing a task group.
tools: Bash, Read
model: haiku
---
Run `npm test` (replace the command with your project's).
Return: how many tests pass and how many fail and, for each failure, the file, the test name and
the error message (at most 10 lines per failure). Do not try to fix anything.
