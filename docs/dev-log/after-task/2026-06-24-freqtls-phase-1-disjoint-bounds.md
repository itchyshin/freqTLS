# After Task: freqTLS Phase 1 — disjoint-bounds asymptotes (engine)

**Date:** 2026-06-24
**Owner(s):** Gauss (TMB), Emmy (plumbing), Fisher (CI), orchestrated by Ada
**Phase:** P1 of the twin build (engine: switch asymptotes nested-gap → disjoint bounds)

## Goal

Replace freqTLS's nested-gap asymptote reparameterisation with bayesTLS's
**disjoint-bounds** scheme (`compute_4pl_bounds`), so the engine matches the twin
spec and `up` becomes a **direct coordinate** (resolving audit E2's structure).
User decision (2026-06-24): match bayesTLS bit-for-bit on the asymptotes.

## Implemented

- **C++ (`src/profile_tls.cpp`):** `beta_gap`→`beta_up`, `X_gap`→`X_up`; added
  `DATA_SCALAR` `low_min/low_w/up_min/up_w`; `low = low_min + low_w·plogis(beta_low)`,
  `up = up_min + up_w·plogis(beta_up)` (independent, no nested gap); per-obs and
  per-column blocks rewritten; `up` sized to `beta_up`.
- **R:** new internal `tls_compute_bounds()` (mirrors bayesTLS `compute_4pl_bounds`,
  pad 0.001 / gap 0.002); wired the 4 bounds scalars into both `tmb_data` sites
  (`fit_tls.R`, `profile.R` contrast refit); `predict.R` rebuilds low/up via the
  disjoint formula; `tls_default_start()` now takes `bounds` and seeds central-ish
  asymptotes (low≈0.05, up≈0.95); contrast-refit start recovers `beta_up` from
  `up` via the disjoint inverse. P1 fixes bounds to `c(0,1)` (the `bounds`
  argument is wired in with the `fit_4pl` facade, P3).
- **Tests:** rewrote the asymptote-transform invariant for disjoint bounds.

## Behaviour contract (intentional change)

No longer byte-identical to profileTLS (disjoint ≠ nested — a deliberate model
change). Forward validation is now **parameter recovery** + **agreement with
bayesTLS**, not the v0.3.3 byte baseline (which served its Phase-0 rename purpose).

## Checks run and outcomes

- Smoke recovery (binomial, seed 1): conv=0, pdHess=TRUE; CTmax 35.93 (truth 36),
  z 4.00 (truth 4), low 0.020, up 0.977, k 4.89; **low < 0.5 < up = TRUE**.
- `devtools::test()` → **573 PASS / 0 fail / 0 warn / 0 skip** (23 files, 112 s).
- `rcmdcheck(--no-manual --no-build-vignettes)` → **0 errors / 0 warnings / 0 notes**.

## Issues found and fixed (during P1)

1. **`low` Wald CI on the wrong scale** — `link_endpoints` back-transformed
   `beta_low` via plain `plogis`, giving the pre-bounds fraction (≈0.038) while the
   estimate is the natural `low` (0.020), so `conf.low > estimate`
   (test-methods.R:78). Fixed: bounds-rescale `beta_low` to
   `low_min + low_w·plogis(·)` in `tls_wald_natural`.
2. **RE-on-log_z non-finite initial value** — the extreme default disjoint start
   (low≈0.011, up≈0.974) made the Laplace inner solve ill-conditioned at
   iteration 0 (NA/NaN gradient). Fixed: central-ish default starts (low≈0.05,
   up≈0.95). Confirmed a milder start converges; recovery unaffected.

## Tests of the tests

The rewritten transform test asserts the disjoint intervals (`low∈[low_min,low_max]`,
`up∈[up_min,up_max]`, `low<up`) — it would fail on the old nested formula, so it
genuinely pins the new reparameterisation.

## Known residuals (→ later phases)

- `up` CI is natural-delta via the ADREPORTed `up` SE; the full coordinate-based
  in-[0,1] guarantee + making `up` profileable (E2 complete) is **P5**.
- Profiling `low`/`up` under **non-default bounds** needs a bounds-aware
  back-transform generalisation (only `beta_low`'s Wald path is rescaled now);
  moot until the `bounds` argument ships (P3).
- The `gap`/`"gap"` name_map sentinel name is now a misnomer (it routes `up` to
  the ADREPORT delta path); rename in P4 when extractors are twinned.

## Next

P2 (copy engine-agnostic bayesTLS modules + the 7 datasets) or P3 (`fit_4pl`
facade with the `bounds`/`threshold` arguments).
