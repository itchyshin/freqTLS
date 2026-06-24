# Recovery test for the binomial 4PL fit. A single moderately dense simulated
# dataset should recover the data-generating CTmax, z, and shape with the
# tolerances in SPEC.md S11. Fast: one fit, fixed seed.

test_that("binomial fit recovers the simulating truth and converges", {
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
  truth <- attr(d, "truth")
  fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
                 family = "binomial", tref = 1)

  # Converged with a positive-definite Hessian.
  expect_identical(fit$convergence$code, 0L)
  expect_true(isTRUE(fit$convergence$pdHess))
  expect_true(is.finite(fit$logLik))

  est <- stats::setNames(fit$estimates$estimate, fit$estimates$parameter)

  # CTmax within 0.4 degrees C; z within 0.6 (absolute).
  expect_lt(abs(est[["CTmax"]] - truth$CTmax), 0.4)
  expect_lt(abs(est[["z"]] - truth$z), 0.6)

  # Asymptotes within 0.05 (absolute).
  expect_lt(abs(est[["low"]] - truth$low), 0.05)
  expect_lt(abs(est[["up"]] - truth$up), 0.05)

  # k within 30% relative.
  expect_lt(abs(est[["k"]] - truth$k) / truth$k, 0.30)
})

test_that("binomial fit has the expected object contract", {
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
  fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
                 family = "binomial", tref = 1)

  expect_s3_class(fit, "profile_tls")
  expect_identical(fit$family$family, "binomial")
  # Binomial has no phi row.
  expect_false("phi" %in% fit$estimates$parameter)
  # df = 5 free parameters (beta_low, beta_gap, beta_logk, beta_CT, beta_logz).
  expect_identical(fit$df, 5L)
  expect_identical(fit$data_summary$n_groups, 1L)
})
