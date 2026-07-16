# bayesTLS parity ledger for the freqTLS v0.2 teaching surface

**Audit date:** 2026-07-16
**freqTLS baseline:** `c9f101429d95846bf41207a66085e59ffcef5b4c` (`origin/main`)
**bayesTLS baseline:** `76510412e06c594c96894a1baba1f0e1a34a5aea`
**Rendered baseline:** <https://daniel1noble.github.io/bayesTLS/>, supplement rendered 2026-07-14
**Scope:** starting source/rendered surfaces, their disposition, and a final-state
reconciliation. Fit evidence is recorded in the canonical tests and check log.

The pinned `ms/supplement.qmd` is authoritative for empirical teaching. The
closing bayesTLS README case list is not authoritative. The freqTLS repository
remains authoritative for what the frequentist engine currently implements.

## Classification contract

Every inventoried surface has exactly one of these target classifications.

| Code | Classification | Public treatment |
|---|---|---|
| `CM` | canonical mirror | Same empirical data, filter, endpoint, model specification, reference time, threshold and estimand as the pinned supplement. |
| `FA` | frequentist analogue | Same scientific task, with maximum-likelihood estimates and confidence intervals rather than posterior summaries. |
| `FX` | freqTLS-only extension | Retain outside the canonical case-study sequence, normally with synthetic data. |
| `EX` | experimental extension | Retain, but label as experimental and keep separate from canonical parity claims. |
| `BL` | benchmark-only legacy | Keep in package/maintainer infrastructure; remove from active teaching, navigation and generated discovery surfaces. |
| `UB` | unsupported / bayesTLS-only | Name the boundary and link to bayesTLS; do not substitute a different analysis. |
| `RM` | remove or replace | Current surface cannot remain active in its present form. |

## Count reconciliation

| Surface | Starting count | Final count | Coverage in this ledger |
|---|---:|---:|---|
| README/homepage level-two sections | 11 | 11 | 11 section rows below |
| README/homepage R chunks | 9 | 9 | 9 chunk rows below |
| Vignettes/articles | 12 | 14 | 12 starting rows plus Snow-gum and Case 4.2 additions below |
| Article level-two sections | 81 | 55 | Starting sections classified; final rewrites/additions reconciled below |
| Article R chunks | 126 | 101 | Starting chunks classified; final rewrites/additions reconciled below |
| Rd topics | 56 | 57 | Starting topics plus installed `snowgum_psii` topic |
| Rd topics containing `\\examples{}` | 46 | 46 | `Example` column below; all classified |
| NAMESPACE exports | 47 | Crosswalk below: 21 shared, 26 freqTLS-only |
| Packaged `.rda` datasets | 6 | 7 | Six starting objects plus installed `snowgum_psii` |
| `inst/extdata` files | 15 | 16 | 10 result caches and 6 raw CSVs below |
| Generated discovery surfaces | 3 | 3 | navbar/article index/reference index, `search.json`, `sitemap.xml`/`llms.txt` |

No homepage section or chunk, article section or chunk, Rd topic/example,
dataset, navigation group, discovery index, or cache/raw-data file remains
unclassified at the end of this ledger.

## Canonical empirical specifications

These specifications are transcribed from the pinned supplement. They are the
acceptance target for replacement articles and for deterministic tests.

