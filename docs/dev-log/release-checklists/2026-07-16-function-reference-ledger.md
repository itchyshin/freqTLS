# Function and reference ledger — experimental 0.1.0

Date: 2026-07-16  
Status: source and rendered-reference audit complete for the local candidate.

The inventory is derived from `NAMESPACE` and `man/*.Rd`, not from a handwritten
API list. `NAMESPACE` has **47 exports**; all 47 have at least one Rd alias.
`devtools::check_man()` passed after `devtools::document()`.

| Check | Result | Release action |
|---|---|---|
| Export → Rd alias | 47/47 | pass |
| Configured pkgdown topic → Rd topic | 50/50; 81 rendered reference pages on the rebuilt site | pass |
| Public examples require bayesTLS/Stan | none found | pass |
| Internal Rd topics rendered as public reference pages | 7 found and removed: `compute_4pl_bounds`, `tdt_check_columns`, `tdt_format_random_effects`, `tdt_random_effect_variables`, `tdt_resolve_time_multiplier`, `tdt_unit_to_minutes`, `tls-diagnostics` | `@noRd`, regenerated Rd, absent from rebuilt reference |
| Interval terminology | bootstrap descriptions implied a posterior analogue | rewritten as a frequentist parametric-bootstrap alternative |
| API-map claim | nonexistent `make_temperature_scenarios()` appeared as a user-facing planned helper | map now labels it as planned and separates existing internal repair-rate support; final rendered review must verify the wording |

The intended public reference placement is the grouping in `_pkgdown.yml`.
Grouped Rd topics and S3 aliases are valid public placements; the audit therefore
does not require a one-page-per-export mapping.
