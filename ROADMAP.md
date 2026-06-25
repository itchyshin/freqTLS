# freqTLS Roadmap

freqTLS is the maximum-likelihood / profile-likelihood complement to
`bayesTLS`: it fits the single-stage 4PL thermal-load-sensitivity model
by ML via TMB, parameterised directly in `CTmax` and `z`, and returns
profile-likelihood compatibility intervals. This roadmap lists the build
phases and their status. The authoritative fitted/planned/unsupported
boundary is `docs/dev-log/known-limitations.md` and
`docs/design/46-capability-matrix.md`; the live phase board is
`docs/dev-log/dashboard/`.

**Version status:** 0.1.0 (experimental lifecycle).

Status legend: `initial` (scaffold only, not yet implemented),
`implemented` (landed with tests, docs, examples, check-log, and an
after-task report), and `planned`.

## Phases

### Phase 0 – Bootstrap team, memory, docs, and package scaffold (implemented)

Owners: Ada + Grace + Rose. Copy and adapt the drmTMB agent-kit:
`AGENTS.md`, `CLAUDE.md`, `.claude/agents/` and `.codex/agents/`,
`.agents/skills/`, the SessionStart hook; build the `docs/dev-log/`
tree, the dashboard (port 8767), and `tools/checkpoint.R`; write the
numbered design docs; write `ROADMAP.md`, `NEWS.md`, `README.Rmd`, the
`DESCRIPTION` (four authors), a minimal `NAMESPACE`, `_pkgdown.yml`, the
CI workflows, `.Rbuildignore`, `inst/COPYRIGHTS`, and `inst/CITATION`.
**Gate:** the DESCRIPTION parses; usethis/devtools see a valid skeleton;
the vision, roadmap, and AGENTS are committed; the first check-log and
after-task entries are written.

### Phase 1 – TMB core and fit engine (implemented)

Owners: Gauss + Noether (+ Emmy). `src/profile_tls.cpp`,
`src/profile_tls_numeric.h`, `src/init.c`; `R/families.R`,
`R/model_matrix.R`, `R/fit_engine.R`, `R/fit_tls.R`, `R/utils.R`,
`R/simulate.R`; `test-parameter-transforms`. **Gate:** the package
compiles; binomial and beta-binomial simulations fit; finite logLik;
convergence code 0; `CTmax` and `z` recovered near truth; the transforms
test is green.

### Phase 2 – API, methods, and extractors (implemented)

Owners: Emmy + Boole + Curie. `R/methods.R` (print, summary, coef, vcov,
logLik, AIC, nobs), `R/extract.R` (`tidy_parameters`, `get_ctmax`,
`get_z`, `get_shape`); `test-fit-binomial`, `test-fit-beta-binomial`.
**Gate:** ungrouped and grouped fits are readable; recovery tests are
green.

### Phase 3 – Profile likelihood and identifiability diagnostics (implemented)

Owners: Fisher + Gauss + Pat. `R/profile.R`, `R/confint.R`,
`R/diagnostics.R` (the 12 warnings), an eye-style
`plot.profile_tls_profile`; `test-profile`, `test-group`. **Gate:**
`D(MLE)` near zero; finite closed CIs; `ci_z == exp(ci_log_z)`; a
non-closing profile gives a warning; group targets work.

### Phase 4 – Predict and Confidence-Eye plotting (implemented)

Owners: Florence + Darwin (parallel with Phase 5 after Phase 3).
`R/predict.R`, `R/plotting.R` (survival curves, the thermal death-time
curve, the surface, the Confidence-Eye profile and interval plots);
`test-predict`. **Gate:** monotone surfaces; the eye plots render;
Florence’s figure-audit passes.

### Phase 5 – bayesTLS benchmark harness (implemented)

Owners: Curie + Jason + Rose (parallel with Phase 4).
`data-raw/make_benchmark_data.R` (reconstructs shrimp counts from
proportions), `R/data.R`, `inst/CITATION`,
`data-raw/build_benchmark_cache.R`, the cache, `test-benchmark-sanity`.
**Gate:** the vendored shrimp counts are sane; the sanity test is green;
no Stan in CI.