| Case | Data and filter | Endpoint and family | Direct model | Extraction and boundary |
|---|---|---|---|---|
| Zebrafish oxygen (Case 1) | `zebrafish_o2`; `ploidy == "diploid"`; oxygen in `c("normoxia", "hyperoxia")`; retain the 26 C normoxia controls | Survival counts; beta-binomial | `ctmax = ~ 0 + oxygen`; `z = ~ 0 + oxygen`; `low = ~ 0 + oxygen`; shared `up = ~ 1`, `k = ~ 1`; `t_ref = 60` min | Relative midpoint; `tls(..., by = "oxygen", lethal = FALSE)`; report `CTmax` and `z`, not `Tcrit`. Hypoxia is not a substitute group: its `z` is weakly identified and it is excluded from the canonical comparison. |
| Cereal aphids (Case 2 main) | `aphid_tdt`; `branch == "heat" & age == "6"`; all three species | Survival counts; beta-binomial | `ctmax = ~ 0 + species`; `z = ~ 0 + species`; `k = ~ temp_c`; shared `low = ~ 1`, `up = ~ 1`; `t_ref = 60` min | Relative midpoint; report species `CTmax` and `z`; TDT curves. Heat injury is permitted only after the Wuhan trace licence/provenance is recorded; any repair kernel is illustrative and unfitted. |
| Cereal aphids (Case 2 extension) | `aphid_tdt`; `branch == "heat"`; all ages and species | Survival counts; beta-binomial | `ctmax = ~ 1 + species * age`; `z = ~ 1 + species * age`; `k = ~ temp_c`; shared `low = ~ 1`, `up = ~ 1`; `t_ref = 60` min | Report every species-by-age `CTmax` and `z` cell. This is part of the canonical case, not a replacement empirical example. |
| Snow gum PSII (Case 3) | `snowgum_psii`; 394 retained rows; Dark versus Light recovery; six `plant` levels | Continuous retained-PSII proportion; Beta | `ctmax = ~ 0 + recovery + (1 | plant)`; `z = ~ 0 + recovery`; shared shape; `t_ref = 60` min | `FA`, not `CM`: the locked freqTLS shared-shape analogue is intentionally simpler than the pinned displayed bayesTLS shape model. Relative midpoint; `lethal = FALSE`; report `CTmax` and `z`, never `Tcrit`. |
| D. suzukii mortality (Case 4) | `dsuzukii`; aggregate by `temp`, `time`, `sex` with `n_dead = sum(dead)`, `n_total = n()` | Mortality/survival counts; beta-binomial | Show separate-sex fits, then joint direct fit: `ctmax = ~ 0 + sex`; `z = ~ 0 + sex`; `low = ~ temp_c`; `up = ~ temp_c`; `k = ~ temp_c`; `t_ref = 240` min | Absolute LT50 threshold; report per-sex `CTmax` and `z`. Explain the supplement's midpoint-coordinate fit as the equivalent Bayesian teaching route. Do not promote `Tcrit` as a case-study result in freqTLS. |
| D. suzukii coma (Case 4.2 supported arm) | `dsuzukii`; group by `temp`, `lvl`, `sex`; `n_total = n()`; `n_awake = sum(is.na(t_coma))`; `duration = first(time)`; drop `duration == 0` | Awake/coma counts; beta-binomial | `ctmax = ~ sex`; `z = ~ sex`; `low = ~ temp_c`; `up = ~ temp_c`; `k = ~ temp_c`; `t_ref = 60` min | Relative midpoint; report `CTmax` and `z`, never `Tcrit`. The censored log-time model is `UB` and must be linked, not approximated. |
| D. suzukii productivity (Case 4.2 unsupported arm) | Same `dsuzukii` individuals | Reproduction incidence plus positive clutch size | bayesTLS hurdle-Gamma/lognormal workflow | `UB`: name and link the hurdle analysis; freqTLS must not claim or imply it has fitted it. |

### Dataset identity and provenance

SHA-256 values are hashes of the exact `.rda` bytes at the pinned commits.

| Object | Rows | bayesTLS SHA-256 | freqTLS SHA-256 | Classification and action |
|---|---:|---|---|---|
| `aphid_tdt` | 3,041 | `3e078b61c5f9ff4885aa3e9a82b5f45295e6de4d2cd9c034d3da2bd2f81424ae` | same | `CM`; retain and test hash/filter. |
| `dsuzukii` | 1,407 | `c030f016e23a829a3caf783c787a792681b18e088684bc2e586c4e14c6bf0c7a` | same | `CM`; retain and test hash/aggregations. |
| `zebrafish_o2` | 905 | `1d5fad99cb005bffe879a8602eba0ca2ac0a55a5b263f179bcc0416a6754d310` | same | `CM`; retain and test the two-treatment filter. |
| `snowgum_psii` | 394 | `20fd38c0dca50e29723b409371d60146197064641c9b51c579cf926d21e89864` | same | `FA`; byte-identical processed object installed for the authorised non-commercial development site; CRAN/commercial/adaptation redistribution remains blocked. |
| `shrimp_lethal` | -- | absent from pinned bayesTLS | `070f496d0e6e94467cd061ce8663704b2a05110f51f07f6cbc232d33cce45a78` | `BL`; package/benchmark only, no active example or discovery entry. |
| `shrimp_sublethal` | -- | absent from pinned bayesTLS | `ed98fcab73e2e2baa9b2828550985ac2a298d4025fd1d49534ec1006f7777e83` | `BL`; package/benchmark only, no active example or discovery entry. |
| `zebrafish_lethal` | -- | absent from pinned bayesTLS | `8e6c09b5318a8234e49263f3dbc3be5368a3dac53f1130eaf5cdb114b0b469ec` | `BL`; the life-stage dataset is not the canonical oxygen-gradient zebrafish example. |

