# Shared API crosswalk: freqTLS 0.2 versus pinned bayesTLS

**Date:** 2026-07-16
**Audience:** maintainers deciding which shared names are true compatibility
contracts and which are only parallel scientific operations
**freqTLS baseline:** `codex/v02-bayestls-parity`, audited from its R sources and
generated `NAMESPACE`
**bayesTLS baseline:** commit
`76510412e06c594c96894a1baba1f0e1a34a5aea`, the source behind the supplement
rendered on 2026-07-14

## Conclusion

The packages share 21 exported names, but only three public functions are
currently code-identical: `format_interval()`, `tdt_quantile()`, and
`ts_curve()`. The classical two-stage functions have the same signatures and
the same valid-input estimands, but small validation and return-class
differences remain. The main workflow names (`fit_4pl()`, `tls()`, prediction,
diagnostics, and plotting) are scientific analogues, not drop-in replacements.
Their input objects, uncertainty engines, output objects, and some defaults
differ by design.

Therefore public documentation must say **shared workflow vocabulary** or
**frequentist analogue**, never “drop-in replacement”. Exact compatibility is
reserved for inference-independent utilities and tested data/model
specifications. A common function name alone is not compatibility evidence.

The generated namespaces contain 47 freqTLS exports and 43 bayesTLS exports:
21 shared, 26 freqTLS-only, and 22 bayesTLS-only. The audit parsed top-level
function definitions and compared their formals and bodies. Existing freqTLS
tests exercise its own “twin” facade but do not load or call bayesTLS; the only
`bayesTLS::` occurrence under `tests/testthat/` is a comment in
`test-heat-injury.R`. No live cross-package API test currently proves drop-in
compatibility.

## Compatibility classes

1. **Exact inference-independent compatibility** means identical accepted
   inputs, values, warnings/messages, classes, and documented edge cases.
2. **Intended core workflow compatibility** means the same scientific step is
   available under the same name, while engine-specific arguments and outputs
   remain explicit.
3. **Inference-dependent side-by-side semantics** means the same name is useful
   for comparison, but its uncertainty, diagnostics, object class, or result
   meaning necessarily differs.
4. **freqTLS-only** and **bayesTLS-only** names are package distinctions. They
   must not be disguised as replacements for a missing shared operation.
5. **Breaking redesign deferred** records apparent compatibility improvements
   that would instead blur the inference boundary or break existing users.

## Exhaustive shared-export classification

