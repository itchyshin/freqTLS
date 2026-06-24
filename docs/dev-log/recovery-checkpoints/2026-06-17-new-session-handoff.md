# NEW-SESSION HANDOFF — profileTLS v0.2 (read this first)

**Start with zero context. Trust repo state + this file. The previous session
hit its context limit mid-Beta and reverted the half-done edits to keep the tree
clean.** Read the companion `2026-06-16-overnight-v0.2.md` for the full done-state
detail; this file is the live pickup.

## Repo state (verified)
- Branch `feat/v0.1-core`, PR #1, tip **`ede9dde`**, clean + pushed.
- `devtools::test()` = **309 pass / 0 fail / 0 warn**; `R CMD check
  (_R_CHECK_FORCE_SUGGESTS_=false)` = **0 / 0 / 0**. CI green; the pkgdown site
  auto-deploys to gh-pages on each R-CMD-check success.

## The standing goal
"Finish profileTLS — match and go **beyond** bayesTLS; complementary/pluralistic
framing, no criticism of either; quick + accurate + impressive." **The maintainer
has now approved ALL remaining roadmap items ("do all of these").** Make the
design calls yourself, document them, implement with the discipline below.

## Done in v0.2 (committed `600ba71`..`ede9dde`)
Parametric bootstrap CIs (+ auto-fallback on non-closing/`pdHess=F`, + multicore
`cores`, + Confidence-Eye lens); real bayesTLS head-to-head cache + rebuilt &
deployed comparison page; **random intercept on CTmax** (engine byte-identical for
no-RE; `ranef()`; `sigma_CTmax` Wald interval; README showcase; profiling under RE
verified-but-slow and gated); **`derive_ctmax()`** absolute-threshold critical
temperature.

## NON-NEGOTIABLE discipline
- **Byte-identical gate:** any `src/profile_tls.cpp` change must leave all 309
  existing tests passing with their original values (recompile via
  `pkgload::load_all` then `devtools::test`). Guard new behaviour so existing
  `family_code`/no-RE paths are unchanged.
- Verify every result against the repo (3 confabulated agent runs happened in this
  build); local checks before pushing; `R CMD check` 0/0/0 per slice; commit +
  push each verified slice to `feat/v0.1-core`.
- Complementary framing; compatibility/confidence language (never
  posterior/credible for profileTLS); keep AGENTS/CLAUDE/SPEC off the public site.
- Update docs in the same commit (NEWS, ROADMAP, README, known-limitations,
  capability-matrix `docs/design/46`, the relevant numbered design doc) and add an
  after-task report + check-log entry.

## Suggested order (bank value, isolate the riskiest cpp refactor)
1. **Beta family** (design fully worked out below — start here).
2. **Covariate effects on low/up/log_k** (biggest cpp refactor; needs a
   `docs/dev-log/decisions.md` entry: it relaxes the "midpoint-only" invariant).
3. **T_crit** (R-only derive; verify vs bayesTLS).
4. **Heat-injury / fluctuating-temperature prediction** (R-only; match
   `bayesTLS::predict_heat_injury`, Sharpe-Schoolfield repair).
5. **Ship RE profiling** (it works — `tls_profile_nll_fun` already passes
   `random`; it's ~40 s/CI so it's gated). Make it opt-in/optimised + selective
   routing (profile CTmax/z; Wald for `sigma_CTmax`/bootstrap), keep the eye on
   Wald for RE.
6. **Polish:** capability matrix, vignettes, site redeploy.

## BETA FAMILY — full design (was half-implemented then reverted)
Continuous-proportion responses in (0,1) (snowgum/PSII). `family = "beta"`,
`family_code = 2L`, `phi` = sum of Beta shapes (same convention as beta-binomial).

- **cpp** (`src/profile_tls.cpp`): in the family branch, change `else {betabinom}`
  to `else if (family_code == 1) {betabinom}` and add
  `else { Type a = p*phi; Type b = (1-p)*phi; floor a,b at 1e-8;
  nll -= dbeta(y(i), a, b, true); }`. Change `if (family_code == 1) ADREPORT(phi)`
  to `if (family_code >= 1)`. (Byte-identical for codes 0/1 — verified the edit
  compiles is the only open risk; TMB has `dbeta(x, s1, s2, give_log)`.)
- **families.R**: add `beta_tls()` (`family_code = 2L`, links incl. `phi`); in
  `resolve_tls_family` set `match.arg(family, c("beta_binomial","binomial","beta"))`
  and a `beta = beta_tls()` switch case.
- **GOTCHA THAT BROKE THE TREE LAST TIME:** `fit_tls()`'s
  `family = c("beta_binomial","binomial")` default **must become**
  `c("beta_binomial","binomial","beta")` to match the resolver's `match.arg`
  choices (otherwise `match.arg` errors `'arg' must be of length 1` on the default
  and *every* fit breaks). Do the same for `simulate_tls()`'s family default.
- **fit_tls**: make `n` optional. After `n_q <- enquo(n)`, if
  `rlang::quo_is_missing(n_q)` set `n_v <- NULL`; later, if `is.null(n_v)`: beta ->
  `n_v <- rep(1, n_obs)` (dummy, unused by the beta nll); else abort "`n` (trials)
  is required for the {family} family". Validation branch: beta -> require
  `y in (0,1)`, clamp to `(eps, 1-eps)` with a warning if clamped, SKIP the
  `0<=y<=n` count check; binomial/beta-binomial -> the existing count check.
- **`family_code == 1L` -> `>= 1L`** (beta also has phi) at: `R/utils.R:90`,
  `R/profile.R` (valid-targets phi list ~L232; contrast `log_phi` start ~L764),
  `R/diagnostics.R:188`, `R/fit_tls.R` tls_estimates phi row (~L350) + SE (~L386).
  KEEP `== 0L` (binomial-only `log_phi` map) at `fit_tls` ~L210 and `profile.R`
  ~L779.
- **simulate_tls**: `family = "beta"` -> draw the proportion directly,
  `y <- rbeta(N, p*phi, (1-p)*phi)`; return a `prop` column (+ true `p`) instead
  of `survived`/`total`. (Decide + document the output column name; `prop` is the
  suggestion.) `phi` required for beta.
- **formula interface**: accept a bare-name LHS as a proportion in
  `tls_parse_response` (returns `n = NULL`); fit_tls then supplies the dummy `n`
  for beta. (Or defer with a clear error and ship the column interface first.)
- **tests** `tests/testthat/test-fit-beta.R`: parameter recovery (CTmax/z/phi from
  `simulate_tls(family="beta", phi=...)`); the `y in (0,1)` validation + clamp;
  `n`-optional; confirm the 309 binomial/beta-binomial tests are unchanged.
- **docs**: `docs/design/02-family-registry.md`, the `family_code` roxygen
  ("0/1/2"), capability matrix, NEWS, README.

## Resume commands
```sh
cd "/Users/z3437171/Dropbox/Github Local/profileTLS"
git log --oneline -10 ; git status --short
R -q -e 'pkgload::load_all("."); devtools::test(".")'   # expect 309 pass
sed -n '1,140p' docs/dev-log/recovery-checkpoints/2026-06-17-new-session-handoff.md
sed -n '1,200p' docs/dev-log/recovery-checkpoints/2026-06-16-overnight-v0.2.md
```
