# After Task: Phase 6 -- docs, vignettes, and pkgdown site

## Date

2026-06-16

## Task

Write the project documentation and build the pkgdown site (SPEC.md S4 project
docs, S13 docs/pkgdown/CI + Confidence-Eye contract + comparison teaching device,
S17 acceptance). Deliverables (Phase 6: documentation-writer + pkgdown-editor +
Pat + Darwin + literature-curator + Grace): regenerate README.Rmd -> README.md
with embedded homepage plots; write four knitr vignettes that build WITHOUT Stan
(`profileTLS`, `model-math`, `profile-likelihood`, `comparing-to-bayesTLS`); flesh
out NEWS.md; finalise `_pkgdown.yml`; and run the consistency sync (Rose hat) so
README / ROADMAP / NEWS / known-limitations / status.json agree (the one-work-
ledger rule). Hard constraint: the comparing-to-bayesTLS vignette must build with
no Stan / bayesTLS installed; profileTLS interval language must stay
"compatibility / confidence", never "posterior" / "credible". Gate: document /
build_readme / test / R CMD check / pkgdown::build_site clean locally.

## Created / Changed

Created:

- `vignettes/profileTLS.Rmd` -- getting started. simulate_tls -> fit_tls ->
  print/summary -> tidy_parameters/get_ctmax/get_z -> confint(method="profile")
  for CTmax & z -> confint(method="wald") comparison -> plot_survival_curves +
  plot_confidence_eye. Always-eval, tiny sim (seed 1).
- `vignettes/model-math.Rmd` -- the 4PL; the direct
  `mid = log10(tref) - (temp - CTmax)/z` parameterisation, verified numerically
  on a live fit (midpoint == log10(tref) at temp = CTmax; midpoint slope in T ==
  -1/z); the nested-gap asymptote transform + the coordinate/link table;
  relative-vs-absolute thresholds (derive_lt / plot_tdt_curve, default relative);
  and the bayesTLS bridge identities `z = -1/b_mid_temp_c`,
  `CTmax = Tbar + (log10(tref) - b_mid_Intercept)/b_mid_temp_c`, plus the inverse
  `beta1 = -1/z`, `beta0 = log10(tref) + (CTmax - Tbar)/z`, checked numerically by
  recovering CTmax/z from the fit's own predicted midpoints (no Stan).
- `vignettes/profile-likelihood.Rmd` -- the LR/deviance profile algorithm, the
  profile() object + plot(); asymmetry and equivariance (live: z CI == exp(log_z
  CI), and the asymmetric lower/upper gaps); profile vs Wald; the upper-asymptote
  delta-Wald fallback; and the honest non-closing fallback (a deliberately sparse
  2x2 design -> open CI returning NA + an `open_*` conf.status + a hollow-point
  Confidence Eye, with the warning caught via withCallingHandlers so the vignette
  still builds).
- `vignettes/comparing-to-bayesTLS.Rmd` -- credit/origins; the three-way design
  table (classical two-stage / Bayesian / profileTLS, all relative-threshold,
  constant-shape); the live bayesTLS `fit_4pl(temp_effects="mid")` /
  `extract_tdt(target_surv="relative")` / `ts_stage1->ts_stage2->ts_ci` recipe in
  `eval=FALSE` chunks; a cache-read chunk guarded by
  `nzchar(cache_path) && file.exists(cache_path)` on
  `system.file("extdata","bayesTLS_benchmark_cache.rds", package="profileTLS")`
  that, when the cache is absent (it is), prints the path + a "run
  data-raw/build_benchmark_cache.R on a Stan machine to populate" note instead of
  erroring; live profileTLS fits on shrimp (profile CTmax/z) + zebrafish
  (per-stage CTmax); and the posterior-density-vs-Confidence-Eye teaching device
  (the eye drawn live; the posterior half described/placeholdered until the cache
  exists). Builds with NO Stan.
- `docs/dev-log/after-task/2026-06-16-phase-6-docs-site.md` -- this report.

Changed:

- `R/confint.R`, `R/diagnostics.R`, `R/profile.R` -- demoted three `[fn()]`
  auto-links to internal `@noRd` helpers (`tls_wald_natural`, `check_tls_data`,
  `tls_resolve_contrast`) to inline code, resolving the lingering document
  cross-link warnings carried since earlier phases.
- `R/profile.R` -- added `@param digits` to `print.profile_tls_profile`
  (undocumented-argument WARNING fix).
- `R/plotting.R` -- the three `Temperature (degC)` / `Temp (degC)` axis labels:
  the literal degree sign converted to the `°` escape (non-ASCII NOTE fix;
  renders identically as a degree sign).
- `README.Rmd` -> `README.md` -- removed the broken logo `<img>` (no logo asset
  exists); the Example now evaluates the quick loop (simulate -> fit ->
  confint(profile) for CTmax & z) and embeds the rendered survival-curve and
  Confidence-Eye plots with fig.alt; tightened the closing pointer to
  `vignette("profileTLS")`. Regenerated via `devtools::build_readme()`.
