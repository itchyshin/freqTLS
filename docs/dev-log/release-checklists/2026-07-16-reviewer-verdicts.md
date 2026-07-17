# Grace / Rose / Pat release verdicts — 0.1.0 merged technical candidate

Candidate package artifact: `freqTLS_0.1.0.tar.gz`, SHA-256
`0b97a520a7dff05d859fa36a30fa7ea7cd304159e9dcf91d9679567ed1f0a5aa`.

| Verifier | Evidence reviewed | Verdict |
| --- | --- | --- |
| Grace | strict post-merge `R CMD check --as-cran` is 0 errors, 0 warnings, one ordinary new-submission NOTE; tarball inventory/exclusions and pkgdown pass; Actions run `29543780687` passed Ubuntu release/devel, Windows release, and macOS release | **platform-clean technical candidate** — upload remains blocked only by final author metadata |
| Rose | 47 exports have Rd aliases; generated site has no internal-page leak or stale release/rights hits; component ledger and exact tarball exclusion scan agree | **submission-surface complete** — no source, rights, or reader-surface discrepancy remains in the merged candidate |
| Pat | fresh installation exercised `simulate_tls()`, `fit_tls()`, Wald confidence intervals, and `check_tls()`; installed-tarball examples, `donttest` examples, and all vignettes passed | **first-workflow passed** — weak-identification recovery guidance is present in help and site surfaces |

Combined verdict: **technical candidate complete; upload NOT READY**. Dan must
resolve the final author order, then the authors must approve the resulting
`Authors@R` metadata before upload. No row above claims CRAN acceptance or
public availability.
