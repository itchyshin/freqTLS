# bayesTLS supplement → freqTLS coverage map

**Date:** 2026-06-17
**Author:** Claude Code (research pass for the maintainer)
**Source studied in full:** `data-raw/.cache/bayesTLS_supplement.qmd` (6,861 lines; the
single-page bayesTLS supplement at <https://daniel1noble.github.io/bayesTLS>).
**Purpose:** A blueprint for freqTLS's case-study articles. It records, section
by section, exactly what the bayesTLS supplement demonstrates (datasets, function
calls with argument settings, tables/figures, numeric results), maps every
exported bayesTLS function to a freqTLS analogue or a documented non-goal, lays
out the freqTLS article plan (mirror **and** exceed bayesTLS), specifies the
D. suzukii lethal-by-sex vendoring, and lists explicit boundaries.

**Reader:** the freqTLS maintainer and the documentation/figure agents (Darwin,
Florence, Pat, Ada) who will build the articles. This is a planning document, not
runnable code.

**Status discipline:** "cached" means a maintainer-built Stan/bayesTLS benchmark
result already exists in `inst/extdata/bayesTLS_benchmark_cache.rds`; "NOT cached"
means `data-raw/build_benchmark_cache.R` must be re-run on a machine with cmdstanr +
CmdStan before that case study's three-way comparison can render. freqTLS itself
is always fit **live** (TMB, no Stan).

---

## Part 0 — Orientation: the bayesTLS pipeline and its data

The supplement frames bayesTLS as a five-step pipeline (Introduction, lines
202–210): **Standardise → Fit → Extract → Predict → Plot**. Every fit caches a
brms `.rds` under `models_dir` so re-rendering reloads rather than refits. The
default likelihood is `beta_binomial(link = "identity")` with a disjoint-bounds
("nested-gap") reparameterisation of the asymptotes:

```
low = 0.001 + inv_logit(lowraw) * 0.498
up  = 0.501 + inv_logit(upraw)  * 0.498
p(t,T) = low + (up - low) / (1 + exp(exp(logk) * (logd - mid)))
mid(T) = beta0 + beta1 * (T - Tbar)
```

freqTLS fits the **identical** forward map by ML/TMB, parameterised directly in
`CTmax` and `z` (with `z = -1/beta1`), and returns profile-likelihood compatibility
intervals instead of posteriors. The two packages therefore describe the same model;
freqTLS's job in these articles is to show the **same numbers from a different
inferential engine** plus extras bayesTLS does not provide (profile intervals, the
Confidence Eye, prior-free bootstrap, freq-vs-Bayes framing).

The four taxa and endpoints in the supplement:

| Taxon | Latin | Endpoint(s) | Grouping | freqTLS dataset |
|---|---|---|---|---|
| Brown shrimp | *Crangon crangon* | lethal mortality; **sublethal** time-to-knockdown | ungrouped | `shrimp_lethal` (lethal only) |
| Zebrafish | *Danio rerio* | lethal mortality | `life_stage` (young_embryos / old_embryos / larvae) | `zebrafish_lethal` |
| Snow gum leaf | *Eucalyptus pauciflora* | **sublethal** PSII retention (Fv/Fm) | ungrouped | `snowgum_psii` (beta family) |
| Vinegar fly | *Drosophila suzukii* | lethal mortality; **sublethal** heat-coma; **sublethal** productivity | `sex` (F / M) | none yet — to vendor lethal-by-sex |

---

## Part 1 — Section-by-section walkthrough of the supplement's 12 TOC sections

### Section 1 — Introduction / "What each function does" (lines 154–306)

**Demonstrates:** install/setup, the five-step pipeline logic, and two function-tour
tables.

- **`tbl-function-core`** — the seven everyday functions: `standardize_data()`,
  `fit_4pl()`, `extract_tdt()`, `tls()`, `predict_survival_curves()`,
  `predict_heat_injury()`, `plot_tdt_curve()`.
- **`tbl-function-tour`** — every exported function grouped by stage (Data, Model
  spec, Fit, Inspection, Accessors, Diagnostics, Predictions, TDT quantities,
  Two-stage, Heat injury, Plotting, Utilities). This is the master list driving the
  analogue table in Part 3.

Key API facts the tour establishes:
- `extract_tdt()` gives `z` and `CTmax` always; `T_crit` is opt-in via `lethal = TRUE`
  (rate-multiplier; lethal-endpoint data only).
- `tls()` is the general entry point: it derives the same quantities from **any**
  hand-coded brms 4PL by evaluating each sub-parameter at a moderator × temperature
  grid with `posterior_linpred()`. `mode` picks relative midpoint vs absolute LT50.
- `target_surv` (`"relative"` = `(low+up)/2` per draw; `"absolute"` = 0.5; or a
  numeric) is shared across `derive_*`, `extract_tdt()` and `tls()`.
- Two-stage is a first-class citizen: `ts_stage1()` / `ts_stage2()` / `ts_ci()` /
  `ts_curve()` implement the classical Rezende/Ørsted pipeline.

### Section 2 — A Tutorial with Simulations (lines 307–1574)

A controlled simulation showing recovery of `z` and `CTmax_1hr` under binomial and
beta-binomial sampling, then a worked example with temperature effects on **every**
shape parameter, then a heat-injury tutorial.

**Simulating data (lines 311–456):**
- `true_params`: `ell = 0.03`, `up = 0.97`, `k = 8`, `m_beta0 = 1.5`,
  `m_beta1 = -0.15`, `T_bar = 34`. Implied `z = -1/beta1 ≈ 6.7 °C`.
- Closed-form truth: `true_alpha = m_beta0 + (1/k)·log((up-0.5)/(0.5-ell)) - m_beta1·T_bar`;
  `true_CTmax = (log10(60) - alpha)/beta1`; `true_T_crit = true_CTmax - 2.5·true_z`
  (median of the rate-multiplier integral; geometric-mean of `r* ∈ [0.1,1]` sits at
  `log10(r*/100) = -2.5`).
- Design: 5 temps `c(30,32,34,36,38)` × 6 durations `c(1,5,15,45,135,405)` min ×
  30 reps × 30 individuals = 900 trials / 27,000 individuals.
- Two DGPs: binomial `y ~ Binomial(n, p_true)`; beta-binomial with `phi = 5`,
  `p_draw ~ Beta(p_true·phi, (1-p_true)·phi)`.
- `fig-true-surface` shows the true 4PL across temperatures.

**Classical two-stage pipeline (lines 457–591):**
- Stage 1: `ts_stage1(sim_bin, temp="T", duration="t", n_surv="y", n_total="n", family="binomial")`
  (logit-link GLM per temperature; midpoint `log10 LT50 = -beta0/beta1`).
  `tbl-stage1-lt50` compares per-temperature LT50 to truth.
- Stage 2: `ts_stage2(stage1_bin, t_ref=60, time_multiplier=1)` (OLS of log10 LT50 on
  T → `z`, `CTmax`, `T_crit`). `fig-stage2-regression` (regression line, log10(60)
  reference, truth).

**Joint Bayesian 4PL (lines 592–1007):**
- `make_4pl_formula()` printed (`show-formula`); `standardize_data(..., temp="T",
  duration="t", n_total="n", n_surv="y", duration_unit="minutes")`.
- Fits: `fit_4pl(std_bin, family = binomial(link="identity"), chains=4, iter=2000,
  cores=4, seed=123, file=..., file_refit="never")` and beta-binomial via the default
  family. `tbl-r2-tutorial` (`bayes_R2()` via `bayes_r2_table()` helper).
- `tbl-recovery` (four 4PL params + slope vs truth); `plot-recovery-fit`
  (`predict_survival_curves()` + `plot_survival_curves()`).
- Deriving z/CTmax/T_crit (lines 798–856): **callout box "T_crit is meaningful only
  for lethal-endpoint data"** (lines 814–820). `extract_tdt(wf_bin, target_surv="relative",
  t_ref=60, time_multiplier=1, ndraws=1000, lethal=TRUE)`.
  **T_crit definition:** `T_crit(r*) = CTmax_1hr + z·log10(r*/100)`, integrated over a
  uniform prior on `log10(r*)` with `TC_rate_range = c(0.1, 1)` % HI/hr. Tables
  `tbl-tls-recovery`, `tbl-uncert-z-ct`.
- `tbl-twostage-compare` (lines 1008–1042): four estimator×dataset combos (two-stage
  vs joint, binomial vs beta-binomial) for z and CTmax_1hr vs truth.

**Worked example — temperature effects on every shape parameter (lines 1044–1419):**
The pivotal extension. Generating model: `ell` constant, `up` **declines** in T, `k`
**rises** in T:
```
ell = 0.49 * inv_logit(ell_raw)                      # constant (≈0.05)
up  = 0.51 + 0.49 * inv_logit(up_raw_0 + up_raw_T*T_c) # declines (≈0.93→0.88)
k   = exp(log_k_0 + log_k_T*T_c)                       # rises   (≈5.4→12.6)
```
with `up_raw_T = -0.60`, `log_k_0 = log(8)`, `log_k_T = 0.30`. The default `fit_4pl()`
already puts `temp_c` on all four sub-parameters, so one call recovers it
(`fit-ext-default`). `tbl-ext-recovery` (per-temperature natural-scale recovery);
`extract_tdt(wf_ext, target_surv="relative", ...)`; `tbl-extract-ext`; **local z(T)**
via finite difference of the bent log10-LT50(T) curve (`local-z-ext`); figures
`plot-true-surface-ext`, `plot-lt50-curve-ext` (bent), `plot-local-z-ext`.

**Heat-injury tutorial (lines 1420–1574):**
- `hi_trace`: 5-day sinusoidal diurnal trace (12–24 °C), damage threshold `T_c = 20`.
- `predict_heat_injury(trace=hi_trace, workflow=wf_bb, target_surv=0.5, T_c=20,
  trace_unit="hours", ndraws=500)`; `plot_heat_injury()` two-panel (`fig-hi-trajectory`).
- "Why are the bands so wide": the rate multiplier `10^((T-CTmax)/z)` is exponential,
  so a 1 °C CTmax shift multiplies hourly HI by `10^(1/z)`.
- Validation (lines 1512–1573): `make_temperature_scenarios(baseline=20, spike_temp=28,
  n_hours=96, spike_times_single=24, spike_times_multi=c(24,48,72))`,
  `planted_dose_from_trace(z=true_z, CTmax_1hr=true_CTmax, T_c=24)` as analytical
  truth vs posterior HI.

### Section 3 — Extended Simulation Results (lines 1575–2138)

A Monte Carlo sweep, **N_sim = 1000 per cell**, comparing six methods:
`Two-stage bin (Normal CI)`, `Two-stage bin (t CI)`, `Two-stage BB (Normal CI)`,
`Two-stage BB (t CI)`, `Joint 4PL (relative)`, `Joint 4PL (absolute)`. Metrics: bias,
95% coverage, RMSE (°C) for `z` and `CTmax_1hr`. RMSE collapses Normal/t variants (4
distinct point estimators). **Failure** = fit errored OR `|z bias| > 20` or
`|CTmax bias| > 10`.

| Scenario | What it varies / DGP | Key finding |
|---|---|---|
| **Scen 1 — Strict equivalence** | binomial, `up≈0.999/low≈0.001`, `k=8`, midpoint slope −0.15; `n_reps ∈ {3,5}` | All methods ~unbiased; two-stage Normal CIs under-cover, t-correction near nominal; joint 4PL well calibrated. |
| **Scen 2 — Likelihood misspec.** | beta-binomial `phi=5`, same mean shape | Point estimates still unbiased; overdispersion alone barely separates binomial/BB two-stage; joint 4PL well calibrated. |
| **Scen 4 — Asymptotes compress** | `up` −0.01/°C from 0.92, `low` +0.01/°C from 0.05 | Two-stage biased (CTmax −, z +) + under-coverage; joint 4PL ~unbiased, near-nominal. |
| **Scen 6 — Drifting `up` (β_up)** | upper asymptote drifts with T (coverage panels) | Normal vs t two-stage CIs differ in coverage despite identical points. |
| **Scen 7 — Constant-reduced `up_0`** | constant `up_0 ∈ {0.65…0.99}` | **Two-stage CTmax coverage collapses as up_0 falls; t-correction does not recover. Joint 4PL holds 92–96% throughout.** |
| **Scen 8 — Design × replication** | full (5×6) vs sparse (3×4) grid × `n_reps ∈ {1,3,5}`; `N ~ Unif{10..20}` | Sparse×1 cripples two-stage (large unstable estimates, implausibly wide t-CIs); joint 4PL coherent across all six cells. |
| **Scen 9 — Short timeframes** | `tmax ∈ {60,120,240,405}` min cap | 60-min cap most demanding (cool temps never reach 50%); joint 4PL retains calibration via strength-sharing. |

Figures `fig-sim-supp-scenN`; RMSE tables `tbl-sim-supp-scenN-rmse`. Helper plotters:
forest plot (cell scenarios 1/2/4/8), sweep-coverage plot (6/7), RMSE table.

### Section 4 — Case Study 1: Shrimp (lines 2139–3220)

**Dataset:** brown shrimp lethal assay; load `shrimp_raw <- shrimp_lethal`. Columns
`Temperature_assay`, `Duration_exposure_hours`, `N_individuals_after_trial`,
`Mortality_after_trial`, with random-effect grouping `Date`, `Tank`. 148 trials,
30–33 °C, 5 min–6 h.

```r
shrimp_std <- standardize_data(shrimp_raw,
  temp = "Temperature_assay", duration = "Duration_exposure_hours",
  n_total = "N_individuals_after_trial", mortality = "Mortality_after_trial",
  random_effects = c("Date", "Tank"), duration_unit = "hours")
