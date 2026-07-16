# pkgdown page ledger — 0.1.0 integration candidate

Built from commit `90efecb` plus the uncommitted final source-audit repairs;
the ledger is refreshed again after the candidate is frozen.

| Check | Result |
| --- | --- |
| `Rscript tools/build-site.R .` | completed; generated-site guards passed |
| HTML pages | 103 |
| Article pages | 15 |
| Reference pages | 82 |
| Internal root pages (`AGENTS`, `CLAUDE`, `SPEC`) | absent after build cleanup |
| Stale release/rights phrases in rendered HTML | 0 hits for `0.2.0.9000`, experimental v0.2, or the superseded Snow-gum block wording |
| Reference example images with empty alt text | 0 |
| `pkgdown::check_pkgdown()` | no problems |

Visual inspection remains part of the final frozen-candidate audit: home, the
function-map article, each article template class, and reference figure pages
must be inspected from the final rebuilt site, not this intermediate build.
