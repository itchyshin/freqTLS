# Handoff — freqTLS autonomous build session (2026-06-24)

**Branch:** `build/freqtls`  ·  **State:** clean, all green  ·  **HEAD:** `6dce092`

> **Session-2 final (HEAD `6dce092`):** the twin is now **feature-complete for the
> fit → extract → predict → compare → plot workflow**. Added since the P4c–P4e
> note below:
> - `431e155` **P4f** `two_stage` classical comparator (`ts_stage1/2/ci/curve`;
>   normal + small-sample t intervals; MASS added to Imports).
> - `dcceac7` **P4g** plots (incl. the Confidence Eye) + extractors accept the
>   `freq_tls` workflow object (not just the bare `profile_tls` fit).
> - `6dce092` **docs** capability sync (NEWS rewritten to the twin API;
>   capability-matrix + known-limitations twin-redesign banners).
>
> Verification: `devtools::test()` **680 PASS / 1 skip**; `R CMD check` 0/0/0.
> **Remaining tranche (validation + docs):** P5 profile-t calibration simulation
> (coverage + width; the §9 ADEMP); P6 three-way benchmark rebuild (freqTLS vs
> bayesTLS vs two_stage on the shared datasets — needs Stan) + `--as-cran` +
> CITATION refresh + lean CI; P7 case-study vignettes mirroring
> `ms/case_studies_new.qmd` + pkgdown site; deprecate profileTLS; NotebookLM
> corpus. Optional secondary twin functions: `make_temperature_scenarios`/
> `planted_dose_from_trace`, `repair_rate_schoolfield` (reconcile with
> `heat_injury.R`), `derive_tdt_landscape`/`plot_tdt_landscape`, `theme_tdt`,
> `summarise_observed_survival`/`get_surv_draws`/`get_hi_draws`, non-default
> `bounds` wiring.

> **Session-2 update:** P4c–P4e landed — the full **fit → extract → predict** twin
> surface is now built and committed:
> - `6001989` **P4c** `extract_tdt()` (nested `$z`/`$CTmax`/`$T_crit`, draws +
>   summary, bootstrap) + `get_z_summary`/`get_z_draws`/`get_ctmax_*`/`get_tcrit_*`.
> - `4b80c04` **P4d** `tls()` does relative **and** absolute/LTx + `lethal`
>   (T_crit) via `extract_tdt`; added `tls_tcrit`.
> - `17a233c` **P4e** `predict_survival_curves()` — survival surface + bootstrap
>   bands; forward 4PL validated == engine `predict` to 1e-16.
>
> Twin API now exported: `standardize_data`, `fit_4pl`, `make_4pl_formula`,
> `tls`/`tls_z`/`tls_ctmax`/`tls_tcrit`, `extract_tdt` + `get_*` accessors,
> `predict_survival_curves`, `diagnose_tdt_fit`, `tdt_parameter_table`.
> Verification: `devtools::test()` **663 PASS / 1 skip**; `R CMD check` 0/0/0.
>
> **Next:** plotting twins (`plot_survival_curves` over `predict_survival_curves`;
> reconcile `plot_tdt_curve`/`plot_heat_injury` with freqTLS's existing plots;
> `theme_tdt`), `summarise_observed_survival`/`get_surv_draws`; then
> `two_stage`/`repair`/`temperature_scenarios`, P5 calibration sim, P6 benchmark
> rebuild + `--as-cran` + CITATION, P7 vignettes (mirror `ms/case_studies_new.qmd`)
> + pkgdown, deprecate profileTLS, NotebookLM corpus.
> The "Exact next steps" below (for `extract_tdt`) are now **done** — kept for the
> design record.

## What this session built (the freqTLS = frequentist-twin-of-bayesTLS build)

Six committed, gated phases. The twin's core workflow now runs end-to-end:
`standardize_data() -> fit_4pl() -> tls() / diagnose_tdt_fit() / tdt_parameter_table()`.

| Commit | Phase | Summary |
|---|---|---|
| `492084c` | P0 | Rename profileTLS→freqTLS, byte-identical (573 tests, check 0/0/0). |
| `3a29ac1` | P1 | TMB asymptotes nested-gap → **disjoint bounds** (`compute_4pl_bounds`); `up` a direct coordinate. |
| `78eceec` | P2 core | bayesTLS's **7 datasets** (Li=`aphid_tdt`, Saruhashi=`zebrafish_o2`) + `standardize_data` + `tdt-utils`. |
| `e458ea1` | P3a | **`fit_4pl`** facade + `make_4pl_formula` (TMB) + `freq_tls` object; direct-mode `ctmax`/`z`/`up`/`low`/`k`/`by`. |
| `43522d6` | P4a | **`tls`** / `tls_z` / `tls_ctmax` — headline z + CTmax with CIs (relative, grouped). |
| `9fd85f8` | P4b | `diagnose_tdt_fit` + `tdt_parameter_table`. |

**Verification (current):** `devtools::test()` → **632 PASS / 0 fail / 0 warn / 1 skip**;
`rcmdcheck(build_args="--no-build-vignettes")` → **0 / 0 / 0**. The 1 skip is
`test-benchmark-sanity` (stale cache, rebuilt in P6). Vignettes are
`--ignore-vignettes` (stale — old data/API; rewritten in P7).

