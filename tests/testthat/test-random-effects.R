# Random intercept on CTmax (v0.2): CTmax ~ <fixed> + (1 | group).
# Engine: src/profile_tls.cpp (b_CT, log_sd_CT, re_index); parsing: R/formula.R.

re_formula <- function() {
  tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
         CTmax ~ 1 + (1 | colony))
}

test_that("a random intercept on CTmax fits, converges, and recovers fixed effects", {
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4,
                    re_sd = 1.5, n_re_groups = 30, seed = 101)
  fit <- suppressWarnings(fit_tls(re_formula(), data = d, family = "binomial",
                                  tref = 1))
  expect_identical(fit$convergence$code, 0L)
  expect_true(isTRUE(fit$convergence$pdHess))

  # The fit carries the RE structure.
  expect_false(is.null(fit$re))
  expect_identical(fit$re$n, 30L)
  expect_identical(fit$tmb_inputs$random, "b_CT")

  est <- fit$estimates
  expect_true("sigma_CTmax" %in% est$parameter)
  ct <- est$estimate[est$parameter == "CTmax"]
  z  <- est$estimate[est$parameter == "z"]
  sg <- est$estimate[est$parameter == "sigma_CTmax"]
  # Fixed effects recover tightly; sigma is positive and finite (recovery of the
  # SD itself is checked, averaged, below).
  expect_true(ct > 35 && ct < 37)
  expect_true(z > 3.5 && z < 4.5)
  expect_true(is.finite(sg) && sg > 0)
  expect_true(is.finite(est$std.error[est$parameter == "sigma_CTmax"]))
})

test_that("sigma_CTmax recovers the random-intercept SD on average (ML, mildly low)", {
  skip_on_cran()
  sigs <- ct <- z <- numeric(0)
  for (s in 201:205) {
    d <- simulate_tls(family = "binomial", CTmax = 36, z = 4,
                      re_sd = 1.5, n_re_groups = 30, seed = s)
    fit <- tryCatch(
      suppressWarnings(fit_tls(re_formula(), data = d, family = "binomial", tref = 1)),
      error = function(e) NULL
    )
    if (!is.null(fit) && isTRUE(fit$convergence$pdHess)) {
      e <- fit$estimates
      sigs <- c(sigs, e$estimate[e$parameter == "sigma_CTmax"])
      ct   <- c(ct,   e$estimate[e$parameter == "CTmax"])
      z    <- c(z,    e$estimate[e$parameter == "z"])
    }
  }
  expect_gte(length(sigs), 4L)
  # ML variance components are biased low with few groups, so the band is
  # asymmetric around the truth (1.5) rather than tight.
  expect_gt(mean(sigs), 1.0)
  expect_lt(mean(sigs), 1.7)
  expect_true(mean(ct) > 35.6 && mean(ct) < 36.4)
  expect_true(mean(z) > 3.85 && mean(z) < 4.15)
})

test_that("the no-RE formula fit is unchanged by the RE machinery", {
  # A formula fit with no random bar must equal the column-interface fit.
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 7)
  f_col <- suppressWarnings(fit_tls(d, y = survived, n = total, time = duration,
                                    temp = temp, family = "binomial", tref = 1))
  f_form <- suppressWarnings(fit_tls(
    tls_bf(survived | trials(total) ~ time(duration) + temp(temp)),
    data = d, family = "binomial", tref = 1))
  expect_true(is.null(f_col$re))
  expect_true(is.null(f_form$re))
  expect_equal(f_col$estimates$estimate, f_form$estimates$estimate, tolerance = 1e-8)
  expect_false("sigma_CTmax" %in% f_col$estimates$parameter)
})

test_that("RE scope is enforced (no up RE, intercept only, single grouping)", {
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4,
                    re_sd = 1, n_re_groups = 6, seed = 3)
  d$other <- rep(letters[1:3], length.out = nrow(d))

  # RE on the upper-asymptote gap (up) is not allowed (no single coordinate);
  # low / log_k REs ARE allowed (tested in test-shape-random-effects.R).
  expect_error(
    suppressWarnings(fit_tls(
      tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
             up ~ (1 | colony)),
      data = d, family = "binomial", tref = 1)),
    "up|CTmax|log_z|low|log_k"
  )
  # Random slope is not allowed.
  expect_error(
    suppressWarnings(fit_tls(
      tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
             CTmax ~ (temp | colony)),
      data = d, family = "binomial", tref = 1)),
    "random intercept|slope"
  )
  # More than one grouping factor is not allowed.
  expect_error(
    suppressWarnings(fit_tls(
      tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
             CTmax ~ (1 | colony) + (1 | other)),
      data = d, family = "binomial", tref = 1)),
    "one random-effects term"
  )
})

test_that("simulate_tls re_sd mode validates its arguments", {
  expect_error(
    simulate_tls(family = "binomial", re_sd = 1, n_re_groups = 5,
                 group = c("A", "B"), CTmax = c(35, 38), z = c(4, 3)),
    "cannot be combined"
  )
  expect_error(
    simulate_tls(family = "binomial", re_sd = 1),  # missing n_re_groups
    "n_re_groups"
  )
  d <- simulate_tls(family = "binomial", re_sd = 1.2, n_re_groups = 8, seed = 1)
  expect_true("colony" %in% names(d))
  expect_identical(length(unique(d$colony)), 8L)
  expect_identical(attr(d, "truth")$re_sd, 1.2)
})

