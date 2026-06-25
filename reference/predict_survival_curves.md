# Predict the fitted survival surface with bootstrap confidence bands

The frequentist twin of `bayesTLS::predict_survival_curves()`. Evaluates
the fitted 4PL survival probability over a temperature-by-duration grid
and adds parametric-bootstrap confidence bands.

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
