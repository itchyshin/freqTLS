# Likelihoods

This document records the symbolic likelihoods and the TMB C++ implementation
notes for freqTLS. Any change to the likelihood parameterisation (the NLL, the
`phi` convention, the probability clamp) must update this file in the same commit
(AGENTS.md design rule 4). The load-bearing engine is `src/profile_tls.cpp` with
stable numeric helpers in `src/profile_tls_numeric.h`.

## Fitted survival probability

For observation `i` with temperature `T_i`, log10 duration `logd_i`, group design
rows `X_CT_i`, `X_logz_i`:

```
z_i  = exp(X_logz_i . beta_logz),
CT_i = X_CT_i . beta_CT,
mid_i = log10(tref) - (T_i - CT_i) / z_i,
eta_i = k * (logd_i - mid_i),
p_i  = low + (up - low) * invlogit(-eta_i),
```

with `low = invlogit(beta_low)`, `up = low + (1 - low) * invlogit(beta_gap)`,
`k = exp(beta_logk)`. The probability is clamped to `[eps, 1 - eps]`
(`eps = 1e-12`) with a branch-free `CppAD::CondExp`, so the optimiser never sees a
hard 0 or 1 and the gradient stays finite.

## Binomial NLL (family_code 0)

```
nll -= dbinom(y_i, n_i, p_i, log = TRUE).
```

## Beta-binomial NLL (family_code 1)

With `phi = exp(log_phi)`, `a = p_i * phi`, `b = (1 - p_i) * phi`, and
`yf = n_i - y_i`, the log density in `lgamma` form is

```
log f = lgamma(n+1) - lgamma(y+1) - lgamma(yf+1)
      + lgamma(phi) - lgamma(n+phi)
      + lgamma(y+a) - lgamma(a)
      + lgamma(yf+b) - lgamma(b),
nll -= log f.
```

`a` and `b` get a small shape floor (`1e-8`) so `lgamma` stays well behaved. This
form follows the drmTMB beta-binomial density pattern
(`drmTMB::src/drmTMB.cpp:1319-1328`); the CondExp clamp and shape floor follow
`drmTMB::src/drmTMB.cpp:1302-1314`. Provenance is recorded in `inst/COPYRIGHTS`.

`y` and `n` are `DATA_VECTOR` (Type), not IVECTOR, because the beta-binomial needs
`lgamma(y + a)` with `a` a `Type`.

## REPORT and ADREPORT

The engine reports the natural-scale parameters for `print`/`summary` (`REPORT`)
and for `sdreport` standard errors (`ADREPORT`):

```
REPORT(low); REPORT(up); REPORT(k); REPORT(phi);
REPORT(beta_CT); REPORT(z_group); REPORT(p_fitted);
ADREPORT(low); ADREPORT(up); ADREPORT(k);
ADREPORT(beta_CT); ADREPORT(beta_logz); ADREPORT(z_group);
if (family_code == 1) ADREPORT(phi);
```

`z_group = exp(beta_logz)` is the per-group thermal sensitivity on the natural
scale.

## Numerical stability

- Positive parameters (`k`, `phi`, `z`) are on log internal scales; `low` on
  logit; the asymptote gap on the nested-gap transform.
- `invlogit(-eta)` is used directly for the descending curve.
- The probability clamp uses nested `CppAD::CondExpLt`/`CondExpGt`, never an `if`
  on a `Type`.
- The header `src/profile_tls_numeric.h` provides a branch-free `invlogit` and a
  stable `log1p_exp` (the series-vs-direct CondExp switch follows
  `drmTMB::src/drm_numeric.h`). Headers use a `#ifndef` guard.
- `src/init.c` registers the DLL; both `init.c` and `profile_tls.cpp` include the
  drmTMB Boolean.h pre-include guard so the package compiles cleanly under R 4.5's
  Apple clang.

## map fixes

For the binomial family, `log_phi` is mapped out (`map = list(log_phi =
factor(NA))`) so it is not estimated. Starting values (from the SPEC):
`beta_low = qlogis(0.02)`, `beta_gap = qlogis(0.95)`, `beta_logk = log(5)`,
`beta_CT = median(temp)` (per group), `beta_logz = log(3)`, `log_phi = log(100)`.
