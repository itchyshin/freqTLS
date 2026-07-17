# Predict the fitted survival surface with bootstrap confidence bands

The frequentist analogue of `bayesTLS::predict_survival_curves()`.
Evaluates the fitted 4PL survival probability over a
temperature-by-duration grid and adds parametric-bootstrap confidence
bands. For random-effects fits the curves are population-level: random
intercepts are integrated during bootstrap refits, but no fitted group
BLUP is added to the reported curve.

## Usage

``` r
predict_survival_curves(
  object,
  temps = NULL,
  durations = NULL,
  nboot = 500L,
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

- temps:

  Temperatures to predict at (default: the observed assay temps).

- durations:

  Exposure durations (default: 100 points log-spaced over the observed
  range, in the data's duration unit).

- nboot:

  Number of bootstrap replicates for the bands (default 500).

- level:

  Confidence level (default 0.95).

- seed:

  Optional RNG seed.

- by:

  Optional name for the grouping column.

## Value

A `freq_surv_curves` object: `$summary` (a tibble of
`[<group>,] temp, duration, survival_lower, survival_median, survival_upper`)
and `$meta`.

## See also

[`fit_4pl()`](https://itchyshin.github.io/freqTLS/reference/fit_4pl.md),
[`predict_survival_surface()`](https://itchyshin.github.io/freqTLS/reference/predict_survival_surface.md),
[`tls()`](https://itchyshin.github.io/freqTLS/reference/tls.md)

## Examples

``` r
# \donttest{
raw <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
dat <- standardize_data(
  raw, temp = "temp", duration = "duration",
  n_total = "total", n_surv = "survived"
)
fit <- fit_4pl(dat, family = "binomial", t_ref = 1, quiet = TRUE)
curves <- predict_survival_curves(
  fit, temps = c(34, 36), durations = c(1, 4), nboot = 10, seed = 1
)
curves$summary
#> # A tibble: 4 × 5
#>    temp duration survival_lower survival_median survival_upper
#>   <dbl>    <dbl>          <dbl>           <dbl>          <dbl>
#> 1    34        1         0.868           0.888          0.919 
#> 2    36        1         0.433           0.470          0.518 
#> 3    34        4         0.331           0.363          0.399 
#> 4    36        4         0.0452          0.0641         0.0773
# }
```
