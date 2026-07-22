# The model and its parameterisation

This vignette is the mathematical reference for `freqTLS`: the
four-parameter logistic (4PL) thermal death-time curve, the direct
`CTmax`/`z` parameterisation, the disjoint-bounds asymptote transform,
the relative-versus-absolute survival threshold, and the algebraic
bridge to [`bayesTLS`](https://github.com/daniel1noble/bayesTLS). The
thermal-load-sensitivity framework was introduced by Daniel W. A. Noble,
Pieter A. Arnold, and Patrice Pottier in `bayesTLS`. The package’s
implementation contract is tested against these equations; this vignette
mirrors it and checks the bridge identities numerically (no Stan
required). If you already understand the matched-configuration bridge to
bayesTLS, you can skip straight to the worked examples in
[`vignette("freqTLS")`](https://itchyshin.github.io/freqTLS/articles/freqTLS.md)
and
[`vignette("comparing-to-bayesTLS")`](https://itchyshin.github.io/freqTLS/articles/comparing-to-bayesTLS.md).

``` r

library(freqTLS)
```

## The 4PL thermal death-time curve

Let $`d`$ be the exposure duration and $`\log d = \log_{10} d`$.
Survival probability follows the descending four-parameter logistic

``` math
p = \mathrm{low} + \frac{\mathrm{up} - \mathrm{low}}{1 + \exp\!\big(k\,(\log_{10} d - \mathrm{mid})\big)},
\qquad k = \exp(\ln k).
```

- $`\mathrm{low}`$ is the lower asymptote (survival at long exposures),
- $`\mathrm{up}`$ is the upper asymptote (survival at short exposures),
- $`k > 0`$ is the steepness; its internal coordinate is the natural
  logarithm $`\ln k`$, and
- $`\mathrm{mid}`$ is the midpoint on the $`\log_{10} d`$ axis.

Survival is high at short durations and falls toward $`\mathrm{low}`$ at
long durations.

## The direct `CTmax`/`z` parameterisation

`freqTLS` lets temperature enter the midpoint directly through the two
headline quantities. With $`z_i = \exp(\eta_{\log z, i})`$ and
$`\mathrm{CTmax}_i`$ a function of the design,

``` math
\mathrm{mid}_i = \log_{10}(t_\mathrm{ref}) - \frac{T_i - \mathrm{CTmax}_i}{z_i}.
```

This parameterisation makes the two biological quantities direct model
parameters, so profile likelihood can constrain them directly:

- At $`T_i = \mathrm{CTmax}_i`$, the midpoint is exactly
  $`\log_{10}(t_\mathrm{ref})`$ — i.e. `CTmax` is the temperature at
  which the threshold crossing occurs at the reference time
  $`t_\mathrm{ref}`$.
- The slope of the midpoint in temperature is
  $`\partial\,\mathrm{mid}/\partial T = -1/z`$, so `z` is the change in
  temperature per order of magnitude (a one-unit change in $`\log_{10}`$
  duration) — the thermal sensitivity in degrees Celsius per 10-fold
  change in exposure duration.

Because `CTmax` and `z` are model parameters (not derived afterwards),
each can be profiled directly. We can check the two properties on a
fitted model:

``` r

set.seed(1)
dat <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
fit <- fit_tls(dat, y = survived, n = total, time = duration, temp = temp,
               family = "binomial", tref = 1)
ct <- get_ctmax(fit)$estimate
zz <- get_z(fit)$estimate

# (1) midpoint at temp = CTmax equals log10(tref) = log10(1) = 0
predict(fit, data.frame(temp = ct, duration = 1), type = "midpoint")
#> [1] 0

# (2) midpoint slope in temperature is -1/z
mids <- predict(fit, data.frame(temp = c(ct, ct + 1), duration = 1), type = "midpoint")
c(slope = diff(mids), minus_one_over_z = -1 / zz)
#>            slope minus_one_over_z 
#>       -0.2501231       -0.2501231
```

## Disjoint-bounds asymptotes

The asymptotes use the bayesTLS
[`compute_4pl_bounds()`](https://itchyshin.github.io/freqTLS/reference/compute_4pl_bounds.md)
parameterisation: the feasible band $`[\ell, u]`$ (default $`[0, 1]`$)
is split at its midpoint, and `low` and `up` each map an unconstrained
coefficient onto one half, so $`\mathrm{up} > \mathrm{low}`$ holds
automatically:

``` math
\mathrm{low} = \ell_{\min} + w_\mathrm{low}\,\mathrm{logit}^{-1}(\beta_\mathrm{low}),
\qquad
\mathrm{up}  = u_{\min}  + w_\mathrm{up}\,\mathrm{logit}^{-1}(\beta_\mathrm{up}).
```

`low` is confined to the lower half-band $`[\ell_{\min}, \ell_{\max}]`$
and `up` to the upper half-band $`[u_{\min}, u_{\max}]`$ (the bands
meet, with a tiny separating gap, at the midpoint). Any
$`(\beta_\mathrm{low}, \beta_\mathrm{up})`$ therefore gives a valid
ordered pair $`\ell < \mathrm{low} < \mathrm{up} < u`$. This is
unconstrained and smooth, which keeps the optimiser and the profiles
well-behaved, and it matches bayesTLS exactly so the two packages share
the asymptote contract.

Under this parameterisation `up` is fitted through its own coordinate
$`\beta_\mathrm{up}`$, just as `low` is fitted through
$`\beta_\mathrm{low}`$. The limitation concerns interval computation,
not fitting: freqTLS does not yet profile $`\beta_\mathrm{up}`$, so it
reports a delta-method Wald interval for `up` (or a bootstrap interval
when requested). The full table of parameters and links:

| Natural parameter     | Internal coordinate | Link                             |
|-----------------------|---------------------|----------------------------------|
| `low`                 | `beta_low`          | logit (onto the lower half-band) |
| `up`                  | `beta_up`           | logit (onto the upper half-band) |
| `k`                   | `beta_logk`         | natural log (`ln`)               |
| `CTmax` (per group)   | `beta_CT[g]`        | identity                         |
| `z` (per group)       | `beta_logz[g]`      | log                              |
| `phi` (beta-binomial) | `log_phi`           | log                              |

## Relative versus absolute thresholds

A “lethal time” such as the LT$`_{50}`$ is the duration at which
survival crosses a target probability. There are two conventions. A
**relative threshold** is a position between the fitted asymptotes; an
**absolute threshold** is a fixed survival probability on the response
scale:

- **Relative** (the `freqTLS` default): the target is interpreted
  relative to the fitted asymptotes, so relative fraction $`0.5`$ means
  halfway between `low` and `up` — which is exactly the 4PL midpoint
  $`\mathrm{mid}`$. This is the configuration that matches the
  `bayesTLS` `target_surv = "relative"` setting and is what the
  benchmark uses (see
  [`vignette("comparing-to-bayesTLS")`](https://itchyshin.github.io/freqTLS/articles/comparing-to-bayesTLS.md)).
- **Absolute**: the target is an absolute survival probability,
  requiring $`p`$ to lie strictly between `low` and `up`.

[`derive_lt()`](https://itchyshin.github.io/freqTLS/reference/derive_lt.md)
solves the 4PL for the duration at which survival reaches its numeric
absolute probability `p`, which must lie strictly between `low` and
`up`. At the relative midpoint, use `p = (low + up) / 2`;
[`plot_tdt_curve()`](https://itchyshin.github.io/freqTLS/reference/plot_tdt_curve.md)
uses that midpoint by default and can plot another valid absolute `p`.
On the $`\log_{10} d`$ axis the relative-threshold crossing is the line
$`\log_{10} d = \mathrm{mid}(T) = \log_{10}(t_\mathrm{ref}) - (T - \mathrm{CTmax})/z`$,
whose slope is $`-1/z`$ — the classic log-linear thermal death-time
line.

``` r

# LT50 (relative midpoint) at three temperatures, in hours
derive_lt(fit, p = 0.5, temp = c(35, 36, 37))
#> [1] 1.6998018 0.9555978 0.5372198
```

## The bridge to bayesTLS

For the matched constant-shape midpoint configuration
(`temp_effects = "mid"`), `bayesTLS` parameterises the midpoint as a
line in temperature,

``` math
\mathrm{mid}(T) = b_{\mathrm{mid,Intercept}} + b_{\mathrm{mid},T_c}\,(T - \bar T),
```

and reads the thermal sensitivity and critical thermal maximum off that
line:

``` math
z = -\frac{1}{b_{\mathrm{mid},T_c}},
\qquad
\mathrm{CTmax}(t_\mathrm{ref}) = \bar T + \frac{\log_{10}(t_\mathrm{ref}) - b_{\mathrm{mid,Intercept}}}{b_{\mathrm{mid},T_c}}.
```

Expanding the `freqTLS` midpoint as a line in $`T`$ gives the inverse
map:

``` math
\beta_1 = -\frac{1}{z}, \qquad
\beta_0 = \log_{10}(t_\mathrm{ref}) + \frac{\mathrm{CTmax} - \bar T}{z},
```

so

``` math
z = -\frac{1}{\beta_1}, \qquad
\mathrm{CTmax} = \bar T + \frac{\log_{10}(t_\mathrm{ref}) - \beta_0}{\beta_1}.
```

These are the midpoint-line identities used by `bayesTLS`. The
reparameterisation shares `(low, up, k)` and is smooth and invertible
while `z` is finite. Therefore a matched constant-shape,
relative-threshold likelihood has the same fitted curve under either
coordinate system. Current `bayesTLS` also offers direct CTmax/z
parameterisation and an absolute-threshold option; numerical comparisons
must still match data, formulas, bounds, threshold, and random-effect
structure. freqTLS’s distinct contribution is maximum-likelihood fitting
with direct profile-likelihood targets.

We can verify the bridge numerically without `bayesTLS`. Fit the
midpoint line directly from the model’s own predicted midpoints (linear
in $`T`$), then recover `CTmax` and `z` from the slope and intercept:

``` r

Tbar <- mean(c(35, 37))               # any centring temperature works
mids <- predict(fit, data.frame(temp = c(35, 37), duration = 1), type = "midpoint")
beta1 <- diff(mids) / 2               # slope in T  (= -1/z)
beta0 <- mids[1] - beta1 * (35 - Tbar) # intercept at T = Tbar

z_recovered     <- -1 / beta1
ctmax_recovered <- Tbar + (log10(1) - beta0) / beta1

rbind(
  fitted    = c(CTmax = ct, z = zz),
  recovered = c(CTmax = ctmax_recovered, z = z_recovered)
)
#>              CTmax        z
#> fitted    35.92586 3.998031
#> recovered 35.92586 3.998031
```

The recovered `CTmax` and `z` match the fitted values to numerical
precision, confirming that the direct parameterisation and the
`bayesTLS` line are two coordinate systems for the same curve.
Equivariance of the profile likelihood under this monotone map is why
the `z` interval equals $`\exp()`$ of the internal `log_z` interval (see
[`vignette("profile-likelihood")`](https://itchyshin.github.io/freqTLS/articles/profile-likelihood.md)).
