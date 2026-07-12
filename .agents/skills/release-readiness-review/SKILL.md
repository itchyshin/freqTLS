---
name: release-readiness-review
description: Review freqTLS before a public, CRAN, GitHub, or internal release.
---

# Release Readiness Review

Use this skill before public releases, GitHub releases, or version tags. Grace
leads; Rose audits claims; Pat and Fisher hold the Definition-of-Done gate.

## Required Checks

1. Confirm the current branch and a clean working tree.
2. Review `NEWS.md`, `README.Rmd` (and the rendered `README.md`), `ROADMAP.md`,
   `docs/dev-log/known-limitations.md`, `docs/design/46-capability-matrix.md`,
   and the `_pkgdown.yml` navigation.
3. Run the package checks appropriate to the release:
   - `devtools::document()`
   - `devtools::test()`
   - `devtools::check()`
   - `pkgdown::check_pkgdown()` and `pkgdown::build_site()`
4. Check examples and vignettes for unsupported syntax, stale claims, or any
   "posterior"/"credible" language describing a freqTLS interval.
5. Check dependency versions and platform risks; confirm the normal-Suggests CI
   matrix covers Ubuntu R release/devel, Windows R release, and macOS R release,
   and remains Stan-free.
6. Confirm the benchmark cache provenance is current and the article reads the
   cache (no live Stan in CI). Restrict equivalence claims to the matched
   relative-threshold, constant-shape model fits; identify the classical
   two-stage comparator as an absolute-LT50 approximation.
7. Audit every installed data/extdata component against
   `docs/design/47-data-license-ledger.md`, `R/data.R`, `inst/COPYRIGHTS`, and
   `inst/CITATION`. Confirm snow-gum remains labelled CC BY-NC 4.0 and that
   snow-gum, Kristineberg, or any other permission-pending asset is absent from
   the source tarball unless written redistribution authority is recorded.
8. Confirm Pieter A. Arnold, Patrice Pottier, and Daniel W. A. Noble have
   explicitly agreed to their `aut` roles before public release or CRAN upload.
9. Build one exact source tarball, record its checksum and inventory, and run
   `R CMD check --as-cran` on that file with normal Suggests. Require zero errors
   and warnings and explain every NOTE.
10. Before CRAN upload, require the candidate commit's GitHub platform matrix,
    win-builder R-devel, R-hub Linux/clang, and independent Grace/Rose/Pat
    completion verdicts. Record skipped checks and residual risks in the check
    log without describing pending gates as passed.

## Release Questions

- What is implemented, documented, and tested?
- What is planned but not implemented (the 0.1.0 non-goals)?
- What should users avoid (weakly identified designs; extrapolated CTmax)?
- What changed since the previous release?
- What would make the release embarrassing if found tomorrow?
