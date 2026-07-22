# Fit a single-stage 4PL thermal-load-sensitivity model by maximum likelihood

`fit_tls()` fits the descending four-parameter logistic (4PL) thermal
death-time model to survival-count data, parameterised directly in
`CTmax` (the critical thermal maximum at the reference time `tref`) and
`z` (thermal sensitivity, degrees Celsius per order-of-magnitude change
in tolerated duration) so that both headline quantities can be profiled.
Survival is modelled as a function of `log10(duration)`; the midpoint
moves with temperature through `CTmax` and `z` (see
[`vignette("model-math")`](https://itchyshin.github.io/freqTLS/articles/model-math.md)).
The thermal-load-sensitivity modelling framework was introduced by
Daniel W. A. Noble, Pieter A. Arnold, and Patrice Pottier in
[bayesTLS](https://daniel1noble.github.io/bayesTLS/).

## Usage

``` r
fit_tls(
  x,
  y,
  n,
  time,
  temp,
  group = NULL,
  family = c("beta_binomial", "binomial", "beta"),
  tref = NULL,
  start = NULL,
  control = list(),
  trace = FALSE,
  quiet = FALSE,
  data = NULL
)
```

## Arguments

- x:

  Either a data frame (column interface) or a `tls_formula` from
  [`tls_bf()`](https://itchyshin.github.io/freqTLS/reference/tls_bf.md)
  (formula interface). For back-compatibility the first argument is
  still positional, so `fit_tls(my_data, y = survived, ...)` continues
  to work.

- y:

  \<[`data-masked`](https://rlang.r-lib.org/reference/args_data_masking.html)\>
  Column of successes (survivors), or, for the `beta` family, the
  response proportion in `(0, 1)`.

- n:

  \<[`data-masked`](https://rlang.r-lib.org/reference/args_data_masking.html)\>
  Column of trials (total individuals). Required for the binomial and
  beta-binomial families; omit it for the `beta` family, whose response
  is already a proportion.

- time:

  \<[`data-masked`](https://rlang.r-lib.org/reference/args_data_masking.html)\>
  Column of exposure durations in minutes; used as `log10(duration)`
  internally.

- temp:

  \<[`data-masked`](https://rlang.r-lib.org/reference/args_data_masking.html)\>
  Column of assay temperatures (degrees C).

- group:

  \<[`data-masked`](https://rlang.r-lib.org/reference/args_data_masking.html)\>
  Optional grouping column. When supplied, each group gets its own
  direct, profile-able `CTmax` and `z` with shared `low`, `up`, and `k`.
  Defaults to `NULL` (a single ungrouped fit).

- family:

  One of `"beta_binomial"` (default), `"binomial"`, or `"beta"` (a
  continuous proportion in `(0, 1)`), or a `tls_family` object from
  [`beta_binomial_tls()`](https://itchyshin.github.io/freqTLS/reference/tls_family.md)
  /
  [`binomial_tls()`](https://itchyshin.github.io/freqTLS/reference/tls_family.md)
  /
  [`beta_tls()`](https://itchyshin.github.io/freqTLS/reference/tls_family.md).

- tref:

  Reference time at which `CTmax` is defined, in minutes. When `NULL`
  (the default), it is `60` minutes (one hour). Use
  [`standardize_data()`](https://itchyshin.github.io/freqTLS/reference/standardize_data.md)
  to convert a raw duration column before fitting; bare formula/column
  data must already use minutes.

- start:

  Optional named list of starting values on the internal (unconstrained)
  scale, overriding the defaults. Names must match the parameters in
  `src/profile_tls.cpp` (`beta_low`, `beta_up`, `beta_logk`, `beta_CT`,
  `beta_logz`, `log_phi`).

- control:

  List of optimiser controls; `optimizer` is passed to
  [`stats::nlminb()`](https://rdrr.io/r/stats/nlminb.html)'s `control`,
  and `trace` toggles optimiser output.

- trace:

  Logical; print optimiser progress. A shortcut for `control$trace`.

- quiet:

  Logical; if `TRUE`, suppress freqTLS's own data-adequacy and
  identifiability diagnostic warnings and messages (the few-groups, beta
  boundary-clamp, and same-grouping notes). Genuine errors and optimiser
  warnings still surface, and
  [`check_tls()`](https://itchyshin.github.io/freqTLS/reference/check_tls.md)
  reports the diagnostics on demand. Default `FALSE`.

- data:

  Used only in the formula interface: the data frame the
  [`tls_bf()`](https://itchyshin.github.io/freqTLS/reference/tls_bf.md)
  columns are resolved against. Ignored in the column interface (where
  the data frame is `x`).

## Value

An object of class `c("profile_tls", "tls_fit")`: a list with the call,
the resolved `family`, `tref`, `group_levels`, a `data_summary`, the
internal-scale MLE `par`, an `estimates` data frame of natural-scale
parameters with standard errors, the `vcov` of the internal coordinates,
the `logLik`, residual `df`, `AIC`, a `convergence` list
(`code`/`pdHess`/`message`), the `name_map`, and the underlying TMB
`obj`, optimiser `opt`, and `sdreport`.

## Details

There are two equivalent interfaces. In the **column interface**,
columns are referenced with tidy evaluation: pass the bare column names
of `data` (as in `dplyr`), not strings. In the **formula interface**,
pass a
[`tls_bf()`](https://itchyshin.github.io/freqTLS/reference/tls_bf.md)
object as `x` and the data frame as `data`; the brms/drmTMB-style
grammar names the response, the two axes, and the `CTmax` / `log_z`
predictors. Both interfaces feed the same likelihood engine, so a
grouped formula fit and the matching `group =` column fit are
numerically identical.

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

Run
[`check_tls()`](https://itchyshin.github.io/freqTLS/reference/check_tls.md)
on the fitted object. Its help page maps every data-adequacy warning to
a concrete design or analysis response.
[`vignette("profile-likelihood")`](https://itchyshin.github.io/freqTLS/articles/profile-likelihood.md)
explains strict open profiles and the default bootstrap recovery
attempt.

## See also

[`check_tls()`](https://itchyshin.github.io/freqTLS/reference/check_tls.md),
[`confint.profile_tls()`](https://itchyshin.github.io/freqTLS/reference/confint.profile_tls.md)

## Examples

``` r
d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
               family = "binomial", tref = 60)
fit$estimates
#>   parameter group    estimate   std.error
#> 1       low  <NA>  0.01990612 0.005521844
#> 2        up  <NA>  0.97732869 0.007971566
#> 3         k  <NA>  4.89171231 0.413062744
#> 4     CTmax   all 28.81675603 0.294280072
#> 5         z   all  3.99803137 0.191371651

# The same fit through the formula interface:
fit2 <- fit_tls(
  tls_bf(survived | trials(total) ~ time(duration) + temp(temp)),
  data = d, family = "binomial", tref = 60
)
```
