# Accessors for an extract_tdt() result

Analogues of the bayesTLS `get_*_summary` / `get_*_draws` accessors.
`*_summary` returns the maximum-likelihood point estimate (in the
compatibility-named `*_median` column) and its bootstrap-percentile
interval. `*_draws` returns one derived estimate from each
parametric-bootstrap refit; these are resampled frequentist estimates,
not posterior draws.

## Usage

``` r
get_z_summary(et)

get_z_draws(et)

get_ctmax_summary(et)

get_ctmax_draws(et)

get_tcrit_summary(et)

get_tcrit_draws(et)
```

## Arguments

- et:

  An
  [`extract_tdt()`](https://itchyshin.github.io/freqTLS/reference/extract_tdt.md)
  result.

## Value

A tibble (see
[`extract_tdt()`](https://itchyshin.github.io/freqTLS/reference/extract_tdt.md)
for the column contract).

## Examples

``` r
# \donttest{
raw <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
dat <- standardize_data(
  raw, temp = "temp", duration = "duration",
  n_total = "total", n_surv = "survived"
)
fit <- fit_4pl(dat, family = "binomial", t_ref = 60, quiet = TRUE)
tdt <- extract_tdt(fit, nboot = 10, seed = 1)
get_z_summary(tdt)
#> # A tibble: 1 × 3
#>   z_median z_lower z_upper
#>      <dbl>   <dbl>   <dbl>
#> 1     4.00    3.65    4.24
get_ctmax_draws(tdt)
#> # A tibble: 10 × 2
#>    .draw CTmax
#>    <int> <dbl>
#>  1     1  28.7
#>  2     2  28.8
#>  3     3  28.9
#>  4     4  28.5
#>  5     5  29.2
#>  6     6  28.5
#>  7     7  28.8
#>  8     8  29.3
#>  9     9  28.5
#> 10    10  29.3
# }
```
