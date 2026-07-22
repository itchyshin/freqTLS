# Report identifiability diagnostics for a fitted model

`check_tls()` re-runs the data-adequacy diagnostics on a fitted
`profile_tls` object, including the two post-fit checks that
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

## Recovery guide

The warning code returned by `check_tls()` identifies the next action:

- `temps`: assay at least three distinct temperatures spanning the
  survival transition.

- `durations` / `durations_per_temp`: assay at least three distinct
  durations per temperature, with times on both sides of the transition.

- `no_mortality`: extend to hotter or longer exposures until mortality
  occurs.

- `all_mortality`: add cooler or shorter exposures that retain
  survivors.

- `threshold`: extend the design until observed survival straddles 0.5.

- `up_not_approached` / `low_not_approached`: add milder / harsher
  conditions approaching survival 1 / 0, or do not interpret that
  asymptote.

- `ctmax_extrapolated`: expand the assayed temperature range to bracket
  CTmax; otherwise report it explicitly as extrapolated.

- `phi_binomial_limit`: consider the simpler binomial family.

After changing the design or family, refit and rerun `check_tls()`. For
an existing data set that cannot be augmented, use the warning to limit
the scientific claim;
[`vignette("profile-likelihood")`](https://itchyshin.github.io/freqTLS/articles/profile-likelihood.md)
explains the strict `fallback = FALSE` diagnostic and the default
bootstrap recovery attempt.

## Examples

``` r
d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
               family = "binomial", tref = 60)
codes <- check_tls(fit)
#> Warning: A fitted CTmax (28.82) lies outside the assayed temperature range [30, 42].
#> ℹ Expand the assay range to bracket CTmax and refit; if that is impossible,
#>   report CTmax explicitly as an extrapolation and do not treat its interval as
#>   design-supported.
codes # character(0) means no data-adequacy diagnostic fired
#> [1] "ctmax_extrapolated"
```
