# Validation, scenario, and edge behaviour of the deterministic heat-injury
# prediction and its bootstrap envelope (R/heat_injury.R), plus the bootstrap
# survival-curve bands (R/predict_survival_curves.R). Dose accumulation is
# checked against hand-computed values.

hi_fit <- function(seed = 1) {
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = seed)
  suppressWarnings(
    fit_tls(d, y = survived, n = total, time = duration, temp = temp,
            family = "binomial", tref = 1)
  )
}

hi_grouped <- function() {
  d <- simulate_tls(family = "binomial", group = c("A", "B"),
                    CTmax = c(34, 38), z = c(3, 5), seed = 2)
  suppressWarnings(
    fit_tls(d, y = survived, n = total, time = duration, temp = temp,
            group = group, family = "binomial", tref = 1)
  )
}

hi_trace <- function(temp = 38, n = 21, to = 1) {
  data.frame(time = seq(0, to, length.out = n), temp = temp)
}

test_that("predict_heat_injury validates the object, trace, and optional arguments", {
  fit <- hi_fit()
  tr <- hi_trace()
  expect_error(predict_heat_injury(list(), tr), "profile_tls")
  expect_error(predict_heat_injury(fit, as.matrix(tr)), "must be a data frame")
  expect_error(predict_heat_injury(fit, tr["time"]), "missing required column.*temp")
  expect_error(predict_heat_injury(fit, data.frame(time = c(0, 1), temp = c("a", "b"))),
               "must be numeric")
  expect_error(predict_heat_injury(fit, data.frame(time = c(0, NA), temp = c(30, 30))),
               "must not contain missing values")
  expect_error(predict_heat_injury(fit, data.frame(time = 0, temp = 30)),
               "at least two rows")
  expect_error(predict_heat_injury(fit, data.frame(time = c(0, 1, 1), temp = 30)),
               "strictly increasing")
  expect_error(predict_heat_injury(fit, tr, group = c("A", "B")), "single group level")
  expect_error(predict_heat_injury(fit, tr, target_surv = c(0.3, 0.4)),
               "single survival probability")
  expect_error(predict_heat_injury(fit, tr, target_surv = "a"),
               "single survival probability")
  expect_error(predict_heat_injury(fit, tr, target_surv = NA_real_),
               "strictly between the fitted asymptotes")
  expect_error(predict_heat_injury(fit, tr, target_surv = 0.999),
               "strictly between the fitted asymptotes")
  expect_error(predict_heat_injury(fit, tr, t_c = "a"), "single temperature")
  expect_error(predict_heat_injury(fit, tr, t_c = c(30, 31)), "single temperature")
})

test_that("an absolute target survival shifts the lethal dose by qlogis()/k", {
  fit <- hi_fit()
  est <- stats::setNames(fit$estimates$estimate, fit$estimates$parameter)
  target <- 0.5
  lt <- derive_lt(fit, p = target, temp = 38)
  tr <- data.frame(time = seq(0, lt, length.out = 400), temp = 38)
  hi <- predict_heat_injury(fit, tr, target_surv = target)
  # One lethal dose to the absolute 50% target is reached at t = LT(0.5).
  expect_equal(hi$dose[nrow(hi)], 1, tolerance = 2e-3)
  expect_equal(hi$survival[nrow(hi)], target, tolerance = 0.01)
  expect_equal(hi$survival[1], est[["up"]], tolerance = 1e-6)
})

test_that("a damage cutoff, irreversibility, and constant-temperature dose follow the map", {
  fit <- hi_fit()
  est <- stats::setNames(fit$estimates$estimate, fit$estimates$parameter)
  tr <- hi_trace(temp = 38, n = 11, to = 0.5)
  hi <- predict_heat_injury(fit, tr)
  # With constant temperature and no repair, dose grows linearly at 1 / LT, where
  # LT = 10^(log10(tref) - (T - CTmax) / z) for the relative midpoint.
  lt_rel <- 10^(log10(1) - (38 - est[["CTmax"]]) / est[["z"]])
  expect_equal(hi$dose, tr$time / lt_rel, tolerance = 1e-8, ignore_attr = TRUE)

  cooled <- predict_heat_injury(fit, tr, t_c = 40)
  expect_true(all(cooled$dose == 0))
  expect_equal(cooled$survival, rep(est[["up"]], nrow(tr)), tolerance = 1e-6)
})

