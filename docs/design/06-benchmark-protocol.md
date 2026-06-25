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
- **snow-gum PSII** (`snowgum_psii`, ungrouped, **continuous proportion**):
  `temp = temp`, `duration = duration` (minutes), `proportion = prop`,
  `tref = 5` minutes, **beta** family. A continuous proportion has no count
  denominator, so the classical two-stage path does not apply; this dataset is a
  two-way `bayesTLS` (beta) vs `freqTLS` comparison.

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
*D. suzukii*, minutes/`tref = 5` for snow-gum). The classical two-stage estimates
the absolute LT50 by construction; for the near-0/near-1 lethal asymptotes of the
count datasets the relative midpoint and the absolute LT50 coincide. A fairness
footnote states this.

## Cache and provenance (R-STALE)

Stan will not run on CI, so the benchmark reads a maintainer-built cache at
`inst/extdata/bayesTLS_benchmark_cache.rds` (summaries plus a `meta` block:
`bayesTLS_version`, `git_sha`, `cmdstan_version`, `date_built`, `seed`, the
configuration, and the R-SHRIMP note). `data-raw/build_benchmark_cache.R` is the
maintainer-run builder. The vignette `vignettes/comparing-to-bayesTLS.Rmd` shows
the live bayesTLS calls with `eval = FALSE`, reads the cache with `eval = TRUE`,
runs freqTLS live, and prints the provenance. `test-benchmark-sanity` is a
tripwire that checks the cached numbers against a live freqTLS fit within a
loose tolerance, and a one-command regeneration path keeps the cache current.

## Licence (R-LICENSE)

The vendored data is CC BY 4.0. Attribution lives in `R/data.R` (`@source`),
`inst/CITATION` (a freqTLS plus bayesTLS bibentry), and the README; freqTLS
code is GPL-3, with provenance in `inst/COPYRIGHTS`.
