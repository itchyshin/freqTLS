# NEW-SESSION HANDOFF — profileTLS (read this first)

Start with zero context; trust repo state + this file. The previous session
completed the v0.2 "do all" roadmap plus three deferred items and ran out of
context. This file is the live pickup.

## Repo state (verified)
- Branch `feat/v0.1-core`, PR #1, tip **`9069fee`**, clean + pushed.
- `devtools::test()` = **389 pass / 0 fail / 0 warn / 0 skip**.
- `rcmdcheck::rcmdcheck(args = "--no-manual", build_args = "--no-manual",
  env = c("_R_CHECK_FORCE_SUGGESTS_" = "false"), error_on = "never")` = **0/0/0**
  at the tip. CI green; the pkgdown site auto-deploys to gh-pages on R-CMD-check
  success.

## Shipped this session (committed `b5c769c`..`9069fee`)
v0.2 features: **beta family** (`family = "beta"`, family_code 2); **profile
intervals under a random effect**; **`derive_tcrit()`** (rate-multiplier critical
temperature); **deterministic `predict_heat_injury()`**; **grouped covariate
effects on `low`/`up`/`log_k`** (engine refactor `bee8d04` byte-identical, then
capability `5a9b78a`); the **frequentist-vs-Bayesian vignette** (incl.
clamping/shrinkage/penalties as implicit priors, 15 verified refs); v0.2 polish/
close-out. Deferred items since: **RE-aware parametric bootstrap for
`sigma_CTmax`** (`9e792fe`); **profile + bootstrap intervals for grouped shape
coordinates** (`9069fee`). 309 -> 389 tests; byte-identical gate held throughout.

## Remaining plan (the "do all" the maintainer approved)
1. **Absolute-target heat injury** — add a `target_surv` arg to
   `predict_heat_injury()` (LT and the dose->survival map gain the
   `qlogis((surv - low)/(up - low))/k` correction; currently relative-threshold
   only). Small slice.
2. **Flagship grouped-shape / RE README example** — a worked front-page example
   of a v0.2 capability; re-knit `README.Rmd`. Small.
3. **Reanalyse bayesTLS data + vendor new datasets + examples** (maintainer
   request: "reanalyse all the data bayesTLS does, find more, add to examples").
   - Reanalyse the vendored `shrimp_lethal` / `zebrafish_lethal` with the v0.2
     features (grouped shapes, RE, `derive_tcrit`, `predict_heat_injury`); expand
     the comparison vignette / examples.
   - **RE-RUN the dataset search** — the prior `landscape_scout` run was lost when
     the process exited (no findings captured). Re-dispatch it (prompt below):
     enumerate every dataset bayesTLS ships/analyses, and find additional
     **openly-licensed (CC0 / CC-BY / public-domain)** thermal-death-time datasets
     (temperature x duration x survival-count-or-proportion). **Vendor only
     clearly-licensed data, with attribution in `R/data.R` + `inst/CITATION`**
     (R-LICENSE discipline). Report-don't-vendor anything with an unclear license.
   - The **live bayesTLS head-to-head needs Stan** (not available here): do the
     profileTLS side live and wire the Bayesian side to the maintainer-built
     cache (`data-raw/build_benchmark_cache.R`, guarded).
4. **General continuous covariates on the shapes** (e.g. `log_k ~ body_size`) —
   rework `tls_predict_pars()` from group-keyed to applying the stored design
   matrix to `newdata`; touches predict/plot/profile/estimates. Medium-large.
5. **Random effects beyond a single `CTmax` intercept** — random slopes, REs on
   `z`/shapes, crossed/nested factors. Large; engine + formula + downstream.
6. **CRAN hardening** — `cran-extrachecks`, DESCRIPTION/URLs/examples,
   `--as-cran`, cross-OS CI before submission. (Release-gating; the package is
   still `0.0.0.9000`. The Stan benchmark cache stays maintainer-built.)

## NON-NEGOTIABLE discipline
- **Byte-identical gate:** any `src/profile_tls.cpp` change must leave the
  existing tests passing with their original values. The shape params
  (`beta_low`/`beta_gap`/`beta_logk`) are `PARAMETER_VECTOR`s with `X_low`/
  `X_gap`/`X_logk` designs AND a **scalar fast-path when size == 1** (the matrix
  product is skipped) -- this is the byte-identical lever; preserve it. Verify
  bit-identical for well-conditioned fits via a `git stash` baseline comparison
  if you touch the engine.
- **TDD** (write the failing test, watch it fail, implement). **Commit + push
  each verified slice** to `feat/v0.1-core`. **Docs in the same commit**: NEWS,
  ROADMAP, `docs/dev-log/known-limitations.md`,
  `docs/design/46-capability-matrix.md`, the relevant numbered design doc, +
  an after-task report in `docs/dev-log/after-task/` and a check-log entry.
- **R CMD check** (`_R_CHECK_FORCE_SUGGESTS_=false`) 0/0/0 per slice before push.
- Complementary/pluralistic framing; **compatibility/confidence** language for
  profileTLS (never posterior/credible); internal docs stay off the public site.

## Implementation map (orientation)
- Families 0/1/2 (binomial/beta-binomial/beta) in `src/profile_tls.cpp`; beta
  uses `dbeta(y, p*phi, (1-p)*phi)`, `n` is a dummy.
- RE: `b_CT`, `log_sd_CT`, `re_index` (guarded on `b_CT.size() > 0`); profile
  under RE re-runs the Laplace per grid point; the RE bootstrap redraws `b_g`
  into `fit$obj$env$last.par.best` and recomputes `p` via `obj$report()`, then
  refits with `random = "b_CT"`.
- `R/predict.R::tls_predict_pars()` resolves per-row CTmax/z/low/up/k (shared
  recycled, grouped indexed); `R/profile.R::tls_shape_index()` resolves shape
  coordinates; `tls_resolve_target()` has low/k family branches and routes
  up/up:<g> to the Wald fallback. The deferred-item guards (grouped-shape
  profile, RE/grouped bootstrap) have been REMOVED -- those now work.
- Grouped shapes require all three (`low`/`up`/`log_k`) to share one factor,
  matching the `CTmax`/`log_z` grouping (`R/formula.R`).

## Dataset-search re-dispatch prompt (for item 3)
Use `landscape_scout` (background). "profileTLS fits a 4PL thermal-death-time
model needing per row a temperature, an exposure duration, and survival counts
(survived/total) or a proportion in (0,1). (1) Enumerate every dataset bayesTLS
(github.com/daniel1noble/bayesTLS) ships/analyses with columns, n, license,
citation -- we already vendor shrimp_lethal + zebrafish_lethal. (2) Find
additional openly-licensed (CC0/CC-BY/public-domain) thermal-death-time datasets
(temp x duration x survival-count-or-proportion) on CRAN packages, Dryad/Zenodo/
figshare/OSF, open-access supplements. For each: columns->temp/duration/(counts|
proportion), n, URL, LICENSE (explicit), DOI. ONLY recommend vendoring clearly-
licensed data; mark others DO NOT VENDOR. Rank the best 3-5 vendorable candidates."

## Resume commands
```sh
cd "/Users/z3437171/Dropbox/Github Local/profileTLS"
git log --oneline -12 ; git status --short
R -q -e 'devtools::test(".")'        # expect 389 pass
sed -n '1,200p' docs/dev-log/recovery-checkpoints/2026-06-17-session-end-handoff.md
```

A good first prompt: "Read
`docs/dev-log/recovery-checkpoints/2026-06-17-session-end-handoff.md` and
continue the deferred-item roadmap, starting with item 1 (absolute-target heat
injury)."
