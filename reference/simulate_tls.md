# Simulate survival-count data from the 4PL thermal-load-sensitivity model

`simulate_tls()` draws survival counts from the locked data-generating
process used throughout the freqTLS test suite and benchmarks. It builds
a factorial grid of temperatures by durations by replicates, computes
the true survival probability under the direct-`CTmax`/`z` 4PL (the same
forward map as the TMB engine in `src/profile_tls.cpp`), and draws
binomial or beta-binomial counts. The simulating truth is attached as
`attr(, "truth")`.

## Usage

``` r
simulate_tls(
  temps = seq(30, 42, by = 2),
  times = c(0.5, 1, 2, 4, 8),
  reps = 3,
  n = 20,
  low = 0.02,
  up = 0.98,
  k = 5,
  CTmax = 36,
  z = 3,
  phi = NULL,
  family = c("binomial", "beta_binomial", "beta"),
  group = NULL,
  re_sd = NULL,
  re_sd_z = NULL,
  re_sd_low = NULL,
  re_sd_logk = NULL,
  n_re_groups = NULL,
  re_group_name = "colony",
  tref = 1,
  seed = NULL
)
```

## Arguments

- temps:

  Numeric vector of assay temperatures (degrees C).

- times:

  Numeric vector of exposure durations (native unit, e.g. hours).

- reps:

  Number of replicate observations per temperature-by-duration cell (per
  group).

- n:

  Number of individuals per observation (binomial size).

- low, up:

  Lower and upper survival asymptotes (`0 < low < up < 1`). A scalar
  (shared) or, for a grouped simulation, one value per group.

- k:

  Steepness of the logistic on the `log10(duration)` scale (`k > 0`). A
  scalar (shared) or, for a grouped simulation, one value per group.

- CTmax:

  Critical thermal maximum at `tref`. A scalar (ungrouped) or, for a
  grouped simulation, a vector with one value per group.

- z:

  Thermal sensitivity (`z > 0`). A scalar or, when grouped, a vector
  with one value per group.

- phi:

  Dispersion (sum of Beta shapes); `NULL` for the binomial family.
  Required when `family = "beta_binomial"` or `family = "beta"`.

- family:

  One of `"binomial"`, `"beta_binomial"`, or `"beta"` (a continuous
  proportion in `(0, 1)`, returned in a `prop` column).

- group:

  Optional **atomic** vector of group labels (character, factor, or
  numeric). When supplied, `CTmax` and `z` must each be either a single
  scalar (shared across groups) or a vector with one value per
  *distinct* group level, in the order the levels first appear. Passing
  a list (for example `group = list(A = list(CTmax = 34))`) is an error:
  use the parallel vector API instead, e.g.
  `simulate_tls(group = c("A", "B"), CTmax = c(34, 38), z = c(3, 5))`.

- re_sd:

  Optional standard deviation of a **random intercept on `CTmax`**. When
  supplied (with `n_re_groups`), `n_re_groups` group-level deviations
  `b_g ~ N(0, re_sd)` are drawn and each group's data is generated with
  `CTmax_g = CTmax + b_g`. This is the data-generating analogue of the
  `CTmax ~ 1 + (1 | group)` engine; `CTmax` and `z` must be scalars and
  it cannot be combined with a fixed `group`. The realised deviations
  are returned in `attr(, "truth")$b`.

- re_sd_z:

  Optional standard deviation of a **random intercept on `log(z)`**.
  When supplied (with `n_re_groups`), `n_re_groups` group-level
  deviations `c_g ~ N(0, re_sd_z)` are drawn on the log scale and each
  group's data is generated with `z_g = exp(log(z) + c_g)` (a
  multiplicative spread on `z`). This is the data-generating analogue of
  the `log_z ~ 1 + (1 | group)` engine. It may be combined with `re_sd`
  (both intercepts share the one `re_group_name` grouping); the realised
  log-z deviations are returned in `attr(, "truth")$b_logz`.

- re_sd_low, re_sd_logk:

  Optional standard deviations of **random intercepts on the lower
  asymptote `low` (logit scale)** and on the steepness **`log(k)`** —
  the shape-coordinate analogues of `re_sd` / `re_sd_z`
  (`low_g = plogis(qlogis(low) + d_g)`, `k_g = exp(log(k) + e_g)`; `up`
  tracks `low` by a fixed head-room fraction). The simulator can
  generate these deviations alongside `re_sd` / `re_sd_z`; realised
  deviations are in `attr(, "truth")$b_low` / `$b_logk`.

- n_re_groups:

  Number of random-effect groups (required with any `re_sd*`).

- re_group_name:

  Name of the grouping column added to the output for the random-effect
  mode (default `"colony"`).

- tref:

  Reference time at which `CTmax` is defined (default `1`).

- seed:

  Optional integer seed for reproducibility.

## Value

A base `data.frame` with columns `temp`, `duration`, the true
probability `p`, and (when grouped) `group`. The count families
(`binomial`, `beta_binomial`) add `total` and `survived`; the `beta`
family instead adds a single continuous proportion column `prop`. The
data-generating parameters are attached as `attr(, "truth")`.

## Details

### The `phi` convention

For the beta-binomial family, `phi` is the **sum of the Beta shape
parameters**: counts are drawn as
`prob <- rbeta(a = p * phi, b = (1 - p) * phi)` followed by
`rbinom(n, prob)`. The Beta mean is `p` and its variance is
`p (1 - p) / (phi + 1)`, so **larger `phi` means less overdispersion**
and the binomial is recovered as `phi -> Inf`. This matches the engine's
parameterisation in
[`beta_binomial_tls()`](https://itchyshin.github.io/freqTLS/reference/tls_family.md).

## Examples

``` r
d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
head(d)
#>   temp duration total survived          p
#> 1   30      0.5    20       20 0.97988215
#> 2   32      0.5    20       20 0.97856626
#> 3   34      0.5    20       19 0.96282035
#> 4   36      0.5    20       14 0.80560767
#> 5   38      0.5    20        4 0.27915697
#> 6   40      0.5    20        2 0.04828075
attr(d, "truth")$CTmax
#> [1] 36
```
