# Component rights ledger — experimental 0.1.0

Status: **source-tarball rights audit passed; not submission clearance**  
Date: 2026-07-16  
Scope: files that could enter the source tarball after `.Rbuildignore` is applied.

`freqTLS` code is GPL (>= 3). That licence does not replace a separately
licensed data component. This ledger is the authoritative release-audit record;
`inst/COPYRIGHTS`, `inst/CITATION`, data help, and the public articles point back
to it. `SHIP` means the recorded evidence supports retaining the component;
`EXCLUDED` means `.Rbuildignore` removes it; `BLOCKED` means it is still in the
working source tree but cannot be part of a CRAN candidate until its
redistribution basis is documented or the component and its reader surface are
removed.

| Component(s) | Source / holder | Licence or permission evidence | Transformation | Consumer(s) | Disposition |
|---|---|---|---|---|---|
| `data/aphid_tdt.rda`; `inst/extdata/data_lethal_TDT_aphid.csv` | Li et al. (2023), Dryad record named in `?aphid_tdt` | CC0 stated in data help | analysis-ready `.rda` from raw CSV | aphid help and case study | SHIP |
| `data/dsuzukii.rda`; `inst/extdata/data_multitrait_TDT_drosophila_suzukii.csv` | Ørsted et al. (2024), Zenodo 10.5281/zenodo.10602268 | CC BY 4.0 stated in data help | analysis-ready `.rda` from raw CSV | fly help, case study, benchmark cache | SHIP |
| `data/zebrafish_o2.rda`; `inst/extdata/data_lethal_TDT_zebrafish_oxygen.csv` | Saruhashi et al. (2026), Zenodo 10.5281/zenodo.20075355 | CC BY 4.0 stated in data help | analysis-ready `.rda` from raw CSV | oxygen-gradient help and case study | SHIP |
| `data/snowgum_psii.rda`; `inst/extdata/data_function_PSII_TDT_snowgum.csv`; `data_function_PSII_TDT_snowgum_glasshouse.csv` | Arnold et al. (2026), bioRxiv 10.64898/2026.04.09.717599, Experiment 1 | **CC BY-NC 4.0** stated in data help | exclude two post/pre rows above 1; `fvfm_prop = final_fvfm / initial_fvfm` | data help, leaf-PSII case study, beta example, cache | SHIP — retain attribution and CC BY-NC notice |
| `data/shrimp_lethal.rda`; `inst/extdata/data_lethal_TDT_brown_shrimp.csv` | bayesTLS 1.0.0 distribution | bayesTLS DESCRIPTION declares CC BY 4.0; upstream HEAD resolved 2026-07-16 as `76510412e06c594c96894a1baba1f0e1a34a5aea` | `.rda` retains source proportions; fit reconstructs deaths as `round(prop * total)` | shrimp case study, heat injury, comparison, cache | SHIP — retain bayesTLS attribution and CC BY 4.0 notice |
| `data/shrimp_sublethal.rda`; `inst/extdata/data_sublethal_TDT_brown_shrimp.csv` | bayesTLS 1.0.0 distribution | bayesTLS DESCRIPTION declares CC BY 4.0; upstream HEAD resolved 2026-07-16 as `76510412e06c594c96894a1baba1f0e1a34a5aea` | cleaned clock-time records | data help and case-study summary | SHIP — retain bayesTLS attribution and CC BY 4.0 notice |
| `data/zebrafish_lethal.rda`; `inst/extdata/data_lethal_TDT_zebrafish.csv` | bayesTLS 1.0.0 distribution | bayesTLS DESCRIPTION declares CC BY 4.0; upstream HEAD resolved 2026-07-16 as `76510412e06c594c96894a1baba1f0e1a34a5aea` | daily records aggregated to trial-level survival | zebrafish case study, comparison, cache | SHIP — retain bayesTLS attribution and CC BY 4.0 notice |
| `inst/extdata/bayesTLS_benchmark_cache.rds` | maintainer-built from listed datasets, bayesTLS 1.0.0, CmdStan 2.36.0 | derivative data; input rights above; cache metadata records `git_sha = "unknown"` | benchmark summaries | comparison and case-study articles, benchmark test | SHIP for the stated versioned comparison; **REPRODUCIBILITY NOTE** — rebuild with an exact upstream SHA before making a stronger regeneration claim |
| `inst/extdata/benchmark_vs_bayes.rds` | freqTLS maintainers | generated from CC BY 4.0 bayesTLS inputs; `data-raw/benchmark-vs-bayes.R` uses Stan seed 1 | three-estimator summary | frequentist/Bayesian article | SHIP — retain script and bayesTLS attribution |
| `inst/extdata/beta_binomial_phi_results.rds` | freqTLS maintainers | pure simulation; `data-raw/beta-binomial-phi-study.R`; metadata: 2026-06-18, 120 simulations, 149 bootstrap draws | coverage summary across phi values | comparison article | SHIP |
| `inst/extdata/calibration_results.rds` | freqTLS maintainers | pure simulation; `data-raw/calibration-study.R` | small-sample calibration summary | frequentist/Bayesian article | SHIP |
| `inst/extdata/coverage_results.rds` | freqTLS maintainers | pure simulation; `data-raw/coverage-study.R`; metadata: seed 20260616, 200 simulations | profile-interval coverage summary | profile article | SHIP |
| `inst/extdata/performance_results.rds` | freqTLS maintainers | pure simulation; `data-raw/performance-study.R`; metadata records seeds 20260601/20260602/20260616 and 300 simulations per accuracy/coverage arm | speed, recovery, and coverage summaries | comparison article | SHIP |
| `inst/extdata/re_recovery_results.rds` | freqTLS maintainers | pure simulation; `data-raw/re-recovery-study.R`; metadata: 2026-06-18, 150 simulations, explicit seeded group-recovery design | random-intercept recovery summary | random-effects article | SHIP |
| `inst/extdata/timing_results.rds` | freqTLS maintainers | maintainer timing run; `data-raw/timing-study.R`; metadata: bayesTLS 1.0.0, CmdStan 2.36.0, seed 123 | comparator wall-clock summary | comparison article | SHIP — descriptive timing only, not a portable performance claim |
| `inst/extdata/data_temp_trace_aphid_summer2016.csv` | external temperature trace | no redistribution licence recorded | raw trace | no installed-package consumer found | EXCLUDED |
| `inst/extdata/kristineberg/*` | Kristineberg technical administrator | bundled README asks users to contact administrator before publication; no redistribution licence | raw sea-temperature trace | no installed-package consumer found | EXCLUDED |
| `inst/extdata/orsted_2024/*` | external temperature trace | no redistribution licence recorded | raw trace | no installed-package consumer found | EXCLUDED |
| `man/figures/*.png`; `vignettes/freqTLS_function_map.svg` | freqTLS maintainers | package-generated outputs | generated from package examples/source SVG | reference pages and get-started article | SHIP |
| adapted code and Confidence-Eye geometry | drmTMB and gllvmTMB, GPL-compatible sources named in `inst/COPYRIGHTS` | GPL provenance recorded | adapted implementation / geometry only | TMB engine and plotting | SHIP |

## Candidate consequence

The exclusions above are enforced in `.Rbuildignore` and were absent from the
210-entry full-vignette source tarball recorded in the exact-artifact ledger.
The ledger supports retaining the listed components under their recorded source
terms. The cache's unknown upstream SHA is a reproducibility limitation: it
does not change the stated bayesTLS version or the component's distribution
terms, but it must be repaired before claiming an exactly reproducible cache
rebuild.
