# Tidy the parameters of a fitted freqTLS model

`tidy_parameters()` returns a broom-style tibble of the natural-scale
parameter estimates with optional Wald confidence intervals. The
intervals are computed on the internal (unconstrained / link) scale as
`estimate +/- z * std.error` and then back-transformed to the natural
scale, so they respect each parameter's bounds (for example `z > 0`,
`0 < low < up`) and are equivariant under the link. For `CTmax`
(identity link) this is the usual symmetric Wald interval.

## Usage

``` r
tidy_parameters(
  fit,
  conf.int = TRUE,
  conf.level = 0.95,
  method = c("wald", "profile")
)
```

## Arguments

- fit:

  A `profile_tls` fit from
  [`fit_tls()`](https://itchyshin.github.io/freqTLS/reference/fit_tls.md).

- conf.int:

  Logical; include `conf.low` / `conf.high` columns (default `TRUE`).

- conf.level:

  Confidence level for the interval (default `0.95`).

- method:

  Either `"wald"` (default) or `"profile"`.

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) with one
row per natural-scale parameter and the columns `parameter`, `group`,
`estimate`, `std.error`, `conf.low`, `conf.high`, `interval_type`, and
`scale`. `scale` is the link on which the interval was constructed
(`"identity"`, `"log"`, or `"logit"`); `interval_type` is `"wald"` or
`"profile"`.

## Details

With `method = "profile"` the intervals are profile-likelihood
confidence intervals (see
[`confint.profile_tls()`](https://itchyshin.github.io/freqTLS/reference/confint.profile_tls.md));
with `method = "wald"` (default) they are the back-transformed
internal-link Wald intervals. The returned shape is identical; only
`interval_type` and the interval values differ. A profile that does not
close returns `NA` on the open side (never a fabricated bound).

## Examples

``` r
d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
               family = "binomial", tref = 1)
tidy_parameters(fit)
#> # A tibble: 5 × 8
#>   parameter group estimate std.error conf.low conf.high interval_type scale   
#>   <chr>     <chr>    <dbl>     <dbl>    <dbl>     <dbl> <chr>         <chr>   
#> 1 low       NA      0.0199   0.00552   0.0115    0.0345 wald          logit   
#> 2 up        NA      0.977    0.00797   0.962     0.993  wald          identity
#> 3 k         NA      4.89     0.413     4.14      5.78   wald          log     
#> 4 CTmax     all    35.9      0.105    35.7      36.1    wald          identity
#> 5 z         all     4.00     0.191     3.64      4.40   wald          log     
tidy_parameters(fit, method = "profile")
#> "up" is profiled with the delta-method Wald interval.
#> ℹ The profile path is not yet wired for the disjoint-bounds "up" coordinate
#>   `beta_up` (SPEC.md S10).
#> # A tibble: 5 × 8
#>   parameter group estimate std.error conf.low conf.high interval_type scale   
#>   <chr>     <chr>    <dbl>     <dbl>    <dbl>     <dbl> <chr>         <chr>   
#> 1 low       NA      0.0199   0.00552   0.0191    0.0631 profile       logit   
#> 2 up        NA      0.977    0.00797   0.962     0.993  wald          identity
#> 3 k         NA      4.89     0.413     4.13      5.78   profile       log     
#> 4 CTmax     all    35.9      0.105    35.7      36.1    profile       identity
#> 5 z         all     4.00     0.191     3.62      4.38   profile       log     
```
