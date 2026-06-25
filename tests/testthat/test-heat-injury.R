# Deterministic heat-injury prediction from the fitted curve under a temperature
# trace (the maximum-likelihood analogue of bayesTLS::predict_heat_injury). No
# model is fitted here; injury is accumulated from the already-fitted 4PL.

test_that("constant-temperature exposure to one lethal time gives midpoint survival", {
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
  fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
                 family = "binomial", tref = 1)
  sh <- coef(fit)
  mid_surv <- (sh[["low"]] + sh[["up"]]) / 2
  t0 <- 38
  lt <- derive_lt(fit, p = mid_surv, temp = t0) # relative lethal time at t0

  trace <- data.frame(time = seq(0, lt, length.out = 200), temp = t0)
  hi <- predict_heat_injury(fit, trace)

  # Dose reaches ~1 (one lethal dose) at t = LT; survival ~ the relative midpoint.
  expect_equal(hi$dose[nrow(hi)], 1, tolerance = 1e-3)
  expect_equal(hi$survival[nrow(hi)], mid_surv, tolerance = 0.02)
  # Survival starts at `up` and is monotone non-increasing.
  expect_equal(hi$survival[1], sh[["up"]], tolerance = 1e-6)
  expect_true(all(diff(hi$survival) <= 1e-9))
  expect_equal(hi$injury, hi$dose * 100, tolerance = 1e-8)
})

test_that("a damage cutoff at T_c freezes injury below it", {
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
  fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
                 family = "binomial", tref = 1)
  trace <- data.frame(time = 0:50, temp = 30) # well below CTmax
  hi <- predict_heat_injury(fit, trace, t_c = 34)
  expect_true(all(hi$dose == 0))
  expect_equal(hi$survival, rep(coef(fit)[["up"]], nrow(trace)), tolerance = 1e-6)
})

test_that("predict_heat_injury validates the trace", {
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
  fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
                 family = "binomial", tref = 1)
  expect_error(predict_heat_injury(fit, data.frame(time = 1, temp = 38)),
               "two")
  expect_error(predict_heat_injury(fit, data.frame(t = 1:3, temp = 38)),
               "time")
  expect_error(predict_heat_injury(fit, data.frame(time = c(0, 2, 1), temp = 38)),
               "increasing")
})

test_that("an absolute survival target reaches that survival at one lethal dose", {
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
  fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
                 family = "binomial", tref = 1)
  sh <- coef(fit)
  t0 <- 38
  # An absolute target strictly inside the fitted asymptotes (not the midpoint).
  target <- sh[["low"]] + 0.8 * (sh[["up"]] - sh[["low"]])
  lt_t <- derive_lt(fit, p = target, temp = t0) # lethal time to the target survival

  trace <- data.frame(time = seq(0, lt_t, length.out = 200), temp = t0)
  hi <- predict_heat_injury(fit, trace, target_surv = target)

  # One target-lethal dose has accumulated at t = LT(target); survival ~ target.
  expect_equal(hi$dose[nrow(hi)], 1, tolerance = 1e-3)
  expect_equal(hi$survival[nrow(hi)], target, tolerance = 1e-3)
  # Still starts at full survival (`up`) and is monotone non-increasing.
  expect_equal(hi$survival[1], sh[["up"]], tolerance = 1e-6)
  expect_true(all(diff(hi$survival) <= 1e-9))
})

test_that("the midpoint target reproduces the relative-threshold default", {
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
  fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
                 family = "binomial", tref = 1)
  sh <- coef(fit)
  mid <- (sh[["low"]] + sh[["up"]]) / 2
  trace <- data.frame(time = seq(0, 1, length.out = 50), temp = 37)

  default_hi <- predict_heat_injury(fit, trace)
  midpoint_hi <- predict_heat_injury(fit, trace, target_surv = mid)
  # target_surv at the midpoint is q = 0: byte-identical to the relative default.
  expect_equal(default_hi$dose, midpoint_hi$dose, tolerance = 1e-10)
  expect_equal(default_hi$survival, midpoint_hi$survival, tolerance = 1e-10)
})

test_that("target_surv must lie strictly between the lower and upper asymptotes", {
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
  fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
                 family = "binomial", tref = 1)
  sh <- coef(fit)
  trace <- data.frame(time = 0:5, temp = 37)
  expect_error(predict_heat_injury(fit, trace, target_surv = sh[["up"]] + 0.01),
               "asymptote")
  expect_error(predict_heat_injury(fit, trace, target_surv = sh[["low"]] - 0.01),
               "asymptote")
  expect_error(predict_heat_injury(fit, trace, target_surv = c(0.4, 0.6)),
               "single")
})

test_that("optional Sharpe-Schoolfield repair reduces injury and warns it is unidentified", {
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
  fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
                 family = "binomial", tref = 1)
  sh <- coef(fit)
  t0 <- 38
  lt <- derive_lt(fit, p = (sh[["low"]] + sh[["up"]]) / 2, temp = t0)
  trace <- data.frame(time = seq(0, lt, length.out = 100), temp = t0)

  base <- predict_heat_injury(fit, trace)
  pars <- list(r_ref = 5, t_a = 8000, t_al = -30000, t_ah = 50000,
               t_l = 295, t_h = 320, t_ref = 298)
  expect_warning(predict_heat_injury(fit, trace, repair = pars), "identified")
  rep_hi <- suppressWarnings(predict_heat_injury(fit, trace, repair = pars))
  # Any positive repair removes some accumulated dose: less injury, more survival.
  expect_lt(rep_hi$dose[nrow(rep_hi)], base$dose[nrow(base)])
  expect_gt(rep_hi$survival[nrow(rep_hi)], base$survival[nrow(base)])
})

test_that("heat-injury functions accept the freq_tls workflow, matching the engine fit", {
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
  std <- standardize_data(d, temp = "temp", duration = "duration",
                          n_total = "total", n_surv = "survived")
  wf <- fit_4pl(std, family = "binomial", t_ref = 1, quiet = TRUE)  # freq_tls
  expect_s3_class(wf, "freq_tls")
  trace <- data.frame(time = seq(0, 2, by = 0.1),
                      temp = 34 + 4 * sin(seq(0, 2, by = 0.1)))

  # predict_heat_injury: the workflow object unwraps to its engine fit, so the
  # prediction is identical to calling it on $fit directly.
  expect_identical(predict_heat_injury(wf, trace),
                   predict_heat_injury(wf$fit, trace))

  # heat_injury_envelope + plot_heat_injury also take the workflow (envelope uses
  # the fit for both the point trajectory and the bootstrap replicates).
  env <- heat_injury_envelope(wf, trace, nboot = 50, seed = 1)
  expect_true(all(c("time", "survival", "conf.low", "conf.high") %in% names(env)))
  expect_s3_class(plot_heat_injury(wf, trace, nboot = 50, seed = 1), "ggplot")
})
