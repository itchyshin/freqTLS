# The model and its parameterisation

This vignette is the mathematical reference for `freqTLS`: the
four-parameter logistic (4PL) thermal death-time curve, the direct
`CTmax`/`z` parameterisation, the disjoint-bounds asymptote transform,
the relative-versus-absolute survival threshold, and the exact algebraic
bridge to [`bayesTLS`](https://github.com/daniel1noble/bayesTLS). The
package’s implementation contract is tested against these equations;
this vignette mirrors it and checks the bridge identities numerically
(no Stan required). If you already trust that freqTLS and bayesTLS
target the same fitted curve, you can skip straight to the worked
examples in
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
\qquad k = \exp(\log k).
```

- $`\mathrm{low}`$ is the lower asymptote (survival at long exposures),
- $`\mathrm{up}`$ is the upper asymptote (survival at short exposures),
- $`k > 0`$ is the steepness, and
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

Two properties make this the right coordinate system for profiling:

- At $`T_i = \mathrm{CTmax}_i`$, the midpoint is exactly
  $`\log_{10}(t_\mathrm{ref})`$ — i.e. `CTmax` is the temperature at
  which the threshold crossing occurs at the reference time
  $`t_\mathrm{ref}`$.
- The slope of the midpoint in temperature is
  $`\partial\,\mathrm{mid}/\partial T = -1/z`$, so `z` is the change in
  temperature per decade ($`\log_{10}`$ unit) of exposure duration — the
  thermal sensitivity (degrees Celsius per decade).

Because `CTmax` and `z` are model coordinates (not derived afterwards),
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

Under this parameterisation `up` has its own coordinate
$`\beta_\mathrm{up}`$, just like `low`. `freqTLS` nonetheless reports
`up` with the delta-method Wald interval: its profile path is not yet
wired for $`\beta_\mathrm{up}`$ (the work is symmetric with `low`,
simply not yet implemented), and it says so. Every other parameter is
profiled on its single coordinate. The full table of coordinates and
links:

| Natural parameter     | Internal coordinate | Link                             |
|-----------------------|---------------------|----------------------------------|
| `low`                 | `beta_low`          | logit (onto the lower half-band) |
| `up`                  | `beta_up`           | logit (onto the upper half-band) |
| `k`                   | `beta_logk`         | log                              |
| `CTmax` (per group)   | `beta_CT[g]`        | identity                         |
| `z` (per group)       | `beta_logz[g]`      | log                              |
| `phi` (beta-binomial) | `log_phi`           | log                              |

## Relative versus absolute thresholds

A “lethal time” such as the LT$`_{50}`$ is the duration at which
survival crosses a target probability. There are two conventions:

- **Relative** (the `freqTLS` default): the target is interpreted
  relative to the fitted asymptotes, so $`p = 0.5`$ means halfway
  between `low` and `up` — which is exactly the 4PL midpoint
  $`\mathrm{mid}`$. This is the configuration that matches the
  `bayesTLS` `target_surv = "relative"` setting and is what the
  benchmark uses (see
  [`vignette("comparing-to-bayesTLS")`](https://itchyshin.github.io/freqTLS/articles/comparing-to-bayesTLS.md)).
- **Absolute**: the target is an absolute survival probability,
  requiring $`p`$ to lie strictly between `low` and `up`.

[`derive_lt()`](https://itchyshin.github.io/freqTLS/reference/derive_lt.md)
solves the 4PL for the crossing duration at a temperature, and
[`plot_tdt_curve()`](https://itchyshin.github.io/freqTLS/reference/plot_tdt_curve.md)
plots the relative midpoint crossing against temperature. On the
$`\log_{10} d`$ axis the relative-threshold crossing is the line
$`\log_{10} d = \mathrm{mid}(T) = \log_{10}(t_\mathrm{ref}) - (T - \mathrm{CTmax})/z`$,
whose slope is $`-1/z`$ — the classic log-linear thermal death-time
line.

``` r

# LT50 (relative midpoint) at three temperatures, in hours
derive_lt(fit, p = 0.5, temp = c(35, 36, 37))
#> [1] 1.6998018 0.9555978 0.5372198
```

## The bridge to bayesTLS

`bayesTLS` fits the same 4PL but, in its constant-shape configuration
(`temp_effects = "mid"`), parameterises the midpoint as a line in
temperature,

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

These are exactly the `bayesTLS` identities. The reparameterisation
shares `(low, up, k)` and is smooth and invertible (the Jacobian is
nonsingular while `z` is finite), so the two models have the **same
likelihood, the same fitted curve, and the same maximum-likelihood
estimate** under the matched constant-shape, relative-threshold
configuration. The only difference is that `CTmax` and `z` are
coordinates in `freqTLS`, hence directly profile-able.

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
