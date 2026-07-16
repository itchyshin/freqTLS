# Thermal-load-sensitivity quantities (z, CTmax) with confidence intervals

The frequentist twin of `bayesTLS::tls()`. Reads a
[`fit_4pl()`](https://itchyshin.github.io/freqTLS/reference/fit_4pl.md)
(`freq_tls`) fit and returns the headline thermal-death-time quantities
— thermal sensitivity `z` and `CTmax` — as point estimates with
confidence intervals, one row per group when the fit is grouped.
Uncertainty uses the engine's profile-likelihood intervals by default
(or Wald / bootstrap via `method`).

## Usage

``` r
tls(
  object,
  by = NULL,
  params = c("all", "z", "ctmax"),
  target_surv = "relative",
  lethal = FALSE,
  method = NULL,
  level = 0.95,
  nboot = 1000L,
  TC_rate_range = c(0.1, 1),
  seed = NULL
)

tls_z(object, ...)

tls_ctmax(object, ...)

tls_tcrit(object, ...)
```

## Arguments

- object:

  A `freq_tls` fit from
  [`fit_4pl()`](https://itchyshin.github.io/freqTLS/reference/fit_4pl.md)
  (or a bare `profile_tls` fit from
  [`fit_tls()`](https://itchyshin.github.io/freqTLS/reference/fit_tls.md)).

- by:

  Optional name for the grouping column in `$summary`; defaults to the
  fit's moderator (e.g. the `ctmax`/`z`/`by` factor).

- params:

  `"all"` (z and CTmax, the default), `"z"`, or `"ctmax"`.

- target_surv:

  Survival threshold for CTmax: `"relative"` (the curve midpoint, the
  default), `"absolute"` (50% survival), or a number in `(0, 1)` for an
  LTx. Non-relative thresholds and `lethal` are derived per bootstrap
  replicate via
  [`extract_tdt()`](https://itchyshin.github.io/freqTLS/reference/extract_tdt.md).

- lethal:

  If `TRUE`, also report `T_crit` (the damage-rate-floor critical
  temperature); uses the bootstrap path.

- method:

  Interval method for the relative path: `"profile"` (default, from the
  fit's stored default), `"wald"`, or `"bootstrap"`. Absolute / `lethal`
  always use bootstrap.

- level:

  Confidence level (default 0.95).

- nboot, TC_rate_range, seed:

  Passed to
  [`extract_tdt()`](https://itchyshin.github.io/freqTLS/reference/extract_tdt.md)
  for the bootstrap path (absolute / LTx / `lethal`).

- ...:

  Passed from `tls_z()` / `tls_ctmax()` / `tls_tcrit()` to `tls()`.

## Value

A `tls` object: a list with `$summary` (a tibble of
`[<group>,] quantity, median, lower, upper`) and `$meta`.

## See also

[`fit_4pl()`](https://itchyshin.github.io/freqTLS/reference/fit_4pl.md),
`tls_z()`, `tls_ctmax()`,
[`confint.profile_tls()`](https://itchyshin.github.io/freqTLS/reference/confint.profile_tls.md)
