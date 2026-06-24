Hi Dan, Pieter, and Patrice,

First, thank you for bayesTLS and for distributing the raw thermal-death-time data with it — having the brown-shrimp and zebrafish assays packaged is hugely useful. While building a likelihood/profile-likelihood complement (freqTLS) that benchmarks against bayesTLS on your datasets, I think I have found a small but consequential data-build bug in `shrimp_lethal`, and I wanted to flag it early and constructively.

**What I see.** In the source CSV `inst/extdata/data_lethal_TDT_brown_shrimp.csv`, the column `Mortality_after_trial` is a *proportion* dead, not a count — e.g. `0.0909` (= 1/11), `0.5` (= 5/10), `0.9` (= 9/10). The shipped `shrimp_lethal` object, however, has `Mortality_after_trial` as an integer that only ever takes the values `0` and `1`. Tracing it back, `data-raw/make_datasets.R` appears to treat this column as a death count and apply `as.integer(...)` to it, which truncates every proportion below 1 to 0.

**Effect.** In the shipped object the shrimp deaths collapse to 113 zeros and 35 ones (35 deaths total across 148 rows). Reconstructing from the CSV proportion with `round(Mortality_after_trial * N_individuals_after_trial)` gives deaths spanning 0 to 11 and summing to 738 — so roughly 95% of the observed mortality is lost in the shipped counts, and 86 rows that have a genuine non-zero death proportion below 1 are floored to zero. A 4PL thermal-death-time curve fitted to the shipped counts is effectively unidentifiable (almost no graded mortality), whereas the reconstructed counts give a clean, well-identified curve (CTmax ~31.8 C, z ~2.2 C in our likelihood fit).

**Minimal reproducer.**

```r
# Shipped object: deaths only take 0/1
data(shrimp_lethal, package = "bayesTLS")
table(shrimp_lethal$Mortality_after_trial)
#>   0   1
#> 113  35
sum(shrimp_lethal$Mortality_after_trial)   # 35

# CSV proportion -> reconstructed counts
csv <- read.csv(
  system.file("extdata", "data_lethal_TDT_brown_shrimp.csv", package = "bayesTLS"),
  fileEncoding = "UTF-8-BOM"
)
deaths <- round(csv$Mortality_after_trial * csv$N_individuals_after_trial)
range(deaths)   # 0 11
sum(deaths)     # 738
sum(deaths > 0 & csv$Mortality_after_trial < 1)   # 86 rows floored to 0 upstream
```

**Suggested fix.** In `data-raw/make_datasets.R`, treat `Mortality_after_trial` as a proportion and derive the integer counts from it before building `shrimp_lethal`, e.g.

```r
deaths   <- round(Mortality_after_trial * N_individuals_after_trial)
survived <- N_individuals_after_trial - deaths
```

(equivalently, your `standardize_data(mortality = ...)` path already does `n_surv = round((1 - mortality) * n_total)`, so feeding the proportion through that route would also be consistent).

**Scope.** This looks specific to the shrimp build. The zebrafish object (`zebrafish_lethal`) is fine — `n_surv + n_dead == n_total` holds for every row, so its daily-mortality summation is correct; I have left it untouched.

For transparency: freqTLS vendors a corrected copy of `shrimp_lethal` (counts rebuilt from the CSV, original proportion retained as `mortality_prop`) under CC BY 4.0 with attribution to bayesTLS, and documents the reconstruction. I would much rather cite a fixed upstream dataset, though, so please take this as a friendly nudge rather than a complaint — happy to open a PR with the one-line fix and a regression check if that is useful.

Thanks again for the package and the data.

Best,
Shinichi (on behalf of the freqTLS project)