```

- **Two-stage:** `ts_stage1(family="binomial")` and `ts_stage1(family="betabinomial")`;
  `ts_stage2(t_ref=60, time_multiplier=60, TC_rate_range=c(0.1,1))`;
  `ts_ci(method="mvn", level=0.95, n_sim=1000)` for line bands; `ts_curve()`.
- **Joint 4PL:** `fit_4pl(shrimp_std, random_effects=c("Date","Tank"), chains=4,
  iter=8000, warmup=4000, cores=4, seed=123, control=list(adapt_delta=0.99,
  max_treedepth=20), file=...)`.
- **Extract:** `extract_tdt(wf_shrimp, target_surv="relative", t_ref=60,
  TC_rate_range=c(0.1,1), ndraws=500, lethal=TRUE)` → z, CTmax_1hr, T_crit.
- **Reported numbers:** shrimp relative-threshold **T_crit = 27.7 °C** (used in
  Fig 6; the Kristineberg fjord 17-yr hourly max is 26.1 °C, below T_crit).
- **Tables:** `tbl-shrimp-summary`, `tbl-shrimp-two-step-tdt`, `tbl-shrimp-diagnostics`,
  `tbl-shrimp-parameters`, `tbl-shrimp-extract`, `tbl-shrimp-approach-compare`,
  `tbl-shrimp-hi-summary`, `tbl-r2-shrimp`.
- **Figures:** `fig-shrimp-two-step-tdt-line`, `fig-shrimp-trace`,
  `fig-shrimp-survival-curves`, `fig-shrimp-landscape`, `fig-shrimp-tdt-line`,
  `fig-shrimp-tcrit-ctmax` (z / CTmax / T_crit densities), `fig-shrimp-approach-compare-tdt-lines`,
  six `fig-shrimp-hi-*` (traces, single/multi/diurnal × no-repair/repair).
- **Heat injury:** `make_temperature_scenarios(baseline=17, spike_temp=CTmax_med,
  n_hours=96, spike_times_single=24, spike_times_multi=c(24,48,72), diurnal_n_days=4,
  diurnal_day_peaks=c(22,27,30,30.5), diurnal_night_temp=c(18,19.5,21.5,22))`;
  `predict_heat_injury(..., target_surv="relative", T_c=shrimp_T_c, trace_unit="hours",
  ndraws=500)`; repair via `repair_pars=list(TA=14065, TAL=50000, TAH=120000,
  TL=10.5+273.15, TH=22.5+273.15, TREF=17+273.15, r_ref=0.05)`.
- **Sublethal time-to-knockdown (sec-shrimp-sublethal, lines 2851–3204):** the
  `shrimp_sublethal` dataset (one row per cup, `time_to_event` minutes to loss of
  response, grouping `date_experiment`/`tank_ID`/`cup_ID`, `assay_temp`). Two routes:
  (a) **censored hierarchical linear** `brms::bf(log10_time ~ temp_c + (1|date_experiment)
  + (1|tank_ID) + (1|cup_ID))` → `z = -1/b_temp_c`, `CTmax = Tbar + (log10(60)-b0)/b_temp_c`;
  (b) **4PL on proportion-still-responding counts** (count cups with `time_to_event > t`
  at 18 log-spaced eval times → `standardize_data()` → `fit_4pl()`). Comparison
  `tbl-shrimp-sub-compare`, `fig-shrimp-sub-compare`. Caveat: rate-multiplier T_crit is
  endpoint-conditional (knockdown z < lethal z), so it is **not** reported for the
  sublethal endpoint.

### Section 5 — Case Study 2: Zebrafish lethal-TDT across life stages (lines 3221–4550)

**Dataset:** `zf <- zebrafish_lethal`; per-day morning/afternoon mortality already
summed into `n_total`/`n_surv`/`n_dead`; `life_stage` factor (young_embryos /
old_embryos / larvae); `assay_temp`, `duration_h`, `Date_experiment`. Standardised
**per stage** in a loop with a **shared `temp_mean`** (grand mean across the panel):

```r
standardize_data(filter(zf, life_stage==s), temp="assay_temp", duration="duration_h",
  n_total="n_total", n_surv="n_surv", random_effects="Date_experiment",
  duration_unit="hours", temp_mean = zf_temp_mean)
