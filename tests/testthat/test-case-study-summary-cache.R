test_that("cross-case-study cache has complete versioned profile summaries", {
  path <- system.file(
    "extdata", "case_study_summary_cache.rds", package = "freqTLS"
  )
  expect_true(nzchar(path))
  cache <- readRDS(path)

  expect_identical(cache$meta$schema_version, 1L)
  expect_identical(cache$meta$freqTLS_version, "0.1.0")
  expect_match(cache$meta$freqTLS_source_commit, "^[0-9a-f]{40}$")
  expect_length(cache$meta$input_md5, 3L)
  expect_identical(nrow(cache$panel), 12L)
  expect_identical(nrow(cache$contrasts), 8L)

  expect_setequal(cache$panel$parameter, c("CTmax", "z"))
  expect_setequal(cache$panel$method, "profile")
  expect_setequal(cache$panel$status, "ok")
  expect_setequal(cache$contrasts$method, c("profile", "bootstrap"))
  expect_setequal(cache$contrasts$conf.status, c("ok", "bootstrap"))
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
