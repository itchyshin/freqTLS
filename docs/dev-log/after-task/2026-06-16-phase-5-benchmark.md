# After Task: Phase 5 -- benchmark data (R-SHRIMP) + cache harness

## Date

2026-06-16

## Task

Build the vendored benchmark datasets and the (Stan-free) benchmark harness
(SPEC.md S5 R-SHRIMP, S8 data-raw/R/data.R, S12 benchmark/column-mapping/cache,
S14 R-SHRIMP/R-STALE/R-LICENSE). Deliverables (Phase 5, Curie + Jason + Rose):
`data-raw/make_benchmark_data.R` (run now), `R/data.R`, `inst/CITATION`,
`data-raw/build_benchmark_cache.R` (written, NOT run), and
`tests/testthat/test-benchmark-sanity.R` (skips when the cache is absent). Hard
environment fact: bayesTLS is not installed and Stan/cmdstanr cannot fit here,
so the Bayesian/two-stage cache is built by a maintainer, not in CI. The
verifiable payoff this phase is the R-SHRIMP-corrected vendored data and
profileTLS fitting the real shrimp + zebrafish data with sensible estimates.

## Created / Changed

Created:

- `data-raw/make_benchmark_data.R` -- maintainer-run, executed now. Downloads
  the shrimp CSV + both shipped `.rda` from the bayesTLS GitHub @HEAD via the
  curl CLI into a git-ignored `data-raw/.cache/`. Rebuilds `shrimp_lethal` from
  the CSV proportion (`deaths = round(mortality_prop * total)`,
  `survived = total - deaths`), keeping `mortality_prop` for provenance; takes
  `zebrafish_lethal` from the shipped object (its build is correct); renames both
  to the profileTLS contract (`temp`, `duration` [hours], `total`, `survived`,
  `+ life_stage`); asserts the rebuilt shrimp death distribution is not collapsed
  to {0,1}; writes `data/shrimp_lethal.rda` + `data/zebrafish_lethal.rda` via
  `usethis::use_data(..., overwrite = TRUE)`; and prints the R-SHRIMP
  before/after death distributions.
- `R/data.R` -- roxygen for both datasets: `@format` (columns/units/n),
  `@source` + `@section Attribution:` (bayesTLS / Noble, Arnold & Pottier 2026 /
  CC BY 4.0 / the original *Crangon crangon* + *Danio rerio* assays), the
  R-SHRIMP reconstruction note on `shrimp_lethal`, `@docType data`,
  `@keywords datasets`, `@name`, and the `"shrimp_lethal"` /
  `"zebrafish_lethal"` object strings. `zebrafish_lethal` notes its counts are
  shipped-correct and cross-links `[shrimp_lethal]`.
- `data-raw/build_benchmark_cache.R` -- maintainer-run; NOT executed. Guarded by
  `if (!requireNamespace("bayesTLS") || !requireNamespace("cmdstanr")) stop(...)`.
  Fits `fit_4pl(temp_effects = "mid", beta_binomial) ->
  extract_tdt(target_surv = "relative", t_ref = 1, time_multiplier = 1,
  output_time_unit = "hours")` for shrimp (ungrouped) + each zebrafish life
  stage, and `ts_stage1 -> ts_stage2 -> ts_ci` (delta CIs); writes summaries-only
  + a `meta` block (`bayesTLS_version`, `git_sha`, `cmdstan_version`,
  `date_built`, `seed`, `config`, realized R-SHRIMP distribution note) to
  `inst/extdata/bayesTLS_benchmark_cache.rds`. Uses the vendored profileTLS
  datasets so the comparators see exactly the R-SHRIMP-corrected counts.
- `tests/testthat/test-benchmark-sanity.R` --
  `skip_if_not(file.exists(system.file("extdata",
  "bayesTLS_benchmark_cache.rds", package = "profileTLS")))`; when present, fits
  profileTLS live on shrimp + each zebrafish stage and asserts CTmax within ~1 C
  and z within ~25% of the cached bayesTLS median.

Changed:

- `inst/CITATION` -- the bayesTLS bibentry note now states the bundled datasets
  are vendored from bayesTLS under CC BY 4.0 and must be cited when used.
