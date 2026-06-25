# Known Limitations

This is the authoritative fitted / planned / unsupported boundary for
freqTLS, indexed by capability. It mirrors the missing-cell audit in
`docs/design/46-capability-matrix.md`. Keep it synchronized with `README.Rmd`,
`ROADMAP.md`, `NEWS.md`, and the capability matrix in the same commit when a
capability changes.

> **bayesTLS-twin redesign (in progress, 2026-06-24).** The package is being
> rebuilt as the frequentist twin of bayesTLS (new API:
> `standardize_data`/`fit_4pl`/`tls`/`extract_tdt`/`predict_survival_curves`/
> `diagnose_tdt_fit`/`two_stage`; disjoint-bounds asymptotes). Current twin
> limitations: `fit_4pl` fixes `bounds = c(0, 1)` and fits the relative backbone
> (absolute/LTx and T_crit are derived post-hoc via `extract_tdt`/`tls` bootstrap,
> not profiled); `extract_tdt` bands are bootstrap (slower than the relative
> profile path); the benchmark cache and case-study vignettes are stale
> (profileTLS-format) and rebuilt at finalization. The profileTLS limitations
> below still describe the shared engine. See `NEWS.md` and the handoff in
> `docs/dev-log/recovery-checkpoints/`.

## Current status: Phase 6 (docs and pkgdown site; v0.1 surface complete)

As of 2026-06-16 the full v0.1 surface is implemented and tested. The TMB 4PL
engine, `fit_tls()`, and `simulate_tls()` (Phase 1); the S3 method surface
(`print`/`summary`/`coef`/`vcov`/`logLik`/`AIC`/`nobs`) and the tidy extractors
(`tidy_parameters()`, `get_ctmax()`, `get_z()`, `get_shape()`) (Phase 2); the
profile-likelihood machinery (`profile()`, `confint(method = "profile")`), the 12
identifiability warnings, and the eye-style profile plot (Phase 3); prediction
(`predict()`, `predict_survival_surface()`, `derive_lt()`) and the Confidence-Eye
and curve/surface plots (Phase 4); the R-SHRIMP-corrected `shrimp_lethal` and
`zebrafish_lethal` datasets and the benchmark harness (Phase 5); and the README,
four vignettes, NEWS, and finalised pkgdown site (Phase 6) are all landed with
tests, documentation, examples, check-log entries, and after-task reports
(Definition of Done). The single remaining gap is the maintainer-built bayesTLS +
two-stage benchmark **cache** (needs Stan; see "Benchmark data and cache" below).
The capabilities below are the v0.1 boundary; "fitted" means landed under the
Definition of Done.

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
link scale). The upper asymptote `up` has no single internal coordinate under the
nested-gap parameterisation, so it is reported with a delta-method **Wald**
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
column fit to optimiser tolerance. v0.1 restrictions: fixed predictors on `low` / `up` / `log_k`
are rejected with a helpful error (shape coordinates are shared scalars), and
`CTmax` and `log_z` must share the same fixed right-hand side. Random-effect bars
(`(1 | block)`), deferred at v0.1, are supported from v0.2 as independent random
*intercepts* on `CTmax` / `log_z` / `low` / `log_k`; random slopes, correlated
random effects, and crossed/nested grouping remain out of scope (use `bayesTLS`). The grouped-by-
factor case (`CTmax ~ group`) is emitted as `~ 0 + group` so its design, labels,
and fit are byte-identical to the column `group =` call. Single-factor formula
grouping (`CTmax ~ group`) reconstructs the per-row grouping vector, so the
group-aware data-adequacy warnings, `diag_data`, and `plot_survival_curves()`
match the column interface. (A general multi-predictor `CTmax` design has no
single grouping label, so it carries none; general continuous predictors are not
yet supported.)

## Planned for v0.1 (fitted on completion of Phases 1-6)

The v0.1 surface is the full cross-product of two families, two designs, and two
CI methods, all eight cells fitted:

