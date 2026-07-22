# Extract the CTmax estimate(s)

Extract the CTmax estimate(s)

## Usage

``` r
get_ctmax(
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

  Logical; include confidence-interval columns (default `TRUE`).

- conf.level:

  Confidence level for the interval (default `0.95`).

- method:

  Either `"wald"` (default) or `"profile"`.

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) of the
`CTmax` row(s) from
[`tidy_parameters()`](https://itchyshin.github.io/freqTLS/reference/tidy_parameters.md).

## Examples

``` r
d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
               family = "binomial", tref = 60)
get_ctmax(fit)
#> # A tibble: 1 × 8
#>   parameter group estimate std.error conf.low conf.high interval_type scale   
#>   <chr>     <chr>    <dbl>     <dbl>    <dbl>     <dbl> <chr>         <chr>   
#> 1 CTmax     all       28.8     0.294     28.2      29.4 wald          identity
```
