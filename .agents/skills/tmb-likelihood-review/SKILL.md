---
name: tmb-likelihood-review
description: Review the freqTLS TMB 4PL likelihood and parameterisation before merging.
---

# TMB Likelihood Review

Use this skill for any change to `src/profile_tls.cpp`, the numeric header, the
density code, or the parameter transforms. Gauss leads; Noether checks the
math-to-code match.

## Review Checklist

- Are all constrained parameters represented internally on unconstrained scales:
  `k`, `phi`, `z` on log; `low` on logit; the asymptote gap on the nested-gap
  transform `up = low + (1 - low) * invlogit(beta_gap)` so `up > low` is
  guaranteed?
- Is the midpoint map exactly `mid = log10(tref) - (temp - CTmax) / z`, and the
  fitted survival `p = low + (up - low) * invlogit(-k * (log10(duration) - mid))`
  (descending: high survival at short durations)?
- Is the probability clamp branch-free (`CppAD::CondExpLt` / `CondExpGt` to
  `[eps, 1 - eps]`), not an `if` on a `Type`?
- Are `y` and `n` `DATA_VECTOR` (Type), not IVECTOR, so the beta-binomial
  `lgamma(y + a)` works with `a` a `Type`? Is there a shape floor on `a`, `b`?
- Is the beta-binomial `phi` convention the sum of the Beta shapes
  (`a = p * phi`, `b = (1 - p) * phi`), matching `simulate_tls()` (R-PHI)?
- Are gradients finite for simulated data, and does `sdreport()` report
  interpretable transformed parameters (`low`, `up`, `k`, `phi`, `beta_CT`,
  `z_group`)?
- Does simulation recover truth under ordinary sample sizes for both families?
- Are boundary and weak-identification cases tested (asymptote on the boundary,
  `phi` toward the binomial limit, threshold never crossed)?
- Is the equivalence to the bayesTLS constant-shape parameterisation preserved
  (`z = -1 / beta1`, `CTmax = Tbar + (log10(tref) - beta0) / beta1`)?

## Provenance

Any pattern adapted from `drmTMB` (the Boolean.h pre-include guard, the
beta-binomial `lgamma` form, the CondExp clamp, the stable `log1p_exp` switch)
must be recorded in `inst/COPYRIGHTS` before the change is treated as complete.
