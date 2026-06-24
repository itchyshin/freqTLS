# After Task: freqTLS Phase 2 (core) — twin datasets + standardize_data + utils

**Date:** 2026-06-24
**Owner(s):** Grace (data/CITATION), Emmy (integration), Darwin (datasets), Ada
**Phase:** P2 (engine-agnostic twin layer), core slice: data + `standardize_data` + utils

## Goal

Bring freqTLS's shipped data and the raw-data entry point into line with the
bayesTLS twin: replace profileTLS's 4 datasets with bayesTLS's **7** (so a
bayesTLS script's data references resolve unchanged), and copy the
engine-agnostic `standardize_data()` + utility helpers verbatim.

## Implemented

- **Datasets (7, raw):** copied `data/*.rda` from bayesTLS —
  `shrimp_lethal`, `shrimp_sublethal`, `zebrafish_lethal`, `snowgum_psii`,
  `dsuzukii` (renamed from `dsuzukii_lethal`), **`zebrafish_o2`** (Saruhashi),
  **`aphid_tdt`** (Li) — plus `inst/extdata/` raw CSVs and the aphid /
  kristineberg / orsted temperature traces. Copied + adapted `R/data.R`
  (`package = "freqTLS"`).
- **`standardize_data()`** copied verbatim (engine-agnostic): one entry point for
  raw count / proportion data → standard schema (`temp`, `duration`, `logd`,
  `temp_c`, `n_total`/`n_surv`/`n_dead`/`survival`) + `tdt_meta` attribute.
- **`R/tdt-utils.R`** = bayesTLS `utils.R` minus the Bayesian-only `tdt_is_grouped`
  draw-name path (reduced to read `meta$grouped`; full version returns in P4).
  Brings `compute_4pl_bounds`, `clock_to_minutes`, `tdt_quantile`,
  `format_interval`, `tdt_*` helpers. **Unified** the asymptote-bounds helper:
  removed P1's `tls_compute_bounds`, repointed the engine to `compute_4pl_bounds`.
- Removed the now-stale old data-build scripts (`make_benchmark_data.R`,
  `vendor_dsuzukii_lethal.R`).

## Checks run and outcomes

- Smoke: `standardize_data()` runs on all 7 (aphid heat → 1314 rows; zebrafish_o2
  → 905, oxygen hypoxia/normoxia/hyperoxia; shrimp via `mortality=`; snowgum via
  `proportion=` → `response_type="proportion"`).
- `devtools::test()` → **586 PASS / 0 fail / 0 warn / 1 skip** (new `test-data.R`,
  `test-standardize_data.R`; benchmark-sanity skipped — see residuals).
- `rcmdcheck(build_args="--no-build-vignettes", args="--ignore-vignettes ...")`
  → **0 errors / 0 warnings / 0 notes**.

## Issues found and fixed

- The data swap changed `zebrafish_lethal`/`shrimp_lethal` column names (now
  bayesTLS raw names). The `test-formula` zebrafish blocks referenced the old
  names → aliased the columns at the top of those (formula-mechanics) blocks.
- `rcmdcheck` first failed at the **build** step: `--no-build-vignettes` had been
  passed as a *check* arg, so it still tried to build the stale vignettes. Fixed
  by passing it via `build_args`.

## Known residuals (→ later phases)

- **benchmark-sanity skipped** — its cache + `profile_tls_points()` helper are
  built from old profileTLS-format data; rebuilt for the bayesTLS raw datasets in
  P6.
- **Case-study vignettes are stale** (old data column names + old API); rewritten
  in P7 (they are `--ignore-vignettes` for now).
- **P2 remaining (engine-agnostic):** `two_stage` (`ts_*`), `repair_rate_schoolfield`,
  `make_temperature_scenarios`, and `plot_*`/`theme_tdt` not yet copied (plotting
  waits for the `freq_tls` object / quantity outputs in P3–P4).
- `inst/CITATION` still the renamed-profileTLS version; refreshed with the data
  citations in P6/P7.

## Next

P3 — the `fit_4pl` facade + `make_4pl_formula` (TMB) consuming `standardize_data`
output, with `ctmax`/`z`/`up`/`low`/`k`/`by`/`threshold`/`bounds` and the
`freq_tls` object — so the new datasets become fittable through the twin API.
