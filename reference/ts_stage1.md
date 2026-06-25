# Stage 1 of the classical two-stage TDT pipeline

Fits a separate logistic dose-response curve at each assay temperature
and reads off `log10(LT50)` (the duration at 50% survival). The binomial
family uses [stats::glm](https://rdrr.io/r/stats/glm.html); the
beta-binomial family uses glmmTMB::glmmTMB with a `betabinomial` family
(overdispersion at Stage 1).

## Usage

``` r
ts_stage1(
  data,
  temp = "temp",
  duration = "duration",
  n_surv = "n_surv",
  n_total = "n_total",
  family = c("binomial", "betabinomial")
)
```

## Arguments

- data:

  Data frame with one row per (temperature, duration) replicate.

- temp, duration, n_surv, n_total:

  Column names (strings) for assay temperature (°C), exposure duration,
  survivors, and trials.

- family:

  `"binomial"` or `"betabinomial"`.

## Value

A tibble with one row per temperature: `temp`, `log10_lt50`,
`se_log10_lt50`, `slope`, `phi` (beta-binomial precision, else `NA`),
`finite_ok`, `bracket_ok`, `stage1_ok`.

## Details

Two validity flags are returned so callers can choose their own success
rule: `finite_ok` (finite coefficients, negative non-trivial slope) and
`bracket_ok` (the fitted LT50 lies within the observed duration range,
padded by 0.5 on the log10 scale). `stage1_ok` is their conjunction.

## Examples

``` r
d <- data.frame(
  temp = rep(c(30, 34, 38), each = 12),
  dur  = rep(rep(c(1, 5, 15, 45), 3), times = 3),
  surv = rbinom(36, 20, 0.5), tot = 20)
ts_stage1(d, "temp", "dur", "surv", "tot", family = "binomial")
#> # A tibble: 3 × 8
#>    temp log10_lt50 se_log10_lt50  slope   phi finite_ok bracket_ok stage1_ok
#>   <dbl>      <dbl>         <dbl>  <dbl> <dbl> <lgl>     <lgl>      <lgl>    
#> 1    30      0.186          1.63 -0.120    NA TRUE      TRUE       TRUE     
#> 2    34      1.87           1.22 -0.203    NA TRUE      TRUE       TRUE     
#> 3    38      0.302          1.03 -0.173    NA TRUE      TRUE       TRUE     
```
