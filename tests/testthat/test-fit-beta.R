# Tests for the continuous-proportion beta family (family = "beta", family_code
# 2): parameter recovery, the optional `n`, the (0, 1) response validation and
# boundary clamp, the bare-name formula response, profile + bootstrap intervals,
# and that a clean beta fit is silent. SPEC.md S11.

test_that("beta fit recovers the simulating truth (CTmax, z, phi)", {
  d <- simulate_tls(family = "beta", CTmax = 36, z = 4, phi = 20, seed = 7)
  truth <- attr(d, "truth")
  fit <- fit_tls(d, y = prop, time = duration, temp = temp, family = "beta",
                 tref = 1)

  expect_identical(fit$convergence$code, 0L)
  expect_true(isTRUE(fit$convergence$pdHess))

  est <- stats::setNames(fit$estimates$estimate, fit$estimates$parameter)
  expect_lt(abs(est[["CTmax"]] - truth$CTmax), 0.6)
  expect_lt(abs(est[["z"]] - truth$z), 1.0)
  expect_lt(abs(est[["low"]] - truth$low), 0.05)
  expect_lt(abs(est[["up"]] - truth$up), 0.05)
  expect_true(est[["phi"]] > 0)
  expect_lt(abs(log(est[["phi"]]) - log(truth$phi)), 1.0)
})

test_that("n (trials) is optional for beta and required for count families", {
  d <- simulate_tls(family = "beta", CTmax = 36, z = 4, phi = 20, seed = 8)
  fit <- fit_tls(d, y = prop, time = duration, temp = temp, family = "beta")
  expect_identical(fit$convergence$code, 0L)

  db <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 8)
  expect_error(
    fit_tls(db, y = survived, time = duration, temp = temp,
            family = "binomial"),
    regexp = "required for the"
  )
})

test_that("beta response must be a proportion; boundary values clamp with a warning", {
  d <- simulate_tls(family = "beta", CTmax = 36, z = 4, phi = 20, seed = 9)

  bad <- d
  bad$prop[1] <- 1.5
  expect_error(
    fit_tls(bad, y = prop, time = duration, temp = temp, family = "beta"),
    regexp = "proportion"
  )

  edge <- d
  edge$prop[1] <- 0
  edge$prop[2] <- 1
  expect_warning(
    fit_tls(edge, y = prop, time = duration, temp = temp, family = "beta"),
    regexp = "[Cc]lamp"
  )
})

test_that("the formula interface accepts a bare-name proportion response", {
  d <- simulate_tls(family = "beta", CTmax = 36, z = 4, phi = 20, seed = 10)
  fcol <- fit_tls(d, y = prop, time = duration, temp = temp, family = "beta")
  ff <- fit_tls(
    tls_bf(prop ~ time(duration) + temp(temp)),
    data = d, family = "beta", tref = 1
  )
  keys <- c("CTmax", "z", "phi", "low", "up", "k")
  expect_equal(coef(ff)[keys], coef(fcol)[keys], tolerance = 1e-4)
})

test_that("profile and bootstrap intervals are available for the beta family", {
  d <- simulate_tls(family = "beta", CTmax = 36, z = 4, phi = 20, seed = 11)
  fit <- fit_tls(d, y = prop, time = duration, temp = temp, family = "beta")

  pr <- confint(fit, "CTmax", method = "profile")
  expect_true(is.finite(pr$conf.low) && is.finite(pr$conf.high))
  expect_lt(pr$conf.low, pr$conf.high)

  # phi is profilable for beta (log_phi is a free parameter).
  pr_phi <- confint(fit, "phi", method = "profile")
  expect_true(is.finite(pr_phi$conf.low) && is.finite(pr_phi$conf.high))

  # The parametric bootstrap must draw beta proportions, not binomial counts.
  bs <- confint(fit, "CTmax", method = "bootstrap", nboot = 60, boot_seed = 1)
  expect_true(is.finite(bs$conf.low) && is.finite(bs$conf.high))
  expect_lt(bs$conf.low, bs$conf.high)
})

test_that("the beta family supports grouped CTmax / z", {
  d <- simulate_tls(family = "beta", group = c("A", "B"),
                    CTmax = c(34, 38), z = c(3, 5), phi = 20, seed = 13)
  fit <- fit_tls(d, y = prop, time = duration, temp = temp, group = group,
                 family = "beta")
  expect_identical(fit$convergence$code, 0L)

  est <- fit$estimates
  ctmax <- stats::setNames(
    est$estimate[startsWith(est$parameter, "CTmax")],
    est$group[startsWith(est$parameter, "CTmax")]
  )
  expect_lt(abs(ctmax[["A"]] - 34), 0.8)
  expect_lt(abs(ctmax[["B"]] - 38), 0.8)
  expect_gt(ctmax[["B"]], ctmax[["A"]] + 2)
})

test_that("a clean beta fit is silent and reports phi with a standard error", {
  d <- simulate_tls(family = "beta", CTmax = 36, z = 4, phi = 20, seed = 12)
  expect_no_warning(
    fit <- fit_tls(d, y = prop, time = duration, temp = temp, family = "beta")
  )
  est <- fit$estimates
  phi_row <- est[est$parameter == "phi", ]
  expect_identical(nrow(phi_row), 1L)
  expect_true(is.finite(phi_row$std.error))
})
