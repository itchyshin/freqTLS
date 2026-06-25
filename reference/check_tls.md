# Report identifiability diagnostics for a fitted model

`check_tls()` re-runs the data-adequacy diagnostics (SPEC.md S10, items
1-8) on a fitted `profile_tls` object, including the two post-fit checks
that
[`fit_tls()`](https://itchyshin.github.io/freqTLS/reference/fit_tls.md)
cannot run before the model exists: whether any fitted `CTmax` is
extrapolated beyond the assayed temperatures (item 7), and whether `phi`
has reached the binomial limit (item 8). Each concern is emitted as a
[`cli::cli_warn()`](https://cli.r-lib.org/reference/cli_abort.html). Use
it to audit a fit, or after
[`suppressWarnings()`](https://rdrr.io/r/base/warning.html) around
[`fit_tls()`](https://itchyshin.github.io/freqTLS/reference/fit_tls.md).

## Usage

``` r
check_tls(fit)
```

## Arguments

- fit:

  A `profile_tls` fit from
  [`fit_tls()`](https://itchyshin.github.io/freqTLS/reference/fit_tls.md),
  or a `freq_tls` workflow from
  [`fit_4pl()`](https://itchyshin.github.io/freqTLS/reference/fit_4pl.md).

## Value

Invisibly, a character vector of the diagnostic codes that fired.

## Details

The profile-geometry diagnostics (items 9-12) are emitted by
[`confint()`](https://rdrr.io/r/stats/confint.html) and
[`profile()`](https://rdrr.io/r/stats/profile.html) when those are
called, not here, because they require the profile likelihood.

## Examples

``` r
d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
               family = "binomial", tref = 1)
check_tls(fit)
```
