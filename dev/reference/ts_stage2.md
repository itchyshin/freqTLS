# Stage 2 of the classical two-stage TDT pipeline

Regresses Stage-1 `log10(LT50)` on assay temperature by ordinary least
squares and derives the classical quantities. `z = -1/slope`;
`CTmax(t_ref) = (log10(t_ref) - intercept) / slope`; `T_crit` follows
the rate-multiplier definition,
`CTmax + z * mean(log10(TC_rate_range/100))`.

## Usage

``` r
ts_stage2(
  stage1,
  t_ref = 60,
  time_multiplier = 1,
  TC_rate_range = c(0.1, 1),
  rows = c("stage1_ok", "finite_ok")
)
```

## Arguments

- stage1:

  Output of
  [`ts_stage1()`](https://itchyshin.github.io/freqTLS/dev/reference/ts_stage1.md).

- t_ref:

  Reference exposure duration for CTmax (minutes). Default 60.

- time_multiplier:

  Multiplier from the Stage-1 duration unit to minutes (e.g. 60 if
  durations are in hours). Default 1.

- TC_rate_range:

  Length-2 HI-rate range (% per hour) for T_crit.

- rows:

  Which Stage-1 rows to keep: `"stage1_ok"` (bracketing validation, the
  case-study default) or `"finite_ok"` (finite/negative slope only, the
  simulation's looser rule).

## Value

`list(fit, summary)`; `fit` is `NULL` if fewer than 3 valid Stage-1
estimates remain. `summary` has `intercept`, `slope_T`, `z`,
`CTmax_1hr`, `T_crit`, `r_squared`, `n_stage1`, `n_excluded`.

## Examples

``` r
d <- data.frame(
  temp = rep(c(30, 32, 34, 36, 38), each = 12),
  dur  = rep(c(1, 5, 15, 45, 135, 405), times = 10),
  surv = rbinom(60, 20, 0.4), tot = 20)
s1 <- ts_stage1(d, "temp", "dur", "surv", "tot")
ts_stage2(s1)$summary
#> # A tibble: 1 × 8
#>   intercept slope_T     z CTmax_1hr T_crit r_squared n_stage1 n_excluded
#>       <dbl>   <dbl> <dbl>     <dbl>  <dbl>     <dbl>    <int>      <int>
#> 1        NA      NA    NA        NA     NA        NA        0          5
```
