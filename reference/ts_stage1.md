# Stage 1 of the classical two-stage TDT pipeline

Fits a separate logistic dose-response curve at each assay temperature
and reads off `log10(LT50)` (the duration at 50% survival). The binomial
family uses [stats::glm](https://rdrr.io/r/stats/glm.html); the
beta-binomial family uses
[glmmTMB::glmmTMB](https://rdrr.io/pkg/glmmTMB/man/glmmTMB.html) with a
`betabinomial` family (overdispersion at Stage 1).

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
d <- simulate_tls(
  family = "binomial", temps = seq(30, 42, by = 2),
  times = c(0.01, 0.03, 0.1, 0.3, 1, 3, 10, 30, 100),
  reps = 4, n = 50, CTmax = 36, z = 4, seed = 42
)
ts_stage1(d, "temp", "duration", "survived", "total", family = "binomial")
#> # A tibble: 7 × 8
#>    temp log10_lt50 se_log10_lt50 slope   phi finite_ok bracket_ok stage1_ok
#>   <dbl>      <dbl>         <dbl> <dbl> <dbl> <lgl>     <lgl>      <lgl>    
#> 1    30     1.52          0.0373 -2.37    NA TRUE      TRUE       TRUE     
#> 2    32     0.956         0.0307 -2.74    NA TRUE      TRUE       TRUE     
#> 3    34     0.476         0.0277 -3.27    NA TRUE      TRUE       TRUE     
#> 4    36     0.0266        0.0290 -2.99    NA TRUE      TRUE       TRUE     
#> 5    38    -0.468         0.0289 -3.01    NA TRUE      TRUE       TRUE     
#> 6    40    -0.974         0.0302 -2.83    NA TRUE      TRUE       TRUE     
#> 7    42    -1.45          0.0378 -2.24    NA TRUE      TRUE       TRUE     
```
