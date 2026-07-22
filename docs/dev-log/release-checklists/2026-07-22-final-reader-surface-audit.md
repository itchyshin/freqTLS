# Final reader-surface audit — 0.1.0

Audited from `1ba3cf5` plus the corrections recorded below, in the clean
`codex/final-reader-surface-audit` checkout on 2026-07-22. This is a public
documentation and pkgdown audit; it does not claim a new CRAN submission state.

## Prior-work sweep

- Earlier release ledgers (`2026-07-16-function-reference-ledger.md` and
  `2026-07-16-pkgdown-page-ledger.md`) supplied the original export and page
  inventory.
- The audit began from current `origin/main` after #56, #57, and #60. There
  were no open GitHub issues or pull requests to duplicate.
- The rendered site, not only its R Markdown and Rd sources, was inspected.

## Function and reference ledger

`NAMESPACE` contains 47 exports. The audit parsed all generated Rd aliases,
mapped every export to its Rd topic, checked that its topic has rendered
reference HTML, and checked that either its alias or topic is named in
`_pkgdown.yml`. Result: **47/47 aliases, 47/47 rendered pages, 47/47 intended
reference placements**.

| Export set | Rd topic and pkgdown placement |
| --- | --- |
| `beta_binomial_tls`, `beta_tls`, `binomial_tls` | `tls_family` |
| `check_tls`; `clock_to_minutes`; `derive_ctmax`; `derive_lt`; `derive_tcrit`; `diagnose_tdt_fit`; `extract_tdt`; `fit_4pl`; `fit_tls`; `format_interval`; `get_ctmax`; `get_shape`; `get_z`; `heat_injury_envelope`; `make_4pl_formula`; `plot_confidence_eye`; `plot_heat_injury`; `plot_survival_curves`; `plot_survival_surface`; `plot_tdt_curve`; `predict_heat_injury`; `predict_survival_curves`; `predict_survival_surface`; `ranef`; `simulate_tls`; `standardize_data`; `tdt_parameter_table`; `tdt_quantile`; `tidy_parameters`; `tls`; `tls_bf`; `ts_ci`; `ts_curve`; `ts_stage1`; `ts_stage2` | Same-named reference topic |
| `get_ctmax_draws`, `get_ctmax_summary`, `get_tcrit_draws`, `get_tcrit_summary`, `get_z_draws`, `get_z_summary` | `tdt-accessors` |
| `tls_ctmax`, `tls_tcrit`, `tls_z` | `tls` |

`devtools::document()` made no generated-manual changes and
`devtools::check_man()` was clean. Reference examples were also covered by the
installed-package test suite. The Bayesian words found in help pages and
articles are deliberate comparisons; no freqTLS interval is described as
posterior or credible.

## Rendered page ledger

The corrected build contained 103 HTML pages: 15 articles, 82 reference
pages/redirects, and the expected home, news, author, roadmap, 404, and index
pages. Every relative local link and asset target resolved (3,074 references,
0 missing). `AGENTS.html`, `CLAUDE.html`, and `SPEC.html` were absent from the
public root and discovery files.

Articles audited: `freqTLS`, `model-math`, `case-study-zebrafish`,
`case-study-li-aphids`, `case-study-snowgum`, `case-study-suzukii`,
`case-study-suzukii-coma`, `case-study-summary`, `comparing-to-bayesTLS`,
`frequentist-and-bayesian`, `heat-injury`, `profile-likelihood`,
`random-effects`, the article index, and the retained direct legacy notice.

Semantic checks confirmed the experimental warning, minute-valued one-hour
default (`tref = 60`), relative-threshold fitting default, limited independent
random intercepts, prediction-only heat injury, Snow-gum attribution pages,
and the frequentist/Bayesian terminology boundary. The only stale release
phrase remaining is the roadmap's historical status legend, where “not yet
implemented” correctly defines the `initial` state.

Visual inspection covered the home/get-started Confidence Eye, the open-profile
fallback, heat-injury band, random-effects Eye, and Snow-gum Eye. Each rendered
cleanly, retained hollow estimates and confidence language, and showed no
posterior-like density display.

## Repairs made by this audit

1. The home page now says that fitting targets the relative midpoint and that
   `extract_tdt()` can derive an absolute threshold afterwards. It no longer
   incorrectly calls that supported post-fit route “not yet wired”; it states
   the actual unsupported boundary: fit-time absolute-threshold mode and
   non-default asymptote bounds.
2. The get-started function map no longer advertises non-existent planned
   `make_temperature_scenarios()` and `repair_rate_schoolfield()` APIs. It now
   identifies user-supplied temperature/repair scenarios and says that repair
   is not fitted from data.

## Reproducible checks

The exact commands and their outcomes are appended to
`docs/dev-log/check-log.md`. The source-derived export/Rd/pkgdown mapping and
the rendered-link audit are base-R/xml2 one-liners in that log, so the ledger
can be regenerated from any clean checkout after `tools/build-site.R`.