- `.gitignore` -- ignore `data-raw/.cache/`.
- `man/shrimp_lethal.Rd`, `man/zebrafish_lethal.Rd` -- via `devtools::document()`.
- `docs/dev-log/check-log.md`, `docs/dev-log/decisions.md`,
  `docs/dev-log/known-limitations.md`, `docs/dev-log/dashboard/status.json`,
  `docs/dev-log/comparator-results/2026-06-16-bayesTLS-upstream-report.md` --
  Phase 5 evidence, the R-SHRIMP decision/limitation, status, and the drafted
  (unsent) friendly upstream report.

## Checks Performed (exact commands + counts)

- R-SHRIMP before/after (the shipped `.rda` vs the CSV reconstruction):
  - shipped `shrimp_lethal$Mortality_after_trial`: `integer`, values `{0, 1}`,
    `table` = 113 zeros + 35 ones, **sum 35** over 148 rows.
  - CSV `Mortality_after_trial`: numeric proportion, summary min 0 / median 0.40
    / mean 0.49 / max 1.0.
  - corrected `deaths = round(prop * N)`: range `[0, 11]`, **12 distinct values,
    sum 738**; `length(which(deaths > 0 & prop < 1))` = **86** rows that
    `as.integer()` had floored to 0.
- `R -q -e 'source("data-raw/make_benchmark_data.R")'` -> printed the before/after
  above and wrote `data/shrimp_lethal.rda` (148 rows) +
  `data/zebrafish_lethal.rda` (323 rows).
- `R -q -e 'tryCatch(source("data-raw/build_benchmark_cache.R"),
  error = function(e) cat(conditionMessage(e)))'` -> GUARD FIRED:
  "build_benchmark_cache.R needs both 'bayesTLS' and 'cmdstanr' ..."; and
  `ls inst/extdata/bayesTLS_benchmark_cache.rds` -> No such file (cache ABSENT).
- `R -q -e 'devtools::document(".")'` -> wrote `man/shrimp_lethal.Rd` +
  `man/zebrafish_lethal.Rd`. (Three pre-existing `@noRd` link warnings from
  confint.R/diagnostics.R/profile.R are unchanged Phase 2-3 notes, not from this
  phase; the `[shrimp_lethal]` cross-link resolves once the alias exists.)
- Verification gate (`devtools::load_all(".")` then the SPEC block):
  - `shrimp: n= 148  temps= 30,30.5,31,31.5,32,32.5,33`;
    `summary(survived/total)` min 0, 1st-Q 0.10, median 0.60, mean 0.507,
    3rd-Q 0.90, max 1.0; R-SHRIMP deaths range `0 11`.
  - `zebrafish: n= 323  stages= old_embryos,young_embryos,larvae`.
  - shrimp `fit_tls(..., family = "beta_binomial", tref = 1)`: conv 0, pdHess
    TRUE; low 1.97e-10, up 0.9414, k 5.694, CTmax 31.775, z 2.194, phi 7.079.
  - zebrafish grouped fit (`group = life_stage`): conv 0, pdHess TRUE;
    CTmax:young 39.921 / CTmax:old 41.379 / CTmax:larvae 39.792;
    z:young 1.998 / z:old 1.798 / z:larvae 1.982; up 0.8635, k 7.827, phi 3.294.
    Warning fired (appropriate): "Fewer than 3 unique durations at temperatures
    40.1, 40.5, 41.2, and 42" (S10 warning 2).
- `R -q -e 'devtools::test(".")'` ->
  `[ FAIL 0 | WARN 0 | SKIP 1 | PASS 201 ]`; the single SKIP is
  `test-benchmark-sanity.R:31:3` "bayesTLS benchmark cache absent (needs Stan +
  bayesTLS to build)". Per-file: benchmark-sanity S=1, fit-beta-binomial 15,
  fit-binomial 13, group 21, methods 36, parameter-transforms 17, predict 38,
  profile 35, simulate 26.

## Outcomes

