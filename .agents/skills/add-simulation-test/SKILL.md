---
name: add-simulation-test
description: Add simulation-based parameter-recovery tests for freqTLS models.
---

# Add a Simulation Test

Use this skill when testing the 4PL likelihood, the links, the profile
machinery, and the fitting workflow. Curie leads.

## Procedure

1. Simulate data from known parameters with `simulate_tls()` (factorial
   temperature x duration grid; locked data-generating process; fixed seed).
2. Fit the intended model with `fit_tls()`.
3. Check convergence diagnostics (`convergence$code == 0`, `pdHess`).
4. Check estimates on the natural scale: `CTmax`, `z`, `low`, `up`, `k`, and
   (for beta-binomial) `phi`.
5. Check profile behaviour where relevant: `|D(MLE)|` near zero, a finite closed
   CI for an interior MLE, and equivariance `ci_z == exp(ci_log_z)` to about
   1e-6.
6. Test edge cases that are scientifically likely and numerically risky.

## CRAN-Safe Tests

Keep CRAN tests small and deterministic. Use fixed seeds and moderate
tolerances. Put long simulation studies in `data-raw/` or an optional workflow,
not in routine package checks.

## Required Edge Cases

- Too few temperatures (< 3) or durations (< 3, overall and per temperature).
- No mortality and all mortality.
- A threshold never crossed; an asymptote not approached.
- `phi` near the binomial limit; near-binomial data fit by beta-binomial.
- A sparse design where the profile does not close (expect a warning and an `NA`
  endpoint, not a crash).
- Grouped designs with shared shape: `CTmax:grp` and `z:grp` finite profiles.

## phi Convention (R-PHI)

`phi` is the sum of the Beta shape parameters: counts are beta-binomial with
`a = p * phi`, `b = (1 - p) * phi`. Larger `phi` means less overdispersion.
Tests and docs must use this single definition.
