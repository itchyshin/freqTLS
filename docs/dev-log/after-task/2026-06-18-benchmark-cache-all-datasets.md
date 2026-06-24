# After Task: benchmark cache for all four case-study datasets

**Date:** 2026-06-18

**Task:** The D. suzukii and snow-gum PSII case-study articles rendered a "pending
cache" note instead of the bayesTLS / two-stage comparison columns — the whole
point of a case study. Both datasets were vendored on 2026-06-17, *after* the
benchmark cache and `data-raw/build_benchmark_cache.R` were written, and the build
script only ever fitted shrimp + zebrafish. Extend the build to both datasets, run
it here (cmdstanr 2.36 + bayesTLS 1.0.0 are present), and wire the two vignettes.

## Created / Changed

- `data-raw/build_benchmark_cache.R` — refactored from a single global config to a
  per-dataset config list (duration column, native time unit, `tref`, group,
  family, response type, two-stage applicability) driving one unified fit loop.
  Added D. suzukii and snow-gum PSII; shrimp + zebrafish unchanged.
- `inst/extdata/bayesTLS_benchmark_cache.rds` — rebuilt; now keys
  `shrimp`, `zebrafish:<stage>`, `dsuzukii:<sex>`, `snowgum`. `two_stage` covers
  the count datasets only. `meta$datasets` records the per-dataset config.
- `vignettes/case-study-suzukii.Rmd` — added the per-sex three-way table chunk
  (`three-way-suzukii`); replaced the "pending cache" section; reframed the intro.
- `vignettes/case-study-leaf-psii.Rmd` — added the beta two-way table chunk
  (`three-way-psii`); replaced the "pending cache" section; corrected the claim
  that bayesTLS consumes counts (it offers a Beta family).
- DoD sync: `NEWS.md` + `DESCRIPTION` (0.3.1), `docs/dev-log/known-limitations.md`
  (the stale "cache is absent" bullet), `docs/design/06-benchmark-protocol.md`
  (the two new datasets + per-dataset `tref`/units + the relative-threshold lock),
  `docs/design/46-capability-matrix.md`, `docs/dev-log/check-log.md`.

## Checks Performed

- `Rscript data-raw/build_benchmark_cache.R` — 7 bayesTLS fits + 6 two-stage fits,
  all chains finished successfully; wrote the cache.
- Reproduction vs the backed-up cache: shrimp + zebrafish bayesian medians within
  0.006 (bounds within 0.038) — MCMC/draw noise; two-stage rows bit-identical.
- `devtools::load_all()` + the exact vignette chunk code → correct three-way and
  two-way tables; Rmd fences balanced, chunk labels unique.
- `devtools::test()` → `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 560 ]`; `SKIP 0` means
  `test-benchmark-sanity` ran against the rebuilt cache and passed.

## Outcomes

- D. suzukii: full three-way per sex. `profileTLS`/`bayesTLS` agree tightly and
  reproduce the published `CTmax` ≈ 35.2 °C, `z` ≈ 3.0 (F) / 3.2 (M); the classical
  two-stage sits a few tenths lower with wider intervals.
- Snow-gum PSII: honest two-way (`bayesTLS` beta vs `profileTLS`), `CTmax` ≈ 46 °C,
  `z` ≈ 6, overlapping intervals; no classical two-stage (no count form).

## Consistency Review

- `rg -n "pending cache"` across live docs/vignettes: the suzukii/leaf-psii
  vignette notes are replaced; remaining hits are dated dev-log records (after-task,
  recovery-checkpoints, comparator-results) left as historical state, not edited.
- Capability ledger synced in one commit: README needed no change (no stale
  benchmark claim); NEWS / DESCRIPTION / known-limitations / design-06 / design-46
  updated together.

## Tests Of The Tests

- The benchmark-sanity tripwire is a live-vs-cached guard; with the rebuilt cache
  it runs (not skips) and passes within the loose tolerance, confirming the cached
  shrimp/zebrafish medians still match a live profileTLS fit.

## What Did Not Go Smoothly

- The handoff stated cmdstanr was "absent"; that was the overnight sandbox — both
  cmdstanr and bayesTLS are installed on this machine, so the maintainer-run cache
  build was runnable here after all.
- `ts_ci()` labels its field `$CTmax_1hr` regardless of `tref`; the value is at the
  passed `tref` (240 min for suzukii), so the existing extractor reuses unchanged.
- A first-draft vignette line claimed the two-stage "brackets the same estimates";
  the verified table showed the two-stage F CTmax interval [34.56, 35.04] does not
  include 35.2, so the prose was corrected to be honest.

## Team Learning

- Smoke-test new cross-package fit paths at low iter before the full multi-fit run:
  it confirmed the Beta + absolute-threshold calls and revealed the `$CTmax_1hr`
  labelling cheaply.
- profileTLS's `CTmax` is the relative-midpoint parameter by construction, so a
  fair benchmark must read bayesTLS on the relative threshold for every dataset,
  even one (suzukii) whose narrative emphasises absolute LT50 — they coincide for
  near-0/near-1 lethal asymptotes.

## Known Limitations

- Snow-gum PSII has no classical two-stage column (continuous proportion).
- `test-benchmark-sanity` covers only shrimp + zebrafish; extending it to the
  suzukii (tref 240, grouped) and snowgum (beta, tref 5) configs is a follow-up.

## Next Best Task

- Run `R CMD check` (builds all vignettes Stan-free from the cache) as the pre-push
  gate, then push. Resume the parked crossed/correlated RE engine design.
