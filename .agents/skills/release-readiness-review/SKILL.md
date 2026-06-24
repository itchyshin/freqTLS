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
5. Check dependency versions and platform risks; confirm CI is ubuntu-only,
   `[pull_request, workflow_dispatch]`, and Stan-free.
6. Confirm the benchmark cache provenance is current and the article reads the
   cache (no live Stan in CI).
7. Confirm the four bayesTLS framework authors are credited (Authors@R,
   Description, README) and the CC BY 4.0 data attribution is present
   (`R/data.R`, `inst/CITATION`).
8. Confirm the bayesTLS co-authors have agreed to being listed before any
   public release.
9. Record skipped checks and residual risks in the check log.

## Release Questions

- What is implemented, documented, and tested?
- What is planned but not implemented (the v0.1 non-goals)?
- What should users avoid (weakly identified designs; extrapolated CTmax)?
- What changed since the previous release?
- What would make the release embarrassing if found tomorrow?
