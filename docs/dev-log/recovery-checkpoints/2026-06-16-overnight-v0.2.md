# OVERNIGHT HANDOVER — profileTLS v0.2 (read this first)

**Autonomous overnight session. Trust repo state + this file over chat memory.**
All work is committed and pushed to `feat/v0.1-core` (PR #1). Everything below was
verified against the repo (tests + `R CMD check`), not taken on an agent's word.

## What landed tonight (all on `feat/v0.1-core`, pushed)

| Commit | What |
| --- | --- |
| `600ba71` | Parametric bootstrap CIs + real bayesTLS head-to-head cache + rebuilt comparison page |
| `fbc870d` | Multicore bootstrap (`cores`, forked refits, reproducible) |
| `3e905cc` | **RE-1 Phase 1**: random intercept on `CTmax` (TMB Laplace), no-RE byte-identical |
| `e01ff1e` | **RE-1 Phase 2**: `ranef()` BLUPs + `sigma_CTmax` Wald interval |
| `951e7e0` | README flagship random-effects example |

(Earlier in the session, before this run: the real cache, the comparison page, and
the gh-pages deploy were already done and verified — see the session-3 handover.)

### Headline results
- **profileTLS ML ≈ bayesTLS posterior** on the shared data (shrimp CTmax
  31.77 [31.63, 31.92] vs 31.72 [31.60, 31.86]; z intervals nearly identical),
  computed in milliseconds with no Stan. This is the comparison page.
- **Bootstrap** gives a prior-free interval *and* an automatic fallback when a
  profile does not close or `pdHess = FALSE`, so profileTLS always returns an
  interval (parity with bayesTLS). Exactly equivariant; multicore; Confidence-Eye
  rendered.
- **Random intercept on `CTmax`** (`CTmax ~ <fixed> + (1 | group)`) fits by
  Laplace; `sigma_CTmax` recovers the truth (e.g. 1.48 [1.03, 2.12] for true 1.5);
  `ranef()` returns BLUPs. **The no-RE path is byte-identical** (the gate held
  through the cpp recompile — all pre-RE tests pass with their original values).

## Verification (exact)
- `devtools::test()`: **295 pass / 0 fail / 0 warn** (was 217 at the start of the
  session; +78 across bootstrap, multicore, RE).
- `R CMD check (_R_CHECK_FORCE_SUGGESTS_=false)`: **0 / 0 / 0** at every commit.
- RE recovery (8 sims, 30 groups, true re_sd 1.5): CTmax/z unbiased; sigma mean
  1.277 (the expected ML downward bias, documented).

## Two real bugs found and fixed (the "verify everything" discipline paid off)
1. `data-raw/build_benchmark_cache.R` `summarise_tdt`/`pull_ci` guessed the wrong
   bayesTLS 1.0.0 output schemas and would have written **all-NA** rows. Fixed
   against the real API (`get_ctmax_summary`/`get_z_summary`; `ts_ci` delta is a
   named list).
2. The perf study's beta-binomial "harder" accuracy row was wrecked by boundary
   "convergences"; tightened the validity filter (`code 0 + pdHess + plausible
   CTmax`). Profile coverage `0.000` in the shipped rds was a dead artifact (now
   0.947/0.953).

## Where the engine RE design lives
`src/profile_tls.cpp`: `re_index`, `b_CT`, `log_sd_CT`; every RE term guarded on
`b_CT.size() > 0` (the byte-identical lever). `R/formula.R::tls_extract_ct_re()`
parses one `(1 | group)` on CTmax. `fit_tls` wires `random = "b_CT"`. Full design:
`docs/design/08-random-effects.md`.

## IMMEDIATE next steps (in order)
1. **RE Phase 2 finish**: profile-likelihood `confint` under the RE. The inner
   refit in `tls_profile_nll_fun` already passes `random = inputs$random`, so it
   re-runs the Laplace at each profile point — and this is **verified to work**:
   on a 20-group fit the profile CTmax/z intervals match Wald (CTmax profile
   [35.84, 37.51] vs Wald [35.88, 37.47]) and cover the truth. **But it is slow
   (~40 s per CI: 25 nested Laplace fits)**, so it stays gated (RE -> Wald) to
   keep `confint()` / `plot_confidence_eye()` fast. To ship: (a) selective routing
   (profile for CTmax/z; Wald for `sigma_CTmax` until a `log_sd_CT` profile target
   exists; Wald for `method = "bootstrap"`); (b) keep the eye on Wald for RE
   (speed); (c) optimise the inner Laplace (warm-start / fewer points) or make it
   explicit opt-in; (d) `skip_on_cran` tests with a tiny config. For
   well-identified RE fixed effects profile ~ Wald, so the Wald default is a sound
   interval in the meantime. `profile()` / bootstrap on an RE fit currently error
   clearly.
2. **RE-aware parametric bootstrap**: redraw `b_g ~ N(0, sigma_hat)` per replicate
   and refit with `random = "b_CT"` (re-pin `obj$fn(opt$par)` before `report()`
   for the RE refit). Gives a prior-free CI for `sigma_CTmax`.

## DECISIONS NEEDED FROM YOU (I did not do these unsupervised)
- **Covariate effects on `low`/`up`/`log_k`** (roadmap item 2) would break the
  stated invariant "temperature effect through the midpoint only (shared low, up,
  k)" (AGENTS.md / `docs/design/01`). AGENTS.md says don't change it without a
  `docs/dev-log/decisions.md` entry. **Add the decision, then I'll implement.**
- **Beta (continuous-proportion) family** (roadmap item 3) changes the response
  contract: `y` becomes a proportion in (0,1) with no trials `n`. Needs an API
  decision (optional `n`? a `proportion` argument? validation branch). Then it's
  a clean `family_code = 2` (`dbeta(y, p*phi, (1-p)*phi)`) + simulate + tests.
- **`T_crit` (rate-multiplier lethal quantity)** is the remaining piece of
  bayesTLS `extract_tdt`'s absolute family. The absolute-threshold critical
  temperature is **done** (`derive_ctmax()`, closed-form, round-trip verified);
  `T_crit` needs a quick confirmation of the rate-multiplier definition (it is a
  lethal-endpoint-only concept in bayesTLS) before implementing.
- **Heat-injury / fluctuating-temperature prediction** (item 5) is the big one;
  deterministic prediction from the fitted curve + a temperature trace.

## Carry-over discipline
Complementary/pluralistic framing, no criticism of either package; flagship
examples use random effects; Nakagawa sole author, bayesTLS authors acknowledged;
internal docs (AGENTS/CLAUDE/SPEC) stay off the public site (`tools/build-site.R`
strips them); verify every claim against the repo; the **no-RE byte-identical
gate** is the hard rule for any further cpp change. Local checks before pushing.

## Resume commands
```sh
cd "/Users/z3437171/Dropbox/Github Local/profileTLS"
git log --oneline -8 ; git status --short
R -q -e 'devtools::test(".")'        # expect 295 pass
R -q -e 'pkgload::load_all("."); print(ranef(fit_tls(tls_bf(survived|trials(total)~time(duration)+temp(temp), CTmax~1+(1|colony)), data=simulate_tls(re_sd=1.5,n_re_groups=12,seed=42,family="binomial"), family="binomial", tref=1)))'
```
