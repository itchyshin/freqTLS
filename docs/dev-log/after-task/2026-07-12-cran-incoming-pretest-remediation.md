# After Task: CRAN Incoming-Pretest Remediation

## 1. Goal

Fix every issue in CRAN incoming pre-test
`freqTLS_0.1.0_20260712_135803` without weakening live package validation, then
produce a new exact source candidate for independent Windows verification.

## 2. Implemented

Rewrote the two spell-flagged DESCRIPTION phrases with equivalent scientific
meaning. Replaced redundant cross-study fit/profile recomputation with a
versioned maintainer cache that records provenance and actual interval methods.
Kept two 1,000-refit bootstrap recipes visible but display-only during package
checks. Corrected the summary article's false claim that all eight contrast
intervals were profiles: the deterministic cache shows seven use the documented
bootstrap fallback. Corrected grouped contrast direction so a name such as
`dCTmax:A-B` consistently means group A minus group B in profile and bootstrap
paths, public documentation, tests, and cached case-study results.

## 3a. Decisions and Rejected Alternatives

We retained version 0.1.0 because CRAN rejected it before publication. We did
not add a spelling whitelist because direct prose made both flags disappear. We
did not remove or skip tests, reduce bootstrap replicate counts to misleading
values, hide the whole vignette suite, or merely explain the 11-minute timing.
We chose a small versioned cache for the redundant synthesis while retaining
live fits and intervals in individual articles and the 827-test suite.

## 4. Files Touched

- `DESCRIPTION`
- `NEWS.md`
- `R/bootstrap.R`
- `R/confint.R`
- `R/profile.R`
- `cran-comments.md`
- `data-raw/build_case_study_summary_cache.R`
- `docs/design/01-model-and-parameterisation.md`
- `docs/design/04-profile-likelihood.md`
- `docs/design/47-data-license-ledger.md`
- `docs/dev-log/after-task/2026-07-12-cran-incoming-pretest-remediation.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/decisions.md`
- `docs/dev-log/release-gates/2026-07-11-cran-0.1.0.md`
- `inst/COPYRIGHTS`
- `inst/extdata/case_study_summary_cache.rds`
- `man/confint.profile_tls.Rd`
- `tests/testthat/test-case-study-summary-cache.R`
- `tests/testthat/test-group.R`
- `vignettes/case-study-summary.Rmd`
- `vignettes/case-study-suzukii.Rmd`
- `vignettes/comparing-to-bayesTLS.Rmd`
- `vignettes/profile-likelihood.Rmd`

## 5. Checks Run

- Windows incoming pre-test -> 625 seconds overall, including 375 seconds for
  vignettes; one NOTE plus the 11-minute wrapper NOTE.
- Debian incoming pre-test -> one DESCRIPTION/new-submission NOTE; all
  substantive checks passed.
- `Rscript --vanilla -e 'devtools::document()'` -> clean regeneration.
- `Rscript --vanilla -e 'devtools::test(stop_on_failure=TRUE)'` -> 827 passes,
  zero failures/warnings/skips in 117.9 seconds.
- `Rscript --vanilla -e 'devtools::check()'` -> `Status: OK`, 0 errors,
  0 warnings, 0 notes in 5 minutes 19.8 seconds; vignette rebuild 76 seconds.
- `Rscript --vanilla -e 'pkgdown::check_pkgdown()'` -> no problems.
- `Rscript --vanilla tools/build-site.R` -> site built and privacy cleanup
  passed. URL check retained seven publisher DOI 403 responses and one transient
  GNU TLS connection failure; these are external endpoint behavior, not broken
  package targets.
- `R CMD build .` -> exact tarball SHA-256
  `e3b38efb954e3292d814c897c2af8620b967ff2ffa72a753bf18c3ab886f62be`,
  212 entries, about 1.5 MiB.
- `R CMD check --as-cran freqTLS_0.1.0.tar.gz` -> 0 errors, 0 warnings,
  1 NOTE (`New submission`); no spell flags; tests 34 seconds and vignettes
  77 seconds wall.
- Clean installation and neutral-directory rendering of the installed main and
  summary vignettes -> passed; cache row counts 12/8; SVG 69/27/0.

## 6. Tests of the Tests

The new installed-cache test checks schema/version/source metadata, all three
input checksums, exact 12/8 row counts, finite estimates and endpoints, headline
profile status, both contrast methods, and valid method/status pairs. The test
would fail for the earlier assumed `closed` status or if bootstrap fallback were
silently relabelled as profile. Directed group tests independently compare both
profile and bootstrap `A-B` estimates against fitted group A minus group B, so
the pre-correction sign convention would fail. Existing bootstrap, group, profile, random-
effect, and malformed-input tests remain enabled and account for the increase
from 800 to 827 passing assertions.

## 7a. Issue Ledger

- `CRAN-SPELL`: fixed; strict incoming feasibility reports no misspellings.
- `CRAN-TIME`: locally fixed; vignette rebuilding fell from the incoming
  Windows 375 seconds to 77 seconds on local strict check and 165 seconds on
  final win-builder; total win-builder checking took 431 seconds.
- `CONTRAST-METHOD-CLAIM`: fixed; seven bootstrap-fallback rows are labelled
  bootstrap rather than profile.
- No open GitHub issue overlapped this focused resubmission fix.

## 8. Consistency Audit

The component ledger and COPYRIGHTS now include the new cache and its upstream
CC BY 4.0 dependencies. Current decisions, release gates, check log, CRAN
comments, vignette prose, cache metadata, generator, and installed-data test
describe the same replacement candidate. Historical reports remain unchanged;
the dated decision and this report supersede their earlier explain-only stance
on the spell flags. README, NEWS, roadmap, capability matrix, and public site do
not claim that freqTLS is on CRAN.

## 9. What Did Not Go Smoothly

The first CRAN upload had passed ordinary win-builder with one explained NOTE,
but the incoming wrapper treated the 11-minute Windows runtime as an additional
issue and rejected it. Timing the whole article first obscured the real source;
chunk timing showed that contrast requests triggered repeated 1,000-refit bootstrap
fallbacks. Two long cache builds were started while process output was delayed;
only one remained active and completed. The deeper audit also exposed the stale
all-profile claim, which was corrected rather than hidden.

## 10. Known Residuals

The replacement has passed final-head GitHub CI, R-hub, win-builder timing, and
fresh Grace/Rose/Pat resubmission audits. It has not yet been resubmitted to
CRAN. CRAN acceptance and public package/check pages remain open.

## 11. Team Learning

Memory receipt: the repository AGENTS contract, ultra-plan,
release-readiness-review, after-task-audit, and prose-style-review procedures
shaped the work. The Rose sweep converted a timing issue into an accuracy fix by
checking what the expensive contrast calls actually returned.

Golden Set: not in scope; no cross-repository known-mistake class or model
class changed. Grouped profile and bootstrap contrast semantics did change; the
directed contrast tests are their regression guard. The deterministic cache test
separately guards the release-specific artifact and its provenance.

## 12. Cross-Product Coverage

Covers: DESCRIPTION incoming spelling; cross-case shrimp, life-stage zebrafish,
and sex-grouped *D. suzukii* summaries; headline profiles; contrast profile
requests and bootstrap fallback; installed cache provenance; package tests;
vignettes; pkgdown; exact source inventory; clean installation; and local strict
CRAN checking.

This does NOT cover CRAN acceptance, mirror propagation, or public CRAN
package/check pages.
