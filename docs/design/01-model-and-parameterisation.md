# Model and Parameterisation

This document is the authoritative record of the freqTLS model, its direct
`CTmax`/`z` parameterisation, the disjoint-bounds asymptotes, and the exact
equivalence to the bayesTLS constant-shape model. Any change to the
parameterisation must update this file in the same commit (AGENTS.md design rule
3). Symbolic statements are verified against the bayesTLS source at HEAD
(2026-06-16); see `docs/design/90-bayesTLS-critique.md` for the cited
file:line references.

## The 4PL thermal death-time curve

Let `logd = log10(duration)`. Survival probability is the descending
four-parameter logistic

```
p = low + (up - low) / (1 + exp(k * (logd - mid))),   k = exp(logk).
```

`low` is the lower asymptote (survival at long exposures), `up` is the upper
asymptote (survival at short exposures), `k > 0` is the steepness, and `mid` is
the midpoint on the `log10(duration)` scale. Survival is high at short durations
and falls toward `low` at long durations.

## bayesTLS constant-shape midpoint

In the bayesTLS constant-shape configuration (`temp_effects = "mid"`), the
midpoint is linear in temperature:

```
mid(T) = b_mid_Intercept + b_mid_temp_c * (T - Tbar),
```

with `Tbar` the centring temperature. bayesTLS then reads the thermal sensitivity
and the critical thermal maximum off this line (bayesTLS `fit_4pl.R:88-94`,
`extract_tdt.R:89-90,144-146`):

```
z = -1 / b_mid_temp_c,
CTmax(tref) = Tbar + (log10(tref) - b_mid_Intercept) / b_mid_temp_c.
```

## freqTLS direct reparameterisation

freqTLS makes `CTmax` and `log_z` the coordinates. With `z_i = exp(eta_logz_i)`
and `CT_i = X_CT_i . beta_CT`,

```
mid_i = log10(tref) - (T_i - CT_i) / z_i.
```

So the temperature enters the midpoint directly through `CTmax` and `z`. The
shape parameters `low`, `up`, `k` are shared across observations by default;
the formula interface may instead give them supported fixed designs, with the
intercept-only default unchanged (see `docs/dev-log/decisions.md`, 2026-06-17).

## Equivalence (same likelihood, same MLE)

Expanding the freqTLS midpoint as a linear function of `T`:

```
mid_i = [log10(tref) + (CT_i - Tbar) / z_i] + [-1 / z_i] * (T_i - Tbar),
```

so the bayesTLS coefficients are

```
beta1 = -1 / z,   beta0 = log10(tref) + (CT - Tbar) / z,
```

and inverting,

```
z = -1 / beta1,   CT = Tbar + (log10(tref) - beta0) / beta1,
```

which is exactly the bayesTLS map. The reparameterisation shares `(low, up, k)`
and is smooth and invertible (the Jacobian is nonsingular while `z` is finite),
so the freqTLS and bayesTLS constant-shape models have the **same likelihood,
the same fitted curve, and the same maximum-likelihood estimate**. The only
difference is that `CTmax` and `z` are coordinates in freqTLS, hence directly
profile-able. Because profile likelihood is equivariant under a monotone
reparameterisation, the `z` profile equals `exp()` of the `log_z` profile, and
the `z` interval equals `exp()` of the `log_z` interval.

## Disjoint-bounds asymptotes

freqTLS parameterises the asymptotes with the bayesTLS `compute_4pl_bounds()`
recipe: the feasible band `[lower, upper]` (default `[0, 1]`) is split at its
midpoint, and `low` and `up` each map an unconstrained coefficient onto one half,
so `up > low` is guaranteed without a hard constraint:

```
low = low_min + low_w * plogis(beta_low)   # lower half-band
up  = up_min  + up_w  * plogis(beta_up)    # upper half-band
```

`low` is confined below the midpoint and `up` above it (the bands meet, with a
tiny separating gap, at the midpoint), so any `(beta_low, beta_up)` gives a valid
ordered pair `lower < low < up < upper`. This adopts the bayesTLS disjoint-bounds
choice (`low < midpoint < up`), so the two packages share the asymptote contract
exactly. (Earlier freqTLS builds used a nested gap
`up = low + (1 - low) * plogis(beta_gap)`; P1 switched to disjoint bounds — see
`docs/dev-log/decisions.md`.) Under disjoint bounds `up` has its own coordinate
`beta_up`; freqTLS nonetheless uses the Wald/delta interval for `up` because its
profile path is not yet wired for `beta_up`. See
`docs/design/04-profile-likelihood.md`.

## Internal coordinates and links

| Natural parameter | Internal coordinate | Link |
| --- | --- | --- |
| `low` | `beta_low` | logit (`plogis`), onto the lower half-band |
| `up` | `beta_up` | logit (`plogis`), onto the upper half-band |
| `k` | `beta_logk` | log |
| `CTmax` (per group) | `beta_CT[g]` | identity |
| `z` (per group) | `beta_logz[g]` | log |
| `phi` (beta-binomial) | `log_phi` | log |

Positive parameters (`k`, `z`, `phi`) use a log internal scale; `low` and `up`
each use a logit onto their half-band. This keeps the optimiser unconstrained and
the gradients finite.

## Groups

With a grouping factor, the design matrices are `model.matrix(~ 0 + group)` for
both `CTmax` and `log_z`, so each group `g` has its own direct `CTmax_g` and
`z_g` (both profile-able), with shared `low`, `up`, `k`. Contrasts `dCTmax` and
`dlog_z` are obtained by reference-plus-contrast recoding; the ratio of thermal
sensitivities is `z_ratio = exp(dlog_z)`.

## Time unit (R-UNITS)

The duration is in the data's native unit (typically hours), and `tref` is in the
same unit, so `CTmax` is the critical thermal maximum at `tref` (e.g. CTmax at
1 hour). When calling bayesTLS for the benchmark, pin the matching
`t_ref`/`time_multiplier` so the two implementations agree on the unit. The unit
and `tref` are surfaced in `print()`.
