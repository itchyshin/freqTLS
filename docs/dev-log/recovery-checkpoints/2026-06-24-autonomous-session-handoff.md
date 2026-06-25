# Handoff — freqTLS autonomous build session (2026-06-24)

**Branch:** `build/freqtls`  ·  **State:** clean, all green  ·  **HEAD:** `9fafffc`

> **Session-4 (HEAD `73e7576`): P7 vignettes — 8/12 render; the freq-vs-bayes
> story is complete.** Ran a full vignette render-sweep (the real gate: does each
> `.Rmd` knit against the installed package?). 5 were already green (freqTLS,
> model-math, profile-likelihood, random-effects, and — after this session —
> frequentist-and-bayesian). Fixed 3 more to the twin API + current data:
> - `4046e90` **frequentist-and-bayesian** (the centerpiece) now carries its
>   scientific backbone — the P5 small-sample **coverage panel** (asymptotic z
>   0.927 → profile-t 0.964 at df≈10; t≡z at df≈100) and the P6 **three-way
>   benchmark** (CTmax within 0.07 °C of bayesTLS), both read from cache so it
>   builds Stan-free. + Bates–Watts (1988).
> - `bcc503d` **case-study-shrimp**, `08ed608` **comparing-to-bayesTLS**,
>   `73e7576` **heat-injury**: every live fit rewired
>   `standardize_data() → fit_4pl() → tls()`; grouped via `by=`; the v0.2
>   stage-shape fit varies `low/up/k ~ g` (AIC 1222.5 → 1187.9).
> - `ef8991e` **confint() + summary() methods for `freq_tls`** (delegate to
>   `$fit`) — a real twin bug fixed: `confint(fit)`/`summary(fit)` on a
>   `fit_4pl()` result previously hit the `stats::confint.default` NA matrix /
>   a generic list. Then `9fafffc` the **getting-started vignette** now leads
>   with the twin API (`standardize_data → fit_4pl`); its downstream chunks
>   (summary/confint/tidy/get_*/plots) work unchanged on the `freq_tls` thanks
>   to the new methods. Full suite **694 PASS / 1 skip**.
>
> **The freq_tls-vs-`$fit` rule (learned this session, use it for the rest):**
> `tls`, `get_ctmax`, `get_z`, `tidy_parameters`, `derive_ctmax`, `derive_tcrit`,
> `plot_*`, `predict_survival_curves`, and `AIC`/`logLik`/`coef` **accept the
> `freq_tls` workflow**. `confint`, `predict_heat_injury`, `plot_heat_injury`,
> and `$estimates`/`$convergence` need the **engine fit** (`fit$fit`). Two warts
> flagged as background tasks (chips): (1) `predict_heat_injury`/`plot_heat_injury`
> should accept `freq_tls`; (2) `fit_4pl(by="g")` labels params
> `CTmax:life_stage<lvl>` where the column interface gives the clean
> `CTmax:<lvl>` (fix at `formula.R:600` / `group_levels`; threads through
> predict/contrasts).
>
> **4 vignettes still fail — and it is NOT purely mechanical.** The bundled data
> was swapped to **bayesTLS's 7 datasets**, so some case-study prose NUMBERS have
> drifted from the old data. Confirmed: **leaf-psii** snow-gum now gives CTmax
> **48.6** / z **3.71**, but the prose hardcodes the old **46.5** / **6.5** in 6
> places and claims a bayesTLS comparison the cache can't back. So the remaining
> 4 need **number verification against `ms/case_studies_new.qmd`**, not just API
> rewiring — a call for the user / Darwin, since it changes stated scientific
> values. Verified data maps for each (so no re-deriving):
> - **case-study-leaf-psii** (snowgum, beta):
>   `standardize_data(snowgum_psii, temp="Temp", duration="Time", proportion="fvfm_prop")`
>   → `fit_4pl(family="beta", t_ref=5)`. Fix API (`confint(fit$fit, ...)`,
>   `fit$fit$convergence`) + the 6 hardcoded numbers + the 45.9/46.5 comparison
>   prose. (Two snowgum CSVs exist — field vs glasshouse — confirm which
>   `snowgum_psii` is.)
> - **case-study-zebrafish** (by life_stage): blocked on the `by=` label wart for
>   clean Confidence-Eye `parm` labels (the eye chunks hardcode
>   `CTmax:young_embryos`). Tables are fine via `tls()$summary`. Map:
>   `standardize_data(zebrafish_lethal, temp="assay_temp", duration="duration_h", n_total="n_total", n_surv="n_surv", duration_unit="hours")`
>   → `fit_4pl(by="life_stage", family="beta_binomial", t_ref=1)`.
> - **case-study-suzukii**: dataset renamed `dsuzukii_lethal`→**`dsuzukii`** and
>   **reshaped** — old `survived/total/time/temp/sex`; new cols
>   `id, temp, lvl, time, sex, rep, prod, dead, t_coma`. Mapping is NOT obvious
>   (semantics of `prod`/`dead`/`lvl`?) — read `?dsuzukii` + the data-raw build
>   script before fitting. Absolute-threshold exemplar (`t_ref=240` min).
> - **case-study-summary**: combines all four fits + a 7-row cross-taxon panel;
>   do last, after the three above are settled.
>
> Verification: each fixed vignette knits to HTML with the expected evidence
> grepped from the output. No R code changed → the test suite is untouched
> (still 691 PASS / 1 skip). Render outputs in `/tmp/vig-render/`.