| Shared export | Primary class | Current contract and action |
|---|---|---|
| `clock_to_minutes(x)` | Exact inference-independent target; repair required | Same formal and numeric conversion, but pinned bayesTLS emits an informational message when all numeric values lie in `[0, 1]`; freqTLS silently multiplies by 1440. Add the message and pin edge-case tests before calling this exact. Evidence: `R/tdt-utils.R:53`; pinned `R/utils.R:58`. |
| `format_interval(median, lower, upper, digits = 2)` | Exact inference-independent | Parsed function body and formals are identical. Wording differs appropriately: freqTLS documents a point estimate/confidence interval and bayesTLS a posterior median/credible interval. Evidence: `R/tdt-utils.R:29`; pinned `R/utils.R:27`. |
| `tdt_quantile(x, probs = c(0.025, 0.5, 0.975))` | Exact inference-independent | Parsed body and formals are identical. Evidence: `R/tdt-utils.R:12`; pinned `R/utils.R:12`. |
| `standardize_data(data, temp, duration, n_total = NULL, n_surv = NULL, n_dead = NULL, survival = NULL, mortality = NULL, proportion = NULL, proportion_eps = 0.001, random_effects = NULL, duration_unit = "hours", temp_mean = NULL)` | Exact inference-independent target; repair required | Formals and standard columns match. freqTLS currently lacks bayesTLS's warning before overwriting an unrelated `survival` column, omits `proportion_eps` from `tdt_meta`, and correctly uses frequentist wording for an unidentified temperature slope. Port the warning and metadata field, preserve the frequentist warning text, and add object-equality tests for every response route. Evidence: `R/standardize_data.R:86`; pinned `R/standardize_data.R:87`; current tests `tests/testthat/test-standardize_data.R`. |
| `ts_stage1(data, temp = "temp", duration = "duration", n_surv = "n_surv", n_total = "n_total", family = c("binomial", "betabinomial"))` | Intended core workflow; nearly exact | Formal arguments and valid-input calculations match. Pinned bayesTLS returns `dplyr::bind_rows(rows)`; freqTLS returns base `do.call(rbind, rows)`, so tibble/data-frame class details can differ. Standardise the return contract without adding a heavy dependency and add cross-package value/class tests. Evidence: `R/two_stage.R:39`; pinned `R/two_stage.R:39`; `tests/testthat/test-two-stage.R`. |
| `ts_stage2(stage1, t_ref = 60, time_multiplier = 1, TC_rate_range = c(0.1, 1), rows = c("stage1_ok", "finite_ok"))` | Intended core workflow; nearly exact | Same formals and estimands for valid inputs. freqTLS lacks pinned bayesTLS's early `t_ref > 0` and `time_multiplier > 0` validation. Add the validation. Both retain the historically misleading field name `CTmax_1hr` even when `t_ref != 60`; a rename is deferred. Evidence: `R/two_stage.R:127`; pinned `R/two_stage.R:136`. |
| `ts_ci(stage2, method = c("delta", "mvn"), level = 0.95, t_ref = 60, time_multiplier = 1, TC_rate_range = c(0.1, 1), temp_grid = NULL, n_sim = 1000, seed = 123)` | Intended core workflow; nearly exact | Same formals and valid-input calculations. freqTLS lacks the same positive-time validation. Add validation and cross-package deterministic delta/MVN tests. Evidence: `R/two_stage.R:200`; pinned `R/two_stage.R:212`. |
| `ts_curve(stage2, temp_grid, time_multiplier = 1)` | Exact inference-independent | Parsed function body and formals are identical. Evidence: `R/two_stage.R:290`; pinned `R/two_stage.R:303`. |
| `make_4pl_formula(...)` | Intended core workflow, not call-compatible | Both expose direct `ctmax`, `z`, `low`, `up`, and `k` formulas, but freqTLS returns a `tls_formula`; bayesTLS returns a `brmsformula`. freqTLS defaults shape formulas to `~ 1`; pinned bayesTLS direct mode makes omitted shapes inherit the direct fixed structure crossed with temperature. freqTLS accepts `by` as a direct `CTmax`/`z` shortcut; pinned bayesTLS rejects `by` in direct mode. Canonical examples must state every formula explicitly. Evidence: `R/fit_4pl.R:39`; pinned `R/fit_4pl.R:121-267`; `tests/testthat/test-fit-4pl.R:9-24`. |
| `fit_4pl(...)` | Intended core workflow plus inference-dependent semantics | Both consume `standardize_data()` output and return a five-part/four-part workflow around a fitted 4PL, but freqTLS fits ML/TMB (`freq_tls` containing `profile_tls`) and bayesTLS fits brms/Stan (`bayes_tls` containing `brmsfit`). freqTLS has `method`, `start`, `trace`, and `quiet`; bayesTLS has priors, chains, sampling controls, caching, `fit = FALSE`, midpoint mode, and `...`. freqTLS currently rejects fitted absolute thresholds and non-default bounds. Most importantly, freqTLS documents `t_ref` in the data's duration unit, whereas pinned bayesTLS defines `t_ref` in minutes and converts through `duration_unit`; identical calls can therefore encode different reference times. Canonical articles must test the resolved model-scale reference time, not merely the literal argument. Evidence: `R/fit_4pl.R:121`; pinned `R/fit_4pl.R:359`; `tests/testthat/test-fit-4pl.R`. |
| `tls(object, ...)` | Intended core workflow plus inference-dependent semantics | Both return a `tls` object with `$summary` columns `quantity`, `median`, `lower`, and `upper`. bayesTLS also returns posterior `$draws`; freqTLS reports ML point estimates and profile/Wald/bootstrap confidence intervals and has no posterior-draw analogue. bayesTLS accepts multiple `params`, an extraction-time `t_ref`, `time_multiplier`, prediction grids, random-effect conditioning, and deprecated `mode`/`p`; freqTLS currently accepts one `params` choice and reads the fitted direct coordinates. Add only harmless aliases/vector selection if needed; do not manufacture posterior-shaped draws. Evidence: `R/tls.R:49`; pinned `R/tls.R:86`; `tests/testthat/test-tls.R`. |
| `tls_z(object, ...)` | Intended core workflow | Identical thin wrapper text, but delegated `tls()` semantics and returned uncertainty differ. Evidence: `R/tls.R:124`; pinned `R/tls.R:290`. |
| `tls_ctmax(object, ...)` | Intended core workflow | Identical thin wrapper text, but delegated `tls()` semantics and reference-time handling differ. Evidence: `R/tls.R:128`; pinned `R/tls.R:294`. |
| `tls_tcrit(object, ...)` | Inference-dependent side-by-side | bayesTLS delegates directly to `tls(params = "tcrit", lethal = TRUE)` and retains posterior draws. freqTLS invokes its bootstrap path, filters a flattened summary, and returns confidence intervals. Tcrit must remain absent from non-lethal canonical examples. Evidence: `R/tls.R:132`; pinned `R/tls.R:298`. |
| `diagnose_tdt_fit(object/workflow)` | Inference-dependent side-by-side | bayesTLS reports Rhat, bulk/tail ESS, divergences, treedepth saturation, BFMI, and pass flags. freqTLS reports optimiser convergence, positive-definite Hessian, gradient norm, log-likelihood, parameter count, AIC, and pass flags. The same name means “run engine-appropriate diagnostics”, not a common schema. Evidence: `R/tls.R:186`; pinned `R/diagnostics.R:32`; `tests/testthat/test-tls.R:55-64`. |
| `tdt_parameter_table(object/workflow, ...)` | Inference-dependent side-by-side | bayesTLS returns posterior natural-scale medians/credible intervals, parameterisation-aware and optionally by moderator. freqTLS returns MLEs with profile/Wald confidence intervals and a generic `group` field. Keep `median` only as the shared output-column vocabulary; documentation must call it the point estimate on the freqTLS path. Evidence: `R/tls.R:229`; pinned `R/diagnostics.R:142`; `tests/testthat/test-tls.R:66-71`. |
| `predict_survival_curves(...)` | Intended core workflow plus inference-dependent semantics | Both return `$summary` with `temp`, `duration`, and `survival_lower/median/upper`. bayesTLS adds `draws_matrix` and `grid` from posterior draws; freqTLS returns a `freq_surv_curves` object with bootstrap bands and metadata. Arguments differ (`ndraws`/`probs` versus `nboot`/`level`/`seed`). Evidence: `R/predict_survival_curves.R:42`; pinned `R/predict_survival_curves.R:193-227`; `tests/testthat/test-predict-survival-curves.R`. |
| `plot_survival_curves(...)` | Inference-dependent side-by-side | bayesTLS plots the result of `predict_survival_curves(pred, observed = ...)`; freqTLS accepts a fit and internally uses its ML prediction path. The input contracts are incompatible even though the plotted scientific quantity is shared. Evidence: `R/plotting.R:347`; pinned `R/plotting.R:73`. |
| `plot_tdt_curve(...)` | Inference-dependent side-by-side | bayesTLS expects an already-derived posterior LT object and can show linear/log panels; freqTLS accepts a fit and derives an ML curve at `p`. Same scientific plot, different input/result contracts. Evidence: `R/plotting.R:465`; pinned `R/plotting.R:231`. |
| `predict_heat_injury(...)` | Inference-dependent side-by-side | bayesTLS takes `(trace, workflow)`, propagates posterior uncertainty, reconciles explicit time units, and supports constant/varying shape plus optional repair. freqTLS takes `(object, trace)`, gives a deterministic MLE trajectory, and treats repair parameters as user-supplied illustrative scenarios. Argument order and output schemas differ. Do not call this compatible. Evidence: `R/heat_injury.R:83`; pinned `R/predict_heat_injury.R:362`. |
| `plot_heat_injury(...)` | Inference-dependent side-by-side | bayesTLS plots an existing heat-injury result; freqTLS accepts a fit and trace and constructs the prediction/envelope. Same name, incompatible input object. Evidence: `R/heat_injury.R:370`; pinned `R/plotting.R:517`. |

