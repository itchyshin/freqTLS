# Argument validation, target resolution, print/plot, and helper behaviour of the
# profile-likelihood machinery in R/profile.R. The numerical core (closed
# intervals, equivariance, grouped contrasts) is covered by test-profile.R and
# test-group.R; this file covers the error messages and edge helpers.

pe_fit <- function() {
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
  suppressWarnings(
    fit_tls(d, y = survived, n = total, time = duration, temp = temp,
            family = "binomial", tref = 1)
  )
}

pe_grouped <- function() {
  d <- simulate_tls(family = "binomial", group = c("A", "B"),
                    CTmax = c(34, 38), z = c(3, 5), seed = 2)
  suppressWarnings(
    fit_tls(d, y = survived, n = total, time = duration, temp = temp,
            group = group, family = "binomial", tref = 1)
  )
}

test_that("profile() validates its arguments", {
  fit <- pe_fit()
  expect_error(profile(fit, "CTmax", extra = 1), "reserved")
  expect_error(profile.profile_tls(list(), "CTmax"), "profile_tls")
  expect_error(profile(fit), "single target name")
  expect_error(profile(fit, c("CTmax", "z")), "single target name")
  expect_error(profile(fit, 1), "single target name")
  expect_error(profile(fit, NULL), "single target name")
  expect_error(profile(fit, "CTmax", level = 0), "single number in \\(0, 1\\)")
  expect_error(profile(fit, "CTmax", level = 1), "single number in \\(0, 1\\)")
  expect_error(profile(fit, "CTmax", level = c(0.9, 0.95)),
               "single number in \\(0, 1\\)")
  expect_error(profile(fit, "CTmax", level = "a"), "single number in \\(0, 1\\)")
  expect_error(profile(fit, "CTmax", npoints = 3), "single number >= 5")
  expect_error(profile(fit, "CTmax", npoints = c(10, 20)), "single number >= 5")
  no_obj <- fit
  no_obj$obj <- NULL
  expect_error(profile(no_obj, "CTmax"), "live TMB object")
})

test_that("profile() explains unknown and inapplicable targets", {
  fit <- pe_fit()
  expect_error(profile(fit, "phi"), "only defined for the beta-binomial family")
  expect_error(profile(fit, "banana"), "Unknown profile target")
  expect_error(profile(fit, "dCTmax:A-B"), "require a grouped fit")
})

test_that("grouped targets must name a fitted level", {
  fg <- pe_grouped()
  expect_error(profile(fg, "CTmax"), "ambiguous in a grouped fit")
  expect_error(profile(fg, "CTmax:Z"), "not a level of this fit")
  expect_error(profile(fg, "low:A"), "single shared shape")
  expect_error(profile(fg, "dCTmax:A"), "Could not parse contrast")
  expect_error(profile(fg, "dCTmax:A-Z"), "must both be levels")
  expect_error(profile(fg, "dCTmax:A-A"), "two different groups")
})

test_that("profile objects print and plot with an honest confidence label", {
  fit <- pe_fit()
  pr <- profile(fit, "CTmax", npoints = 9)
  expect_s3_class(pr, "profile_tls_profile")
  expect_identical(pr$parm, "CTmax")
  expect_lt(pr$conf.low, pr$estimate)
  expect_gt(pr$conf.high, pr$estimate)
  expect_identical(pr$conf.status, "ok")

  expect_message(print(pr), "freqTLS profile")
  expect_message(print(pr), "interval type: profile")
  expect_message(print(pr), "deviance grid")
  expect_identical(suppressMessages(print(pr)), pr)

  p <- plot(pr)
  expect_s3_class(p, "ggplot")
  expect_match(p$labels$caption, "Profile likelihood-ratio confidence interval")
  expect_no_match(p$labels$caption, "posterior|credible")
  expect_error(plot(pr, 1), "reserved")
})

test_that("`up` uses a Wald interval, prints as such, and cannot be plotted", {
  fit <- pe_fit()
  pr <- suppressWarnings(profile(fit, "up", npoints = 9))
  expect_identical(pr$conf.status, "wald_fallback")
  expect_length(pr$deviance, 0L)
  est <- fit$estimates$estimate[fit$estimates$parameter == "up"]
  expect_equal(pr$estimate, est, tolerance = 1e-8)
  expect_lt(pr$conf.low, est)
  expect_gt(pr$conf.high, est)
  expect_message(print(pr), "interval type: Wald/delta")
  expect_error(plot(pr), "no deviance curve to plot")
})

test_that("the profile interval is level-monotone", {
  fit <- pe_fit()
  p80 <- profile(fit, "z", level = 0.8, npoints = 9)
  p99 <- profile(fit, "z", level = 0.99, npoints = 9)
  expect_lt(p99$conf.low, p80$conf.low)
  expect_gt(p99$conf.high, p80$conf.high)
  expect_lt(p80$cutoff, p99$cutoff)
})

test_that("tls_profile_multimodal flags a deviance that falls after rising", {
  grid <- seq(-3, 3, by = 1)
  quad <- grid^2
  expect_false(tls_profile_multimodal(grid, quad, theta_hat = 0))
  # A second dip on the right side: 0, 1, 4, then back down to 2 at +3.
  dip <- c(9, 4, 1, 0, 1, 4, 2)
  expect_true(tls_profile_multimodal(grid, dip, theta_hat = 0))
  # ... and on the left side.
  dip_left <- c(2, 4, 1, 0, 1, 4, 9)
  expect_true(tls_profile_multimodal(grid, dip_left, theta_hat = 0))
  # Too few finite points: nothing to judge.
  expect_false(tls_profile_multimodal(grid[1:3], quad[1:3], theta_hat = 0))
  # Non-finite values are ignored.
  expect_false(tls_profile_multimodal(grid, replace(quad, 1, NA), theta_hat = 0))
  # Tiny numerical wiggles are tolerated.
  wiggle <- c(9, 4, 1, 0, 1, 4, 4 - 5e-5)
  expect_false(tls_profile_multimodal(grid, wiggle, theta_hat = 0))
})

test_that("tls_apply_transform maps natural-scale transforms and rejects unknown ones", {
  expect_identical(tls_apply_transform(2, "identity"), 2)
  expect_equal(tls_apply_transform(0, "exp"), 1)
  expect_equal(tls_apply_transform(0, "plogis"), 0.5)
  expect_error(tls_apply_transform(1, "sqrt"), "Unknown transformation")
})

test_that("tls_validate_level accepts only a probability strictly inside (0, 1)", {
  expect_silent(tls_validate_level(0.95))
  expect_error(tls_validate_level(NA_real_), "single number")
  expect_error(tls_validate_level(Inf), "single number")
  expect_error(tls_validate_level(-0.1), "single number")
})
