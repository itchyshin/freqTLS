# After Task: Human-validation remediation for issues #15--#24

## 1. Goal

Resolve the findings from @itchyshin's assigned human-validation slice while
keeping the experimental 0.1.0 reader boundary intact.

## 2. Implemented

The accessor reference now calls bootstrap rows resampled frequentist estimates,
not posterior draws, and explains that the compatibility-named `*_median` field
holds the maximum-likelihood point estimate. `predict.profile_tls()` and
`tdt_parameter_table()` now define `CTmax`, `z`, `log_z`, `low`, `up`, and `k`.
`plot_tdt_curve()` now defaults to each fitted curve's relative midpoint
`(low + up) / 2`; a supplied numeric `p` is explicitly an absolute probability.
Confidence-Eye captions state their parameter scale, and an all-open profile now
has a visible compact warning. The stale Phase 4 text and the misleading
homepage claim were removed. The rendered profile vignette was updated to
describe the open-profile cue.

## 3. Mathematical Contract

No likelihood, 4PL parameterisation, or profile algorithm changed. The repair
makes the plotting default agree with the existing relative-threshold contract:
the plotted duration is evaluated at `(low + up) / 2`, whereas a numeric `p`
requests an absolute survival probability. `CTmax` remains the critical thermal
maximum at `tref`; `z` remains thermal sensitivity in degrees per decade.

## 3a. Decisions and Rejected Alternatives

The open-profile cue uses a short subtitle rather than a two-line help prompt:
the longer wording clipped the title in the rendered vignette figure. The
relative default was implemented in code rather than merely relabelling the old
absolute `p = 0.5` behavior, because the old label and behavior disagreed.

## 4. Files Touched

Updated roxygen sources in `R/extract_tdt.R`, `R/predict.R`, `R/tls.R`,
`R/profile.R`, and `R/plotting.R`; regenerated their Rd files and the README
figure; updated `README.Rmd`, `README.md`, `vignettes/profile-likelihood.Rmd`,
and `tests/testthat/test-predict.R`; recorded this check log and report.

## 5. Checks Run

- `Rscript --vanilla -e 'devtools::document(); devtools::build_readme(); devtools::check_man(); devtools::test(filter = "profile|predict")'` -> 110 passing, 0 failures, 0 warnings, 0 skips.
- `Rscript --vanilla -e 'devtools::test()'` -> 1,046 passing, 0 failures, 0 warnings, 0 skips (128.4 seconds) on the final source.
- `Rscript --vanilla -e 'pkgdown::check_pkgdown()'` -> `No problems found.`
- `Rscript tools/build-site.R .` -> complete; public-site internal-file removal and six filled reference-image alt texts confirmed.
- `rg -n -i 'posterior draws|full Confidence-Eye interval.*Phase 4|prose never uses "posterior"|Comment when your slice is complete' R README.Rmd README.md man pkgdown-site --glob '!pkgdown-site/search.json'` -> no unresolved issue wording; remaining hits are deliberate Bayesian comparisons or historical NEWS text.
- `git diff --check` -> clean.

## 6. Tests of the Tests

The new `plot_tdt_curve()` test uses the fitted `low` and `up` values to compare
the default plotted duration to an independent `derive_lt()` call at
`(low + up) / 2`, and compares `p = 0.5` to the absolute-threshold result. The
existing sparse-design test still exercises the all-open-profile warning; it
initially caught a capitalization mismatch in the new subtitle, then passed
after the wording was made compatible and visually compact.

## 7a. Issue Ledger

Issues #23 and #24 were resolved directly in tracker #14 and closed. The package
changes address #15--#22; they remain open until this branch is merged, then
will be closed with the merge evidence. Tracker #14 has all @itchyshin review
items checked and links to the finding issues.

## 8. Consistency Audit

The rendered reference pages for `tdt-accessors`, `predict.profile_tls`,
`tdt_parameter_table`, `plot_tdt_curve`, `plot.profile_tls_profile`, and
`plot_confidence_eye`, plus the home page and profile-likelihood article, were
rebuilt and read. The non-closing Confidence-Eye figure was visually inspected:
it shows the open-profile warning, hollow point, and CTmax scale without clipping.
No release-boundary change occurred, so `ROADMAP.md`, `NEWS.md`,
`docs/dev-log/known-limitations.md`, and `docs/design/46-capability-matrix.md`
remain accurate without an unrelated release-status edit.

## 9. What Did Not Go Smoothly

The first full-suite run caught an existing test expectation that was case
sensitive; the repaired wording passed the targeted and final full runs. A
two-line open-profile subtitle avoided horizontal clipping but created vertical
title clipping in the rendered figure, so it was shortened and rebuilt.

## 10. Known Residuals

The dependency freshness notice for MASS, Rcpp, and rlang is environmental and
does not affect the passing checks. This task does not establish a new CRAN
candidate, alter author order, or replace the separate human reviews assigned
to Piet, Patrice, and Dan.

## 11. Team Learning

Rendered visual inspection is necessary after a text-only figure change: a
subtitle can pass the test suite while still crowding a figure title. Threshold
defaults should be tested against the numerical calculation, not just their
caption, whenever `relative` and `absolute` terms meet a plotting helper.

## 12. Cross-Product Coverage

This task covers the human-validation findings in #15--#24 and does NOT cover
new model families, fit-time absolute thresholds, fitted heat-injury dynamics,
or the remaining collaborators' review allocations.
