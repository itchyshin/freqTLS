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
})

test_that("family defaults from the standardized response type", {
  sp <- standardize_data(
    data.frame(t = c(30, 32, 34), e = c(1, 2, 4), fv = c(0.9, 0.5, 0.1)),
    temp = "t", duration = "e", proportion = "fv")
  expect_identical(attr(sp, "tdt_meta")$response_type, "proportion")
  ff <- make_4pl_formula(family = "beta")
  expect_match(deparse1(ff$response), "survival ~")
})

test_that("fit_4pl rejects non-standardized data and (for now) absolute / custom bounds", {
  raw <- simulate_tls(family = "binomial", seed = 2)
  expect_error(fit_4pl(raw), "standardize_data")
  s <- std_sim(seed = 2)
  expect_error(fit_4pl(s, threshold = "absolute", quiet = TRUE), "absolute")
  expect_error(fit_4pl(s, bounds = c(0, 0.9), quiet = TRUE), "bounds")
})