- `NEWS.md` -- fleshed out the 0.0.0.9000 entry (model/engine, methods/extractors,
  profile likelihood + diagnostics, prediction/plotting, data, documentation).
- `_pkgdown.yml` -- finalised: Bootstrap5/flatly; navbar
  intro/reference/articles/news/github; reference sections listing the ACTUAL
  exports (Fitting & post-fit / Profile likelihood / Prediction & plotting /
  Simulation / Data / Package); articles grouped Get started / Model details /
  Comparison.
- `DESCRIPTION` -- added `VignetteBuilder: knitr`; removed the unused `Matrix`
  Import (unused-Imports NOTE fix).
- `.Rbuildignore` -- added `^LICENSE$` (GPL (>= 3) is a standard license; the
  full-text LICENSE file should not ship in the tarball -> top-level-files NOTE
  fix; the file stays in the repo for GitHub display).
- Consistency sync (Rose hat): `docs/dev-log/known-limitations.md` top header
  "Phase 2" -> "Phase 6" + the "Interval caveat (Phase 2)" section rewritten to
  reflect that both Wald and profile methods are fitted; `ROADMAP.md` Phases 1-6
  status `(initial)` -> `(implemented)`; `docs/dev-log/dashboard/status.json`
  Phase 6 -> verified (slice text expanded), metrics verified 6 -> 7, Pat agent
  queued -> verified, profileTLS repo head "Phase 5" -> "Phase 6" with the note
  updated; `docs/dev-log/check-log.md` Phase 6 entry appended.

## Checks Performed (exact commands + counts)

- `R -q -e 'devtools::document(".")'` -> clean. Before the cross-link fixes it
  emitted three "Could not resolve link to topic" warnings (tls_wald_natural,
  check_tls_data, tls_resolve_contrast); after, zero warnings.
- `R -q -e 'devtools::build_readme()'` -> README.md regenerated;
  `man/figures/README-readme-survival-1.png` + `README-readme-eye-1.png` written;
  the embedded confint output shows CTmax conf.low/high [35.8, 36.3], z
  [3.43, 4.38], both `conf.status = ok`, method profile.
- `R -q -e 'devtools::test(".")'` -> `[ FAIL 0 | WARN 0 | SKIP 1 | PASS 201 ]`.
  The SKIP is test-benchmark-sanity.R:31:3 "bayesTLS benchmark cache absent (needs
  Stan + bayesTLS to build)" -- unchanged from Phase 5.
- `_R_CHECK_FORCE_SUGGESTS_=false R -q -e 'rcmdcheck::rcmdcheck(args =
  c("--no-manual"), error_on = "never", env = c("_R_CHECK_FORCE_SUGGESTS_" =
  "false"))'`. The build log shows `creating vignettes ... OK` (all four,
  including comparing-to-bayesTLS, built with no Stan), `checking examples ...
  OK`, `checking tests ... OK`, `checking re-building of vignette outputs ... OK`.
  Final result, verbatim:

```
── R CMD check results ────────────────────────────── profileTLS 0.0.0.9000 ────
Duration: 1m 21.5s

0 errors ✔ | 0 warnings ✔ | 0 notes ✔
```

  (Without `_R_CHECK_FORCE_SUGGESTS_=false`, R CMD check returns 1 ERROR
  "Package suggested but not available: 'bayesTLS' ... Checking can be attempted
  without them by setting the environment variable _R_CHECK_FORCE_SUGGESTS_ to a
  false value" -- a pure environment artifact, since bayesTLS is an optional
  Suggest used only in eval=FALSE vignette chunks and one skipped test.)

- `R -q -e 'pkgdown::build_site(preview = FALSE)'` -> SUCCESS into
  `pkgdown-site/`. Built articles/index.html + all four article HTML files
  (profileTLS, model-math, profile-likelihood, comparing-to-bayesTLS), 36
  reference HTML pages, the reference index across all sections, news/index.html,
  sitemap, redirects, and the search index; "Finished building pkgdown site for
  package profileTLS" with no problems and no warnings on a clean re-run.

## Outcomes

- The full Phase 6 verification gate is clean: document (no warnings),
  build_readme (figures rendered), test (201 pass / 1 skip), R CMD check
  (0 errors, 0 warnings, 0 notes with the standard force-suggests flag), and
  pkgdown::build_site (4 articles + reference index, no problems).
- The comparing-to-bayesTLS vignette is verified to build with NO Stan and no
  bayesTLS: the cache-read chunk is guarded by file.exists() and the cache is
  absent, so the vignette renders the recipe + the "run the cache builder on a
  Stan machine" note + the live profileTLS fits + the Confidence-Eye half of the
  teaching device.
- The README homepage carries a rendered survival-curve plot and a rendered
  Confidence-Eye plot, the model equation, the credit/origins, the install line,
  and the data credits; the quick example runs live.

