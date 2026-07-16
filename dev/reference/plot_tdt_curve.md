# Plot the thermal death-time (TDT) curve: survival-threshold time vs temperature

`plot_tdt_curve()` draws the duration at which survival crosses a target
probability `p` (default the relative midpoint, `p = 0.5`) against
temperature – the classic thermal-death-time line, here read directly
off the fitted 4PL via
[`derive_lt()`](https://itchyshin.github.io/freqTLS/dev/reference/derive_lt.md).
Time is shown on a log10 axis. For a grouped fit a line is drawn per
group.

## Usage

``` r
plot_tdt_curve(fit, p = 0.5, temps = NULL, ...)
```

## Arguments

- fit:

  A `profile_tls` fit from
  [`fit_tls()`](https://itchyshin.github.io/freqTLS/dev/reference/fit_tls.md).

- p:

  Target survival probability for the threshold (default `0.5`).

- temps:

  Numeric vector of temperatures. Defaults to a sequence over the
  observed temperature range.

- ...:

  Reserved; must be empty.

## Value

A `ggplot` object.

## Examples

``` r
d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
               family = "binomial", tref = 1)
plot_tdt_curve(fit)

```
