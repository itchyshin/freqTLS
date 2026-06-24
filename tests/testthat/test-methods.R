# Tests for the S3 methods and tidy extractors on a fitted profile_tls object:
# print / summary / coef / vcov / logLik / AIC / nobs run and return sane shapes,
# and tidy_parameters / get_* return the documented tibble contract. SPEC.md
# S13. Fast: one binomial and one beta-binomial fit reused via a helper.

fit_one <- function(family = "binomial", phi = NULL) {
  d <- simulate_tls(family = family, CTmax = 36, z = 4, phi = phi, seed = 1)
  fit_tls(d, y = survived, n = total, time = duration, temp = temp,
          family = family, tref = 1)
}

test_that("print and summary run and return invisibly / a summary object", {
  fit <- fit_one()
  # The header is written via cli (message stream); the estimates table is on
  # stdout.
  expect_message(print(fit), "freqTLS")
  expect_output(suppressMessages(print(fit)), "CTmax")
  expect_invisible(suppressMessages(print(fit)))

  s <- summary(fit)
  expect_s3_class(s, "summary.profile_tls")
  expect_true(all(c("estimate", "std.error", "statistic", "p.value") %in%
                    names(s$coefficients)))
  expect_output(suppressMessages(print(s)), "Coefficients")
})

test_that("coef returns a named vector or the full estimates data frame", {
  fit <- fit_one()
  cf <- coef(fit)
  expect_type(cf, "double")
  expect_true(all(c("low", "up", "k", "CTmax", "z") %in% names(cf)))
  expect_length(cf, nrow(fit$estimates))

  cf_full <- coef(fit, complete = TRUE)
  expect_s3_class(cf_full, "data.frame")
  expect_true(all(c("parameter", "group", "estimate", "std.error") %in%
                    names(cf_full)))
})

test_that("vcov returns the internal-coordinate covariance matrix", {
  fit <- fit_one()
  vc <- vcov(fit)
  expect_true(is.matrix(vc))
  # 5 internal coordinates for an ungrouped binomial fit.
  expect_identical(dim(vc), c(5L, 5L))
  expect_true(isSymmetric(unname(vc)))
  expect_identical(rownames(vc),
                   c("beta_low", "beta_up", "beta_logk", "beta_CT", "beta_logz"))
})

test_that("logLik, AIC, and nobs return sane scalars with attributes", {
  fit <- fit_one()
  ll <- logLik(fit)
  expect_s3_class(ll, "logLik")
  expect_identical(attr(ll, "df"), 5L)
  expect_identical(attr(ll, "nobs"), fit$data_summary$n_obs)
  expect_true(is.finite(as.numeric(ll)))

  # AIC default equals the stored value; a different k differs.
  expect_equal(AIC(fit), fit$AIC)
  expect_equal(AIC(fit, k = 0), -2 * as.numeric(ll))
  expect_false(isTRUE(all.equal(AIC(fit, k = log(nobs(fit))), AIC(fit))))

  expect_identical(nobs(fit), fit$data_summary$n_obs)
})

test_that("tidy_parameters returns the documented eight-column contract", {
  fit <- fit_one()
  tp <- tidy_parameters(fit)
  expect_s3_class(tp, "tbl_df")
  expect_identical(
    names(tp),
    c("parameter", "group", "estimate", "std.error",
      "conf.low", "conf.high", "interval_type", "scale")
  )
  expect_true(all(tp$interval_type == "wald"))
  # Intervals bracket the point estimate and respect bounds.
  expect_true(all(tp$conf.low <= tp$estimate + 1e-8))
  expect_true(all(tp$conf.high >= tp$estimate - 1e-8))
  expect_true(all(tp$conf.low[tp$parameter == "z"] > 0))
  expect_true(all(tp$conf.low[tp$parameter == "low"] > 0))

  # conf.int = FALSE drops the interval values but keeps the columns.
  tp0 <- tidy_parameters(fit, conf.int = FALSE)
  expect_true(all(is.na(tp0$conf.low)))
  expect_true(all(is.na(tp0$conf.high)))
})

test_that("get_ctmax, get_z, and get_shape subset the tidy table", {
  fit <- fit_one(family = "beta_binomial", phi = 30)
  expect_identical(get_ctmax(fit)$parameter, "CTmax")
  expect_identical(get_z(fit)$parameter, "z")
  expect_setequal(get_shape(fit)$parameter, c("low", "up", "k", "phi"))
})

test_that("the z Wald interval equals exp() of the internal log_z interval", {
  fit <- fit_one()
  fx <- summary(fit$sdreport, select = "fixed")
  e <- fx["beta_logz", "Estimate"]
  se <- fx["beta_logz", "Std. Error"]
  zq <- stats::qnorm(0.975)
  ci_logz <- exp(c(e - zq * se, e + zq * se))
  zrow <- get_z(fit)
  expect_equal(c(zrow$conf.low, zrow$conf.high), ci_logz, tolerance = 1e-8)
})
