## Test environments

- local macOS Tahoe 26.5.2, R 4.6.0 (aarch64)
- GitHub Actions: Ubuntu R release and devel, Windows R release, macOS R release
- R-hub Ubuntu/clang
- win-builder R-devel

## R CMD check results

The exact local replacement tarball (SHA-256
`ad637914a1b59d93196a4193807ff5ece904705aec586c136ff62429f38ef994`)
produced:

```
0 errors | 0 warnings | 1 note
```

The NOTE is the expected incoming-check message: "New submission". There are no
downstream dependencies.

## Resubmission

This is a corrected resubmission after CRAN incoming pre-test
`freqTLS_0.1.0_20260712_135803`.

- DESCRIPTION was rewritten with scientifically equivalent wording so `TLS`
  and `reparameterised` no longer trigger spelling flags.
- The Windows pre-test took 625 seconds, including 375 seconds rebuilding
  vignettes. The cross-case-study synthesis now reads its freqTLS results from a
  version-stamped maintainer cache instead of redundantly recomputing three fits
  and 20 intervals during every check. The cache records input checksums,
  software/source versions, exact fit configuration, and actual interval
  methods. The full 827-test suite and individual case studies continue to run
  live fitting, profiling, bootstrap fallback, and failure paths.
- Two displayed 1,000-refit bootstrap recipes are intentionally not executed
  during package checks; their behavior remains covered by live tests.
- On the replacement candidate, strict local `R CMD check --as-cran` rebuilt
  all vignettes in 68 seconds and returned zero errors, zero warnings, and only
  the expected `New submission` NOTE.

## Additional notes

`freqTLS` uses Template Model Builder through the CRAN packages `TMB` and
`RcppEigen`. Bayesian comparison results shown in vignettes are maintainer-built
caches; `bayesTLS`, Stan, and CmdStan are not package dependencies and are not
run during installation, examples, tests, or vignette building.
