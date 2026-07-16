# Random-effect BLUPs (conditional modes) for a freqTLS fit

`ranef()` returns the predicted random intercepts (the conditional modes
/ BLUPs) with their conditional standard errors, for a fit with a random
intercept on any of `CTmax`, `log_z`, `low`, or `log_k`
(`<param> ~ <fixed> + (1 | group)`). It errors for a fixed-effects-only
fit. Each BLUP is a deviation on its coordinate's internal scale:
`CTmax` in degrees C, `log_z` on `log(z)`, `low` on `logit(low)`,
`log_k` on `log(k)`. When several REs are present the rows are stacked
in `CTmax`, `log_z`, `low`, `log_k` order.

## Usage

``` r
ranef(object, ...)

# S3 method for class 'profile_tls'
ranef(object, ...)
```

## Arguments

- object:

  A `profile_tls` fit from
  [`fit_tls()`](https://itchyshin.github.io/freqTLS/dev/reference/fit_tls.md)
  with a random intercept.

- ...:

  Reserved; must be empty.

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) with one
row per group level (per RE term): `group`, `term` (`"CTmax"`,
`"log_z"`, `"low"`, or `"log_k"`), `estimate` (the BLUP), and
`std.error` (the conditional SE).

## Examples

``` r
d <- simulate_tls(family = "binomial", CTmax = 36, z = 4,
                  re_sd = 1.5, n_re_groups = 12, seed = 42)
fit <- fit_tls(
  tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
         CTmax ~ 1 + (1 | colony)),
  data = d, family = "binomial", tref = 1)
ranef(fit)
#> # A tibble: 12 × 4
#>    group term  estimate std.error
#>    <chr> <chr>    <dbl>     <dbl>
#>  1 g1    CTmax    1.00      0.398
#>  2 g10   CTmax   -1.34      0.398
#>  3 g11   CTmax    0.780     0.398
#>  4 g12   CTmax    2.40      0.398
#>  5 g2    CTmax   -1.97      0.398
#>  6 g3    CTmax   -0.614     0.398
#>  7 g4    CTmax   -0.143     0.398
#>  8 g5    CTmax   -0.525     0.398
#>  9 g6    CTmax   -1.32      0.398
#> 10 g7    CTmax    1.06      0.398
#> 11 g8    CTmax   -1.27      0.398
#> 12 g9    CTmax    1.94      0.398
```
