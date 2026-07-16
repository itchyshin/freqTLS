# Known Limitations

This is the authoritative fitted / planned / unsupported boundary for
freqTLS, indexed by capability. It mirrors the missing-cell audit in
`docs/design/46-capability-matrix.md`. Keep it synchronized with `README.Rmd`,
`ROADMAP.md`, `NEWS.md`, and the capability matrix in the same commit when a
capability changes.

> **Experimental 0.2.0.9000 (2026-07-16).** The active empirical teaching set
> mirrors the pinned bayesTLS supplement: oxygen-gradient zebrafish, cereal
> aphids, Snow-gum PSII, and the mortality and awake/coma *Drosophila suzukii*
> endpoints. Brown shrimp and life-stage zebrafish remain unpublished
> benchmark-only compatibility fixtures and must not appear in active
> tutorials, navigation, README examples, current comparisons, or generated
> discovery surfaces. Censored-time, hurdle-productivity, posterior inference,
> fitted repair dynamics, and CRAN submission are outside this phase.

> **Historical 0.1.0 candidate (2026-07-11).** The bayesTLS-style API included:
> `standardize_data`/`fit_4pl`/`tls`/`extract_tdt`/`predict_survival_curves`/
> `diagnose_tdt_fit`/`two_stage`, with disjoint-bounds asymptotes. Its analogue
> limitations: `fit_4pl` fixes `bounds = c(0, 1)` and fits the relative backbone
> (absolute/LTx and T_crit are derived post-hoc via `extract_tdt`/`tls` bootstrap,
> not profiled); `extract_tdt` bands are bootstrap (slower than the relative
> profile path). The benchmark cache is version-stamped and maintainer-built.

## Current status: experimental v0.2.0.9000

The v0.1 implementation established the TMB 4PL
engine, `fit_tls()`, and `simulate_tls()` (Phase 1); the S3 method surface
(`print`/`summary`/`coef`/`vcov`/`logLik`/`AIC`/`nobs`) and the tidy extractors
(`tidy_parameters()`, `get_ctmax()`, `get_z()`, `get_shape()`) (Phase 2); the
profile-likelihood machinery (`profile()`, `confint(method = "profile")`), the 12
identifiability warnings, and the eye-style profile plot (Phase 3); prediction
(`predict()`, `predict_survival_surface()`, `derive_lt()`) and the Confidence-Eye
and curve/surface plots (Phase 4); the R-SHRIMP-corrected `shrimp_lethal` and
`zebrafish_lethal` datasets and the benchmark harness (Phase 5); and the README,
the original vignette suite, NEWS, and pkgdown site (Phases 6–7). The v0.2 work
reclassifies those historical surfaces against the pinned bayesTLS teaching set;
"fitted" below means implemented and locally tested, not accepted by CRAN.

### Grouped API contract (fitted)

Per-group `CTmax` and `z` (shared `low`/`up`/`k`) are fitted via `~ 0 + group`
on both `CTmax` and `log_z`. The canonical grouped simulation call is
`simulate_tls(group = c("A","B"), CTmax = c(34,38), z = c(3,5))`: `group` is an
**atomic** vector and `CTmax`/`z` are parallel vectors with one value per
distinct group level (or a single shared scalar). A list `group` or a
length-mismatched `CTmax`/`z` is an error, not a silent recycle. Fitted
estimates and `tidy_parameters()` label grouped rows `CTmax:<level>` and
`z:<level>`.

### Interval methods (Wald and profile)

Both interval methods are fitted. `tidy_parameters()` and `confint()` default to
the **profile** intervals (`interval_type`/`method = "profile"`), which respect
the likelihood asymmetry, and offer **Wald** intervals (`method = "wald"`) built
on the internal link scale and back-transformed (first-order, symmetric on the
link scale). Under disjoint bounds the upper asymptote `up` has its own coordinate
`beta_up` but is not yet profiled, so it is reported with a delta-method **Wald**
interval under either method (labelled `interval_type = "wald"`,
`conf.status = "wald_fallback"`) and may slightly exceed 1 near the boundary.
Interval coverage is simulated in `data-raw/performance-study.R` and
`data-raw/coverage-study.R`: profile coverage is near nominal for the binomial
family. The beta-binomial profile can under-cover when the dispersion `phi` is
weakly identified — see the Inference caveats section below.

### Interfaces: column and formula (both fitted)

