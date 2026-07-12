# After Task: CRAN completion-audit remediation

## 1. Goal

Close every package, documentation, licensing, and installed-user defect found
by the fresh Grace/Rose/Pat Sol completion audit, then build and verify one exact
freqTLS 0.1.0 source tarball without weakening CRAN checks.

## 2. Implemented

- Added parameter and return-value documentation to all three callable internal
  helpers that lacked it, plus a class-wide Rd tripwire.
- Replaced the broken README grouped-fit instruction with an executed,
  well-identified grouped simulation, standardization, fit, and estimate query.
- Expanded `predict.profile_tls` help to state every `newdata` fixed-design and
  random-effect requirement, the formula-object recovery boundary, and runnable
  continuous-design and population/conditional random-effect examples.
- Installed the canonical function-map SVG beside the vignette through R's
  supported `vignettes/.install_extras` mechanism and made the vignette locate
  either the build-time or installed asset.
- Moved two unused environmental traces out of `inst/extdata/` into the
  build-excluded licensing-pending tree because their complete underlying-data
  redistribution chains were not established.
- Reconciled SPEC authors/dependencies/data scope, provenance wording, the
  benchmark licensing statement, case-study article counts, the component
  ledger, current decisions, release gates, CRAN comments, and generated Rd/
  README files.

## 3a. Decisions and Rejected Alternatives

- Excluded the environmental traces instead of inferring that a workflow or
  repository licence covered every underlying environmental value. Restoring
  them requires compatible primary terms or written permission and a real
  installed consumer.
- Kept `cli` in `Imports`. The first win-builder result lacked the CRAN package
  `cli` in its server library and stopped before freqTLS installation; removing
  a legitimate dependency would hide an infrastructure failure and weaken the
  package.
- Used `.install_extras` instead of maintaining a duplicate `inst/doc` SVG.
  `R CMD build` consumes/cleans `inst/doc`; the supported vignette declaration
  keeps one canonical SVG and installs it deterministically.
- Enlarged the README grouped simulation after a minimal design executed but
  produced absurd CTmax/z estimates. A runnable example must also be
  scientifically interpretable.

## 4. Files Touched

Modified:

- `R/predict.R`, `R/standardize_data.R`, `R/tdt-utils.R`
- `README.Rmd`, `README.md`, `ROADMAP.md`, `SPEC.md`, `cran-comments.md`
- `docs/design/06-benchmark-protocol.md`,
  `docs/design/47-data-license-ledger.md`
- `docs/dev-log/after-task/2026-07-11-cran-readiness-implementation.md`,
  `docs/dev-log/check-log.md`, `docs/dev-log/decisions.md`,
  `docs/dev-log/known-limitations.md`,
  `docs/dev-log/release-gates/2026-07-11-cran-0.1.0.md`
- `inst/COPYRIGHTS`
- `man/predict.profile_tls.Rd`, `man/standardize_data.Rd`,
  `man/tdt_check_columns.Rd`, `man/tdt_format_random_effects.Rd`,
  `man/tdt_random_effect_variables.Rd`
- `tests/testthat/test-doc-consistency.R`, `vignettes/freqTLS.Rmd`

Added:

- `vignettes/.install_extras`
- `data-raw/licensing-pending/environmental-traces/README.md`
- `data-raw/licensing-pending/environmental-traces/data_temp_trace_aphid_summer2016.csv`
- `data-raw/licensing-pending/environmental-traces/orsted_2024/orsted2024_nichemapr_rennes_2018_hourly.csv.gz`
- this report

Removed from the installed package tree:

- `inst/extdata/data_temp_trace_aphid_summer2016.csv`
- `inst/extdata/orsted_2024/orsted2024_nichemapr_rennes_2018_hourly.csv.gz`

## 5. Checks Run

- `devtools::document()` regenerated the five affected Rd topics.
- Focused documentation/prediction/standardization tests: 94 passes, no
  failures, warnings, or skips.
- Extracted prediction examples ran successfully, including continuous-design
  and population/conditional random-effect predictions.
- Full `devtools::test()`: 800 passes, no failures, warnings, or skips.
- `devtools::check_man()`: clean.
- `devtools::check()`: 0 errors, 0 warnings, 0 notes in 5m49.9s.
- `pkgdown::check_pkgdown()`: no problems.
- `Rscript --vanilla tools/build-site.R`: full site build passed; privacy
  cleanup and changed reference pages passed.
- Neutral-directory render of the installed `freqTLS.Rmd`: passed; function map
  69 text nodes, 27 rectangles, 0 `em` nodes.
- Final `R CMD build .`: 1,551,284 bytes, 210 entries, SHA-256
  `1a8d1248a9517e2ba6df2cc595e181d3cc9846f52b868fdec61caac55326b331`.
- Final `R CMD check --as-cran freqTLS_0.1.0.tar.gz`: 0 errors, 0 warnings,
  exactly 1 expected `New submission` NOTE; examples, `--run-donttest`, tests,
  vignette rebuilds, and PDF/HTML manuals passed.
- Predecessor head `5d83d21` passed the four-platform GitHub matrix and R-hub
  Ubuntu/clang. Replacement-head reruns are still required.
