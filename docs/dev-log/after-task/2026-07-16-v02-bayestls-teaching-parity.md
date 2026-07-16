# After Task: Rebase experimental v0.2 on the bayesTLS teaching template

## 1. Goal

Make the active freqTLS empirical teaching sequence match the bayesTLS
supplement rendered 2026-07-14 at commit `76510412`, as closely as the
frequentist engine permits. Preserve freqTLS-specific likelihood, profile,
bootstrap, diagnostic, Confidence-Eye, formula, limited-random-effect, Beta,
and deterministic heat-injury capabilities without substituting unrelated
empirical examples.

## 2. Implemented

- Bumped the development version to `0.2.0.9000` and reconciled AGENTS, SPEC,
  README, NEWS, ROADMAP, limitations, capability matrix, benchmark protocol,
  API crosswalk, and parity ledger around the experimental v0.2 contract.
- Added one site-wide risk banner and independent warnings in the README,
  package help, `fit_4pl()`, and `fit_tls()`. The warning assigns responsibility
  to users and recommends an independent bayesTLS refit without treating
  agreement as proof.
- Rebuilt the active sequence around oxygen-gradient zebrafish, age-six and
  all-age cereal aphids, Snow-gum PSII, Drosophila mortality, and Drosophila
  awake/coma counts. Exact filters, endpoints, formulas, thresholds, and
  reference times are tested.
- Removed shrimp and life-stage zebrafish from active navigation, summaries,
  examples, search, sitemap, LLM discovery, and comparison tables while
  retaining their data objects and historical caches as compatibility fixtures.
- Added the byte-identical Snow-gum object with an explicit non-commercial
  GitHub/pkgdown authorization boundary. CRAN, commercial reuse, and adaptation
  remain blocked pending a broader written grant.
- Corrected formula-design starts, added deterministic Newton refinement when
  it improves the objective and gradient, and added row-specific direct-
  parameter prediction for interacted formula designs.
- Built the pinned six-unit bayesTLS cache on Totoro, reviewed its candidate
  SHA-256, published only the exact reviewed bytes, and displayed actual
  ML-minus-posterior-median differences. The comparison refuses to subtract
  unlike Drosophila mortality estimands.
- Made Beta boundary handling visible: Snow-gum now warns that 90 of 394 values
  are clamped into `[0.001, 0.999]`, and tests the 89-zero/one-one adjustment.
- Hardened the site build so it installs the exact checkout, filters legacy
  terms and URLs, removes internal governance pages, and requires one warning
  banner on every rendered HTML page.

## 3a. Decisions and Rejected Alternatives

The single-stage 4PL and direct `CTmax`/`log_z` mapping are unchanged. The
default threshold remains relative. Canonical formulas may place fixed effects
on `CTmax`, `z`, and the shape coordinates, and Snow-gum uses one experimental
plant random intercept on `CTmax`. freqTLS reports confidence intervals; the
cache reports bayesTLS posterior medians and credible intervals.

Drosophila mortality is the critical estimand boundary. Its direct freqTLS
coordinates are relative, whereas the pinned reported pair is absolute. The
paired table therefore compares only the numerically derived absolute
240-minute LT50 point and requires one crossing per sex. It does not present a
relative `z` minus absolute `z` difference. Snow-gum is explicitly a refit of
the locked shared-shape analogue, not the richer displayed Bayesian shape
model.

The package retains its broader experimental frequentist capabilities instead
of returning to the former count-only core. Unsupported Bayesian analyses are
linked rather than approximated with substitute endpoints. Requiring ML
estimates to equal posterior medians, averaging discrepancies, deriving an
unvalidated absolute mortality `z`, deleting unpublished compatibility data,
or distributing raw MCMC output were all rejected.

## 4. Files Touched

The change spans package code and tests under `R/` and `tests/testthat/`,
roxygen-generated help under `man/`, the canonical data/cache under `data/` and
`inst/extdata/`, README source/generated files, all canonical vignettes,
`_pkgdown.yml`, the common pkgdown warning include and site builder, CI
deployment concurrency, package provenance/licensing, and the governance/audit
documents under `docs/`. The exhaustive file-level classification is
`docs/dev-log/audits/2026-07-16-bayestls-parity-ledger.md`.

## 5. Checks Run

- `Rscript -e 'devtools::document()'` regenerated package and
  `standardize_data()` help from roxygen sources.
- `Rscript -e 'devtools::test(stop_on_failure = TRUE)'` passed 1,033 tests with
  0 failures, 0 warnings, and 0 skips after the audit repairs.
- `Rscript -e 'devtools::check(document = FALSE, manual = FALSE, error_on =
  "error")'` completed in 3 minutes 12 seconds with 0 errors, 0 warnings, and 0
  notes, including installed-package tests, examples, donttest examples, and
  rebuilt vignettes.
- `Rscript tools/build-site.R` built 103 HTML pages from an exact temporary
  installation; `Rscript -e 'pkgdown::check_pkgdown()'` reported no problems.
- The rendered-site assertion counted
  `id="freqtls-experimental-warning"` in every HTML file and returned 103 pages,
  minimum 1, maximum 1. All seven intended canonical article routes existed.