- families: `binomial` and `beta_binomial` (overdispersion `phi`), count data
  only;
- designs: ungrouped, and grouped via `~ 0 + group` on `CTmax` and `log_z`
  (per-group `CTmax_g`, `z_g`, shared `low`, `up`, `k`);
- CI methods: Wald and profile likelihood.

Additional planned v0.1 capability:

- the temperature effect through the midpoint only (constant shape), matching the
  bayesTLS benchmark configuration;
- profile-likelihood compatibility intervals for `CTmax`, `z`, `low`, `k`, `phi`,
  with `up` via native re-rooting (or a Wald/delta fallback) and group contrasts
  `dCTmax`, `dlog_z`;
- the 12 identifiability warnings (emitted, never silent);
- Confidence-Eye uncertainty plots (the default), survival curves, the thermal
  death-time curve, and the survival surface;
- the cached three-way benchmark against bayesTLS and the classical two-stage
  estimator on the vendored `shrimp_lethal` and `zebrafish_lethal` datasets,
  with the shrimp death counts rebuilt from the vendored CSV proportion at
  `standardize_data()` time (R-SHRIMP).

### Benchmark data and cache (Phase 5)

Fitted:

- The vendored datasets `shrimp_lethal` (148 rows, ungrouped, temps 30-33 C) and
  `zebrafish_lethal` (323 rows, grouped by `life_stage`: young_embryos,
  old_embryos, larvae) are built and documented (CC BY 4.0, attribution in
  `R/data.R`, `inst/CITATION`, `inst/COPYRIGHTS`, README). freqTLS fits both
  with sensible estimates (shrimp CTmax 31.8 C / z 2.2 C; zebrafish per-stage
  CTmax 39.8-41.4 C / z ~1.8-2.0 C; both converge, pdHess TRUE, beta-binomial).
- `snowgum_psii` (319 rows, *Eucalyptus pauciflora* PSII; CC BY 4.0) is the
  continuous-proportion dataset for the **beta** family: `prop = final_fvfm /
  initial_fvfm` over six temperatures (28-48 C) and five durations (minutes).
  `fit_tls(family = "beta", tref = 5)` recovers CTmax ~46.5 C / z ~6.5
  (converges, pdHess TRUE). 60 complete-loss rows sit at `prop == 0` and are
  clamped inward by the beta likelihood (with a warning); the raw proportion is
  vendored unchanged.
- `dsuzukii` (1407 rows, per-individual *Drosophila suzukii* mortality by sex with
  a 0/1 `dead` indicator; CC BY 4.0, Ørsted et al. 2024, Zenodo
  10.5281/zenodo.10602268) is the lethal endpoint. Aggregating to `(temp, time,
  sex)` cells and fitting `fit_4pl`/`fit_tls(group = sex, family =
  "beta_binomial", tref = 240)` (240 min = 4 h, absolute threshold) recovers the
  published per-sex CTmax ~35.2 C and z ~3.0/3.2 (conv 0). The sublethal heat-coma
  and productivity endpoints are non-goals (time-to-event / hurdle models); only
  the per-individual lethal data are vendored.
- **R-SHRIMP is handled at `standardize_data()` time.** freqTLS vendors the raw
  CSV mortality *proportion* (`Mortality_after_trial`) with
  `N_individuals_after_trial`, not baked-in counts.
  `standardize_data(mortality = "Mortality_after_trial")` reconstructs the death
  counts as `round(mortality_prop * total)` at fit time. This sidesteps the
  upstream collapse in `bayesTLS::shrimp_lethal`, which floors mortality to {0, 1}
  (sum 35) where the CSV implies 0..11 (sum 738) — 86 rows were zeroed upstream.
  The vendored proportion spans the real mortality range, verified against the CSV.

Not yet available (limitations):