test_that("tls_injury_traj handles reversible survival and an NULL repair rate", {
  # Hot then cold: the cold step has dmg ~ 0 but non-negative net, so dose is
  # non-decreasing without repair, and reversible/irreversible survival agree.
  time <- c(0, 1, 2, 3)
  temp <- c(40, 40, 20, 20)
  a <- tls_injury_traj(0.02, 0.98, 5, 36, 4, 1, time, temp, q = 0,
                       irreversible = TRUE)
  b <- tls_injury_traj(0.02, 0.98, 5, 36, 4, 1, time, temp, q = 0,
                       irreversible = FALSE)
  expect_true(all(diff(a$dose) >= 0))
  expect_equal(a$survival, b$survival)
  expect_equal(a$survival[1], 0.98, tolerance = 1e-6)

  # Strong repair at the cold step can lower the dose; irreversible survival
  # never recovers while reversible survival may.
  rep_rate <- c(0, 0, 50, 50)
  ai <- tls_injury_traj(0.02, 0.98, 5, 36, 4, 1, time, temp, q = 0,
                        rep_rate = rep_rate, irreversible = TRUE)
  ar <- tls_injury_traj(0.02, 0.98, 5, 36, 4, 1, time, temp, q = 0,
                        rep_rate = rep_rate, irreversible = FALSE)
  expect_true(all(diff(ai$survival) <= 1e-12))
  expect_lt(min(diff(ai$dose)), 0)
  expect_gte(max(diff(ar$survival)), 0)
  expect_gt(max(diff(ar$survival)), 0)
})

test_that("Sharpe-Schoolfield repair rate matches the closed form and clamps bad values", {
  pars <- list(r_ref = 0.4, t_a = 8000, t_al = -50000, t_ah = 80000,
               t_l = 283, t_h = 313, t_ref = 293)
  tk <- 293.15
  expected <- 0.4 * exp(8000 * (1 / 293 - 1 / tk)) /
    (1 + exp(-50000 * (1 / tk - 1 / 283)) + exp(80000 * (1 / 313 - 1 / tk)))
  expect_equal(tls_repair_rate_schoolfield(20, pars), expected, tolerance = 1e-10)
  expect_equal(length(tls_repair_rate_schoolfield(c(10, 20, 30), pars)), 3L)
  neg <- pars; neg$r_ref <- -1
  expect_equal(tls_repair_rate_schoolfield(20, neg), 0)
  expect_error(tls_repair_rate_schoolfield(20, pars[c("r_ref", "t_a")]),
               "missing parameters")
})

test_that("repair is a flagged what-if scenario that can only slow injury", {
  fit <- hi_fit()
  tr <- hi_trace(temp = 37, n = 21, to = 1)
  pars <- list(r_ref = 2, t_a = 8000, t_al = -50000, t_ah = 80000,
               t_l = 283, t_h = 313, t_ref = 310)
  plain <- predict_heat_injury(fit, tr)
  expect_warning(rep <- predict_heat_injury(fit, tr, repair = pars),
                 "not.*identified")
  expect_lte(rep$dose[nrow(rep)], plain$dose[nrow(plain)])
  expect_gte(rep$survival[nrow(rep)], plain$survival[nrow(plain)])
  expect_error(suppressWarnings(predict_heat_injury(fit, tr, repair = list(r_ref = 1))),
               "missing parameter")
})

test_that("heat_injury_envelope validates conf.level and brackets the point trajectory", {
  fit <- hi_fit()
  tr <- hi_trace(temp = 38, n = 11, to = 0.4)
  expect_error(heat_injury_envelope(fit, tr, conf.level = 1, nboot = 5),
               "single number in \\(0, 1\\)")
  expect_error(heat_injury_envelope(fit, tr, conf.level = "a", nboot = 5),
               "single number in \\(0, 1\\)")
  env <- heat_injury_envelope(fit, tr, nboot = 30, seed = 4)
  expect_s3_class(env, "tbl_df")
  expect_named(env, c("time", "temp", "survival", "conf.low", "conf.high"))
  expect_equal(env$survival, predict_heat_injury(fit, tr)$survival)
  expect_true(all(env$conf.low <= env$conf.high))
  expect_true(all(env$conf.low >= 0 & env$conf.high <= 1))
  expect_equal(heat_injury_envelope(fit, tr, nboot = 30, seed = 4), env)
})

test_that("heat_injury_envelope supports target_surv, repair scenarios, and groups", {
  fit <- hi_fit()
  tr <- hi_trace(temp = 38, n = 11, to = 0.4)
  env_abs <- heat_injury_envelope(fit, tr, target_surv = 0.5, nboot = 30, seed = 4)
  expect_true(all(env_abs$conf.low <= env_abs$conf.high))
  pars <- list(r_ref = 2, t_a = 8000, t_al = -50000, t_ah = 80000,
               t_l = 283, t_h = 313, t_ref = 310)
  expect_warning(
    env_rep <- heat_injury_envelope(fit, tr, repair = pars, nboot = 20, seed = 4),
    "not.*identified"
  )
  expect_equal(nrow(env_rep), nrow(tr))

  fg <- hi_grouped()
  expect_error(heat_injury_envelope(fg, tr, nboot = 10, seed = 1),
               "must include a.*group.*column")
  env_b <- heat_injury_envelope(fg, tr, group = "B", nboot = 20, seed = 4)
  env_a <- heat_injury_envelope(fg, tr, group = "A", nboot = 20, seed = 4)
  # Group B has the higher CTmax so it survives the 38 C exposure better.
  expect_gt(env_b$survival[nrow(tr)], env_a$survival[nrow(tr)])
})