## Homepage inventory

### Sections (11/11)

| Current section | Class | Required disposition |
|---|---|---|
| What freqTLS does | `FA` | Lead with experimental status and the ML/profile-likelihood distinction; avoid blanket drop-in claims. |
| Why not the two-stage workflow | `FA` | Retain with evidence-bounded language. |
| How it differs from bayesTLS | `FA` | Rewrite as a side-by-side inference crosswalk and link the pinned supplement and repository. |
| Installation | `FA` | Retain; experimental-development installation only. |
| Quick start | `FA` | Retain synthetic workflow; make fit checks and interval method visible. |
| Formula interface | `EX` | Retain as an explicitly experimental freqTLS capability. |
| Random effects on CTmax and z | `EX` | Retain outside empirical parity examples and label limited/experimental. |
| Population differences in curve shape | `EX` | Retain with synthetic data; do not present it as the canonical constant-shape case specification. |
| The model | `FA` | Reconcile equations and threshold language with the pinned model. |
| Credit and origins | `CM` | Retain bayesTLS/Noble-Arnold-Pottier attribution and add exact pinned provenance. |
| Data credits | `RM` | Rebuild around the four canonical objects; move shrimp/life-stage zebrafish to an explicit benchmark-only ledger, not homepage teaching. |

### Chunks (9/9)

| Chunk | Class | Required disposition |
|---|---|---|
| unnamed setup (`include = FALSE`) | `FX` | Retain build setup. |
| `readme-eye` | `FX` | Retain Confidence Eye as the frequentist visual identity. |
| `quickstart` | `FA` | Retain synthetic shared workflow and add convergence/identifiability reporting. |
| `grouped-headline` | `FX` | Retain as a frequentist grouped-extraction example. |
| `readme-survival` | `FA` | Retain prediction plot with confidence language. |
| `formula` | `EX` | Retain, explicitly experimental. |
| `random-effects` | `EX` | Retain, explicitly experimental. |
| `grouped-shape` | `EX` | Retain, explicitly experimental. |
| `grouped-shape-curves` | `EX` | Retain, explicitly experimental. |

## Article inventory

The `Sections` field records every level-two section. The `Chunks` field records
every R chunk label; the first unnamed setup chunk is written as `(setup-opts)`.
All chunks in a row inherit the row classification unless an exception is stated.

