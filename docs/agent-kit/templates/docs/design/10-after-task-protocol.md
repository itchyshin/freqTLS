# After-Task Protocol

Every meaningful task or phase should leave a compact Markdown report. The
report is part of the project memory and should make later Codex, Claude Code,
human review, and release work easier.

Use the project-local `after-task-audit` skill before closing the task.

## Location

Task reports live in:

```text
docs/dev-log/after-task/
```

Phase reports live in:

```text
docs/dev-log/after-phase/
```

## Required Sections

Each report should include:

- task goal;
- files created or changed;
- checks run and exact outcomes;
- consistency audit;
- tests of the tests, when tests changed;
- what did not go smoothly;
- team learning and process improvements;
- design-doc updates;
- documentation or site updates;
- known limitations and next actions.

## Consistency Audit

Before closing a task, check for stale names, syntax, schemas, parameter names,
planned-versus-implemented language, and unsupported examples across the
repository.

Use project-specific searches, for example:

```sh
rg "old_function|old_parameter|planned.*implemented" README.md docs vignettes R tests
rg "TODO|FIXME|not implemented yet.*implemented" README.md docs vignettes
```

Record the exact `rg` patterns used in the check log or after-task report. A
generic phrase such as "stale-wording scans" is not enough for later auditors.

## Tests Of The Tests

When adding tests, confirm that they actually exercise the intended behaviour.
Examples:

- inspect failure messages before relaxing expectations;
- check that parser tests assert parsed fields, not only object classes;
- use deterministic seeds for simulation or ML tests;
- add a negative test when a rule should reject unsupported syntax or data.

## Closing Rule

A task is not done until the after-task report says what was checked, what was
not checked, and what remains uncertain.

## Template

```md
# After Task: <Title>

## Goal

## Implemented

## Files Changed

## Checks Run

## Tests Of The Tests

## Consistency Audit

## What Did Not Go Smoothly

## Team Learning

## Known Limitations

## Next Actions
```
