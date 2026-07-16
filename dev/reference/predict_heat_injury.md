# Predict cumulative heat injury under a temperature trace

`predict_heat_injury()` is the deterministic, maximum-likelihood
**prediction** analogue of `bayesTLS::predict_heat_injury()`: given a
fitted thermal-load- sensitivity curve and a temperature time-series (a
"trace"), it accumulates thermal damage as a fraction of the lethal dose
and reads survival back off the fitted 4PL. It does **not** fit an
injury or repair model – fitting injury / repair dynamics remains a
`bayesTLS` concern (the complementary boundary); `predict_heat_injury()`
only predicts injury from the already-fitted survival curve. For a
random-effects fit it uses the population curve and does not add a
fitted group BLUP.

## Usage

``` r
predict_heat_injury(
  object,
  trace,
  group = NULL,
  target_surv = NULL,
  t_c = NULL,
  repair = NULL,
  irreversible = TRUE
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

## Value

A data frame with columns `time`, `temp`, `dose` (cumulative, as a
fraction of the lethal dose), `injury` (`dose * 100`, percent), and
`survival`.

## Details

### Dose-accumulation model

One **lethal dose** is the thermal load that drives survival to a target
set by `target_surv`. With the default `target_surv = NULL` the target
is the project-default **relative** threshold – the curve midpoint
`(low + up) / 2`. At temperature `T` the lethal time to the target is
`LT(T) = tref * 10^((CTmax - T) / z - q / k)`, with
`q = qlogis((target_surv - low) / (up - low))` (so `q = 0` at the
midpoint, the same quantity as
[`derive_lt()`](https://itchyshin.github.io/freqTLS/dev/reference/derive_lt.md)
at survival `target_surv`). The instantaneous damage rate is `1 / LT(T)`
(lethal doses per time unit). Cumulative dose is accumulated by forward
Euler over the trace, using the actual per-step time increments: \$\$D_j
= \max\\\big(0,\\ D\_{j-1} + (\mathrm{dmg}(T\_{j-1}) -
\mathrm{rep}\_{j-1})\\\Delta t_j\big),\quad D_1 = 0,\$\$ where \\\Delta
t_j = t_j - t\_{j-1}\\. Survival is read back from the 4PL by treating
the accumulated dose as an equivalent `log10`-time:
`survival(D) = low + (up - low) * plogis(-k * log10(D) + q)`, so `D = 1`
(one lethal dose) reaches exactly `target_surv` – the relative midpoint
`(low + up) / 2` by default, or an **absolute** survival threshold when
`target_surv` is supplied.

The trace `time` and the fit's duration / `tref` **must share a time
unit** (the damage rate is per that unit). With `irreversible = TRUE`
(default) survival is monotone non-increasing. A damage cutoff `t_c`
(for example from
[`derive_tcrit()`](https://itchyshin.github.io/freqTLS/dev/reference/derive_tcrit.md))
sets the damage rate to zero at or below `t_c`.

This integrator is forward Euler (left-endpoint, per actual step), not
the single-`dt` scheme some implementations use; irregular traces are
integrated with their real increments.

### Repair (optional, not identified by the data)

If `repair` is supplied, a Sharpe-Schoolfield repair rate is subtracted
each step (scaled by the current survival fraction, so repair shrinks as
the population dies). The repair parameters are a **user-supplied
scenario layer**: they are not identified by the survival data the model
was fitted to, so `predict_heat_injury()` warns when they are used.
`repair` is a named list with `r_ref`, `t_a`, `t_al`, `t_ah`, `t_l`,
`t_h`, `t_ref`, with the four reference temperatures in **Kelvin**.

## See also

[`derive_lt()`](https://itchyshin.github.io/freqTLS/dev/reference/derive_lt.md)
for the lethal time,
[`derive_tcrit()`](https://itchyshin.github.io/freqTLS/dev/reference/derive_tcrit.md)
for a damage cutoff temperature.

## Examples

``` r
d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
               family = "binomial", tref = 1)
trace <- data.frame(time = seq(0, 2, by = 0.05),
                    temp = 34 + 6 * sin(seq(0, 2, by = 0.05)))
head(predict_heat_injury(fit, trace))
#>   time     temp       dose    injury  survival
#> 1 0.00 34.00000 0.00000000  0.000000 0.9773287
#> 2 0.05 34.29988 0.01649179  1.649179 0.9771725
#> 3 0.10 34.59900 0.03609257  3.609257 0.9765045
#> 4 0.15 34.89663 0.05937839  5.937839 0.9749591
#> 5 0.20 35.19202 0.08701822  8.701822 0.9720083
#> 6 0.25 35.48442 0.11978385 11.978385 0.9668946
```
