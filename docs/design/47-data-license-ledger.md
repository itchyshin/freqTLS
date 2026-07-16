# Data Licence and Redistribution Ledger

This ledger is the CRAN release gate for every file under `data/` and
`inst/extdata/`. It records provenance at the component level because the
licence on an upstream package does not override a more specific licence on a
dataset. `SHIP` means the file may enter the CRAN source tarball with the stated
attribution. `BLOCK` means it must be excluded until the named condition is
resolved. Generated summaries inherit restrictions from their input data.

The release manager must regenerate this inventory from
`find data -maxdepth 1 -name '*.rda'` and `find inst/extdata -type f` before each
submission. Any unlisted file is a release blocker.

## Package datasets (`data/*.rda`)

| Component | Source | Rights holder | Licence / permission | Transformation | Package consumer | CRAN verdict |
| --- | --- | --- | --- | --- | --- | --- |
| `data/aphid_tdt.rda` | Li et al. (2023), Dryad `10.5061/dryad.mcvdnck4j`; source `inst/extdata/data_lethal_TDT_aphid.csv` | Li, Chen, Jorgensen, Overgaard, Renault, Colinet, and Ma | CC0 1.0; attribution requested as scholarly practice | Relabel species; type columns; derive heat/cold branch; no rows dropped | `data(aphid_tdt)` and aphid case study | **SHIP**; retain dataset citation |
| `data/dsuzukii.rda` | Orsted et al. (2024), Zenodo `10.5281/zenodo.10602268`; source `inst/extdata/data_multitrait_TDT_drosophila_suzukii.csv` | Orsted, Willot, Olsen, Kongsgaard, and Overgaard | CC BY 4.0 | Type and reorder columns; no rows dropped; retain `t_coma` and `prod` | mortality uses `dead`; awake/coma counts use `is.na(t_coma)`; censored-time and hurdle-productivity analyses remain unsupported | **SHIP** with attribution and change notice |
| `data/shrimp_lethal.rda` | `bayesTLS` source `inst/extdata/data_lethal_TDT_brown_shrimp.csv` | Brown-shrimp experiment contributors / `bayesTLS` distributors | `bayesTLS` package distribution is CC BY 4.0 | Select six columns; retain mortality as a proportion; counts are reconstructed downstream as `round(prop * N)` | internal legacy benchmark only | **SHIP** with `bayesTLS` attribution |
| `data/shrimp_sublethal.rda` | `bayesTLS` source `inst/extdata/data_sublethal_TDT_brown_shrimp.csv` | Brown-shrimp experiment contributors / `bayesTLS` distributors | `bayesTLS` package distribution is CC BY 4.0 | Drop excluded rows; parse clock times to elapsed minutes; select identifiers | documented package dataset | **SHIP** with `bayesTLS` attribution |
| `data/zebrafish_lethal.rda` | `bayesTLS` source `inst/extdata/data_lethal_TDT_zebrafish.csv` | Life-stage zebrafish experiment contributors / `bayesTLS` distributors | `bayesTLS` package distribution is CC BY 4.0 | Drop excluded trials; sum daily mortality columns; derive survivors; type life stage | internal legacy benchmark only | **SHIP** with `bayesTLS` attribution |
| `data/zebrafish_o2.rda` | Saruhashi et al. (2026), Zenodo `10.5281/zenodo.20075355`; source `inst/extdata/data_lethal_TDT_zebrafish_oxygen.csv` | Saruhashi and data contributors named by the deposit | CC BY 4.0 | Relabel ploidy and oxygen treatments; type and select columns; no rows dropped | oxygen-gradient case study | **SHIP** with attribution and change notice |
| `data/snowgum_psii.rda` | Arnold et al. (2026), `10.64898/2026.04.09.717599`; pinned-object SHA-256 `20fd38c0dca50e29723b409371d60146197064641c9b51c579cf926d21e89864` | Arnold et al.; Pieter A. Arnold is a freqTLS coauthor | CC BY-NC 4.0. On 2026-07-16 the maintainer recorded Pieter A. Arnold's agreement to the current non-commercial GitHub/pkgdown teaching use. This is not evidence of an unrestricted/commercial downstream grant. | Analysis-ready 394-row object copied byte-for-byte from the pinned bayesTLS supplement | Snow-gum PSII case study and exact-data tests | **DEVELOPMENT ONLY / CRAN BLOCK** until a written rights-holder grant explicitly covers CRAN, commercial downstream reuse, and adaptations, or the data are compatibly relicensed |

## Raw and derived external data (`inst/extdata/**`)

