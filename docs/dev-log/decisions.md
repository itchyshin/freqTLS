# Design Decisions

Durable design decisions for freqTLS, append-only. Each entry records what was
decided, why, the alternatives, and what future work must respect. The canonical
specification is `SPEC.md`; these entries record the decisions that shaped it.

## 2026-07-11: Treat 0.1.0 as one release candidate with the tested surface

- Decision: the historical v0.1/v0.2/v0.3 headings are build milestones, not
  published releases. The 0.1.0 candidate includes the implemented Beta family,
  formula and shape-design paths, limited independent random intercepts,
  parametric bootstrap, and deterministic heat-injury prediction.
- Boundary: time-to-event/multivariate responses, fitted injury/repair dynamics,
  correlated/random-slope/crossed/nested/`up` random effects, and universal
  profile support remain unsupported. Benchmark equivalence claims apply only
  to the matched relative-threshold, constant-shape configuration.
- Release gate: local implementation and validation do not imply CRAN release.
  Author consent, data redistribution authority, strict CRAN checks, and public
  CRAN package/check pages are separate evidence tiers.

## 2026-07-11: Correct snow-gum licensing; permission or exclusion

- Decision: the underlying snow-gum PSII source is CC BY-NC 4.0. Earlier current
  documentation that called it CC BY 4.0 was incorrect and is superseded.
- Consequence: never silently relicense the data. Record written redistribution
  permission if obtained; otherwise exclude the processed/raw data, derived
  cache rows, installed vignette, and package claims from the CRAN candidate.
- Historical task reports remain unchanged; this dated decision and the current
  component ledger carry the correction.

## 2026-07-11: Exclude unused environmental traces without a complete rights chain

- Decision: the unused Open-Meteo/ERA5 aphid trace and Orsted/NicheMapR/NCEP
  microclimate trace do not enter the 0.1.0 package. The records reviewed did not
  establish compatible redistribution authority for every underlying provider.
- Consequence: retain both files only under the build-excluded
  `data-raw/licensing-pending/environmental-traces` tree. Restoration requires
  compatible primary terms or written permission, complete installed
  attribution, and a documented package consumer.
- Rationale: a workflow or repository licence does not automatically license
  third-party environmental values produced or redistributed through it; unused
  files create avoidable release exposure.

## 2026-06-16: License is GPL (>= 3)

- Decision: freqTLS is released under GPL (>= 3), overriding the MIT default
  in early drafts.
- Reason: the repository LICENSE was already GPL-3, and freqTLS adapts
  engineering patterns from `drmTMB` and Confidence-Eye geometry from
  `gllvmTMB`, both GPL-3. The vendored `bayesTLS` **data** is CC BY 4.0, which is
  compatible with GPL-3 code as long as the data is attributed.
- Alternatives considered: MIT (rejected: incompatible with reusing GPL-3
  patterns from the sibling packages).
- Consequences: all new code is GPL-3; ported patterns get a provenance note in
  `inst/COPYRIGHTS`; vendored data is attributed in `R/data.R`, `inst/CITATION`,
  and the README.
- Evidence: `LICENSE`, `DESCRIPTION` (`License: GPL (>= 3)`), SPEC section 7.

## 2026-06-16: Direct CTmax and log_z midpoint parameterisation

- Decision: parameterise the 4PL midpoint directly in `CTmax` and `log_z`, with
  `mid = log10(tref) - (temp - CTmax) / z` and `z = exp(log_z)`, rather than in
  the bayesTLS intercept-and-slope coordinates.
- Reason: it makes the two headline scientific quantities, `CTmax` and `z`,
  direct model coordinates, so they can be profiled directly. The mapping is a
  smooth invertible reparameterisation of the bayesTLS constant-shape model
  (`z = -1 / beta1`, `CTmax = Tbar + (log10(tref) - beta0) / beta1`), so it has
  the same likelihood, curve, and MLE; profile likelihood is equivariant under a
  monotone reparameterisation, so the z-profile is `exp()` of the log_z-profile.
