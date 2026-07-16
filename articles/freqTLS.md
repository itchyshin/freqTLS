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
shared-name facade
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
or the `by =` shorthand (e.g. `by = "population"` for a grouped fit).
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
likelihood. The map below shows the main workflow and how each box
corresponds to a `bayesTLS` function. The **“freqTLS extras”** box
(gold, upper right) is the frequentist-only addition — Wald / profile /
bootstrap intervals and the Confidence Eye — and the dashed **“trace &
repair helpers — planned”** box is the one piece not yet ported.

![](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdib3g9IjAgMCAxNTAwIDg4MCIgZm9udC1mYW1pbHk9IkhlbHZldGljYSwgQXJpYWwsIHNhbnMtc2VyaWYiIHdpZHRoPSIxMDAlIiByb2xlPSJpbWciIGFyaWEtbGFiZWxsZWRieT0iZnRscy1tYXAtdGl0bGUgZnRscy1tYXAtZGVzYyI+PHRpdGxlIGlkPSJmdGxzLW1hcC10aXRsZSI+ZnJlcVRMUyBmdW5jdGlvbiBtYXA8L3RpdGxlPgo8ZGVzYyBpZD0iZnRscy1tYXAtZGVzYyI+TWF4aW11bS1saWtlbGlob29kIGFuYWxvZ3VlIG9mIHRoZSBiYXllc1RMUyB3b3JrZmxvdy4gQ29sdW1uczogREFUQSAoc3RhbmRhcmRpemVfZGF0YSk7IEZJVCAoZml0XzRwbCwgd2l0aCBtYWtlXzRwbF9mb3JtdWxhLCB0aWR5X3BhcmFtZXRlcnMgYW5kIHRkdF9wYXJhbWV0ZXJfdGFibGUsIGFuZCBkaWFnbm9zZV90ZHRfZml0IGFuZCBjaGVja190bHMpOyBERVJJVkUgKHRscywgd2l0aCB0bHNfeiwgdGxzX2N0bWF4IGFuZCB0bHNfdGNyaXQsIHBsdXMgZXh0cmFjdF90ZHQgYW5kIHRoZSBkZXJpdmVfbHQsIGRlcml2ZV9jdG1heCBhbmQgZGVyaXZlX3Rjcml0IHByaW1pdGl2ZXMpOyBSRVBPUlQgYW5kIEFDQ0VTUyAoZ2V0X2N0bWF4LCBnZXRfeiBhbmQgZ2V0X3NoYXBlLCBhbmQgdGhlIGdldF8qX3N1bW1hcnkgYW5kIGdldF8qX2RyYXdzIGFjY2Vzc29ycyk7IFBSRURJQ1QgKHByZWRpY3Rfc3Vydml2YWxfY3VydmVzIGFuZCBwcmVkaWN0X2hlYXRfaW5qdXJ5LCB3aXRoIG1ha2VfdGVtcGVyYXR1cmVfc2NlbmFyaW9zIGFuZCByZXBhaXJfcmF0ZV9zY2hvb2xmaWVsZCBtYXJrZWQgbm90IHlldCBwb3J0ZWQpOyBhbmQgUExPVCAodGhlIHBsb3RfKiBmYW1pbHksIGluY2x1ZGluZyBwbG90X2NvbmZpZGVuY2VfZXllKS4gQSBzZXBhcmF0ZSB0d28tc3RhZ2UgY29tcGFyaXNvbiBwYXRoIHJ1bnMgdHNfc3RhZ2UxIHRvIHRzX3N0YWdlMiB0byB0c19jaSBhbmQgdHNfY3VydmUuIEEgaGlnaGxpZ2h0ZWQgYm94IGxpc3RzIHRoZSBmcmVxVExTLW9ubHkgZXh0cmFzOiBXYWxkLCBwcm9maWxlIGFuZCBib290c3RyYXAgY29uZmlkZW5jZSBpbnRlcnZhbHMgd2l0aCBwcm9maWxlLXQgY2FsaWJyYXRpb24sIHRoZSBDb25maWRlbmNlIEV5ZSwgYW5kIHR3ZWx2ZSBpZGVudGlmaWFiaWxpdHkgd2FybmluZ3MuPC9kZXNjPjxkZWZzPjxtYXJrZXIgaWQ9ImFyciIgbWFya2Vyd2lkdGg9IjkiIG1hcmtlcmhlaWdodD0iOSIgcmVmeD0iNyIgcmVmeT0iMyIgb3JpZW50PSJhdXRvIj48cGF0aCBkPSJNMCwwIEw3LDMgTDAsNiBaIiBmaWxsPSIjNTU1IiAvPjwvbWFya2VyPjwvZGVmcz48cmVjdCB4PSIwIiB5PSIwIiB3aWR0aD0iMTUwMCIgaGVpZ2h0PSI4ODAiIGZpbGw9IiNmZmZmZmYiIC8+PCEtLSBUaXRsZSAtLT48dGV4dCB4PSI0MCIgeT0iNDYiIGZvbnQtc2l6ZT0iMjYiIGZvbnQtd2VpZ2h0PSJib2xkIiBmaWxsPSIjMzMzIj5mcmVxVExTIGZ1bmN0aW9uIG1hcDwvdGV4dD48dGV4dCB4PSI0MiIgeT0iNzIiIGZvbnQtc2l6ZT0iMTMiIGZpbGw9IiM3NzciPk1heGltdW0tbGlrZWxpaG9vZCBhbmFsb2d1ZSBvZiB0aGUgYmF5ZXNUTFMgd29ya2Zsb3cuIENvcmUgdXNlciB3b3JrZmxvdzsgcmVwb3J0L2FjY2VzcyBhbmQgcHJlZGljdGlvbiBhcmUgcGFyYWxsZWwgZG93bnN0cmVhbSB1c2VzLjwvdGV4dD48IS0tIENvbHVtbiBoZWFkZXIgY2hpcHMgLS0+PGcgZm9udC1zaXplPSIxMiIgZm9udC13ZWlnaHQ9ImJvbGQiIHRleHQtYW5jaG9yPSJtaWRkbGUiPjxyZWN0IHg9IjE1MCIgeT0iOTgiIHdpZHRoPSIxMTAiIGhlaWdodD0iMjYiIHJ4PSI1IiBmaWxsPSIjYjZkN2E4IiAvPjx0ZXh0IHg9IjIwNSIgeT0iMTE1IiBmaWxsPSIjMjc0ZTEzIj5EQVRBPC90ZXh0PjxyZWN0IHg9IjMzMCIgeT0iOTgiIHdpZHRoPSIxMTAiIGhlaWdodD0iMjYiIHJ4PSI1IiBmaWxsPSIjOWZjNWU4IiAvPjx0ZXh0IHg9IjM4NSIgeT0iMTE1IiBmaWxsPSIjMWM0NTg3Ij5GSVQ8L3RleHQ+PHJlY3QgeD0iNTQ1IiB5PSI5OCIgd2lkdGg9IjE4MCIgaGVpZ2h0PSIyNiIgcng9IjUiIGZpbGw9IiNiNmQ3YTgiIC8+PHRleHQgeD0iNjM1IiB5PSIxMTUiIGZpbGw9IiMyNzRlMTMiPkRFUklWRTwvdGV4dD48cmVjdCB4PSI4MDAiIHk9Ijk4IiB3aWR0aD0iMjUwIiBoZWlnaHQ9IjI2IiByeD0iNSIgZmlsbD0iI2I0YTdkNiIgLz48dGV4dCB4PSI5MjUiIHk9IjExNSIgZmlsbD0iIzIwMTI0ZCI+UkVQT1JUIC8gQUNDRVNTPC90ZXh0PjxyZWN0IHg9IjExODAiIHk9Ijk4IiB3aWR0aD0iMjQwIiBoZWlnaHQ9IjI2IiByeD0iNSIgZmlsbD0iI2Q1YTZiZCIgLz48dGV4dCB4PSIxMzAwIiB5PSIxMTUiIGZpbGw9IiM0YzExMzAiPlBMT1Q8L3RleHQ+PHJlY3QgeD0iODAwIiB5PSI0NTgiIHdpZHRoPSIxMjAiIGhlaWdodD0iMjYiIHJ4PSI1IiBmaWxsPSIjZjljYjljIiAvPjx0ZXh0IHg9Ijg2MCIgeT0iNDc1IiBmaWxsPSIjNzgzZjA0Ij5QUkVESUNUPC90ZXh0PjwvZz48IS0tID09PT09PT09PT09PSBBUlJPV1MgKGRyYXduIGZpcnN0LCB1bmRlciBib3hlcykgPT09PT09PT09PT09IC0tPjxnIGZpbGw9Im5vbmUiIHN0cm9rZT0iIzg4OCIgc3Ryb2tlLXdpZHRoPSIxLjYiIHN0cm9rZS1kYXNoYXJyYXk9IjUsNCI+PHBhdGggZD0iTTEyOCAzMzUgTDE0OCAzMzUiIG1hcmtlci1lbmQ9InVybCgjYXJyKSIgLz48IS0tIHJhdyAtPiBzdGFuZGFyZGl6ZSAtLT48cGF0aCBkPSJNNDE1IDI0NiBMNDE1IDI4NiIgbWFya2VyLWVuZD0idXJsKCNhcnIpIiAvPjwhLS0gbW9kZWwgc3BlYyAtPiBmaXQgLS0+PHBhdGggZD0iTTYzNSAxNzIgTDYzNSAyMTAiIG1hcmtlci1lbmQ9InVybCgjYXJyKSIgLz48IS0tIG1hbnVhbCBmaXQgLT4gdGxzIC0tPjxwYXRoIGQ9Ik02MzUgNDA4IEw2MzUgNDYwIiBtYXJrZXItZW5kPSJ1cmwoI2FycikiIC8+PCEtLSBleHRyYWN0IC0+IGFkdmFuY2VkIC0tPjxwYXRoIGQ9Ik05MTcgNjg4IEw5MTcgNjY4IiBtYXJrZXItZW5kPSJ1cmwoI2FycikiIC8+PCEtLSBoZWxwZXJzIC0+IGhlYXQgaW5qdXJ5IC0tPjxwYXRoIGQ9Ik00MTAgODA5IEw0NjggODA5IiBtYXJrZXItZW5kPSJ1cmwoI2FycikiIC8+PCEtLSB0czEgLT4gdHMyIC0tPjxwYXRoIGQ9Ik02MzAgODA5IEw2ODggODA5IiBtYXJrZXItZW5kPSJ1cmwoI2FycikiIC8+PCEtLSB0czIgLT4gdHNfY2kgLS0+PC9nPjxnIGZpbGw9Im5vbmUiIHN0cm9rZT0iIzU1NSIgc3Ryb2tlLXdpZHRoPSIxLjgiPjxwYXRoIGQ9Ik0zMTAgMzM2IEwzMjggMzM2IiBtYXJrZXItZW5kPSJ1cmwoI2FycikiIC8+PCEtLSBzdGFuZGFyZGl6ZSAtPiBmaXQgLS0+PHBhdGggZD0iTTQxNSAzODQgTDQxNSA0MzgiIG1hcmtlci1lbmQ9InVybCgjYXJyKSIgLz48IS0tIGZpdCAtPiB0aWR5X3BhcmFtZXRlcnMgLS0+PHBhdGggZD0iTTUwMCAzMjIgTDU0MyAyNTIiIG1hcmtlci1lbmQ9InVybCgjYXJyKSIgLz48IS0tIGZpdCAtPiB0bHMgLS0+PHBhdGggZD0iTTUwMCAzNTIgTDU0MyAzNjAiIG1hcmtlci1lbmQ9InVybCgjYXJyKSIgLz48IS0tIGZpdCAtPiBleHRyYWN0IC0tPjxwYXRoIGQ9Ik03MjUgMjUwIEw3OTggMjUxIiBtYXJrZXItZW5kPSJ1cmwoI2FycikiIC8+PCEtLSB0bHMgLT4gZ2V0X2N0bWF4IC0tPjxwYXRoIGQ9Ik03MjUgMzYwIEw3OTggMzYwIiBtYXJrZXItZW5kPSJ1cmwoI2FycikiIC8+PCEtLSBleHRyYWN0IC0+IGFjY2Vzc29ycyAtLT48cGF0aCBkPSJNMTA1MCAyNTEgTDExNzggMzg0IiBtYXJrZXItZW5kPSJ1cmwoI2FycikiIC8+PCEtLSBnZXRfY3RtYXggLT4gcGxvdCAtLT48cGF0aCBkPSJNMTA1MCAzNjAgTDExNzggMzk2IiBtYXJrZXItZW5kPSJ1cmwoI2FycikiIC8+PCEtLSBhY2Nlc3NvcnMgLT4gcGxvdCAtLT48cGF0aCBkPSJNMTAzNSA1MjggTDExNzggNDI0IiBtYXJrZXItZW5kPSJ1cmwoI2FycikiIC8+PCEtLSBwcmVkIHN1cnYgLT4gcGxvdCAtLT48cGF0aCBkPSJNMTAzNSA2MjYgTDExNzggNDQ0IiBtYXJrZXItZW5kPSJ1cmwoI2FycikiIC8+PCEtLSBwcmVkIGhlYXQgLT4gcGxvdCAtLT48cGF0aCBkPSJNNTAwIDM2NiBMNTE1IDM2NiBMNTE1IDUyOCBMNzk4IDUyOCIgbWFya2VyLWVuZD0idXJsKCNhcnIpIiAvPjwhLS0gZml0IC0+IHByZWQgc3VydiAtLT48cGF0aCBkPSJNNTAwIDM3NiBMNTE1IDM3NiBMNTE1IDYyNiBMNzk4IDYyNiIgbWFya2VyLWVuZD0idXJsKCNhcnIpIiAvPjwhLS0gZml0IC0+IHByZWQgaGVhdCAtLT48L2c+PCEtLSA9PT09PT09PT09PT0gQk9YRVMgPT09PT09PT09PT09IC0tPjwhLS0gcmF3IGRhdGEgLS0+PGcgdGV4dC1hbmNob3I9Im1pZGRsZSI+PHJlY3QgeD0iMjQiIHk9IjMwMCIgd2lkdGg9IjEwNCIgaGVpZ2h0PSI3MCIgcng9IjciIGZpbGw9IiNmZmZmZmYiIHN0cm9rZT0iI2JiYmJiYiIgLz48dGV4dCB4PSI3NiIgeT0iMzMyIiBmb250LXNpemU9IjEzIiBmb250LXdlaWdodD0iYm9sZCIgZmlsbD0iIzQ0NCI+cmF3IGRhdGE8L3RleHQ+PHRleHQgeD0iNzYiIHk9IjM1MCIgZm9udC1zaXplPSI5LjUiIGZpbGw9IiM3NzciPmNvdW50cyBvcjwvdGV4dD48dGV4dCB4PSI3NiIgeT0iMzYyIiBmb250LXNpemU9IjkuNSIgZmlsbD0iIzc3NyI+cHJvcG9ydGlvbnM8L3RleHQ+PC9nPjwhLS0gc3RhbmRhcmRpemVfZGF0YSAtLT48ZyB0ZXh0LWFuY2hvcj0ibWlkZGxlIj48cmVjdCB4PSIxNTAiIHk9IjI4OCIgd2lkdGg9IjE2MCIgaGVpZ2h0PSI5NiIgcng9IjciIGZpbGw9IiNkOWVhZDMiIHN0cm9rZT0iIzkzYzQ3ZCIgLz48dGV4dCB4PSIyMzAiIHk9IjMzNCIgZm9udC1zaXplPSIxNSIgZm9udC13ZWlnaHQ9ImJvbGQiIGZpbGw9IiMyNzRlMTMiPnN0YW5kYXJkaXplX2RhdGEoKTwvdGV4dD48dGV4dCB4PSIyMzAiIHk9IjM1NiIgZm9udC1zaXplPSIxMC41IiBmaWxsPSIjNjY2Ij5zY2hlbWEgKyBtZXRhZGF0YTwvdGV4dD48L2c+PCEtLSBtb2RlbCBzcGVjIGhlbHBlcnMgLS0+PGcgdGV4dC1hbmNob3I9Im1pZGRsZSI+PHJlY3QgeD0iMzMwIiB5PSIxODIiIHdpZHRoPSIxNzAiIGhlaWdodD0iNjQiIHJ4PSI3IiBmaWxsPSIjZWZlZmVmIiBzdHJva2U9IiNiN2I3YjciIHN0cm9rZS1kYXNoYXJyYXk9IjUsNCIgLz48dGV4dCB4PSI0MTUiIHk9IjIwMyIgZm9udC1zaXplPSIxMS41IiBmb250LXdlaWdodD0iYm9sZCIgZmlsbD0iIzU1NSI+bW9kZWwgc3BlYyBoZWxwZXJzPC90ZXh0Pjx0ZXh0IHg9IjQxNSIgeT0iMjIxIiBmb250LXNpemU9IjkuNSIgZmlsbD0iIzc3NyI+bWFrZV80cGxfZm9ybXVsYSgpOyB0bHNfYmYoKTwvdGV4dD48dGV4dCB4PSI0MTUiIHk9IjIzNCIgZm9udC1zaXplPSI5LjUiIGZpbGw9IiM3NzciPmdyYW1tYXIg4oCUIG5vIHByaW9ycyAoTUwpPC90ZXh0PjwvZz48IS0tIGZpdF80cGwgLS0+PGcgdGV4dC1hbmNob3I9Im1pZGRsZSI+PHJlY3QgeD0iMzMwIiB5PSIyODgiIHdpZHRoPSIxNzAiIGhlaWdodD0iOTYiIHJ4PSI3IiBmaWxsPSIjY2ZlMmYzIiBzdHJva2U9IiM2ZmE4ZGMiIC8+PHRleHQgeD0iNDE1IiB5PSIzMzIiIGZvbnQtc2l6ZT0iMTYiIGZvbnQtd2VpZ2h0PSJib2xkIiBmaWxsPSIjMWM0NTg3Ij5maXRfNHBsKCk8L3RleHQ+PHRleHQgeD0iNDE1IiB5PSIzNTQiIGZvbnQtc2l6ZT0iMTAuNSIgZmlsbD0iIzY2NiI+am9pbnQgTUwgNFBMIHdvcmtmbG93PC90ZXh0PjwvZz48IS0tIHRpZHlfcGFyYW1ldGVycyAoPSBnZXRfNHBsX2VzdCkgLS0+PGcgdGV4dC1hbmNob3I9Im1pZGRsZSI+PHJlY3QgeD0iMzMwIiB5PSI0NDAiIHdpZHRoPSIxNzAiIGhlaWdodD0iNzQiIHJ4PSI3IiBmaWxsPSIjZDlkMmU5IiBzdHJva2U9IiM4ZTdjYzMiIC8+PHRleHQgeD0iNDE1IiB5PSI0NjgiIGZvbnQtc2l6ZT0iMTMuNSIgZm9udC13ZWlnaHQ9ImJvbGQiIGZpbGw9IiMyMDEyNGQiPnRpZHlfcGFyYW1ldGVycygpPC90ZXh0Pjx0ZXh0IHg9IjQxNSIgeT0iNDg2IiBmb250LXNpemU9IjkuNSIgZmlsbD0iIzY2NiI+KyB0ZHRfcGFyYW1ldGVyX3RhYmxlKCk8L3RleHQ+PHRleHQgeD0iNDE1IiB5PSI0OTkiIGZvbnQtc2l6ZT0iOS41IiBmaWxsPSIjNjY2Ij40UEwgcGFyYW1zLCBib290c3RyYXAgZHJhd3M8L3RleHQ+PC9nPjwhLS0gZGlhZ25vc3RpY3MgLS0+PGcgdGV4dC1hbmNob3I9Im1pZGRsZSI+PHJlY3QgeD0iMzMwIiB5PSI1MzYiIHdpZHRoPSIxNzAiIGhlaWdodD0iNjYiIHJ4PSI3IiBmaWxsPSIjZWZlZmVmIiBzdHJva2U9IiNiN2I3YjciIHN0cm9rZS1kYXNoYXJyYXk9IjUsNCIgLz48dGV4dCB4PSI0MTUiIHk9IjU1NyIgZm9udC1zaXplPSIxMS41IiBmb250LXdlaWdodD0iYm9sZCIgZmlsbD0iIzU1NSI+ZGlhZ25vc3RpY3M8L3RleHQ+PHRleHQgeD0iNDE1IiB5PSI1NzUiIGZvbnQtc2l6ZT0iOS41IiBmaWxsPSIjNzc3Ij5kaWFnbm9zZV90ZHRfZml0KCk7IGNoZWNrX3RscygpPC90ZXh0Pjx0ZXh0IHg9IjQxNSIgeT0iNTg4IiBmb250LXNpemU9IjkuNSIgZmlsbD0iIzc3NyI+Y29udmVyZ2VuY2UsIHBkSGVzcywgMTIgd2FybmluZ3M8L3RleHQ+PC9nPjwhLS0gbWFudWFsIFRNQiBmaXQgLS0+PGcgdGV4dC1hbmNob3I9Im1pZGRsZSI+PHJlY3QgeD0iNTQ1IiB5PSIxMjAiIHdpZHRoPSIxODAiIGhlaWdodD0iNTIiIHJ4PSI3IiBmaWxsPSIjZWZlZmVmIiBzdHJva2U9IiNiN2I3YjciIHN0cm9rZS1kYXNoYXJyYXk9IjUsNCIgLz48dGV4dCB4PSI2MzUiIHk9IjE0MCIgZm9udC1zaXplPSIxMS41IiBmb250LXdlaWdodD0iYm9sZCIgZmlsbD0iIzU1NSI+bWFudWFsIFRNQiBmaXQ8L3RleHQ+PHRleHQgeD0iNjM1IiB5PSIxNTciIGZvbnQtc2l6ZT0iOS41IiBmaWxsPSIjNzc3Ij5maXRfdGxzKCkg4oCUIG9wdGlvbmFsIGlucHV0IHRvIHRscygpPC90ZXh0PjwvZz48IS0tIHRscygpIC0tPjxnIHRleHQtYW5jaG9yPSJtaWRkbGUiPjxyZWN0IHg9IjU0NSIgeT0iMjEyIiB3aWR0aD0iMTgwIiBoZWlnaHQ9Ijg2IiByeD0iNyIgZmlsbD0iI2Q5ZWFkMyIgc3Ryb2tlPSIjOTNjNDdkIiAvPjx0ZXh0IHg9IjYzNSIgeT0iMjQ4IiBmb250LXNpemU9IjE2IiBmb250LXdlaWdodD0iYm9sZCIgZmlsbD0iIzI3NGUxMyI+dGxzKCk8L3RleHQ+PHRleHQgeD0iNjM1IiB5PSIyNjgiIGZvbnQtc2l6ZT0iOS41IiBmaWxsPSIjNjY2Ij5oZWFkbGluZSBleHRyYWN0b3I8L3RleHQ+PHRleHQgeD0iNjM1IiB5PSIyODEiIGZvbnQtc2l6ZT0iOS41IiBmaWxsPSIjNjY2Ij4rIHRsc196IC8gdGxzX2N0bWF4IC8gdGxzX3Rjcml0PC90ZXh0PjwvZz48IS0tIGV4dHJhY3RfdGR0KCkgLS0+PGcgdGV4dC1hbmNob3I9Im1pZGRsZSI+PHJlY3QgeD0iNTQ1IiB5PSIzMjIiIHdpZHRoPSIxODAiIGhlaWdodD0iODYiIHJ4PSI3IiBmaWxsPSIjZDllYWQzIiBzdHJva2U9IiM5M2M0N2QiIC8+PHRleHQgeD0iNjM1IiB5PSIzNTYiIGZvbnQtc2l6ZT0iMTUiIGZvbnQtd2VpZ2h0PSJib2xkIiBmaWxsPSIjMjc0ZTEzIj5leHRyYWN0X3RkdCgpPC90ZXh0Pjx0ZXh0IHg9IjYzNSIgeT0iMzc3IiBmb250LXNpemU9IjkuNSIgZmlsbD0iIzY2NiI+YnVuZGxlIHosIENUbWF4LDwvdGV4dD48dGV4dCB4PSI2MzUiIHk9IjM5MCIgZm9udC1zaXplPSI5LjUiIGZpbGw9IiM2NjYiPlRfY3JpdCwgTFQgY3VydmU8L3RleHQ+PC9nPjwhLS0gYWR2YW5jZWQgcHJpbWl0aXZlcyAtLT48ZyB0ZXh0LWFuY2hvcj0ibWlkZGxlIj48cmVjdCB4PSI1MzUiIHk9IjQ2MiIgd2lkdGg9IjIwMCIgaGVpZ2h0PSI3MiIgcng9IjciIGZpbGw9IiNlZmVmZWYiIHN0cm9rZT0iI2I3YjdiNyIgc3Ryb2tlLWRhc2hhcnJheT0iNSw0IiAvPjx0ZXh0IHg9IjYzNSIgeT0iNDg0IiBmb250LXNpemU9IjExLjUiIGZvbnQtd2VpZ2h0PSJib2xkIiBmaWxsPSIjNTU1Ij5hZHZhbmNlZCBwcmltaXRpdmVzPC90ZXh0Pjx0ZXh0IHg9IjYzNSIgeT0iNTAyIiBmb250LXNpemU9IjkuNSIgZmlsbD0iIzc3NyI+ZGVyaXZlX2x0KCk7IGRlcml2ZV9jdG1heCgpOzwvdGV4dD48dGV4dCB4PSI2MzUiIHk9IjUxNSIgZm9udC1zaXplPSI5LjUiIGZpbGw9IiM3NzciPmRlcml2ZV90Y3JpdCgpPC90ZXh0PjwvZz48IS0tIGdldF9jdG1heCAvIGdldF96IC8gZ2V0X3NoYXBlICg9IGdldF90bHNfZXN0KSAtLT48ZyB0ZXh0LWFuY2hvcj0ibWlkZGxlIj48cmVjdCB4PSI4MDAiIHk9IjIxMiIgd2lkdGg9IjI1MCIgaGVpZ2h0PSI4MiIgcng9IjciIGZpbGw9IiNkOWQyZTkiIHN0cm9rZT0iIzhlN2NjMyIgLz48dGV4dCB4PSI5MjUiIHk9IjI0NSIgZm9udC1zaXplPSIxNCIgZm9udC13ZWlnaHQ9ImJvbGQiIGZpbGw9IiMyMDEyNGQiPmdldF9jdG1heCgpIMK3IGdldF96KCk8L3RleHQ+PHRleHQgeD0iOTI1IiB5PSIyNjMiIGZvbnQtc2l6ZT0iMTQiIGZvbnQtd2VpZ2h0PSJib2xkIiBmaWxsPSIjMjAxMjRkIj5nZXRfc2hhcGUoKTwvdGV4dD48dGV4dCB4PSI5MjUiIHk9IjI4MiIgZm9udC1zaXplPSI5LjUiIGZpbGw9IiM2NjYiPmZpdCDihpIgcGFyYW1ldGVyIHN1bW1hcmllczwvdGV4dD48L2c+PCEtLSBhY2Nlc3NvcnMgLS0+PGcgdGV4dC1hbmNob3I9Im1pZGRsZSI+PHJlY3QgeD0iODAwIiB5PSIzMjIiIHdpZHRoPSIyNTAiIGhlaWdodD0iODIiIHJ4PSI3IiBmaWxsPSIjZDlkMmU5IiBzdHJva2U9IiM4ZTdjYzMiIC8+PHRleHQgeD0iOTI1IiB5PSIzNTIiIGZvbnQtc2l6ZT0iMTMuNSIgZm9udC13ZWlnaHQ9ImJvbGQiIGZpbGw9IiMyMDEyNGQiPmdldF8qX3N1bW1hcnkoKSDCtyBnZXRfKl9kcmF3cygpPC90ZXh0Pjx0ZXh0IHg9IjkyNSIgeT0iMzcyIiBmb250LXNpemU9IjkuNSIgZmlsbD0iIzY2NiI+cGVyLXF1YW50aXR5IHN1bW1hcmllczwvdGV4dD48dGV4dCB4PSI5MjUiIHk9IjM4NSIgZm9udC1zaXplPSI5LjUiIGZpbGw9IiM2NjYiPisgYm9vdHN0cmFwIGRyYXdzPC90ZXh0PjwvZz48IS0tIHByZWRpY3Rfc3Vydml2YWxfY3VydmVzIC0tPjxnIHRleHQtYW5jaG9yPSJtaWRkbGUiPjxyZWN0IHg9IjgwMCIgeT0iNDkyIiB3aWR0aD0iMjM1IiBoZWlnaHQ9Ijc0IiByeD0iNyIgZmlsbD0iI2ZjZTVjZCIgc3Ryb2tlPSIjZjZiMjZiIiAvPjx0ZXh0IHg9IjkxNyIgeT0iNTIyIiBmb250LXNpemU9IjE0LjUiIGZvbnQtd2VpZ2h0PSJib2xkIiBmaWxsPSIjNzgzZjA0Ij5wcmVkaWN0X3N1cnZpdmFsX2N1cnZlcygpPC90ZXh0Pjx0ZXh0IHg9IjkxNyIgeT0iNTQyIiBmb250LXNpemU9IjkuNSIgZmlsbD0iIzY2NiI+dGVtcCDDlyBkdXJhdGlvbiBncmlkPC90ZXh0Pjx0ZXh0IHg9IjkxNyIgeT0iNTU1IiBmb250LXNpemU9IjkuNSIgZmlsbD0iIzY2NiI+KCsgcHJlZGljdF9zdXJ2aXZhbF9zdXJmYWNlKTwvdGV4dD48L2c+PCEtLSBwcmVkaWN0X2hlYXRfaW5qdXJ5IC0tPjxnIHRleHQtYW5jaG9yPSJtaWRkbGUiPjxyZWN0IHg9IjgwMCIgeT0iNTg2IiB3aWR0aD0iMjM1IiBoZWlnaHQ9IjgwIiByeD0iNyIgZmlsbD0iI2ZjZTVjZCIgc3Ryb2tlPSIjZjZiMjZiIiAvPjx0ZXh0IHg9IjkxNyIgeT0iNjE4IiBmb250LXNpemU9IjE0LjUiIGZvbnQtd2VpZ2h0PSJib2xkIiBmaWxsPSIjNzgzZjA0Ij5wcmVkaWN0X2hlYXRfaW5qdXJ5KCk8L3RleHQ+PHRleHQgeD0iOTE3IiB5PSI2MzgiIGZvbnQtc2l6ZT0iOS41IiBmaWxsPSIjNjY2Ij5keW5hbWljIHRyYWNlczwvdGV4dD48dGV4dCB4PSI5MTciIHk9IjY1MSIgZm9udC1zaXplPSI5LjUiIGZpbGw9IiM2NjYiPigrIGhlYXRfaW5qdXJ5X2VudmVsb3BlKTwvdGV4dD48L2c+PCEtLSB0cmFjZSAmIHJlcGFpciBoZWxwZXJzIChwbGFubmVkKSAtLT48ZyB0ZXh0LWFuY2hvcj0ibWlkZGxlIj48cmVjdCB4PSI4MDAiIHk9IjY4OCIgd2lkdGg9IjIzNSIgaGVpZ2h0PSI1NiIgcng9IjciIGZpbGw9IiNmNGY0ZjQiIHN0cm9rZT0iI2NjODg4OCIgc3Ryb2tlLWRhc2hhcnJheT0iNSw0IiAvPjx0ZXh0IHg9IjkxNyIgeT0iNzA4IiBmb250LXNpemU9IjExIiBmb250LXdlaWdodD0iYm9sZCIgZmlsbD0iI2EwNDU0NSI+dHJhY2UgJmFtcDsgcmVwYWlyIGhlbHBlcnMg4oCUIHBsYW5uZWQ8L3RleHQ+PHRleHQgeD0iOTE3IiB5PSI3MjUiIGZvbnQtc2l6ZT0iOS41IiBmaWxsPSIjOTk5Ij5tYWtlX3RlbXBlcmF0dXJlX3NjZW5hcmlvcygpPC90ZXh0Pjx0ZXh0IHg9IjkxNyIgeT0iNzM3IiBmb250LXNpemU9IjkuNSIgZmlsbD0iIzk5OSI+cmVwYWlyX3JhdGVfc2Nob29sZmllbGQoKTwvdGV4dD48L2c+PCEtLSBwbG90XyooKSBmYW1pbHkgLS0+PGcgdGV4dC1hbmNob3I9Im1pZGRsZSI+PHJlY3QgeD0iMTE4MCIgeT0iMzMwIiB3aWR0aD0iMjQwIiBoZWlnaHQ9IjE0MCIgcng9IjciIGZpbGw9IiNlYWQxZGMiIHN0cm9rZT0iI2MyN2JhMCIgLz48dGV4dCB4PSIxMzAwIiB5PSIzNzgiIGZvbnQtc2l6ZT0iMTciIGZvbnQtd2VpZ2h0PSJib2xkIiBmaWxsPSIjNGMxMTMwIj5wbG90XyooKSBmYW1pbHk8L3RleHQ+PHRleHQgeD0iMTMwMCIgeT0iNDA0IiBmb250LXNpemU9IjEwLjUiIGZpbGw9IiM2NjYiPnBsb3RfY29uZmlkZW5jZV9leWUoKSAoZGVmYXVsdCk8L3RleHQ+PHRleHQgeD0iMTMwMCIgeT0iNDI0IiBmb250LXNpemU9IjEwLjUiIGZpbGw9IiM2NjYiPnN1cnZpdmFsIGN1cnZlcyDCtyBzdXJmYWNlIMK3PC90ZXh0Pjx0ZXh0IHg9IjEzMDAiIHk9IjQzOCIgZm9udC1zaXplPSIxMC41IiBmaWxsPSIjNjY2Ij5URFQgY3VydmUgwrcgaGVhdCBpbmp1cnk8L3RleHQ+PC9nPjwhLS0gZnJlcVRMUyBleHRyYXMgKG5vIGRpcmVjdCBiYXllc1RMUyBhbmFsb2d1ZSkgLS0+PGcgdGV4dC1hbmNob3I9Im1pZGRsZSI+PHJlY3QgeD0iMTE4MCIgeT0iMTUwIiB3aWR0aD0iMjQwIiBoZWlnaHQ9IjEyMCIgcng9IjciIGZpbGw9IiNmZmYyY2MiIHN0cm9rZT0iI2UwYjk0ZSIgc3Ryb2tlLWRhc2hhcnJheT0iNSw0IiAvPjx0ZXh0IHg9IjEzMDAiIHk9IjE3NiIgZm9udC1zaXplPSIxMi41IiBmb250LXdlaWdodD0iYm9sZCIgZmlsbD0iIzdmNjAwMCI+ZnJlcVRMUyBleHRyYXM8L3RleHQ+PHRleHQgeD0iMTMwMCIgeT0iMTkwIiBmb250LXNpemU9IjkuNSIgZmlsbD0iIzk5ODIwMCI+KG5vIGRpcmVjdCBiYXllc1RMUyBhbmFsb2d1ZSk8L3RleHQ+PHRleHQgeD0iMTMwMCIgeT0iMjEyIiBmb250LXNpemU9IjEwIiBmaWxsPSIjNjY2Ij5XYWxkIMK3IHByb2ZpbGUgwrcgYm9vdHN0cmFwIENJczwvdGV4dD48dGV4dCB4PSIxMzAwIiB5PSIyMjYiIGZvbnQtc2l6ZT0iMTAiIGZpbGw9IiM2NjYiPihwcm9maWxlLXQgY2FsaWJyYXRlZCk8L3RleHQ+PHRleHQgeD0iMTMwMCIgeT0iMjQ0IiBmb250LXNpemU9IjEwIiBmaWxsPSIjNjY2Ij50aGUgQ29uZmlkZW5jZSBFeWU7PC90ZXh0Pjx0ZXh0IHg9IjEzMDAiIHk9IjI1OCIgZm9udC1zaXplPSIxMCIgZmlsbD0iIzY2NiI+MTIgaWRlbnRpZmlhYmlsaXR5IHdhcm5pbmdzPC90ZXh0PjwvZz48IS0tIENvbXBhcmlzb24gcGF0aCAtLT48dGV4dCB4PSI0MCIgeT0iODAwIiBmb250LXNpemU9IjExIiBmaWxsPSIjNzc3Ij5Db21wYXJpc29uIHBhdGg8L3RleHQ+PHRleHQgeD0iNDAiIHk9IjgxNCIgZm9udC1zaXplPSIxMSIgZmlsbD0iIzc3NyI+bm90IHRoZSBjb3JlIE1MIHdvcmtmbG93PC90ZXh0PjxnIHRleHQtYW5jaG9yPSJtaWRkbGUiPjxyZWN0IHg9IjI1MCIgeT0iNzgyIiB3aWR0aD0iMTYwIiBoZWlnaHQ9IjU0IiByeD0iNyIgZmlsbD0iI2VmZWZlZiIgc3Ryb2tlPSIjYjdiN2I3IiBzdHJva2UtZGFzaGFycmF5PSI1LDQiIC8+PHRleHQgeD0iMzMwIiB5PSI4MDYiIGZvbnQtc2l6ZT0iMTIuNSIgZm9udC13ZWlnaHQ9ImJvbGQiIGZpbGw9IiM1NTUiPnRzX3N0YWdlMSgpPC90ZXh0Pjx0ZXh0IHg9IjMzMCIgeT0iODIzIiBmb250LXNpemU9IjkuNSIgZmlsbD0iIzc3NyI+Y2xhc3NpY2FsIExUNTAgYnkgdGVtcDwvdGV4dD48cmVjdCB4PSI0NzAiIHk9Ijc4MiIgd2lkdGg9IjE2MCIgaGVpZ2h0PSI1NCIgcng9IjciIGZpbGw9IiNlZmVmZWYiIHN0cm9rZT0iI2I3YjdiNyIgc3Ryb2tlLWRhc2hhcnJheT0iNSw0IiAvPjx0ZXh0IHg9IjU1MCIgeT0iODA2IiBmb250LXNpemU9IjEyLjUiIGZvbnQtd2VpZ2h0PSJib2xkIiBmaWxsPSIjNTU1Ij50c19zdGFnZTIoKTwvdGV4dD48dGV4dCB4PSI1NTAiIHk9IjgyMyIgZm9udC1zaXplPSI5LjUiIGZpbGw9IiM3NzciPk9MUyBURFQgbGluZTwvdGV4dD48cmVjdCB4PSI2OTAiIHk9Ijc4MiIgd2lkdGg9IjE3NSIgaGVpZ2h0PSI1NCIgcng9IjciIGZpbGw9IiNlZmVmZWYiIHN0cm9rZT0iI2I3YjdiNyIgc3Ryb2tlLWRhc2hhcnJheT0iNSw0IiAvPjx0ZXh0IHg9Ijc3NyIgeT0iODA2IiBmb250LXNpemU9IjEyLjUiIGZvbnQtd2VpZ2h0PSJib2xkIiBmaWxsPSIjNTU1Ij50c19jaSgpIC8gdHNfY3VydmUoKTwvdGV4dD48dGV4dCB4PSI3NzciIHk9IjgyMyIgZm9udC1zaXplPSI5LjUiIGZpbGw9IiM3NzciPnVuY2VydGFpbnR5ICsgbGluZTwvdGV4dD48L2c+PCEtLSBMZWdlbmQgLS0+PHRleHQgeD0iMTE4MCIgeT0iODU4IiBmb250LXNpemU9IjEwIiBmaWxsPSIjODg4Ij5Tb2xpZCA9IG1haW4gd29ya2Zsb3cgICAgRGFzaGVkID0gb3B0aW9uYWwgLyBwbGFubmVkPC90ZXh0Pjwvc3ZnPg==)

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
