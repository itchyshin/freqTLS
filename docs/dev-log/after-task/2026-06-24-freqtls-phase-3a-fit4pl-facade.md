# After Task: freqTLS Phase 3a — fit_4pl facade + freq_tls object

**Date:** 2026-06-24
**Owner(s):** Emmy (API), Boole (formula), Ada
**Phase:** P3a (the bayesTLS-twin fitting facade; relative threshold, bounds c(0,1))

## Goal

Give freqTLS the bayesTLS-twin fitter: `fit_4pl(standardize_data(...), ctmax=, z=,
up=, low=, k=, by=, threshold=, t_ref=, bounds=, family=)` over the TMB engine,
returning a `freq_tls` workflow object the quantity twins (P4) will read. A
bayesTLS script's fit call should run on freqTLS unchanged.

## Implemented (`R/fit_4pl.R`)

- **`make_4pl_formula()`** — translates the direct-mode args into the engine's
  `tls_formula` (built programmatically, since `tls_bf` uses NSE): `ctmax`→`CTmax`,
  `z`→`log_z`, `up`/`low`/`k`→`up`/`low`/`log_k`; `by` is shorthand for
  `~ 0 + by` on CTmax/z; count → `n_surv | trials(n_total)` response, beta → bare
  `survival`. **Constant-shape invariant:** shapes default to `~ 1` (temperature
  effect runs through the midpoint), overridable per shape.
- **`fit_4pl()`** — validates `standardize_data` output, resolves family from
  `response_type`, builds the formula, fits via `fit_tls`, wraps in a `freq_tls`
  object: `$fit`, `$data`, `$formula`, `$meta` (threshold, p, t_ref, bounds,
  temp_mean, duration_unit, response_type, family, grouped, moderators, method).
- **`print.freq_tls`** — mirrors `print.bayes_tls` (data dims, T_bar, family +
  threshold + t_ref, grouping, convergence + default CI method).

## Checks run and outcomes

- Smoke (twin API end-to-end): shrimp (ungrouped, `t_ref=1`) CTmax 31.8 / z 2.2;
  aphid heat/age-6 by species (conv 0, 3 CTmax rows); zebrafish-O₂ hypoxia vs
  normoxia by oxygen — fits and **honestly reports `pdHess = FALSE`** (the weak
  4-temperature design is poorly identified with per-group CTmax+z; a real
  identifiability signal, surfaced not hidden).
- `devtools::test()` → **611 PASS / 0 fail / 0 warn / 1 skip** (+25 `test-fit-4pl`).
- `rcmdcheck` → **0 / 0 / 0**.

## Decisions

- **Constant shapes by default** (freqTLS invariant; ML-robust): differs from
  bayesTLS's `resolve_shape` which crosses shapes with `temp_c`. CTmax/z (the
  headline) still match; documented divergence. Explicit shape formulas allowed.
- **Object model:** `freq_tls = list(fit, data, formula, meta)` mirroring
  `bayes_tls`, so the P4 quantity twins read `$fit` + `$meta` the same way
  bayesTLS reads `$fit` (brmsfit) + `$meta`.

## Known residuals (→ later)

- **`threshold = "absolute"` and non-default `bounds` error for now** (clear
  messages) — wired into the C++ backbone in P3b.
- **Time-unit policy** (P4 scout flagged): freqTLS `t_ref` is in the data's
  `duration_unit` (stored in meta); bayesTLS's `t_ref`(min)+`time_multiplier`
  triad maps to this. Decide the `tls()`/`extract_tdt()` arg surface in P4.
- zebrafish-O₂ per-group identifiability: the case study (P7) likely needs
  beta-binomial and/or a pooled shape; the non-PD-Hessian warning already guides.

## Next

P3b — C++ fit-time `threshold` (relative/absolute via `derive_ctmax` expression)
+ wire the `bounds` argument; then P4 — the quantity twins (`tls`, `extract_tdt`,
`derive_*`, accessors, `predict_*`, `diagnose_tdt_fit`) against the scout's spec.
