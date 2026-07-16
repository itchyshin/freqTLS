manifest_path <- test_path(
  "..",
  "..",
  "data-raw",
  "canonical_comparator_manifest.R"
)

test_that("canonical comparator manifest pins every active empirical fit", {
  skip_if_not(
    file.exists(manifest_path),
    "data-raw is excluded from the built package"
  )
  source(manifest_path, local = environment())

  specs <- canonical_comparator_specs()
  expect_setequal(
    names(specs),
    c(
      "zebrafish_oxygen",
      "aphid_age6",
      "aphid_all_age",
      "snowgum_psii",
      "drosophila_mortality",
      "drosophila_awake"
    )
  )
  expect_identical(
    CANONICAL_BAYESTLS_SHA,
    "76510412e06c594c96894a1baba1f0e1a34a5aea"
  )
  expect_identical(CANONICAL_BAYESTLS_RENDER_DATE, "2026-07-14")

  expect_identical(
    specs$zebrafish_oxygen$formulas,
    list(
      ctmax = "~ 0 + oxygen",
      z = "~ 0 + oxygen",
      low = "~ 0 + oxygen",
      up = "~ 1",
      k = "~ 1"
    )
  )
  expect_identical(
    specs$aphid_age6$formulas,
    list(
      ctmax = "~ 0 + species",
      z = "~ 0 + species",
      low = "~ 1",
      up = "~ 1",
      k = "~ temp_c"
    )
  )
  expect_identical(
    specs$aphid_all_age$formulas,
    list(
      ctmax = "~ 1 + species * age",
      z = "~ 1 + species * age",
      low = "~ 1",
      up = "~ 1",
      k = "~ temp_c"
    )
  )
  expect_identical(
    specs$snowgum_psii$formulas,
    list(
      ctmax = "~ 0 + recovery + (1 | plant)",
      z = "~ 0 + recovery",
      low = "~ 1",
      up = "~ 1",
      k = "~ 1"
    )
  )
  expect_identical(specs$drosophila_mortality$t_ref, 240)
  expect_identical(specs$drosophila_mortality$threshold, "absolute")
  expect_identical(specs$drosophila_awake$formulas$ctmax, "~ sex")
  expect_identical(specs$drosophila_awake$t_ref, 60)
})

test_that("canonical comparator subsets and endpoints are exact", {
  skip_if_not(
    file.exists(manifest_path),
    "data-raw is excluded from the built package"
  )
  source(manifest_path, local = environment())

  zf <- canonical_prepare_data("zebrafish_oxygen")
  expect_identical(nrow(zf), 380L)
  expect_setequal(unique(as.character(zf$ploidy)), "diploid")
  expect_setequal(unique(as.character(zf$oxygen)), c("normoxia", "hyperoxia"))

  a6 <- canonical_prepare_data("aphid_age6")
  expect_identical(nrow(a6), 499L)
  expect_setequal(unique(as.character(a6$branch)), "heat")
  expect_setequal(unique(as.character(a6$age)), "6")

  aa <- canonical_prepare_data("aphid_all_age")
  expect_identical(nrow(aa), 1503L)
  expect_setequal(unique(as.character(aa$branch)), "heat")
  expect_setequal(unique(as.character(aa$age)), c("2", "6", "12"))

  snow <- canonical_prepare_data("snowgum_psii")
  expect_identical(nrow(snow), 394L)
  expect_setequal(unique(as.character(snow$recovery)), c("Dark", "Light"))

  mort <- canonical_prepare_data("drosophila_mortality")
  expect_identical(nrow(mort), 94L)
  expect_identical(sum(mort$n_total), 1407L)
  expect_identical(sum(mort$n_surv), 785L)

  awake <- canonical_prepare_data("drosophila_awake")
  expect_identical(nrow(awake), 94L)
  expect_gt(min(awake$duration), 0)
  expect_identical(sum(awake$n_total), 1407L)
  expect_identical(sum(awake$n_awake), 583L)
})

test_that("canonical analysis hashes detect subset drift", {
  skip_if_not(
    file.exists(manifest_path),
    "data-raw is excluded from the built package"
  )
  skip_if_not_installed("digest")
  source(manifest_path, local = environment())

  expected <- CANONICAL_ANALYSIS_HASHES
  observed <- vapply(
    names(expected),
    function(id) canonical_hash(canonical_prepare_data(id)),
    character(1)
  )
  expect_identical(observed, expected)
})

test_that("published canonical cache has complete provenance and no legacy cases", {
  cache_path <- test_path(
    "..",
    "..",
    "inst",
    "extdata",
    "canonical_bayesTLS_cache.rds"
  )
  if (!file.exists(cache_path)) {
    cache_path <- system.file(
      "extdata",
      "canonical_bayesTLS_cache.rds",
      package = "freqTLS"
    )
  }
  skip_if_not(
    file.exists(cache_path) && nzchar(cache_path),
    "pinned Totoro cache has not been built"
  )

  cache <- readRDS(cache_path)
  expect_setequal(names(cache), c("meta", "summaries", "diagnostics"))
  expect_identical(cache$meta$schema_version, 1L)
  expect_identical(
    cache$meta$bayesTLS_git_sha,
    "76510412e06c594c96894a1baba1f0e1a34a5aea"
  )
  expect_match(cache$meta$freqTLS_git_sha, "^[0-9a-f]{40}$")
  expect_match(cache$meta$cmdstan_version, "^[0-9]+\\.[0-9]+")
  expect_identical(cache$meta$openblas_num_threads, "1")
  expect_lte(cache$meta$bounded_cores, 16L)

  expected_cases <- c(
    "zebrafish_oxygen",
    "aphid_age6",
    "aphid_all_age",
    "snowgum_psii",
    "drosophila_mortality",
    "drosophila_awake"
  )
  expect_setequal(names(cache$meta$cases), expected_cases)
  expect_setequal(unique(cache$summaries$case_id), expected_cases)
  expect_setequal(unique(cache$diagnostics$case_id), expected_cases)
  expect_setequal(unique(cache$summaries$parameter), c("CTmax", "z"))
  expect_true(all(is.finite(cache$summaries$median)))
  expect_true(all(is.finite(cache$summaries$lower)))
  expect_true(all(is.finite(cache$summaries$upper)))
  expect_match(cache$meta$legacy_exclusion, "Shrimp")
  expect_match(cache$meta$legacy_exclusion, "life-stage zebrafish")
  expect_false(any(grepl(
    "shrimp|life_stage",
    cache$summaries$case_id,
    ignore.case = TRUE
  )))
})