| Article | Sections | Chunks | Class | Required disposition |
|---|---:|---:|---|---|
| `case-study-li-aphids.Rmd` | 5: dataset/question; grouped fit; Confidence Eyes; fit plot; boundary | 9: `(setup-opts)`, `setup`, `data`, `standardize`, `fit`, `ranking`, `eye-ctmax`, `eye-z`, `survival` | `CM` target | Revise `fit` to add `k = ~ temp_c`, shared `low/up`; add the all-age species-by-age extension and TDT curves. Replace shrimp/profile cross-links. |
| `case-study-shrimp.Rmd` | 5: live fit; fit display; critical temperatures; three-way comparison; boundary | 8: `(setup-opts)`, `setup`, `profile-shrimp`, `eye`, `survival`, `tdt`, `derive`, `three-way` | `RM` | Remove from active articles. Replace live URL with an unindexed legacy notice/redirect; all eight chunks leave public teaching. |
| `case-study-snowgum.Rmd` (added) | 3: endpoint/licence; exact model; boundary | 6: `(setup-opts)`, `setup`, `standardize`, `fit`, `quantities`, `eye` | `FA` | Active locked shared-shape frequentist analogue; disclose the richer pinned bayesTLS shape model and the restricted redistribution boundary. |
| `case-study-summary.Rmd` | 8: taxa/question; cached fits; table; three-way validation; Confidence-Eye panel; contrasts; findings; bayesTLS ridge | 7: `(setup-opts)`, `setup`, `fits`, `combine`, `three-way-summary`, `panel`, `contrasts` | `RM` | Rebuild from aphids, Snow gum, oxygen zebrafish, Drosophila mortality and coma. Preserve endpoint, threshold and `t_ref` columns; remove shrimp and life-stage zebrafish from all seven chunks. |
| `case-study-suzukii.Rmd` | 7: dataset; fit; contrasts; validation; three-way comparison; lethal boundary; session | 13: `(setup-opts)`, `setup`, `load-data`, `data-shape`, `fit`, `per-sex`, `eye`, `survival`, `tcrit`, `contrast`, `validation`, `three-way-suzukii`, `session` | `CM` target | Rework to Case 4 direct model with temperature effects on `low/up/k`, absolute LT50 and `t_ref = 240`; delete the `tcrit` result chunk. Add a separate Case 4.2 article for awake/coma counts and explicit censored-time/productivity boundaries. |
| `case-study-suzukii-coma.Rmd` (added) | 3: aggregation; exact count model; unsupported arms | 7: `(setup-opts)`, `setup`, `aggregate`, `standardize`, `fit`, `quantities`, `curves` | `CM` | Active awake/coma count analogue with exact endpoint/filter/formulas; censored time-to-coma and hurdle productivity route to bayesTLS. |
| `case-study-zebrafish.Rmd` | 6: dataset/question; grouped fit; Confidence Eyes; interval reading; fit plot; boundary | 10: `(setup-opts)`, `setup`, `data`, `standardize`, `fit`, `tls`, `ranking`, `eye-ctmax`, `eye-z`, `survival` | `CM` target | Filter diploids to normoxia/hyperoxia only; specify `low = ~ 0 + oxygen`, shared `up/k`; `lethal = FALSE`; report only `CTmax/z`; explain excluded hypoxia. |
| `comparing-to-bayesTLS.Rmd` | 10: credit; three-way design; recipe; live freqTLS; numerical comparison; performance; bootstrap; visual distinction; broader shape; choice | 17: `(setup-opts)`, `setup`, `profile-shrimp`, `profile-zebrafish`, `three-way`, `benchmark-provenance`, `perf-load`, `perf-speed`, `speed-head-to-head`, `perf-acc`, `perf-cov`, `bb-phi`, `bootstrap-demo`, `eye`, `v02-stage-shape`, `v02-up`, `v02-derive` | `RM` | Rewrite around canonical permitted data and refreshed provenance. Remove shrimp and life-stage zebrafish from `profile-*`, `three-way`, provenance and eye chunks. Move shape/profile/performance material to labelled `FX/EX` sections using synthetic data. |
| `freqTLS.Rmd` | 7: simulation; standardise/fit; intervals; plots; groups/shape/random effects; function map; next steps | 16: `(setup-opts)`, `setup`, `simulate`, `truth`, `standardize`, `fit`, `fit-formula`, `summary`, `tidy`, `confint`, `wald`, `survival-curves`, `confidence-eye`, `grouped`, `random-effect`, `function-map` | `FA` with `EX` exceptions | Retain synthetic core. Classify `fit-formula`, `grouped`, `random-effect` as `EX`; the other 13 chunks are `FA/FX`. Update map/cross-links after article reorganisation. |
| `frequentist-and-bayesian.Rmd` | 9: philosophies; priors; identifiability; convergence; interval language; calibration; implicit priors; guidance; references | 5: `(setup-opts)`, `setup`, `identifiability`, `calibration`, `shrinkage` | `FX` | Retain as a frequentist extension with synthetic data. `shrinkage` is `EX`; do not claim posterior and profile intervals are interchangeable. |
| `heat-injury.Rmd` | 8: definition; fit; trace; prediction; repair scenario; bootstrap envelope; thresholds; boundaries | 14: `(setup-opts)`, `setup`, `fit`, `tcrit`, `trace`, `predict`, `plot-trace`, `plot-injury`, `plot-survival`, `repair`, `plot-repair`, `bootstrap`, `bootstrap-plot`, `target` | `RM` | Current shrimp empirical fit is legacy. Rewrite as `FX/EX` with synthetic data, or aphids only after trace provenance passes. Keep repair explicitly unfitted; no empirical repair claim. |
| `model-math.Rmd` | 5: 4PL; direct coordinates; bounds; thresholds; bayesTLS bridge | 5: `(setup-opts)`, `setup`, `ctmax-z-properties`, `derive-lt`, `bridge-check` | `FA` | Retain and verify term-for-term against pinned midpoint/direct equations and relative/absolute thresholds. |
| `profile-likelihood.Rmd` | 6: profile; equivariance; Wald comparison; open profiles; calibration; stance | 12: `(setup-opts)`, `setup`, `profile-object`, `profile-plot`, `equivariance`, `profile-vs-wald`, `tidy-methods`, `non-closing`, `bootstrap-fallback-recipe`, `strict-non-closing`, `non-closing-eye`, `coverage` | `FX` | Retain as the central frequentist extension; preserve open-profile honesty and exact interval-method labels. |
| `random-effects.Rmd` | 5: fixed vs random; CTmax random intercept; sensitivity/shape random effects; combinations/boundary; likelihood | 10: `(setup-opts)`, `setup`, `ctmax-re`, `re-recovery`, `ranef`, `re-predict`, `ctmax-ci`, `eye`, `logz-re`, `combined` | `EX` | Retain with synthetic data and limited/experimental wording; do not mix into canonical empirical parity. |

