# After Task: a `quiet` switch and sharper random-effects guidance

**Date:** 2026-06-18

**Task:** Replace the scattered `suppressWarnings()` calls (vignettes and tests)
with a first-class `fit_tls(quiet = ...)` argument, after the user noted that
`suppressWarnings` is "a bit annoying" and asked for an argument instead. A
follow-up concern — "some warnings are important for users to see" — fixed the
design: `quiet` must default to OFF (interactive users see every signal) and act
as a deliberate opt-in for simulation loops and clean vignette fits, never a
silent default. Two RE refinements rode along: the few-groups advisory threshold
moved from `< 3` to `< 8` levels, and the Confidence Eye subtitle on an RE fit now
names the drawn interval as Wald.

## Design decision

- **Default `quiet = FALSE`.** Interactive users see all diagnostics. `quiet = TRUE`
  is the analyst's deliberate choice (simulation/batch/clean demos).
- **Defer, don't delete.** `check_tls(fit)` still re-runs the data-adequacy
  diagnostics (`check_tls_data()`), so a quiet fit can always be audited.
- **Targeted, not blunt.** `quiet` gates profileTLS's own advisory `cli_warn`s
  (few-groups, same-grouping) rather than blanket-suppressing every warning, so it
  threads cleanly through the parser.

## Created / Changed

- `R/fit_tls.R` — new `quiet = FALSE` argument (signature + roxygen `@param`);
  passes `quiet` to `tls_parse_formula()`; gates the beta boundary-clamp note and
  wraps `check_tls_data()` via a local `maybe_quiet()` helper.
- `R/formula.R` — `quiet` threaded through `tls_parse_formula()` and
  `tls_extract_re()`; the few-groups (`< 8`) and same-grouping advisories are gated
  on `!isTRUE(quiet)`. Few-groups threshold `< 3` → `< 8` with an enriched message
  pointing to `confint(method = "bootstrap")` / `bayesTLS`.
- `R/plotting.R` — RE-fit Eye subtitle now states the interval is Wald and suggests
  `method = "profile"`.
- `tests/testthat/test-quiet.R` — new: default-warns / `quiet`-silent, the `< 8`
  boundary, and parser-level `tls_parse_formula(quiet = TRUE)`.
- `tests/testthat/test-formula.R` — the four direct `tls_parse_formula()` parse
  tests on 3-level `life_stage` now pass `quiet = TRUE` (they bypass `fit_tls`).
- `vignettes/random-effects.Rmd` — the three RE fit chunks use `quiet = TRUE`
  instead of `suppressWarnings()`, demonstrating the API on the pkgdown page.
- DoD sync: `DESCRIPTION` (0.3.2), `NEWS.md` (0.3.2 section),
  `docs/dev-log/known-limitations.md` (corrected the stale "RE bars deferred to
  v0.2" line; RE intercepts are supported, slopes/correlation/crossed remain out
  of scope).

## Verification

- Touched test files (`quiet`, `formula`, `random-effects*`, `shape-random`):
  160 pass, 0 fail, **0 warn**, 9 skip. The pre-existing WARN-4 (the `life_stage`
  parse tests tripping the new `< 8` threshold) is resolved.
- `document()` regenerated `man/fit_tls.Rd` with the `quiet` param.

## Out of scope / next

- The remaining `suppressWarnings()` in the other vignettes (case studies, etc.)
  are clean-data fits; converting them to `quiet = TRUE` is cosmetic and deferred.
- Next slice: a focused calibration/coverage simulation sweep (profile vs Wald vs
  bootstrap coverage; CTmax/z recovery; RE variance vs n_groups), the headline
  empirical backing for a "send to the bayesTLS team" release.
