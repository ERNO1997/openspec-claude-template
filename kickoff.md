<!--
FOR THE HUMAN
Purpose: hand this file to an Opus session to define a NEW project (goal, scope, stack, test command)
before the first OpenSpec change. It writes configuration and notes, not code. It is disposable:
the agent deletes it at the end.

  cd your-new-project            # created with new-project.sh, or from the boilerplate repository
  claude --model opus --effort medium
  > Read kickoff.md and follow it.

For an EXISTING project use read-before-delete.md (the audit) instead.
-->

# Project kickoff (writes config and notes only, no code)

You are starting a **new** project that will be built with OpenSpec and Claude Code on the
**Claude Pro** plan. The owner has a strict weekly quota. Your job is to turn the owner's idea into:

1. a short `context` in `openspec/config.yaml` and the real test command in `.claude/hooks/run-tests.sh`,
2. a handoff note at `explore/kickoff/notes.md` with the first OpenSpec changes, in order.

Then you stop. The first change is proposed in a **new** session.

## Rules

1. **No code.** Do not scaffold, install dependencies, create source folders or run `/opsx:*` commands.
   The project skeleton is the first OpenSpec change, not part of this kickoff.
2. **Be cheap.** Ask questions in batches (at most 5 per batch, at most 3 batches). Keep your replies short.
   Do not research libraries on the web unless the owner asks.
3. **Owner decides.** When the owner has no preference (for example, the stack), recommend one option with
   one line of reasoning and one alternative. Do not write a comparison essay.
4. **Show before writing.** Show each file's proposed content (or diff) and write it only after the owner approves.
5. **Do not create `CLAUDE.md`** or other always-loaded files. `context` in `openspec/config.yaml` already reaches
   every OpenSpec artifact. If the owner wants a `CLAUDE.md` anyway, keep it under 20 lines.

## Step 0: check the setup (no questions yet)

Run these and report in 2-3 lines:

```bash
ls -a; ls .claude .claude/commands/opsx openspec 2>&1 | head -30
grep -n 'TODO\|Tests:' openspec/config.yaml; grep -n '^TEST_CMD=' .claude/hooks/run-tests.sh
git status --short | head; claude --version; openspec --version
```

- If `.claude/commands/opsx/` is missing, ask the owner to run `openspec init --tools claude`
  (it keeps the existing `openspec/config.yaml`) and wait.
- If `.claude/hooks/run-tests.sh` is not executable, propose `chmod +x .claude/hooks/run-tests.sh`.
- Values that are already filled in (no `TODO`) came from `new-project.sh`: confirm them, do not ask again.

## Step 1: interview

Cover these, skipping what is already known:

- **Goal**: what it is, for whom, and the one thing v1 must do well.
- **v1 scope**: 3-6 capabilities. **Out of scope** for v1, explicitly.
- **Stack**: language, framework, database, hosting or runtime target. Package manager.
- **Tests**: framework and the exact command that runs them (it must exit non-zero on failure).
- **Constraints**: sensitive files or folders ("do not touch"), secrets handling, platforms, performance or legal limits.
- **Artifact language**: English unless the owner wants another one.

## Step 2: write the configuration

- `openspec/config.yaml`, `context` block only: replace the `TODO`s. Target 6-12 lines.
  Include only what an agent cannot infer from the code: purpose, stack, test command, constraints, language.
  **No feature lists or roadmaps**: they belong in specs and in the notes, and `context` is paid on every generation.
  Keep the `Prototypes and exploration notes` line. Do not change `rules` or `operations` unless the owner asks.
- `.claude/hooks/run-tests.sh`: set the default in `TEST_CMD="${TEST_CMD:-...}"` to the same command as in `context`.
  Until the skeleton change exists, that command fails; that is expected (the hook only runs with `RUN_QA=1`).

## Step 3: write `explore/kickoff/notes.md`

Follow the shape of `explore/_TEMPLATE/notes.md` (stay within about 25 lines):

- **Decision**: what the project is and the chosen stack, in 2-3 sentences.
- **Discarded alternatives**: stack options considered and why not.
- **Open questions**: what is still undecided, and in which change it should be decided.
- **Planned changes**, in order, each with a kebab-case name and one sentence:
  1. `project-skeleton`: minimal app structure, tooling, `.gitignore` entries for the stack and a passing test
     run by the exact test command (so the QA hook works from the second change on).
  2. 2-4 more changes, each a thin vertical slice of a v1 capability, smallest first.
- **Next step**: `/opsx:propose project-skeleton` in a new session, reading this file.

## Step 4: finish

1. List the files you wrote and anything still `TODO`.
2. Tell the owner the next commands:
   ```
   /clear   (or a new session)
   claude --model opus --effort medium
   > /opsx:propose project-skeleton   (read explore/kickoff/notes.md first)
   ```
   Then Apply with `RUN_QA=1 claude --model sonnet --effort medium` and `/opsx:apply project-skeleton`.
3. Remind them that nothing is committed: suggest reviewing `git status` and making the first commit themselves.
4. When the owner confirms the kickoff is done, **delete this file** (`kickoff.md`) and say so.
