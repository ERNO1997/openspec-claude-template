# openspec-claude-template

A template for working with OpenSpec and Claude Code on the Claude Pro plan while spending as little
of the weekly quota as possible. It gathers the per-project configuration that OpenSpec does not share
between projects (`context`, `rules`, `operations`) and the Claude Code settings that save quota.

Status: checked against the documentation on 29 October 2026 (Claude Code v2.1.284 or later).
What is untested is listed at the end.

## What is included

```
openspec/config.yaml          context, rules and operations
.claude/settings.json         default model (Sonnet), subagents on Haiku, QA hook
.claude/hooks/run-tests.sh    QA outside the LLM (active with RUN_QA=1)
.claude/agents/test-runner.md subagent that runs the tests and summarizes failures
explore/_TEMPLATE/notes.md    handoff note between Explore and Propose
bin/opsx:archive <name>       `openspec archive <name> -y` + moves explore/<name> to explore/archive/
bin/opsx:archive-explore <name>  only moves explore/<name> to explore/archive/
read-before-delete.md         disposable audit briefing for existing projects (see below)
kickoff.md                    disposable kickoff briefing for new projects (see below)
new-project.sh                creates a new project: git init, template, openspec init, context, kickoff.md
make-boilerplate.sh           exports a clean boilerplate for a GitHub template repository
claude-user-settings.example.json  per-account settings (model, effort) to merge into each config dir
install.sh                    copies everything into a project without overwriting files
CHECKLIST.md                  steps per machine, per project and per change
```

## Start a new project

```bash
/path/to/openspec-claude-template/new-project.sh ~/code/my-app \
  --about "What it is, in one line" --stack "TS, Next.js, Postgres" --test "npm test"
cd ~/code/my-app
claude --model opus --effort medium
> Read kickoff.md and follow it.
```

`new-project.sh` needs an empty or missing folder. It runs `git init`, installs the template, runs
`openspec init --tools claude` (which keeps the template's `config.yaml`, so there is nothing to merge),
fills `context` and `TEST_CMD` with the values you pass (it asks for missing ones; Enter leaves `TODO`)
and copies `kickoff.md`. It does not commit.

`kickoff.md` is a briefing for an Opus session. The agent interviews you (goal, v1 scope, out of scope,
stack, tests, constraints), finishes `context` and `TEST_CMD`, writes `explore/kickoff/notes.md` with the
first changes in order (always starting with `project-skeleton`), writes no code, and deletes itself.
Then the normal flow starts with `/opsx:propose project-skeleton` in a new session.

### From a GitHub template repository

This repository stays the source (install, audit, docs). The boilerplate for new projects lives in its
own repository, generated from this one:

```bash
./make-boilerplate.sh ../openspec-claude-boilerplate   # overwrites only the files it manages
cd ../openspec-claude-boilerplate && git init && git add -A && git commit -m "Boilerplate"
gh repo create openspec-claude-boilerplate --private --source . --push
gh repo edit --template
```

New projects then use "Use this template" (or `gh repo create my-app --template <owner>/openspec-claude-boilerplate --clone`),
followed by `openspec init --tools claude` and the kickoff. When you change the template here, run
`make-boilerplate.sh` again on the same folder, review the diff and push.

## Install into a project

```bash
cd my-project
openspec init --tools claude
/path/to/openspec-claude-template/install.sh .
```

If a file already exists, the script leaves the template version next to it with a `.template` suffix
so you can merge it by hand (this happens with `openspec/config.yaml`, which `openspec init` already creates).
Then edit `context` and the test command (`TEST_CMD` in the hook).

## Audit an existing project

`read-before-delete.md` is a briefing for a Sonnet session. It summarizes this template's decisions and
tells the agent how to audit a project that is already started: model pinning, always-loaded context,
MCP servers and plugins, OpenSpec leftovers, large files, hooks. The agent reads cheaply, reports findings
with evidence, and changes nothing until you approve. When you are done, it deletes the file.

```bash
cd your-existing-project
/path/to/openspec-claude-template/install.sh . --with-audit   # or just copy read-before-delete.md
claude --model sonnet --effort medium
> Read read-before-delete.md and follow it.
```

## Workflow

| Phase | Model and effort | Session | Leaves behind |
|---|---|---|---|
| Explore | Sonnet 5.5, `low` or `medium` (Opus 5.5 only for hard architecture decisions) | its own | prototypes in `explore/<topic>/` and `notes.md` |
| Propose | Opus 5.5, `medium` (`high` with many dependencies) | new | `openspec/changes/<n>/` with proposal, specs, design and tasks |
| Apply | Sonnet 5.5, `medium` (`high` for bugs) | short, `/clear` every 3 to 5 tasks | code and ticked checkboxes |
| Archive | `openspec archive <n> -y`, no LLM | any | updated main specs |

Rules for saving quota:

1. On Pro, `default` resolves to Opus 5.5. Pin the model (this template sets Sonnet in `.claude/settings.json`).
2. Within a session, change the effort, not the model: on Opus 5.5, Sonnet 5.5, Haiku 5.5 and Fable 5.1,
   changing effort keeps the cache; `/model` and `opusplan` break it.
3. Hand off between phases with `notes.md`, not with the conversation.
4. Keep mechanical work outside the LLM: `openspec validate --strict`, the tests, the hook, `openspec archive`.
5. Do not put prototypes in `context`: it is injected on every generation.
6. Avoid `ultracode` and subagents other than `test-runner`.

## If Apply goes off track

The Apply skill pauses when a task is unclear, there is an error, or the implementation reveals a
design problem; it then suggests updating the artifacts. Nothing enforces this. The path:
a new session with Opus updates `design.md`, the specs and `tasks.md` of the same change, then
`openspec validate <n> --strict`, and Apply resumes from the first unticked checkbox.

## Where each setting lives

| Scope | OpenSpec | Claude Code |
|---|---|---|
| Your machine | `openspec config` (profile, delivery, workflows) | `${CLAUDE_CONFIG_DIR:-~/.claude}/settings.json`, `${CLAUDE_CONFIG_DIR:-~/.claude}/agents/` |
| One project | `openspec/config.yaml` (context, rules, operations) | `.claude/settings.json`, `.claude/hooks/`, `.claude/agents/` |
| One change | `openspec/changes/<n>/` | the session: `--model`, `--effort`, `/clear` |

`context`, `rules` and `operations` do not exist at the global level; that is why this template exists.

## Untested

- How much cache tokens count toward the weekly limit on Pro (Anthropic does not publish figures).
- The `RUN_QA=1` guard in the hook and how it behaves with `Stop` in your version.
- Whether `/opsx:*` commands work with `claude -p`.
- Whether keeping prototypes inside `openspec/changes/<n>/` passes `validate` and `archive`.
- Whether `/opsx:archive` and `openspec archive -y` leave the same specs.
- Whether Sonnet matches Opus when redesigning interfaces: try it on a real screen.
- Whether your `core` profile includes `sync` and `update`: `openspec config list`.
