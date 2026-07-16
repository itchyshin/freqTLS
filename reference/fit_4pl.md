# Fit the 4PL thermal-load-sensitivity model by maximum likelihood (TMB)

The frequentist analogue of `bayesTLS::fit_4pl()`. Consumes
[`standardize_data()`](https://itchyshin.github.io/freqTLS/reference/standardize_data.md)
output and fits the single-stage 4PL thermal death-time model,
parameterised directly in CTmax and thermal sensitivity (z), via the
freqTLS TMB engine. Returns a `freq_tls` workflow object; uncertainty
(Wald / profile / bootstrap) is computed on demand by the quantity
analogues
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
  Supplying `ctmax`/`z` (or `by`) fits per-group CTmax/z; the two
  headline formulas must produce the same fixed-effect columns.

- threshold:

  `"relative"` (default; CTmax/z at the curve midpoint) or `"absolute"`
  (at the `p`-survival level). The fitting backbone currently accepts
  only `"relative"`; obtain absolute-threshold quantities post fit with
  [`extract_tdt()`](https://itchyshin.github.io/freqTLS/reference/extract_tdt.md)
  and `target_surv = "absolute"`.

- p:

  Survival level for the absolute threshold (default 0.5).

- t_ref:

  Reference exposure time (in the data's `duration_unit`) at which CTmax
  is reported. Default 60 (e.g. minutes); use `t_ref = 1` for hours.

- bounds:

  Asymptote range. Only `c(0, 1)` is currently accepted. Supply survival
  as a probability in `[0, 1]` and let the model estimate `low` and `up`
  within that range; non-default bounds stop with an error.

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

## Experimental software

**Use freqTLS at your own risk.** Results and APIs may be incorrect or
change. Users are responsible for checking their data, design, model
specification, convergence, identifiability, diagnostics, and
interpretation. Important analyses should be independently refitted and
cross-checked with [bayesTLS](https://daniel1noble.github.io/bayesTLS/)
([source repository](https://github.com/daniel1noble/bayesTLS)).
Agreement is a cross-check, not proof of correctness; shared data or
model errors can make both packages agree.

## Before interpretation

Before interpreting the fit, run
[`check_tls()`](https://itchyshin.github.io/freqTLS/reference/check_tls.md).
Its help page gives a recovery action for each data-adequacy warning;
[`vignette("profile-likelihood")`](https://itchyshin.github.io/freqTLS/articles/profile-likelihood.md)
explains strict open profiles and the default bootstrap fallback.

## See also

[`standardize_data()`](https://itchyshin.github.io/freqTLS/reference/standardize_data.md),
[`make_4pl_formula()`](https://itchyshin.github.io/freqTLS/reference/make_4pl_formula.md),
[`fit_tls()`](https://itchyshin.github.io/freqTLS/reference/fit_tls.md),
[`check_tls()`](https://itchyshin.github.io/freqTLS/reference/check_tls.md)

## Examples

``` r
raw <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
dat <- standardize_data(
  raw, temp = "temp", duration = "duration",
  n_total = "total", n_surv = "survived"
)
fit <- fit_4pl(
  dat, family = "binomial", t_ref = 1, method = "wald", quiet = TRUE
)
coef(fit)
#>         low          up           k       CTmax           z 
#>  0.01990609  0.97732873  4.89170992 35.92586046  3.99803066 
```