```

- **Two-stage by stage:** loop `ts_stage1`(bin + BB) then `ts_stage2(time_multiplier=60,
  t_ref=60, TC_rate_range=c(0.1,1))`; `ts_ci(method="mvn", n_sim=1000)`.
- **Approach 1 — separate 4PL per stage:** loop `fit_4pl(zf_std_by_stage[[s]],
  random_effects="Date_experiment", chains=4, iter=8000, warmup=4000, cores=4, seed=123,
  control=list(adapt_delta=0.99, max_treedepth=25))`.
- **Approach 2 — joint 4PL with `life_stage` on EVERY sub-parameter:** hand-coded
  cell-means formula `lowraw ~ 0 + life_stage + temp_c:life_stage` (and same for
  `upraw`, `logk`, `mid`; `mid` also gets `(1|Date_experiment)`),
  `family = beta_binomial(link="identity")`. Per-stage intercept priors plus
  `normal(0, {0.5,0.5,0.3,0.6})` slope priors, `exponential(2)` RE-SD, `gamma(2,0.1)`
  on phi. `brm(..., control=list(adapt_delta=0.995, max_treedepth=20), backend="cmdstanr")`.
- **Extract / TLS:** separate via `extract_tdt(..., target_surv="relative", t_ref=60,
  TC_rate_range=c(0.1,1), ndraws=500, lethal=TRUE)`; joint via
  `tls(fit_zf_joint, by="life_stage", newdata=grid, mode="relative", lethal=TRUE,
  t_ref=60, time_multiplier=60, temp_mean=zf_temp_mean, re_formula=NA)`.
- **Contrasts** by pairing draws on `.draw` (larvae−old, larvae−young, old−young) for z
  and CTmax; pMCMC = twice the smaller tail.
- **Sensitivity (sec-zebrafish-relative-ltx):** relative vs absolute (0.5) threshold;
  `tbl-zebrafish-upper-asymptote` shows young_embryos `up ≈ 0.76` (below 1), so the
  absolute threshold shifts its CTmax but not the others; z robust either way.
- **Tables:** `tbl-zebrafish-summary`, `-two-step-tdt`, `-sep-diagnostics`, `-sep-extract`,
  `-sep-contrasts`, `-joint-diagnostics`, `-joint-extract`, `-compare`,
  `-twostep-joint-compare`, `-upper-asymptote`, `-sep-extract-abs`, `-threshold-compare`,
  `tbl-r2-zebrafish`.
- **Figures:** `fig-zebrafish-two-step-tdt-line`, `-sep-survcurves`, `-sep-landscape`,
  `-sep-tdt-line`, `-overlay-tdt-line` (independent vs joint), `-method-densities`
  (separate vs joint per stage), `-twostep-joint-tdt-lines`, `-threshold-tdt-line`.

### Section 6 — Case Study 3: Leaf PSII (lines 4551–5416)

**Dataset:** snow gum `snowgum_psii`; response `fvfm_prop` = post/pre Fv/Fm,
continuous proportion in (0,1); columns `Temp`, `Time`, `fvfm_prop`, grouping `Day`,
`G_Room`. **Sublethal** (PSII retention, not survival). Standardised with the
**`proportion=` argument** (no counts) and a **Beta likelihood**:

```r
leaf_std <- standardize_data(leaf_raw, temp="Temp", duration="Time",
  proportion="fvfm_prop", random_effects=c("Day","G_Room"), duration_unit="minutes")
