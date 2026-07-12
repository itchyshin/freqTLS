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

  A data frame with numeric columns `temp` and `duration`, plus every
  predictor used in the fitted `CTmax`, `log_z`, `low`, `up`, and
  `log_k` fixed designs. Include `group` for a grouped column-interface
  fit. Conditional random-effect predictions additionally require every
  fitted grouping column. `duration` must be strictly positive (it is
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
               family = "binomial", tref = 1)
nd <- expand.grid(temp = c(34, 36, 38), duration = c(1, 2, 4))
predict(fit, nd, type = "survival")
#> [1] 0.89445180 0.47691987 0.09003950 0.69738630 0.18571146 0.03695279 0.36162991
#> [8] 0.06378846 0.02386996

# A continuous predictor used by CTmax and log_z must also be in newdata.
d$x <- rep(c(-1, 1), length.out = nrow(d))
fit_x <- fit_tls(
  tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
         CTmax ~ x, log_z ~ x),
  data = d, family = "binomial", tref = 1
)
predict(fit_x, data.frame(temp = 36, duration = 2, x = c(-1, 1)))
#> [1] 0.2856389 0.3061423

# \donttest{
# Choose population or fitted-group prediction explicitly for an RE fit.
dre <- simulate_tls(family = "binomial", CTmax = 36, z = 4,
                    re_sd = 1, n_re_groups = 8, seed = 2)
fit_re <- fit_tls(
  tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
         CTmax ~ 1 + (1 | colony)),
  data = dre, family = "binomial", tref = 1
)
colony <- as.character(ranef(fit_re)$group[1])
nd_re <- data.frame(temp = 36, duration = 2, colony = colony)
predict(fit_re, nd_re, re.form = "population")
#> [1] 0.2124193
predict(fit_re, nd_re, re.form = "conditional")
#> [1] 0.1003736
# }
```