`fit_tls()` accepts either the original tidy-eval column interface
(`fit_tls(data, y, n, time, temp, group)`) or a brms/drmTMB-style formula built
with `tls_bf()` (`fit_tls(tls_bf(...), data = ...)`). The formula path resolves
the response (`successes | trials(total)` or `cbind(successes, failures)`), the
`time()` / `temp()` axes, and the `CTmax` / `log_z` fixed-effect designs, then
feeds the same engine, so a grouped formula fit equals the matching `group =`
column fit to optimiser tolerance. `CTmax` and `log_z` may carry supported fixed
designs but must produce the same model-matrix columns; their random-intercept
groupings may differ. The three shape designs are independent of each other and
of the headline fixed design.
Random-effect bars are supported as independent random
*intercepts* on `CTmax` / `log_z` / `low` / `log_k`; random slopes, correlated
random effects, and crossed/nested grouping remain out of scope (use `bayesTLS`). The grouped-by-
factor case (`CTmax ~ group`) is emitted as `~ 0 + group` so its design, labels,
and fit are byte-identical to the column `group =` call. Single-factor formula
grouping (`CTmax ~ group`) reconstructs the per-row grouping vector, so the
group-aware data-adequacy warnings, `diag_data`, and `plot_survival_curves()`
match the column interface. A general multi-predictor design has no single
grouping label, so it carries none.

## Implemented core matrix

The original core matrix covered two count families, two designs, and two CI
methods. Experimental v0.2 retains the Beta family, formula/shape designs,
limited random intercepts, and parametric bootstrap with target-specific routing:

- families: `binomial` and `beta_binomial` for count data, plus `beta` for
  continuous proportions in `(0, 1)`; `phi` is the dispersion coordinate for
  beta-binomial and Beta fits;
- designs: ungrouped and grouped `CTmax` / `log_z` with shared fixed design
  columns, plus independent formula designs on `low`, `up`, and `log_k`;
- CI methods: Wald, profile likelihood, and parametric bootstrap, with the
  target-specific exceptions stated below and in the capability matrix.

Additional implemented capability:

- the matched bayesTLS benchmark configuration keeps the temperature effect
  through the midpoint only (constant shape); the wider fitted API can model
  supported shape designs;
- Wald, profile-likelihood, and bootstrap confidence intervals for `CTmax`, `z`,
  `low`, `k`, `phi`, with `up` via the delta-method Wald fallback (its
  disjoint-bounds coordinate `beta_up` is not yet profiled) and group contrasts
  `dCTmax`, `dlog_z`;
- the 12 identifiability warnings (emitted, never silent);
- Confidence-Eye uncertainty plots (the default), survival curves, the thermal
  death-time curve, and the survival surface;
- the canonical six-unit comparator against pinned bayesTLS, with actual
  ML-minus-posterior-median differences; the older shrimp/life-stage cache is
  retained only as internal compatibility evidence.

### Benchmark data and cache (Phase 5)

Fitted:

- `shrimp_lethal`, `shrimp_sublethal`, and `zebrafish_lethal` remain installed
  only as unpublished compatibility fixtures. They may be used by internal
  legacy benchmark tests but are excluded from active examples, navigation,
  search, summaries, and current comparison claims.
- The byte-identical *Eucalyptus pauciflora* Snow-gum PSII object is installed,
  tested, and rendered in the experimental GitHub/pkgdown development build
  under the recorded non-commercial coauthor authorization. CRAN, commercial
  downstream redistribution, and adaptations remain blocked pending a broader
  written grant; see `docs/design/47-data-license-ledger.md`.
- `dsuzukii` (1407 rows, per-individual *Drosophila suzukii* mortality by sex with
  a 0/1 `dead` indicator; CC BY 4.0, Ørsted et al. 2024, Zenodo
  10.5281/zenodo.10602268) is the lethal endpoint. Aggregating to `(temp, time,
  sex)` cells and fitting `fit_4pl`/`fit_tls(group = sex, family =
  "beta_binomial", tref = 240)` (240 min = 4 h, relative midpoint threshold) recovers the
  published per-sex CTmax ~35.2 C and z ~3.0/3.2 (conv 0). The awake/coma count
  endpoint is also supported after aggregation as
  `n_awake = sum(is.na(t_coma))`; this is distinct from fitting the censored
  individual `t_coma` times. Censored time-to-coma and hurdle productivity
  remain unsupported and are routed to bayesTLS.
- **R-SHRIMP is handled at `standardize_data()` time.** freqTLS vendors the raw
  CSV mortality *proportion* (`Mortality_after_trial`) with
  `N_individuals_after_trial`, not baked-in counts.
  `standardize_data(mortality = "Mortality_after_trial")` reconstructs the death
  counts as `round(mortality_prop * total)` at fit time. This sidesteps the
  upstream collapse in `bayesTLS::shrimp_lethal`, which floors mortality to {0, 1}
  (sum 35) where the CSV implies 0..11 (sum 738) — 86 rows were zeroed upstream.
  The vendored proportion spans the real mortality range, verified against the CSV.

Benchmark-cache limitations:

