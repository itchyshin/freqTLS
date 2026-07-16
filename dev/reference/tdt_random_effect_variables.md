# Extract variable names from random-effect terms

Extract variable names from random-effect terms

## Usage

``` r
tdt_random_effect_variables(random_effects = NULL)
```

## Arguments

- random_effects:

  Optional character vector of grouping-variable names or
  random-intercept terms accepted by
  [`tdt_format_random_effects()`](https://itchyshin.github.io/freqTLS/dev/reference/tdt_format_random_effects.md).

## Value

A character vector containing the unique grouping-variable names.
