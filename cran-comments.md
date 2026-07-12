## Test environments

- local macOS Tahoe 26.5.2, R 4.6.0 (aarch64)
- GitHub Actions: Ubuntu R release and devel, Windows R release, macOS R release
  (pending the candidate PR)
- win-builder R-devel and R-hub Linux/clang (pending)

## R CMD check results

The exact local candidate tarball produced:

```
0 errors | 0 warnings | 1 note
```

The NOTE is the expected incoming-check message: "New submission". There are no
downstream dependencies. Platform results will be added before submission.

## Additional notes

`freqTLS` uses Template Model Builder through the CRAN packages `TMB` and
`RcppEigen`. Bayesian comparison results shown in vignettes are maintainer-built
caches; `bayesTLS`, Stan, and CmdStan are not package dependencies and are not
run during installation, examples, tests, or vignette building.