### Phase 6 – Docs and pkgdown site (implemented)

Owners: documentation-writer + pkgdown-editor + Pat + Darwin +
literature-curator + Grace. README, the vignette suite (`freqTLS`,
`model-math`, `profile-likelihood`, `random-effects`,
`comparing-to-bayesTLS`, `frequentist-and-bayesian`, `heat-injury`, and
the six case studies), NEWS, the final `_pkgdown.yml`. **Gate:**
`devtools::document()`, `devtools::test()`, `devtools::check()`, and
[`pkgdown::build_site()`](https://pkgdown.r-lib.org/reference/build_site.html)
are clean locally.

Each phase closes with an after-task report, a check-log entry, and a
known-limitations / ROADMAP / README / capability-matrix sync
(Definition of Done). The adversarial Definition-of-Done gate before
“core done” is Rose + Pat + Fisher. Execution is sequential P0 -\> P1
-\> P2 -\> P3 (shared engine contract), then parallel P4 and P5, then
P6.

## v0.1 release boundary

**The `v0.1`/`v0.2`/`v0.3` headings below are build milestones, all
released in the single `0.1.0` version** (the fresh fork from
profileTLS). They are kept in build order to record how the surface
grew; nothing here is unreleased.

The v0.1 milestone (core) is count data (binomial and beta-binomial),
shared shape, grouped `CTmax`/`z`, profile CIs (and Wald), a
brms/drmTMB-style formula interface
([`tls_bf()`](https://itchyshin.github.io/freqTLS/reference/tls_bf.md)),
and the cached three-way benchmark. The v0.2 and v0.3 milestones (below)
then added the Beta family, random effects, bootstrap CIs, heat-injury,
and shape predictors — **all of which ship in 0.1.0**. Genuinely still
out of scope: time-to-event, multi-trait responses, a fit-time
absolute-threshold option and non-default `bounds`, a profile interval
or random effect for the upper asymptote `up`, and CRAN hardening. See
`docs/design/46-capability-matrix.md`.

## v0.2 milestone (released in 0.1.0)

Building beyond the v0.1 core, with complementary (not competitive)
framing against `bayesTLS` – the two packages are two valid lenses on
the same model.

- **Parametric bootstrap CIs – done.** Prior-free percentile intervals
  via `confint(method = "bootstrap")`, and the automatic fallback for a
  non-closing profile or a non-positive-definite Hessian
  (`fallback = TRUE`). freqTLS now always returns an interval, the same
  behaviour as the Bayesian path, without a prior.

- **Real `bayesTLS` benchmark cache – done.** Built from `bayesTLS`
  1.0.0.

- **Random intercept on `CTmax` – done.**
  `CTmax ~ <fixed> + (1 | group)` via TMB Laplace; no-RE path
  byte-identical; `sigma_CTmax` reported (ML, biased low with few
  groups);
  [`ranef()`](https://itchyshin.github.io/freqTLS/reference/ranef.md)
  BLUPs; and profile-likelihood intervals for the fixed effects under
  the random effect (the Laplace is re-run at each grid point;
  `sigma_CTmax`, the bootstrap, and the Confidence Eye stay on Wald).

- **Beta (continuous-proportion) family – done.** `family = "beta"` fits
  a response proportion in `(0, 1)` directly
  (`y ~ Beta(p * phi, (1 - p) * phi)`), no trials `n` required; point,
  Wald, profile (including `phi`), and bootstrap intervals all work, and
  grouped `CTmax`/`z` are supported.

- **Critical-temperature derivations – done.**
  [`derive_ctmax()`](https://itchyshin.github.io/freqTLS/reference/derive_ctmax.md)
  (absolute threshold) and
  [`derive_tcrit()`](https://itchyshin.github.io/freqTLS/reference/derive_tcrit.md)
  (rate-multiplier `T_crit = CTmax + z*log10(rate/100)`, lethal-endpoint
  only) complete the `bayesTLS`
  [`extract_tdt()`](https://itchyshin.github.io/freqTLS/reference/extract_tdt.md)
  absolute family by ML, as deterministic transforms of the fitted
  `CTmax`/`z`.

- **Heat-injury prediction – done.**
  [`predict_heat_injury()`](https://itchyshin.github.io/freqTLS/reference/predict_heat_injury.md)
  deterministically accumulates thermal damage from the fitted curve
  under a temperature trace (the ML analogue of
  `bayesTLS::predict_heat_injury()`), with an optional damage cutoff and
  an optional (unidentified) Sharpe-Schoolfield repair layer. One lethal
  dose maps to the **relative** midpoint survival by default, or to an
  **absolute** survival threshold via `target_surv`. It predicts from
  the fitted curve; fitting injury/repair models stays a bayesTLS
  concern.

- **Covariate (grouped) effects on the shape parameters – done.** `low`
  / `up` / `log_k` can vary by a grouping factor through the formula
  interface, relaxing the midpoint-only invariant (engine carries shape
  design matrices; intercept-only is byte-identical). Per-group
  estimates + Wald intervals +
  [`predict()`](https://rdrr.io/r/stats/predict.html);
  [`simulate_tls()`](https://itchyshin.github.io/freqTLS/reference/simulate_tls.md)
  accepts per-group shapes.

- **General continuous covariates on the shapes – done.** Each shape may
  carry its own design *independently* (continuous covariate, grouping
  factor, or intercept), no longer constrained to share one design or
  match the `CTmax` / `log_z` grouping. Per-shape engine widths
  (byte-identical default), link-scale coefficient estimates
  (`k:body_size` is a log-scale slope) with Wald intervals, and
  [`predict()`](https://rdrr.io/r/stats/predict.html) rebuilds each
  shape design from `newdata`. \## v0.3 milestone (released in 0.1.0)

- **Random intercept on `log_z` (item 5) — done.**
  `log_z ~ <fixed> + (1 | group)` adds a random intercept on thermal
  sensitivity, the symmetric counterpart of the v0.2 `CTmax` intercept
  (engine `b_logz` / `log_sd_logz` / `re_index_logz`, no-RE path
  byte-identical). `sigma_logz` is an ML SD on `log(z)` (a
  multiplicative spread on `z`, biased low with few groups);
  [`ranef()`](https://itchyshin.github.io/freqTLS/reference/ranef.md)
  returns the `log_z` BLUPs; fixed effects profile under the Laplace;
  the RE-aware bootstrap redraws the deviations. `CTmax` and `log_z`
  intercepts combine (same or different grouping); the same grouping
  fits two **independent** variances and warns. See
  `docs/design/08-random-effects.md`.

- **Random intercepts on the shape coordinates `low` and `log_k` —
  done.** `low ~ <fixed> + (1 | group)` and
  `log_k ~ <fixed> + (1 | group)` complete “random effects on any
  sub-parameter,” so REs are available on `CTmax` / `log_z` / `low` /
  `log_k` (engine `b_low` / `b_logk`, byte-identical no-RE path).
  `sigma_low` is a SD on `logit(low)`, `sigma_logk` on `log(k)` (both
  ML). The upper asymptote `up` is excluded (its nested gap has no
  single coordinate). The same-grouping independent-variance warning is
  generalised across all four coordinates. A dedicated
  [`vignette("random-effects")`](https://itchyshin.github.io/freqTLS/articles/random-effects.md)
  walks through the lot.

- **Heat-injury bootstrap envelope — done.**
  [`heat_injury_envelope()`](https://itchyshin.github.io/freqTLS/reference/heat_injury_envelope.md)
  returns a prior-free parametric-bootstrap compatibility band around
  the
  [`predict_heat_injury()`](https://itchyshin.github.io/freqTLS/reference/predict_heat_injury.md)
  survival trajectory (the likelihood-path analogue of the `bayesTLS`
  posterior survival band), reusing the same dose-accumulation
  integrator;
  [`plot_heat_injury()`](https://itchyshin.github.io/freqTLS/reference/plot_heat_injury.md)
  draws it.

- **Planned:** random effects further still — a second / crossed /
  nested grouping factor on one sub-parameter, random slopes, and
  correlated multivariate random effects across coordinates. These need
  a stacked-random-vector engine redesign; `bayesTLS` remains the path
  for a correlated random structure.
