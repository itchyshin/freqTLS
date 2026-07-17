# Experimental extension: deterministic heat-injury prediction

This page is a freqTLS-only experimental extension built from synthetic
data. It is not a replacement empirical case and does not estimate a
repair process.

``` r

library(freqTLS)
sim <- simulate_tls(family = "beta_binomial", CTmax = 36, z = 4,
                    phi = 50, seed = 42)
fit <- fit_tls(sim, y = survived, n = total, time = duration, temp = temp,
               family = "beta_binomial", tref = 1, quiet = TRUE)
diagnose_tdt_fit(fit)
#> # A tibble: 1 × 9
#>   converged pd_hessian max_abs_gradient gradient_pass optimizer logLik n_params
#>   <lgl>     <lgl>                 <dbl> <lgl>         <chr>      <dbl>    <int>
#> 1 TRUE      TRUE              0.0000184 TRUE          nlminb     -129.        6
#> # ℹ 2 more variables: AIC <dbl>, all_pass <lgl>
```

``` r

trace <- data.frame(
  time = seq(0, 96, by = 0.25)
)
trace$temp <- 27 + 6 * sin(2 * pi * (trace$time - 6) / 24)
```

``` r

injury <- predict_heat_injury(fit, trace)
head(injury)
#>   time     temp         dose      injury  survival
#> 1 0.00 21.00000 0.000000e+00 0.000000000 0.9892557
#> 2 0.25 21.01285 3.627625e-05 0.003627625 0.9892557
#> 3 0.50 21.05133 7.282956e-05 0.007282956 0.9892557
#> 4 0.75 21.11529 1.102256e-04 0.011022563 0.9892557
#> 5 1.00 21.20445 1.490655e-04 0.014906545 0.9892557
#> 6 1.25 21.31842 1.900114e-04 0.019001136 0.9892557
```

``` r

plot_heat_injury(fit, trace, nboot = 50, seed = 42)
```

![Deterministic survival trajectory under a synthetic fluctuating
temperature trace.](heat-injury_files/figure-html/plot-1.png)

The trajectory is a deterministic transformation of the fitted 4PL and
the user-supplied trace.
[`heat_injury_envelope()`](https://itchyshin.github.io/freqTLS/reference/heat_injury_envelope.md)
can add parametric-bootstrap uncertainty from refitted curves. A repair
rate supplied by the user remains an illustrative scenario: freqTLS has
not fitted that rate from damage/recovery data. Use bayesTLS for its
broader Bayesian heat-injury and repair workflow.
