# Random intercepts on the shape coordinates low and log_k (item 5 stretch):
# low ~ <fixed> + (1 | group), log_k ~ <fixed> + (1 | group). Parallel to the
# CTmax / log_z random intercepts; the upper-asymptote gap (up) is excluded (no
# single coordinate). Engine: b_low / log_sd_low / re_index_low and
# b_logk / log_sd_logk / re_index_logk (src/profile_tls.cpp).

re_low_formula <- function() {
  tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
         low ~ 1 + (1 | colony))
}
re_logk_formula <- function() {
  tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
         log_k ~ 1 + (1 | colony))
}
# A design with enough long-duration / high-temperature coverage to inform the
# shape coordinates per group.
shp_temps <- seq(33, 39, by = 1.5)
shp_times <- c(1, 2, 4, 8, 16)

test_that("a random intercept on low fits, converges, and surfaces sigma_low", {
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, low = 0.1, up = 0.98,
                    temps = shp_temps, times = shp_times, reps = 3, n = 30,
                    re_sd_low = 0.6, n_re_groups = 16, seed = 101)
  fit <- suppressWarnings(fit_tls(re_low_formula(), data = d, family = "binomial",
                                  tref = 1))
  expect_identical(fit$convergence$code, 0L)
  expect_false(is.null(fit$re_low))
  expect_true(is.null(fit$re))
  expect_identical(fit$re_low$n, 16L)
  expect_identical(fit$tmb_inputs$random, "b_low")

  est <- fit$estimates
  expect_true("sigma_low" %in% est$parameter)
  sg <- est$estimate[est$parameter == "sigma_low"]
  expect_true(is.finite(sg) && sg > 0)
  # Fixed effects (CTmax, z) recover even with the shape RE.
  expect_true(est$estimate[est$parameter == "CTmax"] > 35 &&
                est$estimate[est$parameter == "CTmax"] < 37)
  expect_true(est$estimate[est$parameter == "z"] > 3.3 &&
                est$estimate[est$parameter == "z"] < 4.7)
})

test_that("a random intercept on log_k fits, converges, and surfaces sigma_logk", {
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, k = 5,
                    temps = shp_temps, times = shp_times, reps = 3, n = 30,
                    re_sd_logk = 0.3, n_re_groups = 16, seed = 202)
  fit <- suppressWarnings(fit_tls(re_logk_formula(), data = d, family = "binomial",
                                  tref = 1))
  expect_identical(fit$convergence$code, 0L)
  expect_false(is.null(fit$re_logk))
  expect_identical(fit$re_logk$n, 16L)
  expect_identical(fit$tmb_inputs$random, "b_logk")
  est <- fit$estimates
  expect_true("sigma_logk" %in% est$parameter)
  sg <- est$estimate[est$parameter == "sigma_logk"]
  expect_true(is.finite(sg) && sg > 0)
})

test_that("the no-RE formula fit is unchanged by the shape RE machinery", {
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 7)
  f_col <- suppressWarnings(fit_tls(d, y = survived, n = total, time = duration,
                                    temp = temp, family = "binomial", tref = 1))
  f_form <- suppressWarnings(fit_tls(
    tls_bf(survived | trials(total) ~ time(duration) + temp(temp)),
    data = d, family = "binomial", tref = 1))
  expect_true(is.null(f_col$re_low) && is.null(f_col$re_logk))
  expect_equal(f_col$estimates$estimate, f_form$estimates$estimate, tolerance = 1e-8)
  expect_false(any(c("sigma_low", "sigma_logk") %in% f_col$estimates$parameter))
})