```
~19% of `fvfm_prop` are exact zeros (full PSII shutdown) → clamped to 0.001.

- **Two-stage:** Stage 1 by two methods — quasi-binomial logistic and beta-ML
  (`optim` on a beta NLL) — then `fit_stage2_case(time_multiplier=1, t_ref=60,
  TC_rate_range=c(0.1,1))`; `ts_ci`/propagation `n_sim=1000` (seeds 301/302).
- **Joint 4PL:** `fit_4pl(leaf_std, family=brms::Beta(link="identity"),
  random_effects=c("Day","G_Room"), chains=4, iter=8000, warmup=4000, cores=4, seed=123,
  init=0, backend="cmdstanr", control=list(adapt_delta=0.995, max_treedepth=25))`.
- **Extract:** `extract_tdt(wf_leaf, target_surv="relative", t_ref=60, time_multiplier=1,
  ndraws=500, lethal=FALSE)` → **z and CTmax_1hr only; T_crit NOT reported** (caption
  states it explicitly because PSII loss is sublethal). Also `target_surv="absolute"`
  for the like-with-like comparison table.
- **Tables:** `tbl-leaf-summary`, `-two-step-tdt`, `-diagnostics`, `-parameters`,
  `-extract`, `-approach-compare`, `tbl-r2-leaf`, `tbl-leaf-hi-summary`.
- **Figures:** `fig-leaf-two-step-tdt-line`, `-trace`, `-survival-curves` (retained PSII),
  `-landscape`, `-tdt-line`, `-ctmax` (z + CTmax densities, **no T_crit**),
  `-approach-compare-tdt-lines`, six `fig-leaf-hi-*`.
- **Heat injury:** `make_temperature_scenarios(baseline=30, spike_temp=leaf_CTmax_med,
  n_hours=96, diurnal_day_peaks=c(38,41,44,43.5), diurnal_night_temp=c(20,15.5,17.5,19))`;
  `predict_heat_injury(..., target_surv="relative", T_c=leaf_T_c=32.5, trace_unit="hours",
  ndraws=500)`; repair `repair_pars=list(TA=14065, TAL=50000, TAH=120000, TL=10.5+273.15,
  TH=32.5+273.15, TREF=30+273.15, r_ref=0.15)`. "HI" is read as cumulative **functional**
  injury and "survival" as retained function.

### Section 7 — Case Study 4: Vinegar fly D. suzukii across sexes (lines 5417–6150)

See Part 5 for the full data-subsetting recipe. Headlines:

- **Dataset:** `data(dsuzukii)` — long, one row per individual. Columns: `temp`, `time`
  (minutes), `sex` (F/M), `dead` (binary 0/1 mortality), `t_coma` (right-censored coma
  time; NA if still awake), `lvl` (exposure level), `prod` (offspring count).
- **Mortality (lethal):** aggregate to counts by `group_by(temp, time, sex)` →
  `n_total = n()`, `n_dead = sum(dead)`. Fit a **separate** 4PL per sex, plus a
  **joint** model with `sex` on the midpoint only.
  - Per-sex fits: `standardize_data(mort_dros_F, temp="temp", duration="time",
    n_total="n_total", n_dead="n_dead", duration_unit="minutes")`;
    `fit_4pl(std_mort_F, chains=4, iter=8000, warmup=4000, cores=4, seed=123,
    control=list(adapt_delta=0.99, max_treedepth=12))`.
  - **Extract uses a 4-hour reference and absolute threshold:**
    `extract_tdt(wf_dros_mort_M, target_surv="absolute", t_ref=60*4, lethal=TRUE)`.
  - Joint model: `mid ~ sex * temp_c` (sex on midpoint → sex-specific z & CTmax;
    asymptotes & steepness shared); `tls(joint_sex_fit, by="sex", mode="relative"/"absolute",
    lethal=TRUE, t_ref=60*4, temp_mean=...)`.
  - **Numbers (match Ørsted Table 1):** z ≈ **3.06/3.21 (F/M)** relative, **3.04/3.18**
    absolute (Ørsted: 3.03/3.28); CTmax_4hr ≈ **35.1–35.2 °C** both sexes; T_crit ≈ 29 °C.
    pMCMC on the sex z-difference spans zero (no clear difference).
- **Sublethal heat-coma (sec-dros-coma):** right-censored — `r round(100·mean(is.na(t_coma)))`%
  censored. Linear route `brms::bf(log10_coma | cens(cens) ~ temp_c*sex + (1|block))`;
  4PL route on proportion-awake counts (`mid ~ sex*temp_c`). `tbl-dros-coma-compare`:
  z ≈ 2.3–2.4 °C, CTmax_1hr ≈ 36.3–36.5 °C (Ørsted drc: 2.23/2.33, 36.36/36.31).
- **Sublethal productivity (sec-dros-productivity):** **hurdle** model
  `brms::bf(prod ~ logd*temp_c*sex, hu ~ logd*temp_c*sex)`, Gamma vs log-normal by LOO
  (Gamma wins). Incidence component → TDT (`z ≈ 3 °C`, CTmax_1hr 36.3/36.7);
  magnitude component → duration-sensitivity `b(T)` of conditional clutch (no LT50).
  `tbl-dros-prod-incidence`, `tbl-dros-prod-magnitude`.

### Section 8 — Manuscript Figure 5: cross-case-study summary (lines 6151–6401)

A ridge-density panel (`ggridges`) of the joint-4PL posteriors of `z` (left) and
`CTmax` (right) for all four taxa: shrimp (1 ridge), snow gum (1), zebrafish (3 life
stages), fly (2 sexes). Each ridge carries a black-outlined median point + 95% CrI
bar with a printed `median [lo, hi]` label; pMCMC brackets annotate within-taxon
contrasts (zebrafish stages, fly sexes). CTmax reference follows each study: 1 h for
shrimp/zebrafish/leaf (relative midpoint), **4 h** for the fly (absolute LT50). Panels
have independent x-axes. Saved 11.5×9.6 in @600 dpi, with per-taxon SVG illustrations
inset. Persists `fig4_summary.rds` so the manuscript reports the CTmax range as inline
code.

### Section 9 — Manuscript Figure 6: Heat injury and survival (lines 6402–6607)

Two field-trace case studies side by side: **fly** (NicheMapR shaded microclimate,
Rennes 2018, Zenodo 10821572) and **shrimp** (real Kristineberg / Gullmar fjord
sea-surface temperature, summer 2018, **+4 °C warming projection** because the literal
fjord never reaches the shrimp's T_crit of 27.7 °C). For each: temperature trace with
relative-threshold T_crit line; cumulative HI (100% = one LT50); predicted survival;
**with and without repair**. Bands are **±1 SE across posterior draws** (not 95% CrI)
to keep the exponential envelope readable. `predict_heat_injury(..., target_surv="relative",
T_c=Tc, trace_unit="hours", ndraws=150, repair=…, repair_pars=…, save_draws=TRUE)`.
Repair is an **illustrative Sharpe–Schoolfield kernel, not empirically fitted**
(`r_ref = 0.03` LT50-dose/h at reference). Survival trajectories start at each taxon's
fitted upper asymptote (fly ≈85%, shrimp ≈100%), not 100%.

### Section 10 — Derivation of correction factors for threshold summaries (lines 6608–6847)

Pure algebra (no new data). Derives, step by step:
- **Asymmetry correction** `log10 t50(T) = mid(T) + (1/k)·log((up-0.5)/(0.5-low))`
  (Eq. 4) — depends only on (low, up, k), **not** on T.
- **TDT line** `log10 t50(T) = alpha + beta1·T`, `alpha = beta0 - beta1·Tbar +
  (1/k)·log((up-0.5)/(0.5-low))` (boxed).
- **CTmax correction** `CTmax(tref) = Tbar + (log10 tref - beta0)/beta1 -
  (1/beta1)·(1/k)·log((up-0.5)/(0.5-low))` (Eq. 5).
- **Arbitrary threshold** `x/100`: same with `(up - x/100)/(x/100 - low)`.
- **z is robust** (`z = -1/beta1`; correction is T-independent so the slope is
  unchanged), but **CTmax is not** (the asymmetry term enters divided by beta1).
- **Vanishing regime:** when `low≈0, up≈1` the correction → 0.
- **Numerical check** `tbl-supp-corr-check`: closed form vs `uniroot` 4PL inversion to
  floating-point precision, using asymmetric `low=0.05, up=0.85, k=4, beta1=-0.25,
  Tbar=36` (so `z=4`).

This derivation is the mathematical backbone of freqTLS's `derive_ctmax()` (which
already implements the asymmetry correction `qlogis((surv-low)/(up-low))/k`) and the
`relative` vs `absolute` distinction. freqTLS should cite/host the same derivation
in `vignettes/model-math.Rmd`.

### Sections 11–12 — References / Session info (lines 6848–6861)

Bibliography (`@orsted_suzukii_2024`, `@orsted_finding_2022`, `@rezende_landscapes_2014`,
`@jorgensen_unifying_2021`) and `sessionInfo()`. freqTLS's articles should cite the
same primary data papers and add the profile-likelihood methodology references.

---

## Part 2 — Per-case-study capsule (dataset → config → reported → figures)

### Case Study 1 — Shrimp (lethal)
- **Load/standardise:** `shrimp_lethal` → `standardize_data(temp="Temperature_assay",
  duration="Duration_exposure_hours", n_total="N_individuals_after_trial",
  mortality="Mortality_after_trial", random_effects=c("Date","Tank"), duration_unit="hours")`.
- **Config:** beta-binomial; `temp_effects` = midpoint only (constant shape); **lethal**;
  ungrouped; random intercepts Date+Tank.
- **Reported:** z, CTmax_1hr, **T_crit** (rate-multiplier `r* ∈ [0.1,1]`), Bayesian R²,
  diagnostics. T_crit ≈ 27.7 °C.
- **Figures:** survival curves, TDT landscape, TDT line, z/CTmax/T_crit densities,
  approach-comparison TDT lines, heat-injury panels.

### Case Study 2 — Zebrafish (lethal, grouped by life_stage)
- **Load/standardise:** `zebrafish_lethal` → per-stage `standardize_data(temp="assay_temp",
  duration="duration_h", n_total="n_total", n_surv="n_surv",
  random_effects="Date_experiment", duration_unit="hours", temp_mean=shared)`.
- **Config:** beta-binomial; **lethal**; grouped by `life_stage`. Two approaches —
  separate-per-stage and joint with life_stage on all four sub-parameters (cell-means).
- **Reported:** z, CTmax_1hr, T_crit per stage; pairwise contrasts (pMCMC); relative vs
  absolute threshold sensitivity; per-stage upper asymptote (young_embryos ≈0.76).
- **Figures:** separate & joint survival curves/landscapes/TDT lines, independent-vs-joint
  overlay, method-density comparison, threshold-sensitivity TDT line.

### Case Study 3 — Leaf PSII (sublethal, Beta family)
- **Load/standardise:** `snowgum_psii` → `standardize_data(temp="Temp", duration="Time",
  proportion="fvfm_prop", random_effects=c("Day","G_Room"), duration_unit="minutes")`.
- **Config:** **Beta** family (continuous proportion); `temp_effects` = midpoint only;
  **sublethal → `lethal=FALSE`, no T_crit**; ungrouped; random intercepts Day+G_Room.
  Note time unit is **minutes** (tref on minutes scale).
- **Reported:** z and CTmax_1hr only (relative and absolute), Bayesian R², diagnostics.
- **Figures:** retained-PSII curves, landscape, TDT line, z+CTmax densities (no T_crit),
  approach comparison, functional-injury panels.

### Case Study 4 — D. suzukii (lethal, grouped by sex) + sublethal extras
- **Load/standardise:** `dsuzukii` → aggregate to counts (Part 5) → per-sex
  `standardize_data(temp="temp", duration="time", n_total="n_total", n_dead="n_dead",
  duration_unit="minutes")`.
- **Config:** beta-binomial; **lethal**; grouped by `sex` (separate fits and joint
  `mid ~ sex*temp_c`). **CTmax at a 4-hour reference**, **absolute** LT50 threshold
  (following Ørsted).
- **Reported:** z, CTmax_4hr, T_crit per sex; sex contrast (pMCMC, spans zero).
- **freqTLS scope:** lethal-by-sex only (sublethal coma/productivity are non-goals,
  Part 6).

---

## Part 3 — bayesTLS function → freqTLS analogue table

Legend: ✅ direct analogue exists · ◑ partial / different mechanism · 🟡 article-level
(compose from primitives) · ❌ non-goal / out-of-scope.

| bayesTLS function | freqTLS analogue | Status | Notes |
|---|---|---|---|
| `standardize_data()` | (no standalone fn) `fit_tls()` takes tidy-eval columns / `tls_bf()` formula directly | ◑ | freqTLS skips the reshape step; map raw columns straight into `fit_tls(y=, n=, time=, temp=, group=)`. Articles do the dplyr aggregation inline. |
| `fit_4pl()` | `fit_tls()` | ✅ | ML/TMB instead of brms; `family ∈ {binomial, beta_binomial, beta}`; `group=` for grouped CTmax/z; `tref`. Constant-shape = `temp_effects` "mid" equivalent (default). |
| `make_4pl_priors()` | — | ❌ | Prior-free by design. The freq-vs-Bayes article should *explain* this contrast (no priors → no prior-sensitivity, but no regularisation on weak data either). |
| `make_4pl_formula()` | `tls_bf()` / `make_4pl_formula`-equivalent printed in `model-math` | ◑ | freqTLS formula DSL: `y|trials(n) ~ time(d)+temp(T)+CTmax(...)+log_z(...)+low(...)+up(...)+log_k(...)+(1|g)`. |
| `extract_tdt()` | composition of `derive_ctmax()` + `derive_z`/`get_z()` + `derive_tcrit()` | 🟡 | No single bundling wrapper; an article helper can assemble the same table. `lethal=TRUE` ↔ call `derive_tcrit()` only for lethal endpoints. |
| `tls()` (general, any brms 4PL, `by=`, `mode=`) | grouped `fit_tls()` + `tidy_parameters()` / `get_ctmax()` / `get_z()` | ◑ | freqTLS has no "derive from a foreign fit" path (it fits its own model). `mode="relative"/"absolute"` ↔ `derive_ctmax(surv=NULL | explicit)`. `by=` ↔ `group=`. |
| `tls_z()` / `tls_ctmax()` / `tls_tcrit()` | `get_z()` / `get_ctmax()` / `derive_tcrit()` | ✅ | Convenience accessors map cleanly. |
| `derive_z()` (relative/absolute; local z(T)) | `derive_z` internal + `get_z()`; local z(T) | ◑ | `z = -1/beta1` (relative) implemented; **local z(T)** for bent curves is **not** a goal at v0.1–0.2 (freqTLS constant-shape benchmark). Flag in non-goals. |
| `derive_tdt_curve()` | `derive_lt()` + `plot_tdt_curve()` | ✅ | `target_surv` modes map to `p=`/`surv=`. |
| `derive_temperature_for_duration()` | `derive_ctmax(surv=, duration=)` | ✅ | Same inversion at a fixed duration. |
| `derive_tdt_landscape()` | `predict_survival_surface()` | ✅ | Dense temp×duration grid for heatmap. |
| `extract_4pl_pars()` / `tdt_parameter_table()` | `tidy_parameters()` / `get_shape()` | ✅ | Natural-scale low/up/k/CTmax/z (+ phi). |
| `predict_survival_curves()` | `predict.profile_tls()` / `predict_survival_surface()` + `plot_survival_curves()` | ✅ | Curves with observed overlay. |
| `summarise_observed_survival()` | (inline in `plot_survival_curves()`) | ◑ | Observed proportions are overlaid by the plot fn; no standalone export. Could add a tiny helper for the article. |
| `predict_heat_injury()` | `predict_heat_injury()` | ◑ | **Deterministic** ML version (forward Euler from the MLE) vs bayesTLS's posterior bands. `target_surv`, `t_c`, optional Sharpe–Schoolfield `repair`. Uncertainty: bootstrap the trace prediction (article-level) rather than posterior draws. |
| `repair_rate_schoolfield()` | repair-kernel support inside `predict_heat_injury()` (user-supplied pars, flagged not-identified) | ◑ | Same Sharpe–Schoolfield form; freqTLS does not *fit* it (neither does bayesTLS — illustrative). |
| `make_temperature_scenarios()` | 🟡 article helper (build flat/single/multi/diurnal traces) | 🟡 | Not exported; articles construct traces directly. Consider a small internal `make_traces()` if reused across articles. |
| `planted_dose_from_trace()` | 🟡 article helper (analytical HI truth) | 🟡 | For the heat-injury validation article; closed-form, easy to reproduce. |
| `ts_stage1()` | (benchmark code in `data-raw/build_benchmark_cache.R`; classical two-stage cached) | ◑ | freqTLS does **not** export a two-stage fitter; it consumes cached two-stage results for the fair comparison. Articles show the cached classical line, not a live `ts_stage1`. |
| `ts_stage2()` | cached two-stage (as above) | ◑ | Same: cached, not re-implemented. |
| `ts_ci()` (delta / mvn) | cached two-stage delta-method CIs (`method="delta"` in cache build) | ◑ | Benchmark protocol locks `ts_ci(method="delta", level=0.95)`. |
| `ts_curve()` | cached two-stage line | ◑ | Used for approach-comparison TDT-line overlays. |
| `make_4pl_priors`/`make_4pl_formula` (spec) | `tls_bf()` + family constructors | ◑ | See above. |
| `get_ctmax_summary()` / `get_z_summary()` / `get_tcrit_summary()` | `get_ctmax()` / `get_z()` / (`derive_tcrit()` + interval) with `conf.int=TRUE` | ✅ | Median+CrI ↔ estimate + profile/Wald/bootstrap CI. |
| `get_ctmax_draws()` / `get_z_draws()` / `get_tcrit_draws()` / `get_surv_draws()` / `get_hi_draws()` | **bootstrap replicates** (`confint(method="bootstrap")` internals) | ◑ | freqTLS has no posterior draws; the closest object is the parametric-bootstrap sample. Cross-case Figure-5 analogue should use bootstrap distributions or, more honestly, the **Confidence Eye** (interval, not density). |
| `diagnose_tdt_fit()` (Rhat/ESS/divergences) | `check_tls()` (pre/post-fit data-adequacy + convergence flags) | ◑ | Different diagnostics: ML convergence + identifiability warnings, not HMC mixing. |
| `bayes_R2()` / `bayes_r2_table()` | — (report deviance/pseudo-R² or omit) | ❌/🟡 | No Bayesian R²; an article could report a McFadden/Tjur-style pseudo-R² or simply omit. Not a core deliverable. |
| `clock_to_minutes()` | — (do inline; or borrow pattern) | 🟡 | Time parsing is a data-prep convenience; articles can parse clock strings directly. |
| `plot_survival_curves()` | `plot_survival_curves()` | ✅ | Same intent; freqTLS theme. |
| `plot_tdt_curve()` | `plot_tdt_curve()` | ✅ | LT_x vs T on log axis. |
| `plot_tdt_landscape()` | `plot_survival_surface(contour=TRUE)` | ✅ | Heatmap + contours. |
| `plot_temperature_density()` (CTmax/T_crit posterior density + CrI bar) | `plot_confidence_eye()` | ◑ | **freqTLS's flagship divergence:** an honest interval **lens** (hollow point), never a posterior density. Non-closing profile → hollow point only, no lens. |
| `plot_heat_injury()` | (compose from `predict_heat_injury()` output) | 🟡 | No dedicated two-panel plotter yet; article builds HI + survival panels. Candidate for a small `plot_heat_injury()` export. |
| `plot_temperature_scenarios()` / `plot_repair_rate()` | 🟡 article-level | 🟡 | Trace/TPC plots are easy ggplot; not exported. |
| `theme_tdt()` | freqTLS plotting theme (internal) | ◑ | Shared theming exists inside the plot functions. |
| `tdt_quantile()` / `format_interval()` | `tidy_parameters()` formatting / `format_interval`-style helper | 🟡 | Interval formatting; article-level. |
| `print/summary/plot.bayes_tls`, `has_fit()`, `get_brmsfit()` | `print/summary.profile_tls`, `coef/vcov/logLik/AIC.profile_tls` | ◑ | Object accessors differ (TMB obj, not brmsfit). |

**Summary:** the *modelling and derivation* surface maps almost one-to-one
(`fit_4pl`→`fit_tls`, `extract_tdt`/`tls`→`derive_*`+`tidy_parameters`,
`derive_tdt_*`→`derive_lt`/`predict_survival_surface`, all plots). The *Bayesian
machinery* (priors, posterior draws, Bayesian R², HMC diagnostics) has **no analogue
by design** and is replaced by freqTLS's distinctive offerings: profile-likelihood
intervals, prior-free bootstrap, the Confidence Eye, and `check_tls()` identifiability
diagnostics. The *two-stage* functions are **consumed as cache**, not re-implemented.

---

## Part 4 — freqTLS article plan (mirror bayesTLS AND exceed it)

**Common contract for every case-study article (the "three-way" rule):** each must show
**(1) freqTLS live** (TMB fit + profile/bootstrap CI + Confidence Eye),
**(2) bayesTLS** posterior medians + 95% CrI **from the maintainer-built cache**, and
**(3) classical two-stage** point estimates + delta CIs **from the cache**, all locked
to the benchmark protocol (relative threshold, constant shape, beta-binomial unless the
endpoint demands beta, tref per study). freqTLS adds four things bayesTLS lacks:
**profile-likelihood compatibility intervals**, **the Confidence Eye**, **stage/group
SHAPE covariates** (v0.2 grouped low/up/log_k), and an explicit **freq-vs-Bayes framing**.

> **Stan-cache flag.** shrimp + zebrafish are **cached** today. **snowgum + dsuzukii are
> NOT cached** — `data-raw/build_benchmark_cache.R` must be re-run on a Stan machine
> (cmdstanr + CmdStan) with snowgum (Beta family) and the new dsuzukii lethal-by-sex
> counts added before those two case studies can render the full three-way comparison.
> Until then, snowgum/dsuzukii articles can render freqTLS-only + classical two-stage
> (the two-stage classical fit needs no Stan) with the bayesTLS column marked "pending
> cache".

### Article A — Tutorial with simulations (mirror Section 2, exceed it)
- **Mirror:** `simulate_tls()` binomial + beta-binomial → `fit_tls()` → parameter
  recovery table → `derive_ctmax`/`derive_z`/`derive_tcrit` recovery → two-stage vs
  freqTLS point-estimate agreement (`tbl-twostage-compare` analogue).
- **Exceed:**
  - **Profile vs Wald vs bootstrap** intervals on the same simulated fit, side by side,
    with a note on equivariance (profile intervals are invariant to the CTmax/z vs
    low/up/k/mid reparameterisation; Wald is not).
  - **Confidence Eye** for z and CTmax with the observed-temperature rug
    (extrapolation flag).
  - **Coverage panel** from the in-repo coverage study (`coverage_results.rds`) echoing
    Section 3's calibration message, but for profile intervals.
  - **Identifiability** demo: shrink the design (Scen 8/9 spirit) until the profile does
    **not** close, and show the honest hollow-point Confidence Eye + `check_tls()` warning
    — the failure mode bayesTLS hides behind a prior.

### Article B — Shrimp (lethal) (mirror Section 4)
- **Mirror:** survival curves, TDT landscape, TDT line, z/CTmax/T_crit, heat-injury panels.
- **Exceed:** Confidence Eye for z/CTmax/T_crit; profile + bootstrap intervals; the
  three-way comparison TDT-line overlay (freqTLS band vs bayesTLS CrI vs two-stage CI).
- **Cache:** ✅ shrimp cached. Renders fully today.
- **Boundary:** the **sublethal time-to-knockdown** analysis is a **non-goal** (time-to-event;
  Part 6) — mention it as "see bayesTLS" rather than reproduce.

### Article C — Zebrafish across life stages (mirror Section 5) — **the SHAPE-covariate showcase**
- **Mirror:** separate-per-stage and joint fits; per-stage z/CTmax/T_crit; contrasts;
  relative-vs-absolute threshold sensitivity (young_embryos upper asymptote < 1).
- **Exceed:**
  - **v0.2 grouped SHAPE covariates:** fit `life_stage` on low/up/log_k (not just the
    midpoint), directly addressing the young_embryos low-asymptote case that the
    constant-shape benchmark cannot — a capability the benchmark protocol deliberately
    locks out for fairness but the article can showcase as freqTLS's edge.
  - **Confidence Eye per stage** (grouped, auto-expanded `CTmax:young_embryos` etc.) with
    pMCMC-style contrasts replaced by **profile/bootstrap CIs on the difference**
    (`dCTmax`, `dz`) — frequentist contrasts without posteriors.
- **Cache:** ✅ zebrafish (3 stages) cached. Renders fully today.

### Article D — Leaf PSII (sublethal, Beta family) (mirror Section 6)
- **Mirror:** Beta-family fit; retained-PSII curves; landscape; TDT line; z + CTmax
  (**no T_crit** — sublethal); functional-injury panels; relative vs absolute comparison.
- **Exceed:** Confidence Eye for z/CTmax; profile + bootstrap; the boundary-zero clamping
  handled honestly (~19% exact zeros) with a `check_tls()` note; freq-vs-Bayes on a
  continuous proportion.
- **Cache:** ❌ **snowgum NOT cached — re-run `build_benchmark_cache.R` with the Beta family.**
  Until then, render freqTLS + classical two-stage, mark bayesTLS column "pending".

### Article E — D. suzukii across sexes (lethal) (mirror Section 7, lethal subset)
- **Mirror:** per-sex separate fits and a joint `sex`-on-midpoint fit; z/CTmax at the
  **4-hour reference, absolute threshold**; T_crit; sex contrast.
- **Exceed:** Confidence Eye per sex; profile/bootstrap CI on the sex difference; verify
  the published Ørsted numbers (z 3.03/3.28, CTmax_4hr ≈35.2) are recovered by ML too.
- **Cache:** ❌ **dsuzukii NOT cached — vendor lethal-by-sex counts (Part 5), then re-run
  `build_benchmark_cache.R` with sex grouping at tref = 4 h, absolute threshold.**
- **Boundary:** heat-coma and productivity endpoints are **non-goals** (Part 6).

### Article F — Heat injury & survival under field traces (mirror Section 9 / Fig 6)
- **Mirror:** fly + shrimp field traces, cumulative HI (100% = one LT50), predicted
  survival, with/without repair, T_crit line, survival starting at the fitted upper
  asymptote.
- **Exceed:** deterministic ML trajectory plus a **bootstrap envelope** (refit at the MLE,
  propagate trace prediction) as the honest frequentist analogue of bayesTLS's ±1 SE
  posterior band; reuse the same Zenodo/Kristineberg traces and the +4 °C shrimp
  projection caveat.
- **Cache:** uses the fitted freqTLS models (shrimp ✅; fly needs the vendored data +
  fit). Repair kernel is illustrative (not fitted), same caveat as bayesTLS.

### Article G — Cross-case-study summary (mirror Section 8 / Fig 5)
- **Mirror:** a single multi-taxon panel of z and CTmax for shrimp, snow gum, zebrafish
  (3 stages), fly (2 sexes), with per-study reference exposure (1 h / 4 h).
- **Exceed:** replace posterior **ridges** with **Confidence Eyes** (interval lenses +
  hollow points) — the honest frequentist counterpart that cannot be misread as a
  posterior — with within-taxon contrasts shown as CI bars on the difference.
- **Cache:** needs all four taxa fit; snowgum + dsuzukii gated on the cache rebuild.

### Article H — Methods/derivation companion (mirror Section 10, host in `model-math.Rmd`)
- **Mirror:** the asymmetry-correction and CTmax-correction derivations and the numerical
  sanity check (`tbl-supp-corr-check` analogue via `derive_ctmax()` vs `uniroot`).
- **Exceed:** tie the derivation to freqTLS's internal coordinates and to **why the
  profile interval for z is robust but for CTmax is not** (the correction enters CTmax
  divided by beta1) — a natural bridge to the profile-likelihood vignette.

---

## Part 5 — D. suzukii "across sexes": lethal-by-sex vendoring spec

**Goal:** vendor a small `dsuzukii_lethal` dataset (lethal mortality counts by sex) so
Article E and the cache rebuild can run without bayesTLS installed.

**Upstream source:** Ørsted, Hoffmann, Sgrò et al. (2024), *D. suzukii* TDT across
productivity/coma/mortality — `@orsted_suzukii_2024`. The raw `dsuzukii` data ship inside
bayesTLS (`data(dsuzukii)`). The primary deposit is **Zenodo
[10.5281/zenodo.10602268](https://doi.org/10.5281/zenodo.10602268), licensed CC BY 4.0**
— cite it in `R/data.R`, `inst/CITATION`, and the article, exactly as the other vendored
datasets are attributed.

**Raw `dsuzukii` schema (long; one row per individual):**

| Column | Meaning |
|---|---|
| `temp` | assay temperature (°C) |
| `time` | exposure duration (**minutes**) |
| `sex` | `"F"` / `"M"` |
| `dead` | binary mortality indicator (0/1) per individual |
| `t_coma` | time to heat coma (minutes); **NA if the fly stayed awake** (right-censored) |
| `lvl` | exposure-level block label (used in coma/productivity grouping) |
| `prod` | offspring count (productivity endpoint) |

**Exact aggregation the supplement uses for the LETHAL endpoint (lines 5436–5439):**

```r
mort_dros <- dsuzukii |>
  dplyr::group_by(temp, time, sex) |>
  dplyr::summarise(n_total = dplyr::n(), n_dead = sum(dead), .groups = "drop") |>
  dplyr::arrange(temp, time, sex)
