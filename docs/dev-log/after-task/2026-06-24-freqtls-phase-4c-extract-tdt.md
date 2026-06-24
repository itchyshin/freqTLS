# After Task: freqTLS Phase 4c — extract_tdt() + accessors (bootstrap twin)

**Date:** 2026-06-24
**Owner(s):** Fisher, Emmy, Ada (spec from Jason's bayesTLS API scout)
**Phase:** P4c (the comprehensive extractor + accessor suite)

## Goal

The frequentist twin of `bayesTLS::extract_tdt()`: the nested `$z` / `$CTmax` /
`$T_crit` structure (each `draws` + `summary`), with the per-"draw" rows being
**parametric-bootstrap replicates** (the freq analogue of posterior draws), plus
the `get_*_summary` / `get_*_draws` accessors.

## Implemented (`R/extract_tdt.R`)

- **`extract_tdt(object, target_surv, lethal, TC_rate_range, nboot, level, seed, by)`**
  on `tls_bootstrap_replicates()`. Per replicate it reads z (threshold-invariant
  under the constant-shape model) and CTmax (relative = the fitted coordinate;
  absolute = `CTmax − z·qlogis((p−low)/(up−low))/k`), and — when `lethal` —
  derives `T_crit = CTmax + z·log10(rate/100)` with `rate` log-uniform over
  `TC_rate_range`. `*_median` is the MLE point; `*_lower`/`*_upper` are bootstrap
  percentiles. Grouped fits emit one row per group; ungrouped fits omit the group
  column. Column contract matches bayesTLS exactly (`z_median/z_lower/z_upper`;
  `temp_*` for CTmax/T_crit; per-draw value columns `z`/`temp`).
- **Accessors:** `get_z_summary`/`get_z_draws`/`get_ctmax_summary`/`get_ctmax_draws`
  (renames `temp`→`CTmax`)/`get_tcrit_summary`/`get_tcrit_draws` (renames
  `temp`→`T_crit`, errors if not `lethal`). `print.freq_tdt`.

## Checks run and outcomes

- Smoke (grouped, nboot=99): z A 2.88 [2.61,3.19] / B 5.02 [4.72,5.49] (truth 3/5);
  CTmax A 34.0 / B 37.9 (truth 34/38); T_crit below CTmax; absolute(0.5) == relative
  for the symmetric simulated curve (correct — the correction vanishes).
- `devtools::test()` → **650 PASS / 0 fail / 0 warn / 1 skip** (+18 `test-extract-tdt`).
- `rcmdcheck` → **0 / 0 / 0**.

## Issues found and fixed

- The engine labels an **ungrouped** fit's single level `"all"` (not `NA`), which
  leaked a spurious `group` column. Fixed in both `extract_tdt` and `tls`: a fit
  is grouped iff its quantity coefficients are level-tagged (`"CTmax:lvl"`), so
  ungrouped summaries omit the group column.

## Known residuals (→ later)

- **Bootstrap cost:** `extract_tdt` refits `nboot` times (default 1000) — slower
  than `tls()`'s profile/Wald path; documented. T_crit is anchored at the fit's
  `t_ref` (set `t_ref = 60` min ≈ 1 h to match bayesTLS's 1-h anchor).
- `predict_survival_curves` twin, `two_stage`/`repair`/`temperature_scenarios`
  copies, calibration (P5), benchmark + `--as-cran` (P6), vignettes (P7) remain.

## Next

`predict_survival_curves` twin (reshape `predict_survival_surface`), then the
engine-agnostic copies, then P5 calibration.
