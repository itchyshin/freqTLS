# The vendored dsuzukii lethal-by-sex dataset (Drosophila suzukii mortality
# counts aggregated per temp x time x sex), the D. suzukii case-study data.
# Vendored from bayesTLS (CC BY 4.0; Orsted et al. 2024, Zenodo 10602268).

test_that("dsuzukii_lethal loads with the expected structure", {
  data(dsuzukii_lethal, package = "freqTLS", envir = environment())
  expect_s3_class(dsuzukii_lethal, "data.frame")
  expect_true(all(c("temp", "time", "sex", "total", "survived") %in%
                    names(dsuzukii_lethal)))
  expect_setequal(as.character(unique(dsuzukii_lethal$sex)), c("F", "M"))
  expect_true(all(dsuzukii_lethal$survived >= 0 &
                    dsuzukii_lethal$survived <= dsuzukii_lethal$total &
                    dsuzukii_lethal$total > 0))
})

test_that("a sex-grouped fit recovers the published per-sex CTmax/z (Orsted 2024)", {
  data(dsuzukii_lethal, package = "freqTLS", envir = environment())
  # tref = 240 minutes = 4 h, the Orsted absolute reference.
  fit <- suppressWarnings(fit_tls(
    dsuzukii_lethal, y = survived, n = total, time = time, temp = temp,
    group = sex, family = "beta_binomial", tref = 240
  ))
  expect_identical(fit$convergence$code, 0L)
  est <- fit$estimates
  ct <- est$estimate[grepl("^CTmax:", est$parameter)]
  z <- est$estimate[grepl("^z:", est$parameter)]
  # Orsted Table 1: CTmax_4hr ~ 35.2 C both sexes; z ~ 3.0-3.3.
  expect_length(ct, 2L)
  expect_true(all(ct > 34 & ct < 36))
  expect_true(all(z > 2.5 & z < 3.6))
})
