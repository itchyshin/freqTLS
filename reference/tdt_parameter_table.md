# 4PL parameter table (frequentist twin of `tdt_parameter_table`)

Returns the fitted 4PL parameters (`low`, `up`, `k`, `CTmax`, `z`, and
`phi` for over-dispersed families) as point estimates with confidence
intervals, in bayesTLS's `parameter / [group] / median / lower / upper`
shape.

## Usage

``` r
tdt_parameter_table(object, method = NULL, level = 0.95)
```

## Arguments

- object:

  A `freq_tls` fit from
  [`fit_4pl()`](https://itchyshin.github.io/freqTLS/reference/fit_4pl.md)
  (or a `profile_tls` fit).

- method:

  Interval method: `"wald"` (default) or `"profile"`.

- level:

  Confidence level (default 0.95).

## Value

A tibble with `parameter`, `group`, `median`, `lower`, `upper`.

## See also

[`tls()`](https://itchyshin.github.io/freqTLS/reference/tls.md),
[`tidy_parameters()`](https://itchyshin.github.io/freqTLS/reference/tidy_parameters.md)
