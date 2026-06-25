# Capability Matrix (Missing-Cell Audit)

This is the missing-cell audit for freqTLS: the authoritative grid of what is
fitted, planned, and unsupported. It is kept synchronized with
`docs/dev-log/known-limitations.md`, `README.Rmd`, `ROADMAP.md`, and `NEWS.md` in
the same commit when a capability changes (AGENTS.md design rule 10). The live
phase status is on the dashboard (`docs/dev-log/dashboard/status.json`).

> **bayesTLS-twin redesign (completed; released as 0.1.0).** freqTLS has been rebuilt
> as the frequentist twin of bayesTLS. The user-facing API is now
> `standardize_data()` -> `fit_4pl()` -> `tls()` / `extract_tdt()` /
> `predict_survival_curves()` / `diagnose_tdt_fit()`, with `two_stage` as the
> classical comparator; the profileTLS names (`fit_tls`, `tidy_parameters`,
> `get_ctmax`, ...) remain as the internal engine and still work. The
> family x design x CI engine grid below still holds (now on disjoint-bounds
> asymptotes); this audit grid is rewritten to the twin API at finalization
> (benchmark + vignettes). See `NEWS.md` and
> `docs/dev-log/recovery-checkpoints/2026-06-24-autonomous-session-handoff.md`.

## v0.1 core grid: family x design x CI

The v0.1 surface is the full cross-product of two families, two designs, and two
CI methods: **all 8 cells are fitted in v0.1** (on completion of Phases 1-3).

| Family | Design | Wald CI | Profile CI |
| --- | --- | --- | --- |
| binomial | ungrouped | v0.1 | v0.1 |
| binomial | grouped (`~ 0 + group`) | v0.1 | v0.1 |
| beta-binomial | ungrouped | v0.1 | v0.1 |
| beta-binomial | grouped (`~ 0 + group`) | v0.1 | v0.1 |

"v0.1" means planned for the v0.1 release and fitted when its phase lands with
tests, docs, examples, a check-log entry, and an after-task report. As of
2026-06-16 (Phase 6) all of these have landed under the Definition of Done; the
live phase board is `docs/dev-log/dashboard/status.json`.

## Status of each capability (Phase 6)

| Capability | Engine | R API | Point | Wald | Profile | Bootstrap |
| --- | --- | --- | --- | --- | --- | --- |
| binomial, ungrouped | fitted (P1) | fitted (P1) | fitted (P1) | fitted (P3) | fitted (P3) | fitted (v0.2) |
| binomial, grouped | fitted (P1) | fitted (P2) | fitted (P2) | fitted (P3) | fitted (P3) | fitted (v0.2) |
| beta-binomial, ungrouped | fitted (P1) | fitted (P1) | fitted (P1) | fitted (P3) | fitted (P3) | fitted (v0.2) |
| beta-binomial, grouped | fitted (P1) | fitted (P2) | fitted (P2) | fitted (P3) | fitted (P3) | fitted (v0.2) |
| beta, ungrouped | fitted (v0.2) | fitted (v0.2) | fitted (v0.2) | fitted (v0.2) | fitted (v0.2) | fitted (v0.2) |
| beta, grouped | fitted (v0.2) | fitted (v0.2) | fitted (v0.2) | fitted (v0.2) | fitted (v0.2) | fitted (v0.2) |
| Confidence-Eye display | fitted (P4) | fitted (P4) | -- | -- | fitted (P4) | -- |
| bayesTLS benchmark (relative, constant shape) | fitted (P5) | fitted (P5) | fitted (P5) | fitted (P5) | fitted (P5) | cache built (v0.2) |

### Interfaces

Both interfaces map to the same engine and produce numerically identical fits:

| Interface | Status | Notes |
| --- | --- | --- |
| column (tidy-eval `y`/`n`/`time`/`temp`/`group`) | fitted (P1-P2) | the original interface; unchanged |
| formula (`tls_bf()` -> `fit_tls()`) | fitted | brms/drmTMB-style grammar; `CTmax`/`log_z` fixed-effect predictors; v0.1 shapes are intercept-only and random effects are deferred to v0.2 |

## v0.2 milestone (released in 0.1.0)

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
- bayesTLS benchmark cache: **built** from the real `bayesTLS` 1.0.0 + classical
  two-stage fits (`inst/extdata/bayesTLS_benchmark_cache.rds`), covering all four
  case-study datasets (shrimp, zebrafish per stage, and *D. suzukii* per sex as
  three-ways; snow-gum PSII as a beta two-way with no count two-stage).
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
- Random intercepts on `CTmax` (v0.2) and on `log_z` / `low` / `log_k` (v0.3)
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

## Planned (post-v0.1) and non-goals

- Random effects beyond single intercepts on `CTmax` / `log_z` / `low` / `log_k`
  (random slopes, a RE on the upper asymptote `up`, a second / crossed grouping
  factor on one sub-parameter, and correlated multivariate random effects across
  coordinates). These need a stacked-random-vector engine redesign; `bayesTLS` is
  the path for a correlated random structure. The single intercepts on `CTmax` /
  `log_z` / `low` / `log_k` -- with profile intervals for the fixed effects and a
  prior-free RE-aware bootstrap for the variance components -- are fitted.
- Beta / continuous responses: **fitted in v0.2** (`family = "beta"`), with the
  vendored `snowgum_psii` dataset (retained PSII proportion, CC BY 4.0) as the
  real-data showcase.
- Time-to-event responses: non-goal (the wider TDT literature is largely
  failure-time data; the 4PL count/proportion model is the wrong tool for it).
- Multi-trait responses (dsuzukii): non-goal.
- **Fitting** heat-injury / repair sub-models (estimating injury or repair
  dynamics as part of the likelihood): non-goal (belongs to bayesTLS).
  Deterministic heat-injury **prediction** from the already-fitted curve is
  fitted in v0.2 (`predict_heat_injury()`; see the v0.2 section).
- Grouped effects on `low`, `up`, `log_k`: **fitted in v0.2** (see the v0.2
  section). General continuous covariates on the shapes are **also fitted** (each
  shape carries its own independent design; link-scale coefficients + Wald).
- Absolute-threshold default: non-goal (the default is relative).
- A formula interface (`tls_bf()`): **fitted in v0.1** (a thin front-end to the
  column interface). Predictors on `low`/`up`/`k`, independent `CTmax` / `log_z`
  designs, and random effects through it are deferred to v0.2.
- CRAN hardening: non-goal for v0.1.

## Risk register cross-reference

The risks that shape these cells are R-SHRIMP (vendored shrimp counts),
R-STALE (cache drift), R-IDENT (sparse-mortality non-identifiability), R-RELABS
(relative vs absolute threshold), R-UNITS (time/`tref` mismatch), R-EXTRAP
(CTmax extrapolation), R-PHI (phi convention), R-LICENSE (CC-BY attribution),
R-PROFILE (non-closing profile), and R-POSTERIOR (a figure implying a posterior).
See `SPEC.md` section 14 for the full register and mitigations.
