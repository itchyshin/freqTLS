# After Task: CRAN DESCRIPTION quotation follow-up

## 1. Goal

Apply CRAN's requested quotation cleanup to the next package source update
without changing the package names or the submitted 0.1.0 tarball.

## 2. Implemented

In DESCRIPTION, retained single quotes around `bayesTLS` and `freqTLS`, which
are package names. Removed them from Template Model Builder, TMB, and CTmax.

## 3. Mathematical Contract

No model, likelihood, parameterisation, interval, or API behaviour changed.

## 3a. Decisions and Rejected Alternatives

The change is restricted to DESCRIPTION. Editing the already-submitted tarball
or resubmitting version 0.1.0 was rejected: CRAN's version check confirms that
the same version is already in incoming processing.

## 4. Files Touched

`DESCRIPTION`, `docs/dev-log/check-log.md`, and this report.

## 5. Checks Run

`R CMD build --no-resave-data --no-manual .` built the source tarball with
valid DESCRIPTION metadata. `R CMD check --as-cran --no-manual
freqTLS_0.1.0.tar.gz` passed package checks, examples, tests, and vignettes.
The sole expected WARNING is the already-submitted 0.1.0 version.

## 6. Tests of the Tests

The strict check reads DESCRIPTION from the built tarball, so it verifies the
distributed metadata rather than only the working-tree text.

## 7a. Issue Ledger

No GitHub issue was opened: this is a direct minor CRAN follow-up recorded in
the check log and submitted for source review.

## 8. Consistency Audit

The wording now follows the requested package-name distinction in DESCRIPTION.
No public capability or release-boundary claim changed.

## 9. What Did Not Go Smoothly

The sandbox initially could not resolve CRAN or Bioconductor indexes; the
network-enabled rerun completed normally.

## 10. Known Residuals

The 0.1.0 tarball is already with CRAN. This source change requires a later
versioned update if it is ever submitted.

## 11. Team Learning

CRAN editorial feedback about DESCRIPTION is a source-maintenance item, not
authorization to mutate or relabel the artifact already under review.

## 12. Cross-Product Coverage

This task does NOT cover author order, citation policy, package behaviour,
CRAN upload, or CRAN acceptance.
