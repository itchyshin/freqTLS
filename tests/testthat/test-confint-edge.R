# Validation and Wald-route behaviour of confint() (R/confint.R), plus
# make_4pl_formula() argument checks and the fit_4pl() workflow print method.

ce_fit <- function() {
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
  suppressWarnings(
    fit_tls(d, y = survived, n = total, time = duration, temp = temp,
            family = "binomial", tref = 1)
  )
}

test_that("confint validates its arguments", {
  fit <- ce_fit()
  expect_error(confint(fit, extra = 1), "reserved")
  expect_error(confint.profile_tls(list()), "profile_tls")
  expect_error(confint(fit, parm = 1, method = "wald"), "character vector of target names")
  expect_error(confint(fit, level = 1.2, method = "wald"), "single number in \\(0, 1\\)")
  expect_error(confint(fit, method = "likelihood"), "should be one of")
})

test_that("Wald intervals default to every parameter and bracket the estimates", {
  fit <- ce_fit()
  ci <- confint(fit, method = "wald")
  expect_setequal(ci$parameter, fit$estimates$parameter)
  expect_true(all(ci$method == "wald"))
  expect_equal(ci$estimate[match(fit$estimates$parameter, ci$parameter)],
               fit$estimates$estimate, tolerance = 1e-8)
  expect_true(all(ci$conf.low <= ci$estimate & ci$estimate <= ci$conf.high))
  # A 95% Wald interval for CTmax is est +/- qt * SE on the natural scale.
  se <- fit$estimates$std.error[fit$estimates$parameter == "CTmax"]
  ct <- ci[ci$parameter == "CTmax", ]
  expect_equal(ct$conf.high - ct$conf.low, 2 * stats::qt(0.975, df = tls_ci_df(fit)) * se,
               tolerance = 1e-4)
})

test_that("Wald log_z is the log of the z interval and unknown targets are rejected", {
  fit <- ce_fit()
  ci <- confint(fit, parm = c("z", "log_z"), method = "wald")
  z <- ci[ci$parameter == "z", ]
  lz <- ci[ci$parameter == "log_z", ]
  expect_equal(lz$conf.low, log(z$conf.low), tolerance = 1e-10)
  expect_equal(lz$conf.high, log(z$conf.high), tolerance = 1e-10)
  expect_equal(lz$estimate, log(z$estimate), tolerance = 1e-10)
  expect_identical(lz$scale, "log")
  expect_error(confint(fit, parm = "bogus", method = "wald"), "Unknown Wald target")
})

test_that("a wider confidence level gives a wider Wald interval", {
  fit <- ce_fit()
  w80 <- confint(fit, parm = "CTmax", level = 0.8, method = "wald")
  w99 <- confint(fit, parm = "CTmax", level = 0.99, method = "wald")
  expect_lt(w99$conf.low, w80$conf.low)
  expect_gt(w99$conf.high, w80$conf.high)
  expect_equal(w80$level, 0.8)
})

test_that("make_4pl_formula rejects malformed by and shape arguments", {
  expect_error(make_4pl_formula(by = c("a", "b")), "one non-missing column name")
  expect_error(make_4pl_formula(by = NA_character_), "one non-missing column name")
  expect_error(make_4pl_formula(by = ""), "one non-missing column name")
  expect_error(make_4pl_formula(by = 1), "one non-missing column name")
  expect_error(make_4pl_formula(low = "group"), "one-sided formulas")
  expect_error(make_4pl_formula(k = 3), "one-sided formulas")

  f <- make_4pl_formula(by = "pop", family = "binomial")
  expect_s3_class(f, "tls_formula")
  expect_identical(deparse1(f$sub_formulas$CTmax), "CTmax ~ 0 + pop")
  expect_identical(deparse1(f$sub_formulas$log_z), "log_z ~ 0 + pop")
  expect_identical(deparse1(f$response),
                   "n_surv | trials(n_total) ~ time(duration) + temp(temp)")
  beta <- make_4pl_formula(family = "beta")
  expect_identical(deparse1(beta$response),
                   "survival ~ time(duration) + temp(temp)")
})

test_that("print.freq_tls summarises the data, family, and convergence", {
  raw <- simulate_tls(family = "binomial", group = c("A", "B"),
                      CTmax = c(34, 38), z = c(3, 5), seed = 6)
  dat <- standardize_data(raw, temp = "temp", duration = "duration",
                          n_total = "total", n_surv = "survived")
  wf <- fit_4pl(dat, family = "binomial", t_ref = 60, quiet = TRUE)
  out <- utils::capture.output(res <- print(wf))
  expect_identical(out[1], "<freq_tls>")
  expect_match(out[2], sprintf("Data:    %d rows; %d temperatures; %d durations",
                               nrow(dat), length(unique(dat$temp)),
                               length(unique(dat$duration))), fixed = TRUE)
  expect_true(any(grepl("Family:  binomial", out, fixed = TRUE)))
  expect_true(any(grepl("t_ref = 60", out, fixed = TRUE)))
  expect_true(any(grepl("Fit:     converged (pdHess = TRUE)", out, fixed = TRUE)))
  expect_identical(res, wf)
})
