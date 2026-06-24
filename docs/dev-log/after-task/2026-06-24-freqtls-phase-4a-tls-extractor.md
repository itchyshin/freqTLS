# After Task: freqTLS Phase 4a — tls() headline quantity extractor

**Date:** 2026-06-24
**Owner(s):** Emmy, Fisher, Ada (P4 spec from Jason's bayesTLS API scout)
**Phase:** P4a (the bayesTLS-twin `tls()` extractor — z + CTmax, relative threshold)

## Goal

Re-expose freqTLS's CTmax/z estimates + intervals under bayesTLS's `tls()`
contract, so `tls(fit)` returns the headline thermal-death-time quantities with
the same `$summary` shape (`[<group>,] quantity, median, lower, upper`) a
bayesTLS user expects.

## Implemented (`R/tls.R`)

- **`tls(object, by, params, target_surv, method, level)`** — reshapes the engine
  extractors into the twin contract. Reads a `freq_tls` (or bare `profile_tls`),
  pulls z/CTmax point estimates from `fit$estimates`, CIs from `confint()`
  (profile default; wald/bootstrap via `method`), groups by the moderator with
  **cleaned factor-level labels** (`speciesR_padi` → `R_padi`). `$summary` +
  `$meta`, class `tls`.
- **`tls_z()` / `tls_ctmax()`** — single-quantity wrappers.
- **`print.tls`** — mirrors `print.tls` in bayesTLS.

## Checks run and outcomes

- Smoke: shrimp (ungrouped) CTmax 31.8 [31.7, 31.9], z 2.19 [2.03, 2.37]
  (profile); aphid heat/age-6 by species — per-species CTmax (M_dirhodum 35.3 <
  S_avenae 36.6 < R_padi 37.2) and z, biologically ordered; labels cleaned.
- `devtools::test()` → **625 PASS / 0 fail / 0 warn / 1 skip** (+14 `test-tls`).
- `rcmdcheck` → **0 / 0 / 0** (added `@param ...` for the `tls_z`/`tls_ctmax`
  shared Rd).

## Known residuals (→ P4b)

- **Relative threshold only.** `target_surv = "absolute"/numeric` errors for now;
  the conversion (via `derive_ctmax`) + `extract_tdt()` come next.
- **No `$draws` / T_crit yet.** bayesTLS's `$draws` (per-draw) twin = bootstrap
  replicates; T_crit needs the rate construction. Both land in P4b with
  `extract_tdt()` + the `get_*_draws`/`get_*_summary` accessors.
- `diagnose_tdt_fit()` (convergence/pdHess/profile-health) + `tdt_parameter_table()`
  + `predict_survival_curves()` twins: P4b.

## Next

P4b — `extract_tdt()` (nested `$z`/`$CTmax`/`$T_crit`), the `get_*_summary`/
`get_*_draws` accessors (bootstrap = the `.draw` analogue), `diagnose_tdt_fit()`,
and the prediction twins; then the absolute-threshold conversion.
