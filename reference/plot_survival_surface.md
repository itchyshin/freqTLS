# Plot the fitted survival surface over temperature and duration

`plot_survival_surface()` draws the fitted survival probability as a
filled heatmap over a temperature-by-duration grid, with contour lines,
using
[`predict_survival_surface()`](https://itchyshin.github.io/freqTLS/reference/predict_survival_surface.md).
Duration is on a log10 axis. For a grouped fit the surface is faceted by
group.

## Usage

``` r
plot_survival_surface(fit, temps = NULL, times = NULL, contour = TRUE, ...)
```

## Arguments

- fit:

  A `profile_tls` fit from
  [`fit_tls()`](https://itchyshin.github.io/freqTLS/reference/fit_tls.md).

- temps, times:

  Numeric grids passed to
  [`predict_survival_surface()`](https://itchyshin.github.io/freqTLS/reference/predict_survival_surface.md).
  Defaults span the observed ranges.

- contour:

  Logical; overlay contour lines (default `TRUE`).

- ...:

  Reserved; must be empty.

## Value

A `ggplot` object.

## Examples

``` r
d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
               family = "binomial", tref = 60)
plot_survival_surface(fit)

```
