# Quantile wrapper with TDT-friendly defaults

Quantile wrapper with TDT-friendly defaults

## Usage

``` r
tdt_quantile(x, probs = c(0.025, 0.5, 0.975))
```

## Arguments

- x:

  Numeric vector.

- probs:

  Numeric vector of quantile probabilities.

## Value

Numeric vector of length `length(probs)`.

## Examples

``` r
tdt_quantile(rnorm(100))
#> [1] -1.4316545 -0.1061751  1.5475925
```
