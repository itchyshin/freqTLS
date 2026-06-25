# After Task: freqTLS audit remediation (vs bayesTLS) + Florence/Darwin audits

Date: 2026-06-25
Branch: build/freqtls → main (fast-forwarded, pushed)
Commits: `2356661` (CRITICAL), `097011a` (MAJOR), `7feb331` (figures + MINOR)

## Goal

Fix every finding from the freqTLS documentation audit (freqTLS is the subject;
bayesTLS is only the comparison yardstick), then run the Florence figure audit
"with others if necessary", and redeploy the live pkgdown site so it reflects the
corrected docs.

## Setup

- Local R/TMB toolchain is broken (TMB/Matrix ABI mismatch → `library(TMB)`
  segfaults), so all work was **text-only edits verified against the source**, not
  by running R. roxygen changes were hand-synced into the matching `man/*.Rd`
  because `document()` cannot run locally and the pkgdown workflow builds from the
  committed man pages (`build_site(devel = FALSE)`).
- Read-only review agents dispatched this session: **Florence** (figure_reviewer)
  and **Darwin** (audience_reviewer). The earlier 6-agent audit supplied the
  CRITICAL/MAJOR/MINOR list.

## Result

CRITICAL (`2356661`):
- Profile-t / Wald-t calibration: docs said χ²₁ cutoff + `z·se`; code uses
  `qt(1−α/2, df=n−p)²` and `qt(df)`. Corrected across profile-likelihood.Rmd,
  freqTLS.Rmd, design/04, SPEC §10, R/profile.R, R/confint.R + man pages.
- Disjoint-bounds asymptotes: docs said nested-gap (`up = low+(1-low)·plogis`);
  P1 switched to disjoint bounds (`up = up_min+up_w·plogis(beta_up)`,
  `compute_4pl_bounds`). Corrected the formula AND the reason `up` uses Wald/delta
  (it has coordinate `beta_up` but is not yet profiled, and has no RE term) across
  model-math.Rmd, design/01/02/03/04/08/46/90, SPEC, R/{formula,profile,extract,
  utils,fit_tls,simulate}.R, src/profile_tls.cpp, man pages; added a superseding
  decisions.md entry; design/90 + SPEC §5 marked RESOLVED (adopted). Start values
  corrected to low~0.05 / up~0.95 onto the half-bands.
- Invariants: `format_interval` "posterior median/credible interval" → confidence;
  data.R zebrafish_o2 / aphid_tdt "full posterior uncertainty" → profile-likelihood
  confidence (+ man).
- Metadata: ROADMAP 0.3.0 → 0.1.0; `dsuzukii_lethal` → `dsuzukii` (per-individual,
  1407 rows) in CITATION, design/06, known-limitations, build_benchmark_cache.R
  (+ cell aggregation, flagged untested); R-SHRIMP prose (vendored proportion
  rebuilt at standardize_data time, not baked counts); dead
  `vignette("getting-started")` → `vignette("freqTLS")`.

MAJOR (`097011a`):
- README "change only the package" softened with the documented exceptions
  (no fit-time absolute threshold / non-default bounds; bootstrap not posterior;
  constant-shape default) → comparing-to-bayesTLS.
- t_ref (fit_4pl, default 60) vs tref (fit_tls engine, default 1) reconciled.
- frequentist-and-bayesian calibration table relabelled Wald z-ref / t-ref (it
  measures the Wald interval per calibration-study.R), with a note that the
  default profile interval inherits the same t² calibration.
- comparing-to-bayesTLS: explain the `freq_tls` wrapper; use the workflow object
  consistently (S3 methods delegate to `$fit`).
- Biology (Darwin): OCLTT framed as contested; leaf-PSII CTmax flagged sublethal;
  shrimp z plain-English; suzukii absolute-vs-relative caveat moved forward;
  aphid focal-age motivated; summary zebrafish_lethal-vs-zebrafish_o2 split flagged.
  **Corrected a z-direction error** the prior audit and Darwin both missed: a
  LARGER z is a MORE GRADUAL temperature dependence (TDT slope = 1/z), not steeper
  — fixed in summary/suzukii/shrimp.
- Governance: design/00-vision moved shipped features (Beta, heat-injury, RE,
  formula DSL, bootstrap) out of "non-goals"; ROADMAP/known-limitations vignette
  lists and phase framing updated; sim dev-log "narrower" scoped to the simulation.

Figures + MINOR (`7feb331`, Florence audit):
- C-2 non-closing eye uses `fallback = FALSE` (hollow point, no lens — matches the
  contract); C-3/M-1 heat-injury three-panel chunk split into three with correct
  per-panel alt-text (crossing fixed to "near day three"); M-2 cross-taxon panel
  widened + x-expanded so annotations/title are not clipped; M-3 "filled" → "closed
  lens"; m-1 dead fig.alt removed; m-2 facet label.
- `phi` and `log_z` defined at first use; heat-injury moved to its own
  "Applications" navbar group; leaf-PSII "coincide" clarified.
- C-1 (live site still showing pre-fix text) resolved by the redeploy below.

Confidence-Eye contract: Florence confirmed the geometry code passes (pale fill,
hollow point, non-closing fallback, language lock). Cross-taxon panel handles the
non-common-time-scale honestly.

Push + deploy: `main` fast-forwarded `0be4287..7feb331` and pushed; pkgdown
redeployed via `gh workflow run pkgdown.yaml --ref main` (run 28190240280).

## Checks run

- Comprehensive `grep` sweeps (the only verification possible without R): stale
  `dsuzukii_lethal`, `getting-started`, χ²/`qchisq` cutoff claims, `nested-gap` /
  `beta_gap`, `posterior`/`credible` misuse for freqTLS intervals, version 0.3.0 —
  all return only legitimate (rationale / historical / contrast) hits.
- man/*.Rd hand-synced for every changed exported-function roxygen (verified
  `@noRd` helpers correctly have no man page).
- pkgdown redeploy on the ubuntu GHA (TMB compiles there).

## Known limitations / next

- **Deferred (task chips spawned):** (1) add `fig.alt` to the pkgdown reference
  EXAMPLE figures (M-4 — needs roxygen `@examples` edits + `document()` +
  pkgdown-version-specific mechanism); (2) a doc-vs-data tripwire test (the META
  finding) asserting each dataset's name/row-count/columns match R/data.R.
- **Needs a working R:** run `devtools::document()` once to confirm the hand-synced
  man pages match roxygen exactly, and `devtools::check()` / `test()` for a full
  pass. `data-raw/build_benchmark_cache.R` dsuzukii aggregation is untested locally.
- **Verify after deploy:** confirm the live site shows "profile-t" (not
  "chi-square") in the profile-likelihood article and the reference figure caption.
