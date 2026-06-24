# The beta-binomial weak-dispersion advisory.
#
# When overdispersion is mild (phi large -> the data approach the binomial limit)
# the dispersion phi is weakly identified, and a PROFILE confidence interval for
# CTmax / z can under-cover. fit_tls() detects this from phi's relative SE
# (~ SE of log phi > 1) and points the user to method = "wald", which stays
# calibrated in this regime. The advisory is gated by `quiet`.

test_that("weakly-identified beta-binomial dispersion triggers the advisory; quiet silences it", {
  skip_on_cran()
  # phi large -> near binomial -> phi weakly identified -> relative SE > 1.
  d <- simulate_tls(family = "beta_binomial", CTmax = 36, z = 4, phi = 300, seed = 11)
  expect_warning(
    fit_tls(d, y = survived, n = total, time = duration, temp = temp,
            family = "beta_binomial", tref = 1),
    "weakly identified|close to binomial"
  )
  expect_no_warning(
    fit_tls(d, y = survived, n = total, time = duration, temp = temp,
            family = "beta_binomial", tref = 1, quiet = TRUE)
  )
})

test_that("a well-identified beta-binomial dispersion does not trigger the advisory", {
  skip_on_cran()
  # phi small -> strong overdispersion -> phi well identified (relative SE << 1).
  d <- simulate_tls(family = "beta_binomial", CTmax = 36, z = 4, phi = 5, seed = 12)
  expect_no_warning(
    fit_tls(d, y = survived, n = total, time = duration, temp = temp,
            family = "beta_binomial", tref = 1)
  )
})

test_that("confint(method = 'profile') falls back to Wald for weakly-identified phi", {
  skip_on_cran()
  d <- simulate_tls(family = "beta_binomial", CTmax = 36, z = 4, phi = 300, seed = 11)
  fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
                 family = "beta_binomial", tref = 1, quiet = TRUE)
  # fallback = TRUE (default): CTmax/z come back as Wald, with an informative note.
  ci <- expect_message(
    confint(fit, c("CTmax", "z"), method = "profile"),
    "weakly identified|Wald")
  expect_true(all(ci$method == "wald"))
  # fallback = FALSE: the raw profile is returned (no weak-phi routing).
  ci_raw <- suppressMessages(suppressWarnings(
    confint(fit, c("CTmax", "z"), method = "profile", fallback = FALSE)))
  expect_true(any(ci_raw$method == "profile"))
})