## Consistency Review

- One-work-ledger sync applied this commit: README, ROADMAP, NEWS,
  known-limitations, the capability dashboard (status.json), and the design docs
  now agree that the v0.1 surface (Phases 1-6) is implemented, with the single
  outstanding gap being the maintainer bayesTLS+two-stage cache.
- Stale-wording scan (rg over docs + R + vignettes):
  - `rg -n "posterior|credible" R/ vignettes/ README.md` -> the only hits are
    deliberate contrastive uses describing the *bayesTLS* posterior in the
    comparison vignette/README and the explicit "never posterior/credible"
    statements; no profileTLS interval is called a posterior or credible.
  - `rg -n "Phase 2" docs/dev-log/known-limitations.md` -> no stale
    "Current status: Phase 2" header remains.
  - `rg -n "\(initial\)" ROADMAP.md` -> none; all phases now implemented.
  - `rg -n "Wald intervals only|not implemented yet" docs/dev-log` -> none in
    known-limitations (the Phase-2-only interval caveat is rewritten).
- pkgdown reference topics were checked against `man/*.Rd` aliases before listing
  (tls_family covers binomial_tls/beta_binomial_tls; profile_tls-methods covers
  the S3 methods; the internal-keyword tls-diagnostics page is intentionally not
  listed -- only the exported check_tls is).

## Tests Of The Tests

- The test suite is unchanged in count and content this phase (docs-only code
  edits plus three roxygen/label fixes); 201 pass / 1 skip is identical to Phase
  5, confirming no regression from the cross-link, degree-sign, or DESCRIPTION
  changes. The vignettes are exercised by R CMD check's "re-building of vignette
  outputs", which is the real test that they run end to end without Stan.
- The non-closing-profile claim in the profile-likelihood vignette is
  self-checking: the chunk prints the actual `conf.status` and the NA endpoint,
  so a future change that silently fabricated a bound would visibly alter the
  rendered vignette.

## What Did Not Go Smoothly

- R CMD check's default hard ERROR on a missing optional Suggest (`bayesTLS`) is
  not a package defect but reads alarmingly; the fix is R's own documented
  `_R_CHECK_FORCE_SUGGESTS_=false`, which is also what the ubuntu-only, no-Stan CI
  effectively relies on (it never installs bayesTLS). Worth a one-line note in the
  release checklist so a future runner does not mistake it for a real failure.
- The Edit tool normalises Unicode, so the literal degree sign could not be
  swapped for its `°` escape via Edit; used a byte-level perl substitution
  (`s/\xc2\xb0/\\u00b0/g`) instead, then verified the labels still render as a
  degree sign and the file parses.
- pkgdown also renders the root governance markdown (AGENTS/CLAUDE/SPEC/ROADMAP)
  as top-level site pages. This is cosmetic and out of the Phase-6 gate's scope
  (the gate is the 4 articles + reference index, all built); flagged for a later
  pass if the public site should hide them.

## Team Learning

- Demoting `[fn()]` auto-links to inline code is the right move for references to
  `@noRd` internal helpers: the link can never resolve (there is no .Rd), so it is
  a permanent document warning otherwise. Reserve `[fn()]` for exported/documented
  topics.
- For a vignette that depends on an uninstallable backend (Stan), the durable
  pattern is: live recipe in `eval=FALSE` + a `file.exists(system.file(...))`-
  guarded cache read that degrades to an informative note, never an error. This
  keeps the article in the built site and CI while remaining honest about the
  missing numbers.
- Speculative Imports (here Matrix) accrued at scaffold time surface as R CMD
  check NOTEs; prune them when the implementation settles.

## Known Limitations

- The bayesTLS + two-stage benchmark cache
  (`inst/extdata/bayesTLS_benchmark_cache.rds`) is still absent (needs Stan +
  bayesTLS, not installable here). The comparison vignette builds and shows the
  recipe + the live profileTLS side, but the cached Bayesian/two-stage numbers
  and the full three-way table are unavailable until a maintainer runs
  `data-raw/build_benchmark_cache.R`. No coverage rates or numeric three-way
  comparisons are claimed.
- Interval coverage has not been simulated; the intervals are tested for
  self-consistency (equivariance, D(MLE)=0, honest non-closing), not for nominal
  coverage.
- The homepage governance-markdown pages and the missing logo are cosmetic
  follow-ups, not v0.1 blockers.

## Next Best Task

- Run the adversarial Definition-of-Done gate (Rose: stale wording / consistency
  / R-SHRIMP; Pat: a new user can fit + interpret + read the warnings from the
  vignettes; Fisher: profile equivariance, identifiability, fair benchmark) to
  sign off "core done".
- On a Stan machine, run `data-raw/build_benchmark_cache.R` to populate the cache,
  then re-knit comparing-to-bayesTLS so the three-way table and the
  posterior-vs-eye teaching figure render, and confirm test-benchmark-sanity
  stops skipping and passes within tolerance.
