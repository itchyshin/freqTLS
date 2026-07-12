# Confidence intervals for a fitted thermal-load-sensitivity model

[`confint()`](https://rdrr.io/r/stats/confint.html) returns confidence
intervals for the natural-scale parameters of a
[`fit_tls()`](https://itchyshin.github.io/freqTLS/reference/fit_tls.md)
model. Three methods are available:

## Usage

``` r
# S3 method for class 'profile_tls'
confint(
  object,
  parm = NULL,
  level = 0.95,
  method = c("profile", "wald", "bootstrap"),
  npoints = 30L,
  trace = FALSE,
  fallback = TRUE,
  nboot = 1000L,
  boot_seed = NULL,
  cores = 1L,
  ...
)
```

## Arguments

- object:

  A `profile_tls` fit from
  [`fit_tls()`](https://itchyshin.github.io/freqTLS/reference/fit_tls.md).

- parm:

  Character vector of target names (for example `"CTmax"`, `"z"`,
  `"log_z"`, `"low"`, `"k"`, `"phi"`, grouped names such as `"CTmax:A"`,
  or contrasts such as `"dCTmax:A-B"`). `NULL` (default) returns
  intervals for the natural-scale parameters of the fit.

- level:

  Confidence level (default `0.95`).

- method:

  One of `"profile"` (default), `"wald"`, or `"bootstrap"`.

- npoints:

  Number of grid points used per profile (default `30`); ignored for
  `method = "wald"` and `method = "bootstrap"`.

- trace:

  Logical; print inner-optimisation progress (profile/bootstrap).

- fallback:

  Logical; when `method = "profile"` (the default), fall back to the
  parametric bootstrap for any parameter whose profile does not close,
  and for all parameters when the fit's Hessian is not positive definite
  (`pdHess = FALSE`). Default `TRUE`.

- nboot:

  Number of bootstrap replicates for `method = "bootstrap"` or the
  fallback (default `1000`).

- boot_seed:

  Optional integer seed making the bootstrap reproducible without
  disturbing the caller's random stream (default `NULL`).

- cores:

  Number of CPU cores for the bootstrap refits (default `1`, maximum
  `2`). Requests above two warn and use two. `cores > 1` refits
  replicates in parallel by forking (Unix; sequential on Windows).
  Results are identical for a given `boot_seed` regardless of `cores`.

- ...:

  Reserved; must be empty.

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) with one
row per target and columns `parameter`, `conf.low`, `conf.high`,
`estimate`, `level`, `method`, `scale`, and `conf.status`.

## Details

- `method = "profile"` (default) computes profile-likelihood confidence
  intervals by inverting the likelihood-ratio test: the interval is
  `{psi : D(psi) <= qt(1 - alpha/2, df)^2}`, found by
  [`stats::uniroot()`](https://rdrr.io/r/stats/uniroot.html) on each
  side of the MLE on the unconstrained internal coordinate, with the
  endpoints transformed to the natural scale. The cutoff is the squared
  profile-t quantile on `df = n - p` residual degrees of freedom
  (Bates-Watts profile-t), not `qchisq(level, 1)`; the two coincide as
  `df -> Inf`. These intervals are prior-free and respect asymmetry.
  They are equivariant under monotone reparameterisation, so the `z`
  interval equals [`exp()`](https://rdrr.io/r/base/Log.html) of the
  internal `log_z` interval.

- `method = "wald"` reuses the Phase-2 Wald path: `estimate +/- t * se`
  (with `t = qt(1 - alpha/2, df)` on `df = n - p`) on the internal
  (link) scale, back-transformed.

- `method = "bootstrap"` returns prior-free parametric-bootstrap
  percentile intervals: survival counts are regenerated at the observed
  design from the fitted 4PL, the model is refitted `nboot` times, and
  the interval is the percentile range of the replicate estimates. This
  is the likelihood-path analogue of the bayesTLS posterior interval. It
  returns a finite interval only when enough stable, non-degenerate
  refits remain.

When a profile does not close on one side, or the fitted Hessian is not
positive definite (`pdHess = FALSE`),
[`confint()`](https://rdrr.io/r/stats/confint.html) falls back to the
parametric bootstrap for the affected parameters (with a message). The
fallback can still return `NA` when too few valid refits remain. Set
`fallback = FALSE` to keep the strict profile behaviour, which returns
`NA` on the open side (never a fabricated bound) with a warning that the
parameter is weakly identified (see
[`vignette("profile-likelihood")`](https://itchyshin.github.io/freqTLS/articles/profile-likelihood.md)).
The upper asymptote `up` has its own coordinate `beta_up` under disjoint
bounds but is not yet profiled, so it is reported with the delta-method
Wald interval under the profile/Wald methods, with a message.

For a fit with a random intercept (`CTmax ~ <fixed> + (1 | group)`),
`method = "profile"` profiles the fixed-effect coordinates by re-running
the Laplace approximation at each grid point, which is slower than a
fixed-effects profile. Variance components keep their log-scale Wald
intervals under the profile method, and a non-closing random-effects
profile falls back to Wald. `method = "bootstrap"` instead redraws every
active random-intercept block and refits with the Laplace approximation,
returning percentile intervals when enough stable refits remain.

## Examples

``` r
d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
               family = "binomial", tref = 1)
confint(fit, "CTmax", method = "profile")
#> # A tibble: 1 × 8
#>   parameter conf.low conf.high estimate level method  scale    conf.status
#>   <chr>        <dbl>     <dbl>    <dbl> <dbl> <chr>   <chr>    <chr>      
#> 1 CTmax         35.7      36.1     35.9  0.95 profile identity ok         
confint(fit, "z", method = "profile")
#> # A tibble: 1 × 8
#>   parameter conf.low conf.high estimate level method  scale conf.status
#>   <chr>        <dbl>     <dbl>    <dbl> <dbl> <chr>   <chr> <chr>      
#> 1 z             3.62      4.38     4.00  0.95 profile log   ok         
```
