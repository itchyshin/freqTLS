# After Task: CRAN Preflight Roxygen Repair

Date: 2026-07-16
Branch: `build/freqtls`
Reader: freqTLS maintainers preparing the next release-remediation slice

## 1. Goal

Remove the two roxygen warnings found by the July 11 CRAN-readiness audit,
without altering the fitted model, its API, or the release boundary.

## 2. Implemented

`tdt_unit_to_minutes()` now refers to the external comparator helper as literal
`bayesTLS::derive_tdt_curve()` rather than an unresolved Rd link. The roxygen
block for `tls_backtransform()` now immediately precedes that helper, while the
complete `tls_ci_df()` block carries its own final `@noRd` tag.

## 3. Scope and Decisions

This is a documentation-generation repair only. It makes no claim that the
package is CRAN-ready and does not reconcile the contradictory v0.1 scope
statements identified on July 11.

## 4. Files Touched

- `R/tdt-utils.R`
- `R/utils.R`
- `man/tdt_unit_to_minutes.Rd`
- `man/profile.profile_tls.Rd`
- `docs/dev-log/check-log.md`
- this report

## 5. Checks Run

- `Rscript -e 'devtools::document()'` completed with no roxygen warnings.
- `Rscript -e 'devtools::test()'` completed successfully.
- `Rscript -e 'testthat::test_local(reporter = "summary")'` completed with one
  expected benchmark-cache skip.
- `Rscript -e 'devtools::check_man()'` completed with no documentation warnings.
- `git diff --check` passed.

## 6. Tests of the Repair

The prior `derive_tdt_curve` cross-reference no longer asks Rd to resolve a
function that freqTLS does not document. Roxygen also no longer reports either
the broken link or a multi-line `@keywords` field.

## 7. Known Residuals

The package still has unresolved CRAN-release gates: public-scope reconciliation,
the `bayesTLS` Suggest policy, tarball exclusions, first-submission metadata,
URL and data-license review, and multi-platform evidence.

## 8. Next Best Task

Make an explicit release-boundary decision: either retain the shipped expanded
surface as the experimental 0.1.0 scope, or remove/defer the incompatible
capabilities and documentation. Only then update the authoritative documents
and proceed with the remaining CRAN gates.
