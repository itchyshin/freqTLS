# Benchmark Protocol

freqTLS benchmarks itself against `bayesTLS` (Bayesian) and the classical
two-stage estimator on shared, vendored datasets. The benchmark must be fair and
reproducible without Stan in CI. The review checklist is the
`benchmark-vs-bayesTLS-audit` skill (Jason maps the comparator; Rose audits the
claims and provenance).

## Datasets and column mapping

freqTLS uses the column contract
`fit_tls(y = survived, n = total, time = duration, temp = temp, group = )`.

- **shrimp** (`shrimp_lethal`, ungrouped): `temp = Temperature_assay`,
  `duration = Duration_exposure_hours`, `total = N_individuals_after_trial`,
  `survived = N - round(Mortality_after_trial * N)`. The shrimp counts must be
  rebuilt from the CSV proportion (R-SHRIMP, below).
- **zebrafish** (`zebrafish_lethal`, grouped by life stage): `temp = assay_temp`,
  `duration = duration_h`, `total = n_total`, `survived = n_surv` (shipped
  correctly), `group = life_stage`.
- **D. suzukii** (`dsuzukii`, per-individual, grouped by sex): aggregate the 0/1
  `dead` indicator to `(temp, time, sex)` cells (`total = n()`,
  `survived = sum(dead == 0)`); then `temp = temp`, `duration = time` (minutes),
  `group = sex`, `tref = 240` minutes. Count data, so the full three-way applies.

## The R-SHRIMP data fix

The bayesTLS shipped `shrimp_lethal` death counts are corrupted upstream. The CSV
column `Mortality_after_trial` is a **proportion** (for example `0.0909 = 1/11`,
`0.5 = 5/10`), but the upstream `make_datasets.R:25` mislabels it a death count
and `:34` applies `as.integer(...)`, which floors proportions below 1 to 0, so the
shipped death counts collapse to nearly all zero. freqTLS sidesteps this by
vendoring the **raw CSV proportion** (`Mortality_after_trial`) together with
`N_individuals_after_trial`, rather than any baked-in counts;
`standardize_data(mortality = "Mortality_after_trial")` then rebuilds the death
counts as `round(prop * N)` (hence `survived = N - round(prop * N)`) at fit time.
`R/data.R` documents the vendored proportion, and the vendored `.rda` is verified
against the CSV before finalising.

## Three-way comparison (no reimplementation)

freqTLS does not reimplement the comparators; it calls bayesTLS:

- classical two-stage: `bayesTLS::ts_stage1 -> ts_stage2 -> ts_ci`;
- Bayesian: `bayesTLS::fit_4pl(temp_effects = "mid") ->
  extract_tdt(target_surv = "relative")` -- the fair configuration;
- freqTLS: `fit_tls() -> confint(method = "profile")`.

The comparison reports point estimates plus CI width and asymmetry; zebrafish is a
3x3 per life stage and *D. suzukii* a 3x2 per sex. The interval-bearing model fits
(`bayesTLS` posterior, `freqTLS` profile) are locked to the **relative**
midpoint threshold (R-RELABS) -- which is the `freqTLS` `CTmax` parameter -- and
the **constant-shape** model, with the time unit and `tref` matched per dataset
(R-UNITS: hours/`tref = 1` for shrimp and zebrafish, minutes/`tref = 240` for
*D. suzukii*). The classical two-stage estimates
the absolute LT50 by construction; for the near-0/near-1 lethal asymptotes of the
count datasets the relative midpoint and the absolute LT50 are close. A fairness
footnote states this.

## Cache and provenance (R-STALE)

Stan will not run on CI, so the benchmark reads a maintainer-built cache at
`inst/extdata/bayesTLS_benchmark_cache.rds` (summaries plus a `meta` block:
`bayesTLS_version`, `git_sha`, `source_url`, `cmdstan_version`, `date_built`,
`seed`, `config`, `datasets`, `rshrimp_note`, and `freqTLS_note`).
`data-raw/build_benchmark_cache.R` is the
maintainer-run builder. It requires a pinned `bayesTLS` checkout (or verified
`BAYESTLS_GIT_SHA`) and stops rather than writing a cache with an unknown commit.
The vignette `vignettes/comparing-to-bayesTLS.Rmd` shows
the live bayesTLS calls with `eval = FALSE`, reads the cache with `eval = TRUE`,
runs freqTLS live, and prints the provenance. `test-benchmark-sanity` is a
tripwire that checks the cached numbers against a live freqTLS fit within a
loose tolerance, and a one-command regeneration path keeps the cache current.
The release cache was freshly rebuilt on 2026-07-11 against `bayesTLS` 1.0.0 at
commit `578740f20f3a2e6e81b3b700b1d0f0e5a06ecf8a`, using CmdStan 2.36.0. It
contains only shrimp, zebrafish, and *D. suzukii* summaries; permission-pending
snow-gum material was excluded at build time. The `freqTLS_note` records that
freqTLS is fitted live and explains the matched model configuration and the
classical comparator's threshold difference. A future rebuild must retain the
snow-gum exclusion unless compatible written permission is recorded; a
numerical summary is not licence-independent merely because it no longer
contains the input rows.

## Licence (R-LICENSE)

Licensing is component-specific; `docs/design/47-data-license-ledger.md` is the
release gate. Brown-shrimp and life-stage zebrafish files were obtained from the
CC BY 4.0 `bayesTLS` distribution. The *D. suzukii* data and its regenerated
microclimate workflow are CC BY 4.0, and the aphid data are CC0. The snow-gum
source is **CC BY-NC 4.0**, not CC BY 4.0. Written permission or compatible
relicensing for unrestricted CRAN redistribution is pending, so the snow-gum
raw files, derived dataset, and case-study vignette are retained under the
build-excluded `data-raw/licensing-pending/` tree. Attribution alone does not
cure a non-commercial or missing-licence restriction.
