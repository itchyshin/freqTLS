# Grouped-fit tests (SPEC.md S11, test-group). A two-group binomial simulation
# with distinct CTmax and z per group should recover the contrasts within
# tolerance, and the grouped / contrast profile targets should return finite,
# closed intervals. One fit, fixed seed, so the test stays fast.

fit_grouped <- function(seed = 2) {
  dg <- simulate_tls(family = "binomial", group = c("A", "B"),
                     CTmax = c(34, 38), z = c(3, 5), seed = seed)
  suppressWarnings(
    fit_tls(dg, y = survived, n = total, time = duration, temp = temp,
            group = group, family = "binomial", tref = 1)
  )
}

test_that("the grouped fit recovers the per-group CTmax and z", {
  fg <- fit_grouped()
  est <- stats::setNames(fg$estimates$estimate, fg$estimates$parameter)
  # Per-group CTmax within 0.6 C, z within 0.8 (absolute).
  expect_lt(abs(est[["CTmax:A"]] - 34), 0.6)
  expect_lt(abs(est[["CTmax:B"]] - 38), 0.6)
  expect_lt(abs(est[["z:A"]] - 3), 0.8)
  expect_lt(abs(est[["z:B"]] - 5), 0.8)
})

test_that("the grouped fit recovers the CTmax and z contrasts", {
  fg <- fit_grouped()
  est <- stats::setNames(fg$estimates$estimate, fg$estimates$parameter)
  # Delta CTmax = CTmax_B - CTmax_A ~ 4 (tol 0.6).
  expect_lt(abs((est[["CTmax:B"]] - est[["CTmax:A"]]) - 4), 0.6)
  # Delta z = z_B - z_A ~ 2 (tol 0.8).
  expect_lt(abs((est[["z:B"]] - est[["z:A"]]) - 2), 0.8)
})

test_that("grouped CTmax:grp and z:grp profile to finite closed intervals", {
  fg <- fit_grouped()
  ciC <- suppressWarnings(confint(fg, "CTmax:A", method = "profile"))
  expect_true(is.finite(ciC$conf.low) && is.finite(ciC$conf.high))
  expect_lt(ciC$conf.low, ciC$estimate)
  expect_gt(ciC$conf.high, ciC$estimate)
  expect_identical(ciC$conf.status, "ok")

  ciZ <- suppressWarnings(confint(fg, "z:B", method = "profile"))
  expect_true(is.finite(ciZ$conf.low) && is.finite(ciZ$conf.high))
  expect_lt(ciZ$conf.low, ciZ$estimate)
  expect_gt(ciZ$conf.high, ciZ$estimate)
  expect_gt(ciZ$conf.low, 0)
})

test_that("the dCTmax contrast profile matches the per-group difference and closes", {
  fg <- fit_grouped()
  est <- stats::setNames(fg$estimates$estimate, fg$estimates$parameter)

  cc <- suppressWarnings(confint(fg, "dCTmax:A-B", method = "profile"))
  # The written A-B contrast equals CTmax_A - CTmax_B from the
  # ~ 0 + group fit (equivariance of the reparameterisation).
  expect_equal(cc$estimate, unname(est[["CTmax:A"]] - est[["CTmax:B"]]),
               tolerance = 1e-4)
  expect_true(is.finite(cc$conf.low) && is.finite(cc$conf.high))
  expect_lt(cc$conf.low, cc$estimate)
  expect_gt(cc$conf.high, cc$estimate)
})

test_that("the dlog_z contrast profile matches the per-group log-z difference", {
  fg <- fit_grouped()
  est <- stats::setNames(fg$estimates$estimate, fg$estimates$parameter)

  cl <- suppressWarnings(confint(fg, "dlog_z:A-B", method = "profile"))
  expect_equal(cl$estimate, unname(log(est[["z:A"]]) - log(est[["z:B"]])),
               tolerance = 1e-4)
  expect_true(is.finite(cl$conf.low) && is.finite(cl$conf.high))
  # The z ratio is exp(dlog_z); recovers z_A / z_B ~ 3/5 within tolerance.
  expect_lt(abs(exp(cl$estimate) - 3 / 5), 0.25)
})

test_that("bootstrap contrasts follow the written A-minus-B direction", {
  fit <- list(estimates = data.frame(
    parameter = c("CTmax:A", "CTmax:B", "z:A", "z:B"),
    estimate = c(36, 40, 3, 5)
  ))
  reps <- cbind(
    `CTmax:A` = c(35, 36), `CTmax:B` = c(39, 41),
    `z:A` = c(2.5, 3.5), `z:B` = c(4.5, 5.5)
  )

  ct <- tls_boot_target("dCTmax:A-B", fit, reps)
  lz <- tls_boot_target("dlog_z:A-B", fit, reps)

  expect_equal(ct$estimate, -4)
  expect_equal(ct$values, c(-4, -5))
  expect_equal(lz$estimate, log(3) - log(5))
  expect_equal(lz$values, log(reps[, "z:A"]) - log(reps[, "z:B"]))
})