- Alternatives considered: profiling derived quantities from the
  intercept/slope parameterisation via the delta method or bootstrap (the
  bayesTLS-suggested route); rejected as the headline of freqTLS because it
  loses the direct, asymmetry-respecting profile.
- Consequences: changes to this mapping require an update to
  `docs/design/01-model-and-parameterisation.md`; the equivalence must be kept
  exact so the benchmark stays fair.
- Evidence: SPEC sections 6 and 7; `docs/design/01-model-and-parameterisation.md`.

## 2026-06-16: Nested-gap asymptote reparameterisation

- Decision: parameterise the asymptotes as `low = plogis(beta_low)` and
  `up = low + (1 - low) * plogis(beta_gap)`, so `up > low` is guaranteed without
  a constraint.
- Reason: it is unconstrained and smooth, and it is more flexible than the
  bayesTLS disjoint-bounds choice that forces `low < 0.5 < up` (a feasibility
  wall). Smoother profiles follow.
- Alternatives considered: disjoint bounds (the bayesTLS approach); rejected for
  the feasibility wall and rougher profiles.
- Consequences: profiling `up` is not a single internal coordinate, so it needs
  a one-off re-rooting on the native scale (or a Wald/delta fallback); this is
  documented in `docs/design/04-profile-likelihood.md`.
- Evidence: SPEC section 7; `docs/design/01-model-and-parameterisation.md`.

## 2026-06-25: Disjoint-bounds asymptotes (supersedes the nested gap above)

- Decision: parameterise the asymptotes with the bayesTLS `compute_4pl_bounds()`
  recipe — split the feasible band `[lower, upper]` at its midpoint and map each
  asymptote onto one half: `low = low_min + low_w * plogis(beta_low)` (lower
  half-band) and `up = up_min + up_w * plogis(beta_up)` (upper half-band). This
  **reverses** the 2026-06-16 nested-gap decision above.
- Reason: matching bayesTLS exactly lets the two packages share one asymptote
  contract (the twin goal), and gives `up` its own coordinate `beta_up` (the nested
  gap had none). The "feasibility wall" that motivated the nested gap is just the
  intended midpoint split, accepted here.
- Implemented: P1 (commit `3a29ac1`) — TMB switched `beta_gap` → `beta_up`, added
  the four bounds scalars (`low_min`/`low_w`/`up_min`/`up_w`), and `up` became a
  direct coordinate. Bounds default to `c(0, 1)` and reduce the old arithmetic
  exactly.
- Consequences: `up` now has a coordinate, but its profile path is not yet wired
  (it falls back to the delta-method Wald interval — symmetric work with `low`,
  simply not implemented); the compiled objective has no random-intercept term for
  `up`, so a random effect on `up` is still rejected.
- Evidence: `src/profile_tls.cpp` (`beta_up`, disjoint bounds); `compute_4pl_bounds`
  in `R/tdt-utils.R`; `docs/design/01-model-and-parameterisation.md`.

## 2026-06-16: Confidence Eye is the default uncertainty visual, never a posterior

- Decision: the default uncertainty display is the Confidence Eye (a likelihood
  compatibility lens with a hollow point estimate), and freqTLS prose uses
  "compatibility" / "confidence" language, never "posterior" / "credible".
- Reason: freqTLS produces likelihood compatibility intervals, not
  posteriors. A posterior-density visual or posterior language would mislead the
  reader and blur the boundary with `bayesTLS`. The distinct visual identity is
  also a teaching contrast in the comparison vignette.
- Alternatives considered: posterior-style density ribbons (rejected: implies a
  posterior that freqTLS does not compute).
- Consequences: Florence owns the figure gate; a non-closing profile renders a
  hollow point and an open lens, never a fabricated closed eye; the geometry is
  adapted from `gllvmTMB` (GPL-3) with provenance in `inst/COPYRIGHTS`.
- Evidence: SPEC sections 7 and 13; `.agents/skills/figure-visual-audit/SKILL.md`.

## 2026-06-16: bayesTLS framework authors are co-authors

- Decision: list Daniel W. A. Noble, Pieter A. Arnold, and Patrice Pottier as
  authors (`aut`) of freqTLS alongside Shinichi Nakagawa (`aut`, `cre`), and
  credit the bayesTLS framework as the origin of the modelling idea throughout.
