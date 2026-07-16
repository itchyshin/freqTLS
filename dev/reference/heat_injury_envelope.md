# Parametric-bootstrap confidence envelope for a heat-injury trajectory

`heat_injury_envelope()` is the uncertainty counterpart of
[`predict_heat_injury()`](https://itchyshin.github.io/freqTLS/dev/reference/predict_heat_injury.md):
it redraws the fitted curve parameters by parametric bootstrap (the same
machinery [`confint()`](https://rdrr.io/r/stats/confint.html) uses),
re-integrates the survival trajectory under the temperature `trace` for
each draw with the documented dose-accumulation map, and returns a
pointwise confidence band around the point-estimate survival curve. The
band is **prior-free** – it carries no prior and makes no probability
statement about the parameters; it is the likelihood-path analogue of
the `bayesTLS` posterior survival band, **not** a credible band.

## Usage

``` r
heat_injury_envelope(
  object,
  trace,
  group = NULL,
  target_surv = NULL,
  t_c = NULL,
  repair = NULL,
  irreversible = TRUE,
  nboot = 1000L,
  conf.level = 0.95,
  seed = NULL
)
```

## Arguments

- object:

  A `profile_tls` fit from
  [`fit_tls()`](https://itchyshin.github.io/freqTLS/dev/reference/fit_tls.md),
  or a `freq_tls` workflow from
  [`fit_4pl()`](https://itchyshin.github.io/freqTLS/dev/reference/fit_4pl.md).

- trace:

  A data frame with numeric columns `time` (strictly increasing, at
  least two rows) and `temp` (degrees C).

- group:

  Optional single group level (grouped fits only; required when the fit
  is grouped).

- target_surv:

  Optional absolute survival threshold defining one lethal dose: a
  single probability strictly between the fitted lower and upper
  asymptotes. `NULL` (default) uses the project-default relative
  threshold (the curve midpoint `(low + up) / 2`), matching
  [`derive_ctmax()`](https://itchyshin.github.io/freqTLS/dev/reference/derive_ctmax.md)
  and
  [`derive_lt()`](https://itchyshin.github.io/freqTLS/dev/reference/derive_lt.md).

- t_c:

  Optional damage-cutoff temperature (degrees C): at or below it the
  damage rate is zero. `NULL` (default) applies no cutoff.

- repair:

  Optional named list of Sharpe-Schoolfield repair parameters (see
  Details); `NULL` (default) means no repair.

- irreversible:

  Logical; if `TRUE` (default) survival is monotone non-increasing
  (mortality does not reverse even if dose is repaired).

- nboot:

  Number of bootstrap replicates (default `1000`).

- conf.level:

  Width of the pointwise confidence band (default `0.95`).

- seed:

  Optional integer seed; when supplied the bootstrap is reproducible
  without disturbing the caller's random stream.

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) with
`time`, `temp`, `survival` (the point-estimate trajectory from
[`predict_heat_injury()`](https://itchyshin.github.io/freqTLS/dev/reference/predict_heat_injury.md)),
and `conf.low` / `conf.high` (the pointwise parametric-bootstrap
confidence band).

## See also

[`predict_heat_injury()`](https://itchyshin.github.io/freqTLS/dev/reference/predict_heat_injury.md)
for the point trajectory,
[`plot_heat_injury()`](https://itchyshin.github.io/freqTLS/dev/reference/plot_heat_injury.md)
to draw the band.

## Examples

``` r
d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
               family = "binomial", tref = 1)
trace <- data.frame(time = seq(0, 2, by = 0.1),
                    temp = 34 + 6 * sin(seq(0, 2, by = 0.1)))
heat_injury_envelope(fit, trace, nboot = 50, seed = 1)
#> # A tibble: 21 × 5
#>     time  temp survival conf.low conf.high
#>    <dbl> <dbl>    <dbl>    <dbl>     <dbl>
#>  1   0    34      0.977    0.963     0.994
#>  2   0.1  34.6    0.977    0.963     0.992
#>  3   0.2  35.2    0.973    0.960     0.985
#>  4   0.3  35.8    0.962    0.946     0.973
#>  5   0.4  36.3    0.935    0.913     0.954
#>  6   0.5  36.9    0.878    0.837     0.911
#>  7   0.6  37.4    0.776    0.718     0.832
#>  8   0.7  37.9    0.629    0.556     0.697
#>  9   0.8  38.3    0.462    0.391     0.529
#> 10   0.9  38.7    0.314    0.251     0.375
#> # ℹ 11 more rows
```
