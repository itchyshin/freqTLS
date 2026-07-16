# Component rights ledger — 0.1.0 integration candidate

Status: provisional; replace its inventory with the exact `R CMD build` entry
list before a submission decision.

| Component class | Authoritative record | Release treatment |
| --- | --- | --- |
| Package R/C++ code and generated Rd | `DESCRIPTION`, `inst/COPYRIGHTS` | SHIP under GPL (>= 3), with adapted-code notices retained |
| `data/*.rda` other than Snow-gum | `docs/design/47-data-license-ledger.md` | SHIP only where the listed source licence and transformation record are present |
| `data/snowgum_psii.rda` | `R/data.R`, `inst/CITATION`, `inst/COPYRIGHTS`, `data-raw/licensing-pending/snowgum/AUTHORIZATION.md` | SHIP as a separately licensed CC BY-NC 4.0 teaching component; retain attribution, DOI, transformation record, and Pieter A. Arnold's recorded authorization |
| `inst/extdata/canonical_bayesTLS_cache.rds` | `docs/design/47-data-license-ledger.md`, `docs/design/48-canonical-comparator-cache.md` | SHIP only with its source-specific attribution, including the Snow-gum notice where rows derive from that dataset |
| Generated figures and SVG | source vignette/figure files plus `inst/COPYRIGHTS` | SHIP; no external binary or unrecorded asset |
| `data-raw/`, `output/`, `scripts/`, `docs/`, `.codex/` | `.Rbuildignore` | EXCLUDE from the source tarball |
| Licensing-pending raw material | `data-raw/licensing-pending/` | EXCLUDE; provenance retained outside the distributed package |

The final tarball audit must fail if an unlisted component appears, or if a
listed EXCLUDE path appears in the artifact.
