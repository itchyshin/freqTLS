# Standardise a raw survival / proportion dataset for the TDT function library

Rewrites user column names into a single project-standard schema and
attaches metadata used by every downstream fitting and prediction
helper. This is the single entry point for raw data — everything else in
the library assumes the output of this function.

## Usage

``` r
standardize_data(
  data,
  temp,
  duration,
  n_total = NULL,
  n_surv = NULL,
  n_dead = NULL,
  survival = NULL,
  mortality = NULL,
  proportion = NULL,
  proportion_eps = 0.001,
  random_effects = NULL,
  duration_unit = "hours",
  temp_mean = NULL
)
```

## Arguments

- data:

  Raw data frame or tibble.

- temp:

  Column name of the assay temperature (°C).

- duration:

  Column name of the exposure duration. The unit is whatever is in the
  source data; record it via `duration_unit`.

- n_total:

  Column name for total individuals per replicate. Required for count
  responses; leave `NULL` (default) for a continuous `proportion`
  response.

- n_surv:

  Column name for survivor counts.

- n_dead:

  Column name for death counts. Converted to `n_surv` via
  `n_surv = n_total - n_dead`.

- survival:

  Column name for survival proportions in `[0, 1]`. Converted to integer
  counts via `n_total`.

- mortality:

  Column name for mortality proportions in `[0, 1]`. Converted to
  `n_surv = round((1 - mortality) * n_total)`.

- proportion:

  Column name for a continuous proportion response in `[0, 1]` with no
  denominator (modelled with a Beta likelihood). Mutually exclusive with
  the count arguments above.

- proportion_eps:

  Half-open clamp applied to `proportion` so values sit strictly inside
  `(0, 1)` (the Beta density is undefined at exactly 0 or 1). Default
  `0.001`.

- random_effects:

  Optional character vector of grouping variables for random effects,
  e.g. `c("Date", "Tank")`. These columns are converted to factors and
  stored in metadata for the fitter to read.

- duration_unit:

  Label for the unit of `duration`, stored in metadata. Default
  `"hours"`.

- temp_mean:

  Value to subtract from `temp` to form `temp_c`. `NULL` (default) uses
  `mean(temp)`. Supply a fixed value to align multiple datasets to a
  common centre.

## Value

A tibble with the standardised columns plus a `"tdt_meta"` attribute
storing `temp_mean`, `duration_unit`, `random_effects`, `response_type`
(`"count"` or `"proportion"`), and `response_var` (the response column
name for a proportion fit, else `NULL`).

## Details

Two response types are supported:

- **Count data** (binomial / beta-binomial): supply `n_total` plus
  **exactly one** of `n_surv`, `n_dead`, `survival`, or `mortality`. The
  other counts are derived and the standardised columns include
  `n_total`, `n_surv`, `n_dead`, `survival`. `response_type` is recorded
  as `"count"`.

- **Continuous proportion** (Beta), e.g. a chlorophyll-fluorescence
  \\F_v/F_m\\ ratio with no denominator: supply `proportion` and omit
  the count arguments. The value is stored in `survival` (clamped into
  the open interval `(proportion_eps, 1 - proportion_eps)` so the Beta
  likelihood is finite); no `n_total`/`n_surv` columns are created.
  `response_type` is recorded as `"proportion"`.

If the dataset spans multiple categories (life stages, species,
populations, etc.), filter to one category before calling this function
and fit a separate model per subset — the fitter does not estimate
category-level effects.

## Examples

``` r
# Count data
raw <- data.frame(
  temperature_C = rep(c(30, 32, 34), each = 4),
  exposure_h    = rep(c(1, 2, 4, 8), times = 3),
  n             = 30L,
  alive         = c(29, 28, 25, 5, 30, 27, 18, 2, 28, 22, 10, 1)
)
standardize_data(raw,
                 temp     = "temperature_C",
                 duration = "exposure_h",
                 n_total  = "n",
                 n_surv   = "alive")
#> # A tibble: 12 × 12
#>    temperature_C exposure_h     n alive  temp duration  logd n_total n_surv
#>            <dbl>      <dbl> <int> <dbl> <dbl>    <dbl> <dbl>   <int>  <dbl>
#>  1            30          1    30    29    30        1 0          30     29
#>  2            30          2    30    28    30        2 0.301      30     28
#>  3            30          4    30    25    30        4 0.602      30     25
#>  4            30          8    30     5    30        8 0.903      30      5
#>  5            32          1    30    30    32        1 0          30     30
#>  6            32          2    30    27    32        2 0.301      30     27
#>  7            32          4    30    18    32        4 0.602      30     18
#>  8            32          8    30     2    32        8 0.903      30      2
#>  9            34          1    30    28    34        1 0          30     28
#> 10            34          2    30    22    34        2 0.301      30     22
#> 11            34          4    30    10    34        4 0.602      30     10
#> 12            34          8    30     1    34        8 0.903      30      1
#> # ℹ 3 more variables: n_dead <dbl>, survival <dbl>, temp_c <dbl>

# Continuous proportion (Beta) data
raw_p <- data.frame(
  temperature_C = rep(c(30, 32, 34), each = 4),
  exposure_h    = rep(c(1, 2, 4, 8), times = 3),
  fvfm_ratio    = c(0.95, 0.9, 0.7, 0.2, 0.92, 0.6, 0.3, 0, 0.8, 0.4, 0.1, 0)
)
standardize_data(raw_p,
                 temp       = "temperature_C",
                 duration   = "exposure_h",
                 proportion = "fvfm_ratio")
#> # A tibble: 12 × 8
#>    temperature_C exposure_h fvfm_ratio  temp duration  logd survival temp_c
#>            <dbl>      <dbl>      <dbl> <dbl>    <dbl> <dbl>    <dbl>  <dbl>
#>  1            30          1       0.95    30        1 0        0.95      -2
#>  2            30          2       0.9     30        2 0.301    0.9       -2
#>  3            30          4       0.7     30        4 0.602    0.7       -2
#>  4            30          8       0.2     30        8 0.903    0.2       -2
#>  5            32          1       0.92    32        1 0        0.92       0
#>  6            32          2       0.6     32        2 0.301    0.6        0
#>  7            32          4       0.3     32        4 0.602    0.3        0
#>  8            32          8       0       32        8 0.903    0.001      0
#>  9            34          1       0.8     34        1 0        0.8        2
#> 10            34          2       0.4     34        2 0.301    0.4        2
#> 11            34          4       0.1     34        4 0.602    0.1        2
#> 12            34          8       0       34        8 0.903    0.001      2
```