```

So **mortality is derived per individual** (`dead`) and **summed to counts per
`(temp, time, sex)` cell**: `n_total = number of flies in the cell`, `n_dead =
number that died`. For freqTLS, derive `survived = n_total - n_dead` and ship
`dsuzukii_lethal` with columns `temp, time, sex, n_total, n_dead, survived` (and keep
`time` in minutes; **tref = 4 h = 240 min**, absolute LT50 threshold, to match Ørsted).

**Per-sex split for fitting (lines 5458–5459):** `filter(sex == "F")` / `filter(sex == "M")`,
then either two `fit_tls()` calls (one per sex) or one grouped fit with `group = sex`.
The joint sex-difference model puts `sex` on the midpoint only (`mid ~ sex*temp_c` in
bayesTLS); freqTLS's analogue is `group = sex` (per-group CTmax/z, shared shape) or,
to exceed, `sex` on the shape too (v0.2 grouped shapes).

**Numbers to reproduce (validation targets):** z ≈ 3.03 (F) / 3.28 (M) (Ørsted Table 1);
CTmax_4hr ≈ 35.2 °C both sexes; T_crit ≈ 29 °C; sex z-difference CI spans zero.

**Build script:** add a `data-raw/vendor_dsuzukii_lethal.R` mirroring
`data-raw/make_benchmark_data.R` (which vendored shrimp/zebrafish): read `dsuzukii` from
bayesTLS once, run the aggregation above, assert the cell counts are sane, write
`data/dsuzukii_lethal.rda`, and document provenance + CC BY 4.0 in `R/data.R`.

---

## Part 6 — Explicit boundaries (documented non-goals)

freqTLS deliberately does **not** reproduce parts of the supplement. List these in
each article as "for X, see bayesTLS" rather than attempting them:

1. **Sublethal time-to-event (shrimp knockdown; D. suzukii heat-coma).** These use a
   **right-censored log-time regression** (`brms::bf(... | cens(cens) ~ ...)`), a model
   class outside freqTLS's 4PL count/proportion engine. The supplement also recasts
   them as proportion-counts for a 4PL — freqTLS *could* fit that recast, but the
   **time-to-event linear model itself is a non-goal**, and the rate-multiplier **T_crit
   is endpoint-conditional** (knockdown/coma z < lethal z), so T_crit must not be reported
   for these endpoints. (Capability matrix: time-to-event = non-goal.)

2. **D. suzukii multi-trait productivity (fertility).** Modelled with a **hurdle-Gamma**
   (zero-inflation + positive clutch) — two response processes, neither a 4PL survival
   curve. The "magnitude" component has **no LT50 / no z** (unbounded log-linear decline);
   only a duration-sensitivity `b(T)`. freqTLS is **purpose-built for one model class**;
   hurdle/multi-trait responses are explicitly out of scope (capability matrix; CLAUDE.md
   sibling-boundary note → that workflow belongs to bayesTLS).

3. **Full D. suzukii reproduction (knockdown + fertility together).** Out of scope — only
   the **lethal-by-sex** subset is vendored (Part 5).

4. **Posterior-specific deliverables:** Bayesian R² (`bayes_R2`), HMC diagnostics
   (Rhat/ESS/divergences), posterior **densities** as the uncertainty visual, and priors
   (`make_4pl_priors`). freqTLS substitutes the Confidence Eye (interval, **never** a
   posterior), `check_tls()` identifiability diagnostics, and prior-free profile/bootstrap
   intervals. The CLAUDE.md invariant forbids "posterior"/"credible" language and forbids a
   fabricated closed eye on a non-closing profile.

5. **Local z(T) for bent (T-varying-shape) curves** (Section 2 worked example). The
   benchmark and case studies lock **constant shape** (temp through the midpoint only) for
   a fair three-way comparison. freqTLS v0.2 adds **grouped** (factor) shape covariates,
   not **continuous-temperature** shape effects, so the bent-curve local-z(T) demo is not a
   v0.1–0.2 deliverable. Mention as a bayesTLS-specific extension.

6. **Live classical two-stage fitting.** freqTLS does not export `ts_stage1/2/ci/curve`;
   it consumes **cached** two-stage results for the fair comparison. The two-stage line in
   articles comes from `build_benchmark_cache.R`, not a live fit.

---

## Part 7 — Action checklist before the articles can render

1. **Vendor `dsuzukii_lethal`** (Part 5) via `data-raw/vendor_dsuzukii_lethal.R`; document
   CC BY 4.0 + Zenodo 10.5281/zenodo.10602268 in `R/data.R` and `inst/CITATION`.
2. **Extend the Stan benchmark cache** on a cmdstanr machine: re-run
   `data-raw/build_benchmark_cache.R` adding **(a) snowgum** (Beta family, relative
   threshold, tref=5 min or 1 h per the locked protocol — confirm unit) and **(b) dsuzukii
   lethal-by-sex** (beta-binomial, **absolute** threshold, **tref = 4 h**, grouped by sex).
   shrimp + zebrafish already cached. Bump `$meta` provenance.
3. **Decide article-level helpers** to promote to exports if reused: `plot_heat_injury()`,
   a trace builder (`make_traces`-style), an `extract_tdt`-style bundling helper, a
   `summarise_observed_survival` overlay.
4. **Keep capability sync** (per CLAUDE.md) when these land: `README.Rmd`, `ROADMAP.md`,
   `NEWS.md`, `docs/dev-log/known-limitations.md`, `docs/design/46-capability-matrix.md`,
   and the relevant design doc.
5. **Figure gate (Florence):** every Confidence Eye must honour the contract — hollow point
   + open lens on a non-closing profile, never a fabricated closed eye; "compatibility/
   confidence" language only.

---

*End of coverage map.*
