## Test environments

- local macOS Tahoe 26.5.2, R 4.6.0 (aarch64)
- GitHub Actions: Ubuntu R release and devel, Windows R release, macOS R release
  (the predecessor candidate passed all four; replacement-candidate rerun pending)
- R-hub Ubuntu/clang (the predecessor candidate passed; replacement rerun pending)
- win-builder R-devel (replacement candidate submitted; result pending)

## R CMD check results

The exact local candidate tarball (SHA-256
`1a8d1248a9517e2ba6df2cc595e181d3cc9846f52b868fdec61caac55326b331`)
produced:

```
0 errors | 0 warnings | 1 note
```

The NOTE is the expected incoming-check message: "New submission". There are no
downstream dependencies. A first win-builder attempt stopped before package
installation because its R-devel library lacked the CRAN package `cli`; the
same log also lacked `curl` for incoming URL checks. The package was not built
or tested in that attempt. The replacement tarball has been resubmitted and
platform results will be finalized before submission.

## Additional notes

`freqTLS` uses Template Model Builder through the CRAN packages `TMB` and
`RcppEigen`. Bayesian comparison results shown in vignettes are maintainer-built
caches; `bayesTLS`, Stan, and CmdStan are not package dependencies and are not
run during installation, examples, tests, or vignette building.
