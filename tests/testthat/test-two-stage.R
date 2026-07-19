# two_stage (ts_*) — the classical two-stage comparator (per-temperature LT50,
# then linear log10(LT50) ~ T). Engine-agnostic; the binomial path uses glm so
# these run without glmmTMB. Twinned from bayesTLS.

two_stage_example_data <- function(seed = 1) {
  simulate_tls(
    family = "binomial", temps = seq(30, 42, by = 2),
    times = c(0.01, 0.03, 0.1, 0.3, 1, 3, 10, 30, 100),
    reps = 4, n = 50, CTmax = 36, z = 4, seed = seed
  )
}

test_that("two-stage (binomial) recovers CTmax/z and reports normal + t intervals", {
  s <- two_stage_example_data()
  st1 <- ts_stage1(s, temp = "temp", duration = "duration",
                   n_surv = "survived", n_total = "total", family = "binomial")
  expect_true(all(c("temp", "log10_lt50", "stage1_ok") %in% names(st1)))
  expect_gte(sum(st1$stage1_ok), 3L)

  st2 <- ts_stage2(st1, t_ref = 60, time_multiplier = 60)
  expect_true(all(c("z", "CTmax", "r_squared", "T_crit") %in% names(st2$summary)))
  expect_equal(st2$summary$CTmax, 36, tolerance = 1.0)
  expect_equal(st2$settings$t_ref, 60)
  expect_equal(st2$settings$time_multiplier, 60)
  expect_equal(st2$summary$CTmax_1hr, st2$summary$CTmax)
  expect_gt(st2$summary$r_squared, 0.9)

  ci <- ts_ci(st2, method = "delta")
  expect_true(all(c("point", "lower", "upper", "lower_t", "upper_t", "se") %in% names(ci$z)))
  expect_true(all(is.finite(unlist(ci$CTmax))))
  expect_equal(ci$CTmax_1hr, ci$CTmax)
  # The small-sample t interval is wider than the normal interval (Daniel's audit
  # point: with few Stage-1 temperatures the t correction matters).
  expect_lt(ci$z$lower_t, ci$z$lower)
  expect_gt(ci$z$upper_t, ci$z$upper)
  expect_identical(ci$df_resid, sum(st1$stage1_ok) - 2L)
})

test_that("ts_curve returns a fitted duration curve over the temperature grid", {
  s <- two_stage_example_data(seed = 2)
  st2 <- ts_stage2(ts_stage1(s, "temp", "duration", "survived", "total",
                             family = "binomial"), t_ref = 60, time_multiplier = 60)
  cu <- ts_curve(st2, temp_grid = c(33, 36, 39))
  expect_true("temp" %in% names(cu))
  expect_equal(nrow(cu), 3L)
  expect_true(all(is.finite(cu$duration_median)))
})

test_that("two-stage time conventions are inherited and unit-equivalent", {
  hours <- two_stage_example_data(seed = 3)
  minutes <- hours
  minutes$duration <- minutes$duration * 60

  st1_h <- ts_stage1(hours, "temp", "duration", "survived", "total")
  st1_m <- ts_stage1(minutes, "temp", "duration", "survived", "total")
  st2_h <- ts_stage2(st1_h, t_ref = 60, time_multiplier = 60)
  st2_m <- ts_stage2(st1_m, t_ref = 60, time_multiplier = 1)

  expect_equal(st2_h$summary$CTmax, st2_m$summary$CTmax, tolerance = 1e-8)
  expect_equal(ts_ci(st2_h, method = "delta")$CTmax$point,
               ts_ci(st2_m, method = "delta")$CTmax$point, tolerance = 1e-8)
  expect_equal(ts_curve(st2_h, 36)$duration_median,
               ts_curve(st2_m, 36)$duration_median, tolerance = 1e-8)
  expect_error(ts_ci(st2_h, method = "delta", time_multiplier = 1),
               "must match the convention")
  expect_error(ts_curve(st2_h, 36, time_multiplier = 1),
               "must match the convention")

  st2_4h <- ts_stage2(st1_h, t_ref = 240, time_multiplier = 60)
  expect_false("CTmax_1hr" %in% names(st2_4h$summary))
  expect_null(ts_ci(st2_4h, method = "delta")$CTmax_1hr)
})
