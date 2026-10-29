<!--
FOR THE HUMAN
Purpose: hand this file to a Sonnet session so it audits an EXISTING project and proposes changes that
save Claude Pro quota. It is disposable: delete it when the audit is done.

  cd your-existing-project
  cp /path/to/openspec-claude-template/read-before-delete.md .
  claude --model sonnet --effort medium
  > Read read-before-delete.md and follow it.

Tip: start the session in a clean state (no long history) so the audit itself is cheap.
-->

# Project audit for token savings (read-only until approved)

You are auditing an existing project that uses (or will use) OpenSpec with Claude Code on the
**Claude Pro** plan. The owner has a strict weekly quota. Your job is to find what in this project
wastes tokens and to propose concrete fixes. You change nothing until the owner approves.

## Rules for this audit

1. **Read-only first.** Do not edit, move, install or delete anything before the owner approves a specific proposal.
2. **Be cheap yourself.** Do not read the whole repo. Use `ls`, `wc -c`, `wc -l`, `head -n 40`, `grep -c` and
   `git ls-files | head`. Open a file in full only if it is a configuration or instruction file listed below.
3. **Evidence over opinion.** Every finding cites a path and a measured size or line count. If you could not
   measure something, say so instead of guessing.
4. **Facts below may be stale.** They were checked against the docs on 2026-10-29. If something you observe
   contradicts them, report the contradiction and trust the observation. Run `claude --version` and `openspec --version` first.
5. **Do not run the project's tests, builds or installs.** They cost time and tokens and are not needed here.
6. **Never overwrite the owner's files.** Propose merges; where the template ships a file that already exists, the owner merges by hand.

## Background you need (the owner's decisions so far)

### The workflow
OpenSpec core commands: `/opsx:explore`, `/opsx:propose`, `/opsx:apply`, `/opsx:archive` (the `core` profile may also
include `sync` and `update`; check with `openspec config list`).

| Phase | Model and effort | Session | Notes |
|---|---|---|---|
| Explore | Sonnet 5.5, `low` or `medium`; Opus 5.5 only for hard architecture decisions | its own | Explore writes no files by itself; prototypes go in `explore/<topic>/`, plus a 10-20 line `notes.md` handoff |
| Propose | Opus 5.5, `medium` (`high` with many dependencies) | new session | The design is frozen here; a mistake is inherited by everything after |
| Apply | Sonnet 5.5, `medium` (`high` for bugs) | short; `/clear` every 3-5 tasks | Tasks must be self-contained; state lives in `tasks.md` checkboxes |
| Archive | `openspec archive <name> -y`, no LLM | any | `/opsx:archive` does the same through an LLM and asks whether to sync |

Mechanical work stays outside the LLM: `openspec validate <name> --strict`, tests (hook), `openspec archive`.
If Apply discovers the design is wrong, it should stop; a new Opus session updates design, specs and tasks of the same change, then Apply resumes.

### Quota and model facts (Claude Code docs, checked 2026-10-29)
- On Pro, the `default` model resolves to **Opus 5.5** (before Claude Code v2.1.280 it was Sonnet 5). An unpinned project burns quota on the expensive model.
- Pro has one weekly limit shared across all models and with claude.ai chat. Exact figures are not published.
- Effort levels: `low`, `medium`, `high`, `xhigh`, `max`. Opus 5.5, Sonnet 5.5 and Haiku 5.5 default to `medium`. `max` tends to overthink. `ultracode` orchestrates multi-agent workflows and is the opposite of saving.
- Fable 5.1 may bill as usage credits instead of plan limits.
- Each model has its own prompt cache. `/model` and `opusplan` plan-mode toggles force a full uncached re-read. Changing effort keeps the cache on Opus 5.5, Sonnet 5.5, Haiku 5.5 and Fable 5.1 with a subscription.
- Cache actions that break it: connecting or removing MCP servers or plugins when tools load up front, upgrading Claude Code, resuming a long session after the cache expired (the main conversation gets a 1-hour TTL on a subscription within plan usage).
- Editing `CLAUDE.md` mid-session neither breaks the cache nor applies until `/clear`, `/compact` or restart.
- Many accumulated images in a session force reprocessing when the oldest are dropped.
- Subagents inherit the main session's model unless `model` is set in their frontmatter or `CLAUDE_CODE_SUBAGENT_MODEL` is set.
- The window for Sonnet 5.5 and Opus 5.5 is 1M tokens by default; `/autocompact 200k` makes sessions compact earlier.

### OpenSpec configuration facts
- `openspec/config.yaml` is per project: `schema`, `context` (injected into every artifact, max 50 KB), `rules` (keyed by artifact id: `proposal`, `specs`, `design`, `tasks`; apply only to that artifact), `operations.apply.guidance` / `operations.archive.guidance` (advisory only).
- `openspec config` is per machine and only controls `profile`, `delivery`, `workflows`.
- Legacy layouts exist: `openspec/project.md` and `openspec/AGENTS.md` and `/openspec:proposal`-style commands belong to the older workflow; the new one uses `config.yaml` and `/opsx:*`. Old and new side by side means duplicated instructions.
- Progress counts `- [ ]` / `- [x]` checkboxes only; a task list written as plain bullets reads as zero tasks.
- Specs are synced into `openspec/specs/` at archive time (or with `/opsx:sync`), so active changes legitimately show unsynced specs.
- Do not create change folders by hand; `openspec new change` creates required metadata.

