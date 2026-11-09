# Known-truth and edge-case tests for the classical two-stage comparator
# (R/two_stage.R). The data are built so that the per-temperature log10(LT50)
# lies exactly on a line,
#   log10(LT50) = 2 - 0.25 * (temp - 30),
# i.e. slope -0.25 per degree C, so z = 4 and, with duration in minutes and
# t_ref = 60, CTmax = (log10(60) - 9.5) / -0.25. A very large binomial n keeps
# rounding error in the counts negligible.

ts_truth_data <- function(temps = seq(30, 38, by = 2),
                          logd = seq(-1, 3, by = 0.5),
                          n = 10000, slope = -0.25) {
  rows <- lapply(temps, function(tt) {
    lt50 <- 2 + slope * (tt - 30)
    p <- stats::plogis(-3 * (logd - lt50))
    data.frame(temp = tt, duration = 10^logd, total = n,
               survived = round(n * p))
  })
  do.call(rbind, rows)
}

ts_truth_ctmax <- function(t_ref = 60, slope = -0.25, intercept = 9.5) {
  (log10(t_ref) - intercept) / slope
}

test_that("ts_stage1 recovers the true per-temperature log10(LT50)", {
  d <- ts_truth_data()
  st1 <- ts_stage1(d, "temp", "duration", "survived", "total")
  expect_equal(st1$temp, seq(30, 38, by = 2))
  expect_equal(st1$log10_lt50, 2 - 0.25 * (st1$temp - 30), tolerance = 1e-3)
  expect_true(all(st1$slope < 0))
  expect_true(all(is.na(st1$phi)))
  expect_true(all(st1$finite_ok & st1$bracket_ok & st1$stage1_ok))
  expect_true(all(st1$se_log10_lt50 > 0 & st1$se_log10_lt50 < 0.05))
})

test_that("ts_stage1 returns an all-NA row for a temperature with < 3 durations", {
  d <- ts_truth_data()
  thin <- d[d$temp == 34 & d$duration %in% unique(d$duration[d$temp == 34])[1:2], ]
  d <- rbind(d[d$temp != 34, ], thin)
  st1 <- ts_stage1(d, "temp", "duration", "survived", "total")
  row <- st1[st1$temp == 34, ]
  expect_true(is.na(row$log10_lt50))
  expect_true(is.na(row$se_log10_lt50))
  expect_false(row$stage1_ok)
  expect_false(row$finite_ok)
  expect_false(row$bracket_ok)
  expect_equal(sum(st1$stage1_ok), 4L)
})

test_that("ts_stage1 flags an LT50 outside the observed duration range", {
  # LT50 sits at log10(duration) = 2 but only durations <= 10^0.5 were assayed.
  logd <- seq(-1, 0.5, by = 0.5)
  p <- stats::plogis(-3 * (logd - 2))
  d <- data.frame(temp = 30, duration = 10^logd, total = 1000,
                  survived = round(1000 * p))
  st1 <- ts_stage1(d, "temp", "duration", "survived", "total")
  expect_true(st1$finite_ok)
  expect_false(st1$bracket_ok)
  expect_false(st1$stage1_ok)
})

test_that("ts_stage1 rejects an unknown family", {
  expect_error(ts_stage1(ts_truth_data(), "temp", "duration", "survived",
                         "total", family = "poisson"), "should be one of")
})

test_that("ts_stage1 beta-binomial route runs through glmmTMB and reports phi", {
  skip_if_not_installed("glmmTMB")
  set.seed(7)
  logd <- seq(-1, 3, by = 0.5)
  rows <- lapply(c(30, 33, 36), function(tt) {
    lt50 <- 2 - 0.25 * (tt - 30)
    p <- pmin(pmax(stats::plogis(-3 * (logd - lt50)), 0.02), 0.98)
    a <- p * 30; b <- (1 - p) * 30
    data.frame(temp = tt, duration = 10^logd, total = 40,
               survived = stats::rbinom(length(logd), 40,
                                        stats::rbeta(length(logd), a, b)))
  })
  d <- do.call(rbind, rows)
  st1 <- ts_stage1(d, "temp", "duration", "survived", "total",
                   family = "betabinomial")
  expect_equal(nrow(st1), 3L)
  expect_true(all(is.finite(st1$phi)))
  expect_true(all(st1$phi > 0))
  expect_equal(st1$log10_lt50, c(2, 1.25, 0.5), tolerance = 0.3)
})

test_that("ts_stage2 recovers z and CTmax exactly from a noiseless TDT line", {
  st2 <- ts_stage2(ts_stage1(ts_truth_data(), "temp", "duration", "survived",
                             "total"), t_ref = 60, time_multiplier = 1)
  s <- st2$summary
  expect_equal(s$z, 4, tolerance = 1e-2)
  expect_equal(s$slope_T, -0.25, tolerance = 1e-3)
  expect_equal(s$CTmax, ts_truth_ctmax(), tolerance = 1e-2)
  expect_equal(s$CTmax_1hr, s$CTmax)
  expect_equal(s$n_stage1, 5L)
  expect_equal(s$n_excluded, 0L)
  expect_gt(s$r_squared, 0.9999)
  expect_equal(st2$settings$TC_rate_range, c(0.1, 1))
})

