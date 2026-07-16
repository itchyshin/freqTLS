# 4PL parameter table (frequentist analogue of `tdt_parameter_table`)

Returns the fitted 4PL parameters (`low`, `up`, `k`, `CTmax`, `z`, and
`phi` for over-dispersed families) as point estimates with confidence
intervals, in bayesTLS's `parameter / [group] / median / lower / upper`
shape.

## Usage

``` r
tdt_parameter_table(object, method = NULL, level = 0.95)
```

## Arguments

- object:

  A `freq_tls` fit from
  [`fit_4pl()`](https://itchyshin.github.io/freqTLS/reference/fit_4pl.md)
  (or a `profile_tls` fit).

- method:

  Interval method: `"wald"` (default) or `"profile"`.

- level:

  Confidence level (default 0.95).

## Value

A tibble with `parameter`, `group`, `median`, `lower`, `upper`.

## See also

[`tls()`](https://itchyshin.github.io/freqTLS/reference/tls.md),
[`tidy_parameters()`](https://itchyshin.github.io/freqTLS/reference/tidy_parameters.md)

## Examples

``` r
raw <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
dat <- standardize_data(
  raw, temp = "temp", duration = "duration",
  n_total = "total", n_surv = "survived"
)
fit <- fit_4pl(dat, family = "binomial", t_ref = 1, quiet = TRUE)
tdt_parameter_table(fit, method = "wald")
#> # A tibble: 5 × 5
#>   parameter group  median   lower   upper
#>   <chr>     <chr>   <dbl>   <dbl>   <dbl>
#> 1 low       NA     0.0199  0.0115  0.0345
#> 2 up        NA     0.977   0.962   0.993 
#> 3 k         NA     4.89    4.14    5.78  
#> 4 CTmax     all   35.9    35.7    36.1   
#> 5 z         all    4.00    3.64    4.40  
```
