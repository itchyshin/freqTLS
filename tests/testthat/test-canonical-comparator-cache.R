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
  expect_true(all(vapply(
    specs,
    function(x) {
      x$status %in%
        c(
          "canonical_mirror",
          "frequentist_analogue",
          "freqTLS_only_extension",
          "experimental_extension",
          "benchmark_only_legacy",
          "unsupported_bayesTLS_only",
          "remove"
        )
    },
    logical(1)
  )))

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
  expect_true(cache$meta$diagnostic_all_pass)
  expect_length(cache$meta$diagnostic_failures, 0L)
  expect_true(all(cache$diagnostics$all_pass))

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
  expect_true(all(cache$summaries$lower <= cache$summaries$median))
  expect_true(all(cache$summaries$median <= cache$summaries$upper))

  source(manifest_path, local = environment())
  specs <- canonical_comparator_specs()
  expected_groups <- c(
    zebrafish_oxygen = 2L,
    aphid_age6 = 3L,
    aphid_all_age = 9L,
    snowgum_psii = 2L,
    drosophila_mortality = 2L,
    drosophila_awake = 2L
  )
  for (case_id in expected_cases) {
    meta <- cache$meta$cases[[case_id]]
    spec <- specs[[case_id]]
    rows <- cache$summaries[cache$summaries$case_id == case_id, , drop = FALSE]
    expect_identical(
      meta$analysis_hash_sha256,
      unname(CANONICAL_ANALYSIS_HASHES[[case_id]])
    )
    expect_identical(meta$formulas, spec$formulas)
    expect_identical(meta$t_ref, spec$t_ref)
    expect_identical(meta$reported_threshold, spec$threshold)
    expect_identical(nrow(rows), 2L * expected_groups[[case_id]])
    parameter_counts <- table(rows$parameter)
    expect_setequal(names(parameter_counts), c("CTmax", "z"))
    expect_identical(
      as.integer(parameter_counts[c("CTmax", "z")]),
      rep(expected_groups[[case_id]], 2L)
    )
  }
  expect_match(cache$meta$legacy_exclusion, "Shrimp")
  expect_match(cache$meta$legacy_exclusion, "life-stage zebrafish")
  expect_false(any(grepl(
    "shrimp|life_stage",
    cache$summaries$case_id,
    ignore.case = TRUE
  )))
})
