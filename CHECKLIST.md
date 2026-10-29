# Checklist

## Once per machine
- [ ] `claude update` (Sonnet 5.5 requires v2.1.284 or later; Opus 5.5, v2.1.280)
- [ ] `npm install -g @fission-ai/openspec`
- [ ] `openspec config list` and check which workflows you have (are `sync` and `update` included?)
- [ ] Install `jq` (the QA hook uses it)
- [ ] Note a usage baseline with `/usage` to compare later

## Existing project (optional, before the steps below)
- [ ] `./install.sh /path/to/project --with-audit`
- [ ] `claude --model sonnet --effort medium`, then "Read read-before-delete.md and follow it."
- [ ] Review the report, approve the changes you want, and let the agent delete `read-before-delete.md`

## Once per project
- [ ] `openspec init --tools claude`
- [ ] `./install.sh /path/to/project` (overwrites nothing; leaves `*.template` if the file already existed)
- [ ] Edit `context` in `openspec/config.yaml` (stack, test command)
- [ ] Put the real test command in `.claude/hooks/run-tests.sh` (`TEST_CMD`)
- [ ] Reopen Claude Code and check the hook with `/hooks`
- [ ] Try the full flow with a small change
- [ ] Compare `openspec archive <change> -y` with `/opsx:archive` and diff `openspec/specs/`

## For each change
- [ ] Explore: `claude --model sonnet --effort low`, then `/opsx:explore`; prototypes in `explore/<topic>/`
- [ ] Write `explore/<topic>/notes.md` (copy `explore/_TEMPLATE/notes.md`) before closing
- [ ] Propose: new session with `claude --model opus --effort medium`, then `/opsx:propose <name>`
- [ ] `openspec validate <name> --strict` with no errors
- [ ] Review the delta specs and `tasks.md`; commit before Apply
- [ ] Apply: `RUN_QA=1 claude --model sonnet --effort medium`, then `/opsx:apply <name>`
- [ ] `/clear` between groups of 3 to 5 tasks
- [ ] If Apply stops over the design: new session with Opus, update design/specs/tasks, validate and resume
- [ ] Archive: `openspec archive <name> -y` (or `/opsx:archive`) and review `openspec/specs/`
- [ ] Final commit
