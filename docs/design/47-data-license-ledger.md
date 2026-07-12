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
| `data/dsuzukii.rda` | Orsted et al. (2024), Zenodo `10.5281/zenodo.10602268`; source `inst/extdata/data_multitrait_TDT_drosophila_suzukii.csv` | Orsted, Willot, Olsen, Kongsgaard, and Overgaard | CC BY 4.0 | Type and reorder columns; no rows dropped; retain `t_coma` and `prod` for provenance and study context, not as valid freqTLS responses | lethal-response benchmark and *D. suzukii* case study use only `dead` | **SHIP** with attribution and change notice |
| `data/shrimp_lethal.rda` | `bayesTLS` source `inst/extdata/data_lethal_TDT_brown_shrimp.csv` | Brown-shrimp experiment contributors / `bayesTLS` distributors | `bayesTLS` package distribution is CC BY 4.0 | Select six columns; retain mortality as a proportion; counts are reconstructed downstream as `round(prop * N)` | shrimp benchmark, heat-injury, and case-study vignettes | **SHIP** with `bayesTLS` attribution |
| `data/shrimp_sublethal.rda` | `bayesTLS` source `inst/extdata/data_sublethal_TDT_brown_shrimp.csv` | Brown-shrimp experiment contributors / `bayesTLS` distributors | `bayesTLS` package distribution is CC BY 4.0 | Drop excluded rows; parse clock times to elapsed minutes; select identifiers | documented package dataset | **SHIP** with `bayesTLS` attribution |
| `data/zebrafish_lethal.rda` | `bayesTLS` source `inst/extdata/data_lethal_TDT_zebrafish.csv` | Life-stage zebrafish experiment contributors / `bayesTLS` distributors | `bayesTLS` package distribution is CC BY 4.0 | Drop excluded trials; sum daily mortality columns; derive survivors; type life stage | grouped benchmark and case-study vignettes | **SHIP** with `bayesTLS` attribution |
| `data/zebrafish_o2.rda` | Saruhashi et al. (2026), Zenodo `10.5281/zenodo.20075355`; source `inst/extdata/data_lethal_TDT_zebrafish_oxygen.csv` | Saruhashi and data contributors named by the deposit | CC BY 4.0 | Relabel ploidy and oxygen treatments; type and select columns; no rows dropped | oxygen-gradient case study | **SHIP** with attribution and change notice |

## Raw and derived external data (`inst/extdata/**`)

