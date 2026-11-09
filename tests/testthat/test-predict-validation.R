# Input validation, grouping, and conditional-prediction branches of
# R/predict.R: predict(), predict_survival_surface(), derive_lt(),
# derive_ctmax(), derive_tcrit(). Complements test-predict.R (which covers the
# mainstream numerical paths) with known-value checks and the error messages a
# user sees for malformed requests.

pv_fit <- function(seed = 1) {
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = seed)
  suppressWarnings(
    fit_tls(d, y = survived, n = total, time = duration, temp = temp,
            family = "binomial", tref = 1)
  )
}

pv_grouped <- function() {
  d <- simulate_tls(family = "binomial", group = c("A", "B"),
                    CTmax = c(34, 38), z = c(3, 5), seed = 3)
  suppressWarnings(
    fit_tls(d, y = survived, n = total, time = duration, temp = temp,
            group = group, family = "binomial", tref = 1)
  )
}

test_that("predict rejects extra arguments, non-fits, and bad newdata", {
  fit <- pv_fit()
  nd <- data.frame(temp = 36, duration = 2)
  expect_error(predict(fit, nd, bogus = 1), "reserved")
  expect_error(predict.profile_tls(list(), nd), "profile_tls")
  expect_error(predict(fit), "newdata")
  expect_error(predict(fit, newdata = list(temp = 36, duration = 2)),
               "must be a data frame")
  expect_error(predict(fit, data.frame(duration = 2), type = "midpoint"),
               "missing required column.*temp")
  expect_error(predict(fit, data.frame(temp = "hot", duration = 2)),
               "must be numeric")
  expect_error(predict(fit, data.frame(temp = c(36, NA), duration = 2)),
               "temp.*must not contain missing")
  expect_error(predict(fit, data.frame(temp = 36, duration = "long")),
               "duration.*must be numeric")
  expect_error(predict(fit, data.frame(temp = 36, duration = NA_real_)),
               "duration.*must not contain missing")
  expect_error(predict(fit, data.frame(temp = 36, duration = 0)),
               "strictly positive")
})

test_that("predict unwraps a freq_tls workflow", {
  fit <- pv_fit()
  wf <- structure(list(fit = fit), class = c("freq_tls", "list"))
  nd <- data.frame(temp = c(35, 37), duration = 2)
  expect_equal(predict(wf, nd), predict(fit, nd))
})

test_that("type = 'midpoint' and 'parameters' need only temp", {
  fit <- pv_fit()
  mid <- predict(fit, data.frame(temp = c(34, 36, 38)), type = "midpoint")
  ct <- fit$estimates$estimate[fit$estimates$parameter == "CTmax"]
  z <- fit$estimates$estimate[fit$estimates$parameter == "z"]
  # mid = log10(tref) - (temp - CTmax) / z, with tref = 1 here.
  expect_equal(mid, -(c(34, 36, 38) - ct) / z, tolerance = 1e-10)
  expect_equal(diff(mid), rep(-2 / z, 2), tolerance = 1e-10)

  pars <- predict(fit, data.frame(temp = c(34, 36)), type = "parameters")
  expect_true(all(c("CTmax", "z", "low", "up", "k") %in% names(pars)))
  expect_equal(pars$CTmax, rep(ct, 2))
})

test_that("grouped predict rejects missing, NA, and unknown group levels", {
  fit <- pv_grouped()
  nd <- data.frame(temp = c(36, 36), duration = 2)
  expect_error(predict(fit, nd), "must include a.*group.*column")
  expect_error(predict(fit, cbind(nd, group = c("A", NA))),
               "group.*must not contain missing")
  expect_error(predict(fit, cbind(nd, group = c("A", "Z"))),
               "not in the fit.*Z")
  both <- predict(fit, cbind(nd, group = c("A", "B")))
  expect_length(both, 2L)
  expect_gt(both[2], both[1])
})

