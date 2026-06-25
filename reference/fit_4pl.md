# Fit the 4PL thermal-load-sensitivity model by maximum likelihood (TMB)

The frequentist twin of `bayesTLS::fit_4pl()`. Consumes
[`standardize_data()`](https://itchyshin.github.io/freqTLS/reference/standardize_data.md)
output and fits the single-stage 4PL thermal death-time model,
parameterised directly in CTmax and thermal sensitivity (z), via the
freqTLS TMB engine. Returns a `freq_tls` workflow object; uncertainty
(Wald / profile / bootstrap) is computed on demand by the quantity twins
([`tls()`](https://itchyshin.github.io/freqTLS/reference/tls.md),
[`confint()`](https://rdrr.io/r/stats/confint.html)).

## Usage

``` r
fit_4pl(
  data,
  ctmax = NULL,
  z = NULL,
  up = NULL,
  low = NULL,
  k = NULL,
  by = NULL,
  threshold = c("relative", "absolute"),
  p = 0.5,
  t_ref = 60,
  bounds = c(0, 1),
  family = NULL,
  method = c("profile", "wald", "bootstrap"),
  start = NULL,
  control = list(),
  trace = FALSE,
  quiet = FALSE
)
```

## Arguments

- data:

  Output of
  [`standardize_data()`](https://itchyshin.github.io/freqTLS/reference/standardize_data.md).

- ctmax, z, up, low, k, by:

  Direct-mode formula interface; see
  [`make_4pl_formula()`](https://itchyshin.github.io/freqTLS/reference/make_4pl_formula.md).
  Supplying `ctmax`/`z` (or `by`) fits per-group CTmax/z.

- threshold:

  `"relative"` (default; CTmax/z at the curve midpoint) or `"absolute"`
  (at the `p`-survival level). *Absolute is wired into the backbone in a
  later step; for now use `"relative"` and convert post hoc.*

- p:

  Survival level for the absolute threshold (default 0.5).

- t_ref:

  Reference exposure time (in the data's `duration_unit`) at which CTmax
  is reported. Default 60 (e.g. minutes); use `t_ref = 1` for hours.

- bounds:

  Length-2 asymptote range `c(lower, upper)` (default `c(0, 1)`).

- family:

  `"beta_binomial"` (default for counts), `"binomial"`, or `"beta"`.
  `NULL` picks beta for a proportion response, else beta-binomial.

- method:

  Default interval method for downstream extraction (`"profile"`,
  `"wald"`, or `"bootstrap"`); stored in the object.

- start, control, trace, quiet:

  Passed to the engine
  [`fit_tls()`](https://itchyshin.github.io/freqTLS/reference/fit_tls.md).

## Value

A `freq_tls` object: a list with `$fit` (the engine fit), `$data`,
`$formula`, and `$meta` (threshold, t_ref, bounds, temp_mean,
response_type, family, grouped, moderators, method).

## See also

[`standardize_data()`](https://itchyshin.github.io/freqTLS/reference/standardize_data.md),
[`make_4pl_formula()`](https://itchyshin.github.io/freqTLS/reference/make_4pl_formula.md),
[`fit_tls()`](https://itchyshin.github.io/freqTLS/reference/fit_tls.md)
