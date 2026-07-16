# Function and reference ledger — 0.1.0 integration candidate

Status: source audit complete; rendered-reference placement awaits the final
pkgdown build.

| Check | Result | Evidence |
| --- | --- | --- |
| Export inventory | 47 exports | `NAMESPACE` parsed on 2026-07-16 |
| Export without generated Rd alias | 0 | alias scan across `man/*.Rd` |
| Exported API delta from current `main` | 0 | sorted `NAMESPACE` export comparison with `build/freqtls` |
| Roxygen generation | clean | `devtools::document()` regenerated `snowgum_psii.Rd` |
| `check_man()` | clean | `devtools::check_man()` on the integration branch |
| Confidence terminology repair | applied | bootstrap help now calls itself a frequentist resampling interval, not a posterior/credible interval |

The final site audit must add the count of reference HTML pages and confirm that
each export has intended `_pkgdown.yml` reference placement.
