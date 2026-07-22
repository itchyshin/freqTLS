# Patrice reference-time and reader-surface remediation

## 1. Goal

Resolve the silent reference-time trap identified by @p-pottier while keeping
the experimental 0.1.0 single-stage 4PL scope unchanged. An omitted reference
on standardized, labelled data must mean one physical hour; an explicit numeric
reference must preserve its native-unit meaning; bare data must not be silently
ambiguous.

## 2. Implemented

- Added `tls_resolve_tref()` and used it from both `fit_tls()` interfaces and
  `fit_4pl()`. Recognised seconds, minutes, hours, and days resolve to 3600, 60,
  1, and 1/24 respectively when the reference is omitted.
- Preserved explicit values exactly, including `t_ref = 1` for a one-minute
  CTmax and the canonical 60-minute and 240-minute case-study estimands.
- Warned for bare/unlabelled data and errored for unknown labelled units until a
  numeric reference is supplied.
- Repaired #46 terminology, #49 getter interval-method forwarding, #51--#52
  awake/coma wording and duration-zero explanation, #54 rendered diagnostic
  output, and the comparison-cache label join exposed by the wording repair.

## 3a. Decisions and Rejected Alternatives

The public default is a one-hour convention only for recognized metadata; it is
not a general time conversion. Requiring every user to provide `tref` was
rejected because the approved contract requires a safe one-hour default for
standardized data. Silently retaining `1` for labelled minute data was rejected
because it can report a one-minute CTmax as if it were one hour.

## 4. Files Touched

Core changes are in `R/reference-time.R`, `R/fit_tls.R`, `R/fit_4pl.R`, and
`R/extract.R`; regression coverage is in `tests/testthat/test-reference-time.R`
and `test-fit-beta.R`. Roxygen output, README, articles, design notes, NEWS, and
the project contract were synchronized.

## 5. Checks Run

`devtools::document()`, `devtools::check_man()`, targeted tests (98 passing),
the full test suite (1,096 passing), rendered pkgdown checks, `R CMD build`, and
strict `R CMD check --as-cran` all ran. The exact tarball SHA-256 is
`3565f9c8164de017188063216d2589b964939744a3a4793f8fdf54c56347e4ea`.

## 6. Tests of the Tests

The new suite covers each resolution branch, confirms physical-unit invariance,
checks formula and column interfaces separately, asserts warning/error paths,
and tests `Inf` rejection. The temporary comparison-page failure proved that the
reader-facing awake/coma label was also a cache join key; the cache label is now
normalised before matching and the rendered article succeeds.

## 7a. Issue Ledger

- #46, #48, #49, #51, #52, and #54 are implemented and ready for evidence-linked closure.
- #50 is a documented decision: the public return contract remains a tibble.
- #47 (Confidence-Eye redesign) and #53 (real-data heat-injury lesson) remain
  open as intentionally deferred, larger design/data work.

## 8. Consistency Audit

The active source and rendered-site scans have no residual per-decade wording.
The one-hour/explicit-reference distinction appears in help, README, the main
tutorial, design notes, capability matrix, NEWS, and rendered reference pages.

## 9. What Did Not Go Smoothly

The normal README rebuild attempted external metadata resolution in `pak`, so
the installed-package render path was used. Full pkgdown build exceeded the
terminal's 30-second command window; reference and affected articles were
rendered separately, then the project post-build cleanup was run. Neither issue
changed package code or the final tarball result.

## 10. Known Residuals

The new source changes postdate the submitted 0.1.0 tarball. They are not a
claim about CRAN acceptance. Cross-platform CI and GitHub issue closure remain
pending the branch/PR publication.

## 11. Team Learning

Reference-time units are an estimand contract, not plot metadata. A wording
change can also alter a cached-data join key, so rendered empirical articles
must be executed after terminology edits.

## 12. Cross-Product Coverage

This remediation does NOT cover a Confidence-Eye redesign, a real-data
heat-injury tutorial, fitted injury/repair dynamics, new response families,
random-effect extensions, or changes to the submitted tarball.