- Reason: the thermal-load-sensitivity modelling framework and the 4PL
  midpoint-to-z/CTmax mapping are theirs (the `bayesTLS` package); freqTLS
  contributes the TMB ML likelihood, the direct reparameterisation, and the
  profile-likelihood machinery. A person should agree to being listed.
- Alternatives considered: crediting them only in the Description text (rejected:
  understates their contribution to the modelling framework).
- Consequences: confirm with the three co-authors before any public release;
  keep the credit in `DESCRIPTION`, the README, and wherever the model is
  introduced.
- Evidence: SPEC sections 7 and 8; `DESCRIPTION` `Authors@R`.

## 2026-06-16: simulate_tls() grouped API errors on misuse (no silent recycling)

- Decision: `simulate_tls()` validates the grouped API strictly. A non-atomic
  `group` (for example a list `group = list(A = list(CTmax = 34))`) is an error
  that points to the parallel vector API; a grouped `CTmax`/`z` must be either a
  single scalar (an explicit shared recycle) or a vector with one value per
  *distinct* group level (de-duplicated in first-appearance order, matching the
  `~ 0 + group` design), or it is an error.
- Reason: the previous `rep_len()` recycling silently accepted mismatched
  lengths and a list `group`, so a malformed call produced data from the default
  CTmax/z with no warning -- a footgun that could quietly invalidate a recovery
  test or a benchmark. Loud, specific errors are safer than silent defaults.
- Alternatives considered: keep `rep_len()` recycling (rejected: silent misuse);
  warn instead of error (rejected: a wrong DGP should not proceed).
- Consequences: `tls_recycle_param()` enforces the scalar-or-per-level rule;
  `simulate_tls()` and `fit_tls()` agree on group-level order. The canonical
  grouped call is `simulate_tls(group = c("A","B"), CTmax = c(34,38),
  z = c(3,5))`.
- Evidence: `R/simulate.R`; `tests/testthat/test-simulate.R`; SPEC section 11.

## 2026-06-16: Wald intervals are built on the internal link scale

- Decision: `tidy_parameters()` builds Wald confidence intervals on the internal
  (unconstrained / link) scale as `estimate +/- z * std.error` and
  back-transforms the endpoints to the natural scale. `CTmax` (identity link) is
  therefore the usual symmetric Wald interval; `z`, `low`, `k`, `phi` get
  bound-respecting asymmetric intervals; `up` (no single internal coordinate
  under the nested gap) uses a delta-method interval on the natural scale from
  the ADREPORTed `up` standard error. The `scale` column records the link used,
  and `interval_type = "wald"`.
- Reason: a link-scale interval respects each parameter's bounds (`z > 0`,
  `0 < low < up`) and is equivariant -- the `z` interval equals `exp()` of the
  internal `log_z` interval (verified to machine zero). It also puts Wald and the
  Phase-3 profile interval on the same natural scale, so they are directly
  comparable.
- Alternatives considered: a raw delta-method interval on the natural scale for
  every parameter (rejected: can cross bounds, e.g. negative `z` lower limits;
  agrees with the link-scale form only to first order anyway).
- Consequences: Phase 3 fills the same 8-column tibble with
  `interval_type = "profile"` and the profile roots, keeping `scale`. This is a
  minor, documented deviation from the SPEC's "delta or transform" phrasing,
  chosen for bound-safety and Wald/profile comparability.
- Evidence: `R/extract.R` (`tls_wald_natural`, `tls_param_scale`); SPEC sections
  10 and 13.

## 2026-06-16: Temperature effect through the midpoint only (v0.1)

- Decision: model the temperature effect through the midpoint only, with shared
  `low`, `up`, and `k`, matching the bayesTLS constant-shape configuration.
- Reason: it keeps the model identifiable on typical thermal death-time data and
  makes the benchmark against bayesTLS fair (the same constant-shape model).
- Alternatives considered: temperature effects on `low`, `up`, or `k` (a v0.1
  non-goal).
