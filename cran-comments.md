## Test environments

- local macOS Tahoe 26.5.2, R 4.6.0 (aarch64)
- matching Ubuntu, Windows, and macOS checks: pending on the frozen candidate

## R CMD check results

The exact local integration tarball (SHA-256
`97a0684653c07ec064ebbd2eec885cd006ca7cfd3cbe31e85f818d28ec7cbbbd`)
produced:

```
0 errors | 0 warnings | 1 note
```

The NOTE is the expected incoming-check message: "New submission". There are no
downstream dependencies.

This is local candidate evidence only. Matching Windows, Ubuntu, and macOS
checks must run on the frozen candidate before upload.

## Resubmission

This candidate replaces earlier development and pre-test artifacts. Its public
surface uses experimental 0.1.0 wording, ships Snow-gum as a separately
attributed CC BY-NC 4.0 teaching component under the data-holder's recorded
authorization, and keeps `bayesTLS`/Stan outside package dependencies.

## Additional notes

`freqTLS` uses Template Model Builder through the CRAN packages `TMB` and
`RcppEigen`. Bayesian comparison results shown in vignettes are maintainer-built
caches; `bayesTLS`, Stan, and CmdStan are not package dependencies and are not
run during installation, examples, tests, or vignette building.
