# Malformed-input behaviour of the tls_bf() formula interface (R/formula.R).
# Each case checks the specific, actionable message a user would see, and a
# few checks confirm that valid alternative spellings resolve to the same data.

ff_data <- function() {
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
  d$label <- "a"
  d
}

ff_fit <- function(bf, data = ff_data(), ...) {
  suppressWarnings(fit_tls(bf, data = data, family = "binomial", tref = 1, ...))
}

test_that("tls_bf() requires formulas, a response formula, and valid sub-parameters", {
  expect_error(tls_bf(), "requires at least the response-and-axes formula")
  expect_error(tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
                      "CTmax"),
               "inputs must be formulas")
  expect_error(tls_bf(~ time(duration) + temp(temp)),
               "must be the response-and-axes formula")
  expect_error(tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
                      ~ group),
               "must name a sub-parameter on the left-hand side")
  expect_error(tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
                      foo ~ group),
               "Unknown sub-parameter handle")
  expect_error(tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
                      CTmax ~ 1, CTmax ~ group),
               "given more than once")
})

test_that("tls_bf() stores sub-formulas by handle and prints a readable summary", {
  bf <- tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
               CTmax ~ group, log_z ~ 1)
  expect_s3_class(bf, "tls_formula")
  expect_named(bf$sub_formulas, c("CTmax", "log_z"))
  expect_identical(deparse1(bf$sub_formulas$CTmax), "CTmax ~ group")
  out <- NULL
  printed <- utils::capture.output(
    expect_message(out <- print(bf), "tls_formula")
  )
  expect_identical(out, bf)
  expect_true(any(grepl("CTmax ~ group", printed, fixed = TRUE)))
})

test_that("a random-effects grouping must be one existing, complete column", {
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, re_sd = 1,
                    n_re_groups = 10, seed = 5)
  d$other <- rep(c("u", "v"), length.out = nrow(d))
  base <- function(rhs) {
    tls_bf(survived | trials(total) ~ time(duration) + temp(temp), rhs)
  }
  expect_error(ff_fit(tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
                             CTmax ~ 1 + (1 | colony:other)), d),
               "must be a single column")
  expect_error(ff_fit(tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
                             CTmax ~ 1 + (1 | nosuchcol)), d),
               "not in .*data")
  d_na <- d
  d_na$colony[3] <- NA
  expect_error(ff_fit(tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
                             CTmax ~ 1 + (1 | colony)), d_na),
               "must not contain missing values")
})

test_that("a random-effects grouping with fewer than 8 levels warns", {
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, re_sd = 1,
                    n_re_groups = 5, seed = 5)
  expect_warning(
    fit_tls(tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
                   CTmax ~ 1 + (1 | colony)),
            data = d, family = "binomial", tref = 1),
    "only 5 levels"
  )
})

test_that("tls_parse_formula checks its inputs", {
  bf <- tls_bf(survived | trials(total) ~ time(duration) + temp(temp))
  expect_error(tls_parse_formula(survived ~ temp, ff_data()),
               "must be a .*tls_formula")
  expect_error(tls_parse_formula(bf, as.list(ff_data())),
               "must be a data frame")
})

test_that("response specifications are validated with actionable messages", {
  d <- ff_data()
  axes <- "~ time(duration) + temp(temp)"
  mk <- function(lhs) eval(parse(text = sprintf("tls_bf(%s %s)", lhs, axes)))
  expect_error(ff_fit(mk("nosuch | trials(total)")),
               "Could not find the successes column")
  expect_error(ff_fit(mk("survived | trials(nosuch)")),
               "Could not find the trials column")
  expect_error(ff_fit(mk("label | trials(total)")),
               "successes column .* must be numeric")
  expect_error(ff_fit(mk("survived | weights(total)")),
               "must be .*trials")
  expect_error(ff_fit(mk("survived | trials(total, total)")),
               "takes exactly one column")
  expect_error(ff_fit(mk("cbind(survived)")),
               "needs exactly two columns")
  expect_error(ff_fit(mk("cbind(survived, nosuch)")),
               "Could not find the failures column")
  expect_error(ff_fit(mk("log(survived)")),
               "Unrecognised response specification")
})

