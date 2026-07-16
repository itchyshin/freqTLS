# Diagnose a freqTLS fit (frequentist analogue of `diagnose_tdt_fit`)

The maximum-likelihood analogue of `bayesTLS::diagnose_tdt_fit()`: where
the Bayesian version reports Rhat / ESS / divergences, the freqTLS
version reports optimiser convergence, a positive-definite Hessian, and
the gradient norm at the optimum, with a single `all_pass` flag.

## Usage

``` r
diagnose_tdt_fit(object)
```

## Arguments

- object:

  A `freq_tls` fit from
  [`fit_4pl()`](https://itchyshin.github.io/freqTLS/reference/fit_4pl.md)
  (or a `profile_tls` fit).

## Value

A one-row tibble of convergence diagnostics.

## See also

[`fit_4pl()`](https://itchyshin.github.io/freqTLS/reference/fit_4pl.md),
[`check_tls()`](https://itchyshin.github.io/freqTLS/reference/check_tls.md)

## Examples

``` r
raw <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
dat <- standardize_data(
  raw, temp = "temp", duration = "duration",
  n_total = "total", n_surv = "survived"
)
fit <- fit_4pl(dat, family = "binomial", t_ref = 1, quiet = TRUE)
diagnose_tdt_fit(fit)
#> # A tibble: 1 × 9
#>   converged pd_hessian max_abs_gradient gradient_pass optimizer logLik n_params
#>   <lgl>     <lgl>                 <dbl> <lgl>         <chr>      <dbl>    <int>
#> 1 TRUE      TRUE             0.00000617 TRUE          nlminb     -129.        5
#> # ℹ 2 more variables: AIC <dbl>, all_pass <lgl>
```
