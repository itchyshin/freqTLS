# Random effects: hierarchical thermal tolerance

This vignette is for a thermal biologist whose survival assays are
**grouped** — colonies, clutches, populations, tanks, broods — and who
wants to model between-group variation without spending a fixed
coefficient on every group. That is exactly what a **random intercept**
does: it treats the per-group deviations as draws from a Gaussian,
estimates a single between-group standard deviation, and **shrinks**
each group’s estimate toward the overall mean (partial pooling). In
`freqTLS` a random intercept is available on the thermal-tolerance
midpoint `CTmax`, the thermal-sensitivity `log_z`, and the shape
coordinates `low` and `log_k`.

``` r

library(freqTLS)
```

## Fixed groups vs. a random intercept

With a handful of well-sampled groups you can give each its own
**fixed** `CTmax` (`CTmax ~ group`, see `vignette("getting-started")`).
With many groups — or groups you regard as a sample from a population —
a **random intercept** `CTmax ~ 1 + (1 | group)` is the better tool: it
costs one variance parameter instead of one coefficient per group, and
the group estimates borrow strength from each other. The deviations
`b_g ~ N(0, sigma_CTmax^2)` are integrated out by `TMB`’s Laplace
approximation; `sigma_CTmax` is estimated by marginal maximum
likelihood. The no-random-effects path is byte-identical to the
fixed-effects model, so adding `(1 | group)` changes nothing when there
is nothing to pool.

## A random intercept on CTmax

We simulate 14 colonies whose CTmax varies with a between-colony SD of
1.5 °C, then fit a single random intercept.

``` r

set.seed(1)
d <- simulate_tls(family = "binomial", CTmax = 36, z = 4,
                  re_sd = 1.5, n_re_groups = 14, seed = 1)
fit <- fit_tls(
  tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
         CTmax ~ 1 + (1 | colony)),
  data = d, family = "binomial", tref = 1, quiet = TRUE)

# The estimates table carries the population CTmax / z and the between-colony SD.
est <- fit$estimates
est[est$parameter %in% c("CTmax", "z", "sigma_CTmax"),
    c("parameter", "estimate", "std.error")]
#>     parameter  estimate  std.error
#> 4       CTmax 36.010947 0.38977872
#> 5           z  3.952015 0.05042902
#> 6 sigma_CTmax  1.454802 0.27579903
```

