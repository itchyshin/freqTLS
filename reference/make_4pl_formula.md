# Build a freqTLS 4PL formula from the direct CTmax/z interface

Translates the bayesTLS-style direct-mode arguments (`ctmax`, `z`, `up`,
`low`, `k`, `by`) into the engine's
[`tls_bf()`](https://itchyshin.github.io/freqTLS/reference/tls_bf.md)
`tls_formula` object. Supplying a `ctmax` and/or `z` formula is the
direct parameterisation; `by` is shorthand for grouping CTmax and z by a
single moderator (`~ 0 + by`).

## Usage

``` r
make_4pl_formula(
  ctmax = NULL,
  z = NULL,
  up = NULL,
  low = NULL,
  k = NULL,
  by = NULL,
  family = "beta_binomial"
)
```

## Arguments

- ctmax, z, up, low, k:

  One-sided formulas (or `NULL`). `ctmax`/`z` set the CTmax /
  thermal-sensitivity structure; `up`/`low`/`k` the 4PL shape.

- by:

  Optional single moderator column name; shorthand for
  `ctmax = z = ~ 0 + by` when those are not given explicitly.

- family:

  `"beta_binomial"`, `"binomial"`, or `"beta"` (selects the response
  idiom: `n_surv | trials(n_total)` for counts, bare `survival` for the
  continuous-proportion beta family).

## Value

A `tls_formula` object (as built by
[`tls_bf()`](https://itchyshin.github.io/freqTLS/reference/tls_bf.md)).

## Details

Following the freqTLS constant-shape invariant, the asymptotes and
steepness (`up`, `low`, `k`) default to **shared** (`~ 1`) so the
temperature effect runs through the midpoint (CTmax / z) only; pass an
explicit formula to let a shape vary. Random effects go inside the
`ctmax`/`z`/`up`/`low`/`k` formulas, e.g.
`ctmax = ~ 0 + grp + (1 | batch)`.

## See also

[`fit_4pl()`](https://itchyshin.github.io/freqTLS/reference/fit_4pl.md),
[`tls_bf()`](https://itchyshin.github.io/freqTLS/reference/tls_bf.md),
[`standardize_data()`](https://itchyshin.github.io/freqTLS/reference/standardize_data.md)
