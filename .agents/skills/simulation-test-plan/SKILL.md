---
name: simulation-test-plan
description: Design a compact parameter-recovery simulation plan for the freqTLS 4PL thermal-load-sensitivity model.
---

# Simulation Test Plan

Use this skill when planning the simulation evidence for a freqTLS slice
(recovery, coverage, edge behaviour, or benchmark sanity). Curie leads; Fisher
reviews the inferential targets.

## Procedure

1. State the estimand or invariant: recovery of `CTmax`, `z`, `low`, `up`, `k`,
   `phi`; profile equivariance `ci_z == exp(ci_log_z)`; `|D(MLE)| ~ 0`; or a
   warning on a weakly identified design.
2. Construct data from known settings with `simulate_tls()` (locked
   data-generating process, fixed seed, factorial temperature x duration grid).
3. Fit with the public `fit_tls()` workflow and form intervals with
   `confint(method = "profile")`.
4. Check estimates and intervals on the scale the user interprets (degrees for
   `CTmax`, degrees-per-decade for `z`, probabilities for `low`/`up`).
5. Add at least one scientifically likely edge case (sparse design, no/all
   mortality, threshold never crossed, `phi` near the binomial limit).
6. Keep routine tests deterministic and small; put long studies in `data-raw/`.

## freqTLS Targets

- Recovery tolerances (guide, from the SPEC): `CTmax` to about 0.4 deg C, `z`
  to about 0.6, `low`/`up` to about 0.05, `k` to about 30% relative; wider for
  beta-binomial.
- `logLik(beta_binomial) > logLik(binomial)` and `AIC(beta_binomial) <
  AIC(binomial)` on overdispersed data; near-binomial on clean data.
- Benchmark sanity: cached bayesTLS vs live freqTLS within a loose tolerance
  (`CTmax` ~ 1 deg C, `z` ~ 25%); no Stan in the test.

## Edge Cases

Too few temperatures or durations; no mortality; all mortality; threshold never
crossed; asymptote not approached; CTmax extrapolated; non-closing profile
(warning + `NA` endpoint, no crash); grouped designs with shared shape.
