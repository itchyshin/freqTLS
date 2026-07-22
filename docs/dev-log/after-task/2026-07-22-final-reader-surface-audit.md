# After Task: Final reader-surface audit

## 1. Goal

Audit every exported function document and every public pkgdown page after the
human-validation repairs, correct any remaining reader-facing inconsistency,
and leave reproducible evidence.

## 2. Implemented

The home page now distinguishes supported post-fit absolute-threshold
extraction from unsupported fit-time absolute-threshold fitting. The function
map now represents the real public/internal boundary for heat-injury scenarios.
The audit ledger records the complete export-to-Rd-to-pkgdown mapping and the
rendered-site page, link, asset, semantic, and visual checks.

## 3. Mathematical Contract

No likelihood, 4PL mapping, direct `CTmax`/`z` parameterisation, threshold
transform, or interval algorithm changed. Documentation now states the existing
contract: fit the relative midpoint, then derive an absolute threshold only by
the documented post-fit route.

## 3a. Decisions and Rejected Alternatives

The audit retained the supported post-fit absolute extraction route and rejected
the misleading alternative of describing it as wholly unimplemented. It also
rejected invented future helper names in the public map: a user-supplied repair
scenario is not a public API or an estimated repair sub-model.

## 4. Files Touched

- `README.Rmd` and generated `README.md`
- `vignettes/freqTLS_function_map.svg`
- `docs/dev-log/release-checklists/2026-07-22-final-reader-surface-audit.md`
- `docs/dev-log/check-log.md`
- this report

## 5. Checks Run

- `devtools::document()` and `devtools::check_man()` were clean.
- All test files were run in bounded, complete filter batches with 0 failures,
  warnings, or skips; the batch receipts are in the check log.
- `pkgdown::check_pkgdown()` returned `No problems found`.
- The full rendered site was built and the post-build guards passed after the
  corrected get-started article was rendered.
- The export/Rd/reference audit was 47/47/47; the rendered site had 103 HTML
  pages and 0 missing local link or asset targets.
- `git diff --check` was clean.

## 6. Tests of the Tests

The function inventory derives exports from `NAMESPACE`, aliases from generated
Rd files, and placement from `_pkgdown.yml`; it therefore fails if an exported
function loses any part of its public path. The link audit resolves targets
relative to each rendered page rather than trusting source links.

## 7a. Issue Ledger

No open issue or PR matched this final audit when it began. The two repaired
findings were cross-surface wording/map defects, so this focused follow-up PR
is preferable to reopening already-resolved human-review issues.

## 8. Consistency Audit

The README source and generated README, rendered home page, function map,
reference index, capability boundary, and heat-injury documentation agree on
relative fitting, post-fit absolute extraction, user-supplied repair scenarios,
and prediction-only injury/repair scope. Deliberate `bayesTLS` comparisons
retain posterior/credible language only for the Bayesian comparator.

## 9. What Did Not Go Smoothly

pkgdown's full clean build exceeded the interactive terminal slice while
copying assets. Incremental rendering completed the same build, followed by the
existing post-build guard. Re-rendering an individual article temporarily
regenerated stale search entries; rerunning the guard removed them, confirming
why the deployed build must always use `tools/build-site.R` rather than a
piecemeal article render.

## 10. Known Residuals

This is local source and rendered-site evidence, not a new CRAN submission or
live GitHub Pages deployment claim. The package remains experimental and any
future source change requires the affected documentation and site checks again.

## 11. Team Learning

Reader-surface audits must check whether a phrase says a capability is absent,
partially supported, or only unsupported at fit time. The function map should
not use invented helper names as visual placeholders: label the actual public
or internal boundary instead.

## 12. Cross-Product Coverage

The audit covered the R public API, generated Rd, `_pkgdown.yml`, rendered HTML,
README, all articles, discovery files, site assets, and test suite. It did not
change the likelihood, compiled code, benchmark cache, package rights ledger,
or external CRAN/live-site state. It does NOT cover a new exact tarball,
cross-platform checks, a CRAN upload, or a browser fetch from GitHub Pages.

## Next Actions

Open, check, and merge this narrow documentation-audit PR. The next human
validation should review the same merged hash and live deployment, not an
earlier local site.