- The existing bayesTLS + two-stage benchmark cache is a retained **internal
  legacy cache**, not current empirical teaching evidence. It
  (`inst/extdata/bayesTLS_benchmark_cache.rds`) covers shrimp, zebrafish (per
  stage), and *D. suzukii* (per sex), freshly rebuilt against `bayesTLS` 1.0.0
  commit `578740f20f3a2e6e81b3b700b1d0f0e5a06ecf8a` + CmdStan 2.36 via the
  maintainer-run `data-raw/build_benchmark_cache.R`. The rebuild is a maintainer
  step because bayesTLS + CmdStan must not be a CI dependency; the script is
  guarded and stops when they are absent. Snow-gum-derived rows and metadata
  were excluded from the rebuild on 2026-07-11 for licensing. The cache's
  `freqTLS_note` records the historical live-fit/comparator contract. The
  `test-benchmark-sanity` tripwire covers only those retained configurations.
  The canonical six-unit comparator cache is now published at
  `inst/extdata/canonical_bayesTLS_cache.rds` and covers the five endpoints plus
  the all-age aphid extension. It contains Bayesian summaries and diagnostics;
  the comparison article refits freqTLS live and reports actual point
  differences. Its Snow-gum rows use the locked shared-shape analogue, not the
  richer shape terms displayed in the pinned supplement. Drosophila mortality
  compares only the absolute 240-minute LT50 point because the direct freqTLS
  `z` coordinate is a relative-threshold estimand.

## Out of scope for experimental v0.2

- Time-to-event responses; multi-trait responses.
- **Fitting** heat-injury / repair sub-models (belongs to `bayesTLS`);
  deterministic heat-injury **prediction** from the fitted curve is retained in
  experimental v0.2 (see "Heat-injury prediction" below).
- An absolute-threshold default (the default is the relative threshold).
- Correlated, random-slope, crossed, nested, or `up` random effects.
- Universal profile intervals for `up`, variance components, or general
  continuous shape slopes.

General distributional regression belongs to `drmTMB`. The full Bayesian
workflow, heat-injury models, and posterior inference belong to `bayesTLS`.

## Inference caveats (the honest ship stance)

The profile likelihood gives fast, prior-free, asymmetry-respecting confidence
intervals when the MLE is interior and the data identify the target. For boundary
asymptotes, very sparse designs, overdispersion concentrated at zero, or random
effects, the profile may not close; freqTLS warns when you are in that regime
and falls back to a prior-free parametric bootstrap (`confint(fallback = TRUE)`,
the default). If too few refits converge, the interval is `NA` with
`conf.status = "bootstrap_unstable"`; freqTLS does not fabricate bounds. You can
also prefer `bayesTLS` there. freqTLS never claims the profile is universally
superior to the Bayesian path. CTmax extrapolated beyond the duration span is
flagged and shaded.

**Beta-binomial dispersion (weak `phi`).** When overdispersion is mild (`phi`
large, the data near the binomial limit) `phi` is weakly identified and its
estimate runs away. The *profile* interval for `CTmax` / `z` then under-covers — it
profiles the runaway `phi` out to the binomial limit and goes too narrow:
empirical 95% coverage of `z` falls to ~0.65 in the worst regime, while the
**Wald** interval stays near 0.93 and the bootstrap is intermediate (~0.89).
`fit_tls()` warns when `phi`'s relative SE exceeds 1 and points to
`confint(method = "wald")`. This is not a clamping artefact; see
`data-raw/beta-binomial-phi-study.R`.

## Random effects (experimental v0.2 capability)

Single random intercepts on `CTmax`, `log_z`, `low`, and `log_k`,
`<param> ~ <fixed> + (1 | group)`, are fitted by TMB's Laplace
approximation. Caveats:

- `sigma_CTmax` / `sigma_logz` / `sigma_low` / `sigma_logk` are maximum-likelihood
  variance components, biased **low** with few groups (no REML correction); treat
  them cautiously below ~5–8 groups. They live on each coordinate's internal scale:
  `sigma_CTmax` in °C, `sigma_logz` a SD on `log(z)` (a multiplicative spread on
  `z` — read `exp(sigma_logz)`), `sigma_low` a SD on `logit(low)`, `sigma_logk` a
  SD on `log(k)` — none are natural-scale SDs except `sigma_CTmax`. The shape REs
  (`low` / `log_k`) are more weakly identified than `CTmax` and need data that
  informs the asymptote / steepness per group.
- Random effects are supported on `CTmax`, `log_z`, `low`, and `log_k` only — not
  the upper asymptote `up` (the compiled objective has no random-intercept term for
  it), no random slopes, one grouping factor per sub-parameter.
- Placing random intercepts on the **same** grouping factor for two or more
  coordinates fits **independent** variances (correlation forced to zero) and
  **warns**; any true correlation between the group-level deviations is absorbed
  into the marginal SDs and the fixed-effect intervals. A correlated multivariate
  random effect is out of scope — use `bayesTLS`. A `log_z` (or shape) RE and a
  beta-binomial `phi` can also trade off.

