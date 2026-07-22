# Profile-likelihood tests (SPEC.md S11, test-profile). Each test does one fit
# on a fixed-seed simulation, so the suite stays fast. The headline checks are:
# D(MLE) ~ 0, finite closed CIs that bracket the estimate for CTmax and z, exact
# equivariance (ci_z == exp(ci_log_z)), preserved asymmetry, and an honest
# non-closing case that warns and returns NA without crashing.

fit_binom <- function(seed = 1) {
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = seed)
  suppressWarnings(
    fit_tls(d, y = survived, n = total, time = duration, temp = temp,
            family = "binomial", tref = 1)
  )
}

test_that("the profile deviance is ~0 at the MLE", {
  fit <- fit_binom()
  pc <- suppressWarnings(profile(fit, "CTmax"))
  expect_lt(abs(min(pc$deviance, na.rm = TRUE)), 1e-4)

  pz <- suppressWarnings(profile(fit, "z"))
  expect_lt(abs(min(pz$deviance, na.rm = TRUE)), 1e-4)
})

test_that("CTmax and z profile CIs are finite, closed, and bracket the estimate", {
  fit <- fit_binom()

  ciC <- suppressWarnings(confint(fit, "CTmax", method = "profile"))
  expect_true(is.finite(ciC$conf.low) && is.finite(ciC$conf.high))
  expect_lt(ciC$conf.low, ciC$estimate)
  expect_gt(ciC$conf.high, ciC$estimate)
  expect_identical(ciC$conf.status, "ok")

  ciZ <- suppressWarnings(confint(fit, "z", method = "profile"))
  expect_true(is.finite(ciZ$conf.low) && is.finite(ciZ$conf.high))
  expect_lt(ciZ$conf.low, ciZ$estimate)
  expect_gt(ciZ$conf.high, ciZ$estimate)
  # z is strictly positive.
  expect_gt(ciZ$conf.low, 0)
})

test_that("the z profile CI equals exp() of the log_z profile CI (equivariance)", {
  fit <- fit_binom()
  ciZ <- suppressWarnings(confint(fit, "z", method = "profile"))
  ciLz <- suppressWarnings(confint(fit, "log_z", method = "profile"))
  expect_equal(
    c(ciZ$conf.low, ciZ$conf.high),
    exp(c(ciLz$conf.low, ciLz$conf.high)),
    tolerance = 1e-6
  )
})

test_that("profile CIs may be asymmetric and we do not symmetrise them", {
  # The phi profile on a beta-binomial fit is markedly asymmetric on the natural
  # scale (heavier upper tail), which the profile should preserve.
  d <- simulate_tls(family = "beta_binomial", CTmax = 36, z = 3, phi = 50,
                    seed = 1)
  fit <- suppressWarnings(
    fit_tls(d, y = survived, n = total, time = duration, temp = temp,
            family = "beta_binomial", tref = 1)
  )
  ci <- suppressWarnings(confint(fit, "phi", method = "profile"))
  expect_true(is.finite(ci$conf.low) && is.finite(ci$conf.high))
  lower_gap <- ci$estimate - ci$conf.low
  upper_gap <- ci$conf.high - ci$estimate
  # Not symmetric: the two half-widths differ substantially.
  expect_false(isTRUE(all.equal(lower_gap, upper_gap, tolerance = 0.05)))
})

test_that("a sparse / degenerate design warns and returns NA without crashing", {
  ds <- simulate_tls(family = "binomial", temps = c(35, 36), times = c(1, 2),
                     reps = 2, n = 10, CTmax = 36, z = 4, seed = 9)
  fs <- suppressWarnings(
    fit_tls(ds, y = survived, n = total, time = duration, temp = temp,
            family = "binomial", tref = 1)
  )
  # fallback = FALSE keeps the strict profile behaviour (the parametric-bootstrap
  # fallback is exercised in test-bootstrap.R).
  expect_warning(
    confint(fs, "z", method = "profile", fallback = FALSE),
    "did not close|weakly identified"
  )
  ci <- suppressWarnings(confint(fs, "z", method = "profile", fallback = FALSE))
  # An open side is NA (never a fabricated bound) and the status records it.
  expect_true(is.na(ci$conf.low) || is.na(ci$conf.high))
  expect_match(ci$conf.status, "open")

  eye <- suppressWarnings(
    plot_confidence_eye(
      fs, parm = "z", method = "profile", raw_data = FALSE,
      fallback = FALSE
    )
  )
  layer_classes <- vapply(
    eye$layers,
    function(layer) class(layer$geom)[1L],
    character(1)
  )
  expect_false(any(layer_classes == "GeomRibbon"))
  expect_true(any(layer_classes == "GeomPoint"))
  expect_match(eye$labels$subtitle, "hollow points only|without a lens")
})

