# Grace / Rose / Pat release verdicts — 0.1.0 integration candidate

Candidate package artifact: `freqTLS_0.1.0.tar.gz`, SHA-256
`97a0684653c07ec064ebbd2eec885cd006ca7cfd3cbe31e85f818d28ec7cbbbd`.

| Verifier | Evidence reviewed | Verdict |
| --- | --- | --- |
| Grace | local `R CMD check --as-cran` is 0 errors, 0 warnings, one ordinary new-submission NOTE; tarball size/inventory/exclusions and local pkgdown pass | **NOT READY for upload** — matching Ubuntu, Windows, and macOS checks still need this candidate source |
| Rose | 47 exports have Rd aliases; generated site has no internal-page leak or stale release/rights hits; component ledger and tarball exclusion scan agree | **submission-surface complete locally** — hold final verdict until the exact candidate is cross-platform checked and author metadata is final |
| Pat | installed-tarball examples, `donttest` examples, and all vignettes passed under `R CMD check`; weak-identification recovery guidance appears in help/site audit | **NOT READY for sign-off** — an independent first-user walkthrough of the frozen install remains to be recorded |

External/upload gate: Dan will resolve final author order, then all credited
authors must approve the resulting `Authors@R` metadata before upload. No row
above claims CRAN acceptance or public availability.