- The R-SHRIMP bug is verified against the actual upstream object: the shipped
  `shrimp_lethal` collapses observed mortality to {0,1} (35 of 738 deaths
  survive the `as.integer()` floor -- ~95% lost), and the CSV reconstruction
  restores the full 0..11 gradient. This is the single change that makes the
  shrimp fit identifiable.
- profileTLS fits the real data with sensible, finite, plausible estimates:
  shrimp CTmax 31.8 C / z 2.2 C inside the 30-33 C assay range; zebrafish
  per-stage CTmax 39.8-41.4 C with old embryos most heat-tolerant, z ~1.8-2.0 C.
  Both converge (code 0, pdHess TRUE) under beta-binomial with real
  overdispersion (phi 7.1 shrimp, 3.3 zebrafish).
- Data-adequacy warnings fire appropriately, not spuriously: the zebrafish
  sparse high-temperature cells trip the per-temperature duration warning, the
  shrimp fit (CTmax interior) does not trip the extrapolation warning.
- The cache builder is written and its guard verified to stop without
  bayesTLS/Stan; the benchmark test skips (not fails); the cache rds is absent as
  expected. CC-BY attribution is complete across `R/data.R`, `inst/CITATION`,
  `inst/COPYRIGHTS`, and the package README credit (R-LICENSE).

## Consistency Review

- `rg "posterior|credible"` over the Phase-5 files (`data-raw/*.R`, `R/data.R`,
  `tests/testthat/test-benchmark-sanity.R`, `inst/CITATION`): none -- the
  datasets and harness use only "compatibility/confidence" and "posterior
  median" strictly in the bayesTLS-comparator sense (the cache holds bayesTLS
  posterior summaries; profileTLS's own output is never called a posterior).
- Column contract is consistent everywhere: `R/data.R` `@format`,
  `make_benchmark_data.R`, `build_benchmark_cache.R`, and
  `docs/design/06-benchmark-protocol.md` all use `temp/duration[hours]/total/
  survived[/life_stage]` and the `survived = total - round(mortality_prop *
  total)` shrimp rule.
- R-SHRIMP is recorded in one voice across `R/data.R` (the reconstruction note),
  `make_benchmark_data.R` (the header + the live before/after assertion),
  `build_benchmark_cache.R` (the realized-distribution meta note), the
  check-log, `decisions.md`, `known-limitations.md`, and the upstream-report
  draft -- the same numbers (shipped sum 35 / corrected sum 738 / 86 floored
  rows) in each.
- Units (R-UNITS): `tref = 1` hour is matched in `make_benchmark_data.R`
  (duration kept in hours), `build_benchmark_cache.R` (`t_ref = 1`,
  `time_multiplier = 1`, `output_time_unit = "hours"`, `duration_unit =
  "hours"`), and the live test (`fit_tls(..., tref = 1)`).
- `LazyData: true` is already in DESCRIPTION (Phase 0), so the new `data/*.rda`
  load via `data()` and lazy access without a DESCRIPTION change.

## Tests Of The Tests

- `make_benchmark_data.R` carries two live assertions that would stop a silent
  regression: (1) `Mortality_after_trial` must lie in [0, 1] (if a future
  upstream relabels it a count, the proportion assumption fails loudly); (2) the
  rebuilt shrimp deaths must have > 2 distinct values and max > 1 (if the rebuild
  ever re-collapsed to {0,1}, it refuses to ship). The zebrafish path asserts
  `n_surv + n_dead == n_total`.
- `build_benchmark_cache.R`'s guard was *executed* (not just inspected) and
  confirmed to `stop()` because bayesTLS is absent -- so "written but not run" is
  verified, not assumed.
- `test-benchmark-sanity.R` was confirmed to SKIP (count 1), not silently pass:
  the skip reason string is asserted in the run output, so a future cache would
  flip it to a real comparison rather than a no-op.
- The benchmark tolerances are deliberately loose and one-directional (CTmax
  absolute < 1 C; z relative < 25%): tight enough to catch a config mismatch
  (e.g. absolute vs relative threshold, or a unit error shifting CTmax by hours),
  loose enough that a genuine likelihood-vs-posterior difference passes.

