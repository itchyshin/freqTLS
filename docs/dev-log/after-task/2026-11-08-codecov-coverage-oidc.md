# After Task: Codecov first coding pass (freqTLS only)

## Goal

Bounded first coding pass after Shinichi approved the First+Next 13-repo
Codecov rollout. Land real test-coverage collection and one Codecov OIDC
upload on freqTLS CI, then open a narrow review PR and hand off without
waiting on remote CI. Other repos, pigauto, and GLLVModels stay untouched.

## Implemented

- New ubuntu-only `test-coverage.yaml`: `covr::package_coverage()` to
  Cobertura to `codecov/codecov-action` v7 with `use_oidc: true`.
- `codecov.yml`: one expected upload (`after_n_builds: 1`), informational
  status checks, ignore tests/docs/vignettes.
- R-CMD-check four-platform matrix preserved; comment only, no covr there.
- Dashboard note distinguishing config, local covr, CI coverage finish,
  upload transaction, processed commit report, and main baseline, plus
  branch-head versus synthetic PR-merge checkout SHA. No README badge.

## Mathematical Contract

Untouched. This slice does not change the 4PL, the direct `CTmax`/`z`
mapping, the disjoint-bounds asymptotes, the profile algorithm, families,
or the relative-threshold default.

## Files Changed

- `.github/workflows/test-coverage.yaml` (new)
- `.github/workflows/R-CMD-check.yaml` (comment only)
- `codecov.yml` (new)
- `.Rbuildignore`
- `docs/dev-log/dashboard/test-coverage.md` (new)
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-11-08-codecov-coverage-oidc.md`

No `R/`, `src/`, `tests/`, fixtures, NEWS, DESCRIPTION, capability matrix,
ROADMAP, or known-limitations edits. Those public files stay unchanged
because this is CI infrastructure, not a fitted-model capability, and a
live Codecov badge remains deferred until a processed commit report exists.

## Checks Run

- PyYAML 6.0.1: `yaml ok` / `oidc+ubuntu+single-upload ok`.
- R-CMD-check matrix still ubuntu-release, ubuntu-devel, windows-release,
  macos-15-intel; comment only; no covr upload there.
- `git diff --check`: clean.
- `Rscript` / `R`: **ABSENT**. Local covr **NOT_VERIFIED**. No percent
  fabricated.
- `devtools::document()` / `test()` / `check()`: not run (no R; no R
  source change).
- Hosted `test-coverage`, Codecov upload/acceptance, and main baseline:
  **NOT_VERIFIED** until GitHub Actions and Codecov produce them.

Exact command text is in `docs/dev-log/check-log.md`.

## Tests Of The Tests

Did not add or weaken tests. The coverage job re-runs the existing
testthat suite under covr tracing. `skip_on_cran()` still runs here
because r-lib sets `NOT_CRAN`, matching R-CMD-check. Cache and source-tree
`skip_if_not()` guards stay. No scientific suite expansion.

## Consistency Audit

Stale-wording scans used:

```sh
rg -n "codecov|covr|CODECOV_TOKEN|use_oidc" .github codecov.yml docs/dev-log README.Rmd ROADMAP.md NEWS.md docs/design/46-capability-matrix.md docs/dev-log/known-limitations.md
rg -n "posterior|credible" R vignettes README.Rmd docs
```

Public claims: README/DESCRIPTION/capability matrix/known-limitations/
NEWS unchanged. No badge claiming a dashboard. Docs state that config is
not functioning coverage. The `posterior|credible` hits remain the
deliberate teaching contrast, not freqTLS interval language.

Verdict: **clean-with-limitations** — limitations are the NOT_VERIFIED
stages, the missing local R runtime, and the branch-head versus synthetic
merge SHA distinction.

## GitHub Issue Maintenance

`gh issue list --repo itchyshin/freqTLS --state open` returned no open
issues. No Codecov issue existed. Tracker deliberately unchanged. No
scientific issue closed.

## What Did Not Go Smoothly

No R runtime on this host, so no local coverage percent could be produced
without fabricating one. hsquared PR 364 already processed an OIDC branch
report on a sibling repo; that must not be treated as freqTLS proof.

## Team Learning

One coverage job, one flag, `after_n_builds: 1`. Keep check shards and
coverage upload on separate workflows so OS matrices cannot double-count.
Record branch-head SHA and tested checkout SHA separately on
`pull_request` because GitHub may build a synthetic merge commit.

## Known Limitations

- Local covr, CI coverage finish, upload transaction, processed commit
  report, and main baseline are all **NOT_VERIFIED**.
- If OIDC upload fails, that is the moment to consider a Codecov GitHub
  App grant. Do not request it speculatively. Do not use `GH_TOKEN` as a
  Codecov token.
- Main baseline needs an authorized merge plus a `push` run on `main`.
  This lane does not merge.
- covr traces R. TMB C++ in `src/` is not a gcov report.
- Subsequent CI wakes should report evidence only and ask the coordinator
  before further edits.

## Next Actions

Review the PR. Watch `test-coverage` and R-CMD-check independently. Later
CI wakes are evidence-only unless the coordinator asks for a follow-up
edit. Do not merge from this lane.
