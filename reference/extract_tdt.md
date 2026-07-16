# Extract z, CTmax and (optionally) T_crit with bootstrap confidence intervals

The frequentist analogue of `bayesTLS::extract_tdt()`. Runs a parametric
bootstrap (via the freqTLS engine), derives the thermal-death-time
quantities on each replicate, and returns the same nested `$z` /
`$CTmax` / `$T_crit` structure (each a list of `draws` + `summary`). The
per-replicate tables are the frequentist analogue of posterior draws;
`*_median` is the maximum-likelihood point estimate and `*_lower` /
`*_upper` are bootstrap percentiles.

## Usage

``` r
extract_tdt(
  object,
  target_surv = "relative",
  lethal = FALSE,
  TC_rate_range = c(0.1, 1),
  nboot = 1000L,
  level = 0.95,
  seed = NULL,
  by = NULL
)
```

## Arguments

- object:

  A `freq_tls` fit from
  [`fit_4pl()`](https://itchyshin.github.io/freqTLS/reference/fit_4pl.md)
  (or a `profile_tls` fit).

- target_surv:

  `"relative"` (curve midpoint, default), `"absolute"` (50% survival),
  or a numeric survival level in `(0, 1)` for an LTx CTmax.

- lethal:

  If `TRUE`, also derive `T_crit` (the damage-rate-floor critical
  temperature, `CTmax + z * log10(rate / 100)`, `rate` log-uniform over
  `TC_rate_range`), anchored at the fit's reference time.

- TC_rate_range:

  Damage-rate floor range (percent of lethal dose per hour) for
  `T_crit`. Default `c(0.1, 1)`.

- nboot:

  Number of bootstrap replicates (default 1000; smaller is faster).

- level:

  Confidence level (default 0.95).

- seed:

  Optional RNG seed for reproducible replicates / rate draws.

- by:

  Optional name for the grouping column; defaults to the fit moderator.

## Value

A list with `$z`, `$CTmax`, (`$T_crit` when `lethal`), and `$meta`. Each
quantity is `list(draws = <tibble>, summary = <tibble>)`. Column names
follow bayesTLS: `z_median/z_lower/z_upper` for z;
`temp_median/temp_lower/ temp_upper` for CTmax and T_crit; per-draw
value columns are `z` / `temp`.

## See also

[`fit_4pl()`](https://itchyshin.github.io/freqTLS/reference/fit_4pl.md),
[`tls()`](https://itchyshin.github.io/freqTLS/reference/tls.md),
[`get_z_summary()`](https://itchyshin.github.io/freqTLS/reference/tdt-accessors.md),
[`get_ctmax_summary()`](https://itchyshin.github.io/freqTLS/reference/tdt-accessors.md)

## Examples

``` r
# \donttest{
raw <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
dat <- standardize_data(
  raw, temp = "temp", duration = "duration",
  n_total = "total", n_surv = "survived"
)
fit <- fit_4pl(dat, family = "binomial", t_ref = 1, quiet = TRUE)
tdt <- extract_tdt(fit, nboot = 10, seed = 1)
tdt$CTmax$summary
#> # A tibble: 1 × 3
#>   temp_median temp_lower temp_upper
#>         <dbl>      <dbl>      <dbl>
#> 1        35.9       35.8       36.1
# }
```