test_that("predict_survival_surface builds default grids and validates input", {
  fit <- pv_fit()
  surf <- predict_survival_surface(fit)
  expect_equal(nrow(surf), 60L * 60L)
  expect_equal(range(surf$temp), range(fit$data_summary$temp_range))
  expect_equal(range(surf$duration), range(fit$data_summary$time_range),
               tolerance = 1e-8)
  expect_true(all(surf$survival >= 0 & surf$survival <= 1))

  # Grid values agree with predict().
  s2 <- predict_survival_surface(fit, temps = c(34, 38), times = c(1, 4))
  expect_equal(s2$survival,
               predict(fit, s2[, c("temp", "duration")], type = "survival"))

  expect_error(predict_survival_surface(list()), "profile_tls")
  expect_error(predict_survival_surface(fit, temps = "a", times = 1),
               "must be numeric")
  expect_error(predict_survival_surface(fit, temps = 36, times = c(0, 1)),
               "strictly positive")
  expect_error(predict_survival_surface(fit, temps = 36, times = 1, group = "A"),
               "only meaningful for a grouped fit")
})

test_that("predict_survival_surface slices a grouped fit by group", {
  fit <- pv_grouped()
  all_groups <- predict_survival_surface(fit, temps = c(34, 38), times = c(1, 2))
  expect_identical(names(all_groups), c("temp", "duration", "group", "survival"))
  expect_setequal(unique(all_groups$group), c("A", "B"))
  expect_equal(nrow(all_groups), 8L)

  only_b <- predict_survival_surface(fit, temps = c(34, 38), times = c(1, 2),
                                     group = "B")
  expect_true(all(only_b$group == "B"))
  expect_equal(only_b$survival, all_groups$survival[all_groups$group == "B"])

  expect_error(predict_survival_surface(fit, temps = 36, times = 1,
                                        group = c("A", "B")),
               "single fitted group level")
  expect_error(predict_survival_surface(fit, temps = 36, times = 1, group = "Z"),
               "single fitted group level")
})

test_that("derive_lt validates arguments and inverts the curve", {
  fit <- pv_fit()
  expect_error(derive_lt(list(), temp = 36), "profile_tls")
  expect_error(derive_lt(fit, p = 0, temp = 36), "single number in \\(0, 1\\)")
  expect_error(derive_lt(fit, p = c(0.2, 0.5), temp = 36),
               "single number in \\(0, 1\\)")
  expect_error(derive_lt(fit, p = "a", temp = 36), "single number in")
  expect_error(derive_lt(fit, p = 0.5), "non-empty numeric")
  expect_error(derive_lt(fit, p = 0.5, temp = character()), "non-empty numeric")
  expect_error(derive_lt(fit, p = 0.5, temp = c(36, NA)), "missing values")

  lt <- derive_lt(fit, p = 0.5, temp = c(34, 36, 38))
  expect_length(lt, 3L)
  expect_true(all(diff(lt) < 0))
  back <- predict(fit, data.frame(temp = c(34, 36, 38), duration = lt))
  expect_equal(back, rep(0.5, 3), tolerance = 1e-6)
})

test_that("derive_lt resolves a group and rejects a vector of groups", {
  fit <- pv_grouped()
  lt_A <- derive_lt(fit, p = 0.5, temp = 36, group = "A")
  lt_B <- derive_lt(fit, p = 0.5, temp = 36, group = "B")
  # B has the higher CTmax, so at 36 C it survives longer.
  expect_gt(lt_B, lt_A)
  back <- predict(fit, data.frame(temp = 36, duration = lt_A, group = "A"))
  expect_equal(back, 0.5, tolerance = 1e-6)
  expect_error(derive_lt(fit, p = 0.5, temp = 36, group = c("A", "B")),
               "single group level")
})

test_that("derive_ctmax validates arguments and resolves groups", {
  fit <- pv_fit()
  expect_error(derive_ctmax(list()), "profile_tls")
  expect_error(derive_ctmax(fit, duration = numeric()), "non-empty numeric")
  expect_error(derive_ctmax(fit, duration = "a"), "non-empty numeric")
  expect_error(derive_ctmax(fit, duration = c(1, NA)), "strictly positive")
  expect_error(derive_ctmax(fit, duration = -1), "strictly positive")
  expect_error(derive_ctmax(fit, surv = c(0.3, 0.5)), "single number")
  expect_error(derive_ctmax(fit, surv = "a"), "single number")

  g <- pv_grouped()
  expect_error(derive_ctmax(g, group = c("A", "B")), "single group level")
  ct_A <- derive_ctmax(g, group = "A")
  ct_B <- derive_ctmax(g, group = "B")
  est <- stats::setNames(g$estimates$estimate, g$estimates$parameter)
  expect_equal(ct_A, est[["CTmax:A"]], tolerance = 1e-6, ignore_attr = TRUE)
  expect_equal(ct_B, est[["CTmax:B"]], tolerance = 1e-6, ignore_attr = TRUE)
})

