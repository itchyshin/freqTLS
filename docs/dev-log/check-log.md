# Check Log

Append-only log for validation evidence, handoff notes, and important project
state. Each dated entry records the goal, the changes, the exact checks run (with
command text, not summaries), and an interpretation into next steps. GitHub issue
maintenance is recorded here too.

## 2026-06-16 -- Phase 0 bootstrap: team, memory, docs, and package scaffold

Goal:

- Stand up the freqTLS team, dev-log memory, design docs, and package
  metadata by adapting the drmTMB agent-kit to the freqTLS scope (single-stage
  4PL thermal-load-sensitivity, count data, direct CTmax/z, profile-likelihood
  compatibility intervals, benchmark vs bayesTLS). No engine or R/ engine code in
  this phase.

Changes:

- Copied the canonical SPEC verbatim to `SPEC.md`.
- Wrote `AGENTS.md` and `CLAUDE.md` adapted to freqTLS scope, with the
  Definition of Done, the name-to-agent map, the standing review roles, the
  team-improvement loop, and the pkgdown policy.
- Wrote the 13 named and 4 job-function agents under `.claude/agents/` and the
  1-to-1 `.codex/agents/` `.toml` mirrors, preserving each role's model
  (opus -> high reasoning effort, sonnet -> medium).
- Wrote nine local skills under `.agents/skills/`: `tmb-likelihood-review`,
  `figure-visual-audit` (Confidence Eye), `add-simulation-test`,
  `simulation-test-plan`, `after-task-audit` (freqTLS rg patterns),
  `prose-style-review`, `release-readiness-review`, and the two new skills
  `profile-ci-review` and `benchmark-vs-bayesTLS-audit`.
- Wrote `.claude/hooks/session-start.sh` (idempotent R/TMB toolchain setup, no
  Stan) and `.claude/settings.json` (SessionStart hook); kept
  `.claude/settings.local.json`.
- Copied and adapted the agent-kit at `docs/agent-kit/` (README, team-roles,
  bootstrap-checklist, project-memory-policy, and the project-neutral templates).
- Built the `docs/dev-log/` tree: this `check-log.md`, `decisions.md`,
  `known-limitations.md`, the `after-task/`, `after-phase/`,
  `recovery-checkpoints/`, `benchmarks/`, `figure-audits/`,
  `simulation-artifacts/`, `audits/`, `agent-notes/`, `release-checklists/`, and
  `comparator-results/` directories (each with `.gitkeep`), and the
  `dashboard/` (static board polling `status.json` on port 8767).
- Added `tools/start-mission-control.sh` (port 8767) and `tools/checkpoint.R`
  (adapted from the drmTMB `codex-checkpoint.R`).
- Wrote the design docs `docs/design/{00-vision, 01-model-and-parameterisation,
  02-family-registry, 03-likelihoods, 04-profile-likelihood, 05-testing-strategy,
  06-benchmark-protocol, 07-collaboration-and-site, 10-after-task-protocol,
  46-capability-matrix, 90-bayesTLS-critique}.md`.
- Wrote `ROADMAP.md` (phases 0-6 + status, v0.1 boundary), confirmed `NEWS.md`
  (`# freqTLS 0.0.0.9000`), and confirmed/extended `README.Rmd`.
- Confirmed `DESCRIPTION` (4 authors), wrote a minimal `NAMESPACE`, confirmed
  `_pkgdown.yml`, the CI workflows, and `.Rbuildignore`, and wrote
  `inst/COPYRIGHTS` and `inst/CITATION`.

Checks run:

- `R -q -e 'desc::desc(file="DESCRIPTION")'`: parses; the four authors are
  present (Nakagawa cre; Noble, Arnold, Pottier aut). Full output recorded in the
  after-task report.
- `R -q -e 'jsonlite::fromJSON("docs/dev-log/dashboard/status.json")'` and the
  same for `sweep.json`: both valid JSON.
- `R -q -e 'jsonlite::fromJSON(".claude/settings.json")'`: valid JSON.
- `sh -n .claude/hooks/session-start.sh`, `sh -n tools/start-mission-control.sh`:
  pass.
- `Rscript tools/checkpoint.R --stdout`: produces a recovery checkpoint from git
  state.
- `R -q -e 'roxygen2::parse_package(...)'`-style NAMESPACE sanity and a
  `desc`/`Authors@R` eval (see the after-task report for exact text and output).

Stale-claim searches:

- `rg "posterior|credible" R vignettes README.Rmd docs`: only the deliberate
  bayesTLS teaching contrast in `docs/design/90-bayesTLS-critique.md` and the
  Confidence-Eye contrast notes; no freqTLS interval is called a posterior.
- `rg "rho12|meta_V|biv_gaussian"` over the adapted files: none (no
  drmTMB-specific scope terms leaked into freqTLS files).

GitHub issue maintenance:

- No GitHub issues were opened or closed in this phase; the repository is a fresh
  scaffold. The dashboard and ROADMAP are the current work ledger until the issue
  tracker is populated.

Interpretation:

- The Phase 0 scaffold is verified: governance, memory, design docs, and package
  metadata are coherent and parse. The next phase is Phase 1 (Gauss + Noether):
  implement `src/profile_tls.cpp` (already present as a Phase-1 draft), the
  numeric header, `init.c`, and the R engine (`families.R`, `model_matrix.R`,
  `fit_engine.R`, `fit_tls.R`, `utils.R`, `simulate.R`), then regenerate the
  NAMESPACE with roxygen and add `test-parameter-transforms`. The
  NAMESPACE/imports contract and the src/ + R/ layout handed to Phase 1 are
  recorded in the after-task report.

## 2026-06-16 -- Phase 1: TMB engine, fit_tls, simulate

Goal:

- Deliver a correct, compiling, recovery-verified TMB 4PL engine and the
  maximum-likelihood fitting surface (binomial + beta-binomial; direct
  CTmax/log_z midpoint; nested-gap asymptotes), plus `fit_tls()`,
  `simulate_tls()`, and `test-parameter-transforms`. Audit Ada's unverified
  Phase-0 engine drafts critically; fix or rewrite rather than rubber-stamp.

Changes:

- Audited Ada's drafts against SPEC S9. `src/profile_tls.cpp`,
  `profile_tls_numeric.h`, `init.c`, `R/families.R`, `R/model_matrix.R`,
  `R/utils.R` were found spec-correct but never compiled/tested; kept unchanged
  and verified. `R/freqTLS-package.R` had a real bug: it omitted the `rlang`
  imports (`enquo`/`eval_tidy`/`quo_is_null`) that tidy-eval `fit_tls()` needs --
  fixed. The hand-written `NAMESPACE` was deleted so roxygen owns it; the
  two-line `@importFrom stats` (rejected by roxygen2 8.0.0) was collapsed to one
  line; unresolvable `@noRd`/TMB cross-links were demoted to backticks.
- Wrote `R/fit_engine.R` (MakeADFun -> nlminb -> optim(BFGS) fallback ->
  sdreport in tryCatch; convergence list with code/pdHess/optimizer/message;
  mirrors drmTMB::R/drmTMB.R:350-440), `R/fit_tls.R` (public tidy-eval
  `fit_tls()`, default starts, natural-scale estimates table, internal vcov, and
  a minimal `logLik.profile_tls` S3 method), `R/simulate.R` (locked-DGP
  `simulate_tls()` with the documented phi convention), `tests/testthat.R`, and
  `tests/testthat/test-parameter-transforms.R`. Regenerated `NAMESPACE` + `man/`.

Checks run (exact commands):

- `R -q -e 'TMB::compile("src/profile_tls.cpp")'` -> `[1] 0` (clean; only Eigen
  -Wunused-but-set-variable warnings). Artifacts removed afterwards.
- `R -q -e 'devtools::document(".")'` -> regenerated NAMESPACE + man/, no errors.
- `R -q -e 'devtools::load_all("."); cat("LOADED OK\n")'` -> compiled src/,
  printed `LOADED OK`.
- `R -q -e 'devtools::test(".")'` -> `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 17 ]`.
- End-to-end recovery:
  - binomial (truth CTmax=36, z=4): logLik=-129.0538, conv=0, pdHess=TRUE,
    CTmax=35.93 (SE 0.11), z=3.998 (SE 0.19), low=0.0199, up=0.977, k=4.89;
    all p in (0,1).
  - beta-binomial (truth CTmax=36, z=4, phi=50): logLik=-137.71, conv=0,
    pdHess=TRUE, CTmax=35.90 (SE 0.12), z=4.057 (SE 0.21), phi=40.8 (SE 22.3;
    truth within 1 SE); all p in (0,1).
  - binomial df=5 (log_phi mapped out); grouped binomial (truth CTmax c(34,38),
    z c(3,5)) conv=0, pdHess=TRUE, df=7, recovered CTmax:A=34.01, CTmax:B=37.87,
    z:A=2.88, z:B=5.02; default family = beta_binomial.

Phase 2 contract (recorded so Emmy/Boole/Curie can build without re-deriving):

- Signature: `fit_tls(data, y, n, time, temp, group = NULL,
  family = c("beta_binomial", "binomial"), tref = 1, start = NULL,
  control = list(), trace = FALSE)`. Columns are data-masked (bare names).
- `class(fit) = c("profile_tls", "tls_fit")`. Fields: `call`, `family` (a
  `tls_family`), `tref`, `group_levels` (chr; "all" when ungrouped),
  `data_summary` (list: n_obs, n_groups, grouped, temp_range, time_range,
  n_temps, n_times, total_trials, total_successes), `par` (named internal-scale
  MLE), `estimates` (data.frame: parameter, group, estimate, std.error -- rows
  low/up/k, then CTmax(:grp)/z(:grp), then phi for beta-binomial), `vcov`
  (cov.fixed of the internal coordinates, or NULL), `logLik` (numeric scalar),
  `df` (length of optimised par), `AIC`, `convergence` (list: code, pdHess,
  message, optimizer), `name_map` (the internal<->natural<->link<->group table
  from `tls_name_map()`), `obj`/`opt`/`sdreport` (raw TMB objects). The
  `obj$report(par)` REPORT block exposes low/up/k/phi/beta_CT/z_group/p_fitted.
- `logLik.profile_tls` is implemented in `R/fit_tls.R` (carries df + nobs
  attributes); Phase 2 should fold it into the full method set.

Interpretation:

- The Phase 1 gate is met with pasted real output. The engine is correct,
  compiling, and recovery-verified for both families and for grouped designs.
  Next is Phase 2 (Emmy + Boole + Curie): `methods.R`, `extract.R`,
  `test-fit-binomial`, `test-fit-beta-binomial`, against the contract above.

## 2026-06-16 -- Phase 2: API, S3 methods, extractors, recovery tests

Goal:

- Deliver the readable S3 surface and tidy extractors for the `profile_tls`
  object (Emmy + Boole), harden `simulate_tls()` so misuse errors instead of
  silently recycling (Curie -- the footgun fix), and add the recovery + method
  tests. Audit the Phase-1 code critically rather than rubber-stamp it.

Changes:

- Wrote `R/methods.R`: `print.profile_tls` (call, family, tref, data summary,
  the natural-scale estimates table, convergence/pdHess, logLik/df/AIC),
  `summary.profile_tls` + `print.summary.profile_tls` (adds Wald z-statistic and
  p-value columns), `coef.profile_tls` (named vector, or the full estimates df
  with `complete = TRUE`), `vcov.profile_tls` (internal-coordinate cov.fixed,
  warns + returns NULL when sdreport produced no covariance),
  `logLik.profile_tls` (consolidated here from `R/fit_tls.R`; class `logLik`
  with df + nobs attrs), `AIC.profile_tls` (stored AIC for k = 2, computed
  otherwise), `nobs.profile_tls`. Mirrors drmTMB::R/methods.R:2-40,1826-1864,
  2025-2037.
- Removed the duplicate minimal `logLik.profile_tls` from `R/fit_tls.R` to avoid
  a double S3 registration (was `@exportS3Method stats::logLik`).
- Wrote `R/extract.R`: `tidy_parameters(fit, conf.int = TRUE,
  conf.level = 0.95)` returning the 8-column tibble (parameter, group, estimate,
  std.error, conf.low, conf.high, interval_type, scale); `get_ctmax()`,
  `get_z()`, `get_shape()` as tidy subsets. Wald CIs are built on the internal
  (link) scale as `estimate +/- z * se` and back-transformed, so they respect
  bounds and are equivariant (verified `z` CI == exp(internal log_z CI) to 0).
  `up` (no single internal coordinate under the nested gap) uses a delta-method
  Wald interval from the ADREPORTed `up` SE; `interval_type = "wald"` throughout
  (profile wired in Phase 3).
- Hardened `R/simulate.R` (Curie): a list (non-atomic) `group` now errors with
  guidance to the parallel vector API; a grouped `CTmax`/`z` must be a scalar or
  one value per *distinct* group level (added `tls_recycle_param()`); group
  levels are de-duplicated in first-appearance order to match the `~ 0 + group`
  design; positivity checks now cover full vectors.
- Wrote tests: `test-fit-binomial.R`, `test-fit-beta-binomial.R`,
  `test-simulate.R`, `test-methods.R`. Regenerated `NAMESPACE` + `man/`.

Checks run (exact commands):

- `R -q -e 'devtools::document(".")'` -> regenerated NAMESPACE + man/, no
  warnings (a transient first-pass `@return` link-to-`tidy_parameters` warning
  clears on the second run once the topic exists).
- `R -q -e 'devtools::load_all("."); ...; print(f); summary(f); coef(f);
  AIC(f); nobs(f); tidy_parameters(f); get_ctmax(f); get_z(f)'` (binomial,
  truth CTmax=36, z=4): print/summary readable; CTmax=35.93 (SE 0.105), z=3.998
  (SE 0.191), logLik=-129.1, AIC=268.1, nobs=105; `tidy_parameters` has the 8
  columns with Wald CIs (z: [3.64, 4.39] on the log scale; low: [0.0115,
  0.0342]; CTmax: [35.72, 36.13] symmetric on the identity scale).
- `R -q -e 'devtools::test(".")'` ->
  `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 107 ]` (fit-beta-binomial 15, fit-binomial
  13, methods 36, parameter-transforms 17, simulate 26). Includes the
  bb-beats-binom AIC/logLik test (overdispersed phi=8: logLik bb=-142.9 >
  binom=-192.7; AIC bb=297.7 < binom=395.4), the near-binomial collapse on clean
  data (phi -> ~4.4e5; binom AIC wins by 2), and the simulate-misuse error tests
  (list group; mismatched grouped length; ungrouped vector).

Simulate misuse, verified erroring (was silent recycling before):

- `simulate_tls(group = list(A = list(CTmax = 34)))` ->
  "`group` must be an atomic vector of group labels, not a `<list>`." + API hint.
- `simulate_tls(group = c("A","B","C"), CTmax = c(34,38), z = 4)` ->
  "`CTmax` must be a single scalar or have one value per group." (3 levels, length 2).
- `simulate_tls(CTmax = c(34,38), z = 4)` ->
  "`CTmax` must be a single value for an ungrouped simulation."

Stale-claim searches:

- `rg "posterior|credible" R/methods.R R/extract.R tests`: none; all interval
  language is "Wald" / "confidence" / "compatibility".

Phase 3 contract (recorded for Fisher + Gauss):

- `tidy_parameters()` returns the fixed 8-column tibble; Phase 3 adds profile
  CIs by setting `interval_type = "profile"` and filling conf.low/conf.high from
  the profile roots, keeping `scale` as the natural-scale link. The `z` Wald
  interval already equals `exp()` of the internal `beta_logz` Wald interval
  (equivariance verified to 0), so the profile machinery can profile the
  internal coordinate named in `fit$name_map` and transform endpoints; the
  `name_map` (internal/natural/link/group, with `beta_gap -> "gap"` and `up`
  surfaced separately) is the lookup. SEs for grouped `beta_CT`/`beta_logz` must
  be read positionally from `summary(sdreport, select = "fixed")` (the row names
  repeat) -- `tls_wald_natural()` shows the pattern.

Interpretation:

- The Phase 2 gate is met with pasted real output: ungrouped and grouped fits
  print and summarise readably, all extractors return sane shapes, the recovery
  and model-selection tests pass, and `simulate_tls()` misuse now errors clearly.
  Next is Phase 3 (Fisher + Gauss + Pat): `profile.R`, `confint.R`,
  `diagnostics.R`, the eye-style profile plot, and `test-profile` / `test-group`.

## 2026-06-16 -- Phase 3: profile likelihood + identifiability diagnostics

Goal:

