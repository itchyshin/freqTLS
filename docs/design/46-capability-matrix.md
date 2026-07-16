# Capability Matrix (Missing-Cell Audit)

This is the missing-cell audit for freqTLS: the authoritative grid of what is
fitted, planned, and unsupported. It is kept synchronized with
`docs/dev-log/known-limitations.md`, `README.Rmd`, `ROADMAP.md`, and `NEWS.md` in
the same commit when a capability changes (AGENTS.md design rule 10). The live
phase status is on the dashboard (`docs/dev-log/dashboard/status.json`).

> **Experimental 0.2.0.9000 teaching contract.** Active empirical cases mirror
> the pinned bayesTLS supplement: `zebrafish_o2`, `aphid_tdt`, `snowgum_psii`,
> and the mortality and awake/coma endpoints from `dsuzukii`. Brown shrimp and
> life-stage zebrafish remain benchmark-only legacy fixtures, not active
> examples. Censored-time, hurdle-productivity, and fitted repair dynamics are
> unsupported/bayesTLS-only. Every implemented cell below remains experimental.

> **Historical 0.1.0 source surface.** freqTLS is the frequentist analogue of bayesTLS;
> this describes the implemented package source and is not a claim that 0.1.0
> has been submitted to or published by CRAN. The user-facing API is
> `standardize_data()` -> `fit_4pl()` -> `tls()` / `extract_tdt()` /
> `predict_survival_curves()` / `diagnose_tdt_fit()`, with `two_stage` as the
> classical comparator; the profileTLS names (`fit_tls`, `tidy_parameters`,
> `get_ctmax`, ...) remain as the internal engine and still work. The matrices
> below state the current family, design, interval, and target-specific limits.

## 0.2.0.9000 family x design x interval grid

For the ordinary curve parameters, the current experimental source implements the full cross-product of
three families, ungrouped/grouped designs, and Wald/profile/bootstrap confidence
intervals. `beta` consumes a continuous proportion in `(0, 1)`; the two count
families consume successes/trials. “Yes” means implemented with tests and
documentation in the package source.

| Family | Design | Point | Wald | Profile | Bootstrap |
| --- | --- | --- | --- | --- | --- |
| binomial | ungrouped | yes | yes | yes | yes |
| binomial | grouped | yes | yes | yes | yes |
| beta-binomial | ungrouped | yes | yes | yes | yes |
| beta-binomial | grouped | yes | yes | yes | yes |
| beta | ungrouped | yes | yes | yes | yes |
| beta | grouped | yes | yes | yes | yes |

Grouped means per-group `CTmax` and `log_z` through the column interface or
formula designs, with shared shapes by default. `CTmax` and `log_z` must produce
the same fixed-effect design columns, although their random-intercept groupings
may differ. The formula interface also allows independent fixed designs on
`low`, `up`, and `log_k`, including
continuous covariates, subject to the target-specific routing below.

## Target-specific interval routing

The family grid does not imply that every target is profiled. freqTLS reports
the actual interval route in `interval_type` and `conf.status` rather than
silently presenting a fallback as a profile interval.

| Target | Point | Wald | Profile request | Bootstrap | Important boundary |
| --- | --- | --- | --- | --- | --- |
| `CTmax`, `z`/`log_z`, intercept or factor-level `low`, `k`/`log_k` | yes | yes | likelihood profile | yes | a non-closing profile may use the documented bootstrap fallback |
| `phi` (beta-binomial or beta) | yes | yes | likelihood profile | yes | weak dispersion identification can make profile coverage poor; with a weak beta-binomial `phi`, default fallback routes `CTmax`/`z` to Wald |
| upper asymptote `up` | yes | delta-method | Wald fallback (`conf.status = "wald_fallback"`) | yes | the disjoint-bounds `beta_up` coordinate is not profiled |
| general continuous shape slopes | yes | yes | Wald fallback | yes | no universal profile coordinate for these slopes |
| random-effect fixed effects | yes | yes | likelihood profile with Laplace rerun | yes | a non-closing profile falls back to Wald; the Confidence Eye uses Wald for speed |
| variance components | yes | log-scale Wald | Wald under a profile request | RE-aware bootstrap | no variance-component profile coordinate |
| absolute/LTx and `T_crit` derived quantities | yes | not universal | not profiled | yes | deterministic post-fit transforms; relative `CTmax` remains the fitted coordinate |
| group contrasts `dCTmax`, `dlog_z` | yes | yes | yes | yes | contrast profiles are for fixed-effect grouped fits; they are rejected for random-effect fits |

The Confidence Eye visualizes the interval actually used; it is never a
posterior density. The relative-threshold, constant-shape benchmark is a
separate matched comparator configuration and does not expand these fitting
claims.

