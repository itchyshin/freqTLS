# freqTLS 0.1.0 (development)

freqTLS is the frequentist counterpart to the Bayesian **bayesTLS** package: it
fits the four-parameter logistic thermal-load-sensitivity (thermal death-time)
model by maximum likelihood via TMB, parameterised directly in CTmax and thermal
sensitivity (z). A bayesTLS analysis should run on freqTLS by changing only the
package the data and functions come from; uncertainty is reported through a
frequentist trio — Wald (delta), profile-likelihood, and bootstrap — instead of a
posterior. Forked from **profileTLS** (commit `6f963a9`, v0.3.3), which it
supersedes.

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
* Seven shared case-study datasets, including `aphid_tdt` (Li et al. 2023) and
  `zebrafish_o2` (Saruhashi et al. 2026).

## Engine

* Asymptotes use bayesTLS's **disjoint-bounds** reparameterisation
  (`compute_4pl_bounds`); `up` is now a direct coordinate.
* Convergence / positive-definite-Hessian status is surfaced at fit time.

## In progress

* The profile-t interval-calibration evidence (coverage + width simulation),
  the three-way benchmark against bayesTLS, the case-study vignettes mirroring
  the shared manuscript, the pkgdown site, and the formal deprecation of
  profileTLS.
