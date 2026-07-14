# After Task: Experimental-use warning

## 1. Goal

Warn GitHub and pkgdown readers that `freqTLS` is experimental, place
responsibility for checking analyses with users, and recommend an independent
cross-check with the Bayesian sister package `bayesTLS`.

## 2. Implemented

Added one prominent warning below the README badges and regenerated
`README.md`. The warning says that results may be incorrect or change, names
data, model specification, convergence, diagnostics, and interpretation as
user responsibilities, and links to `bayesTLS` for independent checking.

## 3a. Decisions and Rejected Alternatives

The warning lives in `README.Rmd`, which generates both the GitHub README and
the pkgdown homepage. This avoids two copies drifting. A lifecycle badge alone
was rejected because it does not explain the practical risk or tell users what
to do. A package startup warning was not added because the request concerned
the repository and website, and a startup message would change the runtime user
experience.

## 4. Files Touched

- `README.Rmd`
- `README.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-14-experimental-use-warning.md`

## 5. Checks Run

- `Rscript --vanilla -e 'devtools::build_readme(quiet = TRUE)'` regenerated the
  GitHub Markdown successfully.
- `Rscript --vanilla -e 'pkgdown::check_pkgdown()'` reported no problems.
- `Rscript --vanilla tools/build-site.R` completed the full local site build.
- `rg -n -C 3 "Experimental software|use at your own risk|cross-check the results|Bayesian sister" pkgdown-site/index.html README.Rmd README.md`
  confirmed the same notice and `bayesTLS` link in source, generated Markdown,
  and rendered homepage HTML.
- `gh issue list --state open --limit 50 --json number,title,url` returned no
  open issues.

## 6. Tests of the Tests

No model code or runtime behaviour changed, so parameter-recovery and package
tests are not targeted to this task. The validation checks the generated
artifacts rather than only the source: removing or failing to render the notice
would make the exact-string scan of `README.md` or `pkgdown-site/index.html`
fail to find it.

## 7a. Issue Ledger

No overlapping GitHub issue existed. No new issue was needed because this was a
direct, bounded documentation request implemented in a focused branch.

## 8. Consistency Audit

The GitHub and pkgdown surfaces share the generated README, so the warning is
worded once. `NEWS.md`, `ROADMAP.md`, the capability matrix, known limitations,
and model design documents were inspected for scope: none requires a change
because package behaviour and capability did not change. The wording uses
confidence terminology for `freqTLS` and identifies `bayesTLS` as Bayesian.

Memory receipt: loaded the repo `AGENTS.md`, `SPEC.md`, the `route.py freqTLS`
manifest, `VOICE.md`, `PROJECTS.md`, the project prose and after-task skills,
and the R-package/validation guards. They shaped the single-source README edit,
rendered-site verification, stable terminology, and focused scope.

Golden Set: no known repeated-mistake class was implicated, so
`memory_regression.py` was not run.

## 9. What Did Not Go Smoothly

The original checkout contained unrelated edits and was behind `main`, so the
change was isolated in a clean worktree from `origin/main`. The README build
also reported newer available `Rcpp` and `rlang` versions; dependency upgrades
were outside this documentation task.

## 10. Known Residuals

The public warning is not visible until the branch is merged and the normal
GitHub Actions package-check and pkgdown deployment chain succeeds. The notice
reduces misunderstanding but cannot itself verify any user's data or analysis.

## 11. Team Learning

For a risk notice shared by GitHub and pkgdown, place the authoritative wording
in `README.Rmd`, regenerate `README.md`, and inspect the rendered `index.html`.
An experimental badge is not a substitute for a concrete action-oriented
warning.

## 12. Cross-Product Coverage

Coverage includes the GitHub README and pkgdown homepage. It does NOT cover
package startup messages, function-level help pages, vignettes other than the
homepage, runtime diagnostics, or the correctness of individual analyses.
