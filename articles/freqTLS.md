# Getting started with freqTLS

`freqTLS` fits single-stage four-parameter logistic (4PL)
thermal-load-sensitivity (TLS) / thermal death-time models by maximum
likelihood, parameterised **directly in `CTmax`** (the critical thermal
maximum at the reference time `tref`) **and `z`** (thermal sensitivity,
degrees Celsius per order-of-magnitude change in exposure duration). It
returns prior-free **frequentist** confidence intervals — Wald,
profile-likelihood (asymmetry-respecting, the default), and bootstrap.
It is the likelihood complement to the Bayesian
[`bayesTLS`](https://github.com/daniel1noble/bayesTLS) package. The
thermal-load-sensitivity modelling framework was introduced by Daniel W.
A. Noble, Pieter A. Arnold, and Patrice Pottier; see
[`vignette("comparing-to-bayesTLS")`](https://itchyshin.github.io/freqTLS/articles/comparing-to-bayesTLS.md)
for the comparison boundary.

This vignette walks through the core loop: simulate → fit → confidence
intervals → plot. It runs end to end with a small simulation and needs
no Stan, no MCMC, and no internet.

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
object. `t_ref` is the reference time at which `CTmax` is defined, in
minutes.
[`standardize_data()`](https://itchyshin.github.io/freqTLS/reference/standardize_data.md)
converts recognised input duration units to minutes, so the omitted
default is one hour (`t_ref = 60`). A supplied numeric reference is
never converted: `t_ref = 1` deliberately means CTmax at one minute.
Bare formula/column data must already use minutes.

``` r

std <- standardize_data(
  dat,
  temp     = "temp",
  duration = "duration",
  n_total  = "total",
  n_surv   = "survived",
  duration_unit = "hours"
)
```

``` r

fit <- fit_4pl(std, family = "beta_binomial")
fit
#> <freq_tls>
#>   Data:    105 rows; 7 temperatures; 5 durations
#>   T_bar:   36.00
#>   Family:  beta_binomial (relative threshold, t_ref = 60 minutes)
#>   Fit:     converged (pdHess = TRUE); default CI method = profile
```

### Formula interface

For the supported moderators,
[`fit_4pl()`](https://itchyshin.github.io/freqTLS/reference/fit_4pl.md)
takes a **similar direct interface** to `bayesTLS` — `ctmax =`, `z =`,
or the `by =` shorthand (for example, `by = "population"`). The engine
also exposes the explicit 4PL formula grammar through
[`tls_bf()`](https://itchyshin.github.io/freqTLS/reference/tls_bf.md):
the response is survival counts,
[`time()`](https://rdrr.io/r/stats/time.html) identifies duration, and
`temp()` identifies assay temperature. The following formula still fits
the single-stage 4PL, not an ordinary linear model; it matches the
preceding fit:

``` r

fit_f <- fit_tls(
  tls_bf(survived | trials(total) ~ time(duration) + temp(temp)),
  data   = dat,
  family = "beta_binomial",
  tref   = 60
)
all.equal(coef(fit_f), coef(fit))
#> [1] "Mean relative difference: 0.105005"
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
#> Reference time (tref): 60 | family: beta_binomial
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

A tidy, broom-style table first shows all natural-scale 4PL parameters.
Dedicated extractors are useful when a later analysis needs only the
headline quantities:

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
headline quantities are model parameters, so they can be profiled
directly. [`confint()`](https://rdrr.io/r/stats/confint.html) with
`method = "profile"` (the default) inverts the likelihood-ratio test:
the interval is the set of values whose deviance from the maximum stays
below the profile-t cutoff (a squared Student-t quantile on the residual
degrees of freedom, not \chi^2_1; see
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
estimate. Do not use overlap as a hypothesis test; inspect the reported
contrast or confidence interval for that question. A hollow point with
*no* lens flags a profile that did not close (a weakly identified
parameter).

``` r

plot_confidence_eye(fit, parm = c("CTmax", "z"), method = "profile")
```

![Confidence Eye plot: independently scaled pale outlined lenses
spanning profile-likelihood intervals, with dark centre marks and hollow
point estimates, for CTmax and
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
  data = dat_grp, family = "beta_binomial", tref = 60
)
tidy_parameters(fit_grp)
#> # A tibble: 8 × 8
#>   parameter  group estimate std.error conf.low conf.high interval_type scale   
#>   <chr>      <chr>    <dbl>     <dbl>    <dbl>     <dbl> <chr>         <chr>   
#> 1 low        NA      0.0199   0.00459   0.0127    0.0313 wald          logit   
#> 2 up         NA      0.979    0.00794   0.964     0.995  wald          identity
#> 3 k          NA      4.79     0.404     4.06      5.66   wald          log     
#> 4 CTmax:cool cool   28.9      0.288    28.3      29.5    wald          identity
#> 5 CTmax:warm warm   29.0      0.390    28.2      29.8    wald          identity
#> 6 z:cool     cool    2.82     0.180     2.49      3.20   wald          log     
#> 7 z:warm     warm    4.98     0.254     4.50      5.51   wald          log     
#> 8 phi        NA     27.5      8.26     15.3      49.8    wald          log
confint(fit_grp, c("CTmax:cool", "CTmax:warm", "z:cool", "z:warm"),
        method = "profile")
#> # A tibble: 4 × 8
#>   parameter  conf.low conf.high estimate level method  scale    conf.status
#>   <chr>         <dbl>     <dbl>    <dbl> <dbl> <chr>   <chr>    <chr>      
#> 1 CTmax:cool    28.3      29.5     28.9   0.95 profile identity ok         
#> 2 CTmax:warm    28.2      29.8     29.0   0.95 profile identity ok         
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
  data = dat_re, family = "beta_binomial", tref = 60
)
fit_re
#> <freqTLS beta_binomial 4PL fit>
#> Call: fit_tls(x = tls_bf(survived | trials(total) ~ time(duration) +
#> temp(temp), CTmax ~ (1 | colony)), family = "beta_binomial", tref = 60, data =
#> dat_re)
#> Reference time (tref): 60 | CTmax defined at this time
#> Data: 700 observations, ungrouped; 7 temperatures in [30, 42], 5 durations in
#> [0.5, 8]
#> 5798 survivors of 14000 trials
#> Random intercept on CTmax: (1 | colony), 10 groups
#> 
#>    parameter group estimate std.error
#>          low        0.02283  0.002510
#>           up        0.98090  0.003458
#>            k        5.29100  0.215600
#>        CTmax   all 28.76000  0.337500
#>            z   all  4.03100  0.083040
#>          phi       49.98000 11.580000
#>  sigma_CTmax        0.98690  0.223500
#> Optimiser: nloptr_TNEWTON | code 0 | pdHess TRUE | converged (pdHess)
#> Message: Refined stationary point accepted by the freqTLS objective/gradient
#> contract (NLopt status 4); max|gradient| = 9.862e-06
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

`freqTLS` deliberately follows the **standardise → fit → quantities →
plot** workflow used in `bayesTLS`, while keeping its own
maximum-likelihood API. The map below shows the main freqTLS workflow
and selected analogous roles, not a one-to-one map of current `bayesTLS`
functions.
[`extract_tdt()`](https://itchyshin.github.io/freqTLS/reference/extract_tdt.md)
remains an optional compatibility-oriented bootstrap bundle;
[`tls()`](https://itchyshin.github.io/freqTLS/reference/tls.md) is the
primary quantity extractor in this package. The **“freqTLS extras”** box
(gold, upper right) is the frequentist-only addition — Wald / profile /
bootstrap intervals and the Confidence Eye — and the dashed **“trace &
repair helpers — planned”** box is the one piece not yet ported.

![](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdib3g9IjAgMCAxNTAwIDg4MCIgZm9udC1mYW1pbHk9IkhlbHZldGljYSwgQXJpYWwsIHNhbnMtc2VyaWYiIHdpZHRoPSIxMDAlIiByb2xlPSJpbWciIGFyaWEtbGFiZWxsZWRieT0iZnRscy1tYXAtdGl0bGUgZnRscy1tYXAtZGVzYyI+PHRpdGxlIGlkPSJmdGxzLW1hcC10aXRsZSI+ZnJlcVRMUyBmdW5jdGlvbiBtYXA8L3RpdGxlPgo8ZGVzYyBpZD0iZnRscy1tYXAtZGVzYyI+TWF4aW11bS1saWtlbGlob29kIHdvcmtmbG93IGluZm9ybWVkIGJ5IGJheWVzVExTLCBub3QgYSBvbmUtdG8tb25lIEFQSSBtYXAuIENvbHVtbnM6IERBVEEgKHN0YW5kYXJkaXplX2RhdGEpOyBGSVQgKGZpdF80cGwsIHdpdGggbWFrZV80cGxfZm9ybXVsYSwgdGlkeV9wYXJhbWV0ZXJzIGFuZCB0ZHRfcGFyYW1ldGVyX3RhYmxlLCBhbmQgZGlhZ25vc2VfdGR0X2ZpdCBhbmQgY2hlY2tfdGxzKTsgREVSSVZFICh0bHMgYXMgdGhlIHByaW1hcnkgcXVhbnRpdHkgZXh0cmFjdG9yLCB3aXRoIHRsc196LCB0bHNfY3RtYXggYW5kIHRsc190Y3JpdDsgZXh0cmFjdF90ZHQgaXMgYW4gb3B0aW9uYWwgY29tcGF0aWJpbGl0eS1vcmllbnRlZCBib290c3RyYXAgYnVuZGxlKTsgUkVQT1JUIGFuZCBBQ0NFU1MgKGdldF9jdG1heCwgZ2V0X3ogYW5kIGdldF9zaGFwZSwgYW5kIHRoZSBnZXRfKl9zdW1tYXJ5IGFuZCBnZXRfKl9kcmF3cyBhY2Nlc3NvcnMpOyBQUkVESUNUIChwcmVkaWN0X3N1cnZpdmFsX2N1cnZlcyBhbmQgcHJlZGljdF9oZWF0X2luanVyeTsgdGVtcGVyYXR1cmUgdHJhY2VzIGFuZCBhbnkgcmVwYWlyIHNjZW5hcmlvIGFyZSB1c2VyIHN1cHBsaWVkLCBub3QgaGVscGVyIEFQSXMgb3IgZml0dGVkIHN1Yi1tb2RlbHMpOyBhbmQgUExPVCAodGhlIHBsb3RfKiBmYW1pbHksIGluY2x1ZGluZyBwbG90X2NvbmZpZGVuY2VfZXllKS4gQSBzZXBhcmF0ZSB0d28tc3RhZ2UgY29tcGFyaXNvbiBwYXRoIHJ1bnMgdHNfc3RhZ2UxIHRvIHRzX3N0YWdlMiB0byB0c19jaSBhbmQgdHNfY3VydmUuIEEgaGlnaGxpZ2h0ZWQgYm94IGxpc3RzIGZyZXFUTFMgaW50ZXJ2YWwgYW5kIGRpYWdub3N0aWMgZmVhdHVyZXMuPC9kZXNjPjxkZWZzPjxtYXJrZXIgaWQ9ImFyciIgbWFya2Vyd2lkdGg9IjkiIG1hcmtlcmhlaWdodD0iOSIgcmVmeD0iNyIgcmVmeT0iMyIgb3JpZW50PSJhdXRvIj48cGF0aCBkPSJNMCwwIEw3LDMgTDAsNiBaIiBmaWxsPSIjNTU1IiAvPjwvbWFya2VyPjwvZGVmcz48cmVjdCB4PSIwIiB5PSIwIiB3aWR0aD0iMTUwMCIgaGVpZ2h0PSI4ODAiIGZpbGw9IiNmZmZmZmYiIC8+PCEtLSBUaXRsZSAtLT48dGV4dCB4PSI0MCIgeT0iNDYiIGZvbnQtc2l6ZT0iMjYiIGZvbnQtd2VpZ2h0PSJib2xkIiBmaWxsPSIjMzMzIj5mcmVxVExTIGZ1bmN0aW9uIG1hcDwvdGV4dD48dGV4dCB4PSI0MiIgeT0iNzIiIGZvbnQtc2l6ZT0iMTMiIGZpbGw9IiM3NzciPk1heGltdW0tbGlrZWxpaG9vZCB3b3JrZmxvdyBpbmZvcm1lZCBieSBiYXllc1RMUzsgbm90IGEgb25lLXRvLW9uZSBBUEkgbWFwLiBSZXBvcnQvYWNjZXNzIGFuZCBwcmVkaWN0aW9uIGFyZSBwYXJhbGxlbCBkb3duc3RyZWFtIHVzZXMuPC90ZXh0PjwhLS0gQ29sdW1uIGhlYWRlciBjaGlwcyAtLT48ZyBmb250LXNpemU9IjEyIiBmb250LXdlaWdodD0iYm9sZCIgdGV4dC1hbmNob3I9Im1pZGRsZSI+PHJlY3QgeD0iMTUwIiB5PSI5OCIgd2lkdGg9IjExMCIgaGVpZ2h0PSIyNiIgcng9IjUiIGZpbGw9IiNiNmQ3YTgiIC8+PHRleHQgeD0iMjA1IiB5PSIxMTUiIGZpbGw9IiMyNzRlMTMiPkRBVEE8L3RleHQ+PHJlY3QgeD0iMzMwIiB5PSI5OCIgd2lkdGg9IjExMCIgaGVpZ2h0PSIyNiIgcng9IjUiIGZpbGw9IiM5ZmM1ZTgiIC8+PHRleHQgeD0iMzg1IiB5PSIxMTUiIGZpbGw9IiMxYzQ1ODciPkZJVDwvdGV4dD48cmVjdCB4PSI1NDUiIHk9Ijk4IiB3aWR0aD0iMTgwIiBoZWlnaHQ9IjI2IiByeD0iNSIgZmlsbD0iI2I2ZDdhOCIgLz48dGV4dCB4PSI2MzUiIHk9IjExNSIgZmlsbD0iIzI3NGUxMyI+REVSSVZFPC90ZXh0PjxyZWN0IHg9IjgwMCIgeT0iOTgiIHdpZHRoPSIyNTAiIGhlaWdodD0iMjYiIHJ4PSI1IiBmaWxsPSIjYjRhN2Q2IiAvPjx0ZXh0IHg9IjkyNSIgeT0iMTE1IiBmaWxsPSIjMjAxMjRkIj5SRVBPUlQgLyBBQ0NFU1M8L3RleHQ+PHJlY3QgeD0iMTE4MCIgeT0iOTgiIHdpZHRoPSIyNDAiIGhlaWdodD0iMjYiIHJ4PSI1IiBmaWxsPSIjZDVhNmJkIiAvPjx0ZXh0IHg9IjEzMDAiIHk9IjExNSIgZmlsbD0iIzRjMTEzMCI+UExPVDwvdGV4dD48cmVjdCB4PSI4MDAiIHk9IjQ1OCIgd2lkdGg9IjEyMCIgaGVpZ2h0PSIyNiIgcng9IjUiIGZpbGw9IiNmOWNiOWMiIC8+PHRleHQgeD0iODYwIiB5PSI0NzUiIGZpbGw9IiM3ODNmMDQiPlBSRURJQ1Q8L3RleHQ+PC9nPjwhLS0gPT09PT09PT09PT09IEFSUk9XUyAoZHJhd24gZmlyc3QsIHVuZGVyIGJveGVzKSA9PT09PT09PT09PT0gLS0+PGcgZmlsbD0ibm9uZSIgc3Ryb2tlPSIjODg4IiBzdHJva2Utd2lkdGg9IjEuNiIgc3Ryb2tlLWRhc2hhcnJheT0iNSw0Ij48cGF0aCBkPSJNMTI4IDMzNSBMMTQ4IDMzNSIgbWFya2VyLWVuZD0idXJsKCNhcnIpIiAvPjwhLS0gcmF3IC0+IHN0YW5kYXJkaXplIC0tPjxwYXRoIGQ9Ik00MTUgMjQ2IEw0MTUgMjg2IiBtYXJrZXItZW5kPSJ1cmwoI2FycikiIC8+PCEtLSBtb2RlbCBzcGVjIC0+IGZpdCAtLT48cGF0aCBkPSJNNjM1IDE3MiBMNjM1IDIxMCIgbWFya2VyLWVuZD0idXJsKCNhcnIpIiAvPjwhLS0gbWFudWFsIGZpdCAtPiB0bHMgLS0+PHBhdGggZD0iTTYzNSA0MDggTDYzNSA0NzIiIG1hcmtlci1lbmQ9InVybCgjYXJyKSIgLz48IS0tIGV4dHJhY3QgLT4gYWR2YW5jZWQgLS0+PHBhdGggZD0iTTkxNyA2ODggTDkxNyA2NjgiIG1hcmtlci1lbmQ9InVybCgjYXJyKSIgLz48IS0tIGhlbHBlcnMgLT4gaGVhdCBpbmp1cnkgLS0+PHBhdGggZD0iTTQxMCA4MDkgTDQ2OCA4MDkiIG1hcmtlci1lbmQ9InVybCgjYXJyKSIgLz48IS0tIHRzMSAtPiB0czIgLS0+PHBhdGggZD0iTTYzMCA4MDkgTDY4OCA4MDkiIG1hcmtlci1lbmQ9InVybCgjYXJyKSIgLz48IS0tIHRzMiAtPiB0c19jaSAtLT48L2c+PGcgZmlsbD0ibm9uZSIgc3Ryb2tlPSIjNTU1IiBzdHJva2Utd2lkdGg9IjEuOCI+PHBhdGggZD0iTTMxMCAzMzYgTDMyOCAzMzYiIG1hcmtlci1lbmQ9InVybCgjYXJyKSIgLz48IS0tIHN0YW5kYXJkaXplIC0+IGZpdCAtLT48cGF0aCBkPSJNNDE1IDM4NCBMNDE1IDQzOCIgbWFya2VyLWVuZD0idXJsKCNhcnIpIiAvPjwhLS0gZml0IC0+IHRpZHlfcGFyYW1ldGVycyAtLT48cGF0aCBkPSJNNTAwIDMyMiBMNTQzIDI1MiIgbWFya2VyLWVuZD0idXJsKCNhcnIpIiAvPjwhLS0gZml0IC0+IHRscyAtLT48cGF0aCBkPSJNNTAwIDM1MiBMNTQzIDM2MCIgbWFya2VyLWVuZD0idXJsKCNhcnIpIiAvPjwhLS0gZml0IC0+IGV4dHJhY3QgLS0+PHBhdGggZD0iTTcyNSAyNTAgTDc5OCAyNTEiIG1hcmtlci1lbmQ9InVybCgjYXJyKSIgLz48IS0tIHRscyAtPiBnZXRfY3RtYXggLS0+PHBhdGggZD0iTTcyNSAzNjAgTDc5OCAzNjAiIG1hcmtlci1lbmQ9InVybCgjYXJyKSIgLz48IS0tIGV4dHJhY3QgLT4gYWNjZXNzb3JzIC0tPjxwYXRoIGQ9Ik0xMDUwIDI1MSBMMTE3OCAzODQiIG1hcmtlci1lbmQ9InVybCgjYXJyKSIgLz48IS0tIGdldF9jdG1heCAtPiBwbG90IC0tPjxwYXRoIGQ9Ik0xMDUwIDM2MCBMMTE3OCAzOTYiIG1hcmtlci1lbmQ9InVybCgjYXJyKSIgLz48IS0tIGFjY2Vzc29ycyAtPiBwbG90IC0tPjxwYXRoIGQ9Ik0xMDM1IDUyOCBMMTE3OCA0MjQiIG1hcmtlci1lbmQ9InVybCgjYXJyKSIgLz48IS0tIHByZWQgc3VydiAtPiBwbG90IC0tPjxwYXRoIGQ9Ik0xMDM1IDYyNiBMMTE3OCA0NDQiIG1hcmtlci1lbmQ9InVybCgjYXJyKSIgLz48IS0tIHByZWQgaGVhdCAtPiBwbG90IC0tPjxwYXRoIGQ9Ik01MDAgMzY2IEw1MTUgMzY2IEw1MTUgNTI4IEw3OTggNTI4IiBtYXJrZXItZW5kPSJ1cmwoI2FycikiIC8+PCEtLSBmaXQgLT4gcHJlZCBzdXJ2IC0tPjxwYXRoIGQ9Ik01MDAgMzc2IEw1MTUgMzc2IEw1MTUgNjI2IEw3OTggNjI2IiBtYXJrZXItZW5kPSJ1cmwoI2FycikiIC8+PCEtLSBmaXQgLT4gcHJlZCBoZWF0IC0tPjwvZz48IS0tID09PT09PT09PT09PSBCT1hFUyA9PT09PT09PT09PT0gLS0+PCEtLSByYXcgZGF0YSAtLT48ZyB0ZXh0LWFuY2hvcj0ibWlkZGxlIj48cmVjdCB4PSIyNCIgeT0iMzAwIiB3aWR0aD0iMTA0IiBoZWlnaHQ9IjcwIiByeD0iNyIgZmlsbD0iI2ZmZmZmZiIgc3Ryb2tlPSIjYmJiYmJiIiAvPjx0ZXh0IHg9Ijc2IiB5PSIzMzIiIGZvbnQtc2l6ZT0iMTMiIGZvbnQtd2VpZ2h0PSJib2xkIiBmaWxsPSIjNDQ0Ij5yYXcgZGF0YTwvdGV4dD48dGV4dCB4PSI3NiIgeT0iMzUwIiBmb250LXNpemU9IjkuNSIgZmlsbD0iIzc3NyI+Y291bnRzIG9yPC90ZXh0Pjx0ZXh0IHg9Ijc2IiB5PSIzNjIiIGZvbnQtc2l6ZT0iOS41IiBmaWxsPSIjNzc3Ij5wcm9wb3J0aW9uczwvdGV4dD48L2c+PCEtLSBzdGFuZGFyZGl6ZV9kYXRhIC0tPjxnIHRleHQtYW5jaG9yPSJtaWRkbGUiPjxyZWN0IHg9IjE1MCIgeT0iMjg4IiB3aWR0aD0iMTYwIiBoZWlnaHQ9Ijk2IiByeD0iNyIgZmlsbD0iI2Q5ZWFkMyIgc3Ryb2tlPSIjOTNjNDdkIiAvPjx0ZXh0IHg9IjIzMCIgeT0iMzM0IiBmb250LXNpemU9IjE1IiBmb250LXdlaWdodD0iYm9sZCIgZmlsbD0iIzI3NGUxMyI+c3RhbmRhcmRpemVfZGF0YSgpPC90ZXh0Pjx0ZXh0IHg9IjIzMCIgeT0iMzU2IiBmb250LXNpemU9IjEwLjUiIGZpbGw9IiM2NjYiPnNjaGVtYSArIG1ldGFkYXRhPC90ZXh0PjwvZz48IS0tIG1vZGVsIHNwZWMgaGVscGVycyAtLT48ZyB0ZXh0LWFuY2hvcj0ibWlkZGxlIj48cmVjdCB4PSIzMzAiIHk9IjE4MiIgd2lkdGg9IjE3MCIgaGVpZ2h0PSI2NCIgcng9IjciIGZpbGw9IiNlZmVmZWYiIHN0cm9rZT0iI2I3YjdiNyIgc3Ryb2tlLWRhc2hhcnJheT0iNSw0IiAvPjx0ZXh0IHg9IjQxNSIgeT0iMjAzIiBmb250LXNpemU9IjExLjUiIGZvbnQtd2VpZ2h0PSJib2xkIiBmaWxsPSIjNTU1Ij5tb2RlbCBzcGVjIGhlbHBlcnM8L3RleHQ+PHRleHQgeD0iNDE1IiB5PSIyMjEiIGZvbnQtc2l6ZT0iOS41IiBmaWxsPSIjNzc3Ij5tYWtlXzRwbF9mb3JtdWxhKCk7IHRsc19iZigpPC90ZXh0Pjx0ZXh0IHg9IjQxNSIgeT0iMjM0IiBmb250LXNpemU9IjkuNSIgZmlsbD0iIzc3NyI+Z3JhbW1hciDigJQgbm8gcHJpb3JzIChNTCk8L3RleHQ+PC9nPjwhLS0gZml0XzRwbCAtLT48ZyB0ZXh0LWFuY2hvcj0ibWlkZGxlIj48cmVjdCB4PSIzMzAiIHk9IjI4OCIgd2lkdGg9IjE3MCIgaGVpZ2h0PSI5NiIgcng9IjciIGZpbGw9IiNjZmUyZjMiIHN0cm9rZT0iIzZmYThkYyIgLz48dGV4dCB4PSI0MTUiIHk9IjMzMiIgZm9udC1zaXplPSIxNiIgZm9udC13ZWlnaHQ9ImJvbGQiIGZpbGw9IiMxYzQ1ODciPmZpdF80cGwoKTwvdGV4dD48dGV4dCB4PSI0MTUiIHk9IjM1NCIgZm9udC1zaXplPSIxMC41IiBmaWxsPSIjNjY2Ij5qb2ludCBNTCA0UEwgd29ya2Zsb3c8L3RleHQ+PC9nPjwhLS0gdGlkeV9wYXJhbWV0ZXJzICg9IGdldF80cGxfZXN0KSAtLT48ZyB0ZXh0LWFuY2hvcj0ibWlkZGxlIj48cmVjdCB4PSIzMzAiIHk9IjQ0MCIgd2lkdGg9IjE3MCIgaGVpZ2h0PSI3NCIgcng9IjciIGZpbGw9IiNkOWQyZTkiIHN0cm9rZT0iIzhlN2NjMyIgLz48dGV4dCB4PSI0MTUiIHk9IjQ2OCIgZm9udC1zaXplPSIxMy41IiBmb250LXdlaWdodD0iYm9sZCIgZmlsbD0iIzIwMTI0ZCI+dGlkeV9wYXJhbWV0ZXJzKCk8L3RleHQ+PHRleHQgeD0iNDE1IiB5PSI0ODYiIGZvbnQtc2l6ZT0iOS41IiBmaWxsPSIjNjY2Ij4rIHRkdF9wYXJhbWV0ZXJfdGFibGUoKTwvdGV4dD48dGV4dCB4PSI0MTUiIHk9IjQ5OSIgZm9udC1zaXplPSI5LjUiIGZpbGw9IiM2NjYiPjRQTCBwYXJhbXMsIGJvb3RzdHJhcCBkcmF3czwvdGV4dD48L2c+PCEtLSBkaWFnbm9zdGljcyAtLT48ZyB0ZXh0LWFuY2hvcj0ibWlkZGxlIj48cmVjdCB4PSIzMzAiIHk9IjUzNiIgd2lkdGg9IjE3MCIgaGVpZ2h0PSI2NiIgcng9IjciIGZpbGw9IiNlZmVmZWYiIHN0cm9rZT0iI2I3YjdiNyIgc3Ryb2tlLWRhc2hhcnJheT0iNSw0IiAvPjx0ZXh0IHg9IjQxNSIgeT0iNTU3IiBmb250LXNpemU9IjExLjUiIGZvbnQtd2VpZ2h0PSJib2xkIiBmaWxsPSIjNTU1Ij5kaWFnbm9zdGljczwvdGV4dD48dGV4dCB4PSI0MTUiIHk9IjU3NSIgZm9udC1zaXplPSI5LjUiIGZpbGw9IiM3NzciPmRpYWdub3NlX3RkdF9maXQoKTsgY2hlY2tfdGxzKCk8L3RleHQ+PHRleHQgeD0iNDE1IiB5PSI1ODgiIGZvbnQtc2l6ZT0iOS41IiBmaWxsPSIjNzc3Ij5jb252ZXJnZW5jZSwgcGRIZXNzLCAxMiB3YXJuaW5nczwvdGV4dD48L2c+PCEtLSBtYW51YWwgVE1CIGZpdCAtLT48ZyB0ZXh0LWFuY2hvcj0ibWlkZGxlIj48cmVjdCB4PSI1NDUiIHk9IjEyMCIgd2lkdGg9IjE4MCIgaGVpZ2h0PSI1MiIgcng9IjciIGZpbGw9IiNlZmVmZWYiIHN0cm9rZT0iI2I3YjdiNyIgc3Ryb2tlLWRhc2hhcnJheT0iNSw0IiAvPjx0ZXh0IHg9IjYzNSIgeT0iMTQwIiBmb250LXNpemU9IjExLjUiIGZvbnQtd2VpZ2h0PSJib2xkIiBmaWxsPSIjNTU1Ij5tYW51YWwgVE1CIGZpdDwvdGV4dD48dGV4dCB4PSI2MzUiIHk9IjE1NyIgZm9udC1zaXplPSI5LjUiIGZpbGw9IiM3NzciPmZpdF90bHMoKSDigJQgb3B0aW9uYWwgaW5wdXQgdG8gdGxzKCk8L3RleHQ+PC9nPjwhLS0gdGxzKCkgLS0+PGcgdGV4dC1hbmNob3I9Im1pZGRsZSI+PHJlY3QgeD0iNTQ1IiB5PSIyMTIiIHdpZHRoPSIxODAiIGhlaWdodD0iODYiIHJ4PSI3IiBmaWxsPSIjZDllYWQzIiBzdHJva2U9IiM5M2M0N2QiIC8+PHRleHQgeD0iNjM1IiB5PSIyNDgiIGZvbnQtc2l6ZT0iMTYiIGZvbnQtd2VpZ2h0PSJib2xkIiBmaWxsPSIjMjc0ZTEzIj50bHMoKTwvdGV4dD48dGV4dCB4PSI2MzUiIHk9IjI2OCIgZm9udC1zaXplPSI5LjUiIGZpbGw9IiM2NjYiPmhlYWRsaW5lIGV4dHJhY3RvcjwvdGV4dD48dGV4dCB4PSI2MzUiIHk9IjI4MSIgZm9udC1zaXplPSI5LjUiIGZpbGw9IiM2NjYiPisgdGxzX3ogLyB0bHNfY3RtYXggLyB0bHNfdGNyaXQ8L3RleHQ+PC9nPjwhLS0gZXh0cmFjdF90ZHQoKSAtLT48ZyB0ZXh0LWFuY2hvcj0ibWlkZGxlIj48cmVjdCB4PSI1NDUiIHk9IjMyMiIgd2lkdGg9IjE4MCIgaGVpZ2h0PSI4NiIgcng9IjciIGZpbGw9IiNkOWVhZDMiIHN0cm9rZT0iIzkzYzQ3ZCIgLz48dGV4dCB4PSI2MzUiIHk9IjM1NiIgZm9udC1zaXplPSIxNSIgZm9udC13ZWlnaHQ9ImJvbGQiIGZpbGw9IiMyNzRlMTMiPmV4dHJhY3RfdGR0KCk8L3RleHQ+PHRleHQgeD0iNjM1IiB5PSIzNzciIGZvbnQtc2l6ZT0iOS41IiBmaWxsPSIjNjY2Ij5vcHRpb25hbCBjb21wYXRpYmlsaXR5PC90ZXh0Pjx0ZXh0IHg9IjYzNSIgeT0iMzkwIiBmb250LXNpemU9IjkuNSIgZmlsbD0iIzY2NiI+Ym9vdHN0cmFwIGJ1bmRsZTwvdGV4dD48L2c+PCEtLSBhZHZhbmNlZCBwcmltaXRpdmVzIC0tPjxnIHRleHQtYW5jaG9yPSJtaWRkbGUiPjxyZWN0IHg9IjUzNSIgeT0iNDc0IiB3aWR0aD0iMjAwIiBoZWlnaHQ9IjcyIiByeD0iNyIgZmlsbD0iI2VmZWZlZiIgc3Ryb2tlPSIjYjdiN2I3IiBzdHJva2UtZGFzaGFycmF5PSI1LDQiIC8+PHRleHQgeD0iNjM1IiB5PSI0OTYiIGZvbnQtc2l6ZT0iMTEuNSIgZm9udC13ZWlnaHQ9ImJvbGQiIGZpbGw9IiM1NTUiPmFkdmFuY2VkIHByaW1pdGl2ZXM8L3RleHQ+PHRleHQgeD0iNjM1IiB5PSI1MTQiIGZvbnQtc2l6ZT0iOS41IiBmaWxsPSIjNzc3Ij5kZXJpdmVfbHQoKTsgZGVyaXZlX2N0bWF4KCk7PC90ZXh0Pjx0ZXh0IHg9IjYzNSIgeT0iNTI3IiBmb250LXNpemU9IjkuNSIgZmlsbD0iIzc3NyI+ZGVyaXZlX3Rjcml0KCk8L3RleHQ+PC9nPjwhLS0gZ2V0X2N0bWF4IC8gZ2V0X3ogLyBnZXRfc2hhcGUgKD0gZ2V0X3Rsc19lc3QpIC0tPjxnIHRleHQtYW5jaG9yPSJtaWRkbGUiPjxyZWN0IHg9IjgwMCIgeT0iMjEyIiB3aWR0aD0iMjUwIiBoZWlnaHQ9IjgyIiByeD0iNyIgZmlsbD0iI2Q5ZDJlOSIgc3Ryb2tlPSIjOGU3Y2MzIiAvPjx0ZXh0IHg9IjkyNSIgeT0iMjQ1IiBmb250LXNpemU9IjE0IiBmb250LXdlaWdodD0iYm9sZCIgZmlsbD0iIzIwMTI0ZCI+Z2V0X2N0bWF4KCkgwrcgZ2V0X3ooKTwvdGV4dD48dGV4dCB4PSI5MjUiIHk9IjI2MyIgZm9udC1zaXplPSIxNCIgZm9udC13ZWlnaHQ9ImJvbGQiIGZpbGw9IiMyMDEyNGQiPmdldF9zaGFwZSgpPC90ZXh0Pjx0ZXh0IHg9IjkyNSIgeT0iMjgyIiBmb250LXNpemU9IjkuNSIgZmlsbD0iIzY2NiI+Zml0IOKGkiBwYXJhbWV0ZXIgc3VtbWFyaWVzPC90ZXh0PjwvZz48IS0tIGFjY2Vzc29ycyAtLT48ZyB0ZXh0LWFuY2hvcj0ibWlkZGxlIj48cmVjdCB4PSI4MDAiIHk9IjMyMiIgd2lkdGg9IjI1MCIgaGVpZ2h0PSI4MiIgcng9IjciIGZpbGw9IiNkOWQyZTkiIHN0cm9rZT0iIzhlN2NjMyIgLz48dGV4dCB4PSI5MjUiIHk9IjM1MiIgZm9udC1zaXplPSIxMy41IiBmb250LXdlaWdodD0iYm9sZCIgZmlsbD0iIzIwMTI0ZCI+Z2V0Xypfc3VtbWFyeSgpIMK3IGdldF8qX2RyYXdzKCk8L3RleHQ+PHRleHQgeD0iOTI1IiB5PSIzNzIiIGZvbnQtc2l6ZT0iOS41IiBmaWxsPSIjNjY2Ij5wZXItcXVhbnRpdHkgc3VtbWFyaWVzPC90ZXh0Pjx0ZXh0IHg9IjkyNSIgeT0iMzg1IiBmb250LXNpemU9IjkuNSIgZmlsbD0iIzY2NiI+KyBib290c3RyYXAgZHJhd3M8L3RleHQ+PC9nPjwhLS0gcHJlZGljdF9zdXJ2aXZhbF9jdXJ2ZXMgLS0+PGcgdGV4dC1hbmNob3I9Im1pZGRsZSI+PHJlY3QgeD0iODAwIiB5PSI0OTIiIHdpZHRoPSIyMzUiIGhlaWdodD0iNzQiIHJ4PSI3IiBmaWxsPSIjZmNlNWNkIiBzdHJva2U9IiNmNmIyNmIiIC8+PHRleHQgeD0iOTE3IiB5PSI1MjIiIGZvbnQtc2l6ZT0iMTQuNSIgZm9udC13ZWlnaHQ9ImJvbGQiIGZpbGw9IiM3ODNmMDQiPnByZWRpY3Rfc3Vydml2YWxfY3VydmVzKCk8L3RleHQ+PHRleHQgeD0iOTE3IiB5PSI1NDIiIGZvbnQtc2l6ZT0iOS41IiBmaWxsPSIjNjY2Ij50ZW1wIMOXIGR1cmF0aW9uIGdyaWQ8L3RleHQ+PHRleHQgeD0iOTE3IiB5PSI1NTUiIGZvbnQtc2l6ZT0iOS41IiBmaWxsPSIjNjY2Ij4oKyBwcmVkaWN0X3N1cnZpdmFsX3N1cmZhY2UpPC90ZXh0PjwvZz48IS0tIHByZWRpY3RfaGVhdF9pbmp1cnkgLS0+PGcgdGV4dC1hbmNob3I9Im1pZGRsZSI+PHJlY3QgeD0iODAwIiB5PSI1ODYiIHdpZHRoPSIyMzUiIGhlaWdodD0iODAiIHJ4PSI3IiBmaWxsPSIjZmNlNWNkIiBzdHJva2U9IiNmNmIyNmIiIC8+PHRleHQgeD0iOTE3IiB5PSI2MTgiIGZvbnQtc2l6ZT0iMTQuNSIgZm9udC13ZWlnaHQ9ImJvbGQiIGZpbGw9IiM3ODNmMDQiPnByZWRpY3RfaGVhdF9pbmp1cnkoKTwvdGV4dD48dGV4dCB4PSI5MTciIHk9IjYzOCIgZm9udC1zaXplPSI5LjUiIGZpbGw9IiM2NjYiPmR5bmFtaWMgdHJhY2VzPC90ZXh0Pjx0ZXh0IHg9IjkxNyIgeT0iNjUxIiBmb250LXNpemU9IjkuNSIgZmlsbD0iIzY2NiI+KCsgaGVhdF9pbmp1cnlfZW52ZWxvcGUpPC90ZXh0PjwvZz48IS0tIHVzZXItc3VwcGxpZWQgdHJhY2UgYW5kIHJlcGFpciBzY2VuYXJpbzsgbm90IGEgcHVibGljIGhlbHBlciBBUEkgLS0+PGcgdGV4dC1hbmNob3I9Im1pZGRsZSI+PHJlY3QgeD0iODAwIiB5PSI2ODgiIHdpZHRoPSIyMzUiIGhlaWdodD0iNTYiIHJ4PSI3IiBmaWxsPSIjZjRmNGY0IiBzdHJva2U9IiNjYzg4ODgiIHN0cm9rZS1kYXNoYXJyYXk9IjUsNCIgLz48dGV4dCB4PSI5MTciIHk9IjcwOCIgZm9udC1zaXplPSIxMSIgZm9udC13ZWlnaHQ9ImJvbGQiIGZpbGw9IiNhMDQ1NDUiPnVzZXItc3VwcGxpZWQgdHJhY2UgJmFtcDsgcmVwYWlyIHNjZW5hcmlvPC90ZXh0Pjx0ZXh0IHg9IjkxNyIgeT0iNzI1IiBmb250LXNpemU9IjkuNSIgZmlsbD0iIzk5OSI+bm8gcHVibGljIGhlbHBlciBBUEk8L3RleHQ+PHRleHQgeD0iOTE3IiB5PSI3MzciIGZvbnQtc2l6ZT0iOS41IiBmaWxsPSIjOTk5Ij5yZXBhaXIgaXMgbm90IGZpdHRlZCBmcm9tIGRhdGE8L3RleHQ+PC9nPjwhLS0gcGxvdF8qKCkgZmFtaWx5IC0tPjxnIHRleHQtYW5jaG9yPSJtaWRkbGUiPjxyZWN0IHg9IjExODAiIHk9IjMzMCIgd2lkdGg9IjI0MCIgaGVpZ2h0PSIxNDAiIHJ4PSI3IiBmaWxsPSIjZWFkMWRjIiBzdHJva2U9IiNjMjdiYTAiIC8+PHRleHQgeD0iMTMwMCIgeT0iMzc4IiBmb250LXNpemU9IjE3IiBmb250LXdlaWdodD0iYm9sZCIgZmlsbD0iIzRjMTEzMCI+cGxvdF8qKCkgZmFtaWx5PC90ZXh0Pjx0ZXh0IHg9IjEzMDAiIHk9IjQwNCIgZm9udC1zaXplPSIxMC41IiBmaWxsPSIjNjY2Ij5wbG90X2NvbmZpZGVuY2VfZXllKCkgKGRlZmF1bHQpPC90ZXh0Pjx0ZXh0IHg9IjEzMDAiIHk9IjQyNCIgZm9udC1zaXplPSIxMC41IiBmaWxsPSIjNjY2Ij5zdXJ2aXZhbCBjdXJ2ZXMgwrcgc3VyZmFjZSDCtzwvdGV4dD48dGV4dCB4PSIxMzAwIiB5PSI0MzgiIGZvbnQtc2l6ZT0iMTAuNSIgZmlsbD0iIzY2NiI+VERUIGN1cnZlIMK3IGhlYXQgaW5qdXJ5PC90ZXh0PjwvZz48IS0tIGZyZXFUTFMgZXh0cmFzIChubyBkaXJlY3QgYmF5ZXNUTFMgYW5hbG9ndWUpIC0tPjxnIHRleHQtYW5jaG9yPSJtaWRkbGUiPjxyZWN0IHg9IjExODAiIHk9IjE1MCIgd2lkdGg9IjI0MCIgaGVpZ2h0PSIxMjAiIHJ4PSI3IiBmaWxsPSIjZmZmMmNjIiBzdHJva2U9IiNlMGI5NGUiIHN0cm9rZS1kYXNoYXJyYXk9IjUsNCIgLz48dGV4dCB4PSIxMzAwIiB5PSIxNzYiIGZvbnQtc2l6ZT0iMTIuNSIgZm9udC13ZWlnaHQ9ImJvbGQiIGZpbGw9IiM3ZjYwMDAiPmZyZXFUTFMgZXh0cmFzPC90ZXh0Pjx0ZXh0IHg9IjEzMDAiIHk9IjE5MCIgZm9udC1zaXplPSI5LjUiIGZpbGw9IiM5OTgyMDAiPihmcmVxVExTIGludGVydmFsIC8gZGlhZ25vc3RpYyB0b29scyk8L3RleHQ+PHRleHQgeD0iMTMwMCIgeT0iMjEyIiBmb250LXNpemU9IjEwIiBmaWxsPSIjNjY2Ij5XYWxkIMK3IHByb2ZpbGUgwrcgYm9vdHN0cmFwIENJczwvdGV4dD48dGV4dCB4PSIxMzAwIiB5PSIyMjYiIGZvbnQtc2l6ZT0iMTAiIGZpbGw9IiM2NjYiPihwcm9maWxlLXQgY2FsaWJyYXRlZCk8L3RleHQ+PHRleHQgeD0iMTMwMCIgeT0iMjQ0IiBmb250LXNpemU9IjEwIiBmaWxsPSIjNjY2Ij50aGUgQ29uZmlkZW5jZSBFeWU7PC90ZXh0Pjx0ZXh0IHg9IjEzMDAiIHk9IjI1OCIgZm9udC1zaXplPSIxMCIgZmlsbD0iIzY2NiI+MTIgaWRlbnRpZmlhYmlsaXR5IHdhcm5pbmdzPC90ZXh0PjwvZz48IS0tIENvbXBhcmlzb24gcGF0aCAtLT48dGV4dCB4PSI0MCIgeT0iODAwIiBmb250LXNpemU9IjExIiBmaWxsPSIjNzc3Ij5Db21wYXJpc29uIHBhdGg8L3RleHQ+PHRleHQgeD0iNDAiIHk9IjgxNCIgZm9udC1zaXplPSIxMSIgZmlsbD0iIzc3NyI+bm90IHRoZSBjb3JlIE1MIHdvcmtmbG93PC90ZXh0PjxnIHRleHQtYW5jaG9yPSJtaWRkbGUiPjxyZWN0IHg9IjI1MCIgeT0iNzgyIiB3aWR0aD0iMTYwIiBoZWlnaHQ9IjU0IiByeD0iNyIgZmlsbD0iI2VmZWZlZiIgc3Ryb2tlPSIjYjdiN2I3IiBzdHJva2UtZGFzaGFycmF5PSI1LDQiIC8+PHRleHQgeD0iMzMwIiB5PSI4MDYiIGZvbnQtc2l6ZT0iMTIuNSIgZm9udC13ZWlnaHQ9ImJvbGQiIGZpbGw9IiM1NTUiPnRzX3N0YWdlMSgpPC90ZXh0Pjx0ZXh0IHg9IjMzMCIgeT0iODIzIiBmb250LXNpemU9IjkuNSIgZmlsbD0iIzc3NyI+Y2xhc3NpY2FsIExUNTAgYnkgdGVtcDwvdGV4dD48cmVjdCB4PSI0NzAiIHk9Ijc4MiIgd2lkdGg9IjE2MCIgaGVpZ2h0PSI1NCIgcng9IjciIGZpbGw9IiNlZmVmZWYiIHN0cm9rZT0iI2I3YjdiNyIgc3Ryb2tlLWRhc2hhcnJheT0iNSw0IiAvPjx0ZXh0IHg9IjU1MCIgeT0iODA2IiBmb250LXNpemU9IjEyLjUiIGZvbnQtd2VpZ2h0PSJib2xkIiBmaWxsPSIjNTU1Ij50c19zdGFnZTIoKTwvdGV4dD48dGV4dCB4PSI1NTAiIHk9IjgyMyIgZm9udC1zaXplPSI5LjUiIGZpbGw9IiM3NzciPk9MUyBURFQgbGluZTwvdGV4dD48cmVjdCB4PSI2OTAiIHk9Ijc4MiIgd2lkdGg9IjE3NSIgaGVpZ2h0PSI1NCIgcng9IjciIGZpbGw9IiNlZmVmZWYiIHN0cm9rZT0iI2I3YjdiNyIgc3Ryb2tlLWRhc2hhcnJheT0iNSw0IiAvPjx0ZXh0IHg9Ijc3NyIgeT0iODA2IiBmb250LXNpemU9IjEyLjUiIGZvbnQtd2VpZ2h0PSJib2xkIiBmaWxsPSIjNTU1Ij50c19jaSgpIC8gdHNfY3VydmUoKTwvdGV4dD48dGV4dCB4PSI3NzciIHk9IjgyMyIgZm9udC1zaXplPSI5LjUiIGZpbGw9IiM3NzciPnVuY2VydGFpbnR5ICsgbGluZTwvdGV4dD48L2c+PCEtLSBMZWdlbmQgLS0+PHRleHQgeD0iMTE4MCIgeT0iODU4IiBmb250LXNpemU9IjEwIiBmaWxsPSIjODg4Ij5Tb2xpZCA9IG1haW4gd29ya2Zsb3cgICAgRGFzaGVkID0gb3B0aW9uYWwgLyBwbGFubmVkPC90ZXh0Pjwvc3ZnPg==)

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
