# Tests for the data-adequacy / identifiability diagnostics in R/diagnostics.R.
# check_tls_data() is exercised directly on hand-built designs so that each
# warning code fires (or stays silent) for a known, checkable reason; check_tls()
# is exercised on fitted objects and on malformed inputs.

# Run check_tls_data() and return both the codes and the warning messages.
run_diag <- function(...) {
  msgs <- character(0)
  codes <- withCallingHandlers(
    check_tls_data(...),
    warning = function(w) {
      msgs <<- c(msgs, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  list(codes = codes, msgs = msgs)
}

# A well-spread design: 3 temperatures x 3 durations, survival from ~1 to ~0
# crossing 0.5, so no data-adequacy concern should fire.
good_design <- function() {
  list(
    temp = rep(c(34, 36, 38), each = 3),
    time = rep(c(1, 10, 100), times = 3),
    y    = c(48, 40, 5, 45, 25, 1, 30, 4, 0),
    n    = rep(50, 9)
  )
}

test_that("a well-spread design triggers no diagnostics", {
  g <- good_design()
  expect_silent(codes <- check_tls_data(g$y, g$n, g$time, g$temp))
  expect_identical(codes, character(0))
})

test_that("fewer than 3 temperatures fires `temps` with the count in the message", {
  g <- good_design()
  keep <- g$temp != 38
  r <- run_diag(g$y[keep], g$n[keep], g$time[keep], g$temp[keep])
  expect_true("temps" %in% r$codes)
  expect_true(any(grepl("Fewer than 3 unique temperatures (2 found)",
                        r$msgs, fixed = TRUE)))
})

test_that("fewer than 3 durations fires `durations` and suppresses the per-temperature check", {
  g <- good_design()
  keep <- g$time != 100
  r <- run_diag(g$y[keep], g$n[keep], g$time[keep], g$temp[keep])
  expect_true("durations" %in% r$codes)
  expect_false("durations_per_temp" %in% r$codes)
  expect_true(any(grepl("Fewer than 3 unique durations (2 found) overall",
                        r$msgs, fixed = TRUE)))
})

test_that("a temperature with fewer than 3 durations fires `durations_per_temp`", {
  # Three durations overall, but temperature 36 was only assayed at two of them.
  temp <- c(34, 34, 34, 36, 36, 38, 38, 38)
  time <- c(1, 10, 100, 1, 10, 1, 10, 100)
  y    <- c(48, 30, 2, 40, 5, 30, 4, 0)
  r <- run_diag(y, rep(50, 8), time, temp)
  expect_identical(r$codes, "durations_per_temp")
  expect_match(r$msgs, "temperature \"36\"", fixed = TRUE)
})

test_that("all-survived data fires `no_mortality` and flags the missing lower asymptote", {
  g <- good_design()
  r <- run_diag(g$n, g$n, g$time, g$temp)
  expect_setequal(r$codes, c("no_mortality", "low_not_approached"))
  expect_true(any(grepl("No mortality anywhere", r$msgs)))
})

test_that("all-died data fires `all_mortality` and flags the missing upper asymptote", {
  g <- good_design()
  r <- run_diag(rep(0, 9), g$n, g$time, g$temp)
  expect_setequal(r$codes, c("all_mortality", "up_not_approached"))
  expect_true(any(grepl("All mortality anywhere", r$msgs)))
})

test_that("`threshold` fires when partial survival stays on one side of 0.5", {
  g <- good_design()
  # Survival between 0.6 and 0.95 everywhere: partial mortality, never below 0.5.
  y_hi <- c(47, 46, 45, 44, 43, 42, 41, 40, 39)
  r_hi <- run_diag(y_hi, g$n, g$time, g$temp)
  expect_true("threshold" %in% r_hi$codes)
  expect_true(any(grepl("all above 0.5", r_hi$msgs)))
  expect_true("low_not_approached" %in% r_hi$codes)

  # Survival between 0.04 and 0.4 everywhere: never above 0.5.
  y_lo <- c(20, 18, 16, 12, 10, 8, 6, 4, 2)
  r_lo <- run_diag(y_lo, g$n, g$time, g$temp)
  expect_true("threshold" %in% r_lo$codes)
  expect_true(any(grepl("all below 0.5", r_lo$msgs)))
  expect_true("up_not_approached" %in% r_lo$codes)
})

test_that("asymptote diagnostics use the 0.80 and 0.20 cut-offs", {
  g <- good_design()
  y <- c(38, 30, 20, 30, 20, 10, 20, 12, 8)  # max 0.76, min 0.16
  r <- run_diag(y, g$n, g$time, g$temp)
  expect_true("up_not_approached" %in% r$codes)
  expect_false("low_not_approached" %in% r$codes)
  expect_true(any(grepl("max observed survival 0.76 < 0.80", r$msgs, fixed = TRUE)))

  y2 <- c(49, 40, 30, 45, 35, 25, 40, 30, 20)  # min 0.4
  r2 <- run_diag(y2, g$n, g$time, g$temp)
  expect_true("low_not_approached" %in% r2$codes)
  expect_false("up_not_approached" %in% r2$codes)
  expect_true(any(grepl("min observed survival 0.4 > 0.20", r2$msgs, fixed = TRUE)))
})

test_that("CTmax extrapolation (item 7) fires only outside the assayed range", {
  g <- good_design()
  expect_silent(
    inside <- check_tls_data(g$y, g$n, g$time, g$temp, ctmax = c(35, 37))
  )
  expect_identical(inside, character(0))

  r <- run_diag(g$y, g$n, g$time, g$temp, ctmax = c(35, 41.234))
  expect_identical(r$codes, "ctmax_extrapolated")
  expect_match(r$msgs, "41.23", fixed = TRUE)
  expect_match(r$msgs, "[34, 38]", fixed = TRUE)

  r_low <- run_diag(g$y, g$n, g$time, g$temp, ctmax = 30)
  expect_identical(r_low$codes, "ctmax_extrapolated")
})

test_that("phi at the binomial limit (item 8) fires only for phi > 1e4", {
  g <- good_design()
  expect_silent(check_tls_data(g$y, g$n, g$time, g$temp, phi = 50))
  expect_silent(check_tls_data(g$y, g$n, g$time, g$temp, phi = 1e4))
  expect_silent(check_tls_data(g$y, g$n, g$time, g$temp, phi = Inf))
  r <- run_diag(g$y, g$n, g$time, g$temp, phi = 5e4)
  expect_identical(r$codes, "phi_binomial_limit")
  expect_match(r$msgs, "phi (50000)", fixed = TRUE)
})

test_that("multiple concerns accumulate in one call", {
  r <- run_diag(y = c(10, 10), n = c(10, 10), time = c(1, 1), temp = c(30, 30))
  expect_true(all(c("temps", "durations", "no_mortality") %in% r$codes))
  expect_gte(length(r$msgs), 3L)
})

test_that("check_tls() returns no codes for a well-designed binomial fit", {
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
  fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
                 family = "binomial", tref = 1)
  expect_silent(codes <- check_tls(fit))
  expect_identical(codes, character(0))
})

test_that("check_tls() reads phi from a beta-binomial fit without flagging it", {
  d <- simulate_tls(family = "beta_binomial", CTmax = 36, z = 4, phi = 20,
                    seed = 1)
  fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
                 family = "beta_binomial", tref = 1)
  expect_lt(fit$estimates$estimate[fit$estimates$parameter == "phi"], 1e4)
  expect_silent(codes <- check_tls(fit))
  expect_identical(codes, character(0))
})

test_that("check_tls() flags a CTmax extrapolated beyond the assayed temperatures", {
  # Simulated assays span 30-42 C and durations 0.5-8. With tref = 60 the
  # reference-time CTmax (the temperature giving 50% survival after 60 time
  # units) is ~28.8 C, i.e. below every assayed temperature.
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
  fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
                 family = "binomial", tref = 60)
  ctmax_hat <- fit$estimates$estimate[fit$estimates$parameter == "CTmax"]
  expect_lt(ctmax_hat, min(d$temp))
  msgs <- character(0)
  codes <- withCallingHandlers(
    check_tls(fit),
    warning = function(w) {
      msgs <<- c(msgs, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  expect_identical(codes, "ctmax_extrapolated")
  expect_true(any(grepl("outside the assayed temperature range [30, 42]",
                        msgs, fixed = TRUE)))
})

test_that("check_tls() rejects objects that are not fits", {
  expect_error(check_tls(data.frame(a = 1)), "must be a")
  expect_error(check_tls(NULL), "profile_tls")
})

test_that("check_tls() aborts when the fit carries no diagnostic data", {
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
  fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
                 family = "binomial", tref = 1)
  fit$diag_data <- NULL
  expect_error(check_tls(fit), "does not carry the data needed for diagnostics")
})
