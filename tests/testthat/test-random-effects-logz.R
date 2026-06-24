# Random intercept on log_z (item 5): log_z ~ <fixed> + (1 | group).
# The symmetric counterpart of the CTmax RE. Engine: b_logz / log_sd_logz /
# re_index_logz (src/profile_tls.cpp); parsing: tls_extract_re() (R/formula.R).
# sigma_logz is a SD on the LOG scale of z (~ a multiplicative spread on z), and
# like sigma_CTmax it is a maximum-likelihood variance component (biased low with
# few groups).

re_z_formula <- function() {
  tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
         log_z ~ 1 + (1 | colony))
}

test_that("a random intercept on log_z fits, converges, and recovers fixed effects", {
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4,
                    re_sd_z = 0.3, n_re_groups = 30, seed = 101)
  fit <- suppressWarnings(fit_tls(re_z_formula(), data = d, family = "binomial",
                                  tref = 1))
  expect_identical(fit$convergence$code, 0L)
  expect_true(isTRUE(fit$convergence$pdHess))

  # The fit carries the log_z RE structure (and no CTmax RE).
  expect_false(is.null(fit$re_logz))
  expect_true(is.null(fit$re))
  expect_identical(fit$re_logz$n, 30L)
  expect_identical(fit$tmb_inputs$random, "b_logz")

  est <- fit$estimates
  expect_true("sigma_logz" %in% est$parameter)
  expect_false("sigma_CTmax" %in% est$parameter)
  ct <- est$estimate[est$parameter == "CTmax"]
  z  <- est$estimate[est$parameter == "z"]
  sg <- est$estimate[est$parameter == "sigma_logz"]
  # Fixed effects recover tightly; sigma_logz is positive, finite, and has an SE.
  expect_true(ct > 35 && ct < 37)
  expect_true(z > 3.4 && z < 4.6)
  expect_true(is.finite(sg) && sg > 0)
  expect_true(is.finite(est$std.error[est$parameter == "sigma_logz"]))
})

test_that("sigma_logz recovers the random-intercept SD on average (ML, mildly low)", {
  skip_on_cran()
  sigs <- ct <- z <- numeric(0)
  for (s in 301:305) {
    d <- simulate_tls(family = "binomial", CTmax = 36, z = 4,
                      re_sd_z = 0.3, n_re_groups = 30, seed = s)
    fit <- tryCatch(
      suppressWarnings(fit_tls(re_z_formula(), data = d, family = "binomial", tref = 1)),
      error = function(e) NULL
    )
    if (!is.null(fit) && isTRUE(fit$convergence$pdHess)) {
      e <- fit$estimates
      sigs <- c(sigs, e$estimate[e$parameter == "sigma_logz"])
      ct   <- c(ct,   e$estimate[e$parameter == "CTmax"])
      z    <- c(z,    e$estimate[e$parameter == "z"])
    }
  }
  expect_gte(length(sigs), 4L)
  # ML variance components are biased low with few groups; band around truth 0.3.
  expect_gt(mean(sigs), 0.15)
  expect_lt(mean(sigs), 0.40)
  expect_true(mean(ct) > 35.6 && mean(ct) < 36.4)
  expect_true(mean(z) > 3.7 && mean(z) < 4.3)
})

test_that("the no-RE formula fit is unchanged by the log_z RE machinery", {
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 7)
  f_col <- suppressWarnings(fit_tls(d, y = survived, n = total, time = duration,
                                    temp = temp, family = "binomial", tref = 1))
  f_form <- suppressWarnings(fit_tls(
    tls_bf(survived | trials(total) ~ time(duration) + temp(temp)),
    data = d, family = "binomial", tref = 1))
  expect_true(is.null(f_col$re_logz))
  expect_true(is.null(f_form$re_logz))
  expect_equal(f_col$estimates$estimate, f_form$estimates$estimate, tolerance = 1e-8)
  expect_false("sigma_logz" %in% f_col$estimates$parameter)
})

test_that("ranef() returns log_z BLUPs and sigma_logz gets a Wald interval", {
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4,
                    re_sd_z = 0.3, n_re_groups = 12, seed = 42)
  fit <- suppressWarnings(fit_tls(re_z_formula(), data = d, family = "binomial",
                                  tref = 1))
  re <- ranef(fit)
  expect_s3_class(re, "tbl_df")
  expect_identical(nrow(re), 12L)
  expect_identical(names(re), c("group", "term", "estimate", "std.error"))
  expect_true(all(re$term == "log_z"))
  expect_true(all(is.finite(re$estimate)) && all(is.finite(re$std.error)))
  # BLUPs are deviations on log(z), centred near zero.
  expect_lt(abs(mean(re$estimate)), 0.5)

  # sigma_logz gets a positive (log-scale) Wald interval.
  ci <- suppressMessages(confint(fit, "sigma_logz", method = "wald"))
  expect_true(is.finite(ci$conf.low) && is.finite(ci$conf.high))
  expect_gt(ci$conf.low, 0)
  expect_lt(ci$conf.low, ci$conf.high)
})

test_that("sigma_logz stays on Wald under method = profile (no profile coordinate)", {
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4,
                    re_sd_z = 0.3, n_re_groups = 8, seed = 5)
  fit <- suppressWarnings(fit_tls(re_z_formula(), data = d, family = "binomial",
                                  tref = 1))
  ci_s <- suppressMessages(confint(fit, "sigma_logz", method = "profile"))
  expect_identical(ci_s$method, "wald")
  expect_true(is.finite(ci_s$conf.low))
})

