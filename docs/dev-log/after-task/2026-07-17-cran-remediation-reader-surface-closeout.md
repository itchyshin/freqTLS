# After-task report — 0.1.0 CRAN remediation and reader-surface closeout

## 1. Goal

Produce one truthful, auditable experimental 0.1.0 technical candidate: retain the expanded public API, document its boundaries, audit all exports and rendered pkgdown pages, and prove the distributed tarball excludes maintainer material.

## 2. Implemented

The merged release boundary, component-rights ledger, function/reference ledger, pkgdown-page ledger, and exact-candidate ledger now describe the same 0.1.0 package. Snow-gum remains shipped as a separately attributed CC BY-NC 4.0 teaching component under Pieter A. Arnold's authorisation. `bayesTLS` remains outside installed-package dependencies and is described only as a Bayesian comparison path.

## 3a. Decisions and Rejected Alternatives

The decision was to retain the expanded experimental 0.1.0 surface, ship Snow-gum under its separately recorded CC BY-NC 4.0 terms, and exclude maintainer tooling from the source package. We rejected changing the 4PL likelihood, its direct `CTmax`/`log_z` parameterisation, confidence-interval algorithms, or the 47 exported API entries: this was a release-truthfulness task, not a mathematical redesign. The public boundary remains binomial, beta-binomial, and beta responses; column/formula interfaces; fixed shape designs; supported independent random intercepts; Wald/profile/bootstrap confidence intervals; and deterministic heat-injury prediction. Unsupported combinations remain explicit.

## 4. Files Touched

The release ledgers, `cran-comments.md`, and `docs/dev-log/check-log.md` now carry the final post-merge artifact identity and platform evidence. This report records the completed audit and the remaining upload-only author-metadata gate.

## 5. Checks Run

- A clean detached checkout of merge commit `562cb027ced270e6ef32aaee265094f2d760b580` ran `devtools::document()` and `devtools::check_man()` successfully.
- `tools/build-site.R .` produced 103 HTML pages, including 15 articles and 82 reference pages; `pkgdown::check_pkgdown()` reported no problems.
- The rebuilt tarball is `/tmp/freqtls-postmerge-562cb02/freqTLS_0.1.0.tar.gz`, SHA-256 `0b97a520a7dff05d859fa36a30fa7ea7cd304159e9dcf91d9679567ed1f0a5aa`, 1,191,636 bytes, and 226 entries.
- Strict `R CMD check --as-cran --no-manual` reported 0 errors, 0 warnings, and the ordinary new-submission NOTE; tests, examples, `donttest` examples, and vignette rebuilding passed.
- GitHub Actions run `29543780687` passed Ubuntu release/devel, Windows release, and macOS release. Its PR head has no package-source difference from the merge commit.

## 6. Tests of the Tests

The strict tarball check exercises installed help, examples, tests, and vignettes rather than relying on source-only checks. The tarball exclusion scan is a negative test for governance, scripts, outputs, and internal material. The rendered-site scan checks built HTML for stale release claims and internal-page leaks. `git diff --check` found no whitespace errors.

## 7a. Issue Ledger

`gh issue list --repo itchyshin/freqTLS --state open --limit 50` returned no open issues. No issue was created or closed for this evidence-only closeout.

## 8. Consistency Audit

All 47 exports have generated Rd aliases and intended reference placement. The rendered site had no stale 0.2/release-block language and no leaked AGENTS, CLAUDE, or SPEC page. The remaining `posterior`/`credible` hits are deliberately limited to comparisons with `bayesTLS` or language that explicitly says a freqTLS Confidence Eye is not a posterior density. The function-map SVG and Confidence-Eye reference figure were visually inspected and remain legible.

## 9. What Did Not Go Smoothly

The original integration artifact was superseded when the release branch merged. The candidate was therefore rebuilt from a clean detached post-merge checkout, and all ledger references were updated to its new hash rather than carrying forward stale artifact evidence.

## 10. Known Residuals

This remains an experimental package and has not been submitted to CRAN. Final author order is not yet recorded in `Authors@R`; Dan will resolve it, then the authors must approve the resulting metadata before upload. That administrative step does not weaken the technical candidate, but it prevents an upload claim.

## 11. Team Learning

A release ledger must name the exact tarball, not merely a branch or a passing source check. A post-merge rebuild and an explicit package-tree comparison make platform evidence auditable when the CI run was initiated from the PR head.

## 12. Cross-Product Coverage

This arc covers the release boundary across DESCRIPTION, help/reference pages, articles, the rendered pkgdown site, the source tarball, rights records, and the supported macOS/Ubuntu/Windows check surfaces. It does NOT cover author-order selection, CRAN upload, CRAN incoming review, acceptance, archive status, or a live CRAN page. Dan finalises the author order, the authors approve the resulting `Authors@R` metadata, and the package is rebuilt only if that metadata changes package bytes.
