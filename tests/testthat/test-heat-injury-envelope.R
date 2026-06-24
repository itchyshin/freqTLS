# heat_injury_envelope() + plot_heat_injury(): a prior-free parametric-bootstrap
# confidence band around the predict_heat_injury() point trajectory. The
# integrator is shared with predict_heat_injury() (tls_injury_traj), so the point
# column equals predict_heat_injury() exactly.

hi_fit <- function(seed = 1) {
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = seed)
  suppressWarnings(fit_tls(d, y = survived, n = total, time = duration,
                           temp = temp, family = "binomial", tref = 1))
}
hi_trace <- function() {
  # A heating ramp that drives survival through the full transition (CTmax = 36),
  # so the bootstrap band clearly widens as damage accumulates.
  tt <- seq(0, 4, by = 0.1)
  data.frame(time = tt, temp = pmin(34 + 2 * tt, 40))
}

test_that("heat_injury_envelope returns a valid band matching the point trajectory", {
  fit <- hi_fit(); trace <- hi_trace()
  env <- suppressWarnings(heat_injury_envelope(fit, trace, nboot = 60, seed = 1))
  expect_s3_class(env, "tbl_df")
  expect_identical(names(env), c("time", "temp", "survival", "conf.low", "conf.high"))
  expect_identical(nrow(env), nrow(trace))

  # The point survival is exactly predict_heat_injury() (shared integrator).
  pt <- predict_heat_injury(fit, trace)
  expect_equal(env$survival, pt$survival, tolerance = 1e-10)

  # A valid band: ordered, in [0, 1].
  expect_true(all(env$conf.low <= env$conf.high + 1e-12))
  expect_true(all(env$conf.low >= 0 & env$conf.high <= 1))

  # Reproducible for a given seed.
  env2 <- suppressWarnings(heat_injury_envelope(fit, trace, nboot = 60, seed = 1))
  expect_equal(env$conf.low, env2$conf.low)
  expect_equal(env$conf.high, env2$conf.high)
})

test_that("the envelope widens in the high-damage region (exponential dose sensitivity)", {
  fit <- hi_fit(); trace <- hi_trace()
  env <- suppressWarnings(heat_injury_envelope(fit, trace, nboot = 80, seed = 2))
  w <- env$conf.high - env$conf.low
  # Near-full survival at the cool start gives a narrow band; once damage
  # accumulates the band widens substantially. (The band is widest through the
  # transition, not necessarily at the saturated tail, so compare max vs start.)
  expect_gt(max(w), 2 * w[1])
})

test_that("plot_heat_injury returns a ggplot with an honest (non-posterior) caption", {
  skip_if_not_installed("ggplot2")
  fit <- hi_fit(); trace <- hi_trace()
  p <- suppressWarnings(plot_heat_injury(fit, trace, nboot = 40, seed = 1,
                                         time_div = 24, xlab = "Day"))
  expect_s3_class(p, "ggplot")
  cap <- p$labels$caption
  expect_match(cap, "confidence")
  expect_false(grepl("posterior|credible", cap, ignore.case = TRUE))
})

test_that("heat_injury_envelope validates its arguments", {
  fit <- hi_fit(); trace <- hi_trace()
  expect_error(heat_injury_envelope(fit, trace, conf.level = 1.2), "conf.level")
  expect_error(plot_heat_injury(fit, trace, time_div = -1), "time_div")
})

test_that("an absolute target_surv envelope brackets target_surv at one lethal dose", {
  fit <- hi_fit(); trace <- hi_trace()
  # With an absolute target the point trajectory still matches predict_heat_injury.
  env <- suppressWarnings(
    heat_injury_envelope(fit, trace, target_surv = 0.5, nboot = 60, seed = 3))
  pt <- predict_heat_injury(fit, trace, target_surv = 0.5)
  expect_equal(env$survival, pt$survival, tolerance = 1e-10)
  expect_true(all(env$conf.low <= env$conf.high + 1e-12))
})
