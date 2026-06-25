# fit_4pl() — the bayesTLS-twin fitting facade over the TMB engine.

std_sim <- function(seed = 1, ...) {
  d <- simulate_tls(family = "binomial", seed = seed, ...)
  standardize_data(d, temp = "temp", duration = "duration",
                   n_total = "total", n_surv = "survived")
}

test_that("make_4pl_formula builds the engine tls_formula from direct args", {
  ff <- make_4pl_formula(ctmax = ~ 0 + grp, z = ~ 0 + grp, family = "binomial")
  expect_s3_class(ff, "tls_formula")
  expect_match(deparse1(ff$response), "n_surv \\| trials\\(n_total\\)")
  expect_match(deparse1(ff$sub_formulas$CTmax), "0 \\+ grp")
  expect_match(deparse1(ff$sub_formulas$log_z), "0 \\+ grp")
  # constant-shape invariant: shapes default to ~ 1
  expect_match(deparse1(ff$sub_formulas$low), "~ *1$")
  expect_match(deparse1(ff$sub_formulas$up), "~ *1$")
  # beta family uses the bare-name response
  fb <- make_4pl_formula(family = "beta")
  expect_match(deparse1(fb$response), "survival ~")
  # `by` is shorthand for grouping CTmax and z
  fby <- make_4pl_formula(by = "sex", family = "binomial")
  expect_match(deparse1(fby$sub_formulas$CTmax), "0 \\+ sex")
})

test_that("fit_4pl recovers the simulating truth (ungrouped) and returns freq_tls", {
  s <- std_sim(seed = 1, CTmax = 36, z = 4)
  f <- fit_4pl(s, t_ref = 1, family = "binomial", quiet = TRUE)
  expect_s3_class(f, "freq_tls")
  expect_named(f, c("fit", "data", "formula", "meta"))
  expect_identical(f$fit$convergence$code, 0L)
  e <- f$fit$estimates
  expect_equal(e$estimate[e$parameter == "CTmax"], 36, tolerance = 0.3)
  expect_equal(e$estimate[e$parameter == "z"], 4, tolerance = 0.4)
  # meta carries the twin contract
  expect_identical(f$meta$threshold, "relative")
  expect_identical(f$meta$t_ref, 1)
  expect_equal(f$meta$temp_mean, attr(s, "tdt_meta")$temp_mean)
  expect_false(f$meta$grouped)
})

test_that("fit_4pl direct grouping equals the engine column-interface grouped fit", {
  d <- simulate_tls(family = "binomial", group = c("A", "B"),
                    CTmax = c(34, 38), z = c(3, 5), seed = 3)
  s <- standardize_data(d, temp = "temp", duration = "duration",
                        n_total = "total", n_surv = "survived")
  f_direct <- suppressWarnings(fit_4pl(s, ctmax = ~ 0 + group, z = ~ 0 + group,
                                       t_ref = 1, family = "binomial", quiet = TRUE))
  f_col <- suppressWarnings(fit_tls(d, y = survived, n = total, time = duration,
                                    temp = temp, group = group,
                                    family = "binomial", tref = 1, quiet = TRUE))
  expect_equal(as.numeric(logLik(f_direct$fit)), as.numeric(logLik(f_col)),
               tolerance = 1e-5)
  expect_true(f_direct$meta$grouped)
  expect_identical(f_direct$meta$moderators, "group")
  # The direct cell-means design (~ 0 + group) now carries the SAME clean group
  # labels as the column interface (CTmax:A, not CTmax:groupA), end to end.
  expect_identical(f_direct$fit$group_levels, f_col$group_levels)
  expect_identical(get_ctmax(f_direct)$parameter, get_ctmax(f_col)$parameter)
  expect_equal(tls(f_direct)$summary, tls(f_col)$summary, tolerance = 1e-5)
  # by="group" is the shorthand for ~ 0 + group and gives identical labels.
  f_by <- suppressWarnings(fit_4pl(s, by = "group", t_ref = 1,
                                   family = "binomial", quiet = TRUE))
  expect_identical(get_ctmax(f_by)$parameter, get_ctmax(f_col)$parameter)
})

test_that("family defaults from the standardized response type", {
  sp <- standardize_data(
    data.frame(t = c(30, 32, 34), e = c(1, 2, 4), fv = c(0.9, 0.5, 0.1)),
    temp = "t", duration = "e", proportion = "fv")
  expect_identical(attr(sp, "tdt_meta")$response_type, "proportion")
  ff <- make_4pl_formula(family = "beta")
  expect_match(deparse1(ff$response), "survival ~")
})

test_that("the freq_tls workflow is accepted by the plots and extractors", {
  f <- fit_4pl(std_sim(seed = 1), t_ref = 1, family = "binomial", quiet = TRUE)
  # plots (incl. the Confidence Eye) and extractors take the workflow, not just $fit
  expect_s3_class(plot_confidence_eye(f), "ggplot")
  expect_s3_class(plot_survival_curves(f), "ggplot")
  expect_s3_class(plot_tdt_curve(f), "ggplot")
  expect_s3_class(tidy_parameters(f), "tbl_df")
  expect_s3_class(get_ctmax(f), "data.frame")
  expect_type(derive_ctmax(f), "double")
})

test_that("freq_tls supports the standard S3 generics (delegating to the engine fit)", {
  f <- fit_4pl(std_sim(seed = 1), t_ref = 1, family = "binomial", quiet = TRUE)
  expect_type(coef(f), "double")
  expect_s3_class(logLik(f), "logLik")
  expect_true(is.matrix(vcov(f)))
  expect_identical(nobs(f), nobs(f$fit))
  expect_equal(as.numeric(logLik(f)), as.numeric(logLik(f$fit)))
  # confint() and summary() also delegate to the engine fit (not the broken
  # stats::confint.default fall-through on the list).
  ci <- confint(f, "CTmax", method = "wald")
  expect_true(all(c("estimate", "conf.low", "conf.high") %in% names(ci)))
  expect_equal(confint(f, "z", method = "wald")$estimate,
               confint(f$fit, "z", method = "wald")$estimate)
  expect_identical(summary(f), summary(f$fit))
  # check_tls() (data-adequacy diagnostic) also takes the workflow object.
  expect_identical(suppressWarnings(check_tls(f)), suppressWarnings(check_tls(f$fit)))
})

test_that("ranef() works on a freq_tls fit with random effects", {
  d <- simulate_tls(family = "binomial", temps = c(34, 36, 38), times = c(1, 4),
                    reps = 1, n = 8, CTmax = 36, z = 4, re_sd = 1.2,
                    n_re_groups = 10, seed = 42)
  std <- standardize_data(d, temp = "temp", duration = "duration",
                          n_total = "total", n_surv = "survived")
  wf <- suppressWarnings(fit_4pl(std, ctmax = ~ 1 + (1 | colony),
                                 family = "binomial", t_ref = 1, quiet = TRUE))
  expect_equal(ranef(wf), ranef(wf$fit))
})

test_that("fit_4pl rejects non-standardized data and (for now) absolute / custom bounds", {
  raw <- simulate_tls(family = "binomial", seed = 2)
  expect_error(fit_4pl(raw), "standardize_data")
  s <- std_sim(seed = 2)
  expect_error(fit_4pl(s, threshold = "absolute", quiet = TRUE), "absolute")
  expect_error(fit_4pl(s, bounds = c(0, 0.9), quiet = TRUE), "bounds")
})
