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
install.sh                    copies everything into a project without overwriting files
CHECKLIST.md                  steps per machine, per project and per change
```

## Install into a project

```bash
cd my-project
openspec init --tools claude
/path/to/openspec-claude-template/install.sh .
```

If a file already exists, the script leaves the template version next to it with a `.template` suffix
so you can merge it by hand (this happens with `openspec/config.yaml`, which `openspec init` already creates).
Then edit `context` and the test command (`TEST_CMD` in the hook).

To create new projects from GitHub, mark this repository as a "Template repository" in its
settings and use "Use this template".

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
| Your machine | `openspec config` (profile, delivery, workflows) | `~/.claude/settings.json`, `~/.claude/agents/` |
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
