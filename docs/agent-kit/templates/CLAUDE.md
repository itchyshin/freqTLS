# Claude Code Instructions For <PROJECT>

Read `AGENTS.md` first. Follow the same scope, design rules, standard
commands, after-task protocol, and standing review roles as Codex.

Do not introduce a parallel agent configuration system unless the project owner
asks for one. Durable decisions belong in repository files:

- `AGENTS.md`
- `docs/design/`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/`
- issues and pull requests

Before editing after a handoff or crash, run:

```sh
git status --short --branch
git diff --stat
git diff
```

Then read the newest check-log and after-task reports.