### Hooks
A `Stop` hook runs when Claude finishes a response, not only at the end of a task. The template's hook only acts with `RUN_QA=1` and must check `stop_hook_active` to avoid an infinite loop (Claude Code overrides a Stop hook that blocks eight times in a row).

## What the template provides (for comparison)
`openspec/config.yaml` (context/rules/operations), `.claude/settings.json` (model `sonnet`, `CLAUDE_CODE_SUBAGENT_MODEL=haiku`, Stop hook),
`.claude/hooks/run-tests.sh`, `.claude/agents/test-runner.md` (Haiku), `explore/_TEMPLATE/notes.md`, `install.sh`, `CHECKLIST.md`.

## Step 1: cheap inventory (run these, then stop and think)

```bash
claude --version; openspec --version; openspec config list
git status --short | head -20
ls -la; ls -la .claude openspec 2>/dev/null
wc -c CLAUDE.md AGENTS.md openspec/config.yaml openspec/project.md openspec/AGENTS.md .mcp.json 2>/dev/null
wc -c .claude/settings.json .claude/settings.local.json ~/.claude/settings.json 2>/dev/null
ls .claude/agents .claude/commands .claude/skills ~/.claude/agents ~/.claude/skills 2>/dev/null
openspec list; openspec list --specs
git ls-files | wc -l
git ls-files -z | xargs -0 du -k 2>/dev/null | sort -rn | head -15
cat .gitignore 2>/dev/null | head -40
```

## Step 2: what to look for

For each item, record: evidence, why it costs tokens, a suggested fix, and the risk of the fix.

**A. Model and effort pinning**
- Is a `model` set in `.claude/settings.json`, `~/.claude/settings.json` or `ANTHROPIC_MODEL`? If not, Pro sessions run on Opus 5.5.
- Any `effortLevel`/`modelSettings` set high globally? Any `max`, `ultracode`, `MAX_THINKING_TOKENS` or Fable usage by default?
- Is `CLAUDE_CODE_SUBAGENT_MODEL` set, or do custom subagents lack a `model`?
- Does any skill or command frontmatter name a different `model`? (Each such turn is a model switch and an uncached re-read.)

**B. Always-loaded context (paid on every session start)**
- Size of `CLAUDE.md` and `AGENTS.md`; duplicates between them; content that is only needed for one phase.
- Size and content of `context` in `openspec/config.yaml`; prototypes, long API docs or file listings pasted into it.
- Number and size of skills, commands and agents under `.claude/` and `~/.claude/`. Duplicate old (`/openspec:*`) and new (`/opsx:*`) command sets.
- MCP servers in `.mcp.json` or settings: list them, say which the project does not need.
- Plugins enabled that the project does not use.

**C. OpenSpec hygiene**
- Legacy files: `openspec/project.md`, `openspec/AGENTS.md`, old command files.
- Changes in `openspec/changes/` that are finished but not archived; abandoned changes.
- `tasks.md` files that use plain bullets instead of checkboxes.
- Delta specs that were never synced; very large spec files (suggest splitting by capability).
- `openspec config list`: which workflows are installed; any unused workflow generating extra skills.
- Is there a `rules` entry per artifact and `operations` guidance? Compare with the template.

**D. Repository noise Claude may read**
- Large tracked files (generated code, lockfiles, bundles, datasets, images, PDFs). Cite the top offenders from the `du` output.
- Is `node_modules`, `dist`, `build`, `.next`, coverage output or similar ignored in `.gitignore`?
- Prototype HTML or screenshots living in folders Claude is likely to open; many images accumulating in sessions.

**E. Workflow and hooks**
- Existing hooks in settings: any that run on every `PostToolUse`/`Stop` and cost time or tokens? Any `Stop` hook without a `stop_hook_active` check?
- Are tests run by the LLM through long command output? Suggest the template's `run-tests.sh` + `test-runner` subagent.
- Is there a place for exploration notes (`explore/`) and is it referenced by path rather than pasted?

**F. Anything else you notice** that clearly burns tokens (for example huge instruction files, a task list in prose, or a spec that restates the codebase).

## Step 3: report (this is your main output)

Write the report in chat; do not create files. Use this shape:

1. **Summary**: 3-5 lines. What is the single biggest quota leak?
2. **Findings table**, sorted by estimated impact (high / medium / low, qualitative; do not invent token numbers):

| # | Finding | Evidence (path, size) | Why it costs tokens | Suggested fix | Risk |
|---|---|---|---|---|---|

3. **Proposed changes**, grouped as: (a) safe and reversible, (b) needs the owner's judgment, (c) do not touch. For each, show the exact edit or command, but do not run it.
4. **What the template would add or change** in this project, file by file, and which existing files would need a manual merge.
5. **What you could not verify** (for example actual per-session consumption; suggest the owner compares `/usage` before and after).

## Step 4: after the report

- Ask the owner which proposals to apply. Apply only those, one group at a time, showing a diff for each file.
- Do not run `install.sh` unless asked; if asked, it never overwrites (it leaves `*.template` files to merge).
- When the owner confirms that the audit is finished, **delete this file** (`read-before-delete.md`) and say so.
