# Tests for simulate_tls(): the grouped vector API recovers distinct per-group
# CTmax/z, misuse errors clearly (the footgun fix), and the truth attribute is
# correct. SPEC.md S11.

test_that("grouped vector API recovers distinct per-group CTmax and z", {
  d <- simulate_tls(family = "binomial",
                    group = c("A", "B"), CTmax = c(34, 38), z = c(3, 5),
                    seed = 2)
  fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
                 group = group, family = "binomial", tref = 1)

  expect_identical(fit$convergence$code, 0L)
  expect_true(isTRUE(fit$convergence$pdHess))

  est <- fit$estimates
  ctmax <- stats::setNames(
    est$estimate[startsWith(est$parameter, "CTmax")],
    est$group[startsWith(est$parameter, "CTmax")]
  )
  zhat <- stats::setNames(
    est$estimate[startsWith(est$parameter, "z")],
    est$group[startsWith(est$parameter, "z")]
  )

  expect_lt(abs(ctmax[["A"]] - 34), 0.5)
  expect_lt(abs(ctmax[["B"]] - 38), 0.5)
  expect_lt(abs(zhat[["A"]] - 3), 0.7)
  expect_lt(abs(zhat[["B"]] - 5), 0.9)

  # The groups really are distinct (not collapsed to a shared value).
  expect_gt(ctmax[["B"]], ctmax[["A"]] + 2)
  expect_gt(zhat[["B"]], zhat[["A"]] + 0.8)
})

test_that("the truth attribute records the simulating parameters", {
  d <- simulate_tls(family = "beta_binomial", CTmax = 36, z = 4, phi = 20,
                    seed = 5)
  truth <- attr(d, "truth")
  expect_identical(truth$family, "beta_binomial")
  expect_identical(truth$CTmax, 36)
  expect_identical(truth$z, 4)
  expect_identical(truth$phi, 20)
  expect_false(truth$grouped)

  dg <- simulate_tls(family = "binomial",
                     group = c("A", "B"), CTmax = c(34, 38), z = c(3, 5),
                     seed = 2)
  tg <- attr(dg, "truth")
  expect_true(tg$grouped)
  expect_identical(tg$CTmax, c(A = 34, B = 38))
  expect_identical(tg$z, c(A = 3, B = 5))
  expect_identical(tg$group_levels, c("A", "B"))
  expect_true("group" %in% names(dg))
})

test_that("misuse errors clearly instead of silently using defaults", {
  # The footgun: a list passed as `group` must error, not fall through to
  # default scalar CTmax/z.
  expect_error(
    simulate_tls(group = list(A = list(CTmax = 34))),
    regexp = "atomic vector"
  )

  # A grouped CTmax of the wrong length must error.
  expect_error(
    simulate_tls(group = c("A", "B", "C"), CTmax = c(34, 38), z = 4),
    regexp = "one value per group"
  )
  # Likewise for z.
  expect_error(
    simulate_tls(group = c("A", "B"), CTmax = c(34, 38), z = c(3, 4, 5)),
    regexp = "one value per group"
  )
  # A vector CTmax without a group is also an error.
  expect_error(
    simulate_tls(CTmax = c(34, 38), z = 4),
    regexp = "single value for an ungrouped"
  )
})

test_that("a scalar CTmax/z is an explicit shared recycle across groups", {
  d <- simulate_tls(family = "binomial", group = c("A", "B"),
                    CTmax = 36, z = 4, seed = 1)
  truth <- attr(d, "truth")
  expect_identical(truth$CTmax, c(A = 36, B = 36))
  expect_identical(truth$z, c(A = 4, B = 4))
})

test_that("duplicate group labels de-duplicate to distinct levels", {
  d <- simulate_tls(family = "binomial", group = c("A", "A", "B", "B"),
                    CTmax = c(34, 38), z = c(3, 5), seed = 1)
  truth <- attr(d, "truth")
  expect_identical(truth$group_levels, c("A", "B"))
  expect_identical(unname(truth$CTmax), c(34, 38))
})

test_that("the beta family returns a continuous proportion column", {
  d <- simulate_tls(family = "beta", CTmax = 36, z = 4, phi = 20, seed = 6)
  expect_true("prop" %in% names(d))
  expect_false(any(c("survived", "total") %in% names(d)))
  expect_true(all(d$prop > 0 & d$prop < 1))

  truth <- attr(d, "truth")
  expect_identical(truth$family, "beta")
  expect_identical(truth$phi, 20)
})

test_that("the beta family requires phi", {
  expect_error(
    simulate_tls(family = "beta", CTmax = 36, z = 4),
    regexp = "phi"
  )
})
