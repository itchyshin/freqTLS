# Diagnose a freqTLS fit (frequentist twin of `diagnose_tdt_fit`)

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