> **Reference cross-check — bayesTLS `ms/case_studies_new.qmd` (read this
> session).** The bayesTLS *new* case studies are NOT the same analyses as
> freqTLS's old vignettes — porting them faithfully is real work, not a rename,
> and exposes a likely freqTLS capability gap (multi-RE). Exact recipes:
> - **leaf PSII**: bayesTLS uses `proportion="fvfm_prop"`,
>   `duration_unit="minutes"`, `t_ref=60` (NOT the old vignette's `tref=5`),
>   **`random_effects=c("Day","G_Room")`**, `brms::Beta(link="identity")`, and
>   reports **z≈5.1**. freqTLS with no REs (`t_ref=5`) gives **z=3.71** — the gap
>   is mostly the **missing random effects** (and possibly a data-version
>   difference: the bundled `snowgum_psii` has `plant`/`meas_day`; bayesTLS's has
>   `Day`/`G_Room`). freqTLS supports only ONE random intercept per sub-parameter,
>   so two REs (Day+G_Room) may not port directly — a design decision. **Do not
>   trust leaf-PSII numbers until the RE structure + data provenance are matched.**
> - **zebrafish**: the OLD freqTLS vignette is life-stages (`zebrafish_lethal`);
>   bayesTLS's NEW one is OXYGEN (`zebrafish_o2`,
>   `fit_4pl(ctmax=~0+oxygen, z=~0+oxygen, t_ref=60)`, `duration="duration_min"`,
>   `duration_unit="minutes"`). Decide: keep the life-stage study or replace with
>   the oxygen one (the plan's P7 lists `case-study-zebrafish-oxygen` as a CREATE).
> - **suzukii**: bayesTLS aggregates the per-individual `dsuzukii` first —
>   `dsuzukii |> group_by(temp, time, sex) |> summarise(n_total=n(), n_dead=sum(dead))`,
>   then `standardize_data(mort, temp="temp", duration="time", n_total="n_total",
>   n_dead="n_dead", duration_unit="minutes")`, then
>   `fit_4pl(mid = ~ sex * temp_c, t_ref = 60*4)`. (`standardize_data` supports
>   `n_dead=`.) Absolute-threshold / `T_crit` exemplar.
> - **aphids** (a P7 CREATE): `aphid_tdt |> filter(branch=="heat", age=="6")`,
>   `standardize_data(temp="temp", duration="duration_min", n_total="n_total",
>   n_surv="n_surv", duration_unit="minutes")`, `fit_4pl(t_ref=60)`, by species.
> Net: the 4 remaining case studies need **scientific direction** (which
> zebrafish; REs for leaf; the suzukii aggregation), so they are paused for the
> user with the exact recipes above — not rewritten blind.

> **Session-3 (HEAD `fc9bb01`): the twin is now scientifically validated.**
> - `499da87` **P5a** Bates–Watts **profile-t / Wald-t calibration** (`tls_ci_df`
>   = n−p; qnorm→qt, qchisq→qt²; df-aware grid). Equivariance preserved.
> - `bdec351` **P5b** **coverage evidence**: at df≈10 the asymptotic z under-covers
>   (0.927) and the t-correction restores it (0.964); t≡z at df≈100
>   (`data-raw/calibration-study.R`, cached).
> - `4b58775` **P6 (start)** three-way **benchmark**: freqTLS reproduces bayesTLS's
>   CTmax to **0.07 °C** on shrimp; freqTLS's prior-free z tracks the classical
>   two-stage (bayes higher = prior). Installed the redesigned bayesTLS clone.
> - `fc9bb01` **P7 (start)** twin **README** (standardize_data→fit_4pl→tls; data
>   credits → 7 datasets) + `freq_tls` S3 methods (coef/logLik/vcov/nobs).
>
> Verification: `devtools::test()` **691 PASS / 1 skip**; `R CMD check` 0/0/0.
> **Genuinely remaining (presentation + release):** P7 case-study **vignettes**
> (rewrite the stale .Rmd to the twin, mirroring `ms/case_studies_new.qmd` —
> aphid/Li, zebrafish-O₂/Saruhashi, the frequentist-vs-Bayesian centerpiece using
> the P5/P6 evidence) + **pkgdown** build; expand the **benchmark grid** (grouped
> datasets, 4×4000 MCMC) + re-enable `test-benchmark-sanity`; **deprecate
> profileTLS** (lifecycle/superseded); **NotebookLM** corpus; optional secondary
> twins (temperature scenarios, repair, landscape, more accessors); `--as-cran` +
> CITATION refresh. The earlier session-2 notes below are superseded by this.

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
