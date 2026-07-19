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
  t_ref = NULL,
  time_multiplier = NULL,
  TC_rate_range = NULL,
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

  Optional explicit checks against the settings recorded by
  [`ts_stage2()`](https://itchyshin.github.io/freqTLS/reference/ts_stage2.md).
  By default they are inherited. A value that disagrees with the Stage-2
  fit errors rather than silently changing the CTmax convention.

- temp_grid:

  Temperatures for the line band (`"mvn"` only).

- n_sim:

  MVN draws (`"mvn"` only). Default 1000.

- seed:

  RNG seed (`"mvn"` only). Default 123.

## Value

For `"delta"`, a list with `z` and `CTmax`, each
`list(point, lower, upper, lower_t, upper_t, se)`, plus `df_resid`. When
the recorded `t_ref` is exactly 60 minutes, the list also contains the
compatibility alias `CTmax_1hr`, identical to `CTmax`; it is absent for
other reference durations. For `"mvn"`, a list with `summary_ci`
(z/CTmax/T_crit bounds) and `curve_ci` (per-`temp_grid` line band).

## Examples

``` r
d <- simulate_tls(
  family = "binomial", temps = seq(30, 42, by = 2),
  times = c(0.01, 0.03, 0.1, 0.3, 1, 3, 10, 30, 100),
  reps = 4, n = 50, CTmax = 36, z = 4, seed = 42
)
s2 <- ts_stage2(ts_stage1(d, "temp", "duration", "survived", "total"),
                t_ref = 60, time_multiplier = 60)
ts_ci(s2, method = "delta")$z
#> $point
#> [1] 4.083895
#> 
#> $lower
#> [1] 4.002786
#> 
#> $upper
#> [1] 4.165004
#> 
#> $lower_t
#> [1] 3.977516
#> 
#> $upper_t
#> [1] 4.190274
#> 
#> $se
#> [1] 0.04138309
#> 
```