Article totals: **81/81 sections and 126/126 chunks classified**. The new Snow
gum and Drosophila 4.2 pages add 6 sections and 13 chunks; final rewrites leave
14 articles, 54 sections, and 93 chunks. They are classified `FA` and `CM`,
respectively.

## Reference and example inventory

`Example = yes` means the current Rd topic contains an `\\examples{}` block.
Grouped aliases (for example family constructors and accessors) share one Rd
topic and therefore one example classification.

| Rd topic | Example | Class | Required disposition |
|---|---|---|---|
| `aphid_tdt` | yes | `CM` | Replace example with exact heat/age-6 canonical filter and specification. |
| `check_tls` | yes | `FX` | Retain synthetic diagnostic example. |
| `clock_to_minutes` | yes | `CM` | Test input/output parity. |
| `compute_4pl_bounds` | no | `FA` | Retain documented helper; test bounds parity. |
| `confint.profile_tls` | yes | `FX` | Retain synthetic profile/contrast example. |
| `derive_ctmax` | yes | `FX` | Retain; distinguish relative and absolute thresholds. |
| `derive_lt` | yes | `FX` | Retain; distinguish relative and absolute thresholds. |
| `derive_tcrit` | yes | `EX` | Retain synthetic lethal-only example; never use in Snow gum/coma canonical cases. |
| `diagnose_tdt_fit` | yes | `FA` | Test common diagnostic meanings; do not claim identical object structure. |
| `dsuzukii` | yes | `CM` | Show canonical mortality aggregation and point to awake/coma aggregation. |
| `extract_tdt` | yes | `FX` | Retain as frequentist extraction layer; state bootstrap/profile method. |
| `fit_4pl` | yes | `FA` | Use synthetic or canonical permitted data; add experimental warning and fit checks. |
| `fit_tls` | yes | `FX` | Retain lower-level synthetic example and warning. |
| `format_interval` | yes | `CM` | Test formatting parity. |
| `freqTLS-package` | no | `FA` | Add site-independent experimental warning and bayesTLS cross-check links. |
| `get_ctmax` | yes | `FX` | Retain synthetic accessor example. |
| `get_shape` | yes | `FX` | Retain synthetic accessor example. |
| `get_z` | yes | `FX` | Retain synthetic accessor example. |
| `heat_injury_envelope` | yes | `EX` | Replace any empirical legacy input with synthetic data; label bootstrap pointwise band. |
| `make_4pl_formula` | yes | `FA` | Test shared core arguments; document inference-specific return difference. |
| `plot.profile_tls_profile` | yes | `FX` | Retain synthetic profile plot. |
| `plot_confidence_eye` | yes | `FX` | Retain synthetic example; never call lens a density. |
| `plot_heat_injury` | yes | `FA` | Retain synthetic frequentist analogue; ensure band method is explicit. |
| `plot_survival_curves` | yes | `FA` | Retain synthetic/canonical analogue with confidence language. |
| `plot_survival_surface` | yes | `FX` | Retain synthetic extension. |
| `plot_tdt_curve` | yes | `FA` | Retain synthetic/canonical analogue with threshold label. |
| `predict.profile_tls` | yes | `FX` | Retain synthetic lower-level prediction. |
| `predict_heat_injury` | yes | `FA` | Retain synthetic analogue; repair remains unfitted unless separately estimated. |
| `predict_survival_curves` | yes | `FA` | Retain and document frequentist uncertainty object. |
| `predict_survival_surface` | yes | `FX` | Retain synthetic extension. |
| `profile.profile_tls` | yes | `FX` | Retain synthetic example and open-profile behaviour. |
| `profile_tls-methods` | yes | `FX` | Retain synthetic S3 examples. |
| `ranef` | yes | `EX` | Retain synthetic limited-random-intercept example. |
| `shrimp_lethal` | no | `BL` | Runnable/public teaching example removed; keep benchmark-only data documentation out of discovery. |
| `shrimp_sublethal` | no | `BL` | Keep benchmark-only documentation out of discovery. |
| `simulate_tls` | yes | `FX` | Retain synthetic generator. |
| `snowgum_psii` | yes | `FA` | Retain the canonical Dark-versus-Light example with the non-commercial development-use boundary explicit. |
| `standardize_data` | yes | `CM` | Test count and proportion paths against pinned inputs/metadata. |
| `tdt-accessors` | yes | `FX` | Retain frequentist accessor examples. |
| `tdt_check_columns` | no | `CM` | Internal/shared validation semantics; keep out of primary reference grouping. |
| `tdt_format_random_effects` | no | `EX` | Internal experimental formula helper. |
| `tdt_parameter_table` | yes | `FA` | Test schema compatibility; document confidence vs credible fields. |
| `tdt_quantile` | yes | `CM` | Test exact parity. |
| `tdt_random_effect_variables` | no | `EX` | Internal experimental formula helper. |
| `tdt_resolve_time_multiplier` | no | `CM` | Test exact time-unit semantics. |
| `tdt_unit_to_minutes` | no | `CM` | Test exact time-unit semantics. |
| `tidy_parameters` | yes | `FX` | Retain synthetic tidy output. |
| `tls` | yes | `FA` | Use canonical permitted example; document different uncertainty object and never claim drop-in output identity. |
| `tls-diagnostics` | no | `FX` | Retain diagnostics documentation. |
| `tls_bf` | yes | `EX` | Retain experimental formula DSL example. |
| `tls_family` | yes | `EX` | Retain binomial, beta-binomial and Beta constructors; mark Beta experimental. |
| `ts_ci` | yes | `CM` | Test common two-stage calculation and uncertainty convention. |
| `ts_curve` | yes | `CM` | Test common two-stage curve. |
| `ts_stage1` | yes | `CM` | Test common two-stage inputs/outputs. |
| `ts_stage2` | yes | `CM` | Test common two-stage `t_ref`/unit transformation. |
| `zebrafish_lethal` | no | `BL` | Keep benchmark-only documentation out of discovery; never use as the zebrafish case. |
| `zebrafish_o2` | yes | `CM` | Replace example with diploid normoxia/hyperoxia specification and `lethal = FALSE`. |

