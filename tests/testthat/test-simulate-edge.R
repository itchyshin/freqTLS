# Argument validation and random-intercept data generation in simulate_tls()
# (R/simulate.R). The generated data are checked against their own stated truth.

test_that("simulate_tls validates asymptotes, scalars, and the family-specific phi", {
  expect_error(simulate_tls(low = 0.6, up = 0.5), "0 < low < up < 1")
  expect_error(simulate_tls(up = 1), "0 < low < up < 1")
  expect_error(simulate_tls(low = 0), "0 < low < up < 1")
  expect_error(simulate_tls(CTmax = "a"), "must be numeric")
  expect_error(simulate_tls(z = "a"), "must be numeric")
  expect_error(simulate_tls(k = 0), "must be positive")
  expect_error(simulate_tls(z = -1), "must be positive")
  expect_error(simulate_tls(tref = 0), "must be positive")
  expect_error(simulate_tls(family = "beta_binomial"), "phi.*required")
  expect_error(simulate_tls(family = "beta"), "phi.*required")
  expect_error(simulate_tls(family = "gamma"), "should be one of")
})

test_that("simulate_tls validates group labels", {
  expect_error(simulate_tls(group = list("A", "B")), "atomic vector")
  expect_error(simulate_tls(group = c("A", NA), CTmax = c(34, 38), z = c(3, 5)),
               "must not contain missing values")
})

test_that("random-intercept simulation validates its own arguments", {
  expect_error(simulate_tls(re_sd = 1), "requires .*n_re_groups")
  expect_error(simulate_tls(re_sd = 1, n_re_groups = 0), "requires .*n_re_groups")
  expect_error(simulate_tls(re_sd = 1, n_re_groups = "a"), "requires .*n_re_groups")
  expect_error(simulate_tls(re_sd = 1, n_re_groups = 5, group = c("A", "B"),
                            CTmax = c(34, 38), z = c(3, 5)),
               "cannot be combined with fixed")
  expect_error(simulate_tls(re_sd = 1, n_re_groups = 5, CTmax = c(34, 38)),
               "single value for an ungrouped simulation")
  expect_error(simulate_tls(re_sd = -1, n_re_groups = 5),
               "must be a single non-negative number")
  expect_error(simulate_tls(re_sd_low = c(1, 2), n_re_groups = 5),
               "must be a single non-negative number")
  expect_error(simulate_tls(re_sd_logk = "a", n_re_groups = 5),
               "must be a single non-negative number")
})

test_that("beta-binomial random-intercept data have the stated structure and truth", {
  d <- simulate_tls(family = "beta_binomial", phi = 25, CTmax = 36, z = 4,
                    re_sd = 1, n_re_groups = 6, reps = 2, seed = 12)
  expect_true(all(c("temp", "duration", "total", "survived", "p", "colony") %in%
                    names(d)))
  expect_setequal(unique(d$colony), paste0("g", 1:6))
  expect_equal(nrow(d), 6L * 7L * 5L * 2L)
  expect_true(all(d$survived >= 0 & d$survived <= d$total))
  expect_true(all(d$p > 0 & d$p < 1))
  # Different colonies have different true probabilities at the same condition.
  at <- d[d$temp == 36 & d$duration == 1, ]
  expect_gt(length(unique(round(at$p, 6))), 1L)
  expect_equal(attr(d, "truth")$CTmax, 36)
})

test_that("beta random-intercept data return a continuous proportion in (0, 1)", {
  d <- simulate_tls(family = "beta", phi = 30, CTmax = 36, z = 4,
                    re_sd = 1, n_re_groups = 5, reps = 2, seed = 13)
  expect_true("prop" %in% names(d))
  expect_false("survived" %in% names(d))
  expect_true(all(d$prop > 0 & d$prop < 1))
  # The simulated proportion tracks the true curve on average: the mean
  # residual relative to p is small and the correlation is high.
  expect_gt(stats::cor(d$prop, d$p), 0.9)
  expect_lt(abs(mean(d$prop - d$p)), 0.03)
})

test_that("random intercepts on low and log_k move only the requested coordinate", {
  d_low <- simulate_tls(re_sd_low = 0.8, n_re_groups = 6, seed = 5, reps = 1)
  d_k <- simulate_tls(re_sd_logk = 0.5, n_re_groups = 6, seed = 5, reps = 1)
  # With the shared CTmax and z, the long-exposure plateau varies only through
  # `low`; the steepness random intercept leaves the plateaus equal.
  plateau <- function(d) {
    sub <- d[d$temp == 42 & d$duration == 8, ]
    stats::setNames(sub$p, sub$colony)
  }
  expect_gt(stats::sd(plateau(d_low)), 0.005)
  expect_lt(stats::sd(plateau(d_k)), 0.05)
  expect_true(all(d_low$p >= 0 & d_low$p <= 1))
})

test_that("simulate_tls is reproducible for a seed and recovers the truth on average", {
  a <- simulate_tls(seed = 3)
  b <- simulate_tls(seed = 3)
  expect_identical(a, b)
  big <- simulate_tls(reps = 200, n = 100, CTmax = 36, z = 4, seed = 4)
  # Mean observed survival matches the true probability at every condition.
  agg <- stats::aggregate(cbind(survived, total, p) ~ temp + duration, big, mean)
  expect_lt(max(abs(agg$survived / agg$total - agg$p)), 0.03)
})
