# NEW-SESSION HANDOFF — profileTLS v0.2.0 (read this first)

Start with zero context; trust repo state + this file. The previous session
shipped the remaining v0.2 roadmap (items 1-4), the bayesTLS-parity case-study
articles, the `dsuzukii_lethal` dataset, the 0.2.0 release bump, and a live site
refresh. This file is the live pickup. Read `AGENTS.md` + `SPEC.md` before any
implementation slice; before editing, run `git status --short --branch`,
`git diff --stat`, `git diff`, then the newest check-log + after-task reports.

## Repo state (verified)
- Branch `feat/v0.1-core`, PR #1, tip **`d95f1cf`**, clean + pushed. **Version
  0.2.0** (DESCRIPTION / NEWS / ROADMAP / CITATION). CRAN is **descoped** (the
  maintainer said no CRAN; experimental lifecycle).
- `devtools::test()` = **431 pass / 0 fail / 0 warn / 0 skip** (112 `test_that`).
- `rcmdcheck(args="--no-manual", build_args="--no-manual",
  env=c("_R_CHECK_FORCE_SUGGESTS_"="false"), error_on="never")` = **0/0/0** (all 9
  vignettes build Stan-free). `pkgdown::check_pkgdown()` = clean.
- Live site: deployed to gh-pages (`c7a5cb7..f330d5b` mid-session). A **second
  redeploy was launched at session end** (`/tmp/ptls_deploy2.log`, pid 46965) to
  add the 3 dedicated case studies — **VERIFY it pushed** (`git log origin/gh-pages
  -1`); if not, run `R -e 'pkgdown::deploy_to_branch(new_process = FALSE)'`.

## Shipped this session (commits `3ec168b`..`d95f1cf`)
- **Item 1** `3ec168b`: absolute-target heat injury (`predict_heat_injury(...,
  target_surv=)`; `q/k` shift; `NULL` = relative default, byte-identical).
- **Bug fix** `4264609`: formula-grouped fits now carry `diag_data$group` (fixed
  `plot_survival_curves` on formula-grouped fits; partial-match `$`->`[[` lesson).
- **Item 2** `d8446dc`: flagship grouped-shape README example.
- **Item 3** `b146995`+`3681d5e`: v0.2 reanalysis vignette section + vendored
  `snowgum_psii` (beta family, CC BY 4.0).
- **Item 4** `4987423`(engine, byte-identical)+`38ae749`: general continuous
  covariates on shapes. Each shape (low/up/log_k) carries its OWN design
  independently; per-shape engine `shared` detection; general coefficients
  reported LINK-scale (`k:body_size` is a log slope) with Wald from the sdreport
  FIXED block; predict rebuilds the shape design from newdata; profile for a
  continuous slope routes to Wald. Constraint relaxed (`docs/dev-log/decisions.md`
  2026-06-17). **This item was crashed + reverted once mid-attempt** before the
  clean re-do — verify byte-identical via a git-stash baseline if you touch the
  engine again.
- **Articles** `4be7366`+`d95f1cf`: 6 case-study pkgdown articles mirroring the
  bayesTLS supplement + exceeding it (Confidence Eyes, profile intervals,
  frequentist contrasts; never "posterior" for profileTLS): `case-study-shrimp`
  (full three-way, profileTLS ~ bayesTLS ~ two-stage), `case-study-zebrafish`
  (per-stage + the stage-shape AIC showcase), `case-study-leaf-psii` (beta
  family), `case-study-suzukii` (recovers Ørsted 2024), `heat-injury` (trace +
  bootstrap envelope), `case-study-summary` (cross-case Confidence-Eye panel).
  Vendored `dsuzukii_lethal` (CC BY 4.0, Zenodo 10602268). The supplement
  blueprint is `docs/dev-log/comparator-results/2026-06-17-bayesTLS-supplement-coverage-map.md`.
- **0.2.0** `d4ee0c9`.

## Remaining work (prioritized)
1. **Item 5 — random effects beyond a single `CTmax` intercept.** The big one,
   untouched: RE on `z`/shapes, a second/crossed RE term, nested factors. Engine
   (cpp `b_CT`/`log_sd_CT`/`re_index` is the template; design doc `08`) + formula
   (`tls_extract_ct_re`) + downstream. **Byte-identical gate applies** (the no-RE
   path must stay bit-identical). Best done fresh with full context. Start by
   reading `docs/design/08-random-effects.md` + `src/profile_tls.cpp` lines 44-60,
   92-110, 156-188.
