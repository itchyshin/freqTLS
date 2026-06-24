# Check Log

This is an append-only log for validation evidence, handoff notes, and
important project state. Keep entries concise and concrete.

## Template

```md
## YYYY-MM-DD - <short task title>

- Branch: `<branch>`
- Goal: <one sentence>
- Files changed: `<path>`, `<path>`
- Checks run:
  - `<command>`: <exact outcome>
  - `<command>`: <exact outcome>
- Stale-claim searches:
  - `<rg pattern>` over `<paths>`: <outcome>
- Not run: <commands or checks skipped, with reason>
- Next safest action: <one sentence>
```

## YYYY-MM-DD - Install Agent Operating Kit

- Branch: `<branch>`
- Goal: Install project-level agent rules, local skills, dev-log structure, and
  after-task protocol.
- Files changed: `AGENTS.md`, `docs/design/00-vision.md`,
  `docs/design/10-after-task-protocol.md`, `docs/dev-log/check-log.md`,
  `.agents/skills/`
- Checks run:
  - `git status --short --branch`: <record output>
- Not run: full package checks; setup-only change.
- Next safest action: customize placeholders, then commit before feature work.
