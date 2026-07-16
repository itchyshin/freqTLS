# Changelog

## freqTLS 0.2.0.9000

- Rebased the empirical teaching plan on the pinned bayesTLS supplement
  rendered 2026-07-14 (commit
  `76510412e06c594c96894a1baba1f0e1a34a5aea`). Canonical cases are
  oxygen-gradient zebrafish, cereal aphids, Snow-gum PSII, and the
  mortality and awake/coma *Drosophila suzukii* endpoints.
- Brown shrimp and life-stage zebrafish remain installed benchmark-only
  legacy fixtures but are removed from active examples, navigation, and
  current comparison surfaces.
- Retained Beta responses, limited random intercepts, shape formulas,
  deterministic heat-injury prediction, the formula interface, and the
  frequentist interval/diagnostic displays as explicitly experimental.
- Censored-time, hurdle-productivity, fitted repair dynamics, and CRAN
  submission remain out of scope.
- Corrected formula starts so intercept models initialise only their
  intercept while no-intercept cell-mean models initialise every cell.
  Difficult fits may receive a deterministic `nloptr` Newton refinement
  when it improves both the objective and maximum gradient.
- Added row-specific parameter prediction for interacted formula designs
  via `predict(..., type = "parameters")`, including `freq_tls` S3
  dispatch.
- Added the reviewed canonical bayesTLS comparator cache built on Totoro
  from pinned bayesTLS commit `76510412`, with exact analysis hashes,
  sampler diagnostics, source versions, seeds, and a public table of
  actual freqTLS-minus-bayesTLS differences. The historical
  shrimp/life-stage cache remains internal legacy evidence only.
