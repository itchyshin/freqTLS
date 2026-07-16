```text
🎯 GOAL
Codex, working as the sole owner in the freqTLS repository, will turn the
experimental 0.1.0 release into a CRAN-shaped candidate without changing its
shipped expanded model surface. HEADLINE: reconcile the authoritative release
contract with the tested beta, formula, bootstrap, prediction, and limited
random-intercept capabilities, then audit every function document and pkgdown
reader page against that contract. IN PARALLEL: no parallel writers, because this
shared worktree has unrelated local changes; perform only read-only audits in
parallel where safe. DEFER: platform evidence, submission, and public deployment
remain fenced until one exact clean tarball exists. DISCIPLINE: validate each
source/tarball claim against the built artifact, keep the CRAN verdict NOT READY
until the gate evidence exists, and close with check-log and after-task records.
```

# Ultra-plan: CRAN remediation for the expanded 0.1.0 surface

Status: active  
Owner: Codex (single writer)  
Release profile: first CRAN submission; compiled TMB code, vendored data, cached
benchmark, package vignettes, no live network requirement at run time.

## Prior-work sweep

- The July 11 landing-page audit identified scope drift, a non-CRAN `bayesTLS`
  Suggest, a 12.6 MB source tarball, missing submission records, URL/licence
  review, and Ubuntu-only evidence.
- The July 16 roxygen repair closed the two Rd-generation warnings.
- `origin/main` already contains the historical v0.2 parity work; this branch's
  unique content is the landing-page and roxygen repairs. Reconcile history only
  after unrelated local edits are protected.
- The CRAN release gate is fail-closed: current verdict is **NOT READY**.

## Slices

| Slice | Owner / routing | Output | Dependency |
| --- | --- | --- | --- |
| S1 scope | Ada / native, inherited | AGENTS, SPEC, limitations, capability matrix, decision record agree on the expanded 0.1.0 surface | user decision (received) |
| S2 reference audit | Ada / native, inherited | exported-function inventory, roxygen/Rd/reference consistency ledger | S1 public boundary |
| S3 pkgdown audit | Ada / native, inherited | article inventory, rendered-site review, stale-claim and asset ledger | S1, S2 |
| S4 dependencies and tarball | Ada / native, inherited | final `Suggests` policy, `.Rbuildignore`, built-tarball inventory | S1 |
| S5 rights and metadata | Ada / native, inherited | component ledger, submission records, authorship/copyright flags | S1, S4 |
| S6 verification | Ada / native, inherited | exact local checks and a release-rung report | S1-S5; clean candidate |

The implementation owner is the only writer. Three bounded read-only audits
(rights/provenance, function-reference, and rendered-site surface) may run in
parallel; their findings are consolidated into the ledgers before edits. This
keeps the shared dirty worktree safe while retaining the planned independent
checks.

## Verification and closure

Run the document, test, package-check, pkgdown, built-tarball, and exact-artifact
checks that apply to the changed candidate. Do not claim platform-clean,
submission-ready, submitted, or live status without their separate evidence.
