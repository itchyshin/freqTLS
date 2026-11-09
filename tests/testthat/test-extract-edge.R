# Argument validation, accessors, and degraded-input behaviour of extract_tdt()
# (R/extract_tdt.R) and tidy_parameters() (R/extract.R).

ex_fit <- function() {
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
  suppressWarnings(
    fit_tls(d, y = survived, n = total, time = duration, temp = temp,
            family = "binomial", tref = 1)
  )
}

test_that("extract_tdt validates the object and target_surv", {
  fit <- ex_fit()
  expect_error(extract_tdt(list()), "freq_tls.*profile_tls")
  expect_error(extract_tdt(fit, target_surv = "bogus", nboot = 5),
               "should be one of")
  expect_error(extract_tdt(fit, target_surv = 1.5, nboot = 5),
               "must be .*relative.*absolute")
  expect_error(extract_tdt(fit, target_surv = c(0.2, 0.3), nboot = 5),
               "must be .*relative.*absolute")
  expect_error(extract_tdt(fit, target_surv = NA_real_, nboot = 5),
               "must be .*relative.*absolute")
  expect_error(extract_tdt(fit, target_surv = 0.9999, nboot = 5),
               "not attainable in the fitted curve")
  expect_error(extract_tdt(fit, target_surv = 0.0001, nboot = 5),
               "strictly between the fitted asymptotes")
})

test_that("extract_tdt returns bootstrap draws and ordered summaries with a print method", {
  fit <- ex_fit()
  et <- extract_tdt(fit, nboot = 30, seed = 1, lethal = TRUE)
  expect_s3_class(et, "freq_tdt")
  expect_named(et, c("z", "CTmax", "T_crit", "meta"))
  est <- stats::setNames(fit$estimates$estimate, fit$estimates$parameter)

  zs <- get_z_summary(et)
  expect_named(zs, c("z_median", "z_lower", "z_upper"))
  expect_lt(zs$z_lower, zs$z_median)
  expect_lt(zs$z_median, zs$z_upper)
  expect_lt(abs(zs$z_median - est[["z"]]), 0.3)

  cs <- get_ctmax_summary(et)
  expect_lt(abs(cs$temp_median - est[["CTmax"]]), 0.3)
  expect_lt(cs$temp_lower, cs$temp_upper)

  # T_crit = CTmax(1 h anchor) + z * mean(log10(rate / 100)), here with tref = 1.
  tc <- get_tcrit_summary(et)
  expect_lt(tc$temp_median, cs$temp_median)

  expect_named(get_z_draws(et), c(".draw", "z"))
  expect_named(get_ctmax_draws(et), c(".draw", "CTmax"))
  expect_named(get_tcrit_draws(et), c(".draw", "T_crit", "log10_rate"))
  expect_equal(nrow(get_z_draws(et)), et$meta$nboot)

  out <- utils::capture.output(res <- print(et))
  expect_match(out[1], "<freq_tdt> relative threshold; .* bootstrap replicates;.*T_crit included")
  expect_match(out[2], "\\$z, \\$CTmax, \\$T_crit")
  expect_identical(res, et)

  plain <- extract_tdt(fit, nboot = 30, seed = 1)
  expect_null(plain$T_crit)
  expect_no_match(utils::capture.output(print(plain))[1], "T_crit included")
  expect_match(utils::capture.output(print(plain))[2], "^  \\$z, \\$CTmax \\(each")
})

test_that("a numeric target_surv is an absolute threshold", {
  fit <- ex_fit()
  et <- extract_tdt(fit, target_surv = 0.5, nboot = 30, seed = 1)
  expect_identical(et$meta$mode, "absolute")
  expect_equal(et$meta$p, 0.5)
  # The absolute 50% CTmax matches derive_ctmax() at the fitted parameters.
  expect_equal(get_ctmax_summary(et)$temp_median,
               derive_ctmax(fit, surv = 0.5, duration = 1), tolerance = 0.2)
  abs_chr <- extract_tdt(fit, target_surv = "absolute", nboot = 10, seed = 1)
  expect_equal(abs_chr$meta$p, 0.5)
})