## Key decisions made this session (record in DECISIONS)

1. **Full twin** (user): adopt bayesTLS function names as the primary API
   (`fit_4pl`/`make_4pl_formula`/`standardize_data`/`tls`/`extract_tdt`/`get_*`).
   profileTLS's own names (`fit_tls`/`tls_bf`/`get_ctmax`/`tidy_parameters`) remain
   as the internal engine + are still exported for now (deprecate later).
2. **Disjoint bounds** (user): match bayesTLS bit-for-bit on the asymptotes.
3. **Constant-shape default** (freqTLS invariant): `fit_4pl` defaults `up`/`low`/`k`
   to `~ 1`; temperature effect runs through CTmax/z. Differs from bayesTLS's
   temp_c-crossed shapes (documented; CTmax/z still match).
4. **Threshold at extraction, not fit-time** (revised from D2): keep the fit
   relative; convert to absolute via `derive_ctmax`/bootstrap in the quantity
   layer — matches bayesTLS's `extract_tdt(target_surv=)` workflow and avoids the
   C++ mid-shift sign trap.
5. **Bootstrap = the `.draw` analogue** (P4 scout): `tls_bootstrap_replicates()`
   already returns an `nboot × parameter` natural-scale matrix — the engine for
   `extract_tdt`'s `$draws` and for T_crit / absolute CIs.

## Exact next steps (priority order)

**P4 remaining — `extract_tdt()` + accessors (the next focused piece):**
- Build `extract_tdt(object, target_surv, t_ref, lethal, TC_rate_range, nboot, by)`
  on **`tls_bootstrap_replicates(fit, nboot)`** (`R/bootstrap.R:45`; `$replicates`
  is nboot×param, columns = `fit$estimates$parameter`, natural scale).
  - `$z`/`$CTmax` draws = the `z`/`CTmax` (or `z:lvl`/`CTmax:lvl`) columns.
  - `$T_crit` draws = `CTmax_1h + z·log10(rate/100)`, rate ~ log-uniform over
    `TC_rate_range`, **anchored at 1 h, not `t_ref`** (scout §9.7). `CTmax_1h` via
    `derive_ctmax(fit, duration = <1 h in data units>)` — mind the duration unit
    (`meta$duration_unit`; 1 h = 60 if minutes).
  - absolute CTmax draws = `derive_ctmax(fit, surv = p, ...)` per replicate, or the
    closed form `CTmax - z·qlogis((p-low)/(up-low))/k` using each replicate's
    `low`/`up`/`k` columns.
  - `$summary` = median + 2.5/97.5 percentiles. **Match the column-name asymmetry
    exactly** (scout §2.1): `z_median/z_lower/z_upper` for z; `temp_*` for CTmax/
    T_crit; the per-draw CTmax column is literally named `temp`.
- Then the accessors (`R/accessors.R` twin): `get_z_summary`/`get_z_draws`/
  `get_ctmax_*`/`get_tcrit_*` (renames `temp`→`CTmax`/`T_crit`).
- Add `lethal=` (T_crit) and `target_surv=` (absolute) to `tls()` under
  `method="bootstrap"` (consistent draws).

**P2 remaining (engine-agnostic copies):** `two_stage` (`ts_*`; add **dplyr** +
already-Suggested glmmTMB), `repair_rate_schoolfield` (reconcile vs freqTLS's
existing `R/heat_injury.R`), `make_temperature_scenarios`/`planted_dose_from_trace`,
`plot_*`/`theme_tdt`.

**P5 calibration** (profile-t, §9 sim), **P6** benchmark rebuild + `--as-cran` +
`inst/CITATION` refresh, **P7** vignettes mirroring `ms/case_studies_new.qmd` +
pkgdown, **deprecate profileTLS**, **NotebookLM** corpus.

## Gotchas / residuals discovered

- **zebrafish_o2 weak design**: per-group CTmax+z gives `pdHess=FALSE` (honestly
  reported). The case study likely needs beta-binomial and/or pooled shape.
- **Time-unit policy**: freqTLS `tref`/`t_ref` is in the data's `duration_unit`
  (stored in `freq_tls$meta`); bayesTLS's `t_ref`(min)+`time_multiplier` maps to
  this. `extract_tdt`'s T_crit (1 h anchor) must convert.
- **bounds fixed to c(0,1)**: `fit_4pl` errors on non-default `bounds`/`threshold`
  (clear messages). Wiring `bounds` needs the contrast-refit in `R/profile.R` to
  read the fit's bounds (it currently hard-codes `compute_4pl_bounds(0,1)`).
- **Vignettes + benchmark-sanity** reference old data column names — quarantined
  (`--ignore-vignettes`, `skip`) until P6/P7.
- bayesTLS clone at `../bayesTLS` (`422acec`) is the API reference; cloned this
  session.

## Resume command

```sh
cd "/Users/z3437171/Dropbox/Github Local/freqTLS"
git status --short --branch    # expect clean on build/freqtls @ 9fd85f8
git -C ../bayesTLS log --oneline -1   # API reference (422acec)
# then: implement extract_tdt() per "Exact next steps" above.
```