- **The bayesTLS + two-stage benchmark cache
  (`inst/extdata/bayesTLS_benchmark_cache.rds`) is built and covers all four
  case-study datasets** — shrimp, zebrafish (per stage), *D. suzukii* (per sex),
  and snow-gum PSII — rebuilt against `bayesTLS` 1.0.0 + CmdStan 2.36 via the
  maintainer-run `data-raw/build_benchmark_cache.R`. The rebuild is a maintainer
  step because bayesTLS + CmdStan must not be a CI dependency; the script is
  guarded and skips when they are absent. **Residual limitation:** snow-gum PSII
  has **no classical two-stage column** — it is a continuous proportion with no
  count representation, so that case study is an honest two-way (`bayesTLS` beta
  vs `freqTLS`) rather than a three-way. The `test-benchmark-sanity` tripwire
  covers shrimp and zebrafish; extending it to the *D. suzukii* (tref 240 min,
  grouped by sex) and snow-gum (beta, tref 5 min) configurations is a follow-up.

## Out of scope for v0.1 (non-goals; not to be described as implemented)

- Beta / continuous responses: not in v0.1; **fitted in v0.2** (`family =
  "beta"`, see "Beta family" below).
- Time-to-event responses; multi-trait responses.
- **Fitting** heat-injury / repair sub-models (belongs to `bayesTLS`);
  deterministic heat-injury **prediction** from the fitted curve is fitted in
  v0.2 (see "Heat-injury prediction" below).
- An absolute-threshold default (the default is the relative threshold).
- Random effects; a formula DSL.
- Bootstrap confidence intervals (planned later, not v0.1).
- CRAN hardening.

General distributional regression belongs to `drmTMB`. The full Bayesian
workflow, heat-injury models, and posterior inference belong to `bayesTLS`.

## Inference caveats (the honest ship stance)

The profile likelihood gives fast, prior-free, asymmetry-respecting confidence
intervals when the MLE is interior and the data identify the target. For boundary
asymptotes, very sparse designs, overdispersion concentrated at zero, or (future)
random effects, the profile may not close; freqTLS warns when you are in that
regime and, since v0.2, falls back to a prior-free parametric bootstrap
(`confint(fallback = TRUE)`, the default) so an interval is still returned -- the
same "always returns an interval" behaviour as the Bayesian path. You can also
prefer `bayesTLS` there. freqTLS never claims the profile is universally
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

## Random effects (v0.2 CTmax; v0.3 log_z / low / log_k)

Single random intercepts on `CTmax` (v0.2) and on `log_z`, `low`, and `log_k`
(v0.3), `<param> ~ <fixed> + (1 | group)`, are fitted by TMB's Laplace
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
  the upper asymptote `up` (its nested gap has no single coordinate), no random
  slopes, one grouping factor per sub-parameter.
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

## Beta family (v0.2)

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

## Heat-injury prediction (v0.2)

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

## Grouped shape parameters (v0.2)

`low`, `up`, and `log_k` may vary by a grouping factor via the formula interface
(`low ~ group`, `up ~ group`, `log_k ~ group`), relaxing the midpoint-only
invariant (see `docs/dev-log/decisions.md`, 2026-06-17). The engine carries
per-sub-parameter design matrices; the intercept-only default is byte-identical
to the shared-shape model. Since the continuous-covariate work, each shape may
carry its **own** design independently (a grouping factor OR a continuous
covariate OR an intercept), no longer required to share one design or match the
`CTmax` / `log_z` grouping. The grouped shape coordinates `low:<g>` and `k:<g>`
get profile, Wald, and bootstrap intervals; `up:<g>` has no single coordinate
under the nested gap, so it uses the delta-method Wald (like the scalar `up`) and
the bootstrap. A general (continuous) shape coefficient (`k:body_size`) is
reported on its link scale (a log-scale slope) with a Wald interval; profiling a
single continuous slope routes to Wald (no group level to address), and
`predict()` rebuilds the shape design from `newdata`. The benchmark against
bayesTLS still uses the shared-shape (constant-shape) configuration.
