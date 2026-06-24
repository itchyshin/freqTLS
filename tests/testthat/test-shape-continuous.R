# General continuous covariates on the shape / location parameters (item 4):
# a predictor (not just a grouping factor) on low / up / log_k (or CTmax / log_z),
# with design-matrix prediction and Wald intervals for the link-scale
# coefficients. Distinct from the grouped (one-hot factor) path in
# test-shape-covariates.R.

# Manual DGP: log_k varies linearly with a continuous covariate x; everything
# else is constant. Counts are binomial from the engine forward map.
make_cont_k_data <- function(seed = 1, n_per = 9, total = 40) {
  set.seed(seed)
  grid <- expand.grid(temp = c(34, 36, 38), duration = c(0.5, 1, 2, 4))
  CTmax <- 36; z <- 4; low <- 0.02; up <- 0.98
  b0 <- log(4); b1 <- 0.6                      # log_k = b0 + b1 * x
  rows <- do.call(rbind, lapply(seq_len(nrow(grid)), function(j) {
    data.frame(temp = grid$temp[j], duration = grid$duration[j],
               x = seq(-1, 1, length.out = n_per))
  }))
  k <- exp(b0 + b1 * rows$x)
  mid <- log10(1) - (rows$temp - CTmax) / z
  p <- low + (up - low) * stats::plogis(-k * (log10(rows$duration) - mid))
  rows$total <- total
  rows$survived <- stats::rbinom(nrow(rows), total, p)
  rows
}

test_that("a decoupled continuous covariate on log_k fits (constraint relaxed)", {
  d <- make_cont_k_data(seed = 3)
  # log_k ~ x while CTmax / log_z / low / up stay intercept-only: previously a
  # hard error ("must use the same grouping factor as CTmax"). Now allowed.
  fit <- fit_tls(
    tls_bf(survived | trials(total) ~ time(duration) + temp(temp), log_k ~ x),
    data = d, family = "binomial", tref = 1
  )
  expect_identical(fit$convergence$code, 0L)
})

test_that("the continuous log_k slope is recovered on the link (log) scale", {
  d <- make_cont_k_data(seed = 3)
  fit <- fit_tls(
    tls_bf(survived | trials(total) ~ time(duration) + temp(temp), log_k ~ x),
    data = d, family = "binomial", tref = 1
  )
  est <- fit$estimates
  slope <- est$estimate[est$parameter == "k:x"]
  expect_length(slope, 1L)
  # link-scale slope near the true 0.6 (NOT exponentiated)
  expect_equal(slope, 0.6, tolerance = 0.3)
})

test_that("predict applies the continuous design to newdata", {
  d <- make_cont_k_data(seed = 3)
  fit <- fit_tls(
    tls_bf(survived | trials(total) ~ time(duration) + temp(temp), log_k ~ x),
    data = d, family = "binomial", tref = 1
  )
  nd <- data.frame(temp = 36, duration = 2, x = c(-1, 0, 1))
  p <- predict(fit, nd, type = "survival")
  expect_length(p, 3L)
  expect_true(all(p > 0 & p < 1))
  # x changes k, which changes survival at a fixed temp/duration off the midpoint.
  expect_false(isTRUE(all.equal(p[1], p[3])))
})

test_that("a continuous-covariate coefficient gets a finite Wald interval", {
  d <- make_cont_k_data(seed = 3)
  fit <- fit_tls(
    tls_bf(survived | trials(total) ~ time(duration) + temp(temp), log_k ~ x),
    data = d, family = "binomial", tref = 1
  )
  ci <- suppressMessages(confint(fit, "k:x", method = "wald"))
  expect_true(is.finite(ci$conf.low) && is.finite(ci$conf.high))
  expect_lt(ci$conf.low, ci$conf.high)
  # The interval is on the LINK (log) scale and brackets the estimate -- it must
  # NOT be back-transformed (a slope is not a natural-scale k).
  est_kx <- fit$estimates$estimate[fit$estimates$parameter == "k:x"]
  expect_gt(est_kx, ci$conf.low)
  expect_lt(est_kx, ci$conf.high)
  # profile routes general coefficients to Wald (no group level to profile).
  cp <- suppressMessages(confint(fit, "k:x", method = "profile"))
  expect_identical(cp$method, "wald")
})
