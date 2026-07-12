# freqTLS

> Fast, prior-free frequentist confidence intervals — Wald,
> profile-likelihood, and bootstrap — for thermal-load-sensitivity
> (thermal death-time) models; the maximum-likelihood complement to
> `bayesTLS`.

`freqTLS` fits the single-stage four-parameter logistic (4PL) thermal
death-time model by maximum likelihood via
[TMB](https://github.com/kaskr/adcomp), parameterised **directly** in
`CTmax` (critical thermal maximum) and `z` (thermal sensitivity). It
then returns prior-free **frequentist confidence intervals** — Wald,
profile-likelihood (asymmetry-respecting), and bootstrap — for binomial
and beta-binomial survival counts, and for continuous **proportion**
responses in `(0, 1)` via the beta family.

Its signature display is the **Confidence Eye**: a pale horizontal lens
spanning the likelihood interval, with a hollow point estimate. These
are likelihood *confidence* intervals, not posteriors, so the visual
deliberately avoids posterior-density iconography, and the prose never
uses “posterior” or “credible” language.

![Hero figure: a horizontal Confidence Eye for CTmax and z. Each
parameter is a pale, shallow lens spanning its 95% profile-likelihood
confidence interval, with a hollow point estimate at the
maximum-likelihood value. The lens shape reads as an interval, not a
probability density.](reference/figures/README-readme-eye-1.png)

## What freqTLS does

- Fits the 4PL thermal death-time model by **maximum likelihood**,
  directly in `CTmax` and `z`, for **binomial** and **beta-binomial**
  survival counts and continuous **beta** proportions in `(0, 1)` (no
  trials column needed).
- Inverts the likelihood-ratio test to give **profile-likelihood
  confidence intervals** that respect asymmetry and carry no prior.
- Surfaces **identifiability** honestly: when a profile does not close,
  it is flagged, never fabricated. By default
  [`confint()`](https://rdrr.io/r/stats/confint.html) then falls back to
  a prior-free **parametric bootstrap**; unstable refits remain
  unavailable rather than producing a fabricated bound. Set
  `fallback = FALSE` to keep the open profile, which the Confidence Eye
  marks with a hollow point and no lens.
- Ships a tidy column interface
  ([`fit_tls()`](https://itchyshin.github.io/freqTLS/reference/fit_tls.md))
  and a `brms`/`drmTMB`-style **formula interface**
  ([`tls_bf()`](https://itchyshin.github.io/freqTLS/reference/tls_bf.md))
  with fixed-effect predictors on any sub-parameter (`CTmax`, `log_z`,
  `low`, `up`, `log_k`), plus prediction, lethal-time derivation, and
  plotting (survival curves, the survival surface, and the Confidence
  Eye).
- Fits **random intercepts** on `CTmax`, `log_z`, `low`, and `log_k`
  (`<param> ~ <fixed> + (1 | group)`), with profile intervals for the
  fixed effects. At most one intercept term is supported per coordinate,
  and multiple terms remain independent variance blocks; correlated,
  crossed, nested, and random-slope structures are not implemented.
- Derives critical temperatures —
  [`derive_ctmax()`](https://itchyshin.github.io/freqTLS/reference/derive_ctmax.md)
  (absolute threshold) and
  [`derive_tcrit()`](https://itchyshin.github.io/freqTLS/reference/derive_tcrit.md)
  (rate-multiplier) — and predicts **heat injury** under a temperature
  trace
  ([`predict_heat_injury()`](https://itchyshin.github.io/freqTLS/reference/predict_heat_injury.md))
  with a prior-free bootstrap confidence band
  ([`heat_injury_envelope()`](https://itchyshin.github.io/freqTLS/reference/heat_injury_envelope.md),
  [`plot_heat_injury()`](https://itchyshin.github.io/freqTLS/reference/plot_heat_injury.md)).
  See
  [`vignette("frequentist-and-bayesian")`](https://itchyshin.github.io/freqTLS/articles/frequentist-and-bayesian.md)
  for how the likelihood and Bayesian paths compare.

## Why not the two-stage workflow

The classical workflow fits a curve per temperature, then regresses the
derived endpoints in a second stage. That discards the joint
uncertainty: the second-stage standard errors treat noisy first-stage
estimates as fixed, and the design’s identifiability is invisible.
`freqTLS` fits **one** model to all the counts at once and inverts the
likelihood for `CTmax` and `z` directly, so the interval reflects the
whole design and flags weakly identified parameters.

## How it differs from bayesTLS

`freqTLS` and [`bayesTLS`](https://github.com/daniel1noble/bayesTLS) fit
the **same model**. Under the matched constant-shape configuration they
target the same likelihood and the same fitted curve; they differ only
in how uncertainty is summarised.

|  | `bayesTLS` | `freqTLS` |
|----|----|----|
| Inference | Bayesian posterior (MCMC / Stan) | Maximum likelihood + profile likelihood |
| Intervals | Credible intervals (prior-informed) | Confidence intervals (prior-free) |
| Needs Stan / MCMC | Yes | No |
| Speed | Sampling (seconds to minutes) | Optimisation (~ms to ~1 s; see the timing table in [`vignette("comparing-to-bayesTLS")`](https://itchyshin.github.io/freqTLS/articles/comparing-to-bayesTLS.md)) |
| Weak identification | Priors can still yield a finite posterior interval | Open profiles are flagged; bootstrap fallback can also be unstable |
| Extras | Heat-injury and repair sub-models, priors | Explicit non-closing / identifiability flags |

Use `freqTLS` when you want fast, prior-free, asymmetry-respecting
intervals and an explicit identifiability check. When a profile does not
close it can fall back to a parametric bootstrap; if too few stable
refits remain, the result stays unavailable rather than reporting a
fabricated bound. Use `bayesTLS` when you want a full Bayesian workflow,
prior information, or the heat-injury and repair sub-models. The two are
complementary lenses on the same model, not competitors.

## Installation

After the package appears on CRAN, install the released version with:

``` r

install.packages("freqTLS")
```

Or install the development version from
[GitHub](https://github.com/itchyshin/freqTLS):

``` r

# install.packages("pak")
pak::pak("itchyshin/freqTLS")
```

## Quick start

The workflow follows the same **standardize → fit → quantities → plot**
sequence as `bayesTLS`, but the packages are not drop-in replacements.
`freqTLS` implements the tested fixed/grouped designs and limited
random-intercept structures described below; more general Bayesian
models remain in `bayesTLS`. The engine is maximum likelihood (no Stan,
no MCMC, no internet); uncertainty is a frequentist trio (Wald, profile,
bootstrap) instead of a posterior. The deliberate differences are
documented in
[`vignette("comparing-to-bayesTLS")`](https://itchyshin.github.io/freqTLS/articles/comparing-to-bayesTLS.md):
the absolute (p-survival) threshold and non-default asymptote `bounds`
are not yet wired through the ML backbone (fit on the relative midpoint,
then convert with
[`extract_tdt()`](https://itchyshin.github.io/freqTLS/reference/extract_tdt.md));
uncertainty comes as bootstrap replicates rather than posterior draws;
and the temperature effect defaults to the constant-shape configuration.

``` r

library(freqTLS)

# 1. Standardize raw survival counts (the shared bayesTLS entry point)
dat <- simulate_tls(family = "beta_binomial", CTmax = 36, z = 4, phi = 50, seed = 1)
std <- standardize_data(dat, temp = "temp", duration = "duration",
                        n_total = "total", n_surv = "survived")

# 2. Fit the 4PL by maximum likelihood, directly in CTmax and z
fit <- fit_4pl(std, t_ref = 1)

# 3. Headline thermal-death-time quantities with profile-likelihood intervals
tls(fit)
#> <tls> relative threshold; quantities: z, CTmax (profile intervals)
#> # A tibble: 2 × 4
#>   quantity median lower upper
#>   <chr>     <dbl> <dbl> <dbl>
#> 1 CTmax     36.0  35.7  36.3 
#> 2 z          3.90  3.43  4.38
```

For per-group CTmax/z, pass formulas —
`fit_4pl(dat, ctmax = ~ 0 + species, z = ~ 0 + species)` — exactly as in
`bayesTLS`.
[`extract_tdt()`](https://itchyshin.github.io/freqTLS/reference/extract_tdt.md),
[`predict_survival_curves()`](https://itchyshin.github.io/freqTLS/reference/predict_survival_curves.md),
and
[`diagnose_tdt_fit()`](https://itchyshin.github.io/freqTLS/reference/diagnose_tdt_fit.md)
complete the twin surface; the column / formula engine interface
([`fit_tls()`](https://itchyshin.github.io/freqTLS/reference/fit_tls.md),
[`tls_bf()`](https://itchyshin.github.io/freqTLS/reference/tls_bf.md))
remains available underneath.

``` r

# 4. Plot the fitted survival surface (the Confidence Eye is shown above)
plot_survival_curves(fit)
```

![Fitted 4PL survival curves: survival probability declining with
exposure duration, one curve per assay temperature, with observed
proportions overlaid as
points.](reference/figures/README-readme-survival-1.png)

## Formula interface

If you prefer a grammar, build the model with
[`tls_bf()`](https://itchyshin.github.io/freqTLS/reference/tls_bf.md)
and pass it as the first argument with the data in `data =`. The
left-hand side names the survival counts (`successes | trials(total)`);
the right-hand side tags the two axes with the
[`time()`](https://rdrr.io/r/stats/time.html) and `temp()` markers. The
formula path feeds the **same** likelihood engine, so the fits are
numerically identical:

``` r

# Column form and formula form fit the same model:
fit_f <- fit_tls(
  tls_bf(survived | trials(total) ~ time(duration) + temp(temp)),
  data   = dat,
  family = "beta_binomial",
  tref   = 1
)
all.equal(coef(fit_f), coef(fit))
#> [1] TRUE
```

Add a sub-parameter formula for predictors on `CTmax` and `log_z` (for
example `CTmax ~ life_stage, log_z ~ life_stage` for a grouped fit).
These two headline coordinates must use the same fixed-effect design
columns; their supported random-intercept groupings may differ. The
shape coordinates may use independent fixed designs.

## Random effects on CTmax and z

When thermal tolerance varies across colonies, clutches, or populations,
add a **random intercept on `CTmax`** with `CTmax ~ 1 + (1 | group)`.
freqTLS fits it by maximum likelihood through TMB’s Laplace
approximation (matching the `bayesTLS` random-effects-on-the-midpoint
configuration), reports the between-group standard deviation as
`sigma_CTmax`, and returns the group BLUPs via
[`ranef()`](https://itchyshin.github.io/freqTLS/reference/ranef.md). The
no-random-effects path stays byte-identical to the fixed-effects model.

``` r

# 15 colonies whose CTmax varies with SD = 1.5 C.
dre <- simulate_tls(family = "binomial", CTmax = 36, z = 4,
                    re_sd = 1.5, n_re_groups = 15, seed = 1)
fit_re <- fit_tls(
  tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
         CTmax ~ 1 + (1 | colony)),
  data = dre, family = "binomial", tref = 1
)
# Between-colony SD of CTmax (with a Wald interval):
tp <- tidy_parameters(fit_re)
tp[tp$parameter == "sigma_CTmax", c("parameter", "estimate", "conf.low", "conf.high")]
#> # A tibble: 1 × 4
#>   parameter   estimate conf.low conf.high
#>   <chr>          <dbl>    <dbl>     <dbl>
#> 1 sigma_CTmax     1.48     1.03      2.12

# Colony BLUPs (deviations from the population CTmax):
head(ranef(fit_re), 3)
#> # A tibble: 3 × 4
#>   group term  estimate std.error
#>   <chr> <chr>    <dbl>     <dbl>
#> 1 g1    CTmax   -1.03      0.390
#> 2 g10   CTmax   -0.651     0.390
#> 3 g11   CTmax    2.05      0.390

# Choose the prediction target explicitly for a random-intercept fit.
colony_1 <- as.character(ranef(fit_re)$group[1])
new_re <- data.frame(temp = 36, duration = 2, colony = colony_1)
data.frame(
  target = c("population", "colony"),
  survival = c(
    predict(fit_re, new_re, re.form = "population"),
    predict(fit_re, new_re, re.form = "conditional")
  )
)
#>       target   survival
#> 1 population 0.22405366
#> 2     colony 0.08768286
```

Population predictions set every random intercept to zero. Conditional
predictions add the fitted BLUP and therefore require each relevant
grouping column in `newdata`; unseen groups stop with guidance to use
the population prediction. Calling
[`predict()`](https://rdrr.io/r/stats/predict.html) without `re.form` on
a random-effects fit warns and returns the population prediction.

A random intercept on **thermal sensitivity** works the same way, with
`log_z ~ 1 + (1 | group)`. Because `z` is modelled on the log scale, the
deviation is Gaussian on `log(z)` and `sigma_logz` is a standard
deviation on `log(z)` — read `exp(sigma_logz)` as the approximate
multiplicative spread of `z` across groups, not a z-scale SD. The two
intercepts can be combined; with the **same** grouping factor freqTLS
fits two *independent* variances (no correlation term) and warns, since
group-level `CTmax` and `z` deviations are usually correlated — reach
for `bayesTLS` when you need a correlated random effect. Like
`sigma_CTmax`, `sigma_logz` is a maximum-likelihood variance component,
biased low with few groups.

## Population differences in curve shape

Two populations can differ not only in *where* the thermal-death curve
sits (`CTmax`, `z`) but in its *shape* — how steeply survival collapses
with exposure (`k`), or the background and maximum survival (`low`,
`up`). The formula interface lets `low`, `up`, and `log_k` vary by a
grouping factor, relaxing the shared-shape restriction. Here a
heat-tolerant and a heat-sensitive population differ in both `CTmax` and
the curve steepness `k`:

``` r

# The tolerant population has a higher CTmax and a steeper survival collapse.
dpop <- simulate_tls(family = "binomial", group = c("tolerant", "sensitive"),
                     CTmax = c(38, 35), z = c(3.5, 3.5),
                     low = 0.02, up = 0.98, k = c(8, 3), seed = 11)
fit_pop <- fit_tls(
  tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
         CTmax ~ group, log_z ~ group,
         low ~ group, up ~ group, log_k ~ group),
  data = dpop, family = "binomial", tref = 1
)
# Per-group steepness k with profile-likelihood confidence intervals:
confint(fit_pop, parm = c("k:tolerant", "k:sensitive"), method = "profile")
#> # A tibble: 2 × 8
#>   parameter   conf.low conf.high estimate level method  scale conf.status
#>   <chr>          <dbl>     <dbl>    <dbl> <dbl> <chr>   <chr> <chr>      
#> 1 k:tolerant      7.43     10.6      8.86  0.95 profile log   ok         
#> 2 k:sensitive     2.40      3.48     2.90  0.95 profile log   ok
```

The two steepness estimates have non-overlapping confidence intervals,
so the shape difference is identified by the data, not assumed. The
fitted curves show it directly — survival collapses abruptly in the
tolerant population and gradually in the sensitive one:

``` r

plot_survival_curves(fit_pop)
```

![Fitted 4PL survival curves faceted by population. In the tolerant
panel survival drops steeply with exposure duration; in the sensitive
panel it declines more gradually — a per-group difference in curve
steepness (k), with observed proportions
overlaid.](reference/figures/README-grouped-shape-curves-1.png)

## The model

For exposure duration `d` (with `logd = log10(d)`) and assay temperature
`T`, survival follows the descending four-parameter logistic

``` math
p = \mathrm{low} + \frac{\mathrm{up} - \mathrm{low}}{1 + \exp\!\big(k\,(\log_{10} d - \mathrm{mid})\big)},
\qquad
\mathrm{mid} = \log_{10}(t_\mathrm{ref}) - \frac{T - \mathrm{CTmax}}{z}.
```

`CTmax` is the critical thermal maximum at the reference time `tref`,
and `z` is the thermal sensitivity (degrees Celsius per decade of
exposure duration). The temperature effect runs through the midpoint
only (shared `low`, `up`, `k`), matching the `bayesTLS` constant-shape
configuration. Because `CTmax` and `z` are direct model coordinates,
both can be profiled directly.

See
[`vignette("freqTLS")`](https://itchyshin.github.io/freqTLS/articles/freqTLS.md)
for the full walkthrough,
[`vignette("model-math")`](https://itchyshin.github.io/freqTLS/articles/model-math.md)
for the exact bridge to `bayesTLS`, and
[`vignette("profile-likelihood")`](https://itchyshin.github.io/freqTLS/articles/profile-likelihood.md)
for what the profile is doing and the honest non-closing fallback.

## Credit and origins

The thermal-load-sensitivity modelling framework implemented here was
introduced by **Daniel W. A. Noble, Pieter A. Arnold, and Patrice
Pottier** in the [`bayesTLS`](https://github.com/daniel1noble/bayesTLS)
package. The model and the mapping from the 4PL midpoint slope to `z`
and `CTmax` are theirs. `freqTLS` is a likelihood implementation of that
framework. Please cite `bayesTLS` alongside `freqTLS` when you use this
package. `freqTLS` contributes a TMB maximum-likelihood likelihood, the
direct `CTmax`/`z` reparameterisation that makes both quantities
directly profile-able, and profile-likelihood confidence intervals — a
likelihood complement to the Bayesian path (no priors, no MCMC, no
Stan).

## Data credits

The six case-study datasets vendored with `freqTLS` (`shrimp_lethal`,
`shrimp_sublethal`, `zebrafish_lethal`, `zebrafish_o2`, `dsuzukii`, and
`aphid_tdt`) are drawn from the thermal-load-sensitivity literature and
the [`bayesTLS`](https://github.com/daniel1noble/bayesTLS) framework,
redistributed with attribution. They include the two new published case
studies — `aphid_tdt` (cereal aphids across species and ages; Li et
al. 2023) and `zebrafish_o2` (zebrafish across an oxygen gradient;
Saruhashi et al. 2026) — alongside `dsuzukii` (*Drosophila suzukii* by
sex; Ørsted et al. 2024, Zenodo 10.5281/zenodo.10602268). See
[`?aphid_tdt`](https://itchyshin.github.io/freqTLS/reference/aphid_tdt.md),
[`?zebrafish_o2`](https://itchyshin.github.io/freqTLS/reference/zebrafish_o2.md),
the other dataset help pages, and `inst/CITATION` for sources and
licences. `freqTLS` code is released under GPL (\>= 3); the original
data licences apply to the vendored data. Please cite `bayesTLS` and the
original data sources (see `citation("freqTLS")`) when you use these
datasets.
