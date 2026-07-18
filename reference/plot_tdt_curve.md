# Plot the thermal death-time (TDT) curve: survival-threshold time vs temperature

`plot_tdt_curve()` draws the duration at which survival crosses a target
probability `p` against temperature – the classic thermal-death-time
line, here read directly off the fitted 4PL via
[`derive_lt()`](https://itchyshin.github.io/freqTLS/reference/derive_lt.md).
With the default `p = NULL`, each line uses its fitted relative midpoint
`(low + up) / 2`, not necessarily absolute 50% survival. Supply a
numeric `p` for an absolute survival threshold. Time is shown on a log10
axis. For a grouped fit a line is drawn per group.

## Usage

``` r
plot_tdt_curve(fit, p = NULL, temps = NULL, ...)
```

## Arguments

- fit:

  A `profile_tls` fit from
  [`fit_tls()`](https://itchyshin.github.io/freqTLS/reference/fit_tls.md).

- p:

  `NULL` (default) for the fitted relative midpoint, or an absolute
  target survival probability in `(0, 1)`.

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