test_that("a log_z RE profiles fixed effects under the Laplace (slow; skipped on CRAN)", {
  skip_on_cran()
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4,
                    temps = seq(32, 40, by = 2), times = c(1, 2, 4, 8), reps = 2,
                    re_sd_z = 0.3, n_re_groups = 6, seed = 5)
  fit <- suppressWarnings(fit_tls(re_z_formula(), data = d, family = "binomial",
                                  tref = 1))
  ci_p <- suppressMessages(confint(fit, "z", method = "profile", npoints = 6))
  expect_identical(ci_p$method, "profile")
  expect_true(is.finite(ci_p$conf.low) && is.finite(ci_p$conf.high))
  expect_lt(ci_p$conf.low, ci_p$conf.high)
  # Profile brackets the truth z = 4.
  expect_lt(ci_p$conf.low, 4)
  expect_gt(ci_p$conf.high, 4)
})

test_that("the RE-aware bootstrap gives a prior-free sigma_logz interval (slow; skipped on CRAN)", {
  skip_on_cran()
  d <- simulate_tls(family = "binomial",
                    temps = c(34, 36, 38), times = c(1, 4), reps = 2, n = 12,
                    CTmax = 36, z = 4, re_sd_z = 0.3, n_re_groups = 8, seed = 5)
  fit <- suppressWarnings(fit_tls(re_z_formula(), data = d, family = "binomial",
                                  tref = 1))
  ci <- suppressMessages(
    confint(fit, "sigma_logz", method = "bootstrap", nboot = 40, boot_seed = 1)
  )
  expect_identical(ci$method, "bootstrap")
  expect_true(is.finite(ci$conf.low) && is.finite(ci$conf.high))
  expect_gt(ci$conf.low, 0)
  expect_lt(ci$conf.low, ci$conf.high)
})

test_that("RE scope on log_z is enforced (intercept only, single grouping)", {
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4,
                    re_sd_z = 0.3, n_re_groups = 6, seed = 3)
  d$other <- rep(letters[1:3], length.out = nrow(d))

  # Random slope on log_z is not allowed.
  expect_error(
    suppressWarnings(fit_tls(
      tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
             log_z ~ (temp | colony)),
      data = d, family = "binomial", tref = 1)),
    "random intercept|slope"
  )
  # More than one grouping factor on log_z is not allowed.
  expect_error(
    suppressWarnings(fit_tls(
      tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
             log_z ~ (1 | colony) + (1 | other)),
      data = d, family = "binomial", tref = 1)),
    "one random-effects term"
  )
})

test_that("REs on both CTmax and log_z with the same grouping warn but fit", {
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4,
                    re_sd = 1.0, re_sd_z = 0.3, n_re_groups = 14, seed = 9)
  # Same grouping factor on both -> independent variances, correlation forced to
  # zero; this is an honest hazard and must warn.
  expect_warning(
    fit <- fit_tls(
      tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
             CTmax ~ 1 + (1 | colony), log_z ~ 1 + (1 | colony)),
      data = d, family = "binomial", tref = 1),
    "independent|both|correlat"
  )
  expect_false(is.null(fit$re))
  expect_false(is.null(fit$re_logz))
  expect_identical(fit$tmb_inputs$random, c("b_CT", "b_logz"))
  est <- fit$estimates
  expect_true(all(c("sigma_CTmax", "sigma_logz") %in% est$parameter))
  expect_true(all(is.finite(est$estimate)))

  # ranef() returns both terms.
  re <- ranef(fit)
  expect_setequal(unique(re$term), c("CTmax", "log_z"))
  expect_identical(nrow(re), 28L)  # 14 groups x 2 terms
})

test_that("REs on CTmax and log_z with DIFFERENT groupings coexist without the same-group warning", {
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4,
                    re_sd_z = 0.3, n_re_groups = 12, seed = 11)
  # A second, independent grouping factor for the CTmax RE.
  d$batch <- paste0("b", rep(1:4, length.out = nrow(d)))
  fit <- suppressWarnings(fit_tls(
    tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
           CTmax ~ 1 + (1 | batch), log_z ~ 1 + (1 | colony)),
    data = d, family = "binomial", tref = 1))
  expect_false(is.null(fit$re))
  expect_false(is.null(fit$re_logz))
  expect_identical(fit$re$group_var, "batch")
  expect_identical(fit$re_logz$group_var, "colony")
  expect_true(all(c("sigma_CTmax", "sigma_logz") %in% fit$estimates$parameter))
})

test_that("simulate_tls re_sd_z mode validates its arguments", {
  expect_error(
    simulate_tls(family = "binomial", re_sd_z = 0.3, n_re_groups = 5,
                 group = c("A", "B"), CTmax = c(35, 38), z = c(4, 3)),
    "cannot be combined"
  )
  expect_error(
    simulate_tls(family = "binomial", re_sd_z = 0.3),  # missing n_re_groups
    "n_re_groups"
  )
  d <- simulate_tls(family = "binomial", re_sd_z = 0.4, n_re_groups = 8, seed = 1)
  expect_true("colony" %in% names(d))
  expect_identical(length(unique(d$colony)), 8L)
  expect_identical(attr(d, "truth")$re_sd_z, 0.4)

  # Both REs together: one colony column, two sets of deviations recorded.
  d2 <- simulate_tls(family = "binomial", re_sd = 1, re_sd_z = 0.3,
                     n_re_groups = 6, seed = 2)
  expect_identical(length(unique(d2$colony)), 6L)
  expect_identical(attr(d2, "truth")$re_sd, 1)
  expect_identical(attr(d2, "truth")$re_sd_z, 0.3)
})
