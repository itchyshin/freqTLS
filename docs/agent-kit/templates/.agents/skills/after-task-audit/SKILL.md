---
name: after-task-audit
description: Audit a completed task or phase before closing it, checking implementation, equations or algorithms, examples, tests, docs, roadmap, release notes, stale wording, and after-task reporting.
---

# After-Task Audit

Use this skill before treating a meaningful task or phase as complete. Rose owns
the systems question: does the repository now tell one coherent story?

## Required Audit

1. State the implemented claim in one sentence.
2. Check code paths that implement the claim.
3. Check equations, algorithms, schemas, and user-facing syntax describe the
   same behaviour.
4. Check examples and vignettes use supported syntax and current names.
5. Check tests exercise the intended behaviour and at least one failure path
   when appropriate.
6. Run targeted tests for touched behaviour.
7. Run broader package checks when practical:
   - `devtools::test()`
   - `devtools::document()` if roxygen changed
   - `pkgdown::check_pkgdown()` or equivalent site checks
   - `devtools::check()`
8. Search for stale wording across docs and generated site output when relevant.
9. For prose-heavy tasks, apply the `prose-style-review` skill before closing.
10. Update roadmap, NEWS, known limitations, and design docs when behaviour
    changed.
11. Add a compact after-task report under `docs/dev-log/after-task/`.

## Stale-Wording Searches

Use task-specific searches. Examples:

```sh
rg "old_function|old_parameter|old_schema" README.md docs vignettes R tests
rg "planned.*implemented|not implemented yet.*implemented" README.md docs vignettes
rg "TODO|FIXME" README.md docs vignettes R tests
```

Do not mechanically delete historical after-task notes. If an old note was true
when written, leave it; add the new after-task report to supersede it.

## Tests Of The Tests

For new tests, verify at least one of the following:

- the new test failed before the fix;
- the test compares to an independent calculation or fixture;
- the test checks a boundary, malformed input, missing-data path, or prediction
  path;
- the test combines the new feature with an already-supported neighbouring
  feature.

## After-Task Report Template

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