- Consequences: any change requires a design decision and an update to
  `docs/design/01` and `docs/design/02`.
- Evidence: SPEC section 7; `docs/design/02-family-registry.md`.

## 2026-06-16: Reconstruct the shrimp death counts from the CSV (R-SHRIMP)

- Decision: ship `shrimp_lethal` with death counts reconstructed from the
  bayesTLS source CSV proportion (`survived = total - round(mortality_prop *
  total)`), NOT taken from the shipped `bayesTLS::shrimp_lethal` object. Keep the
  original proportion as `mortality_prop` for provenance.
- Reason (verified, not assumed): the bayesTLS source CSV column
  `Mortality_after_trial` is a *proportion* dead, but the upstream build labels
  it a count and applies `as.integer()`, flooring every proportion below 1 to 0.
  Confirmed directly against the shipped `.rda` @HEAD on 2026-06-16: shipped
  deaths take only the values {0, 1} (113 zeros + 35 ones, **sum 35** over 148
  rows); the CSV reconstruction spans **0..11 (sum 738)**, and **86 rows** with a
  genuine non-zero proportion < 1 were floored to zero. The shipped object drops
  ~95% of the observed mortality, so the shrimp 4PL is not identifiable from it.
- Alternatives considered: (a) use the shipped object as-is (rejected: the curve
  cannot be fit -- the shrimp fit only converges to sensible estimates
  [CTmax 31.8, z 2.2, phi 7.1] on the corrected counts); (b) silently patch
  without provenance (rejected: `mortality_prop` is retained and the rebuild is
  documented in `R/data.R`, `make_benchmark_data.R`, and the cache meta, with a
  friendly upstream report drafted).
- Consequences: `data-raw/make_benchmark_data.R` asserts the rebuilt distribution
  is not collapsed before shipping; `data-raw/build_benchmark_cache.R` feeds the
  comparators the *corrected* data so the benchmark isolates method differences
  from the data bug; zebrafish is unaffected (its upstream build is correct) and
  is taken as shipped.
- Evidence: SPEC sections 5, 12, 14 (R-SHRIMP); the shipped vs corrected
  distributions in `docs/dev-log/check-log.md` (2026-06-16 Phase 5) and the
  upstream report in
  `docs/dev-log/comparator-results/2026-06-16-bayesTLS-upstream-report.md`.

## 2026-06-16: The bayesTLS benchmark cache is maintainer-built, not built in CI

- Decision: the bayesTLS posterior + classical two-stage benchmark numbers live
  in a committed cache `inst/extdata/bayesTLS_benchmark_cache.rds`, built by hand
  via `data-raw/build_benchmark_cache.R` (guarded to stop without bayesTLS +
  cmdstanr) and refreshed after a bayesTLS update; freqTLS is fitted live.
- Reason: Stan/cmdstanr and bayesTLS are not available at test/CI time (and the
  package must not depend on them there). Re-running a full Bayesian fit on every
  check is also slow and non-reproducible across Stan toolchains.
- Alternatives considered: (a) a hard bayesTLS/Stan dependency in CI (rejected:
  R-STALE constraint, no Stan at CI time); (b) re-implementing the comparators in
  freqTLS (rejected: the benchmark must call bayesTLS, not a re-derivation).
- Consequences: `test-benchmark-sanity` skips gracefully when the cache is absent
  (it is absent in this environment); the comparison vignette reads the cache
  with `eval = TRUE` and shows live bayesTLS calls with `eval = FALSE`; the cache
  carries a `meta` provenance block (bayesTLS_version, git_sha, cmdstan_version,
  date_built, seed, config, R-SHRIMP realized-distribution note) so drift is
  visible (R-STALE).
- Evidence: SPEC sections 12, 14 (R-STALE); `data-raw/build_benchmark_cache.R`
  (guard executed and confirmed to stop, cache rds confirmed absent, 2026-06-16).

## 2026-06-17: Covariates on the shape parameters low / up / log_k (v0.2)

