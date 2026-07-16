## Test environments

* local macOS arm64, R 4.6.0 (Apple clang 21.0.0; macOS Tahoe 26.5.2)
* Windows and Ubuntu checks on the same frozen post-merge tarball are still
  required before submission.

## R CMD check results

`R CMD build --no-manual --sha256 .` produced `freqTLS_0.1.0.tar.gz`
(1,653,817 bytes; 210 entries; SHA-256
`53461c1bed3081e590f993665a63f733903cd791f08095bf35aaa3a759a7787b`).
`R CMD check --as-cran --no-manual freqTLS_0.1.0.tar.gz` completed with 0
errors, 0 warnings, and one ordinary first-submission NOTE. This is local
candidate evidence only: a clean post-merge rebuild, Windows/Ubuntu evidence,
URL review, final same-hash reviewer verdicts, and final author-order metadata
remain upload blockers.

## Downstream dependencies

There are no CRAN reverse dependencies for this first submission.

## Release boundary and provenance

freqTLS is an experimental maximum-likelihood TMB implementation of the
thermal-load-sensitivity framework introduced in bayesTLS. The package vendors
benchmark data and records its source and licence in `inst/COPYRIGHTS`,
`inst/CITATION`, and the data documentation. The maintainer must confirm that
all credited authors agree to their listed roles before submission. Shinichi
confirmed on 2026-07-16 that all credited co-authors have authorised package
use. The final author order is intentionally deferred for Dan to resolve before
submission; it must be reflected in `Authors@R` and approved by the authors
before upload.
