# Stage 2 of the classical two-stage TDT pipeline

Regresses the valid Stage-1 `log10(LT50)` estimates on assay temperature
by ordinary least squares and derives the classical quantities.
`z = -1/slope`; `CTmax(t_ref) = (log10(t_ref) - intercept) / slope`;
`T_crit` follows the rate-multiplier definition,
`CTmax + z * mean(log10(TC_rate_range/100))`. `t_ref` is expressed in
minutes and is recorded in the returned `$settings`. Thus
`summary$CTmax` is always CTmax at the explicitly recorded reference
duration, not necessarily CTmax at one hour. Stage 2 retains only rows
chosen by `rows`; if fewer than three valid Stage-1 temperatures remain,
it returns a `NULL` fit and an `NA` summary rather than extrapolating a
TDT line.

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
  [`ts_stage1()`](https://itchyshin.github.io/freqTLS/reference/ts_stage1.md).

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

`list(fit, summary, settings)`; `fit` is `NULL` if fewer than 3 valid
Stage-1 estimates remain. `summary` has `intercept`, `slope_T`, `z`,
`CTmax`, `T_crit`, `r_squared`, `n_stage1`, `n_excluded`. `$settings`
records `t_ref`, `time_multiplier`, and `TC_rate_range`; downstream
[`ts_ci()`](https://itchyshin.github.io/freqTLS/reference/ts_ci.md) and
[`ts_curve()`](https://itchyshin.github.io/freqTLS/reference/ts_curve.md)
inherit these settings by default. For compatibility, when `t_ref = 60`
exactly, `summary` also contains a truthful `CTmax_1hr` alias for
`CTmax`; it is absent at every other reference duration.

## Examples

``` r
d <- simulate_tls(
  family = "binomial", temps = seq(30, 42, by = 2),
  times = c(0.01, 0.03, 0.1, 0.3, 1, 3, 10, 30, 100),
  reps = 4, n = 50, CTmax = 36, z = 4, seed = 42
)
s1 <- ts_stage1(d, "temp", "duration", "survived", "total")
ts_stage2(s1, t_ref = 60, time_multiplier = 60)$summary
#> # A tibble: 1 × 9
#>   intercept slope_T     z CTmax T_crit r_squared n_stage1 n_excluded CTmax_1hr
#>       <dbl>   <dbl> <dbl> <dbl>  <dbl>     <dbl>    <int>      <int>     <dbl>
#> 1      10.6  -0.245  4.08  36.0   25.8     0.999        7          0      36.0
```