### Interfaces

Both interfaces map to the same engine and produce numerically identical fits:

| Interface | Status | Notes |
| --- | --- | --- |
| column (tidy-eval `y`/`n`/`time`/`temp`/`group`) | fitted (P1-P2) | the original interface; unchanged |
| formula (`tls_bf()` -> `fit_tls()`) | fitted | brms/drmTMB-style grammar; `CTmax` and `log_z` share fixed design columns, while `low`, `up`, and `log_k` have independent fixed designs; one limited independent random intercept on `CTmax`, `log_z`, `low`, or `log_k` per coordinate |

## Historical build milestones retained in experimental 0.2.0.9000

- Covariate (grouped) effects on the shape parameters (`low` / `up` / `log_k`):
  **fitted** -- via the formula interface (`low ~ group`, `up ~ group`,
  `log_k ~ group`), relaxing the midpoint-only invariant. The engine carries
  per-sub-parameter design matrices, so the intercept-only default is
  byte-identical. Per-group estimates with profile, Wald, and bootstrap intervals
  (`low:<g>` / `k:<g>` profile; `up:<g>` delta-method Wald; all via the bootstrap)
  and per-group `predict()`. Since the continuous-covariate work each shape may
  carry its OWN design independently (factor, continuous covariate, or intercept),
  no longer required to share one design or match `CTmax` / `log_z`. A general
  (continuous) shape coefficient (`k:body_size`) is a link-scale slope with a Wald
  interval (profile routes to Wald); `predict()` rebuilds the design from
  `newdata`. See `docs/dev-log/decisions.md` (2026-06-17).
- Heat-injury prediction (`predict_heat_injury()`): **fitted** -- the
  deterministic ML analogue of `bayesTLS::predict_heat_injury()`. Accumulates
  thermal damage from the fitted curve under a temperature trace (forward Euler,
  per-step increments) as a fraction of the lethal dose, reads survival back off
  the 4PL (one lethal dose -> the **relative** midpoint survival by default, or
  an **absolute** survival threshold via `target_surv`), with an optional
  damage cutoff `t_c` and an optional Sharpe-Schoolfield `repair` layer (flagged
  as not identified by the data). This *predicts* injury from the fitted curve;
  *fitting* injury/repair models stays a `bayesTLS` concern (see non-goals).
  Uncertainty: `heat_injury_envelope()` adds a prior-free parametric-bootstrap
  confidence band around the trajectory (the likelihood-path analogue of the
  `bayesTLS` posterior band), and `plot_heat_injury()` draws it; both reuse the
  same dose-accumulation integrator as `predict_heat_injury()` (v0.3).
- Beta (continuous-proportion) family (`family = "beta"`, `family_code = 2`):
  **fitted** -- models a response proportion in `(0, 1)` directly with
  `y ~ Beta(p * phi, (1 - p) * phi)`, no trials `n` required (a dummy is supplied
  internally and ignored by the likelihood). Point estimates, Wald, profile
  (including `phi`), and parametric-bootstrap intervals all work, and grouped
  `CTmax`/`z` are supported. The column interface takes the proportion as `y`;
  the formula interface takes a bare-name response
  (`prop ~ time(duration) + temp(temp)`). See
  `docs/design/02-family-registry.md`.
- Parametric bootstrap confidence intervals: **fitted** -- prior-free, available
  as `confint(method = "bootstrap")` and as the automatic fallback for a
  non-closing profile or a non-positive-definite Hessian (`fallback = TRUE`, the
  default). Rendered as a distinct lens in the Confidence Eye. See
  `docs/design/04-profile-likelihood.md`.
- Canonical bayesTLS comparator cache: **built and independently published**
  from pinned bayesTLS commit `76510412` on Totoro
  (`inst/extdata/canonical_bayesTLS_cache.rds`; SHA-256
  `3b04bb161250abb1628e3018ff25648984b7c6a4131272e6e9c0557b15c3b2f0`).
  It covers all six locked analysis units, records exact hashes/formulas/
  thresholds/versions/seeds and passed sampler diagnostics, and is displayed
  beside live freqTLS fits with actual point differences. The older shrimp and
  life-stage-zebrafish cache remains internal legacy evidence only.
- Multicore bootstrap (`cores`): **fitted** -- forked refits, reproducible
  regardless of cores.
- `derive_ctmax()`: absolute-threshold critical temperature (closed-form inverse
  of the 4PL; the `bayesTLS` absolute-mode analogue, with the asymmetry
  correction). The default reproduces `CTmax`.
