# Predict a survival surface over a temperature-by-duration grid

`predict_survival_surface()` evaluates the fitted survival probability
on a factorial grid of temperatures by durations, returning a long data
frame suitable for a heatmap or contour plot (see
[`plot_survival_surface()`](https://itchyshin.github.io/freqTLS/dev/reference/plot_survival_surface.md)).
For random-effects fits this helper returns population-level predictions
(random intercepts set to zero); use
`predict(..., re.form = "conditional")` for known-group conditional
predictions. General continuous fixed designs require
[`predict()`](https://rdrr.io/r/stats/predict.html) with their covariate
columns supplied in `newdata`.

## Usage

``` r
predict_survival_surface(object, temps = NULL, times = NULL, group = NULL)
```

## Arguments

- object:

  A `profile_tls` fit from
  [`fit_tls()`](https://itchyshin.github.io/freqTLS/dev/reference/fit_tls.md).

- temps:

  Numeric vector of temperatures. Defaults to a length-60 sequence
  spanning the fit's observed temperature range.

- times:

  Numeric vector of durations (strictly positive). Defaults to a
  length-60 log-spaced sequence spanning the fit's observed duration
  range.

- group:

  Optional single group level (grouped fits only). When `NULL` (default)
  the surface is built for every group level and the result carries a
  `group` column.

## Value

A long `data.frame` with columns `temp`, `duration`, `survival` (and
`group` when the fit is grouped).

## Examples

``` r
d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
               family = "binomial", tref = 1)
head(predict_survival_surface(fit, temps = c(34, 36, 38), times = c(1, 2, 4)))
#>   temp duration   survival
#> 1   34        1 0.89445180
#> 2   36        1 0.47691987
#> 3   38        1 0.09003950
#> 4   34        2 0.69738630
#> 5   36        2 0.18571146
#> 6   38        2 0.03695279
```
