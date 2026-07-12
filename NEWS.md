# freqTLS 0.1.0 (release candidate)

* Corrected grouped contrast direction so `dCTmax:A-B`, `dlog_z:A-B`, and
  `dz:A-B` now follow their written meaning: group A minus group B.

freqTLS is the frequentist counterpart to the Bayesian **bayesTLS** package: it
fits the four-parameter logistic thermal-load-sensitivity (thermal death-time)
model by maximum likelihood via TMB, parameterised directly in CTmax and thermal
sensitivity (z). Under the matched relative-threshold, constant-shape
configuration, it targets the same fitted curve as `bayesTLS`; uncertainty is
reported through a frequentist trio — Wald (delta), profile-likelihood, and
bootstrap — instead of a posterior. Forked from **profileTLS** (commit
`6f963a9`, v0.3.3), which it supersedes.

## bayesTLS-twin API

* `standardize_data()` — the shared raw-data entry point for count or
  continuous-proportion responses (adopted from bayesTLS).
* `fit_4pl()` + `make_4pl_formula()` — the direct CTmax/z formula interface
  (`ctmax`/`z`/`up`/`low`/`k`/`by`, plus `threshold`, `t_ref`, `bounds`,
  `family`), fitted by maximum likelihood through the TMB engine; returns a
  `freq_tls` workflow object.
* `tls()` / `tls_z()` / `tls_ctmax()` / `tls_tcrit()` — z, CTmax, and T_crit with
  confidence intervals at the relative midpoint, the absolute (LT50) threshold,
  or any LTx.
* `extract_tdt()` with `get_z_*` / `get_ctmax_*` / `get_tcrit_*` accessors — the
  nested z / CTmax / T_crit structure, with parametric-bootstrap replicates as
  the frequentist analogue of posterior draws.
* `predict_survival_curves()` — the fitted survival surface with bootstrap bands.
* `diagnose_tdt_fit()` and `tdt_parameter_table()` — convergence diagnostics
  (optimiser/Hessian/gradient) and the 4PL parameter table.
* `two_stage` (`ts_stage1()` / `ts_stage2()` / `ts_ci()` / `ts_curve()`) — the
  classical two-stage comparator, reporting both normal and small-sample t
  intervals.
* The plots (`plot_confidence_eye()`, `plot_survival_curves()`, `plot_tdt_curve()`,
  `plot_heat_injury()`) and extractors accept the `freq_tls` workflow object.
* Six shared case-study datasets, including `aphid_tdt` (Li et al. 2023) and
  `zebrafish_o2` (Saruhashi et al. 2026).

## Inference and calibration

* Small-sample **Bates–Watts profile-t / Wald-t calibration**: confidence
  intervals reference a t distribution with residual df = n − p, restoring
  nominal coverage at small n and reducing to the asymptotic interval as n grows.
  The evidence is a coverage + width simulation (repository-only
  `data-raw/calibration-study.R`, not installed):
  at df ≈ 10 the asymptotic 95% interval covers ~0.93 and the t-correction
  restores ~0.96.
* A three-way **benchmark** (repository-only
  `data-raw/benchmark-vs-bayes.R`, not installed): freqTLS reproduces
  bayesTLS's CTmax to ~0.07 °C on the brown-shrimp data, beside the classical
  two-stage estimator.

## Twin S3 surface

* `confint()`, `summary()`, `ranef()`, and `coef()`/`logLik()`/`vcov()`/`nobs()`,
  the heat-injury functions (`predict_heat_injury()` / `plot_heat_injury()` /
  `heat_injury_envelope()`), and `check_tls()` all accept the `freq_tls` workflow
  object — this listed post-fit surface works on the `fit_4pl()` result.
* `fit_4pl(by = "g")` now labels groups by the bare factor levels
  (`CTmax:young_embryos`), identical to the column interface, end to end.

## Case studies and vignettes (render without Stan)

* The **frequentist-and-bayesian** centerpiece carries the coverage panel and the
  three-way benchmark; `comparing-to-bayesTLS` carries the live + cached
  comparison.
* Worked case studies mirroring the shared manuscript: brown shrimp; zebrafish
  under hypoxia / normoxia / hyperoxia (OCLTT); cereal aphids (Li 2023);
  *D. suzukii* by sex;
  and a cross-taxon summary.

## Simulation

* The build-excluded repository directory `scripts/simulations/` contains a
  freqTLS (ML/TMB) twin of the bayesTLS two-stage-bias simulation (shared
  data-generating process + scoring), with a comparison to the bayesTLS results.
  These maintainer scripts and their DRAC launcher are not installed with the
  package.

## Engine

* Asymptotes use bayesTLS's **disjoint-bounds** reparameterisation
  (`compute_4pl_bounds`); `up` is now a direct coordinate.
* Convergence / positive-definite-Hessian status is surfaced at fit time.

## Superseding profileTLS

* freqTLS is the intended successor to **profileTLS**, its engine donor.
