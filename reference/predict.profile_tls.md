# Predict survival, link, or midpoint from a fitted freqTLS model

[`predict()`](https://rdrr.io/r/stats/predict.html) evaluates the fitted
four-parameter logistic (4PL) thermal-load- sensitivity model at new
temperature-by-duration cells, using exactly the same forward map as the
TMB engine in `src/profile_tls.cpp`: \$\$mid = \log\_{10}(t\_{ref}) -
(temp - CTmax_g) / z_g\$\$ \$\$p = low + (up -
low)\\\mathrm{plogis}(-k(\log\_{10}(duration) - mid)).\$\$

## Usage

``` r
# S3 method for class 'profile_tls'
predict(
  object,
  newdata,
  type = c("survival", "link", "midpoint"),
  re.form = c("population", "conditional"),
  ...
)
```

## Arguments

- object:

  A `profile_tls` fit from
  [`fit_tls()`](https://itchyshin.github.io/freqTLS/reference/fit_tls.md).

- newdata:

  A data frame with numeric columns `temp` and `duration` (and `group`
  for a grouped fit). `duration` must be strictly positive (it is
  `log10`-transformed). For `type = "midpoint"`, `duration` may be
  omitted.

- type:

  One of `"survival"` (default), `"link"`, or `"midpoint"`.

- re.form:

  How to handle fitted random intercepts. `"population"` (default) sets
  them to zero; `"conditional"` adds the fitted BLUP for each
  random-effect grouping column in `newdata`. When omitted for a random-
  effects fit, [`predict()`](https://rdrr.io/r/stats/predict.html) warns
  that it is returning a population prediction.

- ...:

  Reserved; must be empty.

## Value

A numeric vector with one element per row of `newdata`. Survival values
lie in `(0, 1)`.

## Details

Three response types are available:

- `"survival"` (default) returns the fitted survival probability in
  `(0, 1)`.

- `"link"` returns the logit of the survival probability,
  `qlogis(survival)`.

- `"midpoint"` returns the temperature-dependent 4PL midpoint `mid` on
  the `log10(duration)` axis (constant within a temperature, so the
  `duration` column is ignored for this type but a `temp` column is
  still required).

For a grouped fit `newdata` must carry a `group` column whose values are
a subset of the fit's `group_levels`; for an ungrouped fit any `group`
column is ignored.

## Examples

``` r
d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
               family = "binomial", tref = 1)
nd <- expand.grid(temp = c(34, 36, 38), duration = c(1, 2, 4))
predict(fit, nd, type = "survival")
#> [1] 0.89445180 0.47691987 0.09003950 0.69738630 0.18571146 0.03695279 0.36162991
#> [8] 0.06378846 0.02386996
```
