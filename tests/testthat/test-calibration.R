# Bates-Watts profile-t / Wald-t interval calibration: intervals use a t(df=n-p)
# critical value (small-sample correction), converging to the asymptotic
# chi-square / normal as df grows, and preserving equivariance.

std_sim <- function(seed = 1, ...) {
  standardize_data(simulate_tls(family = "binomial", seed = seed, ...),
                   temp = "temp", duration = "duration",
                   n_total = "total", n_surv = "survived")
}

test_that("tls_ci_df is n_obs - n_par, and small designs give few df", {
  fb <- fit_4pl(std_sim(1, CTmax = 36, z = 4), t_ref = 1, family = "binomial",
                quiet = TRUE)
  expect_identical(freqTLS:::tls_ci_df(fb$fit),
                   length(fb$fit$diag_data$y) - length(fb$fit$par))
  fsm <- fit_4pl(std_sim(2, temps = c(33, 36, 39), times = c(1, 4), reps = 2,
                         CTmax = 36, z = 4),
                 t_ref = 1, family = "binomial", quiet = TRUE)
  expect_lt(freqTLS:::tls_ci_df(fsm$fit), 15L)   # genuinely small-sample
})

test_that("the Wald-t interval is wider than the asymptotic z interval at small df", {
  fsm <- fit_4pl(std_sim(2, temps = c(33, 36, 39), times = c(1, 4), reps = 2,
                         CTmax = 36, z = 4),
                 t_ref = 1, family = "binomial", quiet = TRUE)
  ci <- tls_ctmax(fsm, method = "wald")$summary
  width_t <- ci$upper - ci$lower
  e <- fsm$fit$estimates
  se_ct <- e$std.error[e$parameter == "CTmax"]
  width_z <- 2 * stats::qnorm(0.975) * se_ct        # what the old z-calibration gave
  expect_gt(width_t, width_z)                        # t correction widens it
  # ... and the ratio is the t/z critical-value ratio
  df <- freqTLS:::tls_ci_df(fsm$fit)
  expect_equal(width_t / width_z, stats::qt(0.975, df) / stats::qnorm(0.975),
               tolerance = 1e-6)
})

test_that("profile-t preserves equivariance (z interval == exp of the log_z interval)", {
  f <- fit_4pl(std_sim(1, CTmax = 36, z = 4), t_ref = 1, family = "binomial",
               quiet = TRUE)
  ciz  <- suppressWarnings(confint(f$fit, parm = "z",     method = "profile"))
  cilz <- suppressWarnings(confint(f$fit, parm = "log_z", method = "profile"))
  expect_equal(ciz$conf.low,  exp(cilz$conf.low),  tolerance = 1e-6)
  expect_equal(ciz$conf.high, exp(cilz$conf.high), tolerance = 1e-6)
})
