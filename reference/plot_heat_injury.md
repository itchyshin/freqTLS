# Plot a heat-injury survival trajectory with a bootstrap confidence band

`plot_heat_injury()` draws the point-estimate survival trajectory from
[`predict_heat_injury()`](https://itchyshin.github.io/freqTLS/reference/predict_heat_injury.md)
inside the pointwise parametric-bootstrap confidence band from
[`heat_injury_envelope()`](https://itchyshin.github.io/freqTLS/reference/heat_injury_envelope.md).
The band is prior-free – a confidence band, never a posterior / credible
band (the project's honest-uncertainty contract).

## Usage

``` r
plot_heat_injury(
  object,
  trace,
  group = NULL,
  target_surv = NULL,
  t_c = NULL,
  repair = NULL,
  irreversible = TRUE,
  nboot = 1000L,
  conf.level = 0.95,
  seed = NULL,
  time_div = 1,
  xlab = "Time",
  ylab = "Survival"
)
```

## Arguments

- object:

  A `profile_tls` fit from
  [`fit_tls()`](https://itchyshin.github.io/freqTLS/reference/fit_tls.md),
  or a `freq_tls` workflow from
  [`fit_4pl()`](https://itchyshin.github.io/freqTLS/reference/fit_4pl.md).

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
  [`derive_ctmax()`](https://itchyshin.github.io/freqTLS/reference/derive_ctmax.md)
  and
  [`derive_lt()`](https://itchyshin.github.io/freqTLS/reference/derive_lt.md).
  For a bootstrap envelope the target must also be attainable in every
  converged bootstrap refit; otherwise the function aborts rather than
  clipping an invalid refit's threshold.

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

- time_div:

  Optional positive divisor applied to `time` on the x-axis (for example
  `24` to show days when the trace is in hours); default `1`.

- xlab, ylab:

  Axis labels.

## Value

A `ggplot` object.

## See also

[`heat_injury_envelope()`](https://itchyshin.github.io/freqTLS/reference/heat_injury_envelope.md)
for the band data,
[`predict_heat_injury()`](https://itchyshin.github.io/freqTLS/reference/predict_heat_injury.md)
for the point trajectory.

## Examples

``` r
d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
               family = "binomial", tref = 1)
trace <- data.frame(time = seq(0, 2, by = 0.1),
                    temp = 34 + 6 * sin(seq(0, 2, by = 0.1)))
plot_heat_injury(fit, trace, nboot = 50, seed = 1)
```
