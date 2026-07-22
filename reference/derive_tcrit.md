# Derive the critical temperature at a damage-rate floor (T_crit)

`derive_tcrit()` returns the rate-multiplier critical temperature
`T_crit`: the temperature at which the thermal-damage rate falls to a
chosen low floor `rate`. It is the maximum-likelihood analogue of the
`bayesTLS`
[`extract_tdt()`](https://itchyshin.github.io/freqTLS/reference/extract_tdt.md)
absolute-family `T_crit`, and follows directly from the fitted `CTmax`
and `z`: \$\$T\_{crit} = CTmax + z \\ \log\_{10}(rate / 100).\$\$
Because `rate < 100` makes `log10(rate / 100) < 0` and `z > 0`, `T_crit`
sits below `CTmax`: it is the lower thermal threshold at which damage
becomes negligible (the temperature cutoff a heat-injury accumulation
model treats as "no damage").

## Usage

``` r
derive_tcrit(object, rate = 1, group = NULL)
```

## Arguments

- object:

  A `profile_tls` fit from
  [`fit_tls()`](https://itchyshin.github.io/freqTLS/reference/fit_tls.md).

- rate:

  Damage-rate floor(s), a percentage of the lethal dose per hour
  (strictly positive). A scalar or a vector; default `1`.

- group:

  Optional single group level (grouped fits only; required when the fit
  is grouped).

## Value

A numeric vector of critical temperatures (degrees C), one per `rate`.

## Details

`rate` is a damage-rate floor expressed as a **percentage of the lethal
dose per hour**; `bayesTLS` brackets observed breakpoints with a default
range of `0.1`–`1` %/hour. Unlike the Bayesian path, which samples
`rate` to fold an operational choice into the posterior, freqTLS treats
`rate` as a fixed input and returns the deterministic transform of the
fitted `CTmax` and `z`. To propagate uncertainty, apply the delta method
to the joint [`vcov()`](https://rdrr.io/r/stats/vcov.html) of `CTmax`
and `z`; the separate `CTmax` and `z` confidence intervals do not
combine into a valid interval for `T_crit`. For a random-effects fit
this is a population-level derived quantity; it does not add a group
BLUP (best linear unbiased predictor; see
[`ranef()`](https://itchyshin.github.io/freqTLS/reference/ranef.md)).

`T_crit` assumes a **lethal endpoint**: it is a damage-accumulation
concept, so for sublethal endpoints (knockdown, photosynthetic failure)
the steeper `z` drives it implausibly low. `derive_tcrit()` says so,
once per call.

## See also

[`derive_ctmax()`](https://itchyshin.github.io/freqTLS/reference/derive_ctmax.md)
for the absolute-threshold critical temperature.

## Examples

``` r
d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
               family = "binomial", tref = 60)
derive_tcrit(fit, rate = c(0.1, 1)) # lower thermal thresholds
#> `T_crit` assumes a lethal endpoint; for sublethal data its steeper `z` makes it
#> implausibly low.
#> [1] 16.82266 20.82069
```
