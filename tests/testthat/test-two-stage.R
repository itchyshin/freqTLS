# two_stage (ts_*) — the classical two-stage comparator (per-temperature LT50,
# then linear log10(LT50) ~ T). Engine-agnostic; the binomial path uses glm so
# these run without glmmTMB. Twinned from bayesTLS.

test_that("two-stage (binomial) recovers CTmax/z and reports normal + t intervals", {
  s <- standardize_data(
    simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1),
    temp = "temp", duration = "duration", n_total = "total", n_surv = "survived")
  st1 <- ts_stage1(s, family = "binomial")
  expect_true(all(c("temp", "log10_lt50", "stage1_ok") %in% names(st1)))
  expect_gte(sum(st1$stage1_ok), 3L)

  st2 <- ts_stage2(st1, t_ref = 1, time_multiplier = 1)
  expect_true(all(c("z", "CTmax_1hr", "r_squared", "T_crit") %in% names(st2$summary)))
  expect_equal(st2$summary$CTmax_1hr, 36, tolerance = 1.0)
  expect_gt(st2$summary$r_squared, 0.9)

  ci <- ts_ci(st2, method = "delta", t_ref = 1, time_multiplier = 1)
  expect_true(all(c("point", "lower", "upper", "lower_t", "upper_t", "se") %in% names(ci$z)))
  # The small-sample t interval is wider than the normal interval (Daniel's audit
  # point: with few Stage-1 temperatures the t correction matters).
  expect_lt(ci$z$lower_t, ci$z$lower)
  expect_gt(ci$z$upper_t, ci$z$upper)
  expect_identical(ci$df_resid, sum(st1$stage1_ok) - 2L)
})

test_that("ts_curve returns a fitted duration curve over the temperature grid", {
  s <- standardize_data(
    simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 2),
    temp = "temp", duration = "duration", n_total = "total", n_surv = "survived")
  st2 <- ts_stage2(ts_stage1(s, family = "binomial"), t_ref = 1, time_multiplier = 1)
  cu <- ts_curve(st2, temp_grid = c(33, 36, 39))
  expect_true("temp" %in% names(cu))
  expect_equal(nrow(cu), 3L)
})
