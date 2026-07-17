# Package index

## Fit and extract (shared-name workflow analogues)

The primary frequentist workflow: standardise the same data, fit the 4PL
by maximum likelihood, and extract analogous thermal-death-time
quantities.

- [`standardize_data()`](https://itchyshin.github.io/freqTLS/reference/standardize_data.md)
  : Standardise a raw survival / proportion dataset for the TDT function
  library

- [`make_4pl_formula()`](https://itchyshin.github.io/freqTLS/reference/make_4pl_formula.md)
  : Build a freqTLS 4PL formula from the direct CTmax/z interface

- [`fit_4pl()`](https://itchyshin.github.io/freqTLS/reference/fit_4pl.md)
  : Fit the 4PL thermal-load-sensitivity model by maximum likelihood
  (TMB)

- [`tls()`](https://itchyshin.github.io/freqTLS/reference/tls.md)
  [`tls_z()`](https://itchyshin.github.io/freqTLS/reference/tls.md)
  [`tls_ctmax()`](https://itchyshin.github.io/freqTLS/reference/tls.md)
  [`tls_tcrit()`](https://itchyshin.github.io/freqTLS/reference/tls.md)
  : Thermal-load-sensitivity quantities (z, CTmax) with confidence
  intervals

- [`extract_tdt()`](https://itchyshin.github.io/freqTLS/reference/extract_tdt.md)
  : Extract z, CTmax and (optionally) T_crit with bootstrap confidence
  intervals

- [`get_z_summary()`](https://itchyshin.github.io/freqTLS/reference/tdt-accessors.md)
  [`get_z_draws()`](https://itchyshin.github.io/freqTLS/reference/tdt-accessors.md)
  [`get_ctmax_summary()`](https://itchyshin.github.io/freqTLS/reference/tdt-accessors.md)
  [`get_ctmax_draws()`](https://itchyshin.github.io/freqTLS/reference/tdt-accessors.md)
  [`get_tcrit_summary()`](https://itchyshin.github.io/freqTLS/reference/tdt-accessors.md)
  [`get_tcrit_draws()`](https://itchyshin.github.io/freqTLS/reference/tdt-accessors.md)
  : Accessors for an extract_tdt() result

- [`predict_survival_curves()`](https://itchyshin.github.io/freqTLS/reference/predict_survival_curves.md)
  : Predict the fitted survival surface with bootstrap confidence bands

- [`diagnose_tdt_fit()`](https://itchyshin.github.io/freqTLS/reference/diagnose_tdt_fit.md)
  :

  Diagnose a freqTLS fit (frequentist analogue of `diagnose_tdt_fit`)

- [`tdt_parameter_table()`](https://itchyshin.github.io/freqTLS/reference/tdt_parameter_table.md)
  :

  4PL parameter table (frequentist analogue of `tdt_parameter_table`)

## Classical two-stage comparator

The per-temperature GLM + OLS estimator, for benchmarking.

- [`ts_stage1()`](https://itchyshin.github.io/freqTLS/reference/ts_stage1.md)
  : Stage 1 of the classical two-stage TDT pipeline
- [`ts_stage2()`](https://itchyshin.github.io/freqTLS/reference/ts_stage2.md)
  : Stage 2 of the classical two-stage TDT pipeline
- [`ts_ci()`](https://itchyshin.github.io/freqTLS/reference/ts_ci.md) :
  Uncertainty for the classical two-stage TDT quantities
- [`ts_curve()`](https://itchyshin.github.io/freqTLS/reference/ts_curve.md)
  : Median LT-vs-temperature line from a two-stage fit

## Engine (lower-level interface)

The TMB engine behind freqTLS; use it directly for full formula control.

- [`fit_tls()`](https://itchyshin.github.io/freqTLS/reference/fit_tls.md)
  : Fit a single-stage 4PL thermal-load-sensitivity model by maximum
  likelihood
- [`tls_bf()`](https://itchyshin.github.io/freqTLS/reference/tls_bf.md)
  : Build a freqTLS formula object (brms/drmTMB-style)
- [`print(`*`<profile_tls>`*`)`](https://itchyshin.github.io/freqTLS/reference/profile_tls-methods.md)
  [`summary(`*`<profile_tls>`*`)`](https://itchyshin.github.io/freqTLS/reference/profile_tls-methods.md)
  [`print(`*`<summary.profile_tls>`*`)`](https://itchyshin.github.io/freqTLS/reference/profile_tls-methods.md)
  [`coef(`*`<profile_tls>`*`)`](https://itchyshin.github.io/freqTLS/reference/profile_tls-methods.md)
  [`vcov(`*`<profile_tls>`*`)`](https://itchyshin.github.io/freqTLS/reference/profile_tls-methods.md)
  [`logLik(`*`<profile_tls>`*`)`](https://itchyshin.github.io/freqTLS/reference/profile_tls-methods.md)
  [`AIC(`*`<profile_tls>`*`)`](https://itchyshin.github.io/freqTLS/reference/profile_tls-methods.md)
  [`nobs(`*`<profile_tls>`*`)`](https://itchyshin.github.io/freqTLS/reference/profile_tls-methods.md)
  : S3 methods for fitted freqTLS models
- [`tidy_parameters()`](https://itchyshin.github.io/freqTLS/reference/tidy_parameters.md)
  : Tidy the parameters of a fitted freqTLS model
- [`get_ctmax()`](https://itchyshin.github.io/freqTLS/reference/get_ctmax.md)
  : Extract the CTmax estimate(s)
- [`get_z()`](https://itchyshin.github.io/freqTLS/reference/get_z.md) :
  Extract the thermal-sensitivity (z) estimate(s)
- [`get_shape()`](https://itchyshin.github.io/freqTLS/reference/get_shape.md)
  : Extract the shape parameters (low, up, k, and phi)
- [`ranef()`](https://itchyshin.github.io/freqTLS/reference/ranef.md) :
  Random-effect BLUPs (conditional modes) for a freqTLS fit
- [`check_tls()`](https://itchyshin.github.io/freqTLS/reference/check_tls.md)
  : Report identifiability diagnostics for a fitted model
- [`binomial_tls()`](https://itchyshin.github.io/freqTLS/reference/tls_family.md)
  [`beta_binomial_tls()`](https://itchyshin.github.io/freqTLS/reference/tls_family.md)
  [`beta_tls()`](https://itchyshin.github.io/freqTLS/reference/tls_family.md)
  : Response families for thermal-load-sensitivity models

## Profile likelihood

Profile-likelihood deviance curves and prior-free confidence intervals.

- [`profile(`*`<profile_tls>`*`)`](https://itchyshin.github.io/freqTLS/reference/profile.profile_tls.md)
  [`print(`*`<profile_tls_profile>`*`)`](https://itchyshin.github.io/freqTLS/reference/profile.profile_tls.md)
  : Profile-likelihood curves for a fitted thermal-load-sensitivity
  model
- [`confint(`*`<profile_tls>`*`)`](https://itchyshin.github.io/freqTLS/reference/confint.profile_tls.md)
  : Confidence intervals for a fitted thermal-load-sensitivity model

## Prediction and plotting

Predict survival, derive lethal times, and draw the fitted curves, the
survival surface, and the Confidence Eye.

- [`predict(`*`<profile_tls>`*`)`](https://itchyshin.github.io/freqTLS/reference/predict.profile_tls.md)
  [`predict(`*`<freq_tls>`*`)`](https://itchyshin.github.io/freqTLS/reference/predict.profile_tls.md)
  : Predict survival, link, or midpoint from a fitted freqTLS model
- [`predict_survival_surface()`](https://itchyshin.github.io/freqTLS/reference/predict_survival_surface.md)
  : Predict a survival surface over a temperature-by-duration grid
- [`predict_heat_injury()`](https://itchyshin.github.io/freqTLS/reference/predict_heat_injury.md)
  : Predict cumulative heat injury under a temperature trace
- [`heat_injury_envelope()`](https://itchyshin.github.io/freqTLS/reference/heat_injury_envelope.md)
  : Parametric-bootstrap confidence envelope for a heat-injury
  trajectory
- [`plot_heat_injury()`](https://itchyshin.github.io/freqTLS/reference/plot_heat_injury.md)
  : Plot a heat-injury survival trajectory with a bootstrap confidence
  band
- [`derive_lt()`](https://itchyshin.github.io/freqTLS/reference/derive_lt.md)
  : Derive the lethal / survival-threshold duration at a temperature
- [`derive_ctmax()`](https://itchyshin.github.io/freqTLS/reference/derive_ctmax.md)
  : Derive the temperature giving a target survival at a fixed exposure
- [`derive_tcrit()`](https://itchyshin.github.io/freqTLS/reference/derive_tcrit.md)
  : Derive the critical temperature at a damage-rate floor (T_crit)
- [`plot_survival_curves()`](https://itchyshin.github.io/freqTLS/reference/plot_survival_curves.md)
  : Plot fitted survival curves against duration
- [`plot_tdt_curve()`](https://itchyshin.github.io/freqTLS/reference/plot_tdt_curve.md)
  : Plot the thermal death-time (TDT) curve: survival-threshold time vs
  temperature
- [`plot_survival_surface()`](https://itchyshin.github.io/freqTLS/reference/plot_survival_surface.md)
  : Plot the fitted survival surface over temperature and duration
- [`plot_confidence_eye()`](https://itchyshin.github.io/freqTLS/reference/plot_confidence_eye.md)
  : Confidence-Eye (or line) display of headline confidence intervals
- [`plot(`*`<profile_tls_profile>`*`)`](https://itchyshin.github.io/freqTLS/reference/plot.profile_tls_profile.md)
  : Plot a profile-likelihood deviance curve

## Simulation

Generate data from the locked data-generating process.

- [`simulate_tls()`](https://itchyshin.github.io/freqTLS/reference/simulate_tls.md)
  : Simulate survival-count data from the 4PL thermal-load-sensitivity
  model

## Utilities

Small shared helpers (time conversion, interval formatting, quantiles).

- [`clock_to_minutes()`](https://itchyshin.github.io/freqTLS/reference/clock_to_minutes.md)
  : Convert various clock formats to minutes
- [`format_interval()`](https://itchyshin.github.io/freqTLS/reference/format_interval.md)
  : Format a point estimate plus confidence interval as a single string
- [`tdt_quantile()`](https://itchyshin.github.io/freqTLS/reference/tdt_quantile.md)
  : Quantile wrapper with TDT-friendly defaults

## Canonical teaching data

Published empirical examples mirrored from the pinned bayesTLS
supplement; see each help page for source-specific credit and component
licences.

- [`zebrafish_o2`](https://itchyshin.github.io/freqTLS/reference/zebrafish_o2.md)
  : Zebrafish lethal-TDT data across an oxygen gradient
- [`dsuzukii`](https://itchyshin.github.io/freqTLS/reference/dsuzukii.md)
  : Drosophila suzukii multi-trait thermal-tolerance data
- [`aphid_tdt`](https://itchyshin.github.io/freqTLS/reference/aphid_tdt.md)
  : Cereal-aphid lethal-TDT data, three species across three ages
- [`snowgum_psii`](https://itchyshin.github.io/freqTLS/reference/snowgum_psii.md)
  : Snow-gum retained PSII after heat exposure

## Package

- [`freqTLS`](https://itchyshin.github.io/freqTLS/reference/freqTLS-package.md)
  [`freqTLS-package`](https://itchyshin.github.io/freqTLS/reference/freqTLS-package.md)
  : freqTLS: Frequentist Inference for Thermal Load Sensitivity Models