- Replacement exact tarball upload to win-builder R-devel returned HTTP 200;
  result pending.

## 6. Tests of the Tests

- The first grouped README repair executed but yielded CTmax 17.1/52.3 and z
  approximately 1.9e9/3.8e4; rendering therefore caught a scientifically broken
  example even though the code did not error. The strengthened design recovers
  CTmax 35.1/38.0 and z 4.20/4.11.
- Before the SVG repair, the installed Rmd referenced a missing co-located file;
  the neutral-directory render is the independent failure path and now passes.
- The class-wide Rd guard enumerates every non-dataset topic with a `usage`
  block and fails if any lacks `value`; its initial over-broad form correctly
  exposed the six dataset-topic exception and was narrowed explicitly.
- Tarball inventory checks assert absence of every licensing-pending path and
  presence of both the canonical and installed SVG paths.

## 7a. Issue Ledger

- `GRACE-RD`: missing internal return-value documentation — fixed.
- `PAT-README`: unexecutable grouped-fit instruction — fixed and executed.
- `PAT-PREDICT`: incomplete fixed-design/formula prediction help — fixed and
  examples executed.
- `PAT-SVG`: installed main-vignette source missing its SVG dependency — fixed
  through `.install_extras` and independently rendered.
- `ROSE-TRACE`: two environmental traces lacked a complete redistribution chain
  and had no consumer — excluded and recorded.
- `ROSE-DRIFT`: SPEC/provenance/case-study counts stale — fixed across current
  canonical surfaces.
- `WIN-DEP`: first win-builder server lacked `cli` and `curl` — package was not
  tested; replacement submission pending. No GitHub issue was opened because
  this is an ephemeral external service state, not a repository defect.

## 8. Consistency Audit

Task-specific searches covered the broken README call, six-case-study wording,
stale planned provenance, removed trace names, snow-gum CC BY-NC wording,
prediction `newdata` requirements, and posterior/credible usage. The only trace
name hits now occur in the blocked component ledger/tree. The benchmark protocol
no longer generalizes the Orsted workflow licence to the excluded NCEP-derived
trace. Deliberate posterior/credible hits describe bayesTLS or contrast it with
freqTLS confidence intervals. Generated README, Rd, installed vignette, local
pkgdown site, tar inventory, and current release documents were all checked.

## 9. What Did Not Go Smoothly

The fresh auditors found several defects after a locally clean CRAN check,
showing that check success does not prove copy-paste usability, redistribution
authority, or installed-source reproducibility. The first README repair was too
small statistically. A direct `inst/doc` copy worked in one tarball but was
cleaned from the source by `R CMD build`, which led to adopting
`.install_extras`. The first win-builder attempt stopped before package checking
because its server library lacked ordinary CRAN dependencies.

## 10. Known Residuals

- The replacement head still needs four-platform GitHub and R-hub reruns.
- The replacement win-builder result is pending.
- Written `aut` consent from Pieter Arnold, Patrice Pottier, and Daniel Noble is
  still absent and blocks CRAN upload.
- The saved consent email remains an unsent draft pending maintainer approval.
- Final fresh Grace/Rose/Pat approval, PR merge/deployment verification, explicit
  CRAN-upload approval, CRAN submission, and public CRAN page verification remain.
- Seven DOI publisher endpoints return automated 403 responses; their Crossref
  registrations were manually verified.

## 11. Team Learning

Loaded the repo instructions plus ultra-plan, release-readiness,
prose-style-review, figure-visual-audit, and after-task-audit workflows. The hub
router returned no freqTLS LOAD-FIRST manifest, so repository files remained the
technical source of truth. Sol was reserved for the three independent,
release-blocking judgments; no simulation or Totoro/DRAC run was justified for
this packaging/licensing slice. The Golden Set was not applicable because no
known cross-repo model-code mistake class changed. Durable choices were recorded
in the repository decision log rather than hidden memory.

Memory receipt: the repo contract and the ultra-plan, release-readiness,
prose, figure, and after-task guards were loaded; they directly triggered the
fresh three-lens audit, installed-source render, licensing exclusion, stale-
wording sweep, and compliant report.

Golden Set: not in scope because this slice changed package release engineering,
documentation, and data packaging rather than a known cross-repo model-code
mistake class.

## 12. Cross-Product Coverage

- Prediction documentation covers ordinary, continuous fixed-design,
  population random-effect, and conditional known-group paths. It does NOT cover
  adding conditional behavior to the specialised surface, derived-quantity, or
  heat-injury helpers; those remain explicitly population-level.
- SVG installation covers source-tarball build, installed-package lookup,
  neutral-directory vignette rendering, and pkgdown inline output. It does NOT
  cover changing the function-map content or geometry.
- Licensing exclusion covers snow-gum, Kristineberg, and the two environmental
  traces in the CRAN tarball and installed workflows. It does NOT cover private
  research use or future restoration after compatible permission.
- Local checks cover macOS R-devel mechanics and the exact source tarball. They
  do NOT cover the pending replacement Windows, Linux/clang, GitHub matrix,
  collaborator-consent, CRAN-review, or public-page gates.