`sigma_CTmax` is the estimated between-colony standard deviation of
`CTmax`, in °C — directly interpretable on the thermal-tolerance scale.
It is a maximum-likelihood variance component, so it is biased **low**
when there are few groups: it is essentially unbiased by ~14 groups but
increasingly shrunk toward zero below that. A focused recovery study
(`data-raw/re-recovery-study.R`) makes the bias concrete, and shows the
fixed-effect `CTmax` interval losing coverage in step — the empirical
basis for the advisory
[`fit_tls()`](https://itchyshin.github.io/freqTLS/reference/fit_tls.md)
emits below ~8 groups:

| n groups | mean sigma_CTmax | rel. bias | CTmax 95% coverage |
|---------:|-----------------:|----------:|-------------------:|
|        3 |            1.044 |    -0.304 |              0.733 |
|        5 |            1.199 |    -0.200 |              0.853 |
|        8 |            1.352 |    -0.099 |              0.893 |
|       14 |            1.430 |    -0.047 |              0.933 |
|       30 |            1.448 |    -0.035 |              0.920 |

Random-intercept recovery vs number of groups (true sigma_CTmax = 1.5;
150 sims/cell). The ML SD is biased low and the fixed-effect CTmax
interval under-covers with few groups; both settle by ~14 groups.
{.table}

So with only a handful of groups the reported `sigma_CTmax` understates
the true spread and the `CTmax` interval is optimistic; prefer
`confint(method = "bootstrap")` (or `bayesTLS`) for the fixed effects,
and read the variance component as a lower bound.

The conditional modes (BLUPs) — each colony’s shrunken deviation from
the population `CTmax` — come from
[`ranef()`](https://itchyshin.github.io/freqTLS/reference/ranef.md):

``` r

head(ranef(fit), 4)
#> # A tibble: 4 × 4
#>   group term  estimate std.error
#>   <chr> <chr>    <dbl>     <dbl>
#> 1 g1    CTmax   -0.906     0.396
#> 2 g10   CTmax   -0.505     0.396
#> 3 g11   CTmax    2.16      0.396
#> 4 g12   CTmax    0.603     0.396
```

[`confint()`](https://rdrr.io/r/stats/confint.html) gives a positive
(log-scale) Wald interval for `sigma_CTmax`, and a genuine
profile-likelihood interval for the population `CTmax` under the random
effect (each grid point re-runs the Laplace approximation, so it is
slower than a fixed-effects profile):

``` r

suppressMessages(confint(fit, "sigma_CTmax", method = "wald"))[
  , c("parameter", "conf.low", "conf.high")]
#> # A tibble: 1 × 3
#>   parameter   conf.low conf.high
#>   <chr>          <dbl>     <dbl>
#> 1 sigma_CTmax     1.00      2.11
suppressMessages(confint(fit, "CTmax", method = "profile", npoints = 8))[
  , c("parameter", "conf.low", "conf.high", "method")]
#> # A tibble: 1 × 4
#>   parameter conf.low conf.high method 
#>   <chr>        <dbl>     <dbl> <chr>  
#> 1 CTmax         35.2      36.8 profile
```

The Confidence Eye stays on Wald intervals for a random-effects fit (a
profile eye would re-run the Laplace at every grid point for every row),
which is fast and honest — it is still a confidence interval, never a
posterior.

``` r

suppressMessages(plot_confidence_eye(fit, parm = "CTmax"))
```

![Confidence Eye for the population CTmax of a random-intercept fit: a
pale confidence lens with a hollow point estimate near 36 degrees
Celsius, drawn with a Wald interval; a freqTLS uncertainty display, not
a posterior density.](random-effects_files/figure-html/eye-1.png)

## Random effects on sensitivity and curve shape

The same `(1 | group)` syntax works on `log_z` (thermal sensitivity) and
on the shape coordinates `low` (the lower, long-exposure asymptote) and
`log_k` (the steepness). One nuance matters: because `z`, `low`, and `k`
are modelled on transformed scales, their variance components live on
those scales — `sigma_logz` is a SD on `log(z)`, `sigma_low` on
`logit(low)`, `sigma_logk` on `log(k)`. Read `sigma_logz` as an
approximate *multiplicative* spread on `z`: `exp(sigma_logz)` is the
fold-change across groups, not a z-unit SD.

``` r

set.seed(2)
dz <- simulate_tls(family = "binomial", CTmax = 36, z = 4,
                   re_sd_z = 0.3, n_re_groups = 14, seed = 2)
fit_z <- fit_tls(
  tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
         log_z ~ 1 + (1 | colony)),
  data = dz, family = "binomial", tref = 1, quiet = TRUE)
sg <- fit_z$estimates$estimate[fit_z$estimates$parameter == "sigma_logz"]
c(sigma_logz = round(sg, 3),
  approx_fold_spread_in_z = round(exp(sg), 3))
#>              sigma_logz approx_fold_spread_in_z 
#>                   0.265                   1.303
```

The upper asymptote `up` is the **one shape with no random effect**: it
is the nested gap `up = low + (1 - low) * plogis(...)`, which has no
single internal coordinate (the same reason `up` has no
profile-likelihood coordinate). Put the random intercept on `low` or
`log_k` instead.

## Combining random effects, and what is out of scope

You can place random intercepts on more than one coordinate. When two or
more share the **same** grouping factor, `freqTLS` fits them as
**independent** variances (all cross-correlations forced to zero) and
warns:

``` r

set.seed(3)
db <- simulate_tls(family = "binomial", CTmax = 36, z = 4,
                   re_sd = 1.2, re_sd_z = 0.3, n_re_groups = 14, seed = 3)
# Both random intercepts on the same `colony` grouping. This fits, but emits a
# warning that the two variances are independent (no correlation term); we pass
# `quiet = TRUE` to silence it here and discuss it below.
fit_both <- fit_tls(
  tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
         CTmax ~ 1 + (1 | colony), log_z ~ 1 + (1 | colony)),
  data = db, family = "binomial", tref = 1, quiet = TRUE)
fit_both$estimates$parameter[grepl("^sigma", fit_both$estimates$parameter)]
#> [1] "sigma_CTmax" "sigma_logz"
```

In real data the group-level `CTmax` and `z` deviations are usually
correlated; by forcing that correlation to zero, the
independent-variance fit absorbs it into the marginal SDs and the
fixed-effect intervals. If you need a **correlated** random effect — or
crossed/nested grouping factors, or a random *slope* — use
[`bayesTLS`](https://github.com/daniel1noble/bayesTLS), whose Stan back
end fits the full covariance. `freqTLS` deliberately stops at
independent random intercepts on `CTmax` / `log_z` / `low` / `log_k`.

## The likelihood view of shrinkage

A Gaussian random effect *is* a prior on the group deviations, and the
BLUPs are shrunk toward zero exactly as a posterior mean would be — the
empirical-Bayes view of mixed models. What stays prior-free is
everything else: the fixed effects and the variance components are
maximum-likelihood estimates, and their intervals are profile-likelihood
or Wald confidence intervals, not credible intervals. That is the same
complementary stance the rest of `freqTLS` takes toward `bayesTLS` (see
[`vignette("frequentist-and-bayesian")`](https://itchyshin.github.io/freqTLS/articles/frequentist-and-bayesian.md)):
the random effect buys you partial pooling without committing to priors
on the parameters you report. \`\`\`