| Component | Source | Rights holder | Licence / permission | Transformation | Package consumer | CRAN verdict |
| --- | --- | --- | --- | --- | --- | --- |
| `inst/extdata/data_lethal_TDT_aphid.csv` | Li et al. (2023), Dryad `10.5061/dryad.mcvdnck4j` | Li et al. | CC0 1.0 | Vendored `surv.txt`-derived CSV; model-ready copy relabels/types columns | builds `data/aphid_tdt.rda` | **SHIP**; retain citation |
| `inst/extdata/data_lethal_TDT_brown_shrimp.csv` | `bayesTLS` Case Study 1 raw file | Brown-shrimp experiment contributors / `bayesTLS` distributors | `bayesTLS` package distribution is CC BY 4.0 | Vendored raw assay table; downstream column selection and count reconstruction are documented | builds `data/shrimp_lethal.rda` | **SHIP** with `bayesTLS` attribution |
| `inst/extdata/data_lethal_TDT_zebrafish.csv` | `bayesTLS` Case Study 2 raw file | Life-stage zebrafish experiment contributors / `bayesTLS` distributors | `bayesTLS` package distribution is CC BY 4.0 | Vendored daily survival sheet; downstream excluded-row removal and mortality aggregation | builds `data/zebrafish_lethal.rda` | **SHIP** with `bayesTLS` attribution |
| `inst/extdata/data_lethal_TDT_zebrafish_oxygen.csv` | Saruhashi et al. (2026), Zenodo `10.5281/zenodo.20075355` | Saruhashi and deposit contributors | CC BY 4.0 | Vendored source sheet; downstream relabelling and column selection | builds `data/zebrafish_o2.rda` | **SHIP** with attribution and change notice |
| `inst/extdata/data_multitrait_TDT_drosophila_suzukii.csv` | Orsted et al. (2024), Zenodo `10.5281/zenodo.10602268`, `all_data_long_R3.csv` | Orsted et al. | CC BY 4.0 | Vendored long-form source; downstream type/order normalization | builds `data/dsuzukii.rda`; mortality and aggregated awake/coma count analyses are active, while censored-time and hurdle-productivity analyses are unsupported | **SHIP** with attribution and change notice |
| `inst/extdata/data_sublethal_TDT_brown_shrimp.csv` | `bayesTLS` Case Study 1 sublethal raw file | Brown-shrimp experiment contributors / `bayesTLS` distributors | `bayesTLS` package distribution is CC BY 4.0 | Vendored raw clock-time records; downstream exclusions and elapsed-time conversion | builds `data/shrimp_sublethal.rda` | **SHIP** with `bayesTLS` attribution |

## Maintainer-generated result caches (`inst/extdata/*.rds`)

| Component | Source | Rights holder | Licence / permission | Transformation | Package consumer | CRAN verdict |
| --- | --- | --- | --- | --- | --- | --- |
| `inst/extdata/canonical_bayesTLS_cache.rds` | Totoro refits of the six locked canonical analysis units using bayesTLS 1.0.0 at commit `76510412e06c594c96894a1baba1f0e1a34a5aea`; published-file SHA-256 `3b04bb161250abb1628e3018ff25648984b7c6a4131272e6e9c0557b15c3b2f0` | freqTLS maintainers for the compilation; source-data holders retain rights in inputs | Package licence plus each input's terms; Snow-gum rows inherit CC BY-NC 4.0 and the recorded non-commercial GitHub/pkgdown authorization | Curated posterior medians, intervals, provenance and diagnostics only; raw fits remain local | active `comparing-to-bayesTLS` article and cache-integrity tests | **DEVELOPMENT ONLY / CRAN BLOCK** with the Snow-gum component until the broader written grant is archived |
| `inst/extdata/bayesTLS_benchmark_cache.rds` | Historical maintainer fits to shrimp, life-stage zebrafish, and *D. suzukii* using `bayesTLS` 1.0.0 at commit `578740f20f3a2e6e81b3b700b1d0f0e5a06ecf8a`, CmdStan 2.36.0, and the classical comparator | freqTLS maintainers for the compilation; source-data holders retain rights in inputs | Package licence plus the source-specific licences of the retained datasets | Versioned historical summaries and diagnostics | internal legacy benchmark tests only; not an active comparison or teaching cache | **SHIP** with retained dataset attribution |
| `inst/extdata/case_study_summary_cache.rds` | Historical `data-raw/build_case_study_summary_cache.R` fits to shrimp, life-stage zebrafish, and *D. suzukii* | freqTLS maintainers for the compilation; source-data holders retain rights in inputs | Package licence plus the source-specific CC BY 4.0 licences | Version-stamped historical profile/contrast rows | internal legacy integrity test only; no active summary page consumes it | **SHIP** with retained dataset attribution |
| `inst/extdata/benchmark_vs_bayes.rds` | `data-raw/benchmark-vs-bayes.R`; brown-shrimp three-estimator comparison | freqTLS maintainers; shrimp source attribution retained | Package licence plus upstream shrimp CC BY 4.0 | Store point estimates and pairwise differences | `vignettes/frequentist-and-bayesian.Rmd` | **SHIP** with upstream attribution |
| `inst/extdata/beta_binomial_phi_results.rds` | `data-raw/beta-binomial-phi-study.R`; simulated parameter-recovery study | freqTLS maintainers | GPL (>= 3) as package-generated evidence | Aggregate simulated coverage and dispersion summaries with metadata | `vignettes/comparing-to-bayesTLS.Rmd` | **SHIP** |
| `inst/extdata/calibration_results.rds` | `data-raw/calibration-study.R`; simulated calibration study | freqTLS maintainers | GPL (>= 3) as package-generated evidence | Aggregate coverage/width results by calibration cell | `vignettes/frequentist-and-bayesian.Rmd` | **SHIP** |
| `inst/extdata/coverage_results.rds` | `data-raw/coverage-study.R`; simulated profile-likelihood coverage study | freqTLS maintainers | GPL (>= 3) as package-generated evidence | Store metadata, coverage summaries, and available raw simulation results | `vignettes/profile-likelihood.Rmd` | **SHIP** |
| `inst/extdata/performance_results.rds` | `data-raw/performance-study.R`; simulated speed, accuracy, and coverage study | freqTLS maintainers | GPL (>= 3) as package-generated evidence | Aggregate timing, bias/RMSE, and interval coverage with metadata | `vignettes/comparing-to-bayesTLS.Rmd` | **SHIP** |
| `inst/extdata/re_recovery_results.rds` | `data-raw/re-recovery-study.R`; simulated random-effect recovery study | freqTLS maintainers | GPL (>= 3) as package-generated evidence | Aggregate recovery across numbers of grouping levels with metadata | `vignettes/random-effects.Rmd` | **SHIP** |
| `inst/extdata/timing_results.rds` | `data-raw/timing-study.R`; brown-shrimp timing comparison | freqTLS maintainers; shrimp source attribution retained | Package licence plus upstream shrimp CC BY 4.0 | Store maintainer-machine wall-clock summaries and metadata | internal legacy benchmark only; no active comparison consumes it | **SHIP** with upstream attribution |

