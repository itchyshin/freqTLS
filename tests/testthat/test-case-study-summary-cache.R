test_that("cross-case-study cache has complete versioned profile summaries", {
  path <- system.file(
    "extdata", "case_study_summary_cache.rds", package = "freqTLS"
  )
  expect_true(nzchar(path))
  cache <- readRDS(path)

  expect_identical(cache$meta$schema_version, 1L)
  expect_identical(cache$meta$freqTLS_version, "0.1.0")
  expect_identical(
    cache$meta$freqTLS_source_commit,
    "589e3af6c7c226c571ddcbf682f86a578f77ad9c"
  )
  expect_identical(cache$meta$input_md5, list(
    "data/shrimp_lethal.rda" = "0d24614db7f6ce6b72588d737d046a90",
    "data/zebrafish_lethal.rda" = "ef07373ebd05bbb868cbd23bc728adc5",
    "data/dsuzukii.rda" = "7e8f0813293ed74854585f49516a8dfb"
  ))
  expect_identical(cache$meta$configuration$contrast_interval$nboot, 1000L)
  expect_identical(
    cache$meta$configuration$contrast_interval$seeds,
    list(zebrafish = 20260712L, dsuzukii = 20260713L)
  )
  expect_identical(nrow(cache$panel), 12L)
  expect_identical(nrow(cache$contrasts), 8L)

  expect_setequal(cache$panel$parameter, c("CTmax", "z"))
  expect_setequal(cache$panel$method, "profile")
  expect_setequal(cache$panel$status, "ok")
  expect_setequal(cache$contrasts$method, c("profile", "bootstrap"))
  expect_setequal(cache$contrasts$conf.status, c("ok", "bootstrap"))
  expect_identical(sum(cache$contrasts$method == "profile"), 1L)
  expect_identical(sum(cache$contrasts$method == "bootstrap"), 7L)
  expect_true(all(
    (cache$contrasts$method == "profile" & cache$contrasts$conf.status == "ok") |
      (cache$contrasts$method == "bootstrap" &
         cache$contrasts$conf.status == "bootstrap")
  ))
  expect_true(all(is.finite(cache$panel$estimate)))
  expect_true(all(is.finite(cache$panel$conf.low)))
  expect_true(all(is.finite(cache$panel$conf.high)))
  expect_true(all(is.finite(cache$contrasts$estimate)))
  expect_true(all(is.finite(cache$contrasts$conf.low)))
  expect_true(all(is.finite(cache$contrasts$conf.high)))
})
