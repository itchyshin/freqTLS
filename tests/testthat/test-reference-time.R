# One-hour reference resolution is a safety contract, not merely display text.

reference_sim <- function(unit = "hours", multiplier = 1) {
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 318)
  d$duration <- d$duration * multiplier
  standardize_data(
    d, temp = "temp", duration = "duration",
    n_total = "total", n_surv = "survived", duration_unit = unit
  )
}

test_that("omitted fit_4pl reference time means one physical hour", {
  hours <- reference_sim("hours", 1)
  minutes <- reference_sim("minutes", 60)
  seconds <- reference_sim("seconds", 3600)
  days <- reference_sim("days", 1 / 24)

  fits <- lapply(list(hours, minutes, seconds, days), function(d) {
    suppressWarnings(fit_4pl(d, family = "binomial", quiet = TRUE))
  })
  expect_identical(vapply(fits, function(f) f$meta$t_ref, numeric(1)),
                   c(1, 60, 3600, 1 / 24))
  expect_equal(vapply(fits, function(f) as.numeric(logLik(f)), numeric(1)),
               rep(as.numeric(logLik(fits[[1]])), 4), tolerance = 1e-8)
  expect_equal(vapply(fits, function(f) get_ctmax(f)$estimate, numeric(1)),
               rep(get_ctmax(fits[[1]])$estimate, 4), tolerance = 1e-8)
})

test_that("fit_tls resolves standardized column and formula interfaces", {
  minutes <- reference_sim("minutes", 60)
  col <- suppressWarnings(fit_tls(
    minutes, y = n_surv, n = n_total, time = duration, temp = temp,
    family = "binomial", quiet = TRUE
  ))
  frm <- suppressWarnings(fit_tls(
    tls_bf(n_surv | trials(n_total) ~ time(duration) + temp(temp)),
    data = minutes, family = "binomial", quiet = TRUE
  ))
  expect_identical(col$tref, 60)
  expect_identical(frm$tref, 60)
  expect_equal(as.numeric(logLik(col)), as.numeric(logLik(frm)), tolerance = 1e-8)
})

test_that("bare data preserve the historical one-unit reference with a warning", {
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 319)
  expect_warning(
    fallback <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
                        family = "binomial", quiet = TRUE),
    "No .*duration_unit.*metadata"
  )
  expect_identical(fallback$tref, 1)
  expect_no_warning(
    explicit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
                        family = "binomial", tref = 1, quiet = TRUE)
  )
  expect_identical(explicit$tref, 1)
})

test_that("unknown metadata requires an explicit reference and explicit values persist", {
  d <- reference_sim("weeks", 1)
  expect_error(
    fit_4pl(d, family = "binomial", quiet = TRUE),
    "Cannot resolve a one-hour"
  )
  fit <- suppressWarnings(fit_4pl(d, family = "binomial", t_ref = 240, quiet = TRUE))
  expect_identical(fit$meta$t_ref, 240)
})

test_that("an explicit reference is never converted to the one-hour convention", {
  minutes <- reference_sim("minutes", 60)
  one_minute <- suppressWarnings(
    fit_4pl(minutes, family = "binomial", t_ref = 1, quiet = TRUE)
  )
  one_hour <- suppressWarnings(
    fit_4pl(minutes, family = "binomial", quiet = TRUE)
  )
  expect_identical(one_minute$meta$t_ref, 1)
  expect_identical(one_hour$meta$t_ref, 60)
  expect_false(isTRUE(all.equal(get_ctmax(one_minute)$estimate,
                                 get_ctmax(one_hour)$estimate)))
})

test_that("reference time must be finite when supplied explicitly", {
  expect_error(
    freqTLS:::tls_resolve_tref(Inf),
    "finite positive"
  )
})
