# The vendored snowgum PSII dataset: continuous proportion (retained PSII
# function), the real-data showcase for the v0.2 beta family. Vendored from
# bayesTLS (CC BY 4.0); see R/data.R and data-raw/make_benchmark_data.R.

test_that("snowgum_psii loads with the expected structure", {
  data(snowgum_psii, package = "freqTLS", envir = environment())
  expect_s3_class(snowgum_psii, "data.frame")
  expect_true(all(c("temp", "duration", "prop") %in% names(snowgum_psii)))
  # A proportion (retained PSII), within [0, 1]; complete-loss rows sit at 0.
  expect_true(all(snowgum_psii$prop >= 0 & snowgum_psii$prop <= 1))
  expect_gt(nrow(snowgum_psii), 300)
  expect_true(min(snowgum_psii$prop) == 0) # the boundary-zero rows
})

test_that("the beta family fits snowgum_psii with a sensible CTmax", {
  data(snowgum_psii, package = "freqTLS", envir = environment())
  fit <- suppressWarnings(fit_tls(
    snowgum_psii, y = prop, time = duration, temp = temp,
    family = "beta", tref = 5
  ))
  expect_identical(fit$convergence$code, 0L)
  ct <- coef(fit)[["CTmax"]]
  # CTmax sits inside the 28-48 C assay range.
  expect_gt(ct, 28)
  expect_lt(ct, 48)
})
