# After Task: experimental 0.1.0 CRAN remediation and reader-surface audit

Date: 2026-07-16  
Branch: `build/freqtls`  
Verdict: **NOT READY — source remediation complete only; no frozen candidate**

## 1. Goal

Make the shipped expanded experimental surface internally truthful, audit the
public function/reference contract and pkgdown source surface, and identify the
exact provenance and candidate gates without uploading or claiming CRAN status.

## 2. Implemented

The release boundary now names beta responses, both interfaces, fixed shape
designs, independent random intercepts except `up`, Wald/profile/bootstrap
intervals, and deterministic heat-injury prediction as shipped. It keeps the
remaining unsupported combinations explicit. `bayesTLS` is no longer a runtime
Suggest. Seven internal helper Rd topics are no longer public reference pages.

Snow-gum is recorded as a separate CC BY-NC 4.0 component with its primary
source and transformation; it is not presented as relicensed by bayesTLS. The
rights ledger excludes unused unlicensed traces and records bayesTLS 1.0.0's
CC BY 4.0 distribution terms for the remaining upstream data. The cache still
needs an exact upstream SHA before it can support a reproducible rebuild claim.

## 3. Mathematical contract

No likelihood, 4PL `CTmax`/`log_z` map, bounds transform, or interval algorithm
changed. Edits clarify the existing direct-coordinate, frequentist contract;
in particular bootstrap intervals are not described as posterior analogues.

## 4. Files and ledgers

Key sources are `DESCRIPTION`, `.Rbuildignore`, `inst/COPYRIGHTS`,
`inst/CITATION`, `R/confint.R`, `R/tdt-utils.R`, `_pkgdown.yml`, and the
vignettes. The audit artefacts are the dated ultra-plan, component-rights,
function-reference, and pkgdown-page ledgers in `docs/dev-log/release-checklists/`.

## 5. Checks

- `Rscript -e 'devtools::document(); devtools::check_man()'`: passed.
- NAMESPACE/Rd audit: 47 exports, all with an Rd alias.
- `git diff --check`: passed.
- `Rscript tools/build-site.R .`: completed after a repair to the internal-page
  index guard; 101 HTML pages (14 articles, 81 reference pages), no governance
  pages or broken local links, and the function-map SVG guard passed.
- `R CMD build --no-manual --sha256 .`: completed; 210-entry full-vignette
  artifact, 1,653,817 bytes, SHA-256
  `67518e0f585834791c919e86d1c2d20363a1d32edb4cb2a2404d0775d499ad55`.
- `R CMD check --as-cran --no-manual freqTLS_0.1.0.tar.gz`: 0 errors, 0
  warnings, one new-submission NOTE on local macOS arm64 / R 4.6.0.

## 6. Tests of the checks

The internal-reference repair is mechanically testable: roxygen deleted the
seven generated internal Rd files. The next completed pkgdown build must prove
their reference pages and all governance artifacts are absent from HTML,
Markdown, `search.json`, and `sitemap.xml`.

## 7. Consistency and issue audit

The status inventory was synchronized and the targeted stale wording scan found
only deliberate historical/default wording. No GitHub issue was changed: this
was a local remediation lane, and no tracker action was authorized.

## 8. What did not go smoothly

pkgdown initially exposed a false positive in the new search/sitemap guard:
some search-index records have no path. The guard now handles those records as
empty paths and checks only actual internal-page URLs. The full build then
completed, including the SVG corruption and internal-page assertions.

## 9. Team learning

Deleting visible governance HTML is insufficient: pkgdown also publishes raw
Markdown and indexes the source page. The site guard now covers all four routes.
For data, a package-level GPL declaration is not a substitute for a
component-level redistribution record.

## 10. Remaining gates

1. Record written co-author consent and matching Windows/Ubuntu evidence.
2. Adjudicate URLs/DOIs and finalize `cran-comments.md` against the exact
   artifact identity.
3. Obtain final clean post-merge source state and rebuild the frozen artifact.
4. Ask Rose, Grace, and Pat to inspect the
   same frozen hash.
