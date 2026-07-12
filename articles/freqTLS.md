# Getting started with freqTLS

`freqTLS` fits single-stage four-parameter logistic (4PL)
thermal-load-sensitivity (TLS) / thermal death-time models by maximum
likelihood, parameterised **directly in `CTmax` and `z`** (thermal
sensitivity — the temperature rise that cuts the tolerated exposure
roughly tenfold), and returns prior-free **frequentist** confidence
intervals — Wald, profile-likelihood (asymmetry-respecting, the
default), and bootstrap. It is the likelihood complement to the Bayesian
[`bayesTLS`](https://github.com/daniel1noble/bayesTLS) package; the
modelling framework is theirs (see
[`vignette("comparing-to-bayesTLS")`](https://itchyshin.github.io/freqTLS/articles/comparing-to-bayesTLS.md)
for the relationship and credit).

This vignette walks through the core loop: simulate → fit → confidence
intervals → plot. It runs end to end with a small simulation and needs
no Stan, no MCMC, and no internet.

``` r

library(freqTLS)
```

## Simulate a dataset

[`simulate_tls()`](https://itchyshin.github.io/freqTLS/reference/simulate_tls.md)
draws survival counts from the locked data-generating process: a
factorial grid of assay temperatures and exposure durations, with the
4PL evaluated at the supplied true `CTmax`, `z`, and shape parameters.
We use the overdispersed beta-binomial family here; `phi` is its
precision parameter — larger `phi` means *less* overdispersion,
approaching the ordinary binomial as `phi` grows.

``` r

set.seed(1)
dat <- simulate_tls(
  temps  = seq(30, 42, by = 2),
  times  = c(0.5, 1, 2, 4, 8),
  reps   = 3,
  n      = 20,
  CTmax  = 36,
  z      = 4,
  phi    = 50,
  family = "beta_binomial",
  seed   = 1
)
head(dat)
#>   temp duration total survived          p
#> 1   30      0.5    20       20 0.97988215
#> 2   32      0.5    20       18 0.97856626
#> 3   34      0.5    20       20 0.96282035
#> 4   36      0.5    20       17 0.80560767
#> 5   38      0.5    20        3 0.27915697
#> 6   40      0.5    20        2 0.04828075
```

Each row is one temperature-by-duration cell: `survived` out of `total`
individuals survived the exposure. The true parameters used to generate
the data are kept as an attribute, which is handy for checking recovery:

``` r

attr(dat, "truth")[c("CTmax", "z", "phi")]
#> $CTmax
#> [1] 36
#> 
#> $z
#> [1] 4
#> 
#> $phi
#> [1] 50
```

## Standardise and fit the model

`freqTLS` mirrors the `bayesTLS` workflow. First
[`standardize_data()`](https://itchyshin.github.io/freqTLS/reference/standardize_data.md)
names the temperature, duration, and survival-count columns and records
the data contract; then
[`fit_4pl()`](https://itchyshin.github.io/freqTLS/reference/fit_4pl.md)
fits the 4PL by maximum likelihood and returns a `freq_tls` workflow
object. `t_ref` is the reference time at which `CTmax` is defined: the
twin facade
[`fit_4pl()`](https://itchyshin.github.io/freqTLS/reference/fit_4pl.md)
uses the `bayesTLS` spelling `t_ref` (default 60), while the lower-level
engine
[`fit_tls()`](https://itchyshin.github.io/freqTLS/reference/fit_tls.md)
(below) uses `tref` (default 1) — the same quantity, in the data’s
duration unit. The simulated durations here are already in reference
units, so we pass `1`.

``` r

std <- standardize_data(
  dat,
  temp     = "temp",
  duration = "duration",
  n_total  = "total",
  n_surv   = "survived"
)
```

``` r

fit <- fit_4pl(std, family = "beta_binomial", t_ref = 1)
fit
#> <freq_tls>
#>   Data:    105 rows; 7 temperatures; 5 durations
#>   T_bar:   36.00
#>   Family:  beta_binomial (relative threshold, t_ref = 1 hours)
#>   Fit:     converged (pdHess = TRUE); default CI method = profile
```

### Formula interface

For the supported moderators,
[`fit_4pl()`](https://itchyshin.github.io/freqTLS/reference/fit_4pl.md)
takes a **similar direct interface** to `bayesTLS` — `ctmax =`, `z =`,
or the `by =` shorthand (e.g. `by = "life_stage"` for a grouped fit).
Under the hood the engine also exposes a `brms`/`drmTMB`-style grammar
via
[`tls_bf()`](https://itchyshin.github.io/freqTLS/reference/tls_bf.md) —
the left-hand side names the survival counts
(`successes | trials(total)`), the right-hand side tags the two axes
with the [`time()`](https://rdrr.io/r/stats/time.html) and `temp()`
markers — which feeds the same likelihood, so the two fits are
numerically identical:

``` r

fit_f <- fit_tls(
  tls_bf(survived | trials(total) ~ time(duration) + temp(temp)),
  data   = dat,
  family = "beta_binomial",
  tref   = 1
)
all.equal(coef(fit_f), coef(fit))
#> [1] TRUE
```

The grammar scales well beyond a single ungrouped fit: each
sub-parameter can take a grouping factor, a continuous covariate, or an
`lme4`-style random intercept. See **Going further** below.

The print method reports the headline quantities (`CTmax`, `z`), the
shape parameters (`low`, `up`, `k`), the overdispersion `phi`, and the
convergence status. [`summary()`](https://rdrr.io/r/base/summary.html)
adds standard errors and the log-likelihood:

``` r

summary(fit)
#> <freqTLS beta_binomial 4PL fit> summary
#> Call: fit_tls(x = ff, family = fam_name, tref = t_ref, start = start, control =
#> control, trace = trace, quiet = quiet, data = data)
#> Reference time (tref): 1 | family: beta_binomial
#> Data: 105 observations, ungrouped
#> 
#> Coefficients (natural scale; Wald z-test):
#>  parameter group estimate std.error z value  Pr(>|z|)
#>        low         0.0328  0.008901   3.685 2.284e-04
#>         up         0.9761  0.009545 102.300 0.000e+00
#>          k         5.4080  0.684200   7.904 2.696e-15
#>      CTmax   all  36.0000  0.129300 278.500 0.000e+00
#>          z   all   3.9010  0.236600  16.490 4.262e-61
#>        phi        26.6800 10.640000   2.507 1.219e-02
#> Optimiser: nlminb | code 0 | pdHess TRUE | converged (pdHess)
#> logLik -152.8 | df 6 | AIC 317.6
```

A tidy, broom-style table of all natural-scale parameters is available
with
[`tidy_parameters()`](https://itchyshin.github.io/freqTLS/reference/tidy_parameters.md),
and the headline quantities have dedicated extractors:

``` r

tidy_parameters(fit)
#> # A tibble: 6 × 8
#>   parameter group estimate std.error conf.low conf.high interval_type scale   
#>   <chr>     <chr>    <dbl>     <dbl>    <dbl>     <dbl> <chr>         <chr>   
#> 1 low       NA      0.0328   0.00890   0.0191    0.0557 wald          logit   
#> 2 up        NA      0.976    0.00954   0.957     0.995  wald          identity
#> 3 k         NA      5.41     0.684     4.21      6.95   wald          log     
#> 4 CTmax     all    36.0      0.129    35.7      36.3    wald          identity
#> 5 z         all     3.90     0.237     3.46      4.40   wald          log     
#> 6 phi       NA     26.7     10.6      12.1      58.9    wald          log
get_ctmax(fit)
#> # A tibble: 1 × 8
#>   parameter group estimate std.error conf.low conf.high interval_type scale   
#>   <chr>     <chr>    <dbl>     <dbl>    <dbl>     <dbl> <chr>         <chr>   
#> 1 CTmax     all       36.0     0.129     35.7      36.3 wald          identity
get_z(fit)
#> # A tibble: 1 × 8
#>   parameter group estimate std.error conf.low conf.high interval_type scale
#>   <chr>     <chr>    <dbl>     <dbl>    <dbl>     <dbl> <chr>         <chr>
#> 1 z         all       3.90     0.237     3.46      4.40 wald          log
```

## Profile-likelihood confidence intervals

The reason for the direct `CTmax`/`z` parameterisation is that both
headline quantities are model *coordinates*, so they can be profiled
directly. [`confint()`](https://rdrr.io/r/stats/confint.html) with
`method = "profile"` (the default) inverts the likelihood-ratio test:
the interval is the set of values whose deviance from the maximum stays
below the profile-$`t`$ cutoff (a squared Student-$`t`$ quantile on the
residual degrees of freedom, not $`\chi^2_1`$; see
[`vignette("frequentist-and-bayesian")`](https://itchyshin.github.io/freqTLS/articles/frequentist-and-bayesian.md)),
found by root-finding on each side of the MLE.

``` r

confint(fit, parm = "CTmax", method = "profile")
#> # A tibble: 1 × 8
#>   parameter conf.low conf.high estimate level method  scale    conf.status
#>   <chr>        <dbl>     <dbl>    <dbl> <dbl> <chr>   <chr>    <chr>      
#> 1 CTmax         35.7      36.3     36.0  0.95 profile identity ok
confint(fit, parm = "z", method = "profile")
#> # A tibble: 1 × 8
#>   parameter conf.low conf.high estimate level method  scale conf.status
#>   <chr>        <dbl>     <dbl>    <dbl> <dbl> <chr>   <chr> <chr>      
#> 1 z             3.43      4.38     3.90  0.95 profile log   ok
```

These are **confidence** intervals, not posteriors: they carry no prior,
and they need not be symmetric about the estimate. The `conf.status`
column reports `"ok"` when the profile closes on both sides; a weakly
identified parameter is flagged rather than given a fabricated bound
(see
[`vignette("profile-likelihood")`](https://itchyshin.github.io/freqTLS/articles/profile-likelihood.md)).

For comparison, the first-order Wald interval is available with
`method = "wald"`:

``` r

confint(fit, parm = c("CTmax", "z"), method = "wald")
#> # A tibble: 2 × 8
#>   parameter conf.low conf.high estimate level method scale    conf.status
#>   <chr>        <dbl>     <dbl>    <dbl> <dbl> <chr>  <chr>    <chr>      
#> 1 CTmax        35.7      36.3     36.0   0.95 wald   identity ok         
#> 2 z             3.46      4.40     3.90  0.95 wald   log      ok
```

## Plot the fit

[`plot_survival_curves()`](https://itchyshin.github.io/freqTLS/reference/plot_survival_curves.md)
draws the fitted survival probability against exposure duration, one
curve per temperature, with the observed proportions overlaid:

``` r

plot_survival_curves(fit)
```

![Fitted 4PL survival curves: survival probability declining with
exposure duration, one curve per assay temperature, with observed
proportions as points.](freqTLS_files/figure-html/survival-curves-1.png)

The default uncertainty display is the **Confidence Eye**: a pale
confidence lens with a hollow point estimate. It is freqTLS’s visual
identity and deliberately avoids posterior-density iconography, because
these are likelihood intervals. Read the lens **width** as the
confidence interval and the **hollow circle** as the maximum-likelihood
estimate; two eyes that clearly fail to overlap are distinguishable at
the confidence level, and a hollow point with *no* lens flags a profile
that did not close (a weakly identified parameter).

``` r

plot_confidence_eye(fit, parm = c("CTmax", "z"), method = "profile")
```

![Confidence Eye plot: a pale lens spanning the profile-likelihood
interval with a hollow point estimate, for CTmax and
z.](freqTLS_files/figure-html/confidence-eye-1.png)

## Going further: groups, shape predictors, and random effects

The same
[`tls_bf()`](https://itchyshin.github.io/freqTLS/reference/tls_bf.md)
grammar scales from the single fit above to grouped, covariate, and
hierarchical models.

**Other families.** Besides `"beta_binomial"`,
[`fit_tls()`](https://itchyshin.github.io/freqTLS/reference/fit_tls.md)
accepts `"binomial"` (no overdispersion) and `"beta"` (a continuous
proportion in (0, 1) with no trials column; the runnable example below
uses simulated beta data).

**Grouped `CTmax` and `z`.** Put a grouping factor on a sub-parameter to
estimate a separate, directly profile-able `CTmax` and `z` per group,
with one shared curve shape (the `bayesTLS` constant-shape
configuration). In the formula, `z` enters on its internal log scale as
`log_z` (and steepness as `log_k`), so the grouped term is written
`log_z ~ group`. Intervals are still requested by the natural-scale name
(`z:cool`, not `log_z:cool`) —
[`confint()`](https://rdrr.io/r/stats/confint.html) converts internally:

``` r

dat_grp <- simulate_tls(
  temps = seq(30, 42, by = 2), times = c(0.5, 1, 2, 4, 8), reps = 3, n = 20,
  group = c("cool", "warm"), CTmax = c(34, 38), z = c(3, 5),
  phi = 50, family = "beta_binomial", seed = 2
)
fit_grp <- fit_tls(
  tls_bf(
    survived | trials(total) ~ time(duration) + temp(temp),
    CTmax ~ group,
    log_z ~ group
  ),
  data = dat_grp, family = "beta_binomial", tref = 1
)
confint(fit_grp, c("CTmax:cool", "CTmax:warm", "z:cool", "z:warm"),
        method = "profile")
#> # A tibble: 4 × 8
#>   parameter  conf.low conf.high estimate level method  scale    conf.status
#>   <chr>         <dbl>     <dbl>    <dbl> <dbl> <chr>   <chr>    <chr>      
#> 1 CTmax:cool    33.7      34.1     33.9   0.95 profile identity ok         
#> 2 CTmax:warm    37.6      38.2     37.9   0.95 profile identity ok         
#> 3 z:cool         2.47      3.18     2.82  0.95 profile log      ok         
#> 4 z:warm         4.48      5.49     4.98  0.95 profile log      ok
```

**Shape predictors.** The shape parameters are no longer intercept-only:
`low`, `up`, and `log_k` each take their own grouping factor or
continuous covariate (for example `low ~ group` or `log_k ~ body_size`).
See
[`?tls_bf`](https://itchyshin.github.io/freqTLS/reference/tls_bf.md).

**A random intercept.** Add an `lme4`-style `(1 | group)` term to let a
sub-parameter vary across groups drawn from a population — here `CTmax`
varies by `colony`:

``` r

dat_re <- simulate_tls(
  temps = seq(30, 42, by = 2), times = c(0.5, 1, 2, 4, 8), reps = 2, n = 20,
  CTmax = 36, z = 4, phi = 50, family = "beta_binomial",
  re_sd = 1.2, n_re_groups = 10, seed = 3
)
fit_re <- fit_tls(
  tls_bf(
    survived | trials(total) ~ time(duration) + temp(temp),
    CTmax ~ (1 | colony)
  ),
  data = dat_re, family = "beta_binomial", tref = 1
)
fit_re
#> <freqTLS beta_binomial 4PL fit>
#> Call: fit_tls(x = tls_bf(survived | trials(total) ~ time(duration) +
#> temp(temp), CTmax ~ (1 | colony)), family = "beta_binomial", tref = 1, data =
#> dat_re)
#> Reference time (tref): 1 | CTmax defined at this time
#> Data: 700 observations, ungrouped; 7 temperatures in [30, 42], 5 durations in
#> [0.5, 8]
#> 5798 survivors of 14000 trials
#> Random intercept on CTmax: (1 | colony), 10 groups
#> 
#>    parameter group estimate std.error
#>          low        0.02283  0.002510
#>           up        0.98090  0.003458
#>            k        5.29100  0.215600
#>        CTmax   all 35.92000  0.315400
#>            z   all  4.03100  0.083040
#>          phi       49.98000 11.580000
#>  sigma_CTmax        0.98690  0.223500
#> Optimiser: nlminb | code 0 | pdHess TRUE | converged (pdHess)
#> Message: relative convergence (4)
#> logLik -967.4 | df 7 | AIC 1949
head(ranef(fit_re))
#> # A tibble: 6 × 4
#>   group term  estimate std.error
#>   <chr> <chr>    <dbl>     <dbl>
#> 1 g1    CTmax   -1.18      0.330
#> 2 g10   CTmax    1.60      0.330
#> 3 g2    CTmax   -0.173     0.330
#> 4 g3    CTmax    0.257     0.329
#> 5 g4    CTmax   -1.41      0.329
#> 6 g5    CTmax    0.258     0.329
```

The intercept is integrated out by a Laplace approximation;
`sigma_CTmax` is its standard deviation and
[`ranef()`](https://itchyshin.github.io/freqTLS/reference/ranef.md)
returns the per-colony BLUPs. The population `CTmax` interval is
profiled under the random effect (`confint(fit_re, "CTmax")`, the
default), which propagates the variance-component uncertainty that a
Wald interval would understate. Single random intercepts are supported
on `CTmax`, `log_z`, `low`, and `log_k`; see
[`vignette("random-effects")`](https://itchyshin.github.io/freqTLS/articles/random-effects.md)
for the full hierarchical workflow and the few-groups caveats (the
variance components are biased low when fewer than about eight groups
are sampled).

## The core workflow at a glance

`freqTLS` deliberately mirrors the `bayesTLS` workflow, so the same
**standardise → fit → quantities → plot** path runs by maximum
likelihood. The map below shows the main workflow and how each box twins
a `bayesTLS` function. The **“freqTLS extras”** box (gold, upper right)
is the frequentist-only addition — Wald / profile / bootstrap intervals
and the Confidence Eye — and the dashed **“trace & repair helpers —
planned”** box is the one piece not yet ported.

![](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdib3g9IjAgMCAxNTAwIDg4MCIgZm9udC1mYW1pbHk9IkhlbHZldGljYSwgQXJpYWwsIHNhbnMtc2VyaWYiIHdpZHRoPSIxMDAlIiByb2xlPSJpbWciIGFyaWEtbGFiZWxsZWRieT0iZnRscy1tYXAtdGl0bGUgZnRscy1tYXAtZGVzYyI+PHRpdGxlIGlkPSJmdGxzLW1hcC10aXRsZSI+ZnJlcVRMUyBmdW5jdGlvbiBtYXA8L3RpdGxlPgo8ZGVzYyBpZD0iZnRscy1tYXAtZGVzYyI+TWF4aW11bS1saWtlbGlob29kIHR3aW4gb2YgdGhlIGJheWVzVExTIHdvcmtmbG93LiBDb2x1bW5zOiBEQVRBIChzdGFuZGFyZGl6ZV9kYXRhKTsgRklUIChmaXRfNHBsLCB3aXRoIG1ha2VfNHBsX2Zvcm11bGEsIHRpZHlfcGFyYW1ldGVycyBhbmQgdGR0X3BhcmFtZXRlcl90YWJsZSwgYW5kIGRpYWdub3NlX3RkdF9maXQgYW5kIGNoZWNrX3Rscyk7IERFUklWRSAodGxzLCB3aXRoIHRsc196LCB0bHNfY3RtYXggYW5kIHRsc190Y3JpdCwgcGx1cyBleHRyYWN0X3RkdCBhbmQgdGhlIGRlcml2ZV9sdCwgZGVyaXZlX2N0bWF4IGFuZCBkZXJpdmVfdGNyaXQgcHJpbWl0aXZlcyk7IFJFUE9SVCBhbmQgQUNDRVNTIChnZXRfY3RtYXgsIGdldF96IGFuZCBnZXRfc2hhcGUsIGFuZCB0aGUgZ2V0Xypfc3VtbWFyeSBhbmQgZ2V0XypfZHJhd3MgYWNjZXNzb3JzKTsgUFJFRElDVCAocHJlZGljdF9zdXJ2aXZhbF9jdXJ2ZXMgYW5kIHByZWRpY3RfaGVhdF9pbmp1cnksIHdpdGggbWFrZV90ZW1wZXJhdHVyZV9zY2VuYXJpb3MgYW5kIHJlcGFpcl9yYXRlX3NjaG9vbGZpZWxkIG1hcmtlZCBub3QgeWV0IHBvcnRlZCk7IGFuZCBQTE9UICh0aGUgcGxvdF8qIGZhbWlseSwgaW5jbHVkaW5nIHBsb3RfY29uZmlkZW5jZV9leWUpLiBBIHNlcGFyYXRlIHR3by1zdGFnZSBjb21wYXJpc29uIHBhdGggcnVucyB0c19zdGFnZTEgdG8gdHNfc3RhZ2UyIHRvIHRzX2NpIGFuZCB0c19jdXJ2ZS4gQSBoaWdobGlnaHRlZCBib3ggbGlzdHMgdGhlIGZyZXFUTFMtb25seSBleHRyYXM6IFdhbGQsIHByb2ZpbGUgYW5kIGJvb3RzdHJhcCBjb25maWRlbmNlIGludGVydmFscyB3aXRoIHByb2ZpbGUtdCBjYWxpYnJhdGlvbiwgdGhlIENvbmZpZGVuY2UgRXllLCBhbmQgdHdlbHZlIGlkZW50aWZpYWJpbGl0eSB3YXJuaW5ncy48L2Rlc2M+PGRlZnM+PG1hcmtlciBpZD0iYXJyIiBtYXJrZXJ3aWR0aD0iOSIgbWFya2VyaGVpZ2h0PSI5IiByZWZ4PSI3IiByZWZ5PSIzIiBvcmllbnQ9ImF1dG8iPjxwYXRoIGQ9Ik0wLDAgTDcsMyBMMCw2IFoiIGZpbGw9IiM1NTUiIC8+PC9tYXJrZXI+PC9kZWZzPjxyZWN0IHg9IjAiIHk9IjAiIHdpZHRoPSIxNTAwIiBoZWlnaHQ9Ijg4MCIgZmlsbD0iI2ZmZmZmZiIgLz48IS0tIFRpdGxlIC0tPjx0ZXh0IHg9IjQwIiB5PSI0NiIgZm9udC1zaXplPSIyNiIgZm9udC13ZWlnaHQ9ImJvbGQiIGZpbGw9IiMzMzMiPmZyZXFUTFMgZnVuY3Rpb24gbWFwPC90ZXh0Pjx0ZXh0IHg9IjQyIiB5PSI3MiIgZm9udC1zaXplPSIxMyIgZmlsbD0iIzc3NyI+TWF4aW11bS1saWtlbGlob29kIHR3aW4gb2YgdGhlIGJheWVzVExTIHdvcmtmbG93LiBDb3JlIHVzZXIgd29ya2Zsb3c7IHJlcG9ydC9hY2Nlc3MgYW5kIHByZWRpY3Rpb24gYXJlIHBhcmFsbGVsIGRvd25zdHJlYW0gdXNlcy48L3RleHQ+PCEtLSBDb2x1bW4gaGVhZGVyIGNoaXBzIC0tPjxnIGZvbnQtc2l6ZT0iMTIiIGZvbnQtd2VpZ2h0PSJib2xkIiB0ZXh0LWFuY2hvcj0ibWlkZGxlIj48cmVjdCB4PSIxNTAiIHk9Ijk4IiB3aWR0aD0iMTEwIiBoZWlnaHQ9IjI2IiByeD0iNSIgZmlsbD0iI2I2ZDdhOCIgLz48dGV4dCB4PSIyMDUiIHk9IjExNSIgZmlsbD0iIzI3NGUxMyI+REFUQTwvdGV4dD48cmVjdCB4PSIzMzAiIHk9Ijk4IiB3aWR0aD0iMTEwIiBoZWlnaHQ9IjI2IiByeD0iNSIgZmlsbD0iIzlmYzVlOCIgLz48dGV4dCB4PSIzODUiIHk9IjExNSIgZmlsbD0iIzFjNDU4NyI+RklUPC90ZXh0PjxyZWN0IHg9IjU0NSIgeT0iOTgiIHdpZHRoPSIxODAiIGhlaWdodD0iMjYiIHJ4PSI1IiBmaWxsPSIjYjZkN2E4IiAvPjx0ZXh0IHg9IjYzNSIgeT0iMTE1IiBmaWxsPSIjMjc0ZTEzIj5ERVJJVkU8L3RleHQ+PHJlY3QgeD0iODAwIiB5PSI5OCIgd2lkdGg9IjI1MCIgaGVpZ2h0PSIyNiIgcng9IjUiIGZpbGw9IiNiNGE3ZDYiIC8+PHRleHQgeD0iOTI1IiB5PSIxMTUiIGZpbGw9IiMyMDEyNGQiPlJFUE9SVCAvIEFDQ0VTUzwvdGV4dD48cmVjdCB4PSIxMTgwIiB5PSI5OCIgd2lkdGg9IjI0MCIgaGVpZ2h0PSIyNiIgcng9IjUiIGZpbGw9IiNkNWE2YmQiIC8+PHRleHQgeD0iMTMwMCIgeT0iMTE1IiBmaWxsPSIjNGMxMTMwIj5QTE9UPC90ZXh0PjxyZWN0IHg9IjgwMCIgeT0iNDU4IiB3aWR0aD0iMTIwIiBoZWlnaHQ9IjI2IiByeD0iNSIgZmlsbD0iI2Y5Y2I5YyIgLz48dGV4dCB4PSI4NjAiIHk9IjQ3NSIgZmlsbD0iIzc4M2YwNCI+UFJFRElDVDwvdGV4dD48L2c+PCEtLSA9PT09PT09PT09PT0gQVJST1dTIChkcmF3biBmaXJzdCwgdW5kZXIgYm94ZXMpID09PT09PT09PT09PSAtLT48ZyBmaWxsPSJub25lIiBzdHJva2U9IiM4ODgiIHN0cm9rZS13aWR0aD0iMS42IiBzdHJva2UtZGFzaGFycmF5PSI1LDQiPjxwYXRoIGQ9Ik0xMjggMzM1IEwxNDggMzM1IiBtYXJrZXItZW5kPSJ1cmwoI2FycikiIC8+PCEtLSByYXcgLT4gc3RhbmRhcmRpemUgLS0+PHBhdGggZD0iTTQxNSAyNDYgTDQxNSAyODYiIG1hcmtlci1lbmQ9InVybCgjYXJyKSIgLz48IS0tIG1vZGVsIHNwZWMgLT4gZml0IC0tPjxwYXRoIGQ9Ik02MzUgMTcyIEw2MzUgMjEwIiBtYXJrZXItZW5kPSJ1cmwoI2FycikiIC8+PCEtLSBtYW51YWwgZml0IC0+IHRscyAtLT48cGF0aCBkPSJNNjM1IDQwOCBMNjM1IDQ2MCIgbWFya2VyLWVuZD0idXJsKCNhcnIpIiAvPjwhLS0gZXh0cmFjdCAtPiBhZHZhbmNlZCAtLT48cGF0aCBkPSJNOTE3IDY4OCBMOTE3IDY2OCIgbWFya2VyLWVuZD0idXJsKCNhcnIpIiAvPjwhLS0gaGVscGVycyAtPiBoZWF0IGluanVyeSAtLT48cGF0aCBkPSJNNDEwIDgwOSBMNDY4IDgwOSIgbWFya2VyLWVuZD0idXJsKCNhcnIpIiAvPjwhLS0gdHMxIC0+IHRzMiAtLT48cGF0aCBkPSJNNjMwIDgwOSBMNjg4IDgwOSIgbWFya2VyLWVuZD0idXJsKCNhcnIpIiAvPjwhLS0gdHMyIC0+IHRzX2NpIC0tPjwvZz48ZyBmaWxsPSJub25lIiBzdHJva2U9IiM1NTUiIHN0cm9rZS13aWR0aD0iMS44Ij48cGF0aCBkPSJNMzEwIDMzNiBMMzI4IDMzNiIgbWFya2VyLWVuZD0idXJsKCNhcnIpIiAvPjwhLS0gc3RhbmRhcmRpemUgLT4gZml0IC0tPjxwYXRoIGQ9Ik00MTUgMzg0IEw0MTUgNDM4IiBtYXJrZXItZW5kPSJ1cmwoI2FycikiIC8+PCEtLSBmaXQgLT4gdGlkeV9wYXJhbWV0ZXJzIC0tPjxwYXRoIGQ9Ik01MDAgMzIyIEw1NDMgMjUyIiBtYXJrZXItZW5kPSJ1cmwoI2FycikiIC8+PCEtLSBmaXQgLT4gdGxzIC0tPjxwYXRoIGQ9Ik01MDAgMzUyIEw1NDMgMzYwIiBtYXJrZXItZW5kPSJ1cmwoI2FycikiIC8+PCEtLSBmaXQgLT4gZXh0cmFjdCAtLT48cGF0aCBkPSJNNzI1IDI1MCBMNzk4IDI1MSIgbWFya2VyLWVuZD0idXJsKCNhcnIpIiAvPjwhLS0gdGxzIC0+IGdldF9jdG1heCAtLT48cGF0aCBkPSJNNzI1IDM2MCBMNzk4IDM2MCIgbWFya2VyLWVuZD0idXJsKCNhcnIpIiAvPjwhLS0gZXh0cmFjdCAtPiBhY2Nlc3NvcnMgLS0+PHBhdGggZD0iTTEwNTAgMjUxIEwxMTc4IDM4NCIgbWFya2VyLWVuZD0idXJsKCNhcnIpIiAvPjwhLS0gZ2V0X2N0bWF4IC0+IHBsb3QgLS0+PHBhdGggZD0iTTEwNTAgMzYwIEwxMTc4IDM5NiIgbWFya2VyLWVuZD0idXJsKCNhcnIpIiAvPjwhLS0gYWNjZXNzb3JzIC0+IHBsb3QgLS0+PHBhdGggZD0iTTEwMzUgNTI4IEwxMTc4IDQyNCIgbWFya2VyLWVuZD0idXJsKCNhcnIpIiAvPjwhLS0gcHJlZCBzdXJ2IC0+IHBsb3QgLS0+PHBhdGggZD0iTTEwMzUgNjI2IEwxMTc4IDQ0NCIgbWFya2VyLWVuZD0idXJsKCNhcnIpIiAvPjwhLS0gcHJlZCBoZWF0IC0+IHBsb3QgLS0+PHBhdGggZD0iTTUwMCAzNjYgTDUxNSAzNjYgTDUxNSA1MjggTDc5OCA1MjgiIG1hcmtlci1lbmQ9InVybCgjYXJyKSIgLz48IS0tIGZpdCAtPiBwcmVkIHN1cnYgLS0+PHBhdGggZD0iTTUwMCAzNzYgTDUxNSAzNzYgTDUxNSA2MjYgTDc5OCA2MjYiIG1hcmtlci1lbmQ9InVybCgjYXJyKSIgLz48IS0tIGZpdCAtPiBwcmVkIGhlYXQgLS0+PC9nPjwhLS0gPT09PT09PT09PT09IEJPWEVTID09PT09PT09PT09PSAtLT48IS0tIHJhdyBkYXRhIC0tPjxnIHRleHQtYW5jaG9yPSJtaWRkbGUiPjxyZWN0IHg9IjI0IiB5PSIzMDAiIHdpZHRoPSIxMDQiIGhlaWdodD0iNzAiIHJ4PSI3IiBmaWxsPSIjZmZmZmZmIiBzdHJva2U9IiNiYmJiYmIiIC8+PHRleHQgeD0iNzYiIHk9IjMzMiIgZm9udC1zaXplPSIxMyIgZm9udC13ZWlnaHQ9ImJvbGQiIGZpbGw9IiM0NDQiPnJhdyBkYXRhPC90ZXh0Pjx0ZXh0IHg9Ijc2IiB5PSIzNTAiIGZvbnQtc2l6ZT0iOS41IiBmaWxsPSIjNzc3Ij5jb3VudHMgb3I8L3RleHQ+PHRleHQgeD0iNzYiIHk9IjM2MiIgZm9udC1zaXplPSI5LjUiIGZpbGw9IiM3NzciPnByb3BvcnRpb25zPC90ZXh0PjwvZz48IS0tIHN0YW5kYXJkaXplX2RhdGEgLS0+PGcgdGV4dC1hbmNob3I9Im1pZGRsZSI+PHJlY3QgeD0iMTUwIiB5PSIyODgiIHdpZHRoPSIxNjAiIGhlaWdodD0iOTYiIHJ4PSI3IiBmaWxsPSIjZDllYWQzIiBzdHJva2U9IiM5M2M0N2QiIC8+PHRleHQgeD0iMjMwIiB5PSIzMzQiIGZvbnQtc2l6ZT0iMTUiIGZvbnQtd2VpZ2h0PSJib2xkIiBmaWxsPSIjMjc0ZTEzIj5zdGFuZGFyZGl6ZV9kYXRhKCk8L3RleHQ+PHRleHQgeD0iMjMwIiB5PSIzNTYiIGZvbnQtc2l6ZT0iMTAuNSIgZmlsbD0iIzY2NiI+c2NoZW1hICsgbWV0YWRhdGE8L3RleHQ+PC9nPjwhLS0gbW9kZWwgc3BlYyBoZWxwZXJzIC0tPjxnIHRleHQtYW5jaG9yPSJtaWRkbGUiPjxyZWN0IHg9IjMzMCIgeT0iMTgyIiB3aWR0aD0iMTcwIiBoZWlnaHQ9IjY0IiByeD0iNyIgZmlsbD0iI2VmZWZlZiIgc3Ryb2tlPSIjYjdiN2I3IiBzdHJva2UtZGFzaGFycmF5PSI1LDQiIC8+PHRleHQgeD0iNDE1IiB5PSIyMDMiIGZvbnQtc2l6ZT0iMTEuNSIgZm9udC13ZWlnaHQ9ImJvbGQiIGZpbGw9IiM1NTUiPm1vZGVsIHNwZWMgaGVscGVyczwvdGV4dD48dGV4dCB4PSI0MTUiIHk9IjIyMSIgZm9udC1zaXplPSI5LjUiIGZpbGw9IiM3NzciPm1ha2VfNHBsX2Zvcm11bGEoKTsgdGxzX2JmKCk8L3RleHQ+PHRleHQgeD0iNDE1IiB5PSIyMzQiIGZvbnQtc2l6ZT0iOS41IiBmaWxsPSIjNzc3Ij5ncmFtbWFyIOKAlCBubyBwcmlvcnMgKE1MKTwvdGV4dD48L2c+PCEtLSBmaXRfNHBsIC0tPjxnIHRleHQtYW5jaG9yPSJtaWRkbGUiPjxyZWN0IHg9IjMzMCIgeT0iMjg4IiB3aWR0aD0iMTcwIiBoZWlnaHQ9Ijk2IiByeD0iNyIgZmlsbD0iI2NmZTJmMyIgc3Ryb2tlPSIjNmZhOGRjIiAvPjx0ZXh0IHg9IjQxNSIgeT0iMzMyIiBmb250LXNpemU9IjE2IiBmb250LXdlaWdodD0iYm9sZCIgZmlsbD0iIzFjNDU4NyI+Zml0XzRwbCgpPC90ZXh0Pjx0ZXh0IHg9IjQxNSIgeT0iMzU0IiBmb250LXNpemU9IjEwLjUiIGZpbGw9IiM2NjYiPmpvaW50IE1MIDRQTCB3b3JrZmxvdzwvdGV4dD48L2c+PCEtLSB0aWR5X3BhcmFtZXRlcnMgKD0gZ2V0XzRwbF9lc3QpIC0tPjxnIHRleHQtYW5jaG9yPSJtaWRkbGUiPjxyZWN0IHg9IjMzMCIgeT0iNDQwIiB3aWR0aD0iMTcwIiBoZWlnaHQ9Ijc0IiByeD0iNyIgZmlsbD0iI2Q5ZDJlOSIgc3Ryb2tlPSIjOGU3Y2MzIiAvPjx0ZXh0IHg9IjQxNSIgeT0iNDY4IiBmb250LXNpemU9IjEzLjUiIGZvbnQtd2VpZ2h0PSJib2xkIiBmaWxsPSIjMjAxMjRkIj50aWR5X3BhcmFtZXRlcnMoKTwvdGV4dD48dGV4dCB4PSI0MTUiIHk9IjQ4NiIgZm9udC1zaXplPSI5LjUiIGZpbGw9IiM2NjYiPisgdGR0X3BhcmFtZXRlcl90YWJsZSgpPC90ZXh0Pjx0ZXh0IHg9IjQxNSIgeT0iNDk5IiBmb250LXNpemU9IjkuNSIgZmlsbD0iIzY2NiI+NFBMIHBhcmFtcywgYm9vdHN0cmFwIGRyYXdzPC90ZXh0PjwvZz48IS0tIGRpYWdub3N0aWNzIC0tPjxnIHRleHQtYW5jaG9yPSJtaWRkbGUiPjxyZWN0IHg9IjMzMCIgeT0iNTM2IiB3aWR0aD0iMTcwIiBoZWlnaHQ9IjY2IiByeD0iNyIgZmlsbD0iI2VmZWZlZiIgc3Ryb2tlPSIjYjdiN2I3IiBzdHJva2UtZGFzaGFycmF5PSI1LDQiIC8+PHRleHQgeD0iNDE1IiB5PSI1NTciIGZvbnQtc2l6ZT0iMTEuNSIgZm9udC13ZWlnaHQ9ImJvbGQiIGZpbGw9IiM1NTUiPmRpYWdub3N0aWNzPC90ZXh0Pjx0ZXh0IHg9IjQxNSIgeT0iNTc1IiBmb250LXNpemU9IjkuNSIgZmlsbD0iIzc3NyI+ZGlhZ25vc2VfdGR0X2ZpdCgpOyBjaGVja190bHMoKTwvdGV4dD48dGV4dCB4PSI0MTUiIHk9IjU4OCIgZm9udC1zaXplPSI5LjUiIGZpbGw9IiM3NzciPmNvbnZlcmdlbmNlLCBwZEhlc3MsIDEyIHdhcm5pbmdzPC90ZXh0PjwvZz48IS0tIG1hbnVhbCBUTUIgZml0IC0tPjxnIHRleHQtYW5jaG9yPSJtaWRkbGUiPjxyZWN0IHg9IjU0NSIgeT0iMTIwIiB3aWR0aD0iMTgwIiBoZWlnaHQ9IjUyIiByeD0iNyIgZmlsbD0iI2VmZWZlZiIgc3Ryb2tlPSIjYjdiN2I3IiBzdHJva2UtZGFzaGFycmF5PSI1LDQiIC8+PHRleHQgeD0iNjM1IiB5PSIxNDAiIGZvbnQtc2l6ZT0iMTEuNSIgZm9udC13ZWlnaHQ9ImJvbGQiIGZpbGw9IiM1NTUiPm1hbnVhbCBUTUIgZml0PC90ZXh0Pjx0ZXh0IHg9IjYzNSIgeT0iMTU3IiBmb250LXNpemU9IjkuNSIgZmlsbD0iIzc3NyI+Zml0X3RscygpIOKAlCBvcHRpb25hbCBpbnB1dCB0byB0bHMoKTwvdGV4dD48L2c+PCEtLSB0bHMoKSAtLT48ZyB0ZXh0LWFuY2hvcj0ibWlkZGxlIj48cmVjdCB4PSI1NDUiIHk9IjIxMiIgd2lkdGg9IjE4MCIgaGVpZ2h0PSI4NiIgcng9IjciIGZpbGw9IiNkOWVhZDMiIHN0cm9rZT0iIzkzYzQ3ZCIgLz48dGV4dCB4PSI2MzUiIHk9IjI0OCIgZm9udC1zaXplPSIxNiIgZm9udC13ZWlnaHQ9ImJvbGQiIGZpbGw9IiMyNzRlMTMiPnRscygpPC90ZXh0Pjx0ZXh0IHg9IjYzNSIgeT0iMjY4IiBmb250LXNpemU9IjkuNSIgZmlsbD0iIzY2NiI+aGVhZGxpbmUgZXh0cmFjdG9yPC90ZXh0Pjx0ZXh0IHg9IjYzNSIgeT0iMjgxIiBmb250LXNpemU9IjkuNSIgZmlsbD0iIzY2NiI+KyB0bHNfeiAvIHRsc19jdG1heCAvIHRsc190Y3JpdDwvdGV4dD48L2c+PCEtLSBleHRyYWN0X3RkdCgpIC0tPjxnIHRleHQtYW5jaG9yPSJtaWRkbGUiPjxyZWN0IHg9IjU0NSIgeT0iMzIyIiB3aWR0aD0iMTgwIiBoZWlnaHQ9Ijg2IiByeD0iNyIgZmlsbD0iI2Q5ZWFkMyIgc3Ryb2tlPSIjOTNjNDdkIiAvPjx0ZXh0IHg9IjYzNSIgeT0iMzU2IiBmb250LXNpemU9IjE1IiBmb250LXdlaWdodD0iYm9sZCIgZmlsbD0iIzI3NGUxMyI+ZXh0cmFjdF90ZHQoKTwvdGV4dD48dGV4dCB4PSI2MzUiIHk9IjM3NyIgZm9udC1zaXplPSI5LjUiIGZpbGw9IiM2NjYiPmJ1bmRsZSB6LCBDVG1heCw8L3RleHQ+PHRleHQgeD0iNjM1IiB5PSIzOTAiIGZvbnQtc2l6ZT0iOS41IiBmaWxsPSIjNjY2Ij5UX2NyaXQsIExUIGN1cnZlPC90ZXh0PjwvZz48IS0tIGFkdmFuY2VkIHByaW1pdGl2ZXMgLS0+PGcgdGV4dC1hbmNob3I9Im1pZGRsZSI+PHJlY3QgeD0iNTM1IiB5PSI0NjIiIHdpZHRoPSIyMDAiIGhlaWdodD0iNzIiIHJ4PSI3IiBmaWxsPSIjZWZlZmVmIiBzdHJva2U9IiNiN2I3YjciIHN0cm9rZS1kYXNoYXJyYXk9IjUsNCIgLz48dGV4dCB4PSI2MzUiIHk9IjQ4NCIgZm9udC1zaXplPSIxMS41IiBmb250LXdlaWdodD0iYm9sZCIgZmlsbD0iIzU1NSI+YWR2YW5jZWQgcHJpbWl0aXZlczwvdGV4dD48dGV4dCB4PSI2MzUiIHk9IjUwMiIgZm9udC1zaXplPSI5LjUiIGZpbGw9IiM3NzciPmRlcml2ZV9sdCgpOyBkZXJpdmVfY3RtYXgoKTs8L3RleHQ+PHRleHQgeD0iNjM1IiB5PSI1MTUiIGZvbnQtc2l6ZT0iOS41IiBmaWxsPSIjNzc3Ij5kZXJpdmVfdGNyaXQoKTwvdGV4dD48L2c+PCEtLSBnZXRfY3RtYXggLyBnZXRfeiAvIGdldF9zaGFwZSAoPSBnZXRfdGxzX2VzdCkgLS0+PGcgdGV4dC1hbmNob3I9Im1pZGRsZSI+PHJlY3QgeD0iODAwIiB5PSIyMTIiIHdpZHRoPSIyNTAiIGhlaWdodD0iODIiIHJ4PSI3IiBmaWxsPSIjZDlkMmU5IiBzdHJva2U9IiM4ZTdjYzMiIC8+PHRleHQgeD0iOTI1IiB5PSIyNDUiIGZvbnQtc2l6ZT0iMTQiIGZvbnQtd2VpZ2h0PSJib2xkIiBmaWxsPSIjMjAxMjRkIj5nZXRfY3RtYXgoKSDCtyBnZXRfeigpPC90ZXh0Pjx0ZXh0IHg9IjkyNSIgeT0iMjYzIiBmb250LXNpemU9IjE0IiBmb250LXdlaWdodD0iYm9sZCIgZmlsbD0iIzIwMTI0ZCI+Z2V0X3NoYXBlKCk8L3RleHQ+PHRleHQgeD0iOTI1IiB5PSIyODIiIGZvbnQtc2l6ZT0iOS41IiBmaWxsPSIjNjY2Ij5maXQg4oaSIHBhcmFtZXRlciBzdW1tYXJpZXM8L3RleHQ+PC9nPjwhLS0gYWNjZXNzb3JzIC0tPjxnIHRleHQtYW5jaG9yPSJtaWRkbGUiPjxyZWN0IHg9IjgwMCIgeT0iMzIyIiB3aWR0aD0iMjUwIiBoZWlnaHQ9IjgyIiByeD0iNyIgZmlsbD0iI2Q5ZDJlOSIgc3Ryb2tlPSIjOGU3Y2MzIiAvPjx0ZXh0IHg9IjkyNSIgeT0iMzUyIiBmb250LXNpemU9IjEzLjUiIGZvbnQtd2VpZ2h0PSJib2xkIiBmaWxsPSIjMjAxMjRkIj5nZXRfKl9zdW1tYXJ5KCkgwrcgZ2V0XypfZHJhd3MoKTwvdGV4dD48dGV4dCB4PSI5MjUiIHk9IjM3MiIgZm9udC1zaXplPSI5LjUiIGZpbGw9IiM2NjYiPnBlci1xdWFudGl0eSBzdW1tYXJpZXM8L3RleHQ+PHRleHQgeD0iOTI1IiB5PSIzODUiIGZvbnQtc2l6ZT0iOS41IiBmaWxsPSIjNjY2Ij4rIGJvb3RzdHJhcCBkcmF3czwvdGV4dD48L2c+PCEtLSBwcmVkaWN0X3N1cnZpdmFsX2N1cnZlcyAtLT48ZyB0ZXh0LWFuY2hvcj0ibWlkZGxlIj48cmVjdCB4PSI4MDAiIHk9IjQ5MiIgd2lkdGg9IjIzNSIgaGVpZ2h0PSI3NCIgcng9IjciIGZpbGw9IiNmY2U1Y2QiIHN0cm9rZT0iI2Y2YjI2YiIgLz48dGV4dCB4PSI5MTciIHk9IjUyMiIgZm9udC1zaXplPSIxNC41IiBmb250LXdlaWdodD0iYm9sZCIgZmlsbD0iIzc4M2YwNCI+cHJlZGljdF9zdXJ2aXZhbF9jdXJ2ZXMoKTwvdGV4dD48dGV4dCB4PSI5MTciIHk9IjU0MiIgZm9udC1zaXplPSI5LjUiIGZpbGw9IiM2NjYiPnRlbXAgw5cgZHVyYXRpb24gZ3JpZDwvdGV4dD48dGV4dCB4PSI5MTciIHk9IjU1NSIgZm9udC1zaXplPSI5LjUiIGZpbGw9IiM2NjYiPigrIHByZWRpY3Rfc3Vydml2YWxfc3VyZmFjZSk8L3RleHQ+PC9nPjwhLS0gcHJlZGljdF9oZWF0X2luanVyeSAtLT48ZyB0ZXh0LWFuY2hvcj0ibWlkZGxlIj48cmVjdCB4PSI4MDAiIHk9IjU4NiIgd2lkdGg9IjIzNSIgaGVpZ2h0PSI4MCIgcng9IjciIGZpbGw9IiNmY2U1Y2QiIHN0cm9rZT0iI2Y2YjI2YiIgLz48dGV4dCB4PSI5MTciIHk9IjYxOCIgZm9udC1zaXplPSIxNC41IiBmb250LXdlaWdodD0iYm9sZCIgZmlsbD0iIzc4M2YwNCI+cHJlZGljdF9oZWF0X2luanVyeSgpPC90ZXh0Pjx0ZXh0IHg9IjkxNyIgeT0iNjM4IiBmb250LXNpemU9IjkuNSIgZmlsbD0iIzY2NiI+ZHluYW1pYyB0cmFjZXM8L3RleHQ+PHRleHQgeD0iOTE3IiB5PSI2NTEiIGZvbnQtc2l6ZT0iOS41IiBmaWxsPSIjNjY2Ij4oKyBoZWF0X2luanVyeV9lbnZlbG9wZSk8L3RleHQ+PC9nPjwhLS0gdHJhY2UgJiByZXBhaXIgaGVscGVycyAocGxhbm5lZCkgLS0+PGcgdGV4dC1hbmNob3I9Im1pZGRsZSI+PHJlY3QgeD0iODAwIiB5PSI2ODgiIHdpZHRoPSIyMzUiIGhlaWdodD0iNTYiIHJ4PSI3IiBmaWxsPSIjZjRmNGY0IiBzdHJva2U9IiNjYzg4ODgiIHN0cm9rZS1kYXNoYXJyYXk9IjUsNCIgLz48dGV4dCB4PSI5MTciIHk9IjcwOCIgZm9udC1zaXplPSIxMSIgZm9udC13ZWlnaHQ9ImJvbGQiIGZpbGw9IiNhMDQ1NDUiPnRyYWNlICZhbXA7IHJlcGFpciBoZWxwZXJzIOKAlCBwbGFubmVkPC90ZXh0Pjx0ZXh0IHg9IjkxNyIgeT0iNzI1IiBmb250LXNpemU9IjkuNSIgZmlsbD0iIzk5OSI+bWFrZV90ZW1wZXJhdHVyZV9zY2VuYXJpb3MoKTwvdGV4dD48dGV4dCB4PSI5MTciIHk9IjczNyIgZm9udC1zaXplPSI5LjUiIGZpbGw9IiM5OTkiPnJlcGFpcl9yYXRlX3NjaG9vbGZpZWxkKCk8L3RleHQ+PC9nPjwhLS0gcGxvdF8qKCkgZmFtaWx5IC0tPjxnIHRleHQtYW5jaG9yPSJtaWRkbGUiPjxyZWN0IHg9IjExODAiIHk9IjMzMCIgd2lkdGg9IjI0MCIgaGVpZ2h0PSIxNDAiIHJ4PSI3IiBmaWxsPSIjZWFkMWRjIiBzdHJva2U9IiNjMjdiYTAiIC8+PHRleHQgeD0iMTMwMCIgeT0iMzc4IiBmb250LXNpemU9IjE3IiBmb250LXdlaWdodD0iYm9sZCIgZmlsbD0iIzRjMTEzMCI+cGxvdF8qKCkgZmFtaWx5PC90ZXh0Pjx0ZXh0IHg9IjEzMDAiIHk9IjQwNCIgZm9udC1zaXplPSIxMC41IiBmaWxsPSIjNjY2Ij5wbG90X2NvbmZpZGVuY2VfZXllKCkgKGRlZmF1bHQpPC90ZXh0Pjx0ZXh0IHg9IjEzMDAiIHk9IjQyNCIgZm9udC1zaXplPSIxMC41IiBmaWxsPSIjNjY2Ij5zdXJ2aXZhbCBjdXJ2ZXMgwrcgc3VyZmFjZSDCtzwvdGV4dD48dGV4dCB4PSIxMzAwIiB5PSI0MzgiIGZvbnQtc2l6ZT0iMTAuNSIgZmlsbD0iIzY2NiI+VERUIGN1cnZlIMK3IGhlYXQgaW5qdXJ5PC90ZXh0PjwvZz48IS0tIGZyZXFUTFMgZXh0cmFzIChubyBiYXllc1RMUyB0d2luKSAtLT48ZyB0ZXh0LWFuY2hvcj0ibWlkZGxlIj48cmVjdCB4PSIxMTgwIiB5PSIxNTAiIHdpZHRoPSIyNDAiIGhlaWdodD0iMTIwIiByeD0iNyIgZmlsbD0iI2ZmZjJjYyIgc3Ryb2tlPSIjZTBiOTRlIiBzdHJva2UtZGFzaGFycmF5PSI1LDQiIC8+PHRleHQgeD0iMTMwMCIgeT0iMTc2IiBmb250LXNpemU9IjEyLjUiIGZvbnQtd2VpZ2h0PSJib2xkIiBmaWxsPSIjN2Y2MDAwIj5mcmVxVExTIGV4dHJhczwvdGV4dD48dGV4dCB4PSIxMzAwIiB5PSIxOTAiIGZvbnQtc2l6ZT0iOS41IiBmaWxsPSIjOTk4MjAwIj4obm8gYmF5ZXNUTFMgdHdpbik8L3RleHQ+PHRleHQgeD0iMTMwMCIgeT0iMjEyIiBmb250LXNpemU9IjEwIiBmaWxsPSIjNjY2Ij5XYWxkIMK3IHByb2ZpbGUgwrcgYm9vdHN0cmFwIENJczwvdGV4dD48dGV4dCB4PSIxMzAwIiB5PSIyMjYiIGZvbnQtc2l6ZT0iMTAiIGZpbGw9IiM2NjYiPihwcm9maWxlLXQgY2FsaWJyYXRlZCk8L3RleHQ+PHRleHQgeD0iMTMwMCIgeT0iMjQ0IiBmb250LXNpemU9IjEwIiBmaWxsPSIjNjY2Ij50aGUgQ29uZmlkZW5jZSBFeWU7PC90ZXh0Pjx0ZXh0IHg9IjEzMDAiIHk9IjI1OCIgZm9udC1zaXplPSIxMCIgZmlsbD0iIzY2NiI+MTIgaWRlbnRpZmlhYmlsaXR5IHdhcm5pbmdzPC90ZXh0PjwvZz48IS0tIENvbXBhcmlzb24gcGF0aCAtLT48dGV4dCB4PSI0MCIgeT0iODAwIiBmb250LXNpemU9IjExIiBmaWxsPSIjNzc3Ij5Db21wYXJpc29uIHBhdGg8L3RleHQ+PHRleHQgeD0iNDAiIHk9IjgxNCIgZm9udC1zaXplPSIxMSIgZmlsbD0iIzc3NyI+bm90IHRoZSBjb3JlIE1MIHdvcmtmbG93PC90ZXh0PjxnIHRleHQtYW5jaG9yPSJtaWRkbGUiPjxyZWN0IHg9IjI1MCIgeT0iNzgyIiB3aWR0aD0iMTYwIiBoZWlnaHQ9IjU0IiByeD0iNyIgZmlsbD0iI2VmZWZlZiIgc3Ryb2tlPSIjYjdiN2I3IiBzdHJva2UtZGFzaGFycmF5PSI1LDQiIC8+PHRleHQgeD0iMzMwIiB5PSI4MDYiIGZvbnQtc2l6ZT0iMTIuNSIgZm9udC13ZWlnaHQ9ImJvbGQiIGZpbGw9IiM1NTUiPnRzX3N0YWdlMSgpPC90ZXh0Pjx0ZXh0IHg9IjMzMCIgeT0iODIzIiBmb250LXNpemU9IjkuNSIgZmlsbD0iIzc3NyI+Y2xhc3NpY2FsIExUNTAgYnkgdGVtcDwvdGV4dD48cmVjdCB4PSI0NzAiIHk9Ijc4MiIgd2lkdGg9IjE2MCIgaGVpZ2h0PSI1NCIgcng9IjciIGZpbGw9IiNlZmVmZWYiIHN0cm9rZT0iI2I3YjdiNyIgc3Ryb2tlLWRhc2hhcnJheT0iNSw0IiAvPjx0ZXh0IHg9IjU1MCIgeT0iODA2IiBmb250LXNpemU9IjEyLjUiIGZvbnQtd2VpZ2h0PSJib2xkIiBmaWxsPSIjNTU1Ij50c19zdGFnZTIoKTwvdGV4dD48dGV4dCB4PSI1NTAiIHk9IjgyMyIgZm9udC1zaXplPSI5LjUiIGZpbGw9IiM3NzciPk9MUyBURFQgbGluZTwvdGV4dD48cmVjdCB4PSI2OTAiIHk9Ijc4MiIgd2lkdGg9IjE3NSIgaGVpZ2h0PSI1NCIgcng9IjciIGZpbGw9IiNlZmVmZWYiIHN0cm9rZT0iI2I3YjdiNyIgc3Ryb2tlLWRhc2hhcnJheT0iNSw0IiAvPjx0ZXh0IHg9Ijc3NyIgeT0iODA2IiBmb250LXNpemU9IjEyLjUiIGZvbnQtd2VpZ2h0PSJib2xkIiBmaWxsPSIjNTU1Ij50c19jaSgpIC8gdHNfY3VydmUoKTwvdGV4dD48dGV4dCB4PSI3NzciIHk9IjgyMyIgZm9udC1zaXplPSI5LjUiIGZpbGw9IiM3NzciPnVuY2VydGFpbnR5ICsgbGluZTwvdGV4dD48L2c+PCEtLSBMZWdlbmQgLS0+PHRleHQgeD0iMTE4MCIgeT0iODU4IiBmb250LXNpemU9IjEwIiBmaWxsPSIjODg4Ij5Tb2xpZCA9IG1haW4gd29ya2Zsb3cgICAgRGFzaGVkID0gb3B0aW9uYWwgLyBwbGFubmVkPC90ZXh0Pjwvc3ZnPg==)

## Where to next

- [`vignette("model-math")`](https://itchyshin.github.io/freqTLS/articles/model-math.md)
  — the 4PL, the direct `CTmax`/`z` parameterisation, and the exact
  bridge to `bayesTLS`.
- [`vignette("profile-likelihood")`](https://itchyshin.github.io/freqTLS/articles/profile-likelihood.md)
  — what the profile is doing, why intervals can be asymmetric, profile
  versus Wald, and the honest non-closing fallback.
- [`vignette("random-effects")`](https://itchyshin.github.io/freqTLS/articles/random-effects.md)
  — hierarchical thermal-tolerance models: random intercepts on `CTmax`,
  `log_z`, `low`, and `log_k`, with their diagnostics.
- [`vignette("comparing-to-bayesTLS")`](https://itchyshin.github.io/freqTLS/articles/comparing-to-bayesTLS.md)
  — the three-way comparison (classical two-stage, Bayesian, profile
  likelihood) and the credit for the framework.

Before interpreting any fitted model, run `check_tls(fit)`. The recovery
guide in
[`?check_tls`](https://itchyshin.github.io/freqTLS/reference/check_tls.md)
maps each warning to the next design or analysis action; the profile
article shows both the default bootstrap recovery attempt and the strict
`fallback = FALSE` open-profile diagnostic.
