# Uncertainty for the classical two-stage TDT quantities

Two propagation methods on the Stage-2 fit:

- `"delta"` — delta-method standard errors for `z` and `CTmax`, with
  **both Normal and t quantiles** (the t-quantile is the small-sample
  correction for the few Stage-2 residual degrees of freedom). This is
  the method the bias simulation reports.

- `"mvn"` — slope-CI inversion for `z` (defined only when the slope CI
  is wholly negative) plus MVN simulation of the Stage-2 coefficients
  for `CTmax` and `T_crit`, and a `predict.lm` confidence band for the
  LT-vs-T line over `temp_grid`. This is the method the case studies
  report.

## Usage

``` r
ts_ci(
  stage2,
  method = c("delta", "mvn"),
  level = 0.95,
  t_ref = 60,
  time_multiplier = 1,
  TC_rate_range = c(0.1, 1),
  temp_grid = NULL,
  n_sim = 1000,
  seed = 123
)
```

## Arguments

- stage2:

  Output of
  [`ts_stage2()`](https://itchyshin.github.io/freqTLS/reference/ts_stage2.md).

- method:

  `"delta"` or `"mvn"`.

- level:

  Confidence level. Default 0.95.

- t_ref, time_multiplier, TC_rate_range:

  As in
  [`ts_stage2()`](https://itchyshin.github.io/freqTLS/reference/ts_stage2.md).

- temp_grid:

  Temperatures for the line band (`"mvn"` only).

- n_sim:

  MVN draws (`"mvn"` only). Default 1000.

- seed:

  RNG seed (`"mvn"` only). Default 123.

## Value

For `"delta"`, a list with `z` and `CTmax_1hr`, each
`list(point, lower, upper, lower_t, upper_t, se)`, plus `df_resid`. For
`"mvn"`, a list with `summary_ci` (z/CTmax/T_crit bounds) and `curve_ci`
(per-`temp_grid` line band).

## Examples

``` r
d <- data.frame(
  temp = rep(c(30, 32, 34, 36, 38), each = 12),
  dur  = rep(c(1, 5, 15, 45, 135, 405), times = 10),
  surv = rbinom(60, 20, 0.4), tot = 20)
s2 <- ts_stage2(ts_stage1(d, "temp", "dur", "surv", "tot"))
ts_ci(s2, method = "delta")$z
#> $point
#> [1] NA
#> 
#> $lower
#> [1] NA
#> 
#> $upper
#> [1] NA
#> 
#> $lower_t
#> [1] NA
#> 
#> $upper_t
#> [1] NA
#> 
#> $se
#> [1] NA
#> 
```
