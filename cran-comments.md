## Test environments

- local macOS Tahoe 26.5.2, R 4.6.0 (aarch64)
- GitHub Actions run `29543780687` passed Ubuntu release/devel, Windows release,
  and macOS release on PR head `99da90b`, whose package source tree was merged
  unchanged as `562cb027ced270e6ef32aaee265094f2d760b580`

## R CMD check results

The exact post-merge local tarball (SHA-256
`0b97a520a7dff05d859fa36a30fa7ea7cd304159e9dcf91d9679567ed1f0a5aa`)
produced:

```
0 errors | 0 warnings | 1 note
```

The NOTE is the expected incoming-check message: "New submission". There are no
downstream dependencies.

This is technical-candidate evidence only. Before upload, Dan must finalise the
author order and the authors must approve the resulting `Authors@R` metadata.

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