| Component | Source | Rights holder | Licence / permission | Transformation | Package consumer | CRAN verdict |
| --- | --- | --- | --- | --- | --- | --- |
| `inst/extdata/data_lethal_TDT_aphid.csv` | Li et al. (2023), Dryad `10.5061/dryad.mcvdnck4j` | Li et al. | CC0 1.0 | Vendored `surv.txt`-derived CSV; model-ready copy relabels/types columns | builds `data/aphid_tdt.rda` | **SHIP**; retain citation |
| `inst/extdata/data_lethal_TDT_brown_shrimp.csv` | `bayesTLS` Case Study 1 raw file | Brown-shrimp experiment contributors / `bayesTLS` distributors | `bayesTLS` package distribution is CC BY 4.0 | Vendored raw assay table; downstream column selection and count reconstruction are documented | builds `data/shrimp_lethal.rda` | **SHIP** with `bayesTLS` attribution |
| `inst/extdata/data_lethal_TDT_zebrafish.csv` | `bayesTLS` Case Study 2 raw file | Life-stage zebrafish experiment contributors / `bayesTLS` distributors | `bayesTLS` package distribution is CC BY 4.0 | Vendored daily survival sheet; downstream excluded-row removal and mortality aggregation | builds `data/zebrafish_lethal.rda` | **SHIP** with `bayesTLS` attribution |
| `inst/extdata/data_lethal_TDT_zebrafish_oxygen.csv` | Saruhashi et al. (2026), Zenodo `10.5281/zenodo.20075355` | Saruhashi and deposit contributors | CC BY 4.0 | Vendored source sheet; downstream relabelling and column selection | builds `data/zebrafish_o2.rda` | **SHIP** with attribution and change notice |
| `inst/extdata/data_multitrait_TDT_drosophila_suzukii.csv` | Orsted et al. (2024), Zenodo `10.5281/zenodo.10602268`, `all_data_long_R3.csv` | Orsted et al. | CC BY 4.0 | Vendored long-form source; downstream type/order normalization; `t_coma` and `prod` are retained for provenance/context only | builds `data/dsuzukii.rda`; freqTLS analyses consume only the lethal `dead` response | **SHIP** with attribution and change notice |
| `inst/extdata/data_sublethal_TDT_brown_shrimp.csv` | `bayesTLS` Case Study 1 sublethal raw file | Brown-shrimp experiment contributors / `bayesTLS` distributors | `bayesTLS` package distribution is CC BY 4.0 | Vendored raw clock-time records; downstream exclusions and elapsed-time conversion | builds `data/shrimp_sublethal.rda` | **SHIP** with `bayesTLS` attribution |
| `inst/extdata/data_temp_trace_aphid_summer2016.csv` | Open-Meteo Historical Weather API, ERA5 reanalysis | Open-Meteo and underlying Copernicus data providers | CC BY 4.0; attribution and modification notice required | Select Wuhan, Xinxiang, and Beijing; 2016-05-01 through 2016-08-31; retain hourly 2 m temperature; add hours from series start | aphid heat-injury source trace | **SHIP**; attribution and transformation are recorded in `inst/COPYRIGHTS` and this ledger |
| `inst/extdata/orsted_2024/orsted2024_nichemapr_rennes_2018_hourly.csv.gz` | Orsted et al. (2024) Zenodo `10.5281/zenodo.10821572`, `microclimate_injury_accumulation.R`; NicheMapR/NCEP workflow | Orsted et al. and underlying model-data providers | Zenodo record is CC BY 4.0 | Regenerate Rennes 2018 `micro_ncep` output and retain documented hourly air/microclimate columns plus coordinates/source | *D. suzukii* field-temperature scenario source | **SHIP** with attribution and change notice |

## Maintainer-generated result caches (`inst/extdata/*.rds`)