## Shared internal utilities

Static parsed-body comparison found these non-exported helpers identical at the
pinned baseline: `compute_4pl_bounds()`, `tdt_check_columns()`,
`tdt_format_random_effects()`, `tdt_random_effect_variables()`,
`tdt_resolve_time_multiplier()`, and `tdt_unit_to_minutes()`. They support real
behavioural parity, but their unexported status means users must not depend on
them. `tdt_is_grouped()` is deliberately engine-specific. Pinned bayesTLS also
has `tdt_resolve_t_ref()`; freqTLS has no equivalent extraction-time resolver
because its direct `CTmax` coordinate is fixed at fit time.

## Inference-dependent object semantics

| Operation | freqTLS | pinned bayesTLS |
|---|---|---|
| Fit object | `freq_tls` workflow containing a TMB `profile_tls` fit | `bayes_tls` workflow containing a `brmsfit` |
| Point summary | MLE (or bootstrap median only on explicitly bootstrap-derived routes) | Posterior median |
| Main interval | profile-likelihood, Wald/delta, or parametric-bootstrap confidence interval | posterior credible interval |
| Replicate object | parametric-bootstrap replicates are method-specific and may include failed refits | posterior draws are integral to the fitted object |
| Diagnostics | convergence code, Hessian, gradient, likelihood/AIC | Rhat, ESS, divergences, treedepth, BFMI |
| Random effects | one independent random intercept on supported coordinates; population prediction is explicit | brms random-effect structures and `re_formula` conditioning |
| Reference time | direct coordinate fixed at the fit's model-unit `t_ref` | `t_ref` supplied in minutes and can be re-read at extraction time |
| Absolute threshold | fitted backbone currently relative; post-fit bootstrap inversion for absolute/LTx | direct fitted absolute mode where valid, plus posterior post-fit inversion |
| Tcrit | bootstrap-derived and lethal-only | posterior-derived and lethal-only |