test_that("ts_stage2 shifts CTmax with t_ref but keeps T_crit anchored at 1 h", {
  st1 <- ts_stage1(ts_truth_data(), "temp", "duration", "survived", "total")
  s60  <- ts_stage2(st1, t_ref = 60)$summary
  s600 <- ts_stage2(st1, t_ref = 600)$summary
  # One decade longer exposure lowers CTmax by exactly one z.
  expect_equal(s60$CTmax - s600$CTmax, s60$z, tolerance = 1e-6)
  expect_equal(s60$T_crit, s600$T_crit, tolerance = 1e-8)
  expect_false("CTmax_1hr" %in% names(s600))
})

test_that("ts_stage2 returns a NULL fit and NA summary with fewer than 3 valid temperatures", {
  d <- ts_truth_data(temps = c(30, 32))
  st2 <- ts_stage2(ts_stage1(d, "temp", "duration", "survived", "total"))
  expect_null(st2$fit)
  expect_true(is.na(st2$summary$z))
  expect_true(is.na(st2$summary$CTmax))
  expect_equal(st2$summary$n_stage1, 2L)
  expect_equal(st2$summary$n_excluded, 0L)
})

test_that("ts_stage2 refuses a non-decreasing TDT line", {
  # LT50 increases with temperature: biologically impossible; z would be negative.
  d <- ts_truth_data(slope = 0.25, logd = seq(-1, 5, by = 0.5))
  st1 <- ts_stage1(d, "temp", "duration", "survived", "total")
  st2 <- ts_stage2(st1)
  expect_s3_class(st2$fit, "lm")
  expect_gt(st2$summary$slope_T, 0)
  expect_true(is.na(st2$summary$z))
  expect_true(is.na(st2$summary$CTmax))
  expect_true(is.na(st2$summary$T_crit))
})

test_that("ts_stage2 `rows` selects the Stage-1 validity rule and validates inputs", {
  st1 <- ts_stage1(ts_truth_data(), "temp", "duration", "survived", "total")
  st1$stage1_ok[1] <- FALSE
  expect_equal(ts_stage2(st1, rows = "stage1_ok")$summary$n_stage1, 4L)
  expect_equal(ts_stage2(st1, rows = "stage1_ok")$summary$n_excluded, 1L)
  expect_equal(ts_stage2(st1, rows = "finite_ok")$summary$n_stage1, 5L)
  expect_error(ts_stage2(st1, t_ref = -1))
  expect_error(ts_stage2(st1, time_multiplier = 0))
  expect_error(ts_stage2(st1, rows = "bogus"), "should be one of")
})

test_that("ts_ci delta intervals cover the truth and respect the level", {
  st2 <- ts_stage2(ts_stage1(ts_truth_data(), "temp", "duration", "survived",
                             "total"), t_ref = 60)
  ci95 <- ts_ci(st2, method = "delta", level = 0.95)
  ci50 <- ts_ci(st2, method = "delta", level = 0.5)
  # The Stage-1 estimates sit on the line to ~1e-4, so the intervals are
  # extremely tight; they must contain the point estimate, which must sit on
  # the known truth.
  expect_equal(ci95$z$point, 4, tolerance = 1e-2)
  expect_equal(ci95$CTmax$point, ts_truth_ctmax(), tolerance = 1e-2)
  expect_lt(ci95$z$lower, ci95$z$point)
  expect_gt(ci95$z$upper, ci95$z$point)
  expect_lt(ci95$CTmax$lower, ci95$CTmax$point)
  expect_gt(ci95$CTmax$upper, ci95$CTmax$point)
  expect_equal(ci95$z$point, st2$summary$z)
  expect_equal(ci95$z$upper - ci95$z$point, stats::qnorm(0.975) * ci95$z$se)
  expect_equal(ci95$z$upper_t - ci95$z$point, stats::qt(0.975, 3) * ci95$z$se)
  expect_lt(ci50$z$upper - ci50$z$lower, ci95$z$upper - ci95$z$lower)
  expect_identical(ci95$df_resid, 3L)
})

test_that("ts_ci delta returns NA blocks when Stage 2 has no fit", {
  st2 <- ts_stage2(ts_stage1(ts_truth_data(temps = c(30, 32)), "temp",
                             "duration", "survived", "total"), t_ref = 60)
  ci <- ts_ci(st2, method = "delta")
  expect_true(all(is.na(unlist(ci$z))))
  expect_true(all(is.na(unlist(ci$CTmax))))
  expect_true(is.na(ci$df_resid))
  expect_equal(ci$CTmax_1hr, ci$CTmax)
})