| Component | Source | Rights holder | Licence / permission | Transformation | Package consumer | CRAN verdict |
| --- | --- | --- | --- | --- | --- | --- |
| `inst/extdata/bayesTLS_benchmark_cache.rds` | Maintainer fits to shrimp, zebrafish, and *D. suzukii* using `bayesTLS` 1.0.0 at commit `578740f20f3a2e6e81b3b700b1d0f0e5a06ecf8a`, CmdStan 2.36.0, and the classical comparator | freqTLS maintainers for the compilation; source-data holders retain rights in inputs | Package licence plus the source-specific licences of the three retained datasets | Fresh rebuild on 2026-07-11 containing posterior/two-stage summaries and `meta` fields for versions, pinned source, build/configuration, datasets, R-SHRIMP, and `freqTLS_note`; snow-gum inputs were excluded from the rebuild | benchmark tests and several case-study/comparison vignettes | **SHIP** with retained dataset attribution |
| `inst/extdata/benchmark_vs_bayes.rds` | `data-raw/benchmark-vs-bayes.R`; brown-shrimp three-estimator comparison | freqTLS maintainers; shrimp source attribution retained | Package licence plus upstream shrimp CC BY 4.0 | Store point estimates and pairwise differences | `vignettes/frequentist-and-bayesian.Rmd` | **SHIP** with upstream attribution |
| `inst/extdata/beta_binomial_phi_results.rds` | `data-raw/beta-binomial-phi-study.R`; simulated parameter-recovery study | freqTLS maintainers | GPL (>= 3) as package-generated evidence | Aggregate simulated coverage and dispersion summaries with metadata | `vignettes/comparing-to-bayesTLS.Rmd` | **SHIP** |
| `inst/extdata/calibration_results.rds` | `data-raw/calibration-study.R`; simulated calibration study | freqTLS maintainers | GPL (>= 3) as package-generated evidence | Aggregate coverage/width results by calibration cell | `vignettes/frequentist-and-bayesian.Rmd` | **SHIP** |
| `inst/extdata/coverage_results.rds` | `data-raw/coverage-study.R`; simulated profile-likelihood coverage study | freqTLS maintainers | GPL (>= 3) as package-generated evidence | Store metadata, coverage summaries, and available raw simulation results | `vignettes/profile-likelihood.Rmd` | **SHIP** |
| `inst/extdata/performance_results.rds` | `data-raw/performance-study.R`; simulated speed, accuracy, and coverage study | freqTLS maintainers | GPL (>= 3) as package-generated evidence | Aggregate timing, bias/RMSE, and interval coverage with metadata | `vignettes/comparing-to-bayesTLS.Rmd` | **SHIP** |
| `inst/extdata/re_recovery_results.rds` | `data-raw/re-recovery-study.R`; simulated random-effect recovery study | freqTLS maintainers | GPL (>= 3) as package-generated evidence | Aggregate recovery across numbers of grouping levels with metadata | `vignettes/random-effects.Rmd` | **SHIP** |
| `inst/extdata/timing_results.rds` | `data-raw/timing-study.R`; brown-shrimp timing comparison | freqTLS maintainers; shrimp source attribution retained | Package licence plus upstream shrimp CC BY 4.0 | Store maintainer-machine wall-clock summaries and metadata | `vignettes/comparing-to-bayesTLS.Rmd` | **SHIP** with upstream attribution |

## Build-excluded licensing-pending material

| Component | Source and terms | Release treatment |
| --- | --- | --- |
| `data-raw/licensing-pending/snowgum/snowgum_psii.rda` | Arnold et al. (2026), `10.64898/2026.04.09.717599`; **CC BY-NC 4.0** | Not installed; compatible written CRAN redistribution permission or relicensing is required before restoration. |
| `data-raw/licensing-pending/snowgum/data_function_PSII_TDT_snowgum.csv` | Arnold et al. (2026), Experiment 1; **CC BY-NC 4.0** | Not installed or consumed by package code. |
| `data-raw/licensing-pending/snowgum/data_function_PSII_TDT_snowgum_glasshouse.csv` | Exact file-level holder statement and standalone grant not recorded; conservatively treated under the snow-gum restriction | Not installed; provenance and compatible permission are required before use. |
| `data-raw/licensing-pending/snowgum/case-study-leaf-psii.Rmd` | Analysis source derived from the restricted snow-gum data | Not built or linked by pkgdown. |
| `data-raw/licensing-pending/kristineberg/kristineberg_sea_temp_hourly.csv.gz` | University of Gothenburg / Sven Loven Centre; no explicit redistribution licence found | Not installed; written redistribution terms required before restoration. |
| `data-raw/licensing-pending/kristineberg/README.md` | Maintainer provenance note for the adjacent extract | Retained with the blocked data, outside the package build. |

## Closed packaging actions

1. Snow-gum raw data, processed data, and the case-study source were moved to
   the build-excluded licensing-pending tree.
2. `inst/extdata/bayesTLS_benchmark_cache.rds` was freshly rebuilt without
   snow-gum inputs against the pinned bayesTLS commit recorded above; its
   `freqTLS_note` states the retained scope and comparison contract.
3. The Kristineberg extract and provenance note were moved to the same
   build-excluded tree.
4. The final source-tarball inventory must still confirm that none of these
   paths are included and that no installed vignette, test, or example loads
   them.

The release manager should preserve copies outside the CRAN package if these
materials are needed for private validation or manuscript reproduction. Their
exclusion is a packaging decision, not deletion of research provenance.