The shared summary column name `median` is historical cross-package vocabulary.
For freqTLS relative/profile/Wald output it stores an MLE point estimate, not a
sample median. Reader-facing prose must use “estimate” and “confidence
interval”; it must never infer posterior semantics from the column label.

## freqTLS-only exports: retain as frequentist extensions

These 26 exports are legitimate package distinctions and should live in the
separate frequentist-extension teaching area:

- **TMB fitting and formulas:** `fit_tls()`, `tls_bf()`, `binomial_tls()`,
  `beta_binomial_tls()`, `beta_tls()`.
- **Frequentist diagnostics and inference:** `check_tls()`,
  `tidy_parameters()`, `get_ctmax()`, `get_z()`, `get_shape()`, `ranef()`, and
  `plot_confidence_eye()`.
- **Derived confidence/bootstrap quantities:** `extract_tdt()`, `derive_lt()`,
  `derive_ctmax()`, `derive_tcrit()`, `get_z_summary()`, `get_z_draws()`,
  `get_ctmax_summary()`, `get_ctmax_draws()`, `get_tcrit_summary()`, and
  `get_tcrit_draws()`.
- **Prediction/simulation extensions:** `simulate_tls()`,
  `predict_survival_surface()`, `plot_survival_surface()`, and
  `heat_injury_envelope()`.

The `*_draws()` accessors above expose bootstrap-derived draws from
`extract_tdt()`, not posterior draws. Their documentation must say so at every
use.

## bayesTLS-only exports: link rather than substitute

The 22 bayesTLS-only exports define Bayesian or broader workflow capabilities
that freqTLS must not silently imitate:

- **Posterior fit/accessors:** `get_brmsfit()`, `has_fit()`, `get_tls_est()`,
  `get_4pl_est()`, `extract_4pl_pars()`, `get_surv_draws()`, `get_hi_draws()`,
  `bayes_R2_tls()`, and `make_4pl_priors()`.