- Decision: relax the v0.1 "temperature effect through the midpoint only"
  invariant so that `low`, `up`, and `log_k` may vary by a **grouping factor**,
  via the same design-matrix mechanism `CTmax` and `log_z` already use. The TMB
  engine takes per-sub-parameter design matrices `X_low`, `X_gap`, `X_logk` and
  treats `beta_low` / `beta_gap` / `beta_logk` as coefficient vectors; an
  intercept-only design (a single column of ones) reduces each to the shared
  scalar, so the default fit is **byte-identical** to the shared-shape model. The
  v0.2 relaxation is **grouped shapes** (`low ~ group`, `up ~ group`,
  `log_k ~ group`), at the same level of support `CTmax` / `z` have (grouped via
  `~ 0 + group`, with predict / plot / profile resolving per group). The three
  shape designs must match (as `CTmax` / `log_z` must), and they share the
  group-level structure used elsewhere.
- Reason: the maintainer approved the full v0.2 roadmap ("do all"), which lists
  covariate effects on the shape parameters. Per-group steepness and asymptotes
  answer real thermal-biology questions (e.g. does the dose-response steepness
  differ between life stages?). The midpoint-only restriction was a v0.1
  identifiability and benchmark-fairness choice, not a permanent constraint.
- Alternatives considered: (a) keep midpoint-only (rejected: the maintainer asked
  to relax it); (b) an additive "scalar intercept + covariate deviation" engine
  form (rejected: asymmetric with the `~ 0 + group` design `CTmax` / `z` use, and
  awkward for the nested-gap `up`); (c) arbitrary continuous covariates on the
  shapes (deferred: this would also require reworking the group-keyed prediction
  resolver `tls_predict_pars()`, for marginal additional value over grouped
  shapes; a clear error directs users for now).
- Consequences: the benchmark against bayesTLS still locks all three estimators
  to the constant-shape (midpoint-only) configuration for a fair comparison; the
  relaxed shapes are an additive capability, not the default. `docs/design/01`
  and `docs/design/02` are updated. The **byte-identical gate** (intercept-only
  == the prior shared-scalar model, all existing tests passing with their
  original values) is the hard constraint on the engine change. This supersedes
  the 2026-06-16 "Temperature effect through the midpoint only (v0.1)" decision,
  which remains the v0.1 default and the benchmark configuration.
- Evidence: `src/profile_tls.cpp` (`X_low`/`X_gap`/`X_logk`, design-vector shape
  parameters); the 2026-06-17 handoff (maintainer "do all").

## 2026-06-17 -- Shapes may carry independent designs (continuous covariates)

- Decision: remove the "three shapes share one design and match the `CTmax` /
  `log_z` grouping" constraint. Each shape (`low`, `up`, `log_k`) may now carry
  its OWN design independently -- a grouping factor, a continuous covariate
  (`log_k ~ body_size`), or an intercept.
- Why: the maintainer-approved "do all" roadmap item; a covariate on a single
  shape (does steepness depend on body size?) is a natural question the
  same-design constraint blocked.
- Engine: per-shape `shared` detection in `src/profile_tls.cpp` (`low_shared` /
  `gap_shared` / `logk_shared`) lets a covariate on one shape be honoured while
  another stays intercept-only; verified **byte-identical** for the shared /
  grouped cases (the hard gate). Committed as `4987423`.
- Reporting: a general (continuous) shape coefficient is on its **link scale**
  (`k:body_size` is a log-scale slope), like a GLM coefficient -- NOT
  back-transformed. One-hot grouped shapes keep natural per-group values.
  Profiling a single continuous slope routes to **Wald** (like `up`); a dedicated
  profile is a possible refinement.
- Consequences: `predict()` rebuilds each shape design from `newdata` via the
  stored `shape_terms`. The benchmark against bayesTLS still uses the
  constant-shape configuration. Supersedes the same-design half of the grouped
  decision above.

## 2026-06-17 -- Random intercept on log_z (item 5); independent variances only