2. **Zebrafish three-way fallback** (small): `case-study-zebrafish.Rmd`'s three-way
   table falls back to profileTLS-only because its cache lookup misses the
   zebrafish entries — the cache (`inst/extdata/bayesTLS_benchmark_cache.rds`) DOES
   hold zebrafish per-stage bayesTLS medians (only `case-study-shrimp` renders the
   full three-way). Fix the lookup so zebrafish shows both models too.
3. **Stan cache for snowgum + dsuzukii** (maintainer-run, needs cmdstanr): re-run
   `data-raw/build_benchmark_cache.R` adding snowgum (Beta, relative, tref=5 min)
   and dsuzukii (beta_binomial, **absolute**, tref=240 min, grouped by sex). Then
   the leaf-psii + suzukii articles' "pending cache" notes become full three-ways.
   No Stan available in the dev env.
4. **`plot_heat_injury()` export** (small): `heat-injury.Rmd` uses
   `profileTLS:::tls_bootstrap_replicates` (a `:::` into the package; R CMD check
   is clean but it is fragile). Candidate to promote a heat-injury plot +/or the
   bootstrap-replicates helper to a real export with a test.

## NON-NEGOTIABLE discipline
- **Byte-identical gate** on any `src/profile_tls.cpp` change: existing 431 tests
  pass with original values. The per-shape `low_shared`/`gap_shared`/`logk_shared`
  detection + the size-1 scalar fast-path are the levers; verify bit-identical
  (`max|diff| == 0`) via a git-stash HEAD baseline (capture par + estimates +
  profile CIs for binomial / grouped-shape / beta-binomial fits, recompile, diff).
- **TDD** (failing test first). **Commit + push each verified slice** to
  `feat/v0.1-core`. **Docs in the same commit**: NEWS, ROADMAP, known-limitations,
  `docs/design/46-capability-matrix.md`, the numbered design doc, + an after-task
  report + a check-log entry.
- **R CMD check** (`_R_CHECK_FORCE_SUGGESTS_=false`) 0/0/0 + `check_pkgdown()`
  clean per slice before push.
- **Compatibility/confidence** language for profileTLS — NEVER posterior/credible.
  Confidence Eye contract: hollow point + open lens on a non-closing profile,
  never a fabricated closed eye. Complementary (not competitive) bayesTLS framing.

## Lessons / gotchas from this session
- **Subagents stall on complex three-way cache logic** but succeed fast when told
  to COPY the working chunks verbatim from `comparing-to-bayesTLS.Rmd` (the first
  3 case-study agents stalled 30+ min writing nothing; the re-dispatch with
  "copy the working code" specs finished each in ~2-6 min). Don't let an agent
  reinvent cache plumbing.
- **Subagents can't be stopped** via TaskStop (that's for background Bash). If an
  Agent hangs, take over its remaining files yourself (verify the partial work,
  then finish). VendorSuzukii wrote the dsuzukii data + roxygen + CITATION but
  stalled before `document()`/tests — those were finished by hand.
- **Vignettes must use `data(<dataset>)`, not `load("../data/...")`** — source-tree
  paths fail in R CMD check / build_site (the dsuzukii articles had to be fixed).
- **A standalone `rmarkdown::render` uses the INSTALLED package**, not the dev
  source — `R CMD INSTALL .` first (or rely on R CMD check, which reinstalls), or
  a grouped-shape / new-data chunk fails against a stale install.
- **A mid-session crash reverted item-4 WIP to a broken state**; the repo is
  authoritative — on a crash, `git diff`, run the suite, and revert broken
  uncommitted work rather than trust it (the build had earlier confabulated agent
  runs; verify everything).

## Resume commands
```sh
cd "/Users/z3437171/Dropbox/Github Local/profileTLS"
git log --oneline -14 ; git status --short --branch
R -q -e 'devtools::test(".")'        # expect 431 pass
git log origin/gh-pages -1           # confirm the site redeploy landed
sed -n '1,200p' docs/dev-log/recovery-checkpoints/2026-06-17-session-end-handoff-v0.2.0.md
```
A good first prompt: "Read the newest recovery-checkpoint handoff and start item 5
(random effects beyond a single CTmax intercept), or fix the zebrafish three-way
table — your call which first."