Reference totals: **57/57 topics and 46/46 example blocks classified**.

### Exported-function crosswalk

The pinned packages share **21** exported names:
`clock_to_minutes`, `diagnose_tdt_fit`, `fit_4pl`, `format_interval`,
`make_4pl_formula`, `plot_heat_injury`, `plot_survival_curves`, `plot_tdt_curve`,
`predict_heat_injury`, `predict_survival_curves`, `standardize_data`,
`tdt_parameter_table`, `tdt_quantile`, `tls`, `tls_ctmax`, `tls_tcrit`, `tls_z`,
`ts_ci`, `ts_curve`, `ts_stage1`, and `ts_stage2`.

The **26 freqTLS-only exports** are `beta_binomial_tls`, `beta_tls`,
`binomial_tls`, `check_tls`, `derive_ctmax`, `derive_lt`, `derive_tcrit`,
`extract_tdt`, `fit_tls`, the nine `get_*` accessors, `heat_injury_envelope`,
`plot_confidence_eye`, `plot_survival_surface`, `predict_survival_surface`,
`ranef`, `simulate_tls`, `tidy_parameters`, and `tls_bf`. These are `FX` or
`EX`; they stay outside claims of exact shared-API compatibility.

The **22 bayesTLS-only exports** are `bayes_R2_tls`, `derive_tdt_curve`,
`derive_tdt_landscape`, `derive_temperature_for_duration`, `derive_z`,
`extract_4pl_pars`, `get_4pl_est`, `get_brmsfit`, `get_hi_draws`,
`get_surv_draws`, `get_tls_est`, `has_fit`, `make_4pl_priors`,
`make_temperature_scenarios`, `planted_dose_from_trace`, `plot_repair_rate`,
`plot_tdt_landscape`, `plot_temperature_density`,
`plot_temperature_scenarios`, `repair_rate_schoolfield`,
`summarise_observed_survival`, and `theme_tdt`. They are `UB` unless a distinct
freqTLS analogue is documented; missing posterior accessors must not be mimicked
with confidence objects.

