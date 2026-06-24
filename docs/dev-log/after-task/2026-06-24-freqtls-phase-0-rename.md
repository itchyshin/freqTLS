# After Task: freqTLS Phase 0 — scaffold, rename, baseline (green build, behaviour unchanged)

**Date:** 2026-06-24
**Owner(s):** Grace, Gauss, Emmy (orchestrated by Ada)
**Phase:** 0 of the freqTLS build plan (the true gate — must be green before any behaviour change)

## Task goal

Stand up `freqTLS` as the frequentist sibling of `bayesTLS` by copying `profileTLS`
(v0.3.3 @ `6f963a9`) into the `freqTLS` working dir, renaming the package
end-to-end, and proving the renamed package is **byte-identical in behaviour** to
profileTLS on the relative (default) path — with all checks green — before any of
the four substantive changes (D1–D4) begin.

## What was done

- Captured a **v0.3.3 baseline fixture** (`/tmp/freqtls_baseline_v033.rds`): the
  optimiser objective + full `estimates` table for three deterministic fits
  (binomial, beta-binomial, grouped binomial) from `profileTLS@6f963a9`.
- Cloned `bayesTLS` read-only to `../bayesTLS` (head `422acec`) for the Phase-1
  API-confirmation entry gate and the later live benchmark.
- Copied profileTLS's **tracked tree only** via `git archive HEAD | tar -x`
  (the stale `src/*.o`/`*.so` were correctly excluded).
- Renamed `R/profileTLS-package.R → R/freqTLS-package.R` and
  `vignettes/profileTLS.Rmd → vignettes/freqTLS.Rmd`; bulk `profileTLS→freqTLS`
  across 127 files (excluding regenerated `man/`, historical
  `after-task`/`recovery-checkpoints`, and `NEWS.md`/`COPYRIGHTS` handled
  separately); `PROFILETLS_→FREQTLS_` macro in `src/`.
- Structured edits: `DESCRIPTION` (Title→"Frequentist…", Version→0.1.0, added
  co-authors Noble/Arnold/Pottier, Description reframed around the Wald/profile/
  bootstrap trio); `NEWS.md` reset to a clean 0.1.0 development entry citing the
  fork; `inst/COPYRIGHTS` gained a Provenance section (forked from profileTLS
  `6f963a9`).
- Deleted `man/*.Rd` and regenerated via `devtools::document()`.

## Behaviour contract (verified, not changed)

The relative-path likelihood, MLE, and `estimates` table are **unchanged**. The
threshold/bounds/profile-t work (Phases 1–3) is not yet present; this phase only
re-labels the package and DLL. Verified by byte-match below.

## Checks run and exact outcomes (command text, not summaries)

- Rename consistency: `grep -rn "DLL = " R/` → all three (`fit_engine.R:35`,
  `profile.R:383`, `bootstrap.R:170`) say `"freqTLS"`; `src/init.c` →
  `R_init_freqTLS` + `FREQTLS_RESTORE_HAVE_ENUM_BASE_TYPE`; `NAMESPACE` +
  `R/freqTLS-package.R` → `useDynLib(freqTLS, .registration = TRUE)`.
  `grep -rln "profileTLS" R src tests vignettes data-raw inst _pkgdown.yml README* DESCRIPTION`
  (minus `inst/COPYRIGHTS`) → **none**.
- `devtools::document()` → OK (regenerated `man/` + NAMESPACE).
- `devtools::load_all()` → `freqTLS.so` compiled & loaded, no Apple-clang
  `-Wfixed-enum-extension` warning (Boolean.h guard survived).
- **Baseline byte-match** (`/tmp/phase0_gate.R`): binomial / beta-binomial /
  grouped all `d_objective = 0.000e+00`, `max|Δ estimate| = 0.000e+00`. WORST
  DEVIATION = 0.000e+00 → PASS.
- `devtools::test()` → `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 573 ]` across 23 files,
  105 s.
- `rcmdcheck(args = c("--no-manual","--no-build-vignettes","--no-vignettes"))` →
  **ERRORS=0 WARNINGS=0 NOTES=0**.

## Tests of the tests

The byte-match is a genuine differential test: the same `simulate_tls(seed=)` DGP
+ `fit_tls()` run under profileTLS and under freqTLS must agree to machine zero.
A non-zero deviation would have failed the gate; 0.000e+00 confirms the rename did
not perturb the RNG, the TMB template, or the optimiser path.

## Consistency audit

`grep -rln "profileTLS"` over the package surface returns only the deliberate
`inst/COPYRIGHTS` provenance line. `posterior|credible` sweep deferred to Phase 5
(vignette content) — unchanged from profileTLS here. The C++ `profile_tls.cpp`
filename is intentionally kept (TMB keys the DLL off the package `.so` name, not
the source basename — confirmed by the clean `load_all`).

## GitHub issue maintenance

None (fresh repo; no open issues yet). Working tree is uncommitted on `main` —
not committed per the standing "commit only when asked" rule; this is a clean
checkpoint ready to branch + commit on request.

## Known limitations and next actions

- `@importFrom stats qt` and the profile-t cutoff are **not** added yet (Phase 3,
  by design — behaviour must stay unchanged in Phase 0).
- Vignettes/manual were skipped in the structural check; they are rewritten and
  exercised via `pkgdown::build_site()` in Phase 5.
- **Next:** Phase 1 entry gate — confirm the cloned bayesTLS direct-mode arg API
  against the 2026-06-22 prototype, then build `tls_bf_direct()` +
  `tls_resolve_shape()` (centering via `.temp_c`, `tls_compute_bounds()`).

## Team learning

profileTLS's `NEWS.md` and `inst/COPYRIGHTS` were already authored under the
`freqTLS` name — the rename was partly underway upstream, so those exclusions were
harmless. `git archive` (not `cp -r`) is the right copy mechanism: it excluded the
45 MB stale `.o`/18 MB `.so` automatically.