test_that("ranef() returns low / log_k BLUPs with the right term labels", {
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, low = 0.1,
                    temps = shp_temps, times = shp_times, reps = 3, n = 30,
                    re_sd_low = 0.6, n_re_groups = 12, seed = 42)
  fit <- suppressWarnings(fit_tls(re_low_formula(), data = d, family = "binomial",
                                  tref = 1))
  re <- ranef(fit)
  expect_s3_class(re, "tbl_df")
  expect_identical(nrow(re), 12L)
  expect_true(all(re$term == "low"))
  expect_true(all(is.finite(re$estimate)))

  # sigma_low gets a positive log-scale Wald interval.
  ci <- suppressMessages(confint(fit, "sigma_low", method = "wald"))
  expect_gt(ci$conf.low, 0)
  expect_lt(ci$conf.low, ci$conf.high)
})

test_that("RE on the upper asymptote (up) and shape random slopes are rejected", {
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4,
                    re_sd_low = 0.5, n_re_groups = 6, seed = 3)
  # up has no single coordinate -> RE rejected with a clear message.
  expect_error(
    suppressWarnings(fit_tls(
      tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
             up ~ (1 | colony)),
      data = d, family = "binomial", tref = 1)),
    "up|CTmax|log_z|low|log_k"
  )
  # Random slope on a shape is rejected.
  expect_error(
    suppressWarnings(fit_tls(
      tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
             low ~ (temp | colony)),
      data = d, family = "binomial", tref = 1)),
    "random intercept|slope"
  )
})

test_that("a shape RE and a CTmax RE on the same grouping warn (generalised)", {
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, low = 0.1,
                    temps = shp_temps, times = shp_times, reps = 3, n = 30,
                    re_sd = 1.0, re_sd_low = 0.6, n_re_groups = 14, seed = 9)
  expect_warning(
    fit <- fit_tls(
      tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
             CTmax ~ 1 + (1 | colony), low ~ 1 + (1 | colony)),
      data = d, family = "binomial", tref = 1),
    "independent|share|correlat"
  )
  expect_false(is.null(fit$re))
  expect_false(is.null(fit$re_low))
  expect_setequal(fit$tmb_inputs$random, c("b_CT", "b_low"))
  est <- fit$estimates
  expect_true(all(c("sigma_CTmax", "sigma_low") %in% est$parameter))
  re <- ranef(fit)
  expect_setequal(unique(re$term), c("CTmax", "low"))
})

test_that("a fixed effect profiles under a shape (low) RE (slow; skipped on CRAN)", {
  skip_on_cran()
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, low = 0.1,
                    temps = seq(33, 39, by = 2), times = c(1, 2, 4, 8), reps = 2,
                    re_sd_low = 0.6, n_re_groups = 6, seed = 5)
  fit <- suppressWarnings(fit_tls(re_low_formula(), data = d, family = "binomial",
                                  tref = 1))
  # Profiling a fixed effect re-runs the Laplace with random = "b_low" at each
  # grid point; confirms the profile-under-RE path works for a shape RE block.
  ci <- suppressMessages(confint(fit, "CTmax", method = "profile", npoints = 6))
  expect_identical(ci$method, "profile")
  expect_true(is.finite(ci$conf.low) && is.finite(ci$conf.high))
  expect_lt(ci$conf.low, ci$conf.high)
  expect_lt(ci$conf.low, 36)
  expect_gt(ci$conf.high, 36)
})

test_that("simulate_tls re_sd_low / re_sd_logk modes validate and record truth", {
  expect_error(
    simulate_tls(family = "binomial", re_sd_low = 0.5),  # missing n_re_groups
    "n_re_groups"
  )
  expect_error(
    simulate_tls(family = "binomial", re_sd_logk = 0.3, n_re_groups = 5,
                 group = c("A", "B"), CTmax = c(35, 38), z = c(4, 3)),
    "cannot be combined"
  )
  d <- simulate_tls(family = "binomial", re_sd_low = 0.5, re_sd_logk = 0.3,
                    n_re_groups = 8, seed = 1)
  expect_identical(length(unique(d$colony)), 8L)
  expect_identical(attr(d, "truth")$re_sd_low, 0.5)
  expect_identical(attr(d, "truth")$re_sd_logk, 0.3)
  expect_identical(length(attr(d, "truth")$b_low), 8L)
})
