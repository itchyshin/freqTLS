# Recovery checkpoint — autonomous run handoff (2026-06-16)

**Context.** Shinichi was away ~3 hours with the standing goal "finish the package."
This checkpoint records everything done autonomously so work can resume from repo state,
not chat memory. Trust `git`, the tests, and `R CMD check` over this prose.

## Goal status (the four requested items, in order)

1. **Commit + PR — DONE.** Branch `feat/v0.1-core`, PR **#1**
   (https://github.com/itchyshin/profileTLS/pull/1), 5 commits off `main` (still at the
   initial commit). Opened, **not merged** — merge is the maintainer's call.
2. **Benchmark cache (Stan) — DEFERRED to your machine.** Installing/executing
   Stan + bayesTLS was blocked by the sandbox security policy (untrusted external code).
   `data-raw/build_benchmark_cache.R` is ready and guarded; run it where `cmdstanr` +
   `bayesTLS` are available to populate `inst/extdata/bayesTLS_benchmark_cache.rds`. The
   comparison vignette + `test-benchmark-sanity` are cache-guarded (skip until present).
3. **Upstream R-SHRIMP report — STAGED, NOT SENT.** Finalized text:
   `docs/dev-log/comparator-results/2026-06-16-bayesTLS-upstream-ISSUE-BODY.md`
   (send-ready) and `...-upstream-report.md` (full draft + internal notes). Not posted —
   it is an outward, irreversible post under your identity to a colleague's repo, and the
   report itself advises confirming with the co-authors first. One-click send when ready:
   ```sh
   gh issue create --repo daniel1noble/bayesTLS \
     --title "shrimp_lethal death counts look truncated: Mortality_after_trial is a proportion, but as.integer() floors it to 0/1" \
     --body-file docs/dev-log/comparator-results/2026-06-16-bayesTLS-upstream-ISSUE-BODY.md
   ```
4. **Coverage simulation — DONE; site builds.** `data-raw/coverage-study.R` +
   `inst/extdata/coverage_results.rds`; a calibration section added to the
   profile-likelihood vignette.

## Verified (live, this session)

- `R CMD check` (with `_R_CHECK_FORCE_SUGGESTS_=false`): **0 errors / 0 warnings / 0 notes**.
- **201 tests pass + 1 skip** (the Stan-only benchmark-sanity test).
- Engine recovery: binomial CTmax 35.93 / z 4.00; beta-binomial 35.90 / 4.06; grouped
  CTmax:A 34.0 / B 37.9, z:A 2.9 / B 5.0.
- Profile likelihood: exact equivariance (`ci_z == exp(ci_log_z)`, maxabsdiff 0);
  deviance 0 at MLE; non-closing → `NA` + `conf.status`, never fabricated.
- **R-SHRIMP** corrected: shipped deaths `{0,1}` (sum 35) → reconstructed 0–11 (sum 738);
  shrimp fit CTmax 31.77 / z 2.19 on the corrected data.
- **Coverage of 95% profile CIs** (nsim = 200, nominal 0.95):
  - binomial: CTmax **0.945**, z **0.970**, 0 open — well calibrated.
  - beta-binomial: CTmax **0.840**, z **0.865**, 6.5% open — **finite-sample
    under-coverage** (the extra dispersion parameter makes LR intervals optimistic).
    Reported honestly in the vignette; for coverage-critical work, bootstrap-calibrate or
    use bayesTLS.

## Git state

- Branch: `feat/v0.1-core` (tracking `origin/feat/v0.1-core`); PR #1 → `main`.
- Commits: scaffold/governance → engine/inference → data (R-SHRIMP) → vignettes →
  coverage+staged-issue → (this handoff). No compiled artifacts tracked.
- Nothing merged; `main` untouched.

## CI note

`.github/workflows/R-CMD-check.yaml` was patched: `_R_CHECK_FORCE_SUGGESTS_: false` +
hard-deps-plus-explicit-extras, so CI never installs the GitHub-only/Stan-heavy `bayesTLS`
or `cmdstanr`. CI hasn't run yet (it triggers on PR; PR #1 should kick it).

## Open / next steps (for your return)

1. Review & **merge PR #1** (or request changes).
2. **Email Noble / Arnold / Pottier** to confirm co-authorship before any release
   (they are listed as `aut` in DESCRIPTION). Then send the R-SHRIMP issue (command above).
3. On a Stan machine: `Rscript data-raw/build_benchmark_cache.R` → commit the cache →
   the comparison vignette's three-way table + posterior-vs-eye figure populate.
4. Optional follow-ups (non-blocking): expand coverage study (more nsim / sparser designs);
   parametric-bootstrap CIs for beta-binomial; pkgdown cosmetic — root governance `.md`
   (AGENTS/CLAUDE/SPEC/ROADMAP) render as site pages (harmless).

## Risks / honesty

- Coverage characterized only at one truth/sample size; not a full study.
- bayesTLS comparison numbers are not yet real (cache pending) — the vignette is a recipe
  + cache-guarded placeholder, never fabricated.
- Co-authorship is asserted but not yet confirmed with the named authors.

## Resume commands

```sh
cd "/Users/z3437171/Dropbox/Github Local/profileTLS"
git status --short --branch
git log --oneline -8
gh pr view 1 --web
R -q -e 'devtools::test(".")'
R -q -e 'readRDS("inst/extdata/coverage_results.rds")$coverage'
```
