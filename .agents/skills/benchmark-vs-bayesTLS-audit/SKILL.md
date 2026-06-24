---
name: benchmark-vs-bayesTLS-audit
description: Audit the freqTLS-versus-bayesTLS benchmark for a fair configuration, sound cache provenance, and the correct R-SHRIMP data rebuild.
---

# Benchmark vs bayesTLS Audit

Use this skill for any change to `data-raw/make_benchmark_data.R`,
`data-raw/build_benchmark_cache.R`, the vendored datasets, `R/data.R`, or the
`comparing-to-bayesTLS` vignette. Jason maps the comparator; Rose audits the
claims and provenance.

## Fair-Configuration Gate (R-RELABS)

The three-way comparison must lock all estimators to the **relative** mortality
threshold and the **constant-shape** configuration so the comparison is fair:

- classical two-stage: `bayesTLS::ts_stage1 -> ts_stage2 -> ts_ci`;
- Bayesian: `bayesTLS::fit_4pl(temp_effects = "mid") ->
  extract_tdt(target_surv = "relative")`;
- freqTLS: `fit_tls() -> confint(method = "profile")`.

Confirm the temperature effect runs through the midpoint only (shared `low`,
`up`, `k`), the time unit and `tref` match across all three (pin
`t_ref`/`time_multiplier` when calling bayesTLS; R-UNITS), and the comparison
reports point estimates plus CI width and asymmetry. Zebrafish is a 3x3 per
life stage. Include the fairness footnote.

## The R-SHRIMP Data Fix

The bayesTLS shipped `shrimp_lethal` death counts are corrupted upstream: the
CSV column `Mortality_after_trial` is a **proportion** (e.g. `0.0909 = 1/11`,
`0.5 = 5/10`), and the upstream `make_datasets.R` mislabels it a count and
applies `as.integer(...)`, flooring proportions below 1 to 0. freqTLS must
rebuild the counts from the CSV:

- `deaths = round(prop * N)`, hence `survived = N - round(prop * N)`;
- assert the rebuilt death distribution is sane (not collapsed to all zero);
- document the rebuild in `R/data.R` and a friendly upstream report;
- verify the rebuilt `.rda` before finalising.

Zebrafish counts ship correctly (`n_surv`, `n_total`); rename to native columns
only.

## Cache Provenance Gate (R-STALE)

Stan will not run in CI, so the benchmark reads a maintainer-built cache at
`inst/extdata/bayesTLS_benchmark_cache.rds`. Confirm the cache `meta` records
`bayesTLS_version`, `git_sha`, `cmdstan_version`, `date_built`, `seed`, the
configuration, and the R-SHRIMP note. The vignette shows the live calls with
`eval = FALSE`, reads the cache with `eval = TRUE`, runs freqTLS live, and
prints the provenance. A `test-benchmark-sanity` tripwire checks the cached
numbers against a live freqTLS fit within a loose tolerance and a one-command
regeneration path exists.

## Licence Gate (R-LICENSE)

The vendored data is CC BY 4.0. Confirm attribution in `R/data.R` (`@source`),
`inst/CITATION` (freqTLS + bayesTLS bibentry), and the README, with the code
under GPL-3 and provenance in `inst/COPYRIGHTS`.
