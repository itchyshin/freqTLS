# S3 methods for fitted freqTLS models

Standard extractor and display methods for the `profile_tls` object
returned by
[`fit_tls()`](https://itchyshin.github.io/freqTLS/dev/reference/fit_tls.md):
`print`, `summary`, `coef`, `vcov`, `logLik`, `AIC`, and `nobs`. They
mirror the drmTMB method idioms
(`drmTMB::R/methods.R:2-40,1826-1864,2025-2037`).

## Usage

``` r
# S3 method for class 'profile_tls'
print(x, digits = 4, ...)

# S3 method for class 'profile_tls'
summary(object, ...)

# S3 method for class 'summary.profile_tls'
print(x, digits = 4, ...)

# S3 method for class 'profile_tls'
coef(object, complete = FALSE, ...)

# S3 method for class 'profile_tls'
vcov(object, ...)

# S3 method for class 'profile_tls'
logLik(object, ...)

# S3 method for class 'profile_tls'
AIC(object, ..., k = 2)

# S3 method for class 'profile_tls'
nobs(object, ...)
```

## Arguments

- x:

  A `profile_tls` fit from
  [`fit_tls()`](https://itchyshin.github.io/freqTLS/dev/reference/fit_tls.md).

- digits:

  Number of significant digits for the estimates table.

- ...:

  Ignored.

- object:

  A `profile_tls` fit from
  [`fit_tls()`](https://itchyshin.github.io/freqTLS/dev/reference/fit_tls.md).

- complete:

  Logical; return the full estimates data frame instead of a named
  vector.

- k:

  Penalty per parameter (default `2`, giving the AIC).

## Value

`print` and `summary` return their input invisibly / the summary object;
the extractors return the quantities named in their titles.

## Functions

- `print(profile_tls)`: Print a compact, readable summary: the call, the
  family, `tref`, the data summary, the natural-scale estimates table,
  and the convergence state.

- `summary(profile_tls)`: Build a `summary.profile_tls` object carrying
  the estimates table (with Wald z-statistics and p-values), the family,
  `tref`, the data summary, and the convergence state.

- `print(summary.profile_tls)`: Print a `summary.profile_tls` object.

- `coef(profile_tls)`: Extract natural-scale point estimates. With
  `complete = FALSE` (default) a named numeric vector; with
  `complete = TRUE` the full `estimates` data frame (parameter, group,
  estimate, std.error).

- `vcov(profile_tls)`: The variance-covariance matrix of the internal
  (unconstrained) coordinates, from
  [`TMB::sdreport()`](https://rdrr.io/pkg/TMB/man/sdreport.html).
  Returns `NULL` (with a warning) when the `sdreport` did not produce a
  covariance.

- `logLik(profile_tls)`: The maximised log-likelihood, as a `logLik`
  object with `df` and `nobs` attributes so
  [`stats::AIC()`](https://rdrr.io/r/stats/AIC.html) and
  [`stats::BIC()`](https://rdrr.io/r/stats/AIC.html) work.

- `AIC(profile_tls)`: Akaike's An Information Criterion. With the
  default `k = 2` this returns the stored `AIC`; other `k` are computed
  from the log-likelihood and `df`.

- `nobs(profile_tls)`: The number of observations (temperature-by-
  duration cells) used in the fit.

## Examples

``` r
d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
fit <- fit_tls(
  d, y = survived, n = total, time = duration, temp = temp,
  family = "binomial", tref = 1, quiet = TRUE
)
coef(fit)
#>         low          up           k       CTmax           z 
#>  0.01990609  0.97732873  4.89170992 35.92586046  3.99803066 
logLik(fit)
#> 'log Lik.' -129.0538 (df=5)
AIC(fit)
#> [1] 268.1076
nobs(fit)
#> [1] 105
```
