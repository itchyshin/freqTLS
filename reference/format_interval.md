# Format a point estimate plus confidence interval as a single string

Format a point estimate plus confidence interval as a single string

## Usage

``` r
format_interval(median, lower, upper, digits = 2)
```

## Arguments

- median, lower, upper:

  Numeric (scalar or vector). `median` is the central value (a point
  estimate or the median of bootstrap replicates), `lower` and `upper`
  the confidence-interval endpoints.

- digits:

  Integer rounding precision.

## Value

Character like `"5.12 [4.87, 5.4]"`. A non-finite `median` yields
`NA_character_` (rather than `"NA [...]"`); a non-finite bound is shown
as an en dash, so the strings stay table-ready.

## Examples

``` r
format_interval(5.123, 4.872, 5.401)
#> [1] "5.12 [4.87, 5.4]"
format_interval(NA, 1, 2)   # -> NA
#> [1] NA
```
