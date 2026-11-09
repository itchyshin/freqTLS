# Input validation for fit_tls() (R/fit_tls.R), the Beta-family response rules,
# and the print/summary/vcov/ranef methods on grouped, Beta, and random-effect
# fits (R/methods.R).

# print()/summary() write a cli header as messages and a table to stdout; capture
# both and return the messages so they can be matched.
printed_messages <- function(x) {
  msgs <- testthat::capture_messages(utils::capture.output(print(x)))
  paste(msgs, collapse = "")
}

fv_data <- function() simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)

fv_fit <- function(d = fv_data(), ...) {
  suppressWarnings(fit_tls(d, y = survived, n = total, time = duration,
                           temp = temp, family = "binomial", tref = 1, ...))
}

test_that("fit_tls rejects inputs that are neither data frames nor tls_bf formulas", {
  expect_error(fit_tls(1:3, y = a, n = b, time = c, temp = d, family = "binomial"),
               "must be a data frame")
  bf <- tls_bf(survived | trials(total) ~ time(duration) + temp(temp))
  expect_error(fit_tls(bf, family = "binomial", tref = 1), "needs a .*data.* frame")
})

test_that("fit_tls explains missing, unresolvable, and non-numeric columns", {
  d <- fv_data()
  expect_error(fit_tls(d, n = total, time = duration, temp = temp,
                       family = "binomial", tref = 1),
               "`y` must name a column")
  expect_error(fit_tls(d, y = nosuch, n = total, time = duration, temp = temp,
                       family = "binomial", tref = 1),
               "Could not resolve .*y.*nosuch")
  d$chr <- "x"
  expect_error(fit_tls(d, y = survived, n = total, time = chr, temp = temp,
                       family = "binomial", tref = 1),
               "Column .*time.* must be numeric")
})

test_that("fit_tls rejects missing values, non-positive durations, and impossible counts", {
  d <- fv_data()
  na_t <- d; na_t$temp[2] <- NA
  expect_error(fit_tls(na_t, y = survived, n = total, time = duration, temp = temp,
                       family = "binomial", tref = 1),
               "must not contain missing values")
  bad_time <- d; bad_time$duration[1] <- 0
  expect_error(fit_tls(bad_time, y = survived, n = total, time = duration,
                       temp = temp, family = "binomial", tref = 1),
               "strictly positive")
  over <- d; over$survived[1] <- over$total[1] + 1
  expect_error(fit_tls(over, y = survived, n = total, time = duration, temp = temp,
                       family = "binomial", tref = 1),
               "0 <= y <= n")
  zero_n <- d; zero_n$total[1] <- 0
  expect_error(fit_tls(zero_n, y = survived, n = total, time = duration,
                       temp = temp, family = "binomial", tref = 1),
               "0 <= y <= n")
  neg <- d; neg$survived[1] <- -1
  expect_error(fit_tls(neg, y = survived, n = total, time = duration, temp = temp,
                       family = "binomial", tref = 1),
               "0 <= y <= n")
})

test_that("count families require trials and start must be a named list", {
  d <- fv_data()
  expect_error(fit_tls(d, y = survived, time = duration, temp = temp,
                       family = "binomial", tref = 1),
               "trials.*required.*binomial")
  expect_error(fit_tls(d, y = survived, n = total, time = duration, temp = temp,
                       family = "binomial", tref = 1, start = c(1, 2)),
               "must be a named list")
  expect_error(fit_tls(d, y = survived, n = total, time = duration, temp = temp,
                       family = "binomial", tref = -1),
               "single finite positive number")
})

test_that("the Beta family needs no trials, validates the range, and clamps boundaries", {
  d <- simulate_tls(family = "beta", phi = 30, CTmax = 36, z = 4, seed = 8)
  fit <- fit_tls(d, y = prop, time = duration, temp = temp, family = "beta", tref = 1)
  est <- stats::setNames(fit$estimates$estimate, fit$estimates$parameter)
  expect_lt(abs(est[["CTmax"]] - 36), 0.6)
  expect_lt(abs(est[["z"]] - 4), 0.8)
  expect_true(est[["phi"]] > 5 && est[["phi"]] < 200)

  out_of_range <- d
  out_of_range$prop[1] <- 1.2
  expect_error(fit_tls(out_of_range, y = prop, time = duration, temp = temp,
                       family = "beta", tref = 1),
               "must be a proportion in \\[0, 1\\].*1 value")

  edge <- d
  edge$prop[c(1, 2)] <- c(0, 1)
  expect_warning(
    fit_e <- fit_tls(edge, y = prop, time = duration, temp = temp,
                     family = "beta", tref = 1),
    "Clamped 2 boundary proportions"
  )
  expect_s3_class(fit_e, "profile_tls")
  expect_no_warning(
    fit_tls(edge, y = prop, time = duration, temp = temp, family = "beta",
            tref = 1, quiet = TRUE)
  )
})

test_that("print and summary describe Beta, grouped, and random-intercept fits", {
  d <- simulate_tls(family = "beta", phi = 30, CTmax = 36, z = 4, seed = 8)
  fb <- fit_tls(d, y = prop, time = duration, temp = temp, family = "beta", tref = 1)
  expect_match(printed_messages(fb), "mean observed proportion")
  expect_match(printed_messages(summary(fb)), "family: beta")

  dg <- simulate_tls(family = "binomial", group = c("A", "B"),
                     CTmax = c(34, 38), z = c(3, 5), seed = 2)
  fg <- suppressWarnings(
    fit_tls(dg, y = survived, n = total, time = duration, temp = temp,
            group = group, family = "binomial", tref = 1))
  expect_match(printed_messages(fg), "2 groups \\(A, B\\)")
  expect_match(printed_messages(summary(fg)), "2 groups \\(A, B\\)")

  dr <- simulate_tls(family = "binomial", CTmax = 36, z = 4, re_sd = 1.5,
                     n_re_groups = 10, seed = 42)
  fr <- suppressWarnings(fit_tls(
    tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
           CTmax ~ 1 + (1 | colony)),
    data = dr, family = "binomial", tref = 1))
  expect_match(printed_messages(fr),
               "Random intercept on CTmax: \\(1 \\| colony\\), 10 groups")
})

test_that("vcov and ranef degrade with informative messages when the sdreport is missing", {
  fit <- fv_fit()
  no_vc <- fit
  no_vc$vcov <- NULL
  expect_warning(v <- vcov(no_vc), "did not produce a covariance")
  expect_null(v)
  expect_equal(nrow(vcov(fit)), ncol(vcov(fit)))

  dr <- simulate_tls(family = "binomial", CTmax = 36, z = 4, re_sd = 1.5,
                     n_re_groups = 10, seed = 42)
  fr <- suppressWarnings(fit_tls(
    tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
           CTmax ~ 1 + (1 | colony)),
    data = dr, family = "binomial", tref = 1))
  re <- ranef(fr)
  expect_equal(nrow(re), 10L)
  expect_true(all(is.finite(re$estimate)))
  expect_error(ranef(fr, extra = 1), "reserved")
  fr$sdreport <- NULL
  expect_error(ranef(fr), "sdreport.*unavailable")
})

test_that("tls_fmt formats numbers and missing values", {
  expect_identical(tls_fmt(numeric(0)), "NA")
  expect_identical(tls_fmt(NA_real_), "NA")
  expect_identical(tls_fmt(3.14159265, digits = 3), "3.14")
})