test_that("ranef() returns CTmax BLUPs and sigma_CTmax gets a Wald interval", {
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4,
                    re_sd = 1.5, n_re_groups = 12, seed = 42)
  fit <- suppressWarnings(fit_tls(re_formula(), data = d, family = "binomial",
                                  tref = 1))
  re <- ranef(fit)
  expect_s3_class(re, "tbl_df")
  expect_identical(nrow(re), 12L)
  expect_identical(names(re), c("group", "term", "estimate", "std.error"))
  expect_true(all(re$term == "CTmax"))
  expect_true(all(is.finite(re$estimate)) && all(is.finite(re$std.error)))
  # BLUPs are deviations from the fixed CTmax, centred near zero.
  expect_lt(abs(mean(re$estimate)), 1)

  # sigma_CTmax now gets a positive (log-scale) Wald interval.
  ci <- suppressMessages(confint(fit, "sigma_CTmax", method = "wald"))
  expect_true(is.finite(ci$conf.low) && is.finite(ci$conf.high))
  expect_gt(ci$conf.low, 0)
  expect_lt(ci$conf.low, ci$conf.high)

  # ranef() errors on a fixed-effects-only fit.
  d0 <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
  f0 <- suppressWarnings(fit_tls(d0, y = survived, n = total, time = duration,
                                 temp = temp, family = "binomial", tref = 1))
  expect_error(ranef(f0), "no random effects")
})

test_that("RE fits profile fixed effects under the Laplace (slow; skipped on CRAN)", {
  skip_on_cran()
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4,
                    temps = seq(32, 40, by = 2), times = c(1, 2, 4, 8), reps = 2,
                    re_sd = 1, n_re_groups = 6, seed = 5)
  fit <- suppressWarnings(fit_tls(re_formula(), data = d, family = "binomial",
                                  tref = 1))
  # confint(method = "profile") now profiles the fixed effect under the RE by
  # re-running the Laplace at each grid point.
  ci_p <- suppressMessages(confint(fit, "CTmax", method = "profile", npoints = 6))
  expect_identical(ci_p$method, "profile")
  expect_true(is.finite(ci_p$conf.low) && is.finite(ci_p$conf.high))
  expect_lt(ci_p$conf.low, ci_p$conf.high)
  # Profile ~ Wald for a well-identified fixed effect; both cover the truth.
  ci_w <- suppressMessages(confint(fit, "CTmax", method = "wald"))
  expect_lt(abs(ci_p$conf.low - ci_w$conf.low), 0.6)
  expect_lt(ci_p$conf.low, 36)
  expect_gt(ci_p$conf.high, 36)
  # Direct profile() also works for a coordinate target on an RE fit.
  expect_s3_class(suppressMessages(profile(fit, "CTmax", npoints = 6)),
                  "profile_tls_profile")
})

test_that("sigma_CTmax stays on Wald under method = profile (no profile coordinate)", {
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4,
                    re_sd = 1, n_re_groups = 8, seed = 5)
  fit <- suppressWarnings(fit_tls(re_formula(), data = d, family = "binomial",
                                  tref = 1))
  # log_sd_CT has no profile target, so sigma_CTmax stays Wald under "profile".
  ci_s <- suppressMessages(confint(fit, "sigma_CTmax", method = "profile"))
  expect_identical(ci_s$method, "wald")
  expect_true(is.finite(ci_s$conf.low))
})

test_that("the RE-aware bootstrap gives a prior-free sigma_CTmax interval (slow; skipped on CRAN)", {
  skip_on_cran()
  d <- simulate_tls(family = "binomial",
                    temps = c(34, 36, 38), times = c(1, 4), reps = 2, n = 12,
                    CTmax = 36, z = 4, re_sd = 1.2, n_re_groups = 8, seed = 5)
  fit <- suppressWarnings(fit_tls(re_formula(), data = d, family = "binomial",
                                  tref = 1))
  # The parametric bootstrap redraws b_g ~ N(0, sigma_hat) and refits with the
  # random block, giving a prior-free interval for the variance component.
  ci <- suppressMessages(
    confint(fit, "sigma_CTmax", method = "bootstrap", nboot = 40, boot_seed = 1)
  )
  expect_identical(ci$method, "bootstrap")
  expect_true(is.finite(ci$conf.low) && is.finite(ci$conf.high))
  expect_gt(ci$conf.low, 0)
  expect_lt(ci$conf.low, ci$conf.high)
  # The fixed effects are bootstrapped too, and CTmax covers the truth.
  ci_ct <- suppressMessages(
    confint(fit, "CTmax", method = "bootstrap", nboot = 40, boot_seed = 1)
  )
  expect_identical(ci_ct$method, "bootstrap")
  expect_true(ci_ct$conf.low < 36 && ci_ct$conf.high > 36)
})

test_that("a fixed group and a random intercept on CTmax coexist", {
  # CTmax ~ <fixed factor> + (1 | re_group): per-stage fixed CTmax plus a colony
  # random intercept (colonies nested in stage here).
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4,
                    re_sd = 1.2, n_re_groups = 12, seed = 3)
  d$life_stage <- ifelse(as.integer(factor(d$colony)) <= 6L, "A", "B")
  fit <- suppressWarnings(fit_tls(
    tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
           CTmax ~ life_stage + (1 | colony), log_z ~ life_stage),
    data = d, family = "binomial", tref = 1))
  expect_identical(fit$convergence$code, 0L)
  expect_false(is.null(fit$re))
  expect_identical(fit$re$n, 12L)
  expect_setequal(fit$group_levels, c("A", "B"))
  est <- fit$estimates
  expect_true(all(c("CTmax:A", "CTmax:B", "z:A", "z:B", "sigma_CTmax") %in%
                    est$parameter))
  expect_true(all(is.finite(est$estimate)))

  # Contrast profiling under a random effect is not supported (the contrast
  # refit would drop the random block); it errors rather than silently dropping.
  expect_error(suppressMessages(profile(fit, "dCTmax:A-B")), "random")
})
