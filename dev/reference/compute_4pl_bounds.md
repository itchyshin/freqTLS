# Derive 4PL asymptote intervals from a user-supplied response range

Given the lower and upper bounds of where the asymptotes can sit,
returns the disjoint intervals used by
[`make_4pl_formula()`](https://itchyshin.github.io/freqTLS/dev/reference/make_4pl_formula.md)'s
`inv_logit` reparam. `low` is mapped to
`(lower + pad, midpoint - gap/2)`, `up` to
`(midpoint + gap/2, upper - pad)`. The gap kills label-switching by
ensuring `up > low` always; the pad keeps the asymptotes off the exact
boundaries.

## Usage

``` r
compute_4pl_bounds(lower = 0, upper = 1, pad = 0.001, gap = 0.002)
```

## Arguments

- lower, upper:

  Numeric scalars. The response-scale range that the asymptotes can
  occupy (`0` and `1` for proportion data; `0.85` and `1` for PSII-like
  sublethal data, etc.).

- pad:

  Absolute padding from `lower` and `upper`. Default `0.001`.

- gap:

  Absolute gap between the low and up intervals. Default `0.002`.

## Value

Named list with `low_min`, `low_max`, `low_w`, `up_min`, `up_max`,
`up_w`, `midpoint`.
