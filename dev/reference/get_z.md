# Extract the thermal-sensitivity (z) estimate(s)

Extract the thermal-sensitivity (z) estimate(s)

## Usage

``` r
get_z(fit, conf.int = TRUE, conf.level = 0.95)
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
`z` row(s) from
[`tidy_parameters()`](https://itchyshin.github.io/freqTLS/dev/reference/tidy_parameters.md).

## Examples

``` r
d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
               family = "binomial", tref = 1)
get_z(fit)
#> # A tibble: 1 × 8
#>   parameter group estimate std.error conf.low conf.high interval_type scale
#>   <chr>     <chr>    <dbl>     <dbl>    <dbl>     <dbl> <chr>         <chr>
#> 1 z         all       4.00     0.191     3.64      4.40 wald          log  
```