test_that("derive_tcrit equals CTmax + z * log10(rate / 100) and validates rate", {
  fit <- pv_fit()
  est <- stats::setNames(fit$estimates$estimate, fit$estimates$parameter)
  expect_message(tc <- derive_tcrit(fit, rate = c(0.1, 1)), "T_crit")
  expect_equal(tc, est[["CTmax"]] + est[["z"]] * log10(c(0.1, 1) / 100),
               ignore_attr = TRUE)
  expect_lt(tc[1], tc[2])
  expect_lt(tc[2], est[["CTmax"]])

  expect_error(derive_tcrit(list()), "profile_tls")
  expect_error(derive_tcrit(fit, rate = 0), "strictly positive")
  expect_error(derive_tcrit(fit, rate = c(1, NA)), "strictly positive")
  expect_error(derive_tcrit(fit, rate = numeric()), "strictly positive")
  expect_error(derive_tcrit(fit, rate = "a"), "strictly positive")

  g <- pv_grouped()
  gest <- stats::setNames(g$estimates$estimate, g$estimates$parameter)
  expect_message(tcb <- derive_tcrit(g, rate = 1, group = "B"), "T_crit")
  expect_equal(tcb, gest[["CTmax:B"]] + gest[["z:B"]] * log10(1 / 100),
               tolerance = 1e-6, ignore_attr = TRUE)
  expect_error(suppressMessages(derive_tcrit(g, group = c("A", "B"))),
               "single group level")
})

test_that("conditional prediction adds the fitted random intercept on low", {
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, low = 0.1, up = 0.98,
                    temps = seq(33, 39, by = 1.5), times = c(1, 2, 4, 8, 16),
                    reps = 3, n = 30, re_sd_low = 0.6, n_re_groups = 8,
                    seed = 101)
  fit <- suppressWarnings(fit_tls(
    tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
           low ~ 1 + (1 | colony)),
    data = d, family = "binomial", tref = 1))
  re <- ranef(fit)
  lev <- re$group[which.max(abs(re$estimate))]
  # A long exposure at high temperature isolates the lower asymptote, so the
  # conditional prediction must move away from the population value by the
  # sign of the fitted intercept.
  nd <- data.frame(temp = 40, duration = 100, colony = lev)
  pop <- predict(fit, nd, re.form = "population")
  cond <- predict(fit, nd, re.form = "conditional")
  expect_equal(sign(cond - pop), sign(re$estimate[re$group == lev]),
               ignore_attr = TRUE)
  expect_error(predict(fit, cbind(nd[, c("temp", "duration")], colony = NA),
                       re.form = "conditional"), "must not contain missing")
})

test_that("conditional prediction adds the fitted random intercept on log_k", {
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, k = 5,
                    temps = seq(33, 39, by = 1.5), times = c(1, 2, 4, 8, 16),
                    reps = 3, n = 30, re_sd_logk = 0.4, n_re_groups = 8,
                    seed = 202)
  fit <- suppressWarnings(fit_tls(
    tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
           log_k ~ 1 + (1 | colony)),
    data = d, family = "binomial", tref = 1))
  re <- ranef(fit)
  lev <- re$group[which.max(abs(re$estimate))]
  nd <- data.frame(temp = 36, duration = 3, colony = lev)
  pop <- predict(fit, nd, re.form = "population")
  cond <- predict(fit, nd, re.form = "conditional")
  expect_false(isTRUE(all.equal(pop, cond)))
  # Steeper curves (positive intercept) drop survival below the midpoint
  # faster, so at duration > 10^mid the conditional survival is lower.
  mid <- predict(fit, data.frame(temp = 36), type = "midpoint",
                 re.form = "population")
  expect_gt(log10(3), mid)
  expect_equal(sign(cond - pop), -sign(re$estimate[re$group == lev]),
               ignore_attr = TRUE)
})