- Add the profile-likelihood machinery (freqTLS's distinctive contribution):
  `profile.profile_tls()`, `confint.profile_tls(method = c("profile","wald"))`,
  the 12 identifiability warnings, an eye-style `plot.profile_tls_profile()`, and
  `test-profile` / `test-group`. Verify D(MLE) ~ 0, finite closed CIs that bracket
  the estimate, exact equivariance `ci_z == exp(ci_log_z)`, and honest non-closing
  behaviour (warn + NA, no crash).

Changes:

- `R/profile.R` (new): `profile.profile_tls()` + `print`/`plot` methods. Map-refit
  profile NLL evaluator (fix one internal coordinate via TMB `map`, re-optimise
  the rest warm-started at the MLE), bracket-then-`uniroot` endpoint solver
  (adapted from `drmTMB::R/profile.R:2314-2373`), target resolver
  (CTmax/z/log_z/low/k/phi + grouped + contrasts + up), curvature-scaled grid,
  multimodal detector, and the `up` Wald fallback + contrast treatment-coded
  refit.
- `R/confint.R` (new): `confint.profile_tls()` returning a tibble
  (`parameter, conf.low, conf.high, estimate, level, method, scale, conf.status`);
  profile path loops `profile()`, Wald path reuses `tls_wald_natural()` and also
  serves `log_z` targets.
- `R/diagnostics.R` (new): `check_tls_data()` (warnings 1-8) called by `fit_tls`
  before fitting (1-6) and `check_tls(fit)` post-fit (adds 7-8); warnings 9-12 are
  emitted by the profiling code. All via `cli::cli_warn` (never silent).
- `R/extract.R`: `tidy_parameters()` gains `method = c("wald","profile")`; the
  profile path fills the same 8-column shape, with per-row honesty so `up` is
  labelled `"wald"`.
- `R/fit_tls.R`: calls `check_tls_data()` (warnings 1-6); retains `tmb_inputs`
  (clean data/parameters/map) and `diag_data` on the fit for profiling + check_tls.
- `R/fit_engine.R`: returns `tmb_inputs` for the map-refit.
- `R/freqTLS-package.R`: import `rlang::.data`, `stats::confint/profile/
  relevel/uniroot`.
- `tests/testthat/test-profile.R`, `test-group.R` (new).
- `docs/design/04-profile-likelihood.md`: documents the implemented algorithm
  (map-refit not tmbprofile; `up` Wald fallback; contrast refit).

Checks run:

- `R -q -e 'devtools::document(".")'` -> clean; NAMESPACE gains
  `S3method(confint,profile_tls)`, `S3method(profile,profile_tls)`,
  `S3method(plot,profile_tls_profile)`, `S3method(print,profile_tls_profile)`,
  `export(check_tls)`.
- Verification gate (`devtools::load_all(".")` then the SPEC block):
  - `pc <- profile(f, "CTmax"); min(pc$deviance)` -> `0` (D at MLE ~ 0).
  - `confint(f, "CTmax", method="profile")` -> conf.low 35.7, conf.high 36.1,
    estimate 35.9, conf.status "ok" (finite, closed, brackets estimate).
  - z CI `3.623143 4.374418`; exp(log_z CI) `3.623143 4.374418`;
    **equivariance maxabsdiff = 0**.
  - Non-closing sparse case (`temps=c(35,36), times=c(1,2), reps=2, n=10, seed=9`):
    `confint(fs,"CTmax",method="profile")` warns *"The profile likelihood for
    \"CTmax\" did not close on the lower side: \"CTmax\" is weakly identified ...
    Returning \"NA\" ... (R-PROFILE) ... Consider bayesTLS or a bootstrap ..."*,
    returns `conf.low = NA`, `conf.high = 36.0`, `conf.status = "open_lower"`, no
    crash.
- Grouped (`group=c("A","B"), CTmax=c(34,38), z=c(3,5), seed=2`): recovers
  CTmax:A 34.07, CTmax:B 37.99, z:A 3.21, z:B 5.08; `confint(fg,"CTmax:A")` and
  `confint(fg,"z:B")` finite closed; contrasts `dCTmax:A-B` estimate 3.9224 ==
  (CTmax:B - CTmax:A) to 1e-4, `dlog_z:A-B` estimate 0.4592 == log z:B - log z:A.
- beta-binomial phi profile (`CTmax=36,z=3,phi=50,seed=1`): estimate 43.3,
  profile CI [17.5, 272] (markedly asymmetric, preserved). Clean-data bb fit
  (phi -> 1.1e7): phi profile warns inner non-convergence (warning 12) and does
  not close (open_both) -> honest NA.
- `R -q -e 'devtools::test(".")'` ->
  `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 163 ]`
  (fit-beta-binomial 15, fit-binomial 13, group 21, methods 36,
  parameter-transforms 17, profile 35, simulate 26).
- Multimodal detector unit-probed: U-shape -> FALSE, one-sided dip -> TRUE
  (offset minima are caught by warning 10, not 11; the two are complementary).

Stale-claim search:

- `plot.profile_tls_profile` caption uses "compatibility" and excludes
  "posterior"/"credible" (asserted in test-profile). The profile-not-closing
  message uses "weakly identified -- consider bayesTLS or a bootstrap" verbatim.

Interpretation:

- The Phase 3 gate is met with pasted real output: D(MLE)=0, CTmax & z profile
  CIs finite/closed/bracketing, `ci_z == exp(ci_log_z)` to 0 (exact
  equivariance), the sparse case warns + returns NA without crashing, and grouped
  CTmax:grp / z:grp / contrasts profile to finite intervals. `up` is the
  documented Wald/delta fallback (re-rooting deferred as disproportionate).
  Phase 4 (predict + Confidence-Eye plotting) and Phase 5 (benchmark) can build
  on `confint(method="profile")` and the `profile_tls_profile` object
  (`conf.status` marker is ready for the honest non-closing eye).


## 2026-06-16 -- Phase 4: prediction + Confidence-Eye plotting

Goal:

- Add forward prediction and the publication plots, with the Confidence Eye as
  the default uncertainty display (SPEC.md S9 forward map, S13 eye contract, S11
  test-predict). Deliverables (Florence + Darwin): `R/predict.R`
  (`predict.profile_tls`, `predict_survival_surface`, `derive_lt`),
  `R/plotting.R` (`plot_survival_curves`, `plot_tdt_curve`,
  `plot_survival_surface`, `plot_confidence_eye` with `style = c("eye","line")`
  and the honest `conf.status` fallback), and `test-predict`. Verify survival
  strictly decreasing in duration and in temperature; `newdata` returns
  probabilities in (0,1) of the right length; `type = "midpoint"` equals
  `log10(tref)` at `temp = CTmax`; `derive_lt` round-trips; and the survival +
  eye PNGs render and are inspected.

Changes:

- `R/predict.R` (new): `predict.profile_tls(object, newdata, type =
  c("survival","link","midpoint"))` using the engine forward map
  `mid = log10(tref) - (temp - CTmax_g)/z_g`,
  `p = low + (up-low)*plogis(-k(log10(duration)-mid))`;
  `predict_survival_surface()` (long temp x duration x survival grid, per group);
  `derive_lt(p, temp, group)` inverting the 4PL
  (`log10(dur) = mid - qlogis((p-low)/(up-low))/k`); helpers
  `tls_predict_pars()` (per-row group resolver) and `tls_shape_estimates()`.
- `R/plotting.R` (new): `tls_eye_polygon_df()` (gllvmTMB lens helper, adapted;
  GPL-3 provenance in inst/COPYRIGHTS); `plot_confidence_eye()` (pale lens +
  hollow point, eye/line switch, honest fallback off conf.status);
  `plot_survival_curves()`, `plot_tdt_curve()`, `plot_survival_surface()`.
- `tests/testthat/test-predict.R` (new): 38 tests (monotonicity both axes,
  newdata length + range, link = qlogis(survival), midpoint = log10(tref) at
  CTmax for tref 1 and 2, midpoint constancy/omission, derive_lt round-trip +
  relative-midpoint identity + out-of-asymptote abort, surface shape, input
  validation, grouped per-group resolution).
- `NAMESPACE` (document): S3method(predict, profile_tls) + exports derive_lt,
  predict_survival_surface, plot_confidence_eye, plot_survival_curves,
  plot_tdt_curve, plot_survival_surface; importFrom(stats, predict).
- `inst/COPYRIGHTS`: gllvmTMB eye note planned -> implemented (tls_eye_polygon_df
  + plot_confidence_eye structure).

Checks run:

- `R -q -e 'roxygen2::roxygenise(".")'` -> NAMESPACE gains the seven Phase-4
  exports. (Three pre-existing @noRd link warnings unchanged from Phase 2-3.)
- Verification gate (load_all then the SPEC block):
  - survival range over `expand.grid(temp=c(34,36,38), duration=c(1,2,4))`:
    `[0.0239, 0.8945]` (in (0,1)).
  - decreasing with duration (`temp=36, duration=c(0.5,1,2,4,8)`): `TRUE`.
  - decreasing with temperature (`temp=c(32,34,36,38,40), duration=2`): `TRUE`.
  - `ggsave` wrote `/tmp/ptls_survival_p4.png` and `/tmp/ptls_eye_p4.png`.
- Render-proof (PNGs read back and inspected; figure-audits/2026-06-16-eye.md):
  survival curves all monotone-declining with observed points overlaid; eye has
  a pale-green lens + hollow point per facet, "compatibility" caption, no
  posterior wording, no filled points; the sparse-fit eye
  (`/tmp/ptls_eye_open_p4.png`) draws hollow points and NO lens
  (`any(GeomPolygon) == FALSE`) -- the honest fallback; line-style, surface, and
  TDT (log-linear, slope -1/z) PNGs also correct.
- `R -q -e 'devtools::test(".")'` ->
  `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 201 ]`
  (fit-beta-binomial 15, fit-binomial 13, group 21, methods 36,
  parameter-transforms 17, predict 38, profile 35, simulate 26).

Interpretation:

- The Phase 4 gate is met with pasted real output AND render-proof: predict is
  monotone in both axes and reproduces `log10(tref)` at `temp = CTmax` (so the
  reparameterisation is pinned end to end), `derive_lt` round-trips to 1e-6, and
  every figure was inspected as a rendered image, not signed off on code. The
  Confidence Eye honours S13 (pale lens, hollow point, compatibility language)
  and falls back honestly to hollow-points-only when a profile does not close.
  predict, simulate, and derive_lt share one forward map (nothing to drift).
  Next: Phase 5 (benchmark) can compare confint(method="profile") widths and
  predict_survival_surface against the cached bayesTLS summaries; Phase 6 can
  embed plot_confidence_eye + plot_survival_curves as the homepage figures.

## 2026-06-16 -- Phase 5: benchmark data (R-SHRIMP) + cache harness

Goal:

- Vendor the bayesTLS benchmark datasets into the freqTLS column contract,
  correcting the verified R-SHRIMP data bug; document them with CC-BY
  attribution; write (but do NOT run) the maintainer cache builder; and add the
  benchmark sanity tripwire that skips when the cache is absent (SPEC.md S5, S8,
  S12, S14). bayesTLS and Stan are not installed here, so the cache cannot be
  built live; the verifiable payoff is the R-SHRIMP-corrected data and
  freqTLS fitting the real shrimp + zebrafish data.

Changes:

- `data-raw/make_benchmark_data.R` (maintainer-run, executed now): downloads the
  shrimp CSV + both shipped `.rda` from the bayesTLS GitHub @HEAD via the curl
  CLI, rebuilds `shrimp_lethal` from the CSV proportion
  (`survived = total - round(mortality_prop * total)`, keeping `mortality_prop`),
  takes `zebrafish_lethal` from the shipped object (its build is correct),
  renames both to `temp/duration/total/survived[/life_stage]`, asserts the
  rebuilt shrimp death distribution is not collapsed, and writes
  `data/shrimp_lethal.rda` + `data/zebrafish_lethal.rda` via `usethis::use_data`.
- `R/data.R`: roxygen for both datasets -- `@format`, `@source`,
  `@section Attribution:` (bayesTLS / Noble, Arnold & Pottier 2026 / CC BY 4.0 /
  original Crangon crangon + Danio rerio assays), the R-SHRIMP reconstruction
  note on `shrimp_lethal`, `@docType data`, `@keywords datasets`, `@name`, and
  the `"shrimp_lethal"`/`"zebrafish_lethal"` object strings.
- `inst/CITATION`: the bayesTLS bibentry note now states the bundled datasets are
  vendored from bayesTLS under CC BY 4.0 and must be cited when used.
- `data-raw/build_benchmark_cache.R` (maintainer-run; guarded; NOT executed):
  `fit_4pl(temp_effects="mid", beta_binomial) -> extract_tdt(target_surv=
  "relative", t_ref=1, output_time_unit="hours")` for shrimp + each zebrafish
  stage, and `ts_stage1 -> ts_stage2 -> ts_ci`; writes summaries + a `meta` block
  (bayesTLS_version, git_sha, cmdstan_version, date_built, seed, config,
  realized R-SHRIMP distribution note) to
  `inst/extdata/bayesTLS_benchmark_cache.rds`. Stops immediately unless both
  bayesTLS and cmdstanr are installed.
- `tests/testthat/test-benchmark-sanity.R`: `skip_if_not(file.exists(cache))`,
  then asserts the live freqTLS CTmax (within ~1 C) and z (within ~25%)
  against the cached bayesTLS median per dataset.
- `.gitignore`: ignore `data-raw/.cache/` (raw download cache).
- `man/shrimp_lethal.Rd`, `man/zebrafish_lethal.Rd` via `devtools::document()`.

Checks run:

- R-SHRIMP before/after (shipped `.rda` vs CSV reconstruction):
  - shipped `shrimp_lethal$Mortality_after_trial`: integer, values `{0, 1}`,
    113 zeros + 35 ones, **sum 35** over 148 rows.
  - corrected `deaths = round(mortality_prop * total)`: range `[0, 11]`,
    **12 distinct values, sum 738**; 86 rows had a non-zero proportion < 1 that
    `as.integer()` had floored to 0.
- `R -q -e 'source("data-raw/make_benchmark_data.R")'` -> wrote
  `data/shrimp_lethal.rda` (148 rows) + `data/zebrafish_lethal.rda` (323 rows);
  build log printed the before/after distributions above.
- `R -q -e 'tryCatch(source("data-raw/build_benchmark_cache.R"), error=...)'` ->
  GUARD FIRED: "needs both 'bayesTLS' and 'cmdstanr' ...";
  `inst/extdata/bayesTLS_benchmark_cache.rds` confirmed ABSENT.
- Verification gate (`devtools::load_all(".")` then the SPEC block):
  - `shrimp: n= 148  temps= 30,30.5,31,31.5,32,32.5,33`.
  - `summary(survived/total)`: min 0, median 0.60, mean 0.507, max 1.0.
  - R-SHRIMP deaths range `0 11` (not all 0/1).
  - `zebrafish: n= 323  stages= old_embryos,young_embryos,larvae`.
  - shrimp `fit_tls(..., family="beta_binomial", tref=1)`: conv 0, pdHess TRUE;
    low 2.0e-10, up 0.941, k 5.69, CTmax 31.77, z 2.19, phi 7.08.
  - zebrafish grouped fit: conv 0, pdHess TRUE; CTmax young 39.92 / old 41.38 /
    larvae 39.79; z young 2.00 / old 1.80 / larvae 1.98; up 0.864, k 7.83,
    phi 3.29. Appropriate data-adequacy warning fired: "Fewer than 3 unique
    durations at temperatures 40.1, 40.5, 41.2, and 42" (S10 warning 2).
- `R -q -e 'devtools::test(".")'` -> `[ FAIL 0 | WARN 0 | SKIP 1 | PASS 201 ]`
  (benchmark-sanity 1 SKIP at test-benchmark-sanity.R:31:3 "bayesTLS benchmark
  cache absent (needs Stan + bayesTLS to build)"; fit-beta-binomial 15,
  fit-binomial 13, group 21, methods 36, parameter-transforms 17, predict 38,
  profile 35, simulate 26).

Interpretation:

- The R-SHRIMP fix is verified against the actual shipped object, not asserted:
  the upstream `.rda` really does collapse the shrimp deaths to {0,1} (sum 35),
  and the CSV reconstruction restores the full 0..11 mortality gradient
  (sum 738). The shrimp fit only produces sensible, identified estimates
  (CTmax 31.77, z 2.19, real overdispersion phi 7.08) because of this fix -- the
  collapsed shipped data would not support the curve. The fitted shrimp CTmax
  sits inside the 30-33 C assay range, so no extrapolation warning fires there;
  the zebrafish sparse high-temperature cells correctly trigger the per-temp
  duration-adequacy warning while the fit still converges -- exactly the honest
  identifiability story freqTLS exists to surface. The cache builder is
  written and its guard verified to stop without bayesTLS/Stan, so the benchmark
  test skips (not fails). Next: Phase 6 builds the comparing-to-bayesTLS vignette
  (live freqTLS + cached comparators) once a maintainer runs the cache
  builder, and embeds the homepage figures.

## 2026-06-16 -- Phase 6: docs, vignettes, and pkgdown site

Goal:

- Write the README (rendering the homepage survival + Confidence-Eye plots), the
  four vignettes (getting-started, model-math, profile-likelihood, and the
  comparing-to-bayesTLS comparison which MUST build WITHOUT Stan), flesh out
  NEWS, finalise `_pkgdown.yml`, and run the consistency sync (Rose hat) so
  README / ROADMAP / NEWS / known-limitations / status.json agree. Gate:
  document / build_readme / test / R CMD check / pkgdown::build_site clean
  locally (SPEC.md S4, S13, S17).

Changes:

- Cross-link fixes (resolves the lingering Phase 0-5 document warnings): demoted
  the three `[fn()]` auto-links to internal `@noRd` helpers to inline code in
  `R/confint.R` (`tls_wald_natural`), `R/diagnostics.R` (`check_tls_data`), and
  `R/profile.R` (`tls_resolve_contrast`).
- `vignettes/freqTLS.Rmd` (getting started): simulate -> fit -> summary ->
  tidy/get_* -> confint(method="profile") for CTmax & z -> Wald comparison ->
  plot_survival_curves + plot_confidence_eye. Always-eval, tiny sim.
- `vignettes/model-math.Rmd`: the 4PL; the direct
  `mid = log10(tref) - (temp-CTmax)/z` parameterisation (verified numerically:
  midpoint == 0 at temp=CTmax, slope == -1/z); the nested-gap asymptote
  transform; relative-vs-absolute thresholds; and the bayesTLS bridge identities
  `z = -1/beta1`, `CTmax = Tbar + (log10(tref)-beta0)/beta1`, checked numerically
  by recovering CTmax/z from the fit's own predicted midpoints (no Stan).
- `vignettes/profile-likelihood.Rmd`: the LR/deviance profile, the cutoff and the
  plot; asymmetry + equivariance (z CI == exp(log_z CI), live); profile vs Wald;
  the upper-asymptote Wald fallback; and the honest non-closing fallback (a
  deliberately sparse design -> open CI with NA + open_* status + hollow-point
  eye, warning caught so the vignette builds).
- `vignettes/comparing-to-bayesTLS.Rmd`: the three-way design + credit; live
  bayesTLS `fit_4pl`/`extract_tdt`/`ts_*` calls in `eval=FALSE` chunks; a
  cache-read chunk guarded by `file.exists(system.file("extdata",
  "bayesTLS_benchmark_cache.rds", ...))` that prints the "run
  data-raw/build_benchmark_cache.R on a Stan machine" note when the cache is
  absent (it is); live freqTLS fits on shrimp + zebrafish; and the
  posterior-density-vs-Confidence-Eye teaching device (the eye drawn live, the
  posterior half described as placeholder until the cache exists). Builds with NO
  Stan.
- `README.Rmd`: removed the broken logo `<img>` (no logo asset); the example now
  evaluates the quick loop (simulate -> fit -> confint(profile)) and embeds the
  rendered survival-curve and Confidence-Eye plots with fig.alt. `NEWS.md`
  fleshed out (engine, fit_tls, profile CIs, diagnostics, datasets, plots, docs).
- `_pkgdown.yml`: Bootstrap5/flatly; navbar intro/reference/articles/news/github;
  reference sections listing the ACTUAL exports (Fitting & post-fit / Profile
  likelihood / Prediction & plotting / Simulation / Data / Package); articles
  grouped Get started / Model details / Comparison.
- DESCRIPTION: added `VignetteBuilder: knitr`; removed the unused `Matrix`
  Import (NOTE fix). `.Rbuildignore`: added `^LICENSE$` (GPL-3 is a standard
  license; the full-text file should not ship -> NOTE fix). `R/plotting.R`: the
  three degree-sign axis labels converted to `°` escapes (non-ASCII NOTE
  fix; renders identically). `R/profile.R`: documented `print.profile_tls_profile`'s
  `digits` arg (undocumented-argument WARNING fix).
- Consistency sync (Rose hat): `docs/dev-log/known-limitations.md` header
  Phase 2 -> Phase 6 + the interval section now reflects both methods;
  `ROADMAP.md` Phases 1-6 initial -> implemented; `status.json` Phase 6 ->
  verified, metrics verified 6 -> 7, Pat -> verified, repo head Phase 5 ->
  Phase 6.

Checks run (exact commands):

- `R -q -e 'devtools::document(".")'` -> clean (no warnings; the three
  cross-link warnings are gone).
- `R -q -e 'devtools::build_readme()'` -> README.md regenerated;
  `man/figures/README-readme-survival-1.png` + `README-readme-eye-1.png`
  written; the embedded confint output shows CTmax [35.8, 36.3] / z [3.43, 4.38]
  (profile, ok).
- `R -q -e 'devtools::test(".")'` -> `[ FAIL 0 | WARN 0 | SKIP 1 | PASS 201 ]`
  (the SKIP is test-benchmark-sanity.R:31:3, cache absent -- unchanged).
- `_R_CHECK_FORCE_SUGGESTS_=false R -q -e 'rcmdcheck::rcmdcheck(args =
  c("--no-manual"), error_on = "never", env = c("_R_CHECK_FORCE_SUGGESTS_" =
  "false"))'` -> `0 errors | 0 warnings | 0 notes`. (Without the flag, R CMD
  check ERRORs only because the optional Suggest `bayesTLS` is not installed
  here; `creating vignettes ... OK` confirms all four vignettes -- including
  comparing-to-bayesTLS -- build without Stan, and `re-building of vignette
  outputs ... OK` + `checking examples ... OK` + `checking tests ... OK`.)
- `R -q -e 'pkgdown::build_site(preview = FALSE)'` -> SUCCESS into
  `pkgdown-site/`; all 4 articles built (articles/{freqTLS, model-math,
  profile-likelihood, comparing-to-bayesTLS}.html) + 36 reference HTML pages +
  news + search index; "Finished building pkgdown site", no problems/warnings.

Interpretation:

- The Phase 6 gate is clean on every axis: document, build_readme, test, R CMD
  check (0/0/0), and pkgdown all pass with real pasted output. The one
  environment caveat -- R CMD check's hard ERROR on the absent optional
  `bayesTLS` Suggest -- is resolved exactly as R's own message directs
  (`_R_CHECK_FORCE_SUGGESTS_=false`) and matches the maintainer's local-checks
  rule; with the flag the check is 0/0/0, and the CI workflow is ubuntu-only with
  no Stan, so it never installs bayesTLS. The comparing-to-bayesTLS vignette is
  verified to build with NO Stan (the cache-read chunk is guarded and the cache
  is absent), satisfying the load-bearing constraint. Three real check findings
  surfaced and were fixed cleanly (unused Matrix Import; the shipped LICENSE
  file; the undocumented `digits` arg; the non-ASCII degree signs), so there are
  no residual NOTEs to justify. The only outstanding gap remains the maintainer
  bayesTLS+two-stage cache (Stan), which is documented, guarded, and does not
  block the build. freqTLS compatibility language is preserved throughout the
  README, vignettes, and NEWS (no "posterior"/"credible" for freqTLS
  intervals). Next: the adversarial DoD gate (Rose + Pat + Fisher) and, on a Stan
  machine, populating the cache to complete the three-way benchmark table.

## 2026-06-16 -- v0.2: real bayesTLS cache + parametric bootstrap CIs

Goal:

- With `bayesTLS` 1.0.0 + cmdstanr (CmdStan 2.36.0) now installed, build the real
  three-way benchmark cache, and (maintainer request) add a prior-free parametric
  bootstrap so freqTLS always returns an interval -- parity with bayesTLS --
  when a profile does not close or `pdHess = FALSE`.

Changes:

- Fixed two broken output-schema assumptions in
  `data-raw/build_benchmark_cache.R` against the real bayesTLS 1.0.0 API:
  `extract_tdt()` returns a nested list (`get_ctmax_summary()`/`get_z_summary()`
  give `temp_*` / `z_*` columns), and `ts_ci(method="delta")` returns a named
  list (`$CTmax_1hr`, `$z` with `point/lower/upper`), not a `parameter`-keyed
  data frame. The original guessed `tdt$draws$CTmax` and a `parameter` column,
  which would have silently written all-`NA` rows.
- New parametric bootstrap: `R/bootstrap.R`, `confint(method="bootstrap")` and the
  default `fallback=TRUE`, eye rendering, `tests/testthat/test-bootstrap.R`. Docs
  synced (design 04 + 46, NEWS, ROADMAP, known-limitations, README).

Checks run (exact):

- `R CMD INSTALL --no-multiarch --no-docs .` -> `INSTALL_EXIT=0` (needed because
  the cache script does `data(package="freqTLS")`; the package was not
  installed in the dev env).
- `Rscript data-raw/build_benchmark_cache.R` -> `EXIT=0`; wrote
  `inst/extdata/bayesTLS_benchmark_cache.rds`. Bayesian (median [95% CrI]):
  shrimp CTmax 31.7 [31.6, 31.9], z 2.19 [1.95, 2.45]; zebrafish CTmax
  young 40.0 / old 41.3 / larvae 39.7. Two-stage agrees (shrimp CTmax 31.6, z
  2.06). Sanity vs freqTLS ML (live): shrimp CTmax 31.8 [31.6, 31.9], z 2.19
  [1.96, 2.45]; zebrafish CTmax 39.9 / 41.4 / 39.8 -- the profile-likelihood CI
  and the Bayesian credible interval nearly coincide (same likelihood, two lenses)
  and computed without Stan.
- `devtools::document()` -> OK; `devtools::test()` -> `PASS: 249 | FAIL: 0 |
  WARN: 0` (217 -> 249; +32 from test-bootstrap; fallback default did not regress
  any existing test).
- Probes: bootstrap CTmax 36.0 [35.8, 36.3] / z 4.13 [3.80, 4.46] on a
  well-identified fit; `z` interval == `exp(log_z)` interval max abs diff `0`
  (exact equivariance via construction-scale percentiles); sparse fit fallback
  CTmax 35.5 [35.1, 36.0], 300/300 converged; eye renders a bootstrap lens.
- `grep -rn "posterior|credible" R/` -> only deliberate comparison wording
  (R-POSTERIOR clean).

Interpretation:

- Task #1 (real cache) and task #2 (bootstrap) are complete and verified. The
  cache is the genuine head-to-head; the near-coincidence of the ML+profile and
  the Bayesian summaries is the complementary story for the comparison page. The
  bootstrap closes the one capability gap with bayesTLS (always returning an
  interval) while staying prior-free and exactly equivariant. Next: correct the
  comparing-to-bayesTLS vignette recipe (it passes `t_ref`/`time_multiplier` to
  `fit_4pl()` and skips `standardize_data()`), diagnose the stale
  `performance_results.rds` (profile coverage 0.000 / NA -- extraction bug), and
  rebuild + redeploy the comparison page with real numbers + the bootstrap.

## 2026-06-16 -- v0.2: performance study fix + real comparison page + full check

Goal:

- Repair and re-run the performance study, rebuild the `comparing-to-bayesTLS`
  article with real numbers and the bootstrap, and run a full check before
  proposing a commit.

Changes:

- `data-raw/performance-study.R`: profile/Wald coverage and the speed profile now
  pass `fallback = FALSE` (measure the PURE profile, not the v0.2 bootstrap
  fallback); accuracy validity tightened to `code 0 && pdHess && plausible CTmax`.
- `vignettes/comparing-to-bayesTLS.Rmd`: corrected recipe; real three-way table;
  speed/accuracy/coverage tables from the perf rds; a bootstrap-fallback demo.
- `README.md` re-knit from `README.Rmd`.

Checks run (exact):

- `Rscript data-raw/performance-study.R` -> EXIT 0. Accuracy (nsim 300): all
  |rel_bias| < 0.003; beta-binomial harder CTmax bias 0.003 / RMSE 0.10 (was
  18.0 / 78.6 before the validity filter), n_converged 283/300. Coverage:
  binomial profile CTmax 0.947 / z 0.953; beta-binomial profile 0.883 / 0.887
  (honestly < nominal). Speed: fit 6-87 ms, profile CI 85 ms - 1.9 s.
- Three-way shrimp table (live): two-stage CTmax 31.61 [31.33, 31.89] / z 2.06
  [1.49, 2.64]; bayesTLS 31.72 [31.60, 31.86] / 2.19 [1.95, 2.45]; freqTLS
  31.77 [31.63, 31.92] / 2.19 [1.96, 2.46]. Profile and posterior nearly coincide.
- `rmarkdown::render("vignettes/comparing-to-bayesTLS.Rmd")` -> ok; bootstrap demo
  shows strict profile NA vs bootstrap [35.08, 35.99].
- `devtools::build_readme()` -> ok.
- `devtools::test()` -> 249 pass / 0 fail / 0 warn.
- `devtools::check(_R_CHECK_FORCE_SUGGESTS_=false)` -> **0 errors / 0 warnings /
  0 notes**.

Interpretation:

- v0.2 slice (real cache + bootstrap + real comparison page) is complete and
  fully verified: clean check, green tests, a vignette that renders the genuine
  head-to-head with no Stan. The headline -- the prior-free profile interval
  sitting on top of the bayesTLS posterior, in milliseconds -- is the
  complementary story for the page. Deferred to maintainer approval: the git
  commit and the gh-pages deploy ("push only when asked"). Next: build the full
  site on approval, then the RE-1 random-intercept engine (no-RE path must stay
  byte-identical).

## 2026-06-16 -- v0.2: multicore bootstrap

Goal:

- Maintainer request: let the parametric bootstrap use multiple cores.

Changes:

- `R/bootstrap.R`: `cores` argument. Responses are pre-drawn sequentially under
  the seed, then the deterministic refits run via `parallel::mclapply` when
  `cores > 1` (sequential fallback on Windows). Decoupling RNG from scheduling
  makes the result identical for a given seed regardless of `cores` (and equal to
  the prior sequential path -- refits consume no RNG). Threaded `cores` through
  `confint(method=..., cores=)` and `plot_confidence_eye(cores=)`. `parallel`
  added to DESCRIPTION Imports.

Checks run (exact):

- `devtools::test()` -> 251 pass / 0 fail / 0 warn (+2 from the cores-equality
  test).
- Timing probe (binomial, nboot 800): cores=1 4.19 s, cores=4 1.26 s -> 3.34x;
  CIs identical across cores (all.equal TRUE).
- `devtools::check(_R_CHECK_FORCE_SUGGESTS_=false)` -> 0 errors / 0 warnings /
  0 notes.

Interpretation:

- Multicore is opt-in (`cores = 1` default), reproducible regardless of cores,
  and check-clean. No behaviour change for existing single-core callers.

## 2026-06-16 -- v0.2: RE-1 Phase 1 (random intercept on CTmax)

Goal:

- Add a random intercept on CTmax (`CTmax ~ <fixed> + (1 | group)`) by TMB
  Laplace, with the no-RE path byte-identical (the gate).

Changes:

- `src/profile_tls.cpp`: `re_index`, `b_CT`, `log_sd_CT`; RE terms guarded on
  `b_CT.size() > 0`. `fit_tls`/engine wire `random = "b_CT"` + surface
  `sigma_CTmax`; contrast refit passes the no-RE RE fields. `R/formula.R`:
  `tls_extract_ct_re()` parses one `(1 | group)` on CTmax (scope-checked).
  `simulate_tls` RE mode. Guards route RE interval requests to Wald (profile /
  bootstrap for RE are Phase 2). Tests `test-random-effects.R`; design doc 08;
  capability matrix / NEWS / ROADMAP / known-limitations synced.

Checks run (exact):

- `pkgload::load_all()` recompiled the cpp; full suite **251 pass / 0 fail** ->
  byte-identical no-RE gate held before the RE-request path existed.
- RE recovery (8 sims, 30 groups, true re_sd 1.5): CTmax mean 36.015, z mean
  4.001 (unbiased); sigma_CTmax mean 1.277 (expected ML downward bias).
- Full suite after RE tests + the two fixes (report re-pin; obsolete-test
  repurpose): **280 pass / 0 fail / 0 warn**.
- `devtools::check(_R_CHECK_FORCE_SUGGESTS_=false)`: **0 / 0 / 0** (twice: core,
  then with the RE guards).

Interpretation:

- RE-1 Phase 1 is complete and verified; the no-RE path is provably unchanged.
  `sigma_CTmax` is ML (biased low, documented). Two real bugs were found and
  fixed (the `obj$report()` last.par issue via re-pin; the TMB "wrong parameter
  length" via the no-arg report). Next: RE Phase 2 (profile/confint for
  sigma_CTmax + ranef()), then the Beta family.

## 2026-06-16 -- v0.2: RE-1 Phase 2 (ranef + sigma_CTmax Wald interval)

Goal:

- Complete the RE inference surface minimally: BLUPs and an interval for the
  variance component.

Changes:

- `ranef()` generic + `ranef.profile_tls` (CTmax BLUPs + conditional SEs from the
  sdreport random block). `tls_wald_natural` gains a log-scale Wald interval for
  `sigma_CTmax` (`exp(log_sd_CT +/- z*se)`). `print.profile_tls` notes the RE
  grouping. confint RE-guard message updated. Docs synced (design 08, NEWS,
  capability matrix, known-limitations).

Checks run (exact):

- `devtools::document()` -> `NAMESPACE` exports `ranef`.
- Probe: `summary(sdr, "random")` has the b_CT BLUPs + SEs; sigma Wald CI
  exp(0.30 +/- 1.96*0.20) = [0.91, 2.02] (point 1.36).
- Full suite: **295 pass / 0 fail / 0 warn**.
- `devtools::check(_R_CHECK_FORCE_SUGGESTS_=false)`: (see commit) expected 0/0/0.

Interpretation:

- RE now has BLUPs (`ranef()`) and a variance-component interval (Wald, log
  scale). Profile-likelihood `confint` under the RE remains Phase 2 (the only
  remaining RE gap). Next: the Beta (continuous-proportion) family.

## 2026-06-16 -- v0.2: derive_ctmax (absolute-threshold critical temperature)

Goal:

- Add the absolute-threshold critical temperature (bayesTLS extract_tdt
  absolute-mode analogue), R-only and additive.

Changes:

- `derive_ctmax(object, surv, duration, group)` in `R/predict.R`: closed-form
  inverse of the 4PL for temperature, `temp = CTmax - z*(log10(dur) - log10(tref)
  + qlogis((surv-low)/(up-low))/k)`. Default `surv = (low+up)/2`, `duration =
  tref` reproduces `CTmax` (relative-threshold default preserved). Added to
  `_pkgdown.yml`; NEWS + capability matrix synced; tests in `test-predict.R`.

Checks run (exact):

- Round-trip probe: `predict(fit, temp = derive_ctmax(surv, dur), dur)` returns
  `surv` to 1e-6 for surv in {0.25,0.5,0.8} x dur in {1,4}; default == CTmax
  (35.9259); grouped A 35.04 / B 37.99 (truth 35 / 38).
- `pkgdown::check_pkgdown()`: OK (all exports referenced, incl. ranef +
  derive_ctmax).
- `devtools::test()`: **309 pass / 0 fail / 0 warn**.
- `devtools::check(_R_CHECK_FORCE_SUGGESTS_=false)`: **0 / 0 / 0**.

Interpretation:

- The absolute-threshold critical temperature is done and exactly verified
  (closed-form round-trip). `T_crit` (rate-multiplier lethal) remains the only
  piece of the bayesTLS absolute family not yet matched; it needs a spec
  confirmation. Other remaining roadmap items (Beta family, covariates on shape)
  need maintainer design decisions (see the overnight handover).

## 2026-06-17 -- v0.2: beta (continuous-proportion) family

Goal:

- Add a continuous-proportion response family (`family = "beta"`, `family_code`
  2) so responses in (0, 1) fit with the same 4PL CTmax/z machinery as the count
  families. First of the maintainer-approved ("do all") v0.2 roadmap items;
  chosen first to bank value while isolating the riskier covariate cpp refactor.

Changes:

- Engine `src/profile_tls.cpp`: family branch `0 binom / 1 betabinom / else beta`
  with `dbeta(y, p*phi, (1-p)*phi)` (shape floor 1e-8, existing p clamp);
  `ADREPORT(phi)` guard `== 1 -> >= 1`. Codes 0/1 byte-identical (the new
  `else if (family_code == 1)` captures exactly the old `else`).
- `R/families.R` `beta_tls()` + resolver `match.arg(c("beta_binomial",
  "binomial", "beta"))`; `fit_tls()` family default + optional `n` (dummy
  `rep(1, n_obs)` for beta, clear abort for count families) + beta
  validation/clamp; `simulate_tls()` beta `prop` column (binomial/bb RNG
  unchanged); `R/formula.R` bare-name proportion LHS.
- `phi`-presence checks `== 1L -> >= 1L` in utils/profile/diagnostics/fit_tls;
  binomial-only `log_phi` map guards (`== 0L`) left untouched. `R/bootstrap.R`
  beta draw arm (prevents silent binomial draws on a beta fit). `R/methods.R`
  print: "mean observed proportion" for beta.
- Tests: new `tests/testthat/test-fit-beta.R` (RED-first), +2 in
  `test-simulate.R`. Docs: design/02, design/46, NEWS, ROADMAP,
  known-limitations, README (re-knit), after-task
  `2026-06-17-v0.2-beta-family.md`.

Checks run:

- `R -q -e 'devtools::document(".")'` -> OK, no warnings.
- `R -q -e 'devtools::test(".")'` -> `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 340 ]`
  (was 309; +31). The 309 pre-existing expectations pass unchanged, so the no-RE
  / count byte-identical gate held through the cpp recompile.
- `R -q -e 'rcmdcheck::rcmdcheck(args = "--no-manual", build_args =
  "--no-manual", env = c("_R_CHECK_FORCE_SUGGESTS_" = "false"), error_on =
  "never")'` -> `Status: OK` (0 errors / 0 warnings / 0 notes).
- Probe (`devtools::load_all`): ungrouped beta, truth CTmax 36 / z 4 / phi 20 ->
  36.03 / 3.82 / 24.8, code 0, pdHess TRUE; `print()` shows "mean observed
  proportion 0.4218".

Interpretation:

- Beta family fitted and verified; banks the first v0.2 item without touching the
  midpoint-only invariant. Next (suggested order): covariates on `low`/`up`/
  `log_k` (needs a `decisions.md` entry relaxing midpoint-only), then `T_crit`,
  heat-injury prediction, and shipping RE profiling. Noticed but not changed
  (surgical scope): the ROADMAP RE bullet still says `ranef()` is "Phase 2"
  although `ranef()` + the `sigma_CTmax` Wald interval shipped in `e01ff1e` --
  flag for a docs sweep.

## 2026-06-17 -- v0.2: profile-likelihood intervals under a random effect

Goal:

- Ship profile/confint intervals for the fixed-effect coordinates of an RE fit
  (`CTmax ~ <fixed> + (1 | group)`). The inner Laplace re-run already worked
  (`tls_profile_nll_fun()` passes `random`); it was gated by a hard abort in
  `profile()` and Wald routing in `confint()`. R-only; no engine change. Reordered
  ahead of covariates to bank the zero-byte-identical-risk items first.

Changes:

- `R/profile.R`: removed the RE abort; added a contrast-under-RE guard (the
  contrast refit drops the random block). `R/confint.R`: new
  `tls_confint_profile_re()` selective router -- profile the fixed effects, Wald
  for `sigma_CTmax`, Wald (not bootstrap) for the non-closing fallback, Wald for
  `method = "bootstrap"`. Non-RE path dispatched around, textually unchanged.
  `R/plotting.R`: Confidence Eye forces Wald for RE fits (speed).
- Tests: rewrote the old "route to Wald (Phase 2)" test in
  `test-random-effects.R` to the new contract -- a `skip_on_cran` profiling test
  (profile ~ Wald, brackets the truth, `profile()` returns the curve object), a
  fast routing test (`sigma_CTmax`/bootstrap stay Wald, the bootstrap engine
  errors), and a contrast-under-RE error appended to the fixed-group + RE test.
- Docs: design/08, design/46, known-limitations, NEWS, ROADMAP (also fixed the
  stale ROADMAP RE "Phase 2" bullet noted above), after-task
  `2026-06-17-v0.2-re-profiling.md`.

Checks run:

- `R -q -e 'devtools::document(".")'` -> OK, no warnings.
- `R -q -e 'devtools::test(".")'` -> `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 347 ]`
  (was 340; +7). Non-RE paths unchanged (the RE logic is dispatched behind a
  guard).
- `R -q -e 'rcmdcheck::rcmdcheck(args="--no-manual", build_args="--no-manual",
  env=c("_R_CHECK_FORCE_SUGGESTS_"="false"), error_on="never")'` -> `Status: OK`
  (0/0/0).
- Probe: 6-group RE fit, `confint("CTmax", method="profile", npoints=6)` ->
  `method="profile"`, finite ordered interval bracketing the truth, ~ Wald.

Interpretation:

- RE profiling shipped; the remaining RE item is an RE-aware bootstrap for
  `sigma_CTmax`. Next in this run: T_crit (definition confirmed via the bayesTLS
  source: `T_crit = CTmax + z*log10(r*/100)`, a deterministic transform; do NOT
  copy bayesTLS's `runif` rate draw), then heat-injury (forward-Euler dose
  accumulation + optional Sharpe-Schoolfield repair; use per-step `diff(time)`),
  then the covariates-on-shape engine refactor (byte-identical gate), then polish.

## 2026-06-17 -- v0.2: derive_tcrit() rate-multiplier critical temperature

Goal:

- Add `T_crit`, the last piece of bayesTLS `extract_tdt()`'s absolute family.
  R-only; deterministic transform of the fitted CTmax/z.

Changes:

- `R/predict.R`: new exported `derive_tcrit(object, rate = 1, group = NULL)` =
  `CTmax + z*log10(rate/100)` (rate = % lethal dose/hour, fixed input -- NOT the
  bayesTLS `runif` draw), via the shared `tls_predict_pars()` group resolver;
  emits the lethal-endpoint caveat once per call. `tests/testthat/test-predict.R`
  +3 tests (RED-first: "could not find function derive_tcrit"). Docs: `_pkgdown.yml`,
  NEWS, ROADMAP, design/46; after-task `2026-06-17-v0.2-tcrit.md`.

Checks run:

- `R -q -e 'devtools::document(".")'` -> OK, no warnings.
- `R -q -e 'devtools::test(".")'` -> `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 355 ]`
  (was 347; +8).
- `R -q -e 'rcmdcheck::rcmdcheck(args="--no-manual", build_args="--no-manual",
  env=c("_R_CHECK_FORCE_SUGGESTS_"="false"), error_on="never")'` -> `Status: OK`
  (0/0/0).
- Probe: `derive_tcrit(fit, 100) == CTmax`; `derive_tcrit(fit, c(0.1,1,10))` below
  CTmax and increasing in rate.

Interpretation:

- bayesTLS `extract_tdt()` absolute family now matched by ML (derive_ctmax +
  derive_tcrit). Flagged: design/46 lists "heat-injury ... non-goal" but the
  handoff lists a v0.2 heat-injury PREDICTION item -- reconcilable (fitting
  injury/repair = non-goal; deterministic prediction from the fitted curve = the
  v0.2 item). Next slice (#10) resolves and documents this, then implements
  predict_heat_injury; then covariates (engine, byte-identical gate); then polish.

## 2026-06-17 -- v0.2: deterministic heat-injury prediction

Goal:

- Add `predict_heat_injury()`, the ML analogue of
  `bayesTLS::predict_heat_injury()`. Maintainer was asked about the bayesTLS
  boundary and chose "implement (prediction only)": predict injury from the
  fitted curve; do not fit injury/repair models. R-only.

Changes:

- `R/heat_injury.R` (new): `predict_heat_injury(object, trace, group, t_c,
  repair, irreversible)` -- relative `LT(T) = tref*10^((CTmax-T)/z)`,
  `dmg = 1/LT`, forward-Euler dose accumulation over per-step `diff(time)`,
  survival from dose via the 4PL (one lethal dose -> midpoint), optional `t_c`
  cutoff, optional Sharpe-Schoolfield `repair` (Kelvin; warned as not identified
  by the data). Internal `tls_repair_rate_schoolfield()`.
  `tests/testthat/test-heat-injury.R` (new, RED-first). Docs: `_pkgdown.yml`,
  NEWS, ROADMAP, design/46 (reframed the non-goal line: fitting = bayesTLS,
  prediction = freqTLS), known-limitations (reframed line + new section);
  after-task `2026-06-17-v0.2-heat-injury.md`.

Checks run:

- `R -q -e 'devtools::document(".")'` -> OK, no warnings.
- `R -q -e 'devtools::test(".")'` -> `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 368 ]`
  (was 355; +13).
- `R -q -e 'rcmdcheck::rcmdcheck(args="--no-manual", build_args="--no-manual",
  env=c("_R_CHECK_FORCE_SUGGESTS_"="false"), error_on="never")'` -> `Status: OK`
  (0/0/0).
- Probe: constant 38 C to t = LT(38) -> dose ~ 1, survival ~ relative midpoint
  (ties to derive_lt); below-`t_c` trace stays dose 0 / survival up; positive
  repair lowers final dose and raises survival.

Interpretation:

- Heat-injury prediction shipped as the ML complement (prediction only; fitting
  injury/repair stays a bayesTLS non-goal, now documented as such). Only the
  covariates-on-shape engine refactor (byte-identical gate; needs a decisions.md
  entry) and polish remain in the v0.2 "do all" run.

## 2026-06-17 -- v0.2: shape-parameter design engine (covariates 11a)

Goal:

- Byte-identical engine half of covariates on low/up/log_k: shape params take
  design matrices (no new capability yet). decisions.md entry added relaxing the
  midpoint-only invariant.

Changes:

- `src/profile_tls.cpp`: beta_low/beta_gap/beta_logk -> PARAMETER_VECTOR with
  X_low/X_gap/X_logk; a SINGLE shape coefficient uses a scalar path (matrix
  product skipped) so the shared-shape NLL is bit-identical; per-column low/up/k
  reported as vectors. `R/fit_tls.R`: intercept-only shape designs + n_shape
  start. `R/profile.R`: contrast refit passes intercept-only shape designs.

Checks run:

- `R -q -e 'devtools::test(".")'` -> `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 368 ]`.
- git-stash baseline comparison: well-conditioned binomial fits (seeds 1, 7)
  BIT-IDENTICAL (max abs diff 0); degenerate bb-on-clean fit matches baseline on
  pdHess (TRUE) and warnings (none), MLE within ~1e-5. First attempt (matrix
  product for all cases) shifted the MLE ~1e-4 and flipped pdHess -> the scalar
  guard fixes it.
- `R -q -e 'rcmdcheck::rcmdcheck(args="--no-manual", build_args="--no-manual",
  env=c("_R_CHECK_FORCE_SUGGESTS_"="false"), error_on="never")'` -> Status: OK
  (0/0/0).

Interpretation:

- Engine groundwork for grouped shapes committed as a verified byte-identical
  refactor. 11b exposes grouped low/up/log_k (formula + simulate + per-group
  estimates/predict/plot/profile + tests). Then polish + the freq-vs-Bayes
  vignette (now scoped to also cover clamping/shrinkage/penalties as implicit
  priors, with references).

## 2026-06-17 -- v0.2: grouped covariate effects on low/up/log_k (11b)

Goal:

- Expose the 11a engine groundwork: grouped shapes via the formula interface,
  with per-group estimates, Wald intervals, and predict. Final v0.2 feature.

Changes:

- `R/formula.R`: build X_low/X_gap(from up)/X_logk, enforce shared-design + same-
  as-CTmax constraints. `R/fit_tls.R`: forward shape designs; n_shape -> starts /
  name_map; per-group estimates rows + SEs. `R/utils.R`: per-group shape coords in
  the name map. `R/extract.R`: grouped up:<g> Wald via per-column ADREPORT SE.
  `R/predict.R`: `tls_predict_pars()` resolves per-row CTmax/z/low/up/k (removed
  `tls_shape_estimates`); predict / derive_lt / derive_ctmax / predict_heat_injury
  use it. `R/profile.R` + `R/bootstrap.R`: clear errors for grouped shape coords /
  fits (use Wald). `R/simulate.R`: per-group low/up/k (binomial/bb RNG unchanged).
  New `tests/testthat/test-shape-covariates.R`; one v0.1 formula test updated.

Checks run:

- `R -q -e 'devtools::document(".")'` -> OK, no warnings.
- `R -q -e 'devtools::test(".")'` -> `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 379 ]`
  (was 368; +11).
- `R -q -e 'rcmdcheck::rcmdcheck(args="--no-manual", build_args="--no-manual",
  env=c("_R_CHECK_FORCE_SUGGESTS_"="false"), error_on="never")'` -> Status: OK
  (0/0/0).
- Probe: 2-group fit, truth k=c(4,8) -> k:A 3.58 / k:B 7.66 (finite SEs);
  tidy_parameters k:A [2.93,4.37], k:B [6.30,9.32]; per-group predict in (0,1).

Interpretation:

- v0.2 feature roadmap complete (beta, RE profiling, T_crit, heat-injury,
  covariate shapes). Remaining: polish (dashboard, matrix, vignettes, site) and
  the freq-vs-Bayes article (standalone vignette, incl. clamping/shrinkage/
  penalties as implicit priors with references).

## 2026-06-17 -- v0.2: frequentist-vs-Bayesian article (standalone vignette)

Goal:

- Maintainer-requested conceptual vignette on strengths/weaknesses of the
  likelihood vs Bayesian paths, including clamping/shrinkage/penalties as
  implicit priors, with verified references.

Changes:

- `vignettes/frequentist-and-bayesian.Rmd` (new): 8 sections (philosophies;
  priors; identifiability; non-convergence; compatibility vs credible; the
  blurry line = clamping/shrinkage/penalty as implicit priors; agreement vs
  divergence; guidance). Live Stan-free illustrations: a sparse fit whose `z`
  profile is `open_both`, and a no-pooling-vs-partial-pooling BLUP shrinkage
  demo. 15 verified references with DOIs. `_pkgdown.yml` articles index updated;
  NEWS bullet; after-task `2026-06-17-v0.2-freq-bayes-vignette.md`.

Checks run:

- `R -q -e 'rmarkdown::render("vignettes/frequentist-and-bayesian.Rmd")'` ->
  KNIT OK (chunks run Stan-free).
- References verified by a literature-curation pass (authors/year/title/venue/DOI
  against Crossref + publisher pages); all 14 originals correct, + Bishop 2006
  for penalty=MAP.
- `R -q -e 'rcmdcheck::rcmdcheck(args="--no-manual", build_args="--no-manual",
  env=c("_R_CHECK_FORCE_SUGGESTS_"="false"), error_on="never")'` -> Status: OK
  (0/0/0) -- builds the new vignette.

Interpretation:

- The article ships the complementary-framing centrepiece, honestly noting the
  frequentist path is *lightly regularised*, not assumption-free. Only polish
  remains (dashboard refresh, final matrix pass, site rebuild).

## 2026-06-17 -- v0.2 polish and close-out

Goal:

- Sync public capability and refresh the stale internal status board; close the
  v0.2 "do all" run.

Changes:

- `README.Rmd`/`README.md`: v0.2 capabilities bullet (RE intercept + profile,
  grouped shape covariates, derive_ctmax/derive_tcrit, predict_heat_injury) +
  vignette pointer; re-knit (prose-only diff). `docs/dev-log/dashboard/status.json`:
  updated -> 2026-06-17, repo head/note (379 tests, full v0.2 set), the stale
  "unsupported" matrix row -> implemented. after-task `2026-06-17-v0.2-closeout.md`.

Checks run:

- `python3 -m json.tool status.json` -> valid JSON.
- `R -q -e 'devtools::build_readme()'` -> OK; README.md diff +8 lines (prose).
- `R -q -e 'pkgdown::check_pkgdown()'` -> "No problems found".
- Package last R CMD check 0/0/0 at the article commit; README/dashboard are
  doc-only (not in the package build); the pkgdown site redeploys via CI on push.

Interpretation:

- **v0.2 "do all" run COMPLETE.** Seven verified slices shipped (beta, RE
  profiling, T_crit, heat-injury, shape-design engine, grouped shape covariates,
  freq-vs-Bayes vignette) + this close-out. 309 -> 379 tests, every slice
  0/0/0, byte-identical gate held throughout. Carried-forward: profile/bootstrap
  of grouped shape coords, RE-aware bootstrap, general continuous shape
  covariates, absolute-target heat injury, the Stan-built benchmark cache, CRAN
  hardening.

## 2026-06-17 -- post-v0.2: RE-aware parametric bootstrap for sigma_CTmax

Goal:

- Prior-free interval for the random-effect SD (the package's weakest interval).
  First deferred item after the maintainer's "go ahead".

Changes:

- `R/bootstrap.R`: removed the RE-abort guard; RE path redraws b_g ~ N(0, sigma)
  into the compiled full par, recomputes p via obj$report (cpp map), draws y,
  refits with random="b_CT", re-pins, collects sigma_CTmax. rep0 uses the full
  par for RE. tls_boot_target: sigma_CTmax on the log scale. `R/confint.R`: RE +
  method="bootstrap" now runs the RE-aware bootstrap (speed note). Non-RE path
  byte-identical (guarded on is_re; draw_from_p(p_hat) == old draw_y).
- Tests: rewrote the RE bootstrap contract test; added a skip_on_cran RE-bootstrap
  recovery test. Docs: design/08, design/46, known-limitations, ROADMAP, NEWS;
  after-task `2026-06-17-v0.2-re-bootstrap.md`.

Checks run:

- `R -q -e 'devtools::test(".")'` -> `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 383 ]`
  (was 379).
- `R -q -e 'rcmdcheck::rcmdcheck(args="--no-manual", build_args="--no-manual",
  env=c("_R_CHECK_FORCE_SUGGESTS_"="false"), error_on="never")'` -> Status: OK
  (0/0/0).
- Probe: 8-group RE fit, confint("sigma_CTmax", method="bootstrap", nboot=40) ->
  finite positive interval, method "bootstrap"; CTmax bootstrap covers truth.

Interpretation:

- The weakest interval (sigma_CTmax Wald) now has a prior-free bootstrap
  alternative. Remaining deferred: grouped-shape-coord profile/bootstrap,
  absolute-target heat injury, a flagship example; CRAN hardening held for
  explicit confirmation (release-gating).

## 2026-06-17 -- post-v0.2: profile + bootstrap for grouped shape coordinates

Goal:

- Complete grouped shapes: per-group low:<g>/up:<g>/k:<g> get profile + bootstrap
  intervals, not just Wald. Maintainer chose the "quick feature-completions".

Changes:

- `R/profile.R`: tls_resolve_target resolves low:<g> (beta_low, plogis) and k:<g>
  (beta_logk, exp) as profile coords; up:<g> -> delta-method Wald (nested gap);
  new tls_shape_index() (shared-vs-grouped, counts beta_low coords); removed the
  grouped-shape profile guard; tls_up_wald_profile parameterised; low/k dropped
  from scalar_map. `R/bootstrap.R`: removed the grouped-shape guard; per-group
  shape replicates (low_names/up_names/k_names). Scalar shape path byte-identical.
- Tests: +3 in test-shape-covariates.R. Docs: NEWS, known-limitations, matrix,
  ROADMAP; after-task `2026-06-17-v0.2-grouped-shape-intervals.md`.

Checks run:

- `R -q -e 'devtools::test(".")'` -> `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 389 ]`
  (was 383).
- `R -q -e 'rcmdcheck::rcmdcheck(args="--no-manual", build_args="--no-manual",
  env=c("_R_CHECK_FORCE_SUGGESTS_"="false"), error_on="never")'` -> Status: OK
  (0/0/0).
- Probe: 2-group fit, confint("k:A", method="profile") finite/ordered; up:A Wald;
  low:A bootstrap.

Interpretation:

- Grouped shapes are now interval-complete (profile/Wald/bootstrap). Next:
  absolute-target heat injury, flagship README example, the data reanalysis +
  new-dataset vendoring (research agent running), then larger features + CRAN.

## 2026-06-17 -- post-v0.2: absolute-target heat injury (`target_surv`)

Goal:

- Generalise `predict_heat_injury()` from the project-default relative lethal
  threshold (one lethal dose = the curve midpoint survival) to an absolute
  survival target. R-only; default behaviour byte-identical. Item 1 of the
  remaining "do all" roadmap.

Changes:

- `R/heat_injury.R`: new `target_surv = NULL` argument; `q = qlogis((target_surv
  - low)/(up - low))` (`q = 0` for `NULL`); lethal time `lt` gains `- q/k`;
  `survival_from_dose()` gains `+ q`, so `D = 1` reaches `target_surv` exactly.
  Validation: a single probability strictly inside `(low, up)`. Roxygen rewritten
  (dose-accumulation model + `@param target_surv`). `man/predict_heat_injury.Rd`
  regenerated.
- `tests/testthat/test-heat-injury.R`: +3 TDD tests (RED-first). Docs synced:
  NEWS, ROADMAP, `docs/dev-log/known-limitations.md`,
  `docs/design/46-capability-matrix.md`; after-task
  `2026-06-17-v0.2-absolute-heat-injury.md`.

Checks run (exact):

- RED: 3 new tests errored `unused argument (target_surv = ...)`; the 10 existing
  heat-injury expectations passed unchanged.
- `testthat::test_file("tests/testthat/test-heat-injury.R")` -> `[ FAIL 0 | PASS
  22 ]`.
- `R -q -e 'devtools::document(".")'` -> rewrote the Rd, no warnings.
- `R -q -e 'devtools::test(".")'` -> `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 398 ]`
  (was 389; +9). The 389 pre-existing expectations pass unchanged (relative
  default byte-identical, `qlogis(0.5) = 0`).
- `rcmdcheck::rcmdcheck(args = "--no-manual", build_args = "--no-manual",
  env = c("_R_CHECK_FORCE_SUGGESTS_" = "false"), error_on = "never")` ->
  `0 errors | 0 warnings | 0 notes`.

Interpretation:

- The absolute target is pinned to the independently-implemented `derive_lt()`
  (the Phase-4 4PL inverse): one lethal time of constant exposure to the
  `target_surv` lethal time gives `dose -> 1` and `survival -> target_surv`. The
  `q = 0` midpoint reduces to the relative path to `1e-10`, so the default is
  byte-identical. Next: item 2, the flagship grouped-shape README example.

## 2026-06-17 -- bugfix: formula-interface grouped fits carry their group vector

Goal:

- Fix a pre-existing bug surfaced while building the item-2 example:
  `plot_survival_curves()` errored on every formula-interface grouped fit.
  Maintainer approved fixing at source. TDD; R-only; no engine change.

Root cause:

- `fit_tls()`'s formula branch hardcoded `group_v <- NULL`, so
  `fit$diag_data$group` was empty for formula-grouped fits (the column interface
  populated it). The observed-point overlay in `plot_survival_curves()` then
  failed (`"replacement has 0 rows, data has N"`), and the group-aware
  diagnostics fell back to the ungrouped checks. Curves were fine (they use
  `fit$group_levels`).

Changes:

- `R/formula.R`: the single-factor design returns `group = as.character(g)`;
  `tls_parse_formula()` surfaces it as `group = ct_design[["group"]]` (exact `[[`,
  not `$` -- `$group` partial-matches the ungrouped design's `grouped` key to
  `FALSE`). `R/fit_tls.R`: formula branch `group_v <- spec$group`.
- `tests/testthat/test-formula.R`: +4 tests. Docs: NEWS (bug-fix bullet),
  known-limitations (stale "warnings fall back to ungrouped" note replaced);
  after-task `2026-06-17-v0.2-formula-group-vector.md`.

Checks run (exact):

- RED: grouped-vector + plot tests failed (plot with the exact `"replacement has
  0 rows, data has 210"`); first GREEN tripped the ungrouped guard
  (`diag_data$group == FALSE` via `$` partial match), fixed with `[["group"]]`.
- `R -q -e 'devtools::test(".")'` -> `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 402 ]`
  (was 398; +4). Group-aware diagnostics now firing on formula fits regressed no
  existing expectation.
- `rcmdcheck::rcmdcheck(args = "--no-manual", build_args = "--no-manual",
  env = c("_R_CHECK_FORCE_SUGGESTS_" = "false"), error_on = "never")` ->
  `0 errors | 0 warnings | 0 notes`.

Interpretation:

- The formula and column interfaces now agree on `diag_data$group`, so
  `plot_survival_curves()`, the group-aware diagnostics, and any other
  `diag_data$group` consumer work uniformly. The partial-match defect (a silent
  `FALSE`) was caught by the ungrouped TDD guard -- worth keeping. Next: item 2.

## 2026-06-17 -- item 2: flagship grouped-shape README example

Goal:

- Add a worked front-page example of grouped covariate effects on the shape
  parameters (the v0.2 capability without a README example). Docs-only.

Changes:

- `README.Rmd`: new section *Population differences in curve shape* -- a tolerant
  vs sensitive population differing in `CTmax` and steepness `k`, fitted with
  grouped `CTmax`/`log_z`/`low`/`up`/`log_k`; prints per-group `k` profile CIs +
  faceted survival curves. `README.md` re-knit;
  `man/figures/README-grouped-shape-curves-1.png` generated. Depends on the
  group-vector fix (`4264609`). after-task
  `2026-06-17-v0.2-readme-grouped-shape-example.md`.

Checks run (exact):

- `R -q -e 'devtools::build_readme()'` -> built cleanly; real output
  `k:tolerant` 8.86 [7.43, 10.6], `k:sensitive` 2.90 [2.40, 3.48], both
  `conf.status = ok` (non-overlapping). `grep -c "## Warning|## Error" README.md`
  -> 0.
- Figure inspected as an image: two facets (sensitive/tolerant), steep vs gradual
  survival declines, observed points overlaid -- honest, publication-quality.
- `rcmdcheck::rcmdcheck(args = "--no-manual", build_args = "--no-manual",
  env = c("_R_CHECK_FORCE_SUGGESTS_" = "false"), error_on = "never")` ->
  `0 errors | 0 warnings | 0 notes` (no package code changed; the figure is
  referenced by README.md).

Interpretation:

- The shape difference (`k`) is shown to be identified, not assumed -- the
  flagship demonstration of the relaxed midpoint-only invariant. Next: item 3
  (reanalyse vendored datasets + re-run the dataset search; vendor only
  clearly-licensed data, with maintainer sign-off before adding any dataset).

## 2026-06-17 -- item 3a: v0.2 reanalysis section in the comparison vignette

Goal:

- Reanalyse the vendored benchmark datasets with the v0.2 features and expand the
  comparison vignette (maintainer-directed). Stan-free; freqTLS live; existing
  data only (new-dataset vendoring is item 3b, gated).

Changes:

- `vignettes/comparing-to-bayesTLS.Rmd`: new capstone section *Beyond the matched
  shape: stage-specific curves (v0.2)* -- re-fits `zebrafish_lethal` with grouped
  `low`/`up`/`log_k`, AIC vs the shared-shape config, per-stage `up`, and the
  shrimp `derive_ctmax` / `predict_heat_injury`. after-task
  `2026-06-17-v0.2-reanalysis-vignette.md`.

Finding:

- Shared-shape AIC 1221.8 (df 10) vs stage-shape 1187.0 (df 16): dAIC 34.8 for
  stage-specific shapes. Driven by `up` (max survival): young embryos 0.718 (SE
  0.032) vs old 0.918 (0.015), larvae 0.939 (0.025). The constant-shape benchmark
  config cannot express this.

Checks run (exact):

- `rmarkdown::render(...)` FAILED first against the STALE installed package
  (pre-`5a9b78a`, before grouped shapes -- a render `library()`s the installed
  build, not the dev source). After `R CMD INSTALL .` -> `RENDER OK`, Stan-free.
  Values cross-checked against the installed package directly (AIC 1221.8/1187.0,
  up 0.718/0.918/0.939, derive_ctmax 31.73, surv_32C_4h 0.017).
- `rcmdcheck::rcmdcheck(args = "--no-manual", build_args = "--no-manual",
  env = c("_R_CHECK_FORCE_SUGGESTS_" = "false"), error_on = "never")` ->
  `0 errors | 0 warnings | 0 notes` (the check reinstalls the package before
  building vignettes, so it exercises the current grouped-shape engine).

Interpretation:

- The reanalysis shows freqTLS adds a real, identified result beyond the
  matched benchmark (stage-specific survival ceilings). The stale-install render
  gotcha is recorded: always `R CMD INSTALL` (or rely on R CMD check) before
  trusting a standalone vignette render. Next: item 3b -- maintainer approved
  vendoring `snowgum_psii` (CC BY 4.0) to showcase the v0.2 Beta family.

## 2026-06-17 -- item 3b: vendor snowgum_psii (beta-family real dataset)

Goal:

- Give the v0.2 beta family a real dataset. From the `landscape_scout` candidates
  the maintainer chose `snowgum_psii` (CC BY 4.0). Vendor with attribution.

Changes:

- new `data/snowgum_psii.rda` (319 rows: temp 28-48 C, duration 5-120 MIN, prop =
  final/initial Fv/Fm in [0,1]); built by a focused reshape of the bayesTLS CSV so
  shrimp/zebrafish `.rda` are untouched. `data-raw/make_benchmark_data.R` gains
  the reproducible snowgum download/reshape. `R/data.R` doc (+ boundary-zero
  section + runnable beta example), `man/snowgum_psii.Rd`. Attribution:
  `inst/CITATION`, `inst/COPYRIGHTS`. `tests/testthat/test-data-snowgum.R`. Docs:
  NEWS, README (Data credits, prose mirror), design/46, known-limitations.

Checks run (exact):

- RED: test failed `object 'snowgum_psii' not found`.
- `R -q -e 'devtools::test(".")'` -> `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 410 ]`
  (was 402; +8).
- Verified beta fit (load_all): CTmax 46.5 [45.9, 47.1], z 6.5 [5.9, 7.2], conv
  0, pdHess TRUE; 60 boundary zeros clamped with the documented warning.
- `rcmdcheck::rcmdcheck(args = "--no-manual", build_args = "--no-manual",
  env = c("_R_CHECK_FORCE_SUGGESTS_" = "false"), error_on = "never")` ->
  `0 errors | 0 warnings | 0 notes` (the new `.rda`, its example, and the data
  docs are all in the package build).

Interpretation:

- The beta family now has a real, identifiable showcase dataset. The 60
  complete-loss rows at `prop == 0` are vendored raw (not pre-clamped) so the
  honest clamp-with-warning behaviour is visible. Item 3 complete (reanalysis
  vignette + snowgum). Next: item 4 (general continuous covariates on the shapes).

## 2026-06-17 -- item 4: general continuous covariates on the shape parameters

Goal:

- Support a general (continuous) covariate on a shape sub-parameter
  (`log_k ~ body_size`) independently of the other shapes and of `CTmax`/`log_z`,
  end to end. Re-attempted after a process crash corrupted the first attempt; the
  byte-identical engine change was committed separately first (`4987423`).

Changes:

- `src/profile_tls.cpp` (`4987423`): per-shape `low_shared`/`gap_shared`/
  `logk_shared` detection + per-observation paths; report block sizes low/up/k to
  their own coefficient vectors. Byte-identical (max|diff| = 0).
- R rework: `tls_default_start` per-shape widths; `tls_name_map` + `tls_estimates`
  classify each shape (scalar / one-hot / general) -- general designs report
  LINK-scale `beta_*` coefficients with SE from the sdreport FIXED block;
  `R/formula.R` drops the same-design constraint and stores `shape_terms`;
  `R/predict.R` rebuilds a shape design from newdata and applies the forward map;
  `R/confint.R` routes general (group = NA) shape coefficients to a LINK-scale
  Wald (not back-transformed). Two constraint-rejection tests updated to assert
  the relaxed behaviour; new `tests/testthat/test-shape-continuous.R`.

Checks run (exact):

- Byte-identical: binomial / grouped-shape / beta-binomial fits reproduce the
  HEAD baseline estimates to `max|diff| = 0` after the engine + R rework.
- `R -q -e 'devtools::test(".")'` -> `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 423 ]`
  (was 410).
- Acceptance (`log_k ~ x`, truth slope 0.6): conv 0; `k:x` = 0.575 (log scale);
  predict varies with `x`; Wald CI [0.463, 0.688] brackets the estimate; profile
  routes to Wald.
- `rcmdcheck(args="--no-manual", build_args="--no-manual",
  env=c("_R_CHECK_FORCE_SUGGESTS_"="false"), error_on="never")` ->
  `0 errors | 0 warnings | 0 notes`.

Interpretation:

- Item 4 complete. General continuous covariates on the shapes fit, predict, and
  report link-scale coefficients with Wald intervals; the byte-identical gate held
  throughout (engine committed separately and verified). Next: item 5 (RE beyond a
  single CTmax intercept) and the case-study articles.

## 2026-06-17 -- case-study articles, dsuzukii vendoring, v0.2.0 release + site deploy

Goal:

- Build bayesTLS-parity case-study articles, vendor the dsuzukii lethal-by-sex
  data, bump to 0.2.0, and refresh the stale live pkgdown site.

Changes:

- New articles (`4be7366`): `vignette("case-study-suzukii")` (D. suzukii lethal
  across sexes; recovers Orsted 2024 CTmax ~35.2 / z 3.0-3.2; sex diffs span 0),
  `vignette("heat-injury")` (deterministic injury under a trace + bootstrap
  envelope), `vignette("case-study-summary")` (cross-case Confidence-Eye panel,
  4 taxa). Shrimp + zebrafish three-way remain in `comparing-to-bayesTLS`;
  snowgum is in the summary + `?snowgum_psii`.
- New dataset `dsuzukii_lethal` (94 cells, mortality by sex; CC BY 4.0, Zenodo
  10602268) with doc, test, provenance script, CITATION/COPYRIGHTS/README.
- `_pkgdown.yml`: Case studies navbar; snowgum_psii + dsuzukii_lethal in the
  reference index. Version bumped to 0.2.0 (`d4ee0c9`).

Checks run (exact):

- `devtools::test()` -> 431 pass / 0 fail.
- `rcmdcheck(... _R_CHECK_FORCE_SUGGESTS_=false ...)` -> 0 errors / 0 warnings /
  0 notes (all 8 vignettes build Stan-free).
- `pkgdown::check_pkgdown()` -> No problems found.
- `pkgdown::build_site()` -> built; the cross-case Confidence-Eye panel inspected
  as a rendered image (honest interval lenses + hollow points, compatibility
  language, no posterior).
- `pkgdown::deploy_to_branch()` -> pushed gh-pages `c7a5cb7..f330d5b` (force);
  the stale live site is refreshed at v0.2.0.

Interpretation:

- The live site now carries every article (incl. frequentist-vs-Bayes, which the
  maintainer had seen missing only because the deploy was frozen at 600ba71) plus
  the new case studies. NOT built (3 subagents stalled on the three-way cache
  logic): dedicated shrimp / zebrafish / snowgum case-study articles -- their
  content is covered by `comparing-to-bayesTLS` (shrimp + zebrafish three-way) and
  the cross-case summary + dataset docs. The snowgum + dsuzukii bayesTLS/two-stage
  comparison columns need the Stan cache rebuilt (maintainer-run). Minor: the
  heat-injury vignette uses an internal `:::` for the bootstrap envelope (R CMD
  check clean; a candidate to promote to an export).

## 2026-06-17 -- Random intercept on log_z (item 5, v0.3)

Goal:

- Land the first slice of roadmap item 5: a random intercept on `log_z`
  (`log_z ~ <fixed> + (1 | group)`), the symmetric counterpart of the v0.2 random
  intercept on `CTmax`, under the byte-identical engine gate.

Changes:

- Engine `src/profile_tls.cpp`: `re_index_logz` / `b_logz` / `log_sd_logz`
  (appended last), the deviation added to `logz_i` before `exp()` under a
  `b_logz.size()>0` guard, the `dnorm` prior and `sigma_logz`/`b_logz` reports
  under the same guard.
- R: `tls_extract_re()` (generalised parser, called for CTmax and log_z),
  `tls_has_re()`/`tls_re_blocks()` (R/utils.R), and the routing in
  fit_tls/methods/extract/confint/profile/bootstrap/plotting generalised to the
  blocks; `simulate_tls(re_sd_z=)`; same-grouping-on-both warning. New tests in
  `tests/testthat/test-random-effects-logz.R`; two scope tests flipped.
- Docs synced one commit: NEWS (0.3.0), ROADMAP, design/08, known-limitations,
  capability-matrix, decisions, README.Rmd (+re-knit README.md), DESCRIPTION
  (0.2.0 -> 0.3.0), man/.

Checks run:

- `devtools::test()` -> `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 498 ]` (was 431; the
  byte-identical gate held -- every pre-existing test passed with original values,
  and the slow Laplace-profile / RE-aware-bootstrap tests ran, SKIP 0).
- `rcmdcheck::rcmdcheck(args="--no-manual", build_args="--no-manual",
  env=c("_R_CHECK_FORCE_SUGGESTS_"="false"), error_on="never")` -> 0 errors / 0
  warnings / 0 notes.
- `pkgdown::check_pkgdown()` -> clean. `devtools::build_readme()` -> clean.

Interpretation:

- Item 5 slice 1 (log_z RE) is landed and verified. Reviewed pre-implementation by
  Gauss/Noether/Emmy/Fisher and post-implementation by Ada/Rose (four stale prose
  spots fixed). Next: optional item-5 stretch (RE on shapes / a second grouping
  factor, reusing `tls_re_blocks()`), then the zebrafish three-way cache fix and
  the `plot_heat_injury` / bootstrap-helper export. Pre-existing `tls_bf`
  shape-sharing roxygen drift noted for a separate one-line fix.

## 2026-06-17 -- Zebrafish three-way fix + heat-injury envelope/plot exports (v0.3)

Goal:

- Two follow-ups from the v0.2.0 handover: (1) the zebrafish case-study three-way
  table fell back to freqTLS-only; (2) the heat-injury vignette reached into the
  package with `freqTLS:::tls_bootstrap_replicates`.

Changes:

- **Zebrafish (commit d5cea79):** the cache lookup checked a bare `"zebrafish"`
  key and a nonexistent `group` column; the cache keys stages as
  `"zebrafish:<life_stage>"`. Fixed the lookup; now shows both CTmax and z per
  stage with honest profile CIs (parity with shrimp). Vignette-only; verified by a
  standalone render + a targeted table check (`cache_has_zebra: TRUE`, all three
  estimators populated).
- **Heat-injury exports:** extracted `predict_heat_injury()`'s forward-Euler
  integrator into an internal `tls_injury_traj()` (byte-identical); added exported
  `heat_injury_envelope()` (prior-free parametric-bootstrap compatibility band) and
  `plot_heat_injury()` (draws it, honest caption naming the variability source +
  B). The heat-injury vignette now calls these (no `:::`, no inline
  re-implementation). New `tests/testthat/test-heat-injury-envelope.R`; both
  exports added to `_pkgdown.yml`.

Checks run:

- `devtools::test()` -> `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 514 ]` (byte-identical
  `predict_heat_injury` confirmed: `test-heat-injury` unchanged).
- `rcmdcheck::rcmdcheck(args="--no-manual", build_args="--no-manual",
  env=c("_R_CHECK_FORCE_SUGGESTS_"="false"), error_on="never")` -> 0/0/0.
- `pkgdown::check_pkgdown()` -> clean (after listing the two exports; the check
  correctly flagged them missing from the index first).

Interpretation:

- Both handover follow-ups landed and verified. Reviewed by Florence (the new
  heat-injury figure: figure-honest; caption gained the variability source +
  replicate count). One self-caught test wrinkle: the first "envelope widens"
  assertion targeted the saturated tail instead of the high-damage transition
  (fixed with a ramp trace). Remaining: item-5 stretch (RE on shapes / crossed
  factors) is a larger engine-design effort; the Stan-cache rebuild stays
  maintainer-run (no cmdstanr here).

## 2026-06-17 -- Random intercepts on shape coordinates low / log_k (v0.3, item-5 stretch)

Goal:

- Extend the random-intercept system from CTmax / log_z to the shape coordinates
  `low` and `log_k`, completing "random effects on any sub-parameter" (up excluded:
  no single coordinate). Crossed / nested REs deferred (engine redesign).

Changes:

- Engine `src/profile_tls.cpp`: `re_index_low` / `re_index_logk` +
  `b_low` / `log_sd_low` / `b_logk` / `log_sd_logk` (appended); the deviation is
  added on each shape's internal scale under a `b_*.size() > 0` guard, with the
  no-RE branch kept as the original expressions verbatim (byte-identical); up_i
  recomputed from the shifted low_i.
- R: `tls_extract_re()` now applied to `low` / `log_k` shape RHSs (`up` bar
  rejected); `tls_re_blocks()` / `tls_has_re()` / fit_tls / extract / confint /
  bootstrap / contrast-refit / print extended to the two blocks; the same-grouping
  warning generalised across CTmax / log_z / low / log_k; `simulate_tls(re_sd_low=,
  re_sd_logk=)`. New `tests/testthat/test-shape-random-effects.R`; two scope tests
  updated (a `low` RE is now accepted; only `up` is rejected).
- Docs synced: NEWS, design/08, capability-matrix, known-limitations, decisions,
  README.Rmd (+ re-knit), man/ (also fixed a stale cross-package `\link` in
  heat_injury_envelope.Rd).

Checks run:

- Standalone byte-identical gate (engine + plumbing, before the parser surface):
  `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 514 ]`.
- `devtools::test()` (full, after the parser surface + test fixes):
  `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 555 ]`.
- `rcmdcheck::rcmdcheck(...)` -> 0/0/0. `pkgdown::check_pkgdown()` -> clean.

Interpretation:

- Item 5 is substantially complete: RE intercepts on CTmax / log_z / low / log_k,
  all reusing `tls_re_blocks()`. The remaining RE work (crossed / nested grouping
  factors, correlated multivariate REs) needs a stacked-random-vector engine
  redesign and is documented as a focused next slice; `bayesTLS` is the path for
  correlated structures meanwhile. Reviewed by Gauss (engine) and Ada (integration).

## 2026-06-18 -- Benchmark cache: all four case-study datasets (suzukii + snowgum)

Goal:

- Populate the bayesTLS + classical two-stage benchmark cache for the two
  case-study datasets it never covered (`dsuzukii_lethal`, `snowgum_psii`) so the
  D. suzukii and snow-gum PSII articles render their comparisons instead of a
  "pending cache" note, and wire those two vignettes to read the cache. The build
  script predated both datasets (vendored 2026-06-17) and only ever fitted shrimp
  + zebrafish.

Changes:

- Generalised `data-raw/build_benchmark_cache.R` from a global config to a
  per-dataset config (duration column, native time unit, tref, group, family,
  response type, two-stage applicability). Added D. suzukii (counts, grouped by
  sex, tref 240 min -> full three-way) and snow-gum PSII (continuous proportion,
  Beta family, tref 5 min -> bayesTLS-only, no count two-stage). shrimp + zebrafish
  config unchanged. All interval-bearing fits stay on the relative-midpoint
  threshold (the freqTLS CTmax parameter).
- Rebuilt `inst/extdata/bayesTLS_benchmark_cache.rds` (bayesTLS 1.0.0, CmdStan
  2.36.0, seed 123; meta now carries a per-dataset `datasets` block).
- Wired `case-study-suzukii.Rmd` (per-sex three-way) and `case-study-leaf-psii.Rmd`
  (beta two-way) to read the cache; replaced their "pending cache" sections; fixed
  an inaccurate "bayesTLS consumes counts" line (bayesTLS does offer a Beta family).
- DoD sync: NEWS + DESCRIPTION (0.3.1), known-limitations, design/06, design/46.

Checks run:

- `Rscript data-raw/build_benchmark_cache.R` -> wrote the cache; 7 bayesTLS fits +
  6 two-stage fits, all chains finished successfully.
- Reproduction check (new vs backed-up cache): shrimp + zebrafish bayesian medians
  reproduce to <= 0.006 (interval bounds <= 0.038, MCMC/draw-sampling noise);
  two_stage rows bit-identical (max abs diff 0).
- New rows validate vs published values: `dsuzukii:F` CTmax 35.20 [35.07, 35.30] /
  z 3.02; `:M` 35.22 / 3.18 (Orsted ~35.2, 3.03/3.28). `snowgum` CTmax 45.94 /
  z 5.85 (bayesTLS) vs 46.51 / 6.54 (freqTLS), overlapping intervals.
- Vignette chunk logic verified via `devtools::load_all()` running the exact
  three-way chunk code -> correct tables for both vignettes; Rmd fences balanced,
  chunk labels unique (`three-way-suzukii`, `three-way-psii`).
- `devtools::test()` -> `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 560 ]` (SKIP 0:
  test-benchmark-sanity ran against the rebuilt cache and passed the live-vs-cached
  tripwire).

Interpretation:

- The "pending cache" gap is closed for every case study. D. suzukii is a full
  three-way; snow-gum PSII is an honest two-way (a continuous proportion has no
  count two-stage). The headline freqTLS<->bayesTLS agreement is tight on every
  dataset, while the classical two-stage is the cruder estimator (e.g. suzukii F
  CTmax 34.80 vs 35.2 for the two model fits). Next: R CMD check (builds the
  vignettes Stan-free from the cache) before push; the benchmark-sanity tripwire
  could be extended to the suzukii/snowgum configs (a follow-up, noted in
  known-limitations).

## 2026-07-11 -- Get-started function-map repair and CRAN-readiness audit

Goal:

- Repair the function map that broke into ordinary page text on the deployed
  get-started article, then assess local and public CRAN readiness without
  treating green development CI as submission evidence.

Changes:

- `vignettes/freqTLS.Rmd` now emits the inline function-map SVG inside a Pandoc
  raw-HTML fence. This prevents wildcard labels such as `get_*_summary()` from
  becoming HTML `<em>` elements that terminate the SVG namespace.
- The section is now "The core workflow at a glance" rather than "The whole
  API", because the map intentionally omits some exported utilities.
- `tools/build-site.R` now fails when the rendered SVG is missing, unclosed,
  contains `<em>`, loses either wildcard accessor label, or contains fewer than
  60 SVG text nodes.
- `devtools::document()` regenerated two hand-synchronised pages:
  `man/profile.profile_tls.Rd` and `man/tdt_unit_to_minutes.Rd`. The latter
  exposes a real unresolved-link warning recorded below.

Checks run:

- Live pre-fix browser DOM check on
  `https://itchyshin.github.io/freqTLS/articles/freqTLS.html` -> 39 SVG text
  nodes, 19 rectangles, two `<em>` elements inside the SVG, and stray text
  beginning `summary() · get` immediately after the SVG.
- `Rscript --vanilla -e 'pkgdown::build_article("freqTLS", new_process = FALSE,
  quiet = FALSE)'` with the package installed in `/tmp/freqTLS-lib` -> article
  built successfully.
- Local post-fix browser DOM check -> 69 SVG text nodes, 27 rectangles, zero
  `<em>` elements, the literal `get_*_summary() · get_*_draws()` label, a valid
  DOM `viewBox`, and one `#where-to-next` heading after the map.
- `R_LIBS_USER='/tmp/freqTLS-lib:/Users/z3437171/Library/R/arm64/4.6/library'
  Rscript --vanilla tools/build-site.R` -> full site built; internal
  `AGENTS.html`, `CLAUDE.html`, and `SPEC.html` removed; alt text filled on six
  reference pages; the new function-map gate passed.
- `Rscript --vanilla -e 'devtools::document()'` -> completed, with warnings for
  the unresolved `derive_tdt_curve` link and `@noRd` text in `R/utils.R:22`;
  regenerated the two pages named above.
- `Rscript --vanilla -e 'devtools::test()'` ->
  `[ FAIL 0 | WARN 0 | SKIP 1 | PASS 771 ]`. The skip message still describes
  the benchmark cache as old profileTLS-format data.
- `Rscript --vanilla -e 'pkgdown::check_pkgdown()'` -> `No problems found`.
- `Rscript --vanilla -e 'devtools::check_man()'` -> unresolved
  `derive_tdt_curve` cross-reference plus the two roxygen warnings above.
- `Rscript --vanilla -e 'urlchecker::url_check()'` -> the pkgdown URL redirects
  to its trailing-slash form; five DOI endpoints returned HTTP 403 to the
  checker.
- Strict `rcmdcheck::rcmdcheck(args = "--as-cran", error_on = "never")` ->
  `1 ERROR | 0 WARNING | 1 NOTE`: unavailable suggested packages `bayesTLS` and
  `covr`; incoming NOTE for new submission, the non-mainstream `bayesTLS`
  Suggest, the redirecting pkgdown URL, and a 12,567,882-byte tarball.
- Relaxed `rcmdcheck::rcmdcheck(args = "--as-cran",
  env = c("_R_CHECK_FORCE_SUGGESTS_" = "false"), error_on = "never")` ->
  `0 ERROR | 1 WARNING | 2 NOTEs`: missing `derive_tdt_curve` link; the same
  incoming NOTE with a 12,567,884-byte tarball; and non-standard top-level
  `output` and `scripts` directories. Compilation, installation, examples,
  tests, vignette rebuild, and PDF/HTML manuals otherwise passed.
- `curl -LIsS https://cran.r-project.org/package=freqTLS` -> redirect followed
  by HTTP 404 at the package index: freqTLS is not currently on CRAN.
- `gh issue list --state open --limit 100 --json number,title,url` -> `[]`; no
  overlapping open issue was available to update.
- Exact consistency scans:
  `rg -n "whole API|full surface|function map|freqTLS extras|trace & repair"
  README.Rmd ROADMAP.md NEWS.md docs vignettes R tests`;
  `rg -n "posterior|credible" R vignettes README.Rmd docs`;
  `rg -n "planned.*implemented|not implemented yet.*implemented|TODO|FIXME"
  README.Rmd ROADMAP.md docs vignettes R tests`.

Interpretation:

- The function map is repaired in the local rendered artifact and protected by
  the site build. It is not deployed yet.
- The package is implemented broadly and its local tests are healthy, but it is
  not CRAN-ready. Submission blockers include the unresolved Rd link, the
  GitHub-only Suggest strategy, the 12.6 MB tarball and non-standard top-level
  directories, missing submission metadata, and contradictory authoritative
  scope claims across `AGENTS.md`, `SPEC.md`, README/NEWS, the capability
  matrix, and known limitations.

## 2026-07-11 -- freqTLS 0.1.0 CRAN-readiness implementation

Goal:

- Implement the approved CRAN-readiness plan on `codex/cran-readiness`, correct
  the snow-gum licence, exclude permission-pending components, reconcile the
  release contract, and produce an exact locally verified source tarball.

Checks run:

- `Rscript --vanilla -e 'devtools::test()'` ->
  `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 772 ]` in 116 seconds. The bootstrap
  greater-than-two-core test confirmed the warning-and-cap route.
- `Rscript --vanilla -e 'devtools::check_man()'` -> completed with no warnings.
- First `Rscript --vanilla -e 'devtools::check()'` -> `1 ERROR | 0 WARNING |
  2 NOTEs`: escaped `\\donttest{}` generated an invalid example file; the
  linked-worktree `.git` pointer and `cran-comments.md` entered the build.
- After correcting the roxygen markup and adding anchored build exclusions,
  `Rscript --vanilla -e 'devtools::check()'` -> `0 errors | 0 warnings |
  0 notes`, including examples, `--run-donttest`, tests, and vignette rebuilds.
- `Rscript --vanilla -e 'pkgdown::check_pkgdown()'` -> `No problems found`.
- `Rscript --vanilla tools/build-site.R` -> full site built successfully;
  internal pages removed, reference alt text filled, and the function-map gate
  passed.
- `Rscript --vanilla -e 'urlchecker::url_check()'` -> 20 URLs passed and seven
  DOI resolver requests returned automated HTTP 403. Each DOI then returned
  HTTP 200 from `https://api.crossref.org/works/<doi>` using a named user agent:
  `10.1002/9780470316757`, `10.1080/00401706.1970.10488634`,
  `10.1080/01621459.1975.10479864`, `10.1093/aje/kwt245`,
  `10.1093/biomet/80.1.27`, `10.1111/j.2517-6161.1996.tb02080.x`, and
  `10.1198/016214508000000337`.
- `R CMD build .` -> built `freqTLS_0.1.0.tar.gz`.
- `du -h freqTLS_0.1.0.tar.gz` -> `1.8M`.
- `tar -tzf freqTLS_0.1.0.tar.gz` plus anchored scans -> 211 entries; no
  `output/`, `scripts/`, `data-raw/`, governance files, `cran-comments.md`,
  compiled artefacts, snow-gum, or Kristineberg material. Installed data are
  six `.rda` files and 16 licensed `inst/extdata` components.
- `R CMD check --as-cran freqTLS_0.1.0.tar.gz` with normal Suggests ->
  `0 errors | 0 warnings | 1 note`; the only NOTE is `New submission`. PDF and
  HTML manuals, examples, `--run-donttest`, tests, and vignette rebuilds passed.
- Component-ledger coverage script -> all 22 installed `data/*.rda` and
  `inst/extdata/**` files appear in `docs/design/47-data-license-ledger.md`.
- Benchmark-cache audit -> no `snowgum` rows or metadata; the RDS contains a
  dated `licensing_note` explaining the exclusion.
- Live deployed function-map audit after pkgdown deployment -> 69 SVG text
  nodes, 27 rectangles, zero `<em>` nodes, and no stray following text.
- `gh issue list --state open --limit 100 --json number,title,url` -> `[]`;
  there was no overlapping issue to update.
- Consistency scans:
  `rg -n "combine freely|always returns|always finite|most bayesTLS analyses|already released|on CRAN|CRAN hardening: non-goal|snowgum_psii" README.Rmd README.md ROADMAP.md NEWS.md SPEC.md AGENTS.md docs/design docs/dev-log/known-limitations.md vignettes R tests _pkgdown.yml`;
  `rg -n "Vendored.*CC BY 4\\.0|snow.gum.*CC BY 4\\.0|CC BY 4\\.0.*snow" README.Rmd README.md SPEC.md AGENTS.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R inst`;
  `rg -n "snowgum_psii|case-study-leaf-psii|data_function_PSII_TDT_snowgum|kristineberg" R tests vignettes _pkgdown.yml README.Rmd NEWS.md inst/extdata`.

Interpretation:

- Local package, documentation, pkgdown, licensing-inventory, and exact-tarball
  gates pass. Snow-gum is correctly recorded as CC BY-NC 4.0 and is excluded,
  not silently relabelled. Kristineberg is also excluded pending explicit terms.
- This is not yet an upload-ready CRAN release: the GitHub platform matrix,
  win-builder, R-hub, Sol-level Grace/Rose/Pat review, and written confirmation
  from Arnold, Pottier, and Noble remain open gates.

## 2026-07-11 -- Post-Sol correction and replacement exact tarball

Goal:

- Close the first Sol adversarial review findings, rebuild all public/generated
  artefacts, and replace the stale candidate with a tarball derived from the
  corrected source tree.

Checks run:

- Source and generated-document review removed the remaining universal-interval,
  drop-in package-switch, seven-dataset, and snow-gum cache claims. The retained
  phrase is explicitly negative: “the packages are not drop-in replacements.”
- `Rscript --vanilla tools/build-site.R` -> full site rebuilt successfully. The
  post-build gate removed `AGENTS.html`, `CLAUDE.html`, `SPEC.html` and their
  copied Markdown sources; removed 40 corresponding search-index records and
  the sitemap URLs; filled example alt text on six reference pages; and passed
  the function-map guard.
- Direct site assertions -> none of `AGENTS`, `CLAUDE`, or `SPEC` remains as a
  root HTML/Markdown file or URL in `search.json`, `sitemap.xml`, or `llms.txt`.
  The rendered function map contains exactly 69 `<text>` nodes, 27 `<rect>`
  nodes, and zero `<em>` nodes.
- `Rscript --vanilla -e 'pkgdown::check_pkgdown()'` -> `No problems found`.
- `Rscript --vanilla -e 'devtools::test()'` ->
  `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 772 ]` in 115.3 seconds.
- `R CMD build .` -> rebuilt `freqTLS_0.1.0.tar.gz`; SHA-256
  `fc0ee9ac4c3d0ef7c8c8a281d61d7988e31d4d8e9ad3db9ae18731946e737572`.
- `du -h freqTLS_0.1.0.tar.gz` -> `1.8M`; `tar -tzf` -> 211 entries. Anchored
  inventory scans found no `output/`, `scripts/`, `data-raw/`, governance tree,
  `cran-comments.md`, `pkgdown-site/`, compiled artefacts, snow-gum, or
  Kristineberg material.
- `R CMD check --as-cran freqTLS_0.1.0.tar.gz` under R 4.6.0 on
  aarch64 macOS -> `0 errors | 0 warnings | 1 note`. The only NOTE is
  `New submission`; installation, compiled-code checks, examples,
  `--run-donttest`, installed-package tests, vignette rebuilding, and PDF/HTML
  manuals all passed.

What did not go smoothly:

- The first post-build search cleanup assumed every pkgdown search record had a
  scalar `path`; one record did not, so the build stopped after site generation.
  The filter now handles missing/non-scalar paths, and a second complete site
  build passed the cleanup and its fail-loud invariant.

Interpretation:

- This SHA-256 supersedes the earlier local tarball evidence. Local source,
  generated-site, inventory, and strict macOS CRAN checks now refer to the same
  corrected source state. External author consent, GitHub platform CI,
  win-builder, R-hub, and a fresh Sol Grace/Rose/Pat verdict remain required
  before upload.

## 2026-07-11 -- Pinned benchmark provenance and current exact tarball

Goal:

- Close the second Sol audit findings about benchmark provenance, comparator
  thresholds, installed-user guidance, and privileged pkgdown deployment; then
  build and check a replacement source tarball from the corrected source.

Checks run:

- Upstream `bayesTLS` history/API audit -> pinned commit
  `578740f20f3a2e6e81b3b700b1d0f0e5a06ecf8a`, the latest examined 1.0.0
  commit before the original cache date that exports the comparator API used by
  the builder. The cache records that 40-character SHA and its exact GitHub
  source URL.
- Maintainer cache rebuild with `BAYESTLS_GIT_SHA=578740f20f3a2e6e81b3b700b1d0f0e5a06ecf8a`,
  four chains, 4,000 iterations, seed 123, and CmdStan 2.36.0 -> completed for
  shrimp, three zebrafish stages, and two *D. suzukii* sexes. Cache SHA-256 after
  the final metadata correction is
  `081fac1e97b02662071a2e764d953dba1dae033e9941e5266bbefa3872fa663f`.
- Comparator-contract review -> `freqTLS` and `bayesTLS` are described only as
  matched relative-threshold, constant-shape model fits. The classical
  two-stage route is now consistently identified as an absolute-LT50
  approximation for the near-0/near-1 lethal curves. A cache test asserts this
  distinction.
- `Rscript --vanilla -e 'devtools::test()'` after the Sol corrections ->
  `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 779 ]` in 114.4 seconds.
- `Rscript --vanilla -e 'devtools::test(filter = "benchmark-sanity", reporter = "summary")'`
  after the metadata wording correction -> 16 expectations passed.
- `Rscript --vanilla tools/build-site.R` -> complete site build passed; 405
  valid search records, zero malformed paths or internal governance URLs, and
  function-map counts of 69 `<text>`, 27 `<rect>`, and zero `<em>` nodes.
- `.github/workflows/pkgdown.yaml` review -> deployment occurs only after a
  successful `R-CMD-check` `workflow_run` whose `head_branch` is `main`; PR-head
  code is never checked out under the workflow's `contents: write` permission.
  Both workflow files parse as YAML.
- `R CMD build .` -> current exact candidate `freqTLS_0.1.0.tar.gz`, SHA-256
  `b938c45ad2b43bfa0ba28388e6a3fe08fc7176f74d824e74adb5faaeb01fa40e`,
  2.1 MB and 211 entries.
- Exact tarball inventory and extracted-cache assertions -> no `output/`,
  `scripts/`, `data-raw/`, governance files, licensing-pending material,
  snow-gum, Kristineberg, or compiled artefacts; pinned cache SHA/source,
  dataset scope, and absolute-LT50 note all present.
- `R CMD check --as-cran freqTLS_0.1.0.tar.gz` under R 4.6.0 on aarch64 macOS
  -> `0 errors | 0 warnings | 1 note`. The only NOTE is `New submission`;
  installation, compiled-code checks, examples, `--run-donttest`, tests,
  vignette rebuilding, and PDF/HTML manuals passed.

Interpretation:

- This tarball SHA supersedes every earlier candidate recorded above. The local
  technical gate is clean. The artifact is not upload-ready until the fresh
  Sol Grace/Rose/Pat audit, GitHub platform matrix, win-builder, R-hub, and all
  three written author-consent rows pass.

## 2026-07-11 -- Sol round-3 remediation and exact candidate

Goal:

- Close every Grace, Rose, and Pat finding from the third independent Sol audit,
  regenerate public artefacts, and replace the rejected candidate with one exact
  locally checked tarball.

Findings closed:

- Grace: the privileged pkgdown `workflow_run` now requires a successful trusted
  same-repository `push` to `main`; the package check workflow has explicit
  `contents: read`; all GitHub/r-lib/JamesIves actions are pinned to verified
  40-character upstream commit SHAs.
- Rose: `dsuzukii` documents only `dead` as a freqTLS response; Li and Saruhashi
  dataset citations are present; benchmark protocol/ledger match the freshly
  rebuilt cache's `freqTLS_note` schema and pinned source; the capability matrix
  describes the actual three-family, three-interval 0.1.0 surface and its
  target-specific exceptions; `bounds = c(0, 1)` is explicit in installed help.
- Pat: the profile article executes the default bootstrap recovery first and
  then an explicit `fallback = FALSE` open-profile diagnostic; random-effects
  routing and Confidence-Eye behavior are current; warnings 1--7 provide
  concrete recovery actions through discoverable `check_tls()` help; milestone
  prose was removed from task help.
- Neighbor sweep: all current installed articles treat the benchmark cache as a
  shipped integrity requirement and identify `data-raw` scripts as
  repository-only. The cache's R-SHRIMP note now points to installed help rather
  than excluded governance files.

Checks run:

- `Rscript --vanilla -e 'devtools::document()'` -> regenerated `dsuzukii`,
  diagnostics, fit, and formula help without warnings.
- `Rscript --vanilla -e 'devtools::build_readme()'` -> README rebuilt; the tool
  reported only that local development copies of Rcpp and rlang were behind
  newer available versions, not a package-check defect.
- `Rscript --vanilla -e 'devtools::check_man()'` -> no documentation problems.
- `utils::readCitationFile("inst/CITATION", ...)` -> five valid entries: freqTLS,
  bayesTLS, Orsted, Li, and Saruhashi.
- Full `Rscript --vanilla -e 'devtools::test(reporter = "summary")'` -> completed
  with no failures, warnings, or skips. Focused Pat tests had 109 passing
  expectations; the benchmark test has 20 provenance/fit expectations.
- `Rscript --vanilla -e 'pkgdown::check_pkgdown()'` -> `No problems found`.
- `Rscript --vanilla tools/build-site.R` -> complete build passed; 408 scalar
  search paths, no internal governance URLs, function-map counts 69/27/0 for
  `<text>`/`<rect>`/`<em>`, and the profile article rendered a bootstrap-status
  default row followed by `open_both`/`NA` under `fallback = FALSE`.
- `Rscript --vanilla -e 'urlchecker::url_check()'` -> 20 URLs passed and the same
  seven publisher DOI resolvers returned automated HTTP 403; their registrations
  were already verified through Crossref in the preceding release pass.
- `Rscript --vanilla -e 'devtools::check()'` -> `0 errors | 0 warnings | 0
  notes` in 4 minutes 10 seconds, including examples, tests, and vignette rebuild.
- `R CMD build .` -> `freqTLS_0.1.0.tar.gz`, SHA-256
  `bd93eac3786cabd648e7fb20306d63322190b26b28848c483fd935631ce09437`,
  1,859,394 bytes (1.77 MiB), 211 entries.
- Exact inventory/cache assertions -> no forbidden directories, governance,
  permission-pending components, snow-gum, Kristineberg, or compiled artefacts;
  pinned cache source, comparator threshold distinction, retained datasets, and
  installed-help provenance all present.
- `R CMD check --as-cran freqTLS_0.1.0.tar.gz` under R 4.6.0 on aarch64 macOS
  -> `0 errors | 0 warnings | 1 note`; only `New submission`. Installation,
  examples, `--run-donttest`, tests, vignette rebuild, PDF manual, and HTML manual
  passed.

Interpretation:

- This SHA supersedes every candidate above and proves the local technical
  artifact gate. A new Sol Grace/Rose/Pat verdict, GitHub platform matrix,
  win-builder, R-hub, and written author consent remain required before upload.

## 2026-07-11 -- Sol round-4 contract correction and final local candidate

Goal:

- Correct the two remaining public-contract discrepancies found by the fourth
  independent Sol review, rebuild all affected artefacts, and check the exact
  replacement source tarball under strict CRAN conditions.

Corrections:

- Formula, README, installed help, specification, capability, and limitation
  prose now state that `CTmax` and `log_z` must use the same fixed-effect
  model-matrix columns; their supported random-intercept groupings may differ,
  and shape-coordinate fixed designs may differ.
- Strict open profiles are shown as a hollow point with no lens. Public prose no
  longer implies that an unclosed likelihood interval has a bounded lens.
- Two stale `v0.2 relaxed` test labels were removed without changing test
  behaviour.

Checks run:

- `Rscript --vanilla -e 'devtools::document()'` -> documentation regenerated
  without warnings.
- `Rscript --vanilla -e 'devtools::build_readme()'` -> README regenerated; only
  local development-dependency update notices were printed.
- `Rscript --vanilla -e 'devtools::test(filter = "formula|profile|doc-consistency")'`
  -> completed with no failures, warnings, or skips.
- `Rscript --vanilla tools/build-site.R` -> complete site build passed; 408
  valid search entries, no internal governance URLs, and function-map counts of
  69 `<text>`, 27 `<rect>`, and zero `<em>` nodes.
- `R CMD build .` -> exact candidate `freqTLS_0.1.0.tar.gz`, SHA-256
  `092585cfc81280d7ef06dfd12cc462f5e8c69d88069925980cd36bd0c086f61e`,
  1,859,554 bytes and 211 entries.
- Exact tarball inventory and extraction assertions -> no `output/`, `scripts/`,
  `data-raw/`, governance files, licensing-pending material, snow-gum,
  Kristineberg, or compiled artefacts; the benchmark cache is present and
  readable.
- `R CMD check --as-cran freqTLS_0.1.0.tar.gz` under R 4.6.0 on aarch64 macOS
  -> `0 errors | 0 warnings | 1 note`. The only NOTE is `New submission`;
  installation, compiled-code checks, examples, `--run-donttest`, tests,
  vignette rebuilding, and PDF/HTML manuals passed.

Interpretation:

- This checksum supersedes every candidate recorded above and proves the final
  local technical artifact gate. Sol round 5, the GitHub platform matrix,
  win-builder, R-hub, and written author consent remain required before upload.

## 2026-07-11 -- Sol round-5 remediation and replacement exact candidate

Goal:

- Address every package, documentation, pkgdown, and workflow defect found by
  the fifth independent Sol Grace/Rose/Pat audit, then regenerate and strictly
  check a replacement source tarball.

Findings closed:

- Prediction now rebuilds supported continuous `CTmax`/`log_z` fixed designs
  from `newdata`. Random-effects prediction distinguishes explicit population
  predictions (`re.form = "population"`) from known-group conditional
  predictions (`re.form = "conditional"`); missing or unseen conditional groups
  stop rather than silently receiving a zero BLUP. Focused prediction tests cover
  both paths.
- README, installed help, the random-effects vignette, design documents,
  capability matrix, and known limitations explain the prediction boundary.
  Specialised surface/derived/heat-injury helpers are identified as population-
  level for random-effects fits.
- SPEC and current design documents now agree on the 0.1.0 beta-family scope,
  relative-threshold model comparison versus the absolute-LT50 classical
  approximation, and hollow-point/no-lens behavior for open profiles.
- Brown-shrimp and life-stage zebrafish help now gives source-specific bayesTLS
  attribution, transformation notes, and CC BY 4.0 terms. Snow-gum remains
  correctly labelled CC BY-NC 4.0 and excluded.
- The invalid `make_4pl_formula()` random-effect example was replaced; the
  shared fixed-column rule and unsupported `up` random effect are discoverable
  in primary help. Direct negative and no-lens regression tests were added.
- Bootstrap refits suppress low-level optimiser trial-step warnings after
  classifying convergence explicitly; a regression test prevents leakage.
- Pkgdown manual deployment was removed, trusted checkout credentials are not
  persisted, and deployment can run only after a successful same-repository
  main-branch check. DESCRIPTION expands critical thermal maximum (`CTmax`) at
  first use; the dangling COPYRIGHTS `LICENSE` pointer was removed.
- The aphid and oxygen-gradient zebrafish examples now use `\donttest{}` and
  execute successfully under `--run-donttest`.

Checks run:

- Focused prediction/formula/profile/bootstrap/data/doc tests -> no failures,
  warnings, or skips. The independent prediction slice reported 68 passing
  expectations.
- Full `devtools::test(reporter = "summary")` -> no failures, warnings, or
  skips.
- `devtools::check_man(); pkgdown::check_pkgdown()` -> no problems found.
- `Rscript --vanilla tools/build-site.R` -> complete site build passed; 408
  valid search entries, no internal governance URLs, current prediction/data
  help, and function-map counts of 69 `<text>`, 27 `<rect>`, zero `<em>`.
- `urlchecker::url_check()` -> 20 endpoints passed; the same seven publisher
  DOI resolvers returned automated HTTP 403. Exact registrations and titles for
  all seven were confirmed through the Crossref works API.
- `devtools::check()` -> `0 errors | 0 warnings | 0 notes` in 6 minutes 9
  seconds, including the newly runnable `\donttest{}` examples and vignette
  rebuilds.
- `R CMD build .` -> exact candidate `freqTLS_0.1.0.tar.gz`, SHA-256
  `7c2594a27ea9da6e61689a417d510827c0ba21ecb3fcb3f819ad656a81a7e8c5`,
  1,864,624 bytes and 211 entries.
- Exact inventory and extraction assertions -> no build-only directories,
  governance, permission-pending data, snow-gum, Kristineberg, or compiled
  artefacts; benchmark cache present and readable.
- `R CMD check --as-cran freqTLS_0.1.0.tar.gz` under R 4.6.0 on aarch64 macOS
  -> `0 errors | 0 warnings | 1 note`; only `New submission`. Installation,
  compiled code, examples, `--run-donttest` (116 seconds), tests, vignette
  rebuild (122 seconds), and PDF/HTML manuals passed.

Interpretation:

- This checksum supersedes every earlier artifact. The local package, docs, and
  pkgdown gates are clean. Commit/PR-specific CI, win-builder, R-hub, final
  post-platform Grace/Rose/Pat approval, and written author consent remain open.

## 2026-07-11 -- PR #2 CI setup repair

Goal:

- Diagnose the first four-platform PR run from logs and repair only the failing
  workflow setup expression.

Checks and finding:

- `gh pr checks 2 --watch --interval 10` -> all four jobs in run
  `29174528886` failed during `setup-r-dependencies`, before package build/check.
- The failed logs show the pinned r-lib action generated
  `dependencies = c(needs, ("hard", "soft"))`, which is invalid R, from the
  workflow input `dependencies: '"hard", "soft"'`.
- The pinned action source at commit
  `d3c5be51b12e724e68f33216ca3c148b66d5f0b6` documents the input as an R
  expression and interpolates it inside `c(needs, (...))`. The workflow now
  supplies `c("hard", "soft")`; the resulting expression parses locally.
- The run also warned that checkout v4 targets deprecated Node 20. Both
  workflows now pin checkout v6 commit
  `df4cb1c069e1874edd31b4311f1884172cec0e10`; its upstream `action.yml` uses
  Node 24.
- Both workflow files parse with Ruby YAML, all action references remain full
  40-character SHAs, and `git diff --check` passes.

Interpretation:

- This was a workflow-expression failure, not a package failure. The package
  tarball is unchanged because `.github/` and the check log are build-excluded.
  PR #2 must rerun all four platform jobs before the CI gate can pass.

## 2026-07-11 -- Sol completion audit, licensing exclusions, and replacement candidate

Goal:

- Close the fresh Grace/Rose/Pat completion-audit findings, rebuild the installed
  documentation and site, and verify a new exact CRAN source artifact.

Commands and outcomes:

- `Rscript --vanilla -e 'devtools::document()'` -> regenerated prediction,
  proportion-clamp, and three internal helper topics; each callable internal
  topic now documents parameters and return value.
- `Rscript --vanilla -e 'devtools::test(filter =
  "doc-consistency|predict|standardize", stop_on_failure = TRUE)'` -> 94 passes,
  zero failures/warnings/skips after excluding dataset topics from the callable-
  return-value tripwire.
- Extracted `predict.profile_tls` examples with `tools::Rd2ex()` and sourced them
  after `devtools::load_all()` -> ordinary, continuous-fixed-design, population
  RE, and conditional RE examples all executed and returned finite predictions.
- `Rscript --vanilla -e 'devtools::build_readme()'` -> the grouped example ran;
  the initial small design exposed nonsensical estimates, so it was replaced by
  a 4-replicate, 40-trial design recovering CTmax 35.1/38.0 and z 4.20/4.11.
- `Rscript --vanilla -e 'devtools::test(stop_on_failure = TRUE)'` -> 800 passes,
  zero failures/warnings/skips in 111.5 seconds.
- `Rscript --vanilla -e 'devtools::check_man()'` -> clean.
- `Rscript --vanilla -e 'devtools::check()'` -> zero errors, warnings, or notes
  in 5 minutes 49.9 seconds.
- `Rscript --vanilla -e 'pkgdown::check_pkgdown()'` -> no problems found.
- `Rscript --vanilla tools/build-site.R` -> full local site built; internal
  AGENTS/CLAUDE/SPEC pages and source files removed from the public artifact;
  changed reference pages rebuilt successfully.
- `Rscript --vanilla -e 'urlchecker::url_check()'` -> 20 reachable endpoints;
  the same seven publisher DOI resolvers returned automated 403 responses. Their
  registrations were already manually verified through Crossref.
- `R CMD build .` -> exact `freqTLS_0.1.0.tar.gz`, 1,551,284 bytes, 210 entries,
  SHA-256 `1a8d1248a9517e2ba6df2cc595e181d3cc9846f52b868fdec61caac55326b331`.
- Tar inventory scan -> both canonical/installed function-map SVG paths present;
  no `output/`, `scripts/`, `data-raw/`, governance, snow-gum, Kristineberg,
  environmental traces, licensing-pending paths, or compiled artifacts.
- Clean install to `/tmp/freqtls-lib`, followed by rendering installed
  `freqTLS.Rmd` from `/tmp/freqtls-neutral` -> success; installed map counts 69
  `<text>`, 27 `<rect>`, zero `<em>`.
- `R CMD check --as-cran freqTLS_0.1.0.tar.gz` -> zero errors, zero warnings,
  one NOTE (`New submission`); `--run-donttest` 115 seconds, tests 30 seconds,
  vignette rebuild 124 seconds, PDF/HTML manuals passed.
- GitHub run `29175810837` at predecessor head `5d83d21` -> Ubuntu release,
  Ubuntu devel, Windows release, and macOS release all passed.
- R-hub run `29175814161` at predecessor head `5d83d21` -> Ubuntu/clang status
  OK. Replacement-head reruns remain required.
- First win-builder R-devel log at
  `https://win-builder.r-project.org/jOFn6gLj3SeZ/00check.log` -> stopped at
  dependency checking because the server lacked CRAN package `cli`; incoming
  URL/DOI checks also reported missing `curl`. No freqTLS installation,
  compilation, example, test, or vignette check ran. The replacement exact
  tarball was resubmitted with HTTP 200; result pending.

Interpretation:

- The new local artifact closes the audit's package/documentation/licensing
  blockers. External readiness is still unproven until the replacement head
  passes the four-platform matrix and R-hub, win-builder returns a real package
  result, and fresh Grace/Rose/Pat verdicts approve. Written collaborator consent
  remains a hard upload gate.

## 2026-07-12 -- Replacement platform results and author confirmations

Goal:

- Close the external platform and collaborator-consent gates for the exact
  freqTLS 0.1.0 release candidate before the final independent audit.

Commands and outcomes:

- `git rev-parse HEAD` ->
  `3fe45a942f80e58c3233cb8ff8ffd354ce96842a`.
- `shasum -a 256 freqTLS_0.1.0.tar.gz` ->
  `1a8d1248a9517e2ba6df2cc595e181d3cc9846f52b868fdec61caac55326b331`.
- `gh run view 29177778758 --json status,conclusion,headSha,jobs` -> success at
  release commit `3fe45a9`; Ubuntu release, Ubuntu devel, Windows release, and
  macOS release all passed.
- `gh run view 29177783632 --json status,conclusion,headSha,jobs` -> success at
  release commit `3fe45a9`; the independent R-hub Ubuntu/clang check passed.
- `curl -fsSL https://win-builder.r-project.org/4xKTjl6D6WT4/00check.log` ->
  R-devel r90235 completed with `Status: 1 NOTE`. The NOTE is `New submission`
  and DESCRIPTION spell-check flags for the acronym `TLS` and valid British
  spelling `reparameterised`. Package installation, compiled-code checks,
  examples, tests (86 seconds), vignette rebuilding (367 seconds), and PDF/HTML
  manuals all passed.
- Maintainer confirmation on 2026-07-12 -> Pieter A. Arnold, Patrice Pottier,
  and Daniel W. A. Noble all agreed to proceed with their freqTLS 0.1.0 `aut`
  roles; confirmations were received through email and text correspondence.

Interpretation:

- The replacement exact artifact is green on the required GitHub, R-hub, and
  win-builder platforms. The win-builder NOTE is expected and explained in
  `cran-comments.md`; it is not a release blocker. All three author-consent rows
  are closed. The fresh Grace/Rose/Pat completion adversary remains the final
  pre-submission gate.

Fresh completion-adversary outcomes:

- Grace -> READY: exact checksum/inventory, local `--as-cran`, GitHub matrix,
  R-hub, win-builder, CRAN comments, provenance, and submission mechanics pass.
- Pat -> READY: clean install, README first fit, intervals, prediction,
  diagnostics, examples, all installed vignettes, neutral-directory render,
  and function-map structure pass using the exact tarball.
- Rose -> substantively READY, with one process condition: commit and push the
  gate-closing records and confirm a clean tree. No licensing, scope,
  provenance, consent, or stale-release-claim blocker remains.

Interpretation:

- Two fresh reviewers returned READY and Rose's sole NOT-READY condition is the
  landing of this evidence-only batch, not a candidate defect. Commit, push,
  and clean-tree verification close the completion-adversary gate without
  rebuilding the byte-identical, already verified tarball.

## 2026-07-12 -- CRAN incoming-pretest rejection and remediation

Goal:

- Fix every issue in CRAN incoming pre-test
  `freqTLS_0.1.0_20260712_135803` without weakening the package tests or the
  scientific interval contract.

Incoming evidence:

- Windows `00check.log` -> `Status: 1 NOTE`; substantive checks all passed.
  Timings were 625 seconds overall, 375 seconds for vignette rebuilding,
  89 seconds for tests, 20 seconds for examples, 36 seconds for manuals, and
  22 seconds for R code problems. The incoming NOTE flagged `TLS` and
  `reparameterised`; the additional wrapper NOTE was `Overall checktime 11 min
  > 10 min`.
- Debian `00check.log` -> `Status: 1 NOTE`; substantive checks all passed.
  Vignettes took 177 seconds and tests 38 seconds. The only NOTE was the same
  new-submission/DESCRIPTION spelling report.
- Per-vignette/chunk timing -> `case-study-summary.Rmd` was the dominant local
  article; its contrast chunk repeatedly ran default bootstrap fallback after
  open contrast profiles. The deterministic replacement cache has seven
  bootstrap-fallback contrast rows and one closed profile,
  although the article called all eight profile intervals.

Remediation and current checks:

- DESCRIPTION now says `thermal-load-sensitivity framework for thermal
  death-time modelling` and that the midpoint `is written directly in terms of`
  `CTmax` and `z`, removing both spell flags without changing the model claim.
- `data-raw/build_case_study_summary_cache.R` generated
  `inst/extdata/case_study_summary_cache.rds`: 12 headline profile rows, eight
  contrast rows with actual methods, input MD5 values, package/source/R/TMB
  versions, and exact model configuration.
- `vignettes/case-study-summary.Rmd` now reads the cache; its clean local render
  fell to 1.15 seconds. Two 1,000-refit bootstrap recipes are display-only, with
  explicit interactive-run guidance. Tests and individual case studies retain
  live bootstrap/profile coverage.
- `Rscript --vanilla -e 'devtools::test(stop_on_failure=TRUE)'` -> 819 passes,
  zero failures/warnings/skips in 117.7 seconds.
- `Rscript --vanilla -e 'devtools::check()'` -> `Status: OK`, zero errors,
  warnings, or notes in 5 minutes 19.8 seconds; vignette rebuilding took
  72 seconds elapsed / 76 seconds wall.

Interpretation:

- The local source closes the two incoming issue classes with a wide vignette-
  timing margin and without removing live validation. Exact-tarball strict
  checks and external Windows timing remain required before resubmission.

Exact replacement-artifact evidence:

- `R CMD build .` -> `freqTLS_0.1.0.tar.gz`, 212 entries, about 2.1 MiB,
  SHA-256 `6c2bcadb9b9bd4448ae0e53a97bb2417a87dac76cd6e5620e50a87b933b58160`.
- Tar inventory scan -> the versioned summary cache is present; no `output/`,
  `scripts/`, `data-raw/`, governance, licensing-pending material, snow-gum,
  Kristineberg, environmental traces, or compiled artifacts are present.
- `R CMD check --as-cran freqTLS_0.1.0.tar.gz` -> zero errors, zero warnings,
  one NOTE (`New submission`). No possible-misspelling report remains;
  `--run-donttest` took 119 seconds wall, tests 32 seconds wall, and vignette
  rebuilding 76 seconds wall. PDF and HTML manuals passed.
- Clean install to `/tmp/freqtls-replacement-lib`, followed by neutral-directory
  renders of installed `freqTLS.Rmd` and `case-study-summary.Rmd` -> success.
  The installed cache has 12 panel and eight contrast rows. The installed
  function-map SVG has 69 `<text>`, 27 `<rect>`, and zero `<em>` elements.

Interpretation:

- The exact replacement artifact removes both DESCRIPTION spell flags and has a
  large local vignette-runtime reduction. External Windows timing, final-head
  CI/R-hub, and fresh completion verdicts remain required before resubmission.

## 2026-07-12 -- Contrast-direction and deterministic-cache audit correction

Goal:

- Close the fresh Grace/Rose findings before treating the incoming-pretest fix
  as a resubmission candidate.

Changes and evidence:

- `dCTmax:A-B`, `dlog_z:A-B`, and `dz:A-B` now mean group A minus group B in
  both profile refitting and bootstrap extraction. Design docs, roxygen,
  generated Rd, NEWS, tests, and the *D. suzukii* article use that convention.
- The cache generator now uses `fallback = FALSE` for the 12 headline profiles
  and fixed seeds `20260712` / `20260713` with `nboot = 1000` for the two
  contrast sets. Metadata records the exact generation commit
  `589e3af6c7c226c571ddcbf682f86a578f77ad9c`, all three input MD5 values,
  `nboot`, and both seeds.
- Two consecutive cache builds returned identical SHA-256
  `3b4ee270de90fcf7ffab42850da953353515ce9509bb54fee7a2ffdec1edc8a2`.
- The cache test pins the exact generation commit/checksums/configuration,
  expects 12 profile/`ok` headline rows and the deterministic contrast split
  (one profile, seven bootstrap fallbacks), and checks finite endpoints.
- Targeted `group|case-study-summary-cache|bootstrap` tests -> 77 passes; both
  changed case-study vignettes rendered successfully.
- Full `devtools::test()` -> 827 passes, zero failures/warnings/skips in
  117.9 seconds.
- Final exact `freqTLS_0.1.0.tar.gz` -> SHA-256
  `ad637914a1b59d93196a4193807ff5ece904705aec586c136ff62429f38ef994`,
  about 2.1 MiB, 212 entries.
- Strict `R CMD check --as-cran` on that artifact -> zero errors, zero warnings,
  one NOTE (`New submission`); tests 31 seconds wall, vignette rebuilding
  68 seconds wall, manuals passed.

Interpretation:

- The audit findings are fixed in code, generated artifacts, tests, and public
  prose. All external gates and fresh verdicts must now target the `ad637914`
  artifact; predecessor replacement results are timing evidence only.

## 2026-07-12 -- Final Rose cleanup and exact replacement candidate

Goal:

- Remove the last stale reader-facing profile count and contradictory internal
  contrast comment, then reconcile the after-task record before resubmission.

Changes and checks:

- `vignettes/case-study-summary.Rmd` now states that all 12 headline profiles
  close: six groups for each of two parameters. `R/profile.R` now describes the
  internal reference/alternate recoding consistently with public `A-B` meaning
  A minus B.
- The remediation after-task report now lists the contrast implementation,
  documentation, tests, NEWS, and generated Rd files and identifies the
  contrast semantic change and its directed regression tests.
- `Rscript --vanilla -e 'devtools::document()'` -> passed.
- `Rscript --vanilla -e 'devtools::test(filter="group|case-study-summary-cache", stop_on_failure=TRUE)'`
  -> 48 passes, zero failures/warnings/skips in 2.6 seconds.
- Installed-package renders of `case-study-summary.Rmd` and
  `case-study-suzukii.Rmd` -> passed.
- `Rscript '/Users/z3437171/Dropbox/Github Local/Shinichi/tools/check-after-task.R' docs/dev-log/after-task/2026-07-12-cran-incoming-pretest-remediation.md`
  -> structure check passed.
- `Rscript tools/build-site.R` -> passed; privacy cleanup removed internal hub
  pages. Generated source and HTML contain the corrected 12-profile wording.
- `Rscript --vanilla -e 'devtools::test(stop_on_failure=TRUE)'` -> 827 passes,
  zero failures/warnings/skips in 122.8 seconds.
- `Rscript --vanilla -e 'pkgdown::check_pkgdown()'` -> no problems.
- `R CMD build .` -> `freqTLS_0.1.0.tar.gz`, SHA-256
  `e3b38efb954e3292d814c897c2af8620b967ff2ffa72a753bf18c3ab886f62be`,
  about 1.5 MiB and 212 entries; excluded-path and compiled-artifact inventory
  scan returned no hits.
- `R CMD check --as-cran freqTLS_0.1.0.tar.gz` -> zero errors, zero warnings,
  one expected `New submission` NOTE; `--run-donttest` 121 seconds elapsed /
  126 seconds wall, tests 31/34 seconds, vignettes 67/77 seconds, and both
  manuals passed.

Interpretation:

- Local source, rendered site, exact tarball inventory, and strict check are
  ready. External GitHub, R-hub, win-builder timing, and fresh completion
  verdicts must target this exact `e3b38ef...f62be` candidate; all earlier
  external results are predecessor evidence only.

## 2026-07-12 -- Exact replacement external gate complete

Goal:

- Prove that the exact final replacement candidate closes Uwe Ligges's vignette
  timing request and passes every external platform and completion gate before
  CRAN resubmission.

Evidence:

- Exact tarball: `freqTLS_0.1.0.tar.gz`, SHA-256
  `e3b38efb954e3292d814c897c2af8620b967ff2ffa72a753bf18c3ab886f62be`,
  1,552,384 bytes and 212 entries.
- `gh run view 29196192961` at source HEAD
  `7097a1333fc15b31c65b2863ab74039faca23724` -> success on Ubuntu R release,
  Ubuntu R devel, Windows R release, and macOS R release.
- `gh run view 29196204879` at the same source HEAD -> R-hub Ubuntu/clang
  success.
- `curl -fsSL https://win-builder.r-project.org/z8E3gcN9PWek/00check.log` ->
  package `freqTLS` version `0.1.0`; `Status: 1 NOTE`; the only NOTE is `New
  submission`. Installation took 87 seconds and checking took 431 seconds;
  tests took 89 seconds and vignette rebuilding 165 seconds. No spelling or
  overall-checktime NOTE appears.
- Uwe Ligges's rejection reply identified the original 375-second vignette
  rebuild as the main problem and asked for toy data, fewer iterations, or
  precomputed lengthy results. The versioned cross-case cache implements the
  permitted precomputed-results route while live tests and individual case
  studies retain executable coverage.
- Fresh exact-artifact verdicts: Pat READY; Rose READY; Grace no local blocker
  with all stated external conditions now satisfied.

Interpretation:

- Every technical, licensing, provenance, author-consent, installed-user, and
  external-platform gate is closed for the exact replacement tarball. The next
  actions are evidence-only merge, CRAN resubmission/confirmation, and public
  package/check-page verification. Do not claim publication before those pages
  exist.

## 2026-07-12 -- CRAN remediation merged

Goal:

- Land the verified CRAN-remediation source and trigger trusted post-merge
  package/site verification without changing the frozen source tarball.

Evidence:

- `gh pr view 4` -> PR #4 was squash-merged to `main` as
  `adb5e0dc5ace287ff7304a43ba839dffdc5fb88a` at 2026-07-12 15:01 UTC.
- `git pull --ff-only origin main` in the clean main worktree -> fast-forwarded
  to the merge commit with no local changes.
- The merge contains the final exact-artifact evidence batch. This follow-up
  edits only `docs/dev-log/`, which is anchored out of the package build, so the
  frozen CRAN tarball remains SHA-256
  `e3b38efb954e3292d814c897c2af8620b967ff2ffa72a753bf18c3ab886f62be`.

Interpretation:

- The implementation is landed. This normal main-branch evidence push triggers
  the post-merge R-CMD-check workflow; its successful push event in turn
  authorizes the cleaned pkgdown deployment. CRAN resubmission still uses the
  already frozen exact tarball.

## 2026-07-14 -- Experimental-use warning

Goal:

- Make the package's experimental status and the user's responsibility explicit
  on both the GitHub README and the pkgdown homepage, and recommend an
  independent `bayesTLS` cross-check for important analyses.

Changes:

- Added a prominent warning immediately below the README badges. It states that
  results may be incorrect or change without notice, names the checks that
  remain the user's responsibility, and links to `bayesTLS` as the Bayesian
  sister package.
- Regenerated `README.md` from `README.Rmd`; the pkgdown homepage continues to
  read this generated file, so GitHub and pkgdown carry the same wording.

Checks run:

- `Rscript --vanilla -e 'devtools::build_readme(quiet = TRUE)'` -> passed and
  regenerated `README.md`; reported only that installed `Rcpp` and `rlang`
  development dependencies have newer available versions.
- `Rscript --vanilla -e 'pkgdown::check_pkgdown()'` -> `No problems found`.
- `Rscript --vanilla tools/build-site.R` -> passed; built the full site, removed
  internal files, and filled reference-page alt text as designed.
- `rg -n -C 3 "Experimental software|use at your own risk|cross-check the results|Bayesian sister" pkgdown-site/index.html README.Rmd README.md`
  -> found the warning in both README artifacts and in the rendered homepage
  blockquote, including the live `bayesTLS` link.
- `gh issue list --state open --limit 50 --json number,title,url` -> `[]`; there
  was no overlapping issue to update.

Interpretation:

- The source and local rendered artifact now state the risk plainly. Public
  visibility still depends on merging the focused branch and the normal
  R-CMD-check -> pkgdown deployment chain succeeding.

## 2026-07-16 -- Experimental v0.2 bayesTLS teaching parity

Goal:

- Rebase active freqTLS teaching, data, formulas, thresholds, estimands,
  documentation, and comparison evidence on bayesTLS commit `76510412`, while
  retaining explicitly experimental frequentist extensions and removing
  unpublished compatibility fixtures from public discovery.

Checks and evidence:

- `Rscript -e 'devtools::document()'` -> regenerated source-synchronized Rd.
- `Rscript -e 'devtools::test(stop_on_failure = TRUE)'` -> 1,033 pass, 0 fail,
  0 warn, 0 skip.
- `Rscript -e 'devtools::check(document = FALSE, manual = FALSE, error_on =
  "error")'` -> 0 errors, 0 warnings, 0 notes; examples, donttest examples,
  installed tests, and vignette rebuild passed.
- `Rscript tools/build-site.R` -> 103 HTML pages from an exact temporary
  installation; internal pages removed; post-build assertions passed.
- `Rscript -e 'pkgdown::check_pkgdown()'` -> `No problems found`.
- `Rscript -e 'devtools::test()'` -> 1,120 passing tests, 0 failures,
  warnings, or skips.
- Rendered warning scan -> 103 pages, exactly one
  `freqtls-experimental-warning` element per page; all seven canonical article
  routes present.
- `rg -n -i "shrimp|life-stage|zebrafish_lethal"
  pkgdown-site/search.json` -> no matches; legacy URLs absent from sitemap,
  LLM discovery, and article index.
- `devtools::test(filter = "canonical-comparator-cache", stop_on_failure =
  TRUE)` -> 120 pass, 0 fail/warn/skip after installed-package hardening.
- Canonical cache -> 40 summary rows, six cases, maximum R-hat 1.0019, zero
  divergences, zero tree-depth hits, all ESS/BFMI gates passed; published
  SHA-256 `3b04bb161250abb1628e3018ff25648984b7c6a4131272e6e9c0557b15c3b2f0`.
- Fisher final audit -> READY. Pat final applied-user audit -> READY. Rose found
  no remaining source blocker after the installed-test, governance, package-
  help, rendered-site, and whitespace repairs.
- `gh pr checks 7` at implementation HEAD `d6b1acd` -> all four matrix jobs
  passed (Ubuntu R release/devel, Windows R release, macOS R release), run
  `29514936172`.
- `gh issue list --state open --limit 100 --json number,title,url` -> `[]`.
- `git diff --check` -> clean.

Interpretation:

- The local package, rendered site, canonical comparator, and governance now
  tell one v0.2 story. The release remains experimental. Snow-gum is authorized
  only for the current non-commercial GitHub/pkgdown use and remains a CRAN/
  commercial/adaptation blocker. Important analyses still require independent
  bayesTLS refitting and user scrutiny; agreement is not proof of correctness.

## 2026-07-16 -- Experimental v0.2 publication and closure repair

Goal:

- Verify the merged v0.2 package and advertised root site, then close defects
  found only by independent live, visual, and governance review.

Checks and evidence:

- PRs #6, #8, #7, and #9 merged sequentially as `40f5c64`, `de812c1`,
  `c81d51f`, and `f22980b`; no implementation change was made directly on
  `main`.
- `gh run view 29518817974` -> all four R-CMD-check jobs passed at exact current
  `main` SHA `f22980b95f597775e1efeadc7f93911566dabce7`.
- `gh run view 29519504501` -> the pkgdown deployment passed at the same SHA and
  published the experimental site at the advertised repository root.
- Live sitemap audit -> 75/75 URLs returned HTTP 200 and each contained exactly
  one `freqtls-experimental-warning` element. `search.json`, `sitemap.xml`, and
  `llms.txt` contained no active shrimp or life-stage-zebrafish teaching entry.
- The live visual audit found that the fixed Bootstrap navbar covered the
  warning's headline and first sentence. `pkgdown/extra.css` now reserves the
  navbar's 56-pixel height, and `test-experimental-warning.R` pins that offset.
- `Rscript -e 'devtools::test(filter =
  "experimental-warning|canonical-case-specifications|canonical-comparator-cache",
  stop_on_failure = TRUE)'` -> 198 pass, 0 fail, 0 warn, 0 skip.
- `Rscript -e 'devtools::test(stop_on_failure = TRUE)'` -> 1,042 pass, 0 fail,
  0 warn, 0 skip.
- `Rscript -e 'devtools::check(document = FALSE, manual = FALSE, error_on =
  "error")'` -> completed in 3 minutes 27 seconds with 0 errors, 0 warnings,
  and 0 notes; installed tests, examples, donttest examples, and vignette
  rebuilding all passed.
- `Rscript tools/build-site.R` -> 103 HTML pages rebuilt from the exact checkout
  at `pkgdown-site/`; internal governance pages and stale `/dev/` output were
  absent; generated-artifact assertions passed.
- `Rscript -e 'pkgdown::check_pkgdown()'` -> `No problems found`.
- Fresh headless-Chrome screenshots of home, zebrafish, reference, news,
  authors, and 404 pages showed the complete warning below the navbar before
  page content. Desktop and narrow-width surfaces were included.
- The project figure-audit workflow opened all 12 freshly rendered article PNGs
  individually. Confidence Eyes retained pale lenses and hollow estimates,
  interval methods/scales were named, and the non-closing profile drew no lens.
  Evidence: `docs/dev-log/figure-audits/2026-07-16-v02-pkgdown.md`.
- Current-tree inventory -> 14 vignettes, 55 level-two article sections, 101 R
  chunks, 57 Rd topics, 46 Rd example blocks, and 16 `inst/extdata` files. The
  parity ledger now records those exact totals, adds `snowgum_psii`, and marks
  `shrimp_lethal` as having no runnable example.
- Consumer scan of all current vignettes -> `benchmark_vs_bayes.rds`,
  `beta_binomial_phi_results.rds`, and `performance_results.rds` are not active
  article inputs; the licence ledger now labels them retained/internal rather
  than naming obsolete consumers.
- Stale-contract scan of SPEC, ROADMAP, capability matrix, and known limitations
  -> current claims consistently describe experimental `0.2.0.9000`; the only
  retained 0.1-candidate text is explicitly dated historical context.
- Final independent gate -> Fisher READY on data/model/estimand/cache evidence;
  Pat READY after desktop and real-mobile warning inspection; Rose READY after
  inventory, governance, licence-consumer, closure-record, and stale-claim
  re-audits.
- `git diff --check` -> clean.

Interpretation:

- Scientific parity and package behavior were already green. The closure repair
  makes the warning visibly usable, aligns the exhaustive ledgers with the real
  tree, and records current-main CI, deployment, and live-route evidence. The
  experimental, non-CRAN, unsupported-model, and Snow-gum rights boundaries are
  unchanged.

## 2026-07-16 -- 0.1.0 release-lane integration baseline

Goal:

- Reconcile the approved experimental 0.1.0 CRAN-remediation scope with the
  newer `main` implementation before producing a replacement source candidate.

Checks and evidence:

- `git merge-base origin/main build/freqtls` -> `e1a817e`; API comparison of
  `NAMESPACE` exports between `origin/main` and `build/freqtls` -> no delta.
- CRAN Repository Policy, source-package clauses (accessed 2026-07-16) ->
  copyright/IP of every component must be clear and unambiguous; the maintainer
  warrants agreement to use credited authors' material; CRAN must have a
  perpetual distribution right.
- Shinichi confirmed that all coauthors authorise package use, and that Pieter
  A. Arnold is the Snow-gum data holder who authorised use of that dataset.
- `Rscript -e 'devtools::document()'` -> regenerated `man/snowgum_psii.Rd`.
- `Rscript -e 'devtools::build_readme()'` -> regenerated `README.md`; local
  dependency freshness notices only (`MASS`, `Rcpp`, `rlang`).

Interpretation:

- The old frozen tarball and current-main 0.2 closure record are not evidence
  for this integration candidate. The candidate must be rebuilt from this branch
  after the full source, reference, pkgdown, and tarball audits complete.

## 2026-07-16 -- Rendered pkgdown audit on the 0.1.0 integration branch

Evidence:

- `Rscript tools/build-site.R .` -> complete; post-build cleanup removed
  `AGENTS`, `CLAUDE`, and `SPEC` HTML/Markdown artifacts and filled reference
  example alt text.
- Built-site inventory -> 103 HTML pages, 15 articles, and 82 reference pages.
- Rendered HTML stale scan for `0.2.0.9000`, experimental v0.2, and superseded
  Snow-gum-block language -> 0 hits.
- `Rscript -e 'pkgdown::check_pkgdown()'` -> `No problems found`.
- Export/Rd scan -> 47 `NAMESPACE` exports and 0 exports without a generated
  Rd alias; `devtools::check_man()` -> clean.

Interpretation:

- The generated public surface is coherent with the current 0.1.0 source
  boundary. It is intermediate evidence only: any installed-byte change requires
  a fresh site build and a new exact-candidate ledger entry.

## 2026-07-16 -- Exact local 0.1.0 integration artifact

Evidence:

- `R CMD build --no-resave-data --no-manual` ->
  `/tmp/freqtls-candidate-90efecb/freqTLS_0.1.0.tar.gz`.
- `shasum -a 256` ->
  `97a0684653c07ec064ebbd2eec885cd006ca7cfd3cbe31e85f818d28ec7cbbbd`.
- Tarball -> 1,191,852 bytes and 226 entries. Forbidden-path scan for
  maintainer outputs, governance/docs, Git metadata, source scripts, and
  internal contract files -> 0 entries. Snow-gum dataset/cache entries -> 3.
- `R CMD check --as-cran --no-manual freqTLS_0.1.0.tar.gz` -> 0 errors,
  0 warnings, 1 ordinary `New submission` NOTE. Installed tests, examples,
  `donttest` examples, and vignette rebuild all passed.

Interpretation:

- This is the current macOS technical artifact. It does not establish a
  cross-platform or upload claim: matching platform evidence, final author
  order, and reviewer verdicts still apply to this exact candidate identity.

## 2026-07-17 -- Post-merge 0.1.0 technical candidate

Evidence:

- `git diff --stat 99da90b0d90f81acf57747807aeb670796f29434 562cb027ced270e6ef32aaee265094f2d760b580` -> no package-source difference between the Actions-tested PR head and merge commit.
- From a clean detached checkout of `562cb027ced270e6ef32aaee265094f2d760b580`, `Rscript --vanilla -e 'devtools::document(); devtools::check_man()'` -> completed cleanly.
- `Rscript tools/build-site.R .` -> complete; rendered-site inventory -> 103 HTML pages, 15 articles, 82 reference pages; stale-claim and internal-page scans -> 0 hits; `Rscript -e 'pkgdown::check_pkgdown()'` -> `No problems found`.
- `R CMD build --no-resave-data --no-manual` -> `/tmp/freqtls-postmerge-562cb02/freqTLS_0.1.0.tar.gz`; `shasum -a 256` -> `0b97a520a7dff05d859fa36a30fa7ea7cd304159e9dcf91d9679567ed1f0a5aa`; 1,191,636 bytes and 226 entries.
- Forbidden-path scan for `output`, `scripts`, `docs`, `tools`, `data-raw`, `.codex`, `.git`, `.github`, and internal contract files -> 0 entries; Snow-gum data/cache entries -> 3.
- `R CMD check --as-cran --no-manual freqTLS_0.1.0.tar.gz` -> 0 errors, 0 warnings, 1 ordinary `New submission` NOTE; installed tests, examples, `donttest` examples, and vignette rebuilding passed.
- GitHub Actions run `29543780687` -> Ubuntu release/devel, Windows release, and macOS release all passed for the merged package source.

Interpretation:

- The merged source has a frozen, platform-clean technical candidate. This is not an upload or CRAN-acceptance claim: final `Authors@R` ordering remains for Dan and author approval before submission.

## 2026-07-18 -- Human-validation remediation (#15--#24)

Goal:

- Resolve the documentation, reference-page, Confidence-Eye, threshold-semantics,
  and tracker findings recorded from @itchyshin's assigned human-validation
  slice.

Checks and evidence:

- `Rscript --vanilla -e 'devtools::document(); devtools::build_readme(); devtools::check_man(); devtools::test(filter = "profile|predict")'` -> 110 passing tests, 0 failures, 0 warnings, 0 skips. This includes the new default-relative-midpoint test for `plot_tdt_curve()` and the existing non-closing-profile display test.
- `Rscript --vanilla -e 'devtools::test()'` -> 1,046 passing tests, 0 failures, 0 warnings, 0 skips (128.4 seconds) on the final source.
- `Rscript tools/build-site.R .` -> completed; internal `AGENTS`, `CLAUDE`, and `SPEC` files removed from the public site, and alt text filled for six reference example figures.
- `Rscript --vanilla -e 'pkgdown::check_pkgdown()'` -> `No problems found.`
- `rg -n -i 'posterior draws|full Confidence-Eye interval.*Phase 4|prose never uses "posterior"|Comment when your slice is complete' R README.Rmd README.md man pkgdown-site --glob '!pkgdown-site/search.json'` -> only deliberate Bayesian-comparison or historical-news references remain; the accessor reference now explicitly identifies bootstrap refits as frequentist estimates.
- `git diff --check` -> clean.

Interpretation:

- The public reference and rendered-site surfaces now distinguish frequentist
  bootstrap refits from posterior draws, define direct model terms, state the
  relative default used by `plot_tdt_curve()`, label Confidence-Eye scales, and
  visibly identify open profile intervals. The tracker-only shrimp and
  completion-comment items were corrected and closed without a package-source
  change.

## 2026-07-19 -- Daniel Noble review: generalized unit, threshold, and reader-surface remediation (#27, #29, #31, #34, #35, #37, #38, #39)

Goal:

- Treat the related review findings as one contract: duration is always in the
  caller's native unit; `t_ref` uses that same unit; `CTmax` is defined at that
  reference time; and relative and absolute targets have distinct meanings.

Checks and evidence:

- `Rscript --vanilla -e 'devtools::document(); devtools::build_readme(); devtools::check_man(); devtools::test()'` -> 1,076 passing tests, 0 failures, 0 warnings, 0 skips (132.2 seconds). The command regenerated roxygen output and README figures before testing.
- `Rscript tools/build-site.R .` -> completed; removed internal `AGENTS`, `CLAUDE`, and `SPEC` artifacts and filled alt text on six reference figures.
- `Rscript --vanilla -e 'pkgdown::check_pkgdown()'` -> `No problems found.`
- `git diff --check` -> clean.
- `rg -n -i 'CTmax_1hr|use `t_ref = 1` for hours|duration.*reference units|model \*coordinates\*|same likelihood-defined curve|Brown shrimp and life-stage zebrafish|frequentist analogue of posterior draws|p = 0.5.*relative' README.Rmd README.md R vignettes pkgdown-site --glob '!pkgdown-site/search.json' --glob '!pkgdown-site/news/**' --glob '!vignettes/case-study-shrimp.Rmd'` -> only the documented `CTmax_1hr` compatibility alias in `ts_stage2()`/`ts_ci()` (available only for `t_ref = 60`) and historical ROADMAP language remained.
- `find pkgdown-site -type f \( -name 'AGENTS.html' -o -name 'CLAUDE.html' -o -name 'SPEC.html' \)` -> no matches.

Interpretation:

- The public and programmatic surfaces now agree that no hidden conversion is
  applied: `t_ref = 1` means one hour only when duration is supplied in hours.
  Two-stage output labels, reference pages, plotted axes/captions, benchmark
  scripts, examples, and articles use that same rule. Bootstrap refits preserve
  every supported shape coefficient, while derived routes that cannot evaluate
  a varying shape at an unknown temperature reject the request before producing
  misleading output.

## 2026-07-21 -- CRAN DESCRIPTION quotation follow-up

Evidence:

- Konstanze Lauseker's CRAN acknowledgement (2026-07-21) requested that the
  next source update omit single quotation marks around terms that are not
  package or software names.
- `R CMD build --no-resave-data --no-manual .` -> built
  `freqTLS_0.1.0.tar.gz`; DESCRIPTION metadata passed.
- `R CMD check --as-cran --no-manual freqTLS_0.1.0.tar.gz` -> package checks,
  examples, tests, and vignette rebuild all passed. Its sole WARNING was
  `Insufficient package version (submitted: 0.1.0, existing: 0.1.0)` and
  `Days since last update: 0`, expected because 0.1.0 is already in CRAN's
  incoming process.

Interpretation:

- DESCRIPTION now retains quotes for the package names `bayesTLS` and
  `freqTLS`, but uses plain `Template Model Builder (TMB)` and `critical
  thermal maximum (CTmax)`. This is a source correction for a future update;
  it does not alter the tarball already submitted to CRAN and must not be
  resubmitted as version 0.1.0.
## 2026-07-21 -- Patrice Pottier review remediation (#46, #48--#54)

Goal:

- Remove the silent CTmax reference-time trap while preserving every explicit
  estimand, then complete Patrice's compatible terminology, getter, article,
  and reference-example repairs.

Checks and evidence:

- `Rscript -e 'devtools::document(); devtools::check_man(); devtools::load_all(quiet = TRUE); rmarkdown::render("README.Rmd", output_file = "README.md", quiet = TRUE); devtools::test(filter = "reference-time|fit-beta|profile")'` -> 98 passing checks, 0 failures, warnings, or skips. The renderer issued only external-badge fetch warnings under the sandbox; it wrote `README.md` successfully.
- `Rscript -e 'devtools::test()'` -> 1,096 passing tests, 0 failures, warnings, or skips (135.1 seconds). New tests prove physical one-hour equivalence for seconds/minutes/hours/days, column and formula `fit_tls()` resolution, explicit 1-minute and 240-minute preservation, bare-data warning, unknown-metadata error, and non-finite reference rejection.
- `Rscript -e 'pkgdown::build_reference(".")'`, `Rscript -e 'pkgdown::build_article("comparing-to-bayesTLS", ".", new_process = FALSE)'`, `Rscript -e 'pkgdown::build_article("case-study-summary", ".", new_process = FALSE)'`, then the post-build portion of `tools/build-site.R` -> rendered pages show one-hour resolution, explicit `character(0)` diagnostics, biology-first awake/coma wording, and the zero-duration rationale; no internal AGENTS/CLAUDE/SPEC pages remain.
- `Rscript -e 'pkgdown::check_pkgdown()'` -> `No problems found`.
- `rg -n -i 'per decade|per-decade' R man README.Rmd README.md vignettes docs/design docs/dev-log/known-limitations.md ROADMAP.md NEWS.md -g '!docs/design/10-after-task-protocol.md'` and the same scan of rendered HTML -> 0 active reader-surface hits.
- `R CMD build --no-resave-data --no-manual --keep-empty-dirs .` -> `freqTLS_0.1.0.tar.gz`, 1,225,575 bytes, 228 entries, SHA-256 `3565f9c8164de017188063216d2589b964939744a3a4793f8fdf54c56347e4ea`.
- `R CMD check --as-cran --no-manual freqTLS_0.1.0.tar.gz` -> 0 errors; the sole warning is CRAN incoming feasibility reporting that submitted/existing version `0.1.0` already exists, which is expected while the prior submission is in flight. Installed tests, examples, `donttest` examples, and vignette rebuild all passed.
- `git diff --check` -> clean.

Interpretation:

- Omission is now safe only when metadata identifies a physical unit: it means
  one hour. A numeric reference is never converted, so `t_ref = 1` on minute
  data remains CTmax at one minute. Bare data retain the backwards-compatible
  one-native-unit result but now warn; unknown labelled units fail until the
  user supplies a reference. The code/documentation changes are source work
  after the submitted tarball and do not amend that artifact.

## 2026-07-21 -- Documentation correctness pass (#47, #53 and cross-surface audit)

Goal:

- Make every known reader-facing correction concrete before requesting the
  remaining human validation, including the Confidence Eye and heat-injury
  examples formerly deferred from the reference-time repair.

Checks and evidence:

- `Rscript -e 'devtools::test()'` -> 1,116 passing tests, 0 failures, 0
  warnings, 0 skips (135.9 seconds).
- `Rscript -e 'devtools::document(); devtools::check_man()'` -> regenerated
  `plot_confidence_eye.Rd` and `standardize_data.Rd` without documentation
  problems.
- `Rscript -e 'pkgdown::check_pkgdown()'` -> `No problems found`; final
  `tools/build-site.R` evidence is recorded in the after-task report.
- `rg -n -i 'one minute|LT50 \(relative midpoint\)|synthetic examples|heat-injury prediction.*\*\*fitted\*\*|tls_eye_polygon_df|round\(\(1 - mortality\)' README.Rmd README.md R man vignettes docs inst pkgdown-site --glob '!docs/dev-log/check-log.md' --glob '!docs/dev-log/recovery-checkpoints/**'` -> only intentional current explanations or historical records.
- `rg -n -i 'posterior|credible' R man README.Rmd README.md vignettes docs pkgdown-site --glob '!pkgdown-site/search.json'` -> `bayesTLS` contrasts only; no freqTLS output uses Bayesian interval language.
- A direct rendered 7 by 3.45 inch Confidence-Eye PNG was inspected after the
  caption-wrap/margin and centre-mark repairs: the full confidence caption is
  visible, each parameter has an independent x scale, and the dark centre mark
  remains visible inside the hollow estimate ring.

Interpretation:

- The default confidence figure now communicates interval scale and source
  without a legend or misleading `z` rug. The real zebrafish teaching example
  uses a CC BY 4.0 installed dataset and labels its temperature trace as a
  hypothetical extrapolation from static assays. `fit_tls()`/`fit_4pl()` and
  all repaired examples preserve literal time units and distinguish relative
  midpoint from absolute survival targets.

## 2026-07-22 -- PR #56 reviewer correction: minute-valued reference time

Goal:

- Address Daniel Noble's review: make the public `tref` / `t_ref` contract
  unambiguously minute-valued, with one hour always written as `60`, without
  deleting the intentionally installed internal R-SHRIMP regression guard.

Checks and evidence:

- `Rscript -e 'rmarkdown::render("README.Rmd", output_file = "README.md", quiet = TRUE); devtools::test()'`
  -> 1,120 passing tests, 0 failures, warnings, or skips (132.9 seconds). The
  README renderer reported only unavailable external badge/MathJax resources;
  it regenerated `README.md` successfully.
- `Rscript -e 'devtools::load_all(); testthat::test_file("tests/testthat/test-reference-time.R", reporter = "summary"); devtools::check_man()'`
  -> the minute-normalisation contract and generated documentation passed.
- `rg -n --glob '!pkgdown-site/**' --glob '!man/**' 't_?ref\\s*=\\s*1[^0-9/]|one-native|1 in hours|1/24|same unit as.*duration' README.Rmd R vignettes docs/design NEWS.md`
  -> only deliberate statements that explicit `tref = 1` means one minute and
  the simulation helper's explicit one-minute default remain.

Interpretation:

- `standardize_data()` now converts recognised seconds/minutes/hours/days input
  to minutes and records both the input label and the canonical minute unit.
  `fit_4pl()` and `fit_tls()` therefore default to `60` minutes; direct bare
  data must already express duration in minutes. `simulate_tls()` retains its
  separately documented explicit one-minute default for test-fixture stability.

## 2026-07-22 -- Pieter pkgdown and home-page cleanup (#58, #59)

Goal:

- Repair site-wide equation rendering found during Pieter Arnold's human
  validation and remove benchmark-only fixture names from the public home page
  without removing their attribution from the distributed package.

Checks and evidence:

- `Rscript tools/build-site.R .` -> completed a clean full public-site build.
  Its rendered-artifact guards confirmed that KaTeX assets occur on
  `derive_lt`, `derive_ctmax`, `derive_tcrit`, and `model-math`; internal and
  benchmark-only discovery pages were still removed.
- `Rscript -e 'pkgdown::check_pkgdown()'` -> `No problems found`.
- `rg -n -i 'katex math|katex-auto.js' pkgdown-site/reference/derive_lt.html pkgdown-site/reference/derive_ctmax.html pkgdown-site/reference/derive_tcrit.html pkgdown-site/articles/model-math.html` -> KaTeX stylesheet, renderer, and local helper occur on every checked equation page.
- `rg -n 'shrimp_lethal|shrimp_sublethal|zebrafish_lethal' pkgdown-site/index.html` -> 0 matches.
- `git diff --check` -> clean.

Interpretation:

- `_pkgdown.yml` now selects KaTeX explicitly rather than relying on pkgdown's
  MathML default, and `tools/build-site.R` fails if its equation pages lose the
  KaTeX assets in a future build. The home page directs readers to canonical
  examples while `inst/CITATION` and `inst/COPYRIGHTS` retain the complete
  legacy-fixture attribution trail.
