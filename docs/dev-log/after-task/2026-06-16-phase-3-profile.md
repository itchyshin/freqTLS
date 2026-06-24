# After Task: Phase 3 -- Profile likelihood + identifiability diagnostics

## Date

2026-06-16

## Task

Implement profileTLS's distinctive contribution: profile-likelihood
compatibility intervals and the identifiability-diagnostics story the Bayesian
path lacks. Deliverables (SPEC.md S10-S11, Phase 3): `R/profile.R`
(`profile.profile_tls`), `R/confint.R`
(`confint.profile_tls(method = c("profile","wald"))`), `R/diagnostics.R` (the 12
warnings), an eye-style `plot.profile_tls_profile`, profile wiring into
`tidy_parameters(method = "profile")`, and `test-profile` / `test-group`.
Gate: `D(MLE) ~ 0`; finite closed CIs that bracket the estimate for CTmax & z;
`ci_z == exp(ci_log_z)`; sparse design warns + returns NA (no crash); grouped
CTmax:grp / z:grp profile to finite intervals.

## Created / Changed

Created:

- `R/profile.R` -- `profile.profile_tls()`, `print`/`plot` methods, the map-refit
  profile-NLL evaluator, the bracket-then-`uniroot` endpoint solver, the target
  resolver (CTmax / z / log_z / low / k / phi + grouped + contrasts + up), the
  curvature-scaled grid, the multimodal detector, the `up` Wald fallback, and the
  contrast treatment-coded refit.
- `R/confint.R` -- `confint.profile_tls()` returning the interval tibble; profile
  path (loops `profile()`) and Wald path (reuses `tls_wald_natural()`, also
  serves `log_z`).
- `R/diagnostics.R` -- `check_tls_data()` (warnings 1-8) and `check_tls()`
  (post-fit, adds 7-8).
- `tests/testthat/test-profile.R`, `tests/testthat/test-group.R`.

Changed:

- `R/extract.R` -- `tidy_parameters()` gains `method = c("wald","profile")`;
  per-row honest `interval_type` (so `up` reads `"wald"` under the profile path).
- `R/fit_tls.R` -- calls `check_tls_data()` (warnings 1-6); retains `tmb_inputs`
  and `diag_data` on the fit.
- `R/fit_engine.R` -- returns `tmb_inputs` (clean data / parameters / map) for the
  map-refit.
- `R/profileTLS-package.R` -- import `rlang::.data`, `stats::confint`,
  `stats::profile`, `stats::relevel`, `stats::uniroot`.
- `docs/design/04-profile-likelihood.md` -- documents the implemented algorithm
  vs the draft (map-refit not tmbprofile; `up` Wald fallback; contrast refit).
- `docs/dev-log/check-log.md`, `docs/dev-log/dashboard/status.json` -- Phase 3
  evidence + status.

## Checks Performed (exact commands + counts)

- `R -q -e 'suppressMessages(devtools::document("."))'` -> clean; NAMESPACE gains
  `confint`, `profile`, `plot.profile_tls_profile`, `print.profile_tls_profile`,
  `export(check_tls)`.
- Verification gate (`devtools::load_all(".")` then the SPEC block):
  - `min(profile(f,"CTmax")$deviance)` = `0`.
  - `confint(f,"CTmax",method="profile")` -> [35.72, 36.13], estimate 35.93,
    conf.status "ok".
  - z CI `[3.623143, 4.374418]`; exp(log_z CI) `[3.623143, 4.374418]`;
    equivariance maxabsdiff = `0`.
  - sparse (`temps=c(35,36),times=c(1,2),reps=2,n=10,seed=9`):
    `confint(fs,"CTmax",method="profile")` warns "did not close ... weakly
    identified ... NA ... bayesTLS or a bootstrap", returns conf.low NA,
    conf.high 36.0, status open_lower, no crash.
- `R -q -e 'devtools::test(".")'` -> `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 163 ]`
  (fit-beta-binomial 15, fit-binomial 13, group 21, methods 36,
  parameter-transforms 17, profile 35, simulate 26).
- Grouped recovery + profiles + contrasts and beta-binomial phi profile checked
  with pasted output (see check-log).

## Outcomes

- The profile machinery works and is exactly equivariant: profiling the internal
  coordinate and transforming endpoints gives `ci_z == exp(ci_log_z)` to machine
  precision (maxabsdiff 0), confirming the Phase 1-2 equivariance claim end to
  end through the profile path.
- D(MLE) = 0 (the map-refit reproduces the full-fit `-logLik` at the fitted
  coordinate to the last digit), so the chi-square inversion is correctly
  anchored.
- The non-closing case is honest: it warns, returns `NA` on the open side (never
  a fabricated bound), sets a `conf.status` marker, and does not crash. The
  clean-data beta-binomial phi profile additionally exercises warning 12 (inner
  non-convergence) and warning 9 (open_both) together.
