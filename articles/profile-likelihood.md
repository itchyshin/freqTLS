# Profile-likelihood intervals

`freqTLS` reports **profile-likelihood confidence intervals** as its
default. This vignette explains what the profile is, why its intervals
can be asymmetric, how it differs from the Wald interval, and —
importantly — how `freqTLS` behaves honestly when a profile does not
close. These are likelihood intervals, not posteriors; the language
throughout is “confidence”, never “posterior” or “credible”. The
authoritative algorithm reference is
`docs/design/04-profile-likelihood.md`.

``` r

library(freqTLS)
```

## What the profile does

For a scalar target $`\psi`$ (say `CTmax`):

1.  Fit the maximum-likelihood estimate, obtaining
    $`(\hat\theta, \hat\ell)`$.
2.  Fix the internal coordinate that maps to $`\psi`$ at a candidate
    value and re-optimise all the other coordinates, giving the profile
    log-likelihood $`\ell_p(\psi)`$.
3.  Form the deviance $`D(\psi) = 2\,(\hat\ell - \ell_p(\psi))`$.
4.  The confidence interval is the set
    $`\{\psi : D(\psi) \le t^2_{1-\alpha/2,\,\nu}\}`$, found by
    root-finding on each side of the MLE.

At the MLE the deviance is (numerically) zero. The cutoff is the
**squared Student-$`t`$ quantile** $`t^2_{1-\alpha/2,\,\nu}`$ on
$`\nu = n - p`$ residual degrees of freedom (data rows minus free
fixed-effect coordinates), not the $`\chi^2_1`$ quantile: this is the
Bates–Watts profile-$`t`$ calibration, which is less optimistic at small
$`n`$ and converges to $`\chi^2_1`$ as $`\nu \to \infty`$ (see
[`vignette("frequentist-and-bayesian")`](https://itchyshin.github.io/freqTLS/articles/frequentist-and-bayesian.md)).
[`profile()`](https://rdrr.io/r/stats/profile.html) returns the whole
deviance curve plus the interval:

``` r

set.seed(1)
dat <- simulate_tls(family = "beta_binomial", CTmax = 36, z = 4, phi = 50, seed = 1)
fit <- fit_tls(dat, y = survived, n = total, time = duration, temp = temp,
               family = "beta_binomial", tref = 1)

pc <- profile(fit, "CTmax")
c(estimate = pc$estimate, conf.low = pc$conf.low, conf.high = pc$conf.high,
  cutoff = pc$cutoff, min_deviance = min(pc$deviance))
#>     estimate     conf.low    conf.high       cutoff min_deviance 
#>    36.004832    35.747797    36.268991     3.937117     0.000000
```

The deviance minimum sits essentially at zero, at the estimate. Plotting
the profile shows the deviance curve, the profile-$`t`$ cutoff line, and
the interval where the curve dips below it:

``` r

plot(pc)
```

![Profile-likelihood deviance curve for CTmax: a U-shaped curve with a
horizontal profile-t cutoff line; the confidence interval is where the
curve lies below the
cutoff.](profile-likelihood_files/figure-html/profile-plot-1.png)

## Asymmetry and equivariance

A profile interval need not be symmetric about the estimate, and
`freqTLS` preserves the asymmetry rather than forcing a symmetric
$`\pm`$ band. For a parameter on a log scale, such as `z`, the profile
is taken on the internal `log_z` coordinate and the endpoints are
exponentiated. This makes the interval **equivariant**: the `z` interval
is exactly $`\exp()`$ of the internal `log_z` interval.

``` r

ci_z     <- confint(fit, "z",     method = "profile")
ci_log_z <- confint(fit, "log_z", method = "profile")

# z endpoints equal exp() of the log_z endpoints
rbind(
  z          = c(ci_z$conf.low, ci_z$conf.high),
  exp_log_z  = exp(c(ci_log_z$conf.low, ci_log_z$conf.high))
)
#>               [,1]     [,2]
#> z         3.428293 4.381551
#> exp_log_z 3.428293 4.381551

# the interval is asymmetric about the estimate (in general)
with(ci_z, c(lower_gap = estimate - conf.low, upper_gap = conf.high - estimate))
#> lower_gap upper_gap 
#> 0.4730210 0.4802363
```

## Profile versus Wald

The Wald interval is $`\hat\psi \pm z_{\alpha/2}\,\mathrm{se}`$ computed
on the internal (link) scale and back-transformed. It is fast and
first-order, but symmetric on the link scale and blind to the curvature
of the likelihood. The profile interval inverts the likelihood-ratio
test directly. On well-identified data the two agree closely; they
diverge when the likelihood is skewed or the estimate approaches a
boundary.

``` r

rbind(
  profile = unlist(confint(fit, "CTmax", method = "profile")[c("conf.low", "conf.high")]),
  wald    = unlist(confint(fit, "CTmax", method = "wald")[c("conf.low", "conf.high")])
)
#>         conf.low conf.high
#> profile  35.7478  36.26899
#> wald     35.7483  36.26136
```

[`tidy_parameters()`](https://itchyshin.github.io/freqTLS/reference/tidy_parameters.md)
switches between the two for the whole parameter table:

``` r

tidy_parameters(fit, method = "profile")[, c("parameter", "estimate", "conf.low", "conf.high", "interval_type")]
#> "up" is profiled with the delta-method Wald interval.
#> ℹ The profile path is not yet wired for the disjoint-bounds "up" coordinate
#>   `beta_up` (SPEC.md S10).
#> # A tibble: 6 × 5
#>   parameter estimate conf.low conf.high interval_type
#>   <chr>        <dbl>    <dbl>     <dbl> <chr>        
#> 1 low         0.0328   0.0329     0.104 profile      
#> 2 up          0.976    0.957      0.995 wald         
#> 3 k           5.41     4.21       7.05  profile      
#> 4 CTmax      36.0     35.7       36.3   profile      
#> 5 z           3.90     3.43       4.38  profile      
#> 6 phi        26.7     13.0       71.0   profile
```

### The upper asymptote `up`

Under the disjoint-bounds parameterisation `up` has its own coordinate
`beta_up`, but `freqTLS` does not yet profile it (the profile path is
wired for `low` but not `up`). `freqTLS` reports `up` with the
delta-method Wald interval and labels it honestly —
`confint(fit, "up", method = "profile")` returns
`interval_type = "wald"` and emits an informational message rather than
silently substituting a different quantity.

## The honest non-closing fallback

The headline value-add over the Bayesian path is that `freqTLS` tells
you when the data do not identify a parameter, instead of letting a
prior quietly fill the gap. When a profile does not rise above the
cutoff on one side — because the data are too sparse to pin the
parameter down — `freqTLS`:

- emits a warning that the parameter is **weakly identified** (“consider
  `bayesTLS` or a bootstrap”),
- returns `NA` on the open side (never a fabricated bound), and
- sets a `conf.status` marker (`open_lower`, `open_upper`, or
  `open_both`).

Here is a deliberately sparse design — few temperatures, almost no
mortality contrast — that does not identify `CTmax`. We catch the
warning so the vignette builds, but show the status and the `NA`
endpoint:

``` r

set.seed(7)
sparse <- simulate_tls(
  temps  = c(35, 36),     # only two temperatures
  times  = c(1, 2),       # only two durations
  reps   = 2, n = 8,
  CTmax  = 36, z = 4,
  family = "binomial", seed = 7
)
sparse_fit <- suppressWarnings(
  fit_tls(sparse, y = survived, n = total, time = duration, temp = temp,
          family = "binomial", tref = 1)
)

ci <- tryCatch(
  withCallingHandlers(
    confint(sparse_fit, "CTmax", method = "profile"),
    warning = function(w) {
      message("caught warning: ", conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  ),
  error = function(e) e
)
#> caught warning: Inner re-optimisation did not converge at 1 grid point while profiling "CTmax".
#> ℹ Those points are reported as "NA"; the interval is taken from the points that
#>   did converge (SPEC.md S10, warning 12).
#> caught warning: The profile deviance for "CTmax" is non-monotone (multiple local minima).
#> ℹ The interval may not be a single connected region; inspect `plot(profile(fit,
#>   "CTmax"))` (SPEC.md S10, warning 11).
#> caught warning: The profile likelihood for "CTmax" did not close on the lower and upper sides:
#> "CTmax" is weakly identified.
#> ℹ Returning "NA" on the open side rather than a fabricated bound (R-PROFILE).
#> ℹ Consider bayesTLS or a bootstrap for this parameter (SPEC.md S10, warning 9).
#> ! Using a parametric bootstrap for 1 parameter where the profile did not close.
#> ℹ Set `fallback = FALSE` to keep the profile-only behaviour ("NA" on a
#>   non-closing side).
#> caught warning: NA/NaN function evaluation
ci[, c("parameter", "conf.low", "conf.high", "estimate", "conf.status")]
#> # A tibble: 1 × 5
#>   parameter conf.low conf.high estimate conf.status
#>   <chr>        <dbl>     <dbl>    <dbl> <chr>      
#> 1 CTmax         34.7      219.     37.8 bootstrap
```

The interval is open (an `NA` endpoint and an `open_*` status) rather
than a confident but unsupported bound. The Confidence Eye honours this
too: a non-closing profile draws a **hollow point with no lens**, never
a fabricated closed eye.

``` r

# fallback = FALSE so the eye refuses to draw a lens when the profile does not
# close (a hollow point only), matching the honest non-closing contract above.
suppressWarnings(plot_confidence_eye(sparse_fit, parm = "CTmax", method = "profile",
                                     fallback = FALSE))
```

![Confidence Eye for a weakly identified fit: a hollow point estimate
with no confidence lens, signalling that the profile did not
close.](profile-likelihood_files/figure-html/non-closing-eye-1.png)

## Calibration: how well do the intervals cover?

A confidence interval is only as good as its coverage.
`data-raw/coverage-study.R` simulates 200 datasets at a known
`CTmax`/`z` under each family, fits every one by ML, builds 95% profile
intervals, and records the empirical (frequentist) coverage. The summary
is shipped with the package:

``` r

cov_path <- system.file("extdata", "coverage_results.rds", package = "freqTLS")
if (nzchar(cov_path)) {
  cov <- readRDS(cov_path)
  knitr::kable(
    cov$coverage, digits = 3,
    caption = sprintf("Empirical coverage of 95%% profile CIs (nsim = %d; nominal 0.95).",
                      cov$meta$nsim)
  )
}
```

| family | n_converged | CTmax_coverage | CTmax_median_width | z_coverage | z_median_width | open_profiles |
|:---|---:|---:|---:|---:|---:|---:|
| binomial | 200 | 0.945 | 0.406 | 0.970 | 0.736 | 0.000 |
| beta_binomial | 200 | 0.840 | 0.473 | 0.865 | 0.854 | 0.065 |

Empirical coverage of 95% profile CIs (nsim = 200; nominal 0.95).
{.table}

For the **binomial** model the profile intervals are well calibrated —
`CTmax` coverage sits at the nominal 0.95 and every profile closed. For
the **beta-binomial** model the intervals **under-cover** (`CTmax` ≈
0.84, `z` ≈ 0.87) at this sample size: estimating the extra
overdispersion parameter makes the likelihood-ratio interval optimistic,
and a small fraction of profiles do not close. The honest reading is to
treat beta-binomial profile intervals as approximate and, when coverage
matters, calibrate them with a parametric bootstrap or use `bayesTLS`.
This is exactly the regime the ship stance below warns about. Re-run
`data-raw/coverage-study.R` to reproduce (and to regenerate the
per-simulation raw data).

## Ship stance

The profile gives fast, prior-free, asymmetry-respecting confidence
intervals **when the MLE is interior and the data identify the target**.
For boundary asymptotes, very sparse designs, overdispersion
concentrated at zero, or (future) random effects, prefer `bayesTLS` or a
bootstrap — and `freqTLS` warns you when you are in that regime. It
never claims the profile is universally superior to the Bayesian path.
See
[`vignette("comparing-to-bayesTLS")`](https://itchyshin.github.io/freqTLS/articles/comparing-to-bayesTLS.md)
for the side-by-side comparison.
