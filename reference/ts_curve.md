# Median LT-vs-temperature line from a two-stage fit

Median LT-vs-temperature line from a two-stage fit

## Usage

``` r
ts_curve(stage2, temp_grid, time_multiplier = 1)
```

## Arguments

- stage2:

  Output of
  [`ts_stage2()`](https://itchyshin.github.io/freqTLS/reference/ts_stage2.md).

- temp_grid:

  Temperatures (°C) to evaluate.

- time_multiplier:

  Multiplier to minutes. Default 1.

## Value

A tibble with `temp` and `duration_median` (minutes).

## Examples

``` r
d <- data.frame(
  temp = rep(c(30, 34, 38), each = 12),
  dur  = rep(c(1, 5, 15, 45), times = 9),
  surv = rbinom(36, 20, 0.4), tot = 20)
ts_curve(ts_stage2(ts_stage1(d, "temp", "dur", "surv", "tot")),
         temp_grid = seq(30, 38, 1))
#> # A tibble: 9 × 2
#>    temp duration_median
#>   <dbl>           <dbl>
#> 1    30              NA
#> 2    31              NA
#> 3    32              NA
#> 4    33              NA
#> 5    34              NA
#> 6    35              NA
#> 7    36              NA
#> 8    37              NA
#> 9    38              NA
```