`ranef()` returns the per-term BLUPs (term column) and the variance
components get log-scale Wald intervals. `confint(method = "profile")` and
`profile()` profile the fixed-effect coordinates under the random effect(s)
(re-running the Laplace at each grid point with all active blocks);
the variance components stay on Wald under the profile method (no profile
coordinate), the non-closing fallback uses Wald, and the Confidence Eye stays on
Wald for speed; a prior-free RE-aware bootstrap (`method = "bootstrap"`) redraws
every block's deviations and refits, giving variance-component intervals (slow — a
Laplace refit per replicate). The no-RE path is byte-identical to the
fixed-effects model. See `docs/design/08-random-effects.md`.

For direct survival prediction, `predict(..., re.form = "population")` sets the
random intercepts to zero and `re.form = "conditional"` adds fitted BLUPs for
known groups supplied in `newdata`. Omitting `re.form` warns and returns the
population prediction; missing or unseen conditional groups stop. The
specialised surface, lethal-time, critical-temperature, and heat-injury helpers
remain population-level for random-effects fits. General continuous fixed
designs on `CTmax`/`log_z` are rebuilt by `predict()` from `newdata`; specialised
grid helpers do not yet accept arbitrary covariate settings.

## Beta family (experimental v0.2 capability)

The `beta` family (`family = "beta"`, `family_code = 2`) fits a continuous
proportion response `y` in `(0, 1)` directly, `y ~ Beta(p * phi, (1 - p) * phi)`,
using the same 4PL mean curve and the same `phi` convention as the beta-binomial.
No trials column `n` is required (a dummy is supplied internally and ignored by
the likelihood); pass the proportion as `y` in the column interface, or a
bare-name response (`prop ~ time(duration) + temp(temp)`) in the formula
interface. Caveats: the beta density is undefined at exactly `0` and `1`, so
boundary responses are clamped inward to `(1e-6, 1 - 1e-6)` with a warning (model
genuine zero/one inflation with the beta-binomial or a different tool); the
likelihood assumes the dispersion `phi` is constant across the curve. Point
estimates, Wald, profile (including a `phi` profile), and parametric-bootstrap
intervals are all available, and grouped `CTmax`/`z` work. The count families are
byte-identical to before. See `docs/design/02-family-registry.md`.

## Heat-injury prediction (experimental v0.2 capability)

`predict_heat_injury()` is a deterministic predictor, not a fitted model: it
accumulates thermal damage from the already-fitted 4PL under a user-supplied
temperature trace and reads survival back off the curve (the ML analogue of
`bayesTLS::predict_heat_injury()`). Boundary: *fitting* injury / repair dynamics
stays a `bayesTLS` concern; freqTLS only *predicts* from its fitted curve.
One lethal dose maps to the **relative** midpoint survival by default
(`LT(T) = tref * 10^((CTmax - T) / z)`); supplying `target_surv` instead defines
the lethal dose at an **absolute** survival threshold, shifting the lethal time
and the dose-to-survival map by `qlogis((target_surv - low) / (up - low)) / k`
(the same threshold convention as `derive_ctmax()` / `derive_lt()`). Remaining
caveats: the trace `time` and the fit's `tref` / duration must share a time unit;
integration is forward Euler over the actual per-step increments; and the
optional Sharpe-Schoolfield `repair` parameters are a user-supplied scenario
layer that is **not identified** by the survival data (a warning is emitted when
repair is used).

## Grouped shape parameters (experimental v0.2 capability)

`low`, `up`, and `log_k` may vary by a grouping factor via the formula interface
(`low ~ group`, `up ~ group`, `log_k ~ group`), relaxing the midpoint-only
invariant (see `docs/dev-log/decisions.md`, 2026-06-17). The engine carries
per-sub-parameter design matrices; the intercept-only default is byte-identical
to the shared-shape model. Since the continuous-covariate work, each shape may
carry its **own** design independently (a grouping factor OR a continuous
covariate OR an intercept), no longer required to share one design or match the
`CTmax` / `log_z` grouping. The grouped shape coordinates `low:<g>` and `k:<g>`
get profile, Wald, and bootstrap intervals; `up:<g>` is not yet profiled
(disjoint-bounds `beta_up`), so it uses the delta-method Wald (like the scalar `up`) and
the bootstrap. A general (continuous) shape coefficient (`k:body_size`) is
reported on its link scale (a log-scale slope) with a Wald interval; profiling a
single continuous slope routes to Wald (no group level to address), and
`predict()` rebuilds the shape design from `newdata`. The benchmark against
bayesTLS still uses the shared-shape (constant-shape) configuration.