- Grouped per-group targets and group contrasts (`dCTmax`, `dlog_z`) profile to
  finite closed intervals; the recoded-fit contrast estimate equals the
  per-group difference from the `~ 0 + group` fit to 1e-4.
- `tidy_parameters(method = "profile")` fills the same 8-column shape and is
  per-row honest about the `up` Wald fallback.

## Consistency Review

- `rg "posterior|credible"` over `R/profile.R R/confint.R R/diagnostics.R`: none
  in user-facing strings; the plot caption uses "compatibility" and a test
  asserts the absence of "posterior"/"credible".
- The profile-not-closing message uses the SPEC wording "weakly identified --
  consider bayesTLS or a bootstrap".
- Design doc 04 now matches the implementation (map-refit, `up` Wald fallback,
  contrast refit). The targets table and ship stance are unchanged and still
  accurate. The dashboard matrix `profile` cells move planned -> implemented for
  the four family x design cells.
- `interval_type` is now a per-row vector; the existing `test-methods` assertion
  `all(tp$interval_type == "wald")` still holds for the default Wald path.

## Tests Of The Tests

- The equivariance test would fail if endpoints were transformed before
  profiling (the whole point); it passes at tol 1e-6 with actual diff 0.
- The non-closing test asserts both the warning regex and `is.na` on one side and
  `conf.status` matching "open"; a fabricated finite bound would fail the NA
  check.
- The contrast tests assert the recoded estimate equals the per-group difference
  to 1e-4, catching any basis / indexing error in the treatment-coded refit.
- The multimodal detector was unit-probed against a U-shape (FALSE) and a
  one-sided dip (TRUE) to confirm it is not dead code; offset minima are caught
  by warning 10 instead, so warnings 10 and 11 are complementary, not redundant.
- The asymmetry test asserts the two half-widths of the phi interval differ by
  more than 5%, so a symmetrising bug would fail.

## What Did Not Go Smoothly

- First attempt rebuilt the inner objective from `obj$env$data` /
  `obj$env$parameters`. The mapped-out `log_phi` slot comes back as a length-0
  vector with leftover `map`/`shape` attributes, so every map-refit silently
  failed and all deviances were `NA`. Fix: retain the *clean* TMB inputs
  (`fit$tmb_inputs`) at fit time and rebuild from those, warm-starting at the
  MLE. After that the evaluator returned `-logLik` exactly at the MLE coordinate.
- The contrast path initially errored ("Profiling needs the TMB inputs retained
  in the fit") because the recoded fit did not carry `tmb_inputs`; fixed by
  storing `engine$tmb_inputs` on the recoded object.
- `check_tls` emits several warnings; a naive `expect_warning(check_tls(fs), ...)`
  let the second warning leak past the matcher (1 WARN in the run). Fixed by
  collecting all warnings with `withCallingHandlers` and asserting on the codes.

## Team Learning

- For TMB profiling, never reconstruct from `obj$env`; keep the original clean
  inputs on the fit object. Mapped-out parameters make `obj$env$parameters`
  non-round-trippable. (Gauss / Fisher.)
- Profiling the *internal* coordinate and transforming the endpoints is the
  honest, equivariant route and gives `ci_z == exp(ci_log_z)` for free; do not
  profile the natural-scale quantity directly. (Fisher.)
- `up`'s nested-gap reparameterisation has no single coordinate; the Wald/delta
  fallback (with an honest label) is the right v0.1 call rather than shipping a
  second compiled parameterisation. Revisit only if a profiled `up` is needed.
  (Gauss / Emmy.)
- Group contrasts are profile-able by a one-line design change (`~ relevel(g)`)
  plus a refit -- the equivariant move -- without any new C++. (Fisher / Emmy.)

## Known Limitations

- `up` is reported with a Wald/delta interval under both methods (documented).
- Warnings 10 (boundary) and 11 (multimodal) have live, unit-probed code paths
  but are not triggered by a dedicated end-to-end test fixture (they are rare on
  well-posed sims); they are exercised structurally and via the detector unit
  probe. A future phase could add a hand-crafted degenerate fixture.
- Profile cost is a full re-optimisation per grid point (npoints default 30) plus
  the endpoint refits; fine for v0.1 sims but the benchmark (Phase 5) should keep
  npoints modest or cache.

## Next Best Task

- Phase 4 (Florence + Darwin): `predict.R` and `plotting.R` (the Confidence Eye).
  The profile object already carries `conf.status`, `conf.low/high`, and `scale`,
  so the eye can render a hollow point + open lens for a non-closing profile
  (R-PROFILE / R-POSTERIOR contract). Phase 5 (benchmark) can compare
  `confint(method="profile")` widths/asymmetry against the cached bayesTLS
  posterior summaries.
