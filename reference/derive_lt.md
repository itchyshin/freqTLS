# Derive the lethal / survival-threshold duration at a temperature

`derive_lt()` solves the fitted 4PL for the duration at which survival
crosses a target probability `p` at a given temperature (an "LT" /
lethal- time-style quantity, e.g. `p = 0.5` gives the absolute 50%
survival time). To obtain the curve's relative midpoint, use
`p = (low + up) / 2`; that crossing has `log10(duration) = mid` exactly.

## Usage

``` r
derive_lt(object, p = 0.5, temp, group = NULL)
```

## Arguments

- object:

  A `profile_tls` fit from
  [`fit_tls()`](https://itchyshin.github.io/freqTLS/reference/fit_tls.md).

- p:

  Absolute target survival probability in `(low, up)` (default `0.5`).

- temp:

  Numeric temperature(s) at which to solve.

- group:

  Optional single group level (grouped fits only). Required when the fit
  is grouped.

## Value

A numeric vector of durations (same length as `temp`) on the data's
native time unit.

## Details

Survival follows
`p = low + (up - low) * plogis(-k (log10(duration) - mid))`, so the
duration at which survival equals a target `p` solves
\$\$\log\_{10}(duration) = mid - \mathrm{qlogis}\\\left(\frac{p -
low}{up - low}\right) / k.\$\$ The target must lie strictly between
`low` and `up` for a finite crossing; otherwise the survival curve never
reaches `p` and `derive_lt()` aborts with an explanatory message
(confidence-language, never silent). For a random-effects fit this is a
population-level derived quantity; it does not add a group BLUP (best
linear unbiased predictor; see
[`ranef()`](https://itchyshin.github.io/freqTLS/reference/ranef.md)).

## Examples

``` r
d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
               family = "binomial", tref = 60)
# Absolute 50% survival duration at 36 C:
derive_lt(fit, p = 0.5, temp = 36)
#> [1] 0.9555978
```
