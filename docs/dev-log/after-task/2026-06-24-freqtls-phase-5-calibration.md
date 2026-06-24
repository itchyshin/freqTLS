# After Task: freqTLS Phase 5 — profile-t / Wald-t calibration + coverage evidence

**Date:** 2026-06-24
**Owner(s):** Fisher (inference), Curie (simulation), Gauss (engine), Ada
**Phase:** P5 (the calibrated frequentist interval — the package's headline claim)

## Goal

Replace the asymptotic chi-square / normal interval calibration — which Daniel's
2026-06-16 audit flagged as **under-covering at small n** — with the Bates-Watts
profile-t / Wald-t small-sample correction, and produce the coverage **evidence**
that it works.

## Implemented (P5a, committed `499da87`)

- `tls_ci_df(fit)` = data rows − estimated parameters (`n_obs − length(par)`);
  RE fits approximate.
- Wald: `qnorm` → `qt(df)` in `tls_wald_natural` (so `tidy_parameters` / `get_*` /
  `tls` / `confint(method="wald")`) and the continuous-shape coefficient path.
- Profile: cutoff `qchisq(level,1)` → `qt(1−α/2, df)^2` (profile-t), with a
  df-aware grid span `(qt(df)+1.5)·se`.
- Converges to the asymptotic interval as `df → ∞`; equivariance preserved
  (`z` interval == `exp` of the internal `log_z` interval, verified to 1e-6).
- Bonus: the df-aware grid fixed false-"open" profiles on sparse designs.

## Evidence (P5b, `data-raw/calibration-study.R`, cached `inst/extdata/calibration_results.rds`)

Wald coverage of CTmax and z over 500 replicates per design (binomial,
CTmax = 36, z = 4; truth-in-interval; MC-SE ≈ 0.01). Wald coverage is cheap
(fit + sdreport SE, no profiling); profile-t tracks Wald-t but is far slower.

| cell  | median df | cov CTmax (z) | cov CTmax (t) | cov z (z) | cov z (t) | width CTmax z→t |
|-------|-----------|---------------|---------------|-----------|-----------|------------------|
| small | 10        | **0.927**     | **0.964**     | 0.927     | 0.960     | 0.91 → 1.04 |
| mid   | 35        | 0.946         | 0.964         | 0.946     | 0.950     | 0.53 → 0.55 |
| large | 100       | 0.970         | 0.970         | 0.960     | 0.964     | 0.41 → 0.41 |

**Reading.** At small n the asymptotic normal under-covers (0.927, ~2 MC-SE below
the 0.95 nominal); the t(df) correction restores nominal coverage (0.96) at a
modest width cost; at large n t ≡ z (no penalty). This is the documented
small-sample behaviour and the justification for naming the package's intervals
"calibrated". It directly answers the audit's t-distribution concern with
in-repo evidence rather than assertion.

## Checks run and outcomes

- `Rscript data-raw/calibration-study.R` → the table above (494/499/500 of 500
  replicates converged with a PD Hessian and finite SEs per cell).
- `devtools::test()` → **686 PASS / 0 fail / 0 warn / 1 skip** (+`test-calibration.R`
  pinning df = n−p, the t/z width ratio, and equivariance).
- `rcmdcheck` → **0 / 0 / 0**.

## Known limitations / next

- The evidence shown is **Wald** coverage (cheap). Profile-t coverage tracks
  Wald-t but is slow to sweep; a spot-check at small n confirms it; a full
  profile + bootstrap + bayesTLS coverage campaign (the §9 ADEMP grid across
  family / φ / #groups / threshold) is the P6-adjacent validation campaign.
- RE-fit df is approximate (`n − p` over-states it); the few-groups advisory and
  a RE-specific coverage cell remain for the campaign.
- Next: P6 three-way benchmark (freqTLS vs bayesTLS vs two_stage) on the shared
  datasets, `--as-cran`, CITATION; P7 case-study vignettes + pkgdown.