test_that("plot_heat_injury returns a confidence-band plot and validates time_div", {
  fit <- hi_fit()
  tr <- hi_trace(temp = 38, n = 11, to = 0.4)
  expect_error(plot_heat_injury(fit, tr, time_div = 0, nboot = 5),
               "single positive number")
  expect_error(plot_heat_injury(fit, tr, time_div = c(1, 2), nboot = 5),
               "single positive number")
  p <- plot_heat_injury(fit, tr, nboot = 20, seed = 2, time_div = 0.4,
                        xlab = "Fraction of exposure")
  expect_s3_class(p, "ggplot")
  expect_equal(range(p$data$x), c(0, 1))
  expect_identical(p$labels$x, "Fraction of exposure")
  expect_match(p$labels$caption, "confidence band")
  expect_match(p$labels$caption, "B = 20", fixed = TRUE)
  expect_no_match(p$labels$caption, "posterior|credible")
})

test_that("shape-varying fits are rejected by heat-injury and survival-band functions", {
  d <- simulate_tls(family = "binomial", group = c("A", "B"),
                    CTmax = c(35, 38), z = c(4, 3), low = 0.02, up = 0.98,
                    k = c(3, 9), seed = 4)
  fit <- suppressWarnings(fit_tls(
    tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
           CTmax ~ group, log_z ~ group, low ~ group, up ~ group, log_k ~ group),
    data = d, family = "binomial", tref = 1))
  tr <- hi_trace(temp = 38, n = 5, to = 0.2)
  expect_error(predict_heat_injury(fit, tr, group = "A"),
               "varying fixed-effect shape design")
  expect_error(predict_survival_curves(fit, temps = 36, durations = 1, nboot = 5),
               "varying fixed-effect shape design")
})

test_that("predict_survival_curves returns ordered bootstrap bands around the fit", {
  fit <- hi_fit()
  sc <- predict_survival_curves(fit, temps = c(34, 38), durations = c(0.5, 2, 8),
                                nboot = 40, seed = 3)
  expect_s3_class(sc, "freq_surv_curves")
  s <- sc$summary
  expect_equal(nrow(s), 6L)
  expect_true(all(s$survival_lower <= s$survival_median &
                    s$survival_median <= s$survival_upper))
  expect_true(all(s$survival_lower >= 0 & s$survival_upper <= 1))
  expect_lte(sc$meta$nboot, 40L)
  expect_identical(sc$meta$level, 0.95)
  expect_equal(sc$meta$tref, 1)
  # The bootstrap median tracks the point prediction.
  point <- predict(fit, s[, c("temp", "duration")])
  expect_lt(max(abs(s$survival_median - point)), 0.08)
  # Reproducible with a seed; a wider level gives a wider band.
  again <- predict_survival_curves(fit, temps = c(34, 38), durations = c(0.5, 2, 8),
                                   nboot = 40, seed = 3)
  expect_equal(again$summary, s)
  wide <- predict_survival_curves(fit, temps = c(34, 38), durations = c(0.5, 2, 8),
                                  nboot = 40, seed = 3, level = 0.99)
  expect_true(all(wide$summary$survival_upper - wide$summary$survival_lower >=
                    s$survival_upper - s$survival_lower - 1e-12))
  expect_output(print(sc), "freq_surv_curves")
  expect_identical(utils::capture.output(res <- print(sc))[1L],
                   sprintf("<freq_surv_curves> %d grid cells; %d bootstrap replicates",
                           nrow(sc$summary), sc$meta$nboot))
  expect_identical(res, sc)
})

test_that("predict_survival_curves defaults its grid and validates inputs", {
  fit <- hi_fit()
  sc <- predict_survival_curves(fit, nboot = 10, seed = 1)
  expect_length(unique(sc$summary$duration), 100L)
  expect_setequal(unique(sc$summary$temp), unique(fit$diag_data$temp))
  expect_error(predict_survival_curves(list()), "freq_tls.*profile_tls")
  expect_error(predict_survival_curves(fit, temps = "a"), "must be numeric")
  expect_error(predict_survival_curves(fit, temps = 36, durations = c(0, 1)),
               "strictly positive")
})

test_that("predict_survival_curves labels grouped bands by the moderator", {
  fg <- hi_grouped()
  sc <- predict_survival_curves(fg, temps = 36, durations = c(1, 4), nboot = 20,
                                seed = 2)
  expect_true("group" %in% names(sc$summary))
  expect_setequal(sc$summary$group, c("A", "B"))
  expect_identical(sc$meta$by, "group")
  # B has the higher CTmax, hence higher survival at the same exposure.
  a <- sc$summary$survival_median[sc$summary$group == "A" & sc$summary$duration == 4]
  b <- sc$summary$survival_median[sc$summary$group == "B" & sc$summary$duration == 4]
  expect_gt(b, a)
})
