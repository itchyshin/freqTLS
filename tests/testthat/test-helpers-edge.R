# Small internal helpers and thin front-end checks: link transforms, unit and
# reference-time resolution, design-matrix construction, family resolution, and
# the tls() / diagnose_tdt_fit() front ends.

test_that("tls_link and tls_backtransform are inverse for every supported link", {
  x <- c(0.2, 1.5, 3)
  for (lnk in c("log", "identity")) {
    expect_equal(tls_backtransform(tls_link(x, lnk), lnk), x)
  }
  p <- c(0.1, 0.5, 0.9)
  expect_equal(tls_backtransform(tls_link(p, "logit"), "logit"), p)
  expect_equal(tls_link(0.5, "logit"), 0)
  expect_equal(tls_link(exp(1), "log"), 1)
  expect_error(tls_backtransform(1, "probit"), "Unknown link")
  expect_error(tls_link(1, "probit"), "Unknown link")
})

test_that("tls_minutes_multiplier converts documented unit labels and rejects the rest", {
  expect_equal(tls_minutes_multiplier("seconds"), 1 / 60)
  expect_equal(tls_minutes_multiplier(" Hours "), 60)
  expect_equal(tls_minutes_multiplier("days"), 1440)
  expect_error(tls_minutes_multiplier("fortnights"), "Cannot convert")
  expect_error(tls_minutes_multiplier(NA_character_), "must name the unit")
  expect_error(tls_minutes_multiplier(""), "must name the unit")
  expect_error(tls_minutes_multiplier(c("min", "h")), "must name the unit")
  expect_error(tls_minutes_multiplier(60), "must name the unit")
})

test_that("tls_resolve_tref honours explicit values and metadata", {
  expect_identical(tls_resolve_tref(30), 30)
  expect_error(tls_resolve_tref(-1), "single finite positive number")
  expect_error(tls_resolve_tref(c(1, 2)), "single finite positive number")
  expect_error(tls_resolve_tref(Inf), "single finite positive number")
  expect_error(tls_resolve_tref("a"), "single finite positive number")
  expect_identical(tls_resolve_tref(NULL, list(duration_unit = "minutes")), 60)
  expect_warning(def <- tls_resolve_tref(NULL, NULL), "defaults to 60 minutes")
  expect_identical(def, 60)
  expect_error(tls_resolve_tref(NULL, list(duration_unit = "hours")),
               "must be recorded in minutes")
})

test_that("build_tls_design builds intercept-only and cell-means designs", {
  ungrouped <- build_tls_design(NULL, 4L)
  expect_identical(dim(ungrouped$X_CT), c(4L, 1L))
  expect_false(ungrouped$grouped)
  expect_identical(ungrouped$levels, "all")

  g <- build_tls_design(c("B", "A", "B", "A"), 4L)
  expect_true(g$grouped)
  expect_identical(g$levels, c("A", "B"))
  expect_identical(colnames(g$X_CT), c("A", "B"))
  expect_equal(unname(g$X_CT[, "A"]), c(0, 1, 0, 1))
  expect_equal(rowSums(g$X_CT), rep(1, 4), ignore_attr = TRUE)

  expect_error(build_tls_design(c("A", "B"), 3L), "one entry per observation")
  expect_error(build_tls_design(c("A", NA, "B"), 3L), "must not contain missing")
})

test_that("resolve_tls_family accepts names and family objects", {
  expect_s3_class(resolve_tls_family("binomial"), "tls_family")
  expect_equal(resolve_tls_family("beta_binomial")$family_code, 1L)
  expect_equal(resolve_tls_family("beta")$family_code, 2L)
  fam <- binomial_tls()
  expect_identical(resolve_tls_family(fam), fam)
  expect_error(resolve_tls_family("poisson"), "should be one of")
})

test_that("tls() prints, returns flat summaries, and rejects non-fits", {
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
  fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
                 family = "binomial", tref = 1)
  expect_error(tls(list()), "freq_tls.*profile_tls")
  res <- tls(fit, params = "z", method = "wald")
  expect_s3_class(res, "tls")
  expect_identical(res$meta$params, "z")
  out <- utils::capture.output(ret <- print(res))
  expect_match(out[1], "<tls> relative threshold; quantities: z \\(wald intervals\\)")
  expect_identical(ret, res)
  est_z <- fit$estimates$estimate[fit$estimates$parameter == "z"]
  expect_equal(res$summary$median, est_z, tolerance = 1e-6)
  expect_lt(res$summary$lower, est_z)
  expect_gt(res$summary$upper, est_z)

  both <- tls(fit, params = "all", method = "wald")
  expect_setequal(both$summary$quantity, c("z", "CTmax"))
})

test_that("diagnose_tdt_fit reports convergence and rejects non-fits", {
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
  fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
                 family = "binomial", tref = 1)
  expect_error(diagnose_tdt_fit(list()), "freq_tls.*profile_tls")
  dg <- diagnose_tdt_fit(fit)
  expect_true(dg$converged)
  expect_true(dg$pd_hessian)
  expect_lt(dg$max_abs_gradient, 1e-3)
  expect_equal(dg$n_params, nrow(fit$estimates))
  expect_equal(dg$logLik, as.numeric(stats::logLik(fit)), tolerance = 1e-8)
  expect_true(dg$all_pass)
})
