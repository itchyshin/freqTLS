# Median LT-vs-temperature line from a two-stage fit

Median LT-vs-temperature line from a two-stage fit

## Usage

``` r
ts_curve(stage2, temp_grid, time_multiplier = NULL)
```

## Arguments

- stage2:

  Output of
  [`ts_stage2()`](https://itchyshin.github.io/freqTLS/reference/ts_stage2.md).

- temp_grid:

  Temperatures (°C) to evaluate.

- time_multiplier:

  Optional explicit check against the setting recorded by
  [`ts_stage2()`](https://itchyshin.github.io/freqTLS/reference/ts_stage2.md).
  By default the Stage-2 setting is inherited.

## Value

A tibble with `temp` and `duration_median` (minutes).

## Examples

``` r
d <- simulate_tls(
  family = "binomial", temps = seq(30, 42, by = 2),
  times = c(0.01, 0.03, 0.1, 0.3, 1, 3, 10, 30, 100),
  reps = 4, n = 50, CTmax = 36, z = 4, seed = 42
)
s2 <- ts_stage2(ts_stage1(d, "temp", "duration", "survived", "total"),
                t_ref = 60, time_multiplier = 60)
ts_curve(s2, temp_grid = seq(30, 42, 1))
#> # A tibble: 13 × 2
#>     temp duration_median
#>    <dbl>           <dbl>
#>  1    30         1814.  
#>  2    31         1032.  
#>  3    32          587.  
#>  4    33          334.  
#>  5    34          190.  
#>  6    35          108.  
#>  7    36           61.6 
#>  8    37           35.0 
#>  9    38           19.9 
#> 10    39           11.3 
#> 11    40            6.46
#> 12    41            3.67
#> 13    42            2.09
```
