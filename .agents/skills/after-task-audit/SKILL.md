---
name: after-task-audit
description: Audit a completed freqTLS task or phase before closing it, checking implementation, equations, examples, tests, docs, pkgdown, roadmap, NEWS, the capability matrix, known limitations, stale wording, and after-task reporting.
---

# After-Task Audit

Use this skill before treating a meaningful `freqTLS` task or phase as
complete. It is Rose's forest-and-trees checklist: make sure the repository
tells one coherent story after code changes.

## Required Audit

1. State the implemented claim in one sentence.
2. Check the code paths that implement the claim.
3. Check that the symbolic equations and R syntax describe the same model
   (the 4PL, the direct `CTmax`/`z` map, the nested-gap asymptotes).
4. Check that examples and vignettes use supported syntax and current names.
5. Check that tests exercise the intended behaviour and at least one failure
   path (a sparse design, a non-closing profile, a malformed input).
6. Run targeted tests for the touched behaviour.
7. Run broader package checks when practical:
   - `devtools::test()`
   - `devtools::document()` if roxygen changed
   - `pkgdown::check_pkgdown()`
   - `pkgdown::build_site()` if user-facing docs changed
   - `devtools::check()`
8. Search for stale wording across docs and the generated site.
9. For prose-heavy tasks, apply the `prose-style-review` skill before closing.
10. For family, parameterisation, diagnostic, or implemented-scope changes,
    check the status inventory explicitly: `README.Rmd` current status,
    `ROADMAP.md`, `NEWS.md`, `docs/dev-log/known-limitations.md`,
    `docs/design/46-capability-matrix.md`, the relevant numbered design doc, and
    `_pkgdown.yml` when navigation should change. Record the exact `rg` patterns
    used; do not write only "stale-wording scans".
11. Inspect overlapping open GitHub issues before closing. Prefer commenting on
    or updating an existing issue over opening a duplicate. Record issue
    comments, new issues, closures, or the reason no issue action was needed.
12. Update roadmap, NEWS, known limitations, the capability matrix, and design
    docs when behaviour changed.
13. Add a compact after-task report under `docs/dev-log/after-task/`.

## Stale-Wording Searches

Use task-specific searches. Common `freqTLS` patterns:

```sh
rg "CTmax|log_z|tref|relative|absolute|beta_binomial" README.Rmd ROADMAP.md NEWS.md docs vignettes R tests
rg "posterior|credible" R vignettes README.Rmd docs
rg "z[^a-zA-Z_]|thermal sensitivity|degrees per decade" README.Rmd docs vignettes R
rg "planned.*implemented|not implemented yet.*implemented|TODO|FIXME" README.Rmd ROADMAP.md docs vignettes R tests
```

The `posterior|credible` search should return only the deliberate teaching
contrast in the comparison vignette and the critique doc; any other hit in a
freqTLS-output context is a defect. Generated pkgdown pages under
`pkgdown-site/` can also carry stale text after a build.

Do not mechanically delete historical after-task notes. If an old note was true
when written, leave it; add the new after-task report to supersede it.

## Tests Of The Tests

For new tests, verify at least one of the following:

- the new test failed before the fix;
- the test compares the likelihood or profile to an independent calculation;
- the test checks a boundary, malformed input, sparse design, or non-closing
  profile path;
- the test combines the new feature with an already-supported neighbouring
  feature (e.g. grouped beta-binomial).

## After-Task Report Template

```md
# After Task: <Title>

## Goal

## Implemented

## Mathematical Contract

## Files Changed

## Checks Run

## Tests Of The Tests

## Consistency Audit

## GitHub Issue Maintenance

## What Did Not Go Smoothly

## Team Learning

## Known Limitations

## Next Actions
```

The task is not closed until the report records what passed, what remains
uncertain, which docs/examples were synchronized, what went wrong or felt
clumsy, and which team skill or process should improve next.
