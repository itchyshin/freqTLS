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
  thermal-sensitivity structure and must have the same fixed-effect
  model-matrix columns; `up`/`low`/`k` set the 4PL shape. Random
  intercepts are supported on `ctmax`, `z`, `low`, and `k`, but not
  `up`.

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
explicit formula to let a shape vary. `ctmax` and `z` must produce the
same fixed-effect model-matrix columns. Supported random intercepts go
inside the `ctmax`/`z`/`low`/`k` formulas; `up` random effects are not
supported. For example, `ctmax = ~ 1 + (1 | batch)` keeps the same
intercept-only fixed design as the default `z = ~ 1` while adding a
`CTmax` random intercept.

## See also

[`fit_4pl()`](https://itchyshin.github.io/freqTLS/reference/fit_4pl.md),
[`tls_bf()`](https://itchyshin.github.io/freqTLS/reference/tls_bf.md),
[`standardize_data()`](https://itchyshin.github.io/freqTLS/reference/standardize_data.md)

## Examples

``` r
make_4pl_formula()
#> <tls_formula>
#> n_surv | trials(n_total) ~ time(duration) + temp(temp)
#> low ~ 1
#> up ~ 1
#> log_k ~ 1
#> CTmax ~ 1
#> log_z ~ 1
make_4pl_formula(by = "population", family = "binomial")
#> <tls_formula>
#> n_surv | trials(n_total) ~ time(duration) + temp(temp)
#> low ~ 1
#> up ~ 1
#> log_k ~ 1
#> CTmax ~ 0 + population
#> log_z ~ 0 + population
```
