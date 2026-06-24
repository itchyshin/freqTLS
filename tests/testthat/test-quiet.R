# Tests for the `quiet` argument.
#
# `quiet` silences freqTLS's OWN diagnostics (the few-groups random-effects
# advisory and the same-grouping independent-variance warning) without changing
# the fitted object. The default (`quiet = FALSE`) keeps every signal visible to
# interactive users; `quiet = TRUE` is the deliberate opt-in for simulation loops
# and clean vignette fits. It threads through the parser, so the same switch
# silences `tls_parse_formula()` when it is called directly.

test_that("the default surfaces the few-groups advisory; quiet = TRUE silences it", {
  skip_on_cran()
  bf <- tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
               CTmax ~ 1 + (1 | colony))
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4,
                    re_sd = 1.5, n_re_groups = 4, seed = 11)
  # quiet = FALSE (default): the advisory reaches the user.
  expect_warning(
    fit_tls(bf, data = d, family = "binomial", tref = 1),
    "fewer than|weakly identified"
  )
  # quiet = TRUE: silenced, and the fit is still a profile_tls object.
  fit_q <- expect_no_warning(
    fit_tls(bf, data = d, family = "binomial", tref = 1, quiet = TRUE)
  )
  expect_s3_class(fit_q, "profile_tls")
})

test_that("the few-groups advisory fires below ~8 groups, not at or above", {
  skip_on_cran()
  bf <- tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
               CTmax ~ 1 + (1 | colony))
  d_small <- simulate_tls(family = "binomial", CTmax = 36, z = 4,
                          re_sd = 1.5, n_re_groups = 5, seed = 1)
  d_big <- simulate_tls(family = "binomial", CTmax = 36, z = 4,
                        re_sd = 1.5, n_re_groups = 12, seed = 1)
  expect_warning(
    fit_tls(bf, data = d_small, family = "binomial", tref = 1),
    "fewer than"
  )
  expect_no_warning(
    fit_tls(bf, data = d_big, family = "binomial", tref = 1)
  )
})

test_that("quiet threads into the parser: tls_parse_formula(quiet = TRUE) is silent", {
  bf <- tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
               CTmax ~ 1 + (1 | colony))
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4,
                    re_sd = 1.5, n_re_groups = 4, seed = 3)
  expect_warning(
    freqTLS:::tls_parse_formula(bf, d),
    "fewer than|weakly identified"
  )
  expect_no_warning(
    freqTLS:::tls_parse_formula(bf, d, quiet = TRUE)
  )
})
