# Extract the shape parameters (low, up, k, and phi)

Extract the shape parameters (low, up, k, and phi)

## Usage

``` r
get_shape(fit, conf.int = TRUE, conf.level = 0.95)
```

## Arguments

- fit:

  A `profile_tls` fit from
  [`fit_tls()`](https://itchyshin.github.io/freqTLS/dev/reference/fit_tls.md).

- conf.int:

  Logical; include Wald `conf.low` / `conf.high` (default `TRUE`).

- conf.level:

  Confidence level for the Wald interval (default `0.95`).

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) of the
shape rows (`low`, `up`, `k`, and `phi` for the beta-binomial family)
from
[`tidy_parameters()`](https://itchyshin.github.io/freqTLS/dev/reference/tidy_parameters.md).

## Examples

``` r
d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
               family = "binomial", tref = 1)
get_shape(fit)
#> # A tibble: 3 × 8
#>   parameter group estimate std.error conf.low conf.high interval_type scale   
#>   <chr>     <chr>    <dbl>     <dbl>    <dbl>     <dbl> <chr>         <chr>   
#> 1 low       NA      0.0199   0.00552   0.0115    0.0345 wald          logit   
#> 2 up        NA      0.977    0.00797   0.962     0.993  wald          identity
#> 3 k         NA      4.89     0.413     4.14      5.78   wald          log     
```
