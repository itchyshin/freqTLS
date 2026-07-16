# Response families for thermal-load-sensitivity models

`binomial_tls()` and `beta_binomial_tls()` describe the count response
distribution for
[`fit_tls()`](https://itchyshin.github.io/freqTLS/reference/fit_tls.md),
and `beta_tls()` the continuous-proportion response in `(0, 1)` (e.g.
PSII operating efficiency or relative chlorophyll fluorescence). All
three model survival as a four-parameter logistic function of log10
duration; the beta-binomial and beta families add a dispersion parameter
`phi`.

## Usage

``` r
binomial_tls()

beta_binomial_tls()

beta_tls()
```

## Value

A `tls_family` object: a list with `family`, `family_code` (0 binomial,
1 beta-binomial, 2 beta), and `links` for the natural-scale parameters.

## Details

The `phi` convention for the beta-binomial family is the **sum of the
Beta shape parameters**: for fitted survival probability `p`, counts are
Beta-Binomial with shapes `a = p * phi` and `b = (1 - p) * phi`. Larger
`phi` means *less* overdispersion (the binomial is recovered as `phi`
grows). This matches the simulation convention in
[`simulate_tls()`](https://itchyshin.github.io/freqTLS/reference/simulate_tls.md)
and differs from the precision/size parameterisations used by some other
packages. The `beta` family uses the **same shapes** for the continuous
proportion, `y ~ Beta(p * phi, (1 - p) * phi)`, so `phi` carries the
identical meaning and a larger `phi` again means a tighter response
around the fitted curve.

## Examples

``` r
binomial_tls()
#> $family
#> [1] "binomial"
#> 
#> $family_code
#> [1] 0
#> 
#> $links
#>        low         up          k      CTmax          z 
#>    "logit"    "logit"      "log" "identity"      "log" 
#> 
#> attr(,"class")
#> [1] "tls_family"
beta_binomial_tls()
#> $family
#> [1] "beta_binomial"
#> 
#> $family_code
#> [1] 1
#> 
#> $links
#>        low         up          k      CTmax          z        phi 
#>    "logit"    "logit"      "log" "identity"      "log"      "log" 
#> 
#> attr(,"class")
#> [1] "tls_family"
beta_tls()
#> $family
#> [1] "beta"
#> 
#> $family_code
#> [1] 2
#> 
#> $links
#>        low         up          k      CTmax          z        phi 
#>    "logit"    "logit"      "log" "identity"      "log"      "log" 
#> 
#> attr(,"class")
#> [1] "tls_family"
```