## Build-excluded licensing-pending material

| Component | Source and terms | Release treatment |
| --- | --- | --- |
| `data-raw/licensing-pending/snowgum/snowgum_psii.rda` | Source/provenance copy of the installed development object; Arnold et al. (2026), `10.64898/2026.04.09.717599`; **CC BY-NC 4.0** | Current GitHub/pkgdown teaching use is covered by the maintainer attestation; CRAN and unrestricted/commercial downstream redistribution remain blocked. |
| `data-raw/licensing-pending/snowgum/data_function_PSII_TDT_snowgum.csv` | Arnold et al. (2026), Experiment 1; **CC BY-NC 4.0** | Not installed or consumed by package code. |
| `data-raw/licensing-pending/snowgum/data_function_PSII_TDT_snowgum_glasshouse.csv` | Exact file-level holder statement and standalone grant not recorded; conservatively treated under the snow-gum restriction | Not installed; provenance and compatible permission are required before use. |
| `data-raw/licensing-pending/snowgum/case-study-leaf-psii.Rmd` | Analysis source derived from the restricted snow-gum data | Not built or linked by pkgdown. |
| `data-raw/licensing-pending/kristineberg/kristineberg_sea_temp_hourly.csv.gz` | University of Gothenburg / Sven Loven Centre; no explicit redistribution licence found | Not installed; written redistribution terms required before restoration. |
| `data-raw/licensing-pending/kristineberg/README.md` | Maintainer provenance note for the adjacent extract | Retained with the blocked data, outside the package build. |
| `data-raw/licensing-pending/environmental-traces/data_temp_trace_aphid_summer2016.csv` | Open-Meteo Historical Weather API / ERA5-derived extract; a complete primary redistribution chain for every underlying provider was not recorded | Not installed or consumed; compatible primary terms or written permission are required before restoration. |
| `data-raw/licensing-pending/environmental-traces/orsted_2024/orsted2024_nichemapr_rennes_2018_hourly.csv.gz` | Orsted et al. (2024) Zenodo `10.5281/zenodo.10821572` NicheMapR/NCEP-derived output; the workflow licence does not alone establish redistribution authority for the derived environmental values | Not installed or consumed; compatible underlying-data terms or written permission are required before restoration. |

## Closed packaging actions

1. Snow-gum raw files remain in the build-excluded licensing-pending tree. The
   byte-identical processed object is installed only in the experimental
   development branch for the approved non-commercial GitHub/pkgdown teaching
   use. CRAN remains blocked until the broader written grant is archived.
2. `inst/extdata/bayesTLS_benchmark_cache.rds` was freshly rebuilt without
   snow-gum inputs against the pinned bayesTLS commit recorded above; its
   `freqTLS_note` states the retained scope and comparison contract.
3. The Kristineberg extract and provenance note were moved to the same
   build-excluded tree.
4. The two unused environmental traces were moved out of `inst/extdata/` because
   their complete underlying-data redistribution chains were not established.
5. The final source-tarball inventory must confirm that no build-excluded raw
   path is included. The installed `data/snowgum_psii.rda` is the deliberate,
   documented exception for the current non-commercial development site.

The release manager should preserve copies outside the CRAN package if these
materials are needed for private validation or manuscript reproduction. Their
exclusion is a packaging decision, not deletion of research provenance.