- [`standardize_data()`](https://itchyshin.github.io/freqTLS/dev/reference/standardize_data.md)
  now warns with the affected count and epsilon whenever a continuous
  proportion is moved off 0 or 1 for the Beta likelihood. The Snow-gum
  example makes its 90 adjusted values explicit.

## freqTLS 0.1.0 (unreleased historical candidate)

- Corrected grouped contrast direction so `dCTmax:A-B`, `dlog_z:A-B`,
  and `dz:A-B` now follow their written meaning: group A minus group B.

freqTLS is the frequentist counterpart to the Bayesian **bayesTLS**
package: it fits the four-parameter logistic thermal-load-sensitivity
(thermal death-time) model by maximum likelihood via TMB, parameterised
directly in CTmax and thermal sensitivity (z). Under the matched
relative-threshold, constant-shape configuration, it targets the same
fitted curve as `bayesTLS`; uncertainty is reported through a
frequentist trio — Wald (delta), profile-likelihood, and bootstrap —
instead of a posterior. Forked from **profileTLS** (commit `6f963a9`,
v0.3.3), which it supersedes.

### bayesTLS-analogue API (historical 0.1 surface)

- [`standardize_data()`](https://itchyshin.github.io/freqTLS/dev/reference/standardize_data.md)
  — the shared raw-data entry point for count or continuous-proportion
  responses (adopted from bayesTLS).
- [`fit_4pl()`](https://itchyshin.github.io/freqTLS/dev/reference/fit_4pl.md) +
  [`make_4pl_formula()`](https://itchyshin.github.io/freqTLS/dev/reference/make_4pl_formula.md)
  — the direct CTmax/z formula interface
  (`ctmax`/`z`/`up`/`low`/`k`/`by`, plus `threshold`, `t_ref`, `bounds`,
  `family`), fitted by maximum likelihood through the TMB engine;
  returns a `freq_tls` workflow object.
- [`tls()`](https://itchyshin.github.io/freqTLS/dev/reference/tls.md) /
  [`tls_z()`](https://itchyshin.github.io/freqTLS/dev/reference/tls.md)
  /
  [`tls_ctmax()`](https://itchyshin.github.io/freqTLS/dev/reference/tls.md)
  /
  [`tls_tcrit()`](https://itchyshin.github.io/freqTLS/dev/reference/tls.md)
  — z, CTmax, and T_crit with confidence intervals at the relative
  midpoint, the absolute (LT50) threshold, or any LTx.
- [`extract_tdt()`](https://itchyshin.github.io/freqTLS/dev/reference/extract_tdt.md)
  with `get_z_*` / `get_ctmax_*` / `get_tcrit_*` accessors — the nested
  z / CTmax / T_crit structure, with parametric-bootstrap replicates as
  the frequentist analogue of posterior draws.
- [`predict_survival_curves()`](https://itchyshin.github.io/freqTLS/dev/reference/predict_survival_curves.md)
  — the fitted survival surface with bootstrap bands.
- [`diagnose_tdt_fit()`](https://itchyshin.github.io/freqTLS/dev/reference/diagnose_tdt_fit.md)
  and
  [`tdt_parameter_table()`](https://itchyshin.github.io/freqTLS/dev/reference/tdt_parameter_table.md)
  — convergence diagnostics (optimiser/Hessian/gradient) and the 4PL
  parameter table.
- `two_stage`
  ([`ts_stage1()`](https://itchyshin.github.io/freqTLS/dev/reference/ts_stage1.md)
  /
  [`ts_stage2()`](https://itchyshin.github.io/freqTLS/dev/reference/ts_stage2.md)
  /
  [`ts_ci()`](https://itchyshin.github.io/freqTLS/dev/reference/ts_ci.md)
  /
  [`ts_curve()`](https://itchyshin.github.io/freqTLS/dev/reference/ts_curve.md))
  — the classical two-stage comparator, reporting both normal and
  small-sample t intervals.
- The plots
  ([`plot_confidence_eye()`](https://itchyshin.github.io/freqTLS/dev/reference/plot_confidence_eye.md),
  [`plot_survival_curves()`](https://itchyshin.github.io/freqTLS/dev/reference/plot_survival_curves.md),
  [`plot_tdt_curve()`](https://itchyshin.github.io/freqTLS/dev/reference/plot_tdt_curve.md),
  [`plot_heat_injury()`](https://itchyshin.github.io/freqTLS/dev/reference/plot_heat_injury.md))
  and extractors accept the `freq_tls` workflow object.
- Shared empirical data included `aphid_tdt` and `zebrafish_o2`; the
  active v0.2 teaching set and legacy boundary are listed above.

### Inference and calibration

- Small-sample **Bates–Watts profile-t / Wald-t calibration**:
  confidence intervals reference a t distribution with residual df = n −
  p, restoring nominal coverage at small n and reducing to the
  asymptotic interval as n grows. The evidence is a coverage + width
  simulation (repository-only `data-raw/calibration-study.R`, not
  installed): at df ≈ 10 the asymptotic 95% interval covers ~0.93 and
  the t-correction restores ~0.96.
- A three-way **benchmark** (repository-only
  `data-raw/benchmark-vs-bayes.R`, not installed): freqTLS reproduces
  bayesTLS’s CTmax to ~0.07 °C on the brown-shrimp data, beside the
  classical two-stage estimator.

### Analogue S3 surface

- [`confint()`](https://rdrr.io/r/stats/confint.html),
  [`summary()`](https://rdrr.io/r/base/summary.html),
  [`ranef()`](https://itchyshin.github.io/freqTLS/dev/reference/ranef.md),
  and
  [`coef()`](https://rdrr.io/r/stats/coef.html)/[`logLik()`](https://rdrr.io/r/stats/logLik.html)/[`vcov()`](https://rdrr.io/r/stats/vcov.html)/[`nobs()`](https://rdrr.io/r/stats/nobs.html),
  the heat-injury functions
  ([`predict_heat_injury()`](https://itchyshin.github.io/freqTLS/dev/reference/predict_heat_injury.md)
  /
  [`plot_heat_injury()`](https://itchyshin.github.io/freqTLS/dev/reference/plot_heat_injury.md)
  /
  [`heat_injury_envelope()`](https://itchyshin.github.io/freqTLS/dev/reference/heat_injury_envelope.md)),
  and
  [`check_tls()`](https://itchyshin.github.io/freqTLS/dev/reference/check_tls.md)
  all accept the `freq_tls` workflow object — this listed post-fit
  surface works on the
  [`fit_4pl()`](https://itchyshin.github.io/freqTLS/dev/reference/fit_4pl.md)
  result.
- `fit_4pl(by = "g")` now labels groups by the bare factor levels
  (`CTmax:young_embryos`), identical to the column interface, end to
  end.

### Case studies and vignettes (render without Stan)

- The **frequentist-and-bayesian** centerpiece carries the coverage
  panel and the three-way benchmark; `comparing-to-bayesTLS` carries the
  live + cached comparison.
- Historical 0.1 articles included unpublished compatibility fixtures.
  They are not part of the active v0.2 teaching set.

### Simulation

- The build-excluded repository directory `scripts/simulations/`
  contains a freqTLS (ML/TMB) analogue of the bayesTLS two-stage-bias
  simulation (shared data-generating process + scoring), with a
  comparison to the bayesTLS results. These maintainer scripts and their
  DRAC launcher are not installed with the package.

### Engine

- Asymptotes use bayesTLS’s **disjoint-bounds** reparameterisation
  (`compute_4pl_bounds`); `up` is now a direct coordinate.
- Convergence / positive-definite-Hessian status is surfaced at fit
  time.

### Superseding profileTLS

- freqTLS is the intended successor to **profileTLS**, its engine donor.