- Decision: add a single random intercept on `log_z`
  (`log_z ~ <fixed> + (1 | group)`), the symmetric counterpart of the v0.2 `CTmax`
  intercept, as a faithful mirror of the `b_CT` engine (`b_logz` / `log_sd_logz` /
  `re_index_logz`, appended at the end of the C++ declarations). The deviation is
  Gaussian on the `log_z` coordinate (before `exp`), so `sigma_logz` is a SD on
  `log(z)`. `CTmax` and `log_z` intercepts may be combined, but only as
  **independent** variances — no correlation term — and the parser warns when the
  same grouping factor is on both.
- Reason: between-group variation in thermal **sensitivity** (`z`) is as real as
  variation in tolerance (`CTmax`); the log-scale placement is the correct analogue
  (additive on the sub-parameter's internal coordinate). A correlated bivariate
  `(CTmax, log_z)` random effect needs a covariance parameterisation that is a
  larger change and is better served by `bayesTLS`; independent intercepts are the
  high-value, low-risk slice.
- Alternatives considered: (a) a multiplicative RE on `z` directly (rejected:
  breaks the equation↔C++ correspondence and is a different model); (b) a
  correlated `(CTmax, log_z)` 2×2 random effect (deferred: covariance machinery,
  out of scope); (c) a stored `re_blocks` field on the fit object (chosen instead:
  an on-demand `tls_re_blocks()` helper deriving blocks from `fit$re` / `fit$re_logz`,
  keeping the persisted object contract and back-compat while centralising the
  per-block bookkeeping).
- Consequences: byte-identical gate re-verified (498 pass / 0 / 0 / 0; the no-RE
  and CTmax-only paths unchanged). `sigma_logz` is honestly labelled a log-scale SD
  (multiplicative on `z`), ML-biased low with few groups. Reviewed by Gauss
  (engine), Noether (math), Emmy (architecture), Fisher (inference) before
  implementation.
- Evidence: `src/profile_tls.cpp`, `R/formula.R` (`tls_extract_re`), `R/utils.R`
  (`tls_re_blocks` / `tls_has_re`), `tests/testthat/test-random-effects-logz.R`,
  `docs/design/08-random-effects.md`.

## 2026-06-17 -- Random intercepts on the shape coordinates low and log_k; up excluded

- Decision: extend the random-intercept system to `low` and `log_k`
  (`<param> ~ <fixed> + (1 | group)`), the shape-coordinate analogues of the
  CTmax / log_z REs, reusing the `tls_re_blocks()` path. The upper asymptote `up`
  is deliberately **excluded**: its nested gap (`up = low + (1-low)*plogis(beta_gap)`)
  has no single internal coordinate, the same reason `up` has no profile coordinate.
  The engine adds the deviation on each shape's internal (logit / log) scale under a
  byte-identical guard (the no-RE path is the original code verbatim). The
  same-grouping independent-variance warning is generalised to fire once per shared
  grouping across any of CTmax / log_z / low / log_k.
- Reason: completes "random effects on any sub-parameter" (the first item on the
  design/08 out-of-scope list) cleanly. Between-group variation in the
  background-survival asymptote (`low`) is a real hierarchical need; `log_k` rounds
  out the set. `low` and `log_k` have clean single coordinates, so the mirror is
  byte-identical-safe; `up` does not, so it stays out.
- Alternatives considered: (a) a RE on `up` via the gap coordinate (rejected:
  `sigma_gap` is uninterpretable and inconsistent with up's coordinate-less
  treatment); (b) crossed / nested REs and a second grouping factor on one
  sub-parameter (deferred: TMB's static parameter structure makes this a
  stacked-random-vector engine redesign — "the big one" — not a safe incremental
  slice; `bayesTLS` is the path for correlated/crossed structures meanwhile).
- Consequences: byte-identical gate re-verified (the no-RE / CTmax-only / log_z-only
  paths unchanged). Shape REs are more weakly identified than CTmax (need data
  informing the asymptote / steepness per group); documented. `simulate_tls()`
  gains `re_sd_low` / `re_sd_logk` (RNG-stream-preserving for existing calls).
- Evidence: `src/profile_tls.cpp`, `R/formula.R`, `R/utils.R`, `R/simulate.R`,
  `tests/testthat/test-shape-random-effects.R`, `docs/design/08-random-effects.md`.