test_that("up uses the delta/Wald fallback with a message and no profile curve", {
  fit <- fit_binom()
  expect_message(
    suppressWarnings(confint(fit, "up", method = "profile")),
    "delta-method Wald"
  )
  ci <- suppressMessages(suppressWarnings(confint(fit, "up", method = "profile")))
  expect_identical(ci$method, "wald")
  expect_identical(ci$conf.status, "wald_fallback")
  expect_true(is.finite(ci$conf.low) && is.finite(ci$conf.high))
})

test_that("plot.profile_tls_profile returns a ggplot with confidence wording", {
  skip_if_not_installed("ggplot2")
  fit <- fit_binom()
  pc <- suppressWarnings(profile(fit, "CTmax"))
  p <- plot(pc)
  expect_s3_class(p, "ggplot")
  # Confidence-Eye contract: confidence language, never posterior.
  expect_match(p$labels$caption, "confidence")
  expect_false(grepl("posterior|credible", tolower(p$labels$caption)))
})

test_that("tidy_parameters(method = 'profile') fills the 8-column shape", {
  fit <- fit_binom()
  # tidy over all params profiles `up` too, which emits an info message.
  tp <- suppressMessages(suppressWarnings(tidy_parameters(fit, method = "profile")))
  expect_identical(
    names(tp),
    c("parameter", "group", "estimate", "std.error",
      "conf.low", "conf.high", "interval_type", "scale")
  )
  # Profile for all rows except `up`, which is honestly labelled Wald/delta
  # (no single internal coordinate under the nested-gap reparameterisation).
  expect_true(all(tp$interval_type[tp$parameter != "up"] == "profile"))
  expect_identical(tp$interval_type[tp$parameter == "up"], "wald")
  # CTmax and z rows are finite and bracket the estimate.
  for (p in c("CTmax", "z")) {
    row <- tp[tp$parameter == p, ]
    expect_true(is.finite(row$conf.low) && is.finite(row$conf.high))
    expect_lt(row$conf.low, row$estimate)
    expect_gt(row$conf.high, row$estimate)
  }
})

test_that("parameter getters pass profile intervals through without changing rows", {
  fit <- fit_binom()
  ct <- suppressMessages(suppressWarnings(get_ctmax(fit, method = "profile")))
  zz <- suppressMessages(suppressWarnings(get_z(fit, method = "profile")))
  sh <- suppressMessages(suppressWarnings(get_shape(fit, method = "profile")))
  expect_true(all(ct$interval_type == "profile"))
  expect_true(all(zz$interval_type == "profile"))
  expect_true(all(sh$parameter %in% c("low", "up", "k", "phi")))
  expect_identical(sh$interval_type[sh$parameter == "up"], "wald")
})

test_that("check_tls fires data-adequacy warnings on a sparse fit", {
  ds <- simulate_tls(family = "binomial", temps = c(35, 36), times = c(1, 2),
                     reps = 2, n = 10, CTmax = 36, z = 4, seed = 9)
  fs <- suppressWarnings(
    fit_tls(ds, y = survived, n = total, time = duration, temp = temp,
            family = "binomial", tref = 1)
  )
  # check_tls emits several warnings; collect them all and assert on the codes.
  codes <- character(0)
  msgs <- character(0)
  withCallingHandlers(
    codes <- check_tls(fs),
    warning = function(w) {
      msgs <<- c(msgs, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  expect_true(any(grepl("Fewer than 3 unique temperatures", msgs)))
  expect_true("temps" %in% codes)
  expect_true("durations" %in% codes)
})
