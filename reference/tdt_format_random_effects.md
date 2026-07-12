# Format bare names as `(1 | name)` random-effect terms

Format bare names as `(1 | name)` random-effect terms

## Usage

``` r
tdt_format_random_effects(random_effects = NULL)
```

## Arguments

- random_effects:

  Optional character vector of grouping-variable names or already
  formatted random-intercept terms.

## Value

A character vector of random-intercept terms. Bare names are wrapped as
`(1 | name)`; `NULL` or an empty input returns
[`character()`](https://rdrr.io/r/base/character.html).