test_that("ts_ci mvn gives z, CTmax, T_crit bounds and a monotone LT-vs-T band", {
  st2 <- ts_stage2(ts_stage1(ts_truth_data(), "temp", "duration", "survived",
                             "total"), t_ref = 60)
  ci <- ts_ci(st2, method = "mvn", temp_grid = c(31, 34, 37), n_sim = 500,
              seed = 11)
  s <- ci$summary_ci
  expect_lt(s$z_lower, st2$summary$z); expect_gt(s$z_upper, st2$summary$z)
  expect_lt(s$CTmax_lower, st2$summary$CTmax)
  expect_gt(s$CTmax_upper, st2$summary$CTmax)
  expect_equal(c(s$z_lower, s$z_upper), c(4, 4), tolerance = 1e-2)
  expect_lt(s$Tcrit_lower, s$Tcrit_upper)
  expect_equal(ci$curve_ci$temp, c(31, 34, 37))
  expect_true(all(ci$curve_ci$duration_lower < ci$curve_ci$duration_upper))
  # The band is centred on the fitted line, 10^(9.5 - 0.25 * T).
  fit_line <- ts_curve(st2, c(31, 34, 37))$duration_median
  expect_true(all(ci$curve_ci$duration_lower < fit_line &
                    fit_line < ci$curve_ci$duration_upper))
  expect_equal(fit_line, 10^(9.5 - 0.25 * c(31, 34, 37)), tolerance = 0.02)
  # Same seed, same draws.
  again <- ts_ci(st2, method = "mvn", n_sim = 500, seed = 11)
  expect_equal(again$summary_ci, s)
  expect_equal(nrow(again$curve_ci), 0L)
})

test_that("ts_ci mvn leaves z bounds NA when the slope interval reaches zero", {
  st1 <- ts_stage1(ts_truth_data(), "temp", "duration", "survived", "total")
  # Add noise to Stage-1 LT50s so that the slope CI straddles zero.
  st1$log10_lt50 <- c(1.0, 1.4, 0.8, 1.3, 0.9)
  st2 <- ts_stage2(st1, t_ref = 60)
  skip_if(is.null(st2$fit) || is.na(st2$summary$z),
          "noisy line did not give a negative slope")
  ci <- ts_ci(st2, method = "mvn", n_sim = 200, seed = 1)
  expect_true(is.na(ci$summary_ci$z_lower))
  expect_true(is.na(ci$summary_ci$z_upper))
  expect_true(is.finite(ci$summary_ci$CTmax_lower))
})

test_that("ts_ci mvn returns NA summaries and an NA curve when Stage 2 has no fit", {
  st2 <- ts_stage2(ts_stage1(ts_truth_data(temps = c(30, 32)), "temp",
                             "duration", "survived", "total"), t_ref = 60)
  ci <- ts_ci(st2, method = "mvn", temp_grid = c(31, 33))
  expect_true(all(is.na(unlist(ci$summary_ci))))
  expect_equal(ci$curve_ci$temp, c(31, 33))
  expect_true(all(is.na(ci$curve_ci$duration_lower)))
  expect_equal(nrow(ts_ci(st2, method = "mvn")$curve_ci), 0L)
})

test_that("ts_ci rejects a convention that disagrees with Stage 2", {
  st2 <- ts_stage2(ts_stage1(ts_truth_data(), "temp", "duration", "survived",
                             "total"), t_ref = 60)
  expect_error(ts_ci(st2, t_ref = 120), "must match the convention")
  expect_error(ts_ci(st2, TC_rate_range = c(1, 2)), "must match the convention")
  expect_no_error(ts_ci(st2, t_ref = 60, time_multiplier = 1))
})

test_that("ts_curve is NA without a fit and matches the TDT line otherwise", {
  bad <- ts_stage2(ts_stage1(ts_truth_data(temps = c(30, 32)), "temp",
                             "duration", "survived", "total"))
  cu_bad <- ts_curve(bad, temp_grid = c(31, 33))
  expect_equal(cu_bad$temp, c(31, 33))
  expect_true(all(is.na(cu_bad$duration_median)))

  good <- ts_stage2(ts_stage1(ts_truth_data(), "temp", "duration", "survived",
                              "total"))
  cu <- ts_curve(good, temp_grid = c(30, 34, 38))
  expect_equal(cu$duration_median, 10^(9.5 - 0.25 * c(30, 34, 38)),
               tolerance = 0.02)
})

test_that("hand-built Stage-2 objects without settings use the historical defaults", {
  good <- ts_stage2(ts_stage1(ts_truth_data(), "temp", "duration", "survived",
                              "total"), t_ref = 60, time_multiplier = 1)
  legacy <- list(fit = good$fit, summary = good$summary)
  expect_equal(ts_ci(legacy, method = "delta")$CTmax$point,
               good$summary$CTmax)
  expect_equal(ts_curve(legacy, 34)$duration_median,
               ts_curve(good, 34)$duration_median)
})

test_that("an invalid recorded Stage-2 convention is rejected", {
  good <- ts_stage2(ts_stage1(ts_truth_data(), "temp", "duration", "survived",
                              "total"))
  good$settings$t_ref <- -5
  expect_error(ts_ci(good, method = "delta"), "time convention is invalid")
  good$settings$t_ref <- 60
  good$settings$time_multiplier <- c(1, 2)
  expect_error(ts_curve(good, 34), "time convention is invalid")
})
