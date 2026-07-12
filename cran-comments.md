## Test environments

- local macOS Tahoe 26.5.2, R 4.6.0 (aarch64)
- GitHub Actions: Ubuntu R release and devel, Windows R release, macOS R release
  (all passed at release commit `3fe45a9`)
- R-hub Ubuntu/clang (passed at release commit `3fe45a9`)
- win-builder R-devel, R Under development r90235 (1 NOTE)

## R CMD check results

The exact local candidate tarball (SHA-256
`1a8d1248a9517e2ba6df2cc595e181d3cc9846f52b868fdec61caac55326b331`)
produced:

```
0 errors | 0 warnings | 1 note
```

The local NOTE is the expected incoming-check message: "New submission". The
win-builder NOTE contains the same message and flags `TLS` and the valid British
spelling `reparameterised` as possibly misspelled words in DESCRIPTION. There
are no downstream dependencies. The replacement win-builder run installed the
package and passed compiled-code checks, examples, tests, vignette rebuilding,
and both manuals.

## Additional notes

`freqTLS` uses Template Model Builder through the CRAN packages `TMB` and
`RcppEigen`. Bayesian comparison results shown in vignettes are maintainer-built
caches; `bayesTLS`, Stan, and CmdStan are not package dependencies and are not
run during installation, examples, tests, or vignette building.
