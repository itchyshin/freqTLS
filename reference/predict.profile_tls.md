# Predict survival, link, or midpoint from a fitted freqTLS model

[`predict()`](https://rdrr.io/r/stats/predict.html) evaluates the fitted
four-parameter logistic (4PL) thermal-load- sensitivity model at new
temperature-by-duration cells, using exactly the same forward map as the
TMB engine in `src/profile_tls.cpp`:

## Usage

``` r
# S3 method for class 'profile_tls'
predict(
  object,
  newdata,
  type = c("survival", "link", "midpoint", "parameters"),
  re.form = c("population", "conditional"),
  ...
)

# S3 method for class 'freq_tls'
predict(
  object,
  newdata,
  type = c("survival", "link", "midpoint", "parameters"),
  re.form = c("population", "conditional"),
  ...
)
```

## Arguments

- object:

  A `profile_tls` fit from
  [`fit_tls()`](https://itchyshin.github.io/freqTLS/reference/fit_tls.md).

- newdata:

  A data frame with numeric columns `temp` and `duration`, plus every
  predictor used in the fitted `CTmax`, `log_z`, `low`, `up`, and
  `log_k` fixed designs. Include `group` for a grouped column-interface
  fit. Conditional random-effect predictions additionally require every
  fitted grouping column. `duration` must be strictly positive (it is
  `log10`-transformed). For `type = "midpoint"` or `"parameters"`,
  `duration` may be omitted.

- type:

  One of `"survival"` (default), `"link"`, `"midpoint"`, or
  `"parameters"`.

- re.form:

  How to handle fitted random intercepts. `"population"` (default) sets
  them to zero; `"conditional"` adds the fitted BLUP for each
  random-effect grouping column in `newdata`. When omitted for a random-
  effects fit, [`predict()`](https://rdrr.io/r/stats/predict.html) warns
  that it is returning a population prediction.

- ...:

  Reserved; must be empty.

## Value

For `type = "parameters"`, a data frame with one row per row of
`newdata` and columns `CTmax`, `z`, `low`, `up`, and `k`. Otherwise a
numeric vector with one element per row; survival values lie in
`(0, 1)`.

## Details

Here `CTmax` is the critical thermal maximum at the reference duration
`tref`; `z` is thermal sensitivity in degrees per order-of-magnitude
change in duration; `low` and `up` are the fitted lower and upper
survival asymptotes; and `k` controls the curve's steepness. The model
fits `log_z = log(z)` internally, then reports positive natural-scale
`z` values.

\$\$mid = \log\_{10}(t\_{ref}) - (temp - CTmax_g) / z_g\$\$ \$\$p =
low + (up - low)\\\mathrm{plogis}(-k(\log\_{10}(duration) - mid)).\$\$

Four response types are available:

- `"survival"` (default) returns the fitted survival probability in
  `(0, 1)`.

- `"link"` returns the logit of the survival probability,
  `qlogis(survival)`.

- `"midpoint"` returns the temperature-dependent 4PL midpoint `mid` on
  the `log10(duration)` axis (constant within a temperature, so the
  `duration` column is ignored for this type but a `temp` column is
  still required).

- `"parameters"` returns the row-specific natural-scale `CTmax`, `z`,
  `low`, `up`, and `k` values. This is useful for interacted formula
  designs; the `duration` column may be omitted.

`newdata` must also contain every predictor used by the fitted
fixed-effect designs for `CTmax`, `log_z`, `low`, `up`, or `log_k`. For
a grouped column- interface fit, supply `group` with values from the
fitted `group_levels`. For a formula fit, a literal
[`tls_bf()`](https://itchyshin.github.io/freqTLS/reference/tls_bf.md)
call preserves the fixed-design formulas needed to rebuild transformed
or interacted terms. If the model was instead passed through a
formula-object variable,
[`predict()`](https://rdrr.io/r/stats/predict.html) can rebuild direct
numeric design columns but asks the user to refit with a literal
[`tls_bf()`](https://itchyshin.github.io/freqTLS/reference/tls_bf.md)
call when a transformed or interacted design cannot be recovered safely.

## Examples

``` r
d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
               family = "binomial", tref = 60)
nd <- expand.grid(temp = c(34, 36, 38), duration = c(1, 2, 4))
predict(fit, nd, type = "survival")
#> [1] 0.89445183 0.47691988 0.09003948 0.69738630 0.18571139 0.03695280 0.36162978
#> [8] 0.06378843 0.02386999

# A continuous predictor used by CTmax and log_z must also be in newdata.
d$x <- rep(c(-1, 1), length.out = nrow(d))
fit_x <- fit_tls(
  tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
         CTmax ~ x, log_z ~ x),
  data = d, family = "binomial", tref = 60
)
predict(fit_x, data.frame(temp = 36, duration = 2, x = c(-1, 1)))
#> [1] 0.1678131 0.2048207

# \donttest{
# Choose population or fitted-group prediction explicitly for an RE fit.
dre <- simulate_tls(family = "binomial", CTmax = 36, z = 4,
                    re_sd = 1, n_re_groups = 8, seed = 2)
fit_re <- fit_tls(
  tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
         CTmax ~ 1 + (1 | colony)),
  data = dre, family = "binomial", tref = 60
)
colony <- as.character(ranef(fit_re)$group[1])
nd_re <- data.frame(temp = 36, duration = 2, colony = colony)
predict(fit_re, nd_re, re.form = "population")
#> [1] 0.2124211
predict(fit_re, nd_re, re.form = "conditional")
#> [1] 0.1003736
# }
```
