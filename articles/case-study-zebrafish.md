# Case 1: zebrafish heat tolerance under normoxia and hyperoxia

This is the frequentist analogue of Case 1 in the [`bayesTLS`
supplement](https://daniel1noble.github.io/bayesTLS/). It uses the same
organism, data, filter, response, formulas, one-hour reference time,
relative threshold, and estimands. Only the inference engine and
uncertainty language differ.

``` r

library(freqTLS)
#> freqTLS 0.1.0
#> Please cite: Noble DWA, Arnold PA, Nakagawa S & Pottier P (2026) A flexible
#>   modelling framework for estimating thermal tolerance and sensitivity.
#>   bioRxiv. doi:10.64898/2026.07.16.738378
#> Run  citation("freqTLS")  for all entries.
#> 
#> Tutorial & online vignette: https://itchyshin.github.io/freqTLS/
```

## Exact data subset

We retain diploid larvae under normoxia and hyperoxia, including the 26
°C normoxia controls. Hypoxia is deliberately excluded: its duration
design does not identify `z` well enough for the canonical comparison.

``` r

data(zebrafish_o2)
zf <- droplevels(subset(
  zebrafish_o2,
  ploidy == "diploid" & oxygen %in% c("normoxia", "hyperoxia")
))
table(zf$oxygen, zf$temp)
#>            
#>              26  38  39  40
#>   normoxia  119 149  23  23
#>   hyperoxia   0  24  23  19
```

``` r

zf_std <- standardize_data(
  zf, temp = "temp", duration = "duration_min",
  n_total = "n_total", n_surv = "n_surv", duration_unit = "minutes"
)
stopifnot(attr(zf_std, "tdt_meta")$duration_unit == "minutes")
```

## Locked model

The response is beta-binomial. `CTmax`, `z`, and `low` vary by oxygen;
`up` and `k` are shared. Because `t_ref = 60` is expressed in the
standardized minute unit, `CTmax` is the relative-midpoint critical
temperature at one hour.

``` r

zf_fit <- fit_4pl(
  zf_std,
  ctmax = ~ 0 + oxygen,
  z = ~ 0 + oxygen,
  low = ~ 0 + oxygen,
  up = ~ 1,
  k = ~ 1,
  family = "beta_binomial",
  t_ref = 60,
  method = "wald",
  quiet = TRUE
)
diagnose_tdt_fit(zf_fit)
#> # A tibble: 1 × 9
#>   converged pd_hessian max_abs_gradient gradient_pass optimizer logLik n_params
#>   <lgl>     <lgl>                 <dbl> <lgl>         <chr>      <dbl>    <int>
#> 1 TRUE      TRUE               0.000195 TRUE          nlminb     -280.        9
#> # ℹ 2 more variables: AIC <dbl>, all_pass <lgl>
```

Always inspect the convergence code, Hessian, gradient, and
[`check_tls()`](https://itchyshin.github.io/freqTLS/reference/check_tls.md)
messages before interpretation. This page uses Wald confidence intervals
and names that method explicitly; profile and bootstrap intervals remain
available for sensitivity checks.

``` r

zf_tls <- tls(zf_fit, by = "oxygen", lethal = FALSE, method = "wald")
zf_table <- zf_tls$summary
names(zf_table)[names(zf_table) == "median"] <- "estimate"
zf_table
#> # A tibble: 4 × 5
#>   oxygen    quantity estimate lower upper
#>   <chr>     <chr>       <dbl> <dbl> <dbl>
#> 1 normoxia  CTmax       38.7  38.4  39.0 
#> 2 hyperoxia CTmax       39.3  39.1  39.5 
#> 3 normoxia  z            6.01  4.37  8.25
#> 4 hyperoxia z            2.50  2.14  2.92
```

The reported quantities are `CTmax` and `z`. `Tcrit` is not reported:
the hyperoxia design lacks a benign-temperature control, and the
supplement marks this case `lethal = FALSE` for extraction.

``` r

plot_confidence_eye(zf_fit, parm = c("CTmax", "z"), method = "wald")
```

![Independently scaled Wald Confidence Eyes for zebrafish CTmax and z
under normoxia and hyperoxia, shown as outlined lenses with hollow
estimates.](case-study-zebrafish_files/figure-html/eye-1.png)

## Interpretation and boundary

`CTmax` asks whether hyperoxia shifts the one-hour thermal limit. `z`
asks whether oxygen changes the rate at which tolerated duration falls
with warming. Agreement with bayesTLS is a useful cross-check, not proof
of correctness: shared data, filter, or model errors can make both
packages agree. Triploid and hypoxia analyses are not silently
substituted here.