## Navigation and discovery inventory

| Surface | Current state | Class | Target check |
|---|---|---|---|
| Homepage bayesTLS link | GitHub only | `RM` | Link both the public supplement and repository. |
| Article navbar: Get started | `freqTLS` | `FA` | Retain. |
| Article navbar: Model details | math, profile, random effects | `FX/EX` | Retain, with random effects labelled experimental. |
| Article navbar: Comparison | comparison plus philosophy | `RM` | Rebuilt canonical comparison plus frequentist extension. |
| Article navbar: Applications | shrimp-based heat injury | `RM` | Synthetic/authorized aphid extension only. |
| Article navbar: Case studies | shrimp, zebrafish, aphids, Drosophila, stale summary | `RM` | Exact order: zebrafish oxygen; aphids; Snow gum; Drosophila Case 4; Drosophila Case 4.2; canonical summary. No shrimp or life-stage zebrafish. |
| Reference: twin API | blanket “bayesTLS-style twin API” | `RM` | Rename shared workflow; link compatibility matrix; no drop-in claim. |
| Reference: engine/profile/prediction/simulation/utilities | active freqTLS capabilities | `FX/EX` | Retain; mark experimental components. |
| Reference: Data | includes three legacy objects, omits Snow gum | `RM` | Canonical public data: aphid, Snow gum, oxygen zebrafish, Drosophila. Legacy data excluded from active navigation/discovery. |
| `search.json` | generated before post-build filtering | `RM` | Post-build remove legacy article/data URLs and internal governance URLs; fail if forbidden terms/URLs survive. |
| `sitemap.xml` | generated before post-build filtering | `RM` | Remove legacy/internal URLs and assert canonical article URLs exist once. |
| `llms.txt` | generated discovery file, only internal-page guard exists | `RM` | Add the same legacy/internal/canonical assertions used for search and sitemap. |
| Old article URLs | `articles/case-study-shrimp.html` active | `BL` | Unindexed legacy notice or redirect; never a current teaching page. |
| Canonical intended URLs | Snow gum and Case 4.2 were absent | `CM`/`FA` | Added and asserted `case-study-snowgum.html` and `case-study-suzukii-coma.html`; both are present in clean rendered output. |

## Cache and raw-data inventory

