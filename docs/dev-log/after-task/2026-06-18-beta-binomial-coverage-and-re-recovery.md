# After Task: beta-binomial coverage diagnosis + Wald fallback, and RE recovery

**Date:** 2026-06-18

**Task:** Two user-directed threads. (1) Diagnose *why* the beta-binomial profile
CIs under-cover in the performance study, decide whether it is a clamping
artefact, check the bootstrap, and — without distorting the likelihood — make the
default robust. (2) Quantify the random-effect variance recovery that justifies
the new `< ~8`-group advisory.

## Diagnosis (beta-binomial profile under-coverage)

It is **not clamping** (the likelihood floors `1e-12` / `1e-8` never activate at
the relevant `phi`/`p`). The cause is the dispersion `phi` becoming **weakly
identified** as overdispersion weakens (`phi` large → near binomial): `phî` runs
away (median 442, relative SE 3.2 at `phi = 200`), and the profile — which
re-optimises `log_phi` at each grid point (confirmed map-refit in `profile.R`) —
profiles it out to the binomial limit and goes too narrow. Wald propagates the
flat-`phi` uncertainty through the joint Hessian and stays calibrated; the
parametric bootstrap is intermediate. Coverage of `z` (nsim 120):

| phi | rel. SE | profile | Wald | bootstrap |
|----:|--------:|--------:|-----:|----------:|
|   5 |    0.28 |   0.925 | 0.925| 0.925 |
|  50 |    0.66 |   0.924 | 0.941| 0.941 |
| 200 |    3.22 |   0.685 | 0.935| 0.907 |

## The fix (robust routing, no likelihood change)

- **`fit_tls()` advisory** (gated by `quiet`): warns when `phi`'s relative SE
  (≈ SE of `log phi`) exceeds 1, recommending Wald.
- **`confint(method = "profile")` weak-`phi` fallback**: routes `CTmax` / `z` /
  `log_z` to the calibrated Wald interval when `fallback = TRUE` (the default) and
  `phi` is weakly identified, via the existing `general_parm` → Wald path, with a
  note. `fallback = FALSE` keeps the raw profile. No likelihood is altered.
- Shared `tls_phi_rel_se()` helper backs both, so the threshold lives in one place.
- Policy (user decision): **profile stays the default** (now robust); Wald is
  prominently endorsed for routine fixed-effects work in `comparing-to-bayesTLS`.

## RE variance recovery

`sigma_CTmax` is biased low and the fixed-effect `CTmax` interval under-covers with
few groups; both settle by ~14 (nsim 150, true `sigma_CTmax = 1.5`):

| n groups | mean sigma | rel. bias | CTmax coverage |
|---------:|-----------:|----------:|---------------:|
| 3 | 1.04 | −0.30 | 0.73 |
| 5 | 1.20 | −0.20 | 0.85 |
| 8 | 1.35 | −0.10 | 0.89 |
| 14 | 1.43 | −0.05 | 0.93 |
| 30 | 1.45 | −0.04 | 0.92 |

## Created / Changed

- `R/confint.R` — weak-`phi` → Wald fallback in the fixed-effects profile branch;
  new internal `tls_phi_rel_se()`.
- `R/fit_tls.R` — weak-`phi` advisory (refactored onto `tls_phi_rel_se()`).
- `data-raw/beta-binomial-phi-study.R`, `data-raw/re-recovery-study.R` — new
  maintainer studies; caches `inst/extdata/beta_binomial_phi_results.rds`,
  `inst/extdata/re_recovery_results.rds`.
- `vignettes/comparing-to-bayesTLS.Rmd` — "Why the beta-binomial profile can dip"
  section + coverage-vs-`phi` table + Wald endorsement.
- `vignettes/random-effects.Rmd` — RE recovery table + sharper bias prose.
- `tests/testthat/test-beta-binomial-phi.R` (new): advisory fires/silenced,
  `< 8` boundary not relevant here, confint fallback vs `fallback = FALSE`.
- `tests/testthat/test-fit-beta-binomial.R` — collapse test uses `quiet = TRUE`
  (the collapse now correctly trips the advisory, asserted elsewhere).
- DoD: `DESCRIPTION` (0.3.3), `NEWS.md`, `docs/dev-log/known-limitations.md`
  (fixed the stale "coverage not simulated" line + a stray "compatibility";
  added the weak-`phi` caveat).

## Verification

Full suite: **573 pass, 0 fail, 0 error, 0 warn**. Both new vignette chunks
render against the full caches.
