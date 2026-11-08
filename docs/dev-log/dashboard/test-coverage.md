# Test coverage collection and Codecov upload

**Slice:** first Codecov coding pass (freqTLS lane only)
**Approval:** Shinichi approved the First+Next 13-repo Codecov rollout; this
file records the pipeline, not a coverage percentage.

This is **code-coverage infrastructure** (covr + Codecov). It is not a
scientific interval-coverage claim, not a `bayesTLS` comparator result, and
not a fitted-capability change. hsquared PR 364 processed a 78.21% OIDC
branch report without owner action on that repo; that is **not** proof for
freqTLS.

## What runs

| Workflow | Role | Shards | Uploads to Codecov? |
| --- | --- | --- | --- |
| `R-CMD-check.yaml` | package check | ubuntu-release, ubuntu-devel, windows-release, macos-15-intel | **no** |
| `test-coverage.yaml` | `covr::package_coverage()` then one OIDC upload | ubuntu only | **yes, once** (`flags: ubuntu-covr`) |
| `pkgdown.yaml` | site build/deploy after trusted main check | n/a | no |
| `rhub.yaml` | manual R-hub | n/a | no |

Do **not** add covr to the R-CMD-check OS matrix. Those four jobs run the
same testthat suite; uploading more than once would double-count.

The coverage job keeps the existing skips. `skip_on_cran()` tests still run
because r-lib sets `NOT_CRAN`, matching R-CMD-check. Cache and source-tree
`skip_if_not()` guards stay. The job does not add tests, weaken tests, or
restart a scientific campaign. covr traces R; TMB C++ in `src/` is not a
gcov report.

Auth is documented Codecov OIDC (`use_oidc: true`) with job-scoped
`contents: read` and `id-token: write`. No `CODECOV_TOKEN`, and
`GITHUB_TOKEN` / `GH_TOKEN` is not used as a Codecov token (`GITHUB_PAT` is
only the usual r-lib install token).

## Evidence stages (do not collapse)

Config on a branch is not functioning coverage. Keep these claims separate:

| Stage | What would prove it | This first pass |
| --- | --- | --- |
| 0. Config landed | workflow + `codecov.yml` on an isolated branch | this PR |
| 1. Local checks / local covr | `devtools::test()` / `covr::package_coverage()` on this host | **NOT_VERIFIED** — no R runtime here |
| 2. CI coverage finish | GitHub Actions `test-coverage` job produced `cobertura.xml` and a covr percent in the log / step summary | **NOT_VERIFIED** until that job completes |
| 3. Upload transaction | Codecov action log shows a successful OIDC upload (`fail_ci_if_error: true`) | **NOT_VERIFIED** until that step succeeds |
| 4. Processed commit report | Codecov commit URL for the **reported** SHA shows an accepted report | **NOT_VERIFIED** until Codecov accepts it |
| 5. Main baseline | https://app.codecov.io/gh/itchyshin/freqTLS (or the GitHub Codecov app) shows `main` | **NOT_VERIFIED**; needs an **authorized merge** to `main` plus a successful `push` run of `test-coverage.yaml` on `main` |

Stage 5 is why the workflow listens to `push` on `main` as well as
`pull_request`. GitHub Actions will run the PR workflow from this branch
without merging. The **main baseline** will not exist until someone with
merge authority lands the workflow on `main` and that `push` job uploads.
This lane does not merge.

## Branch head versus tested checkout SHA

On `pull_request`, GitHub Actions may check out a **synthetic merge commit**
of the PR branch into `main`, not the branch-head SHA. Record both:

- **branch head SHA:** `github.event.pull_request.head.sha` (the commit on
  this PR branch);
- **tested checkout SHA:** `github.sha` (often the merge commit).

A Codecov branch report, if it appears, must be matched to the SHA Codecov
actually processed. Do not treat a green config review, a covr print, or a
hsquared percentage as a freqTLS dashboard.

## Architecture notes

- PR comments from Codecov, if the GitHub App is installed for this
  repository, can appear after a successful upload. That is stage 4-ish,
  still not stage 5.
- If OIDC upload fails, treat that as an actual uploader failure before
  asking the owner for a Codecov GitHub App grant or a repository token.
  Do not mint or extract tokens; do not put `GH_TOKEN` in the Codecov
  `token:` input. hsquared's processed report is not a freqTLS grant.
- Coverage status checks are **informational** (`codecov.yml`). This pass
  does not fail PRs on an unknown baseline percentage.
- README Codecov badge is deferred until stage 4 exists. A badge is not
  evidence.

## Local covr (when R is available)

```r
# Same testthat suite the CI job measures; skips preserved
cov <- covr::package_coverage()
print(cov)
covr::report(cov)
```

Do not treat a local percent as a Codecov dashboard number.