| File | Class | Required disposition |
|---|---|---|
| `canonical_bayesTLS_cache.rds` | `CM` / `FA` | Built on Totoro from pinned bayesTLS commit `76510412`, independently published by reviewed SHA-256, and consumed by the active comparison. It records all six locked units, exact hashes/formulas/thresholds/versions/seeds and passing diagnostics. Snow-gum is the locked shared-shape analogue; mortality preserves the absolute-versus-relative estimand boundary. |
| `bayesTLS_benchmark_cache.rds` | `BL` | Preserve internally for historical shrimp/life-stage regression tests; do not expose it as current parity evidence. |
| `benchmark_vs_bayes.rds` | `BL` | Remove from active pages unless rebuilt from canonical permitted cases. |
| `case_study_summary_cache.rds` | `RM` | Rebuild for the five canonical endpoints and retain endpoint/threshold/`t_ref` fields. |
| `beta_binomial_phi_results.rds` | `FX` | Retain performance extension; do not treat as empirical parity evidence. |
| `calibration_results.rds` | `FX` | Retain frequentist validation extension with provenance. |
| `coverage_results.rds` | `FX` | Retain frequentist validation extension with provenance. |
| `performance_results.rds` | `FX` | Retain frequentist validation extension with provenance. |
| `re_recovery_results.rds` | `EX` | Retain experimental random-effect validation with provenance. |
| `timing_results.rds` | `FX` | Retain frequentist benchmark with provenance. |
| `data_lethal_TDT_aphid.csv` | `CM` | Retain; hash and verify against packaged object build. |
| `data_lethal_TDT_zebrafish_oxygen.csv` | `CM` | Retain; hash and verify against packaged object build. |
| `data_multitrait_TDT_drosophila_suzukii.csv` | `CM` | Retain; hash and verify against packaged object build. |
| `data_lethal_TDT_brown_shrimp.csv` | `BL` | Retain maintainer/benchmark only; no public teaching/discovery. |
| `data_sublethal_TDT_brown_shrimp.csv` | `BL` | Retain maintainer/benchmark only; no public teaching/discovery. |
| `data_lethal_TDT_zebrafish.csv` | `BL` | Retain maintainer/benchmark only; no public teaching/discovery. |
| Snow gum processed object | absent at audit start | `FA` | Installed byte-identically with provenance for non-commercial GitHub/pkgdown use; raw sources remain build-excluded and the broader grant remains required for CRAN/commercial/adaptation use. |

## Blockers and audit gates

1. **Snow gum has a split publication boundary.** The repository now archives
   the maintainer attestation covering the current non-commercial GitHub/pkgdown
   teaching use, so the processed object and public development page may ship.
   CRAN, commercial downstream use, and adaptations remain blocked until a
   broader written rights-holder grant is archived.
2. **Canonical freqTLS live fits are validated, with limitations visible.** The
   five primary fits and the all-age aphid extension now have deterministic
   subset/formula tests plus convergence, Hessian, and raw-gradient gates.
   Drosophila lower-asymptote uncertainty and the unstable absolute-LT50
   bootstrap are displayed rather than hidden. The reviewed Bayesian comparator
   cache now covers all six locked units; the public comparison reports actual
   differences and does not subtract unlike Drosophila mortality estimands.
3. **The Wuhan trace is not in the current freqTLS extdata inventory.** Its
   upstream source, licence, transformation and hash must pass the data licence
   ledger before the aphid field projection becomes active.
4. **Legacy discovery requires a generated-artifact gate.** Removing an article
   from `_pkgdown.yml` does not by itself remove its reference page, search
   entry, sitemap URL or stale deployed HTML. The site builder and deployment
   check must enforce the allowlist/denylist on rendered output.
5. **No exact drop-in API claim is supported by name overlap alone.** The 21
   shared exports require input/output tests; inference-dependent outputs must
   remain explicitly different even when their calls look similar.

## Closure statement

Baseline inventory is complete: **11/11 homepage sections, 9/9 homepage chunks,
12/12 articles, 81/81 article sections, 126/126 article chunks, 56/56 starting
Rd topics, 46/46 Rd example blocks, 47/47 exports, all packaged datasets, all
15 starting extdata files, and all navigation/search/sitemap/llms surfaces are
classified.** The added Snow-gum Rd topic and canonical comparator cache are
also classified, bringing the final tree to 57 Rd topics and 16 extdata files. New
surfaces are specified as target additions. There are no unclassified baseline
surfaces; the five blockers above are explicit implementation gates rather than
inventory gaps.