test_that("extract_tdt accepts a freq_tls workflow", {
  raw <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
  dat <- standardize_data(raw, temp = "temp", duration = "duration",
                          n_total = "total", n_surv = "survived")
  wf <- fit_4pl(dat, family = "binomial", t_ref = 60, quiet = TRUE)
  expect_s3_class(wf, "freq_tls")
  et <- extract_tdt(wf, nboot = 20, seed = 2)
  expect_s3_class(et, "freq_tdt")
  expect_equal(et$meta$tref, wf$fit$tref)
  # `extract_tdt()` copies the fitted z into the bootstrap summary median when
  # every replicate succeeds (nboot = 20 here); the point estimate is exact.
  expect_equal(get_z_summary(et)$z_median, wf$fit$estimates$estimate[
    wf$fit$estimates$parameter == "z"], tolerance = 1e-6)
})

test_that("accessors reject objects that are not extract_tdt() results", {
  expect_error(get_z_summary(list()), "must be an .*extract_tdt")
  expect_error(get_z_draws(1), "must be an .*extract_tdt")
  expect_error(get_ctmax_summary(list(z = 1)), "must be an .*extract_tdt")
  expect_error(get_ctmax_draws(NULL), "must be an .*extract_tdt")
  fit <- ex_fit()
  et <- extract_tdt(fit, nboot = 10, seed = 1)
  expect_error(get_tcrit_summary(et), "no T_crit.*lethal = TRUE")
  expect_error(get_tcrit_draws(et), "no T_crit.*lethal = TRUE")
  expect_error(get_tcrit_summary(list()), "must be an .*extract_tdt")
})

test_that("extract_tdt refuses an absolute threshold for shape-varying fits", {
  d <- simulate_tls(family = "binomial", group = c("A", "B"),
                    CTmax = c(35, 38), z = c(4, 3), low = 0.02, up = 0.98,
                    k = c(3, 9), seed = 4)
  fit <- suppressWarnings(fit_tls(
    tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
           CTmax ~ group, log_z ~ group, low ~ group, up ~ group, log_k ~ group),
    data = d, family = "binomial", tref = 1))
  expect_error(extract_tdt(fit, target_surv = "absolute", nboot = 5),
               "varying fixed-effect shape design")
})

test_that("tidy_parameters validates its inputs", {
  fit <- ex_fit()
  expect_error(tidy_parameters(list()), "profile_tls")
  expect_error(tidy_parameters(fit, conf.level = 1), "single number in \\(0, 1\\)")
  expect_error(tidy_parameters(fit, conf.level = c(0.9, 0.95)),
               "single number in \\(0, 1\\)")
  expect_error(tidy_parameters(fit, method = "bootstrap"), "should be one of")
})

test_that("tidy_parameters Wald intervals bracket estimates and widen with level", {
  fit <- ex_fit()
  t90 <- tidy_parameters(fit, conf.level = 0.9)
  t99 <- tidy_parameters(fit, conf.level = 0.99)
  expect_true(all(t90$conf.low <= t90$estimate & t90$estimate <= t90$conf.high))
  expect_true(all(t99$conf.high - t99$conf.low >= t90$conf.high - t90$conf.low))
  expect_equal(t90$estimate, t99$estimate)
  # log-link parameters stay positive on the natural scale.
  z <- t90[t90$parameter == "z", ]
  expect_gt(z$conf.low, 0)
})

test_that("tidy_parameters returns NA intervals when the sdreport is unavailable", {
  fit <- ex_fit()
  fit$sdreport <- NULL
  tp <- tidy_parameters(fit)
  expect_true(all(is.na(tp$conf.low)))
  expect_true(all(is.na(tp$conf.high)))
  expect_false(anyNA(tp$estimate))
})