test_that("a count response with a bare proportion column asks for trials", {
  d <- ff_data()
  d$prop <- d$survived / d$total
  expect_error(
    suppressWarnings(fit_tls(tls_bf(prop ~ time(duration) + temp(temp)),
                             data = d, family = "binomial", tref = 1)),
    "trials"
  )
})

test_that("cbind(successes, failures) and successes | trials() give the same fit", {
  d <- ff_data()
  d$died <- d$total - d$survived
  a <- ff_fit(tls_bf(survived | trials(total) ~ time(duration) + temp(temp)), d)
  b <- ff_fit(tls_bf(cbind(survived, died) ~ time(duration) + temp(temp)), d)
  expect_equal(a$estimates$estimate, b$estimates$estimate, tolerance = 1e-8)
  expect_equal(a$logLik, b$logLik, tolerance = 1e-8)
})

test_that("time() and temp() axis markers are validated", {
  d <- ff_data()
  resp <- function(rhs) {
    eval(parse(text = sprintf("tls_bf(survived | trials(total) ~ %s)", rhs)))
  }
  expect_error(ff_fit(resp("time(duration) + time(duration) + temp(temp)")),
               "axis is given more than once")
  expect_error(ff_fit(resp("time(duration, total) + temp(temp)")),
               "takes exactly one column")
  expect_error(ff_fit(resp("time(duration) + temp(temp) + temp(temp)")),
               "axis is given more than once")
  expect_error(ff_fit(resp("time(duration) + temp(temp, total)")),
               "takes exactly one column")
  expect_error(ff_fit(resp("time(duration) + temp + temp(temp)")),
               "Untagged term")
  expect_error(ff_fit(resp("temp(temp)")), "missing the .*time.* axis")
  expect_error(ff_fit(resp("time(duration)")), "missing the .*temp.* axis")
  expect_error(ff_fit(resp("time(nosuch) + temp(temp)")),
               "Could not find the time column")
  expect_error(ff_fit(resp("time(duration) + temp(label)")),
               "temp column .* must be numeric")
})

test_that("fixed-effect designs reject missing and degenerate specifications", {
  d <- ff_data()
  d$grp <- rep(c("a", "b"), length.out = nrow(d))
  base <- function(...) {
    tls_bf(survived | trials(total) ~ time(duration) + temp(temp), ...)
  }
  expect_error(ff_fit(base(CTmax ~ 0)), "at least an intercept or a predictor")

  d_na <- d
  d_na$grp[2] <- NA
  expect_error(ff_fit(base(CTmax ~ grp), d_na),
               "grouping column must not contain missing values")

  d_x <- d
  d_x$x <- seq_len(nrow(d))
  expect_error(ff_fit(base(CTmax ~ x, log_z ~ 1), d_x),
               "must use the same fixed-effect predictors")
})

test_that("a single-factor CTmax formula labels cells by the factor levels", {
  d <- simulate_tls(family = "binomial", group = c("A", "B"),
                    CTmax = c(34, 38), z = c(3, 5), seed = 3)
  f_int <- ff_fit(tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
                         CTmax ~ group, log_z ~ group), d)
  f_cell <- ff_fit(tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
                          CTmax ~ 0 + group, log_z ~ 0 + group), d)
  expect_true(all(c("CTmax:A", "CTmax:B", "z:A", "z:B") %in%
                    f_int$estimates$parameter))
  expect_equal(f_int$estimates$estimate, f_cell$estimates$estimate,
               tolerance = 1e-6)
  est <- stats::setNames(f_int$estimates$estimate, f_int$estimates$parameter)
  expect_lt(abs(est[["CTmax:A"]] - 34), 0.7)
  expect_lt(abs(est[["CTmax:B"]] - 38), 0.7)
})