- **Posterior TDT derivation/landscapes:** `derive_z()`, `derive_tdt_curve()`,
  `derive_tdt_landscape()`, `derive_temperature_for_duration()`, and
  `plot_tdt_landscape()`.
- **Heat/repair/scenario workflow:** `repair_rate_schoolfield()`,
  `plot_repair_rate()`, `make_temperature_scenarios()`,
  `plot_temperature_scenarios()`, `plot_temperature_density()`, and
  `planted_dose_from_trace()`.
- **Plot/data presentation:** `summarise_observed_survival()` and `theme_tdt()`.

Unsupported censored-time and hurdle-response analyses are article-level
bayesTLS routes rather than exported freqTLS functions; the API inventory must
not imply that their absence can be repaired by a same-named freqTLS helper.

## Backward-compatible repairs permitted in this phase

1. Align `clock_to_minutes()` messages and edge-case tests.
2. Align `standardize_data()` overwrite warnings and `proportion_eps` metadata;
   test equality of standardised values, retained columns, factor conversion,
   metadata, warnings, and errors on the same fixtures.
3. Align two-stage positive-time validation and return class while preserving
   existing columns and the historical `CTmax_1hr` name.
4. Permit vector `params` in `tls()` and the deprecated `mode`/`p` aliases only
   if they map unambiguously to existing freqTLS operations.
5. Add paired specification tests that pin the actual data hash, filter,
   response, formulas, family, threshold, and resolved reference time. Estimate
   equality is not an API compatibility requirement.
6. Add schema tests for the intentionally common pieces of `$summary`, while
   explicitly testing engine-specific fields separately.

## Breaking redesign deferred

- Do not make `freq_tls` inherit from `bayes_tls`, or make `profile_tls` pretend
  to be a `brmsfit`.
- Do not add fake posterior `$draws` to `tls()` or prediction objects. Bootstrap
  replicates must remain labelled as bootstrap replicates, including failed-fit
  provenance.
- Do not accept and silently ignore bayesTLS sampling arguments (`prior`,
  `chains`, `warmup`, `backend`, `file`, or `fit = FALSE`) in freqTLS
  `fit_4pl()`.
- Do not change freqTLS's existing `fit_tls(..., tref = )` spelling or return
  class during this cleanup. A future API version may reconcile `tref`/`t_ref`
  only with a lifecycle migration.
- Do not overload plotting functions to guess whether their first argument is a
  fit, prediction, landscape, or heat-injury result. A future S3 design can
  unify dispatch after explicit object contracts are agreed.
- Do not copy bayesTLS midpoint-mode, fitted repair, censored-time, hurdle, or
  posterior-landscape APIs into freqTLS in this phase.
- Do not change constant-shape defaults merely to match a bayesTLS convenience
  default. Canonical parity is achieved by explicit formulas in both packages,
  not by hidden inheritance rules.

## Evidence and verification status

Static evidence used:

- freqTLS `NAMESPACE`, `R/fit_4pl.R`, `R/tls.R`, `R/standardize_data.R`,
  `R/tdt-utils.R`, `R/two_stage.R`, `R/predict_survival_curves.R`,
  `R/heat_injury.R`, and `R/plotting.R`;
- pinned bayesTLS files at commit
  `76510412e06c594c96894a1baba1f0e1a34a5aea`: `NAMESPACE`, `R/fit_4pl.R`,
  `R/tls.R`, `R/standardize_data.R`, `R/utils.R`, `R/two_stage.R`,
  `R/predict_survival_curves.R`, `R/predict_heat_injury.R`,
  `R/diagnostics.R`, and `R/plotting.R`;
- freqTLS tests `test-fit-4pl.R`, `test-tls.R`,
  `test-standardize_data.R`, `test-two-stage.R`, and
  `test-predict-survival-curves.R`.

This ledger is a source audit, not a runtime parity certificate. Exact claims
above come from identical parsed function bodies at the pinned source commit.
The “nearly exact” and core-workflow rows require the paired tests listed above
before release.
