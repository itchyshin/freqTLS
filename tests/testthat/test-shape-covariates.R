# Covariate (grouped) effects on the shape parameters low / up / log_k (v0.2).
# The engine carries per-sub-parameter design matrices; the formula interface
# opts the shapes into a grouping factor. Intercept-only shapes are byte-identical
# (covered by the wider suite); these tests cover the grouped path.

test_that("grouped shapes (log_k ~ group) recover per-group steepness", {
  d <- simulate_tls(family = "binomial", group = c("A", "B"),
                    CTmax = c(35, 38), z = c(4, 3),
                    low = 0.02, up = 0.98, k = c(3, 9), seed = 4)
  fit <- suppressWarnings(fit_tls(
    tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
           CTmax ~ group, log_z ~ group,
           low ~ group, up ~ group, log_k ~ group),
    data = d, family = "binomial", tref = 1))

  expect_identical(fit$convergence$code, 0L)
  est <- fit$estimates
  kk <- stats::setNames(est$estimate[startsWith(est$parameter, "k:")],
                        est$group[startsWith(est$parameter, "k:")])
  expect_length(kk, 2L)
  # B is the steeper group; both recover within a wide tolerance.
  expect_gt(kk[["B"]], kk[["A"]])
  expect_lt(abs(kk[["A"]] - 3), 1.5)
  expect_lt(abs(kk[["B"]] - 9), 3)
})

test_that("grouped shapes get per-group estimates with Wald intervals and predict", {
  d <- simulate_tls(family = "binomial", group = c("A", "B"),
                    CTmax = c(35, 38), z = c(4, 3),
                    low = c(0.02, 0.05), up = c(0.97, 0.99), k = c(4, 6),
                    seed = 5)
  fit <- suppressWarnings(fit_tls(
    tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
           CTmax ~ group, log_z ~ group,
           low ~ group, up ~ group, log_k ~ group),
    data = d, family = "binomial", tref = 1))

  est <- fit$estimates
  expect_true(all(c("low:A", "low:B", "up:A", "up:B", "k:A", "k:B") %in%
                    est$parameter))
  # Wald CIs are available for a grouped shape coefficient.
  ci <- suppressMessages(confint(fit, "k:A", method = "wald"))
  expect_true(is.finite(ci$conf.low) && is.finite(ci$conf.high))
  expect_lt(ci$conf.low, ci$conf.high)
  # predict resolves the per-group shape (survival in (0, 1), per group).
  nd <- data.frame(temp = c(35, 38), duration = c(1, 1), group = c("A", "B"))
  p <- predict(fit, nd, type = "survival")
  expect_length(p, 2L)
  expect_true(all(p > 0 & p < 1))
})

test_that("grouped shape coordinates get profile and bootstrap intervals", {
  d <- simulate_tls(family = "binomial", group = c("A", "B"),
                    CTmax = c(35, 38), z = c(4, 3),
                    low = 0.02, up = 0.98, k = c(4, 7), seed = 8)
  fit <- suppressWarnings(fit_tls(
    tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
           CTmax ~ group, log_z ~ group,
           low ~ group, up ~ group, log_k ~ group),
    data = d, family = "binomial", tref = 1))

  # Profile interval for a grouped steepness coordinate (k:A -> beta_logk).
  pk <- suppressMessages(confint(fit, "k:A", method = "profile"))
  expect_identical(pk$method, "profile")
  expect_true(is.finite(pk$conf.low) && is.finite(pk$conf.high))
  expect_lt(pk$conf.low, pk$conf.high)
  # up:A has no single coordinate (nested gap), so it stays Wald, like scalar up.
  pu <- suppressMessages(confint(fit, "up:A", method = "profile"))
  expect_true(is.finite(pu$conf.low) && is.finite(pu$conf.high))
  # Bootstrap interval for a grouped lower-asymptote coordinate.
  bl <- suppressMessages(
    confint(fit, "low:A", method = "bootstrap", nboot = 50, boot_seed = 1)
  )
  expect_identical(bl$method, "bootstrap")
  expect_true(is.finite(bl$conf.low) && is.finite(bl$conf.high))
})

test_that("a shape may be grouped while the others stay shared", {
  d <- simulate_tls(family = "binomial", group = c("A", "B"),
                    CTmax = c(35, 38), z = c(4, 3), low = 0.02, up = 0.98,
                    k = c(4, 8), seed = 6)
  # log_k grouped while low / up stay shared: previously a "same design" error,
  # now allowed -- the engine handles independent shape design widths.
  fit <- suppressWarnings(fit_tls(
    tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
           CTmax ~ group, log_z ~ group, log_k ~ group),
    data = d, family = "binomial", tref = 1))
  expect_identical(fit$convergence$code, 0L)
  expect_true(all(c("k:A", "k:B") %in% fit$estimates$parameter))
})