- `rg -n -i "shrimp|life-stage|zebrafish_lethal"
  pkgdown-site/dev/search.json` returned no hit. Legacy URLs were absent from
  `sitemap.xml`, `llms.txt`, and `articles/index.html`.
- `Rscript -e 'x <- readRDS("inst/extdata/canonical_bayesTLS_cache.rds"); ...'`
  confirmed 40 summary rows, six diagnostic rows, maximum R-hat 1.0019, zero
  divergences, and zero tree-depth hits. Cache SHA-256 is
  `3b04bb161250abb1628e3018ff25648984b7c6a4131272e6e9c0557b15c3b2f0`.
- `git diff --check` returned no whitespace error after the audit-ledger repair.
- `gh pr checks 7` at implementation HEAD `d6b1acd` reported pass on Ubuntu R
  release, Ubuntu R devel, Windows R release, and macOS R release in run
  `29514936172`.

## 6. Tests of the Tests

The canonical tests pin dataset bytes and deterministic analysis hashes, exact
filters/aggregations, formulas, families, `t_ref`, thresholds, endpoints,
reported quantities, convergence, Hessian, raw gradient, and forbidden
`Tcrit`. Installed-package cache tests now exercise the distributed cache
without depending on build-excluded `data-raw`. The comparison joins fail
closed at 18 primary rows, 18 all-age aphid rows, and two mortality rows. The
mortality transform requires exactly one observed-range 50% crossing. Generic
and Snow-gum-specific tests prove the new clamp warning and exact boundary
counts.

## 8. Consistency Audit

The parity ledger classifies all starting homepage sections/chunks, 12 article
surfaces and 126 chunks, reference topics/example blocks, data, caches,
navigation, and discovery artifacts. AGENTS, SPEC, the benchmark protocol,
package help, and generated Rd were re-audited after Rose found retained v0.1
language. The public prose uses confidence language for freqTLS and posterior/
credible language only for the explicitly Bayesian comparator.

The final independent gate returned Fisher READY and Pat READY. Fisher verified
formula/threshold/estimand parity, cache diagnostics, actual differences, join
cardinality, and the Drosophila root guard. Pat verified the visible Snow-gum
clamp warning, copyable comparison code, canonical navigation, diagnostic and
interval language, and bayesTLS routing. Rose found no remaining source blocker;
the four-platform implementation-head CI pass and this validated closure record
close the two conditions remaining in her re-audit.

## 7a. Issue Ledger

`gh issue list --state open --limit 100 --json number,title,url` returned `[]`;
no overlapping issue required an update. PR #6 delivered the urgent warning and
merged first. PR #8 fixed pkgdown concurrency and merged separately. Draft PR
#7 carries the v0.2 parity, canonical cache, audit repairs, and this closure
record.

## 9. What Did Not Go Smoothly

The original checkout was dirty, so implementation moved to a clean worktree
and preserved the user's changes. A version-only pkgdown installation rendered
stale development code. Formula starts did not initially match no-intercept
cell-mean designs. Base `rbind()` rejected comparator summaries with different
grouping columns. A global pkgdown concurrency group let skipped PR workflows
cancel the valid main deployment. The first installed-package cache test tried
to source build-excluded `data-raw`. Finally, the Snow-gum tutorial claimed a
visible Beta clamp while the code was silent. Each failure now has a code,
test, build, or governance guard.

## 11. Team Learning

`docs/dev-log/team-improvements.md` records five reusable lessons: install the
exact development checkout; initialise formula starts from the design matrix;
key deployment concurrency by upstream branch; separate candidate construction
from reviewed-byte publication; and audit search terms as a reader would query
them, not only forbidden URLs. The Rose–Pat–Fisher default-NOT-DONE gate caught
both an installed-package failure and a material 90/394 response adjustment
that ordinary source tests had not made visible.

## 10. Known Residuals

freqTLS 0.2.0.9000 remains experimental and is not a CRAN submission. It does
not fit censored time-to-event, hurdle-productivity, posterior, or repair-rate
models. Drosophila absolute-LT50 uncertainty remains unavailable because the
exact-model bootstrap produced too few converged refits; the point result is
labelled accordingly. Snow-gum CRAN/commercial/adaptation redistribution
remains blocked. The Wuhan trace remains excluded pending a complete licence
chain. Raw MCMC fits stay local. The small canonical cache must be rebuilt from
the pinned source workflow whenever data, formulas, thresholds, or either
engine changes.

## 12. Cross-Product Coverage

Covered: source and rendered README, home/articles/reference/news/authors/error
pages, canonical empirical cases, reference examples, warning injection,
navbar/search/sitemap/LLM discovery, source and installed tests, cache
provenance, licence ledger, and GitHub/pkgdown publication workflow. Deferred:
CRAN submission, removal/deprecation of legacy data objects, censored/hurdle
models, fitted repair dynamics, and raw posterior-output distribution.

This task does NOT cover a CRAN submission, new likelihood families, censored
or hurdle engines, Bayesian inference inside freqTLS, a fitted repair kernel,
deletion of legacy benchmark inputs, or unrestricted Snow-gum redistribution.