- `derive_tcrit()`: the rate-multiplier critical temperature
  `T_crit = CTmax + z * log10(rate / 100)` (the `bayesTLS` `extract_tdt()`
  rate-floor analogue), a deterministic transform of the fitted `CTmax`/`z`.
  Lethal-endpoint only; `rate` is a fixed input (freqTLS does not sample it,
  unlike the Bayesian path). This completes the `extract_tdt()` absolute family.
- Random intercepts on `CTmax`, `log_z`, `low`, and `log_k`
  (`<param> ~ <fixed> + (1 | group)`): **fitted** -- TMB Laplace, no-RE path
  byte-identical; `sigma_CTmax` (°C) / `sigma_logz` (SD on `log z`) / `sigma_low`
  (SD on `logit low`) / `sigma_logk` (SD on `log k`), all ML and biased low with
  few groups, with log-scale Wald intervals; `ranef()` BLUPs per term;
  profile-likelihood intervals for the fixed effects under the RE(s) (Laplace re-run
  at each grid point; the Confidence Eye stays on Wald for speed); and a prior-free
  RE-aware bootstrap (`method = "bootstrap"`) that redraws each block's deviations
  and refits. Any subset combines (same or different grouping); sharing a grouping
  factor fits independent variances and warns. The upper asymptote `up` is excluded
  (the compiled objective has no random-intercept term for `up`). See
  `docs/design/08-random-effects.md`.
- Random-effect prediction: **fitted** -- `predict(..., re.form = "population")`
  sets random intercepts to zero; `re.form = "conditional"` adds fitted BLUPs
  for known grouping levels supplied in `newdata`. Omitting `re.form` warns and
  returns the population prediction. Specialised surface, lethal-time,
  critical-temperature, and heat-injury helpers are population-level for
  random-effects fits.

## Unsupported or planned after experimental v0.2

- Random effects beyond single intercepts on `CTmax` / `log_z` / `low` / `log_k`
  (random slopes, a RE on the upper asymptote `up`, a second / crossed grouping
  factor on one sub-parameter, and correlated multivariate random effects across
  coordinates). These need a stacked-random-vector engine redesign; `bayesTLS` is
  the path for a correlated random structure. The single intercepts on `CTmax` /
  `log_z` / `low` / `log_k` -- with profile intervals for the fixed effects and a
  prior-free RE-aware bootstrap for the variance components -- are fitted.
- Beta / continuous responses: **fitted in v0.2** (`family = "beta"`). The
  simulated parameter-recovery tests and the Snow-gum development example
  demonstrate this capability. The processed Snow-gum object and vignette are
  installed/rendered only for the authorized non-commercial GitHub/pkgdown
  development use; CRAN and commercial redistribution remain blocked.
- Time-to-event responses: non-goal (the wider TDT literature is largely
  failure-time data; the 4PL count/proportion model is the wrong tool for it).
- Multi-trait joint likelihoods remain a non-goal. The aggregated awake/coma
  count endpoint is supported; censored `t_coma` and hurdle `prod` models are
  not.
- **Fitting** heat-injury / repair sub-models (estimating injury or repair
  dynamics as part of the likelihood): non-goal (belongs to bayesTLS).
  Deterministic heat-injury **prediction** from the already-fitted curve is
  fitted in v0.2 (`predict_heat_injury()`; see the v0.2 section).
- Grouped effects on `low`, `up`, `log_k`: **fitted in v0.2** (see the v0.2
  section). General continuous covariates on the shapes are **also fitted** (each
  shape carries its own independent design; link-scale coefficients + Wald).
- Absolute-threshold default: non-goal (the default is relative).
- A formula interface (`tls_bf()`): **fitted** (a thin front-end to the column
  interface). Predictors on `low`/`up`/`log_k`, shared-column fixed designs for
  `CTmax` / `log_z`, and the limited random-intercept structures listed above
  are retained in experimental 0.2.0.9000.
- CRAN hardening is release engineering rather than a model capability; this
  matrix does not claim public CRAN availability.

## Risk register cross-reference

The risks that shape these cells are R-SHRIMP (vendored shrimp counts),
R-STALE (cache drift), R-IDENT (sparse-mortality non-identifiability), R-RELABS
(relative vs absolute threshold), R-UNITS (time/`tref` mismatch), R-EXTRAP
(CTmax extrapolation), R-PHI (phi convention), R-LICENSE (CC-BY attribution),
R-PROFILE (non-closing profile), and R-POSTERIOR (a figure implying a posterior).
R-LICENSE is enforced per component by `docs/design/47-data-license-ledger.md`;
there is no package-wide assumption that every upstream dataset is CC BY 4.0.
See `SPEC.md` section 14 for the full register and mitigations.
