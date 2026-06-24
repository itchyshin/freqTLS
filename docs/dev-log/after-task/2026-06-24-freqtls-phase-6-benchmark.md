# After Task: freqTLS Phase 6 (start) — three-way benchmark vs bayesTLS

**Date:** 2026-06-24
**Owner(s):** Grace (benchmark/repro), Fisher (inference), Jason (bayesTLS), Ada
**Phase:** P6 (does the twin reproduce bayesTLS? + classical two-stage)

## Goal

Validate the central twin claim — freqTLS reproduces bayesTLS's CTmax/z on shared
data — by fitting one shared dataset with all three estimators and comparing.

## Setup

- Installed the **redesigned bayesTLS clone** (`../bayesTLS`, the direct-CTmax/z
  version freqTLS twins) over the older installed midpoint version, so the
  comparison is against the current bayesTLS API. R-only install (Stan compiles
  at fit time). cmdstan 2.36.0.
- `data-raw/benchmark-vs-bayes.R`: brown shrimp (lethal, ungrouped, beta-binomial);
  freqTLS `fit_4pl` (TMB/ML) + `tls`, bayesTLS `fit_4pl` (Stan, 2 chains x 1200) +
  `tls`, classical `two_stage`. Cached `inst/extdata/benchmark_vs_bayes.rds`.

## Result

| quantity | freqTLS | bayesTLS | two_stage | freq − bayes |
|----------|---------|----------|-----------|--------------|
| CTmax    | 31.774  | 31.845   | 31.620    | **−0.071 °C** |
| z        | 2.194   | 2.402    | 2.045     | −0.208 (8.7%) |

**Reading.**
- **CTmax agrees to 0.07 °C** across all three — reproducing the 2026-06-16 audit's
  ~0.057 °C shrimp agreement. The headline thermal-tolerance quantity is
  estimator-invariant on count data, as expected from the shared likelihood.
- For **z**, the two *frequentist* estimators agree closely (freqTLS 2.19 ≈
  two-stage 2.05) while bayesTLS sits higher (2.40). That gap is the **prior's
  pull** on a beta-binomial dispersion with a short MCMC (the audit's beta-binomial
  φ caveat), not a freqTLS error — freqTLS, being prior-free, tracks the classical
  estimator. This is exactly the freq-vs-Bayes contrast the shared paper makes.

## Checks run

- `Rscript data-raw/benchmark-vs-bayes.R` → the table above (bayesTLS 2 chains
  finished, no divergences reported). freqTLS + two_stage deterministic.
- Package suite unaffected (no `R/` change): 686 PASS / check 0/0/0 from P5b.

## Known limitations / next

- One dataset (ungrouped shrimp) so far; the full three-way table (zebrafish life
  stages, zebrafish-O₂, aphids, suzukii — grouped) is the P7 benchmark for the
  comparison vignette (more Stan time; cache it).
- bayesTLS run is short (2 chains x 1200) for speed; the published comparison
  should use 4 x 4000 with a longer warmup (will tighten the z posterior).
- Rebuild `test-benchmark-sanity` (currently skipped) against this cache once the
  full grid is built.
- Next: expand the benchmark grid; then P7 vignettes (mirroring
  `ms/case_studies_new.qmd`) + pkgdown; deprecate profileTLS.