## What Did Not Go Smoothly

- `utils::download.file()` failed twice in the sandbox: the default libcurl
  method was blocked outright, and `method = "curl"` plus `download.file`'s own
  `-o` produced curl error 56 (write failure) when writing under
  `tempdir()`/`/var/folders`. Root cause: the sandbox blocks curl writes to the
  system temp dir from inside this R process. Fix: call the curl CLI directly via
  `system2("curl", c("-sSL", "-o", dest, url))` and download into a git-ignored
  `data-raw/.cache/` under the package tree instead of `tempdir()`. This is also
  friendlier for a maintainer (the raw downloads are inspectable). The script is
  robust on a normal machine too (curl is a hard dep of the download step, noted
  in the header).
- The `extract_tdt()` / `ts_ci()` output schemas are bayesTLS-version dependent
  and I cannot run them here, so the cache builder's summarisers
  (`summarise_tdt`, `pull_ci`) read defensively (`%||%` fallbacks across likely
  column names) and are flagged in comments as the spot a maintainer adjusts if a
  bayesTLS update renames columns. This is honest scope: the cache numbers are
  unverifiable in this environment, and the script says so.

## Team Learning

- (Curie) Verify a data bug against the *shipped artifact*, not the bug report:
  loading the upstream `.rda` and tabulating `Mortality_after_trial` ({0,1}, sum
  35) is the proof; the CSV reconstruction (0..11, sum 738) is the fix. Pasting
  both distributions is worth more than restating the mechanism.
- (Rose) "Written but not run" is a claim that must itself be tested: executing
  the guard and confirming the `stop()` (and the absent rds) is the difference
  between a verified skip and a hopeful one. A Phase-0 agent confabulated; this
  phase trusts only pasted output.
- (Jason) Match the comparator's units explicitly. bayesTLS defaults to
  `t_ref = 60` and `output_time_unit = "min"`; profileTLS uses `tref = 1` hour.
  The cache builder pins `t_ref = 1` / `time_multiplier = 1` /
  `output_time_unit = "hours"` so CTmax@1h is the same quantity in all three
  estimators -- the most likely source of a spurious benchmark gap, closed up
  front.
- (Curie/Darwin) Feed the comparators the *corrected* data, not the raw bayesTLS
  objects: `build_benchmark_cache.R` reads the profileTLS `shrimp_lethal` so the
  benchmark compares methods on identical counts, isolating method differences
  from the upstream data bug.

## Known Limitations

- The bayesTLS + two-stage cache (`inst/extdata/bayesTLS_benchmark_cache.rds`) is
  ABSENT in this environment and cannot be built here (no bayesTLS, no CmdStan).
  The benchmark numbers are therefore unverified until a maintainer runs
  `data-raw/build_benchmark_cache.R`; `test-benchmark-sanity` skips and the
  comparison vignette (Phase 6) has nothing to read yet.
- `build_benchmark_cache.R`'s `extract_tdt()` / `ts_ci()` summarisers assume a
  plausible output schema and read defensively; a bayesTLS API change may need a
  one-line column-name edit (flagged in the script).
- The shrimp assay covers a narrow 30-33 C range with a single fitted CTmax
  (31.8 C, interior); the zebrafish design has sparse high-temperature cells (the
  fired duration warning). Benchmark agreement on these designs is a sanity
  tripwire, not a coverage statement (the dashboard "Wald/profile coverage"
  guard still holds: no coverage rates are claimed).

## Next Best Task

- Phase 6 (docs/site): once a maintainer runs `build_benchmark_cache.R`, build
  `vignettes/comparing-to-bayesTLS.Rmd` -- live bayesTLS calls `eval = FALSE`,
  read the cache `eval = TRUE`, fit profileTLS live, print provenance, and place
  the bayesTLS posterior density beside the profileTLS Confidence Eye (the S13
  teaching device). The three-way table populates for shrimp + each zebrafish
  stage.
- Send the drafted friendly upstream report
  (`docs/dev-log/comparator-results/2026-06-16-bayesTLS-upstream-report.md`) to
  the bayesTLS authors after a maintainer review (it is text-only and unsent).
