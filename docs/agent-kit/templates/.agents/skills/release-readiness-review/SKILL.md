---
name: release-readiness-review
description: Review an R package before a public, CRAN, GitHub, or internal release.
---

# Release Readiness Review

Use this skill before public releases, CRAN submissions, GitHub releases,
course handoffs, or lab-internal version tags.

## Required Checks

1. Confirm current branch and clean working tree.
2. Review `NEWS.md`, `README.md`, roadmap, known limitations, and pkgdown or
   Quarto site navigation.
3. Run package checks appropriate to the release:
   - `devtools::document()`
   - `devtools::test()`
   - `devtools::check()`
   - `pkgdown::check_pkgdown()` or equivalent
4. Check examples and vignettes for unsupported syntax or stale claims.
5. Check dependency versions and platform risks.
6. Confirm generated docs are up to date.
7. Record skipped checks and residual risks in the check log.

## Release Questions

- What is implemented, documented, and tested?
- What is planned but not implemented?
- What should users avoid?
- What changed since the previous release?
- What would make the release embarrassing if found tomorrow?
