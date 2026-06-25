# After-Task Protocol

Every meaningful task or phase should leave a compact Markdown report. The report
is part of the project memory and should make later Codex, Claude Code, and human
review easier.

Use the project-local `after-task-audit` skill before closing the task. That
skill is the operational checklist; this document is the stable design note.

## Location

Task reports live in `docs/dev-log/after-task/`. Phase reports live in
`docs/dev-log/after-phase/`.

## Required sections

Each report should include:

- task goal;
- what was implemented;
- the mathematical contract touched (the 4PL, the direct `CTmax`/`z` map, the
  disjoint-bounds asymptotes, the profile algorithm), where relevant;
- files created or changed;
- checks run and exact outcomes (command text, not summaries);
- tests of the tests;
- consistency audit;
- GitHub issue maintenance;
- what did not go smoothly;
- team learning and process improvements;
- known limitations and next actions.

A phase report also records the symbolic mathematical contract and a consistency
audit across the phase.

## Consistency audit

Before closing a task, check for stale names and syntax across the repository.
Common freqTLS checks:

```sh
rg "CTmax|log_z|tref|relative|absolute|beta_binomial" README.Rmd ROADMAP.md NEWS.md docs vignettes R tests
rg "posterior|credible" R vignettes README.Rmd docs
rg "z[^a-zA-Z_]|thermal sensitivity|degrees per decade" README.Rmd docs vignettes R
```

The `posterior|credible` search must return only the deliberate teaching contrast
in the comparison vignette and `docs/design/90-bayesTLS-critique.md`. Any other
hit in a freqTLS-output context is a defect. The goal is not only to make tests
pass; it is to make sure code, docs, examples, design notes, and site navigation
describe the same package.

## Status inventory

For family, parameterisation, diagnostic, or implemented-scope changes,
explicitly check the status inventory before closing:

- `README.Rmd` current project status;
- `ROADMAP.md`;
- `NEWS.md`;
- `docs/dev-log/known-limitations.md`;
- `docs/design/46-capability-matrix.md`;
- the relevant numbered design doc (`01` for parameterisation, `02` for families,
  `03` for likelihoods, `04` for profiling, `06` for the benchmark);
- `_pkgdown.yml` when navigation should change.

Paste the exact `rg` patterns used into the check log or after-task report. A
generic phrase such as "stale-wording scans" is not enough.

## GitHub issue maintenance

Before closing a meaningful task, inspect overlapping open GitHub issues. Prefer
updating an existing issue over opening a duplicate. Record whether the task
commented on an issue, opened a new issue, closed an issue, or deliberately left
the tracker unchanged.

## Prose audit

If the task changes README text, vignettes, pkgdown pages, after-task notes,
release notes, or long design docs, run a prose-style pass before closing using
the `prose-style-review` skill. For very small prose-only tasks, keep the report
compact.

## Tests of the tests

When adding tests, confirm that they actually exercise the intended behaviour:
inspect failure messages before relaxing expectations; use deterministic seeds;
add a negative test when a rule should reject unsupported input; and confirm the
profile equivariance check `ci_z == exp(ci_log_z)` where profiling is touched.

## Closing rule

A task is not done until the after-task report says what was checked and what
remains uncertain.
