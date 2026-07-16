# Derive the temperature giving a target survival at a fixed exposure

`derive_ctmax()` inverts the fitted 4PL for **temperature**: it returns
the assay temperature at which survival equals a target `surv` after
exposure `duration`. By default `surv` is the *relative* midpoint
threshold `(low + up) / 2` and `duration` is `tref`, so
`derive_ctmax(fit)` reproduces the fitted `CTmax`. Supplying an
**absolute** `surv` gives the absolute- threshold critical temperature
(the analogue of the `bayesTLS`
[`extract_tdt()`](https://itchyshin.github.io/freqTLS/reference/extract_tdt.md)
absolute mode), with the asymmetry correction
`qlogis((surv - low) / (up - low)) / k` built in.

## Usage

``` r
derive_ctmax(object, surv = NULL, duration = NULL, group = NULL)
```

## Arguments

- object:

  A `profile_tls` fit from
  [`fit_tls()`](https://itchyshin.github.io/freqTLS/reference/fit_tls.md).

- surv:

  Target survival probability in `(low, up)`. `NULL` (default) uses the
  relative midpoint `(low + up) / 2`, reproducing `CTmax` at `tref`.

- duration:

  Exposure duration(s) (native time unit; strictly positive). Defaults
  to the fit's `tref`.

- group:

  Optional single group level (grouped fits only).

## Value

A numeric vector of temperatures (degrees C), one per `duration`.

## Details

Solving `surv = low + (up - low) * plogis(-k (log10(duration) - mid))`
with `mid = log10(tref) - (temp - CTmax) / z` for the temperature gives
\$\$temp = CTmax - z\Big(\log\_{10} duration - \log\_{10} t\_{ref} +
\mathrm{qlogis}\\\big(\tfrac{surv - low}{up - low}\big) / k\Big).\$\$
The target `surv` must lie strictly between `low` and `up`. For a
random-effects fit this is a population-level derived quantity; it does
not add a group BLUP.

## Examples

``` r
d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
               family = "binomial", tref = 1)
derive_ctmax(fit)                                  # ~ CTmax (relative, at tref)
#> [1] 35.92586
derive_ctmax(fit, surv = 0.5, duration = c(1, 4))  # absolute 50% survival
#> [1] 35.92114 33.51409
```
