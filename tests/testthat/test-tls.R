# tls() — the bayesTLS-twin quantity extractor (z, CTmax with CIs).

std_sim <- function(seed = 1, ...) {
  standardize_data(simulate_tls(family = "binomial", seed = seed, ...),
                   temp = "temp", duration = "duration",
                   n_total = "total", n_surv = "survived")
}

test_that("tls() returns z and CTmax with confidence intervals (ungrouped)", {
  f <- fit_4pl(std_sim(seed = 1, CTmax = 36, z = 4), t_ref = 1,
               family = "binomial", quiet = TRUE)
  r <- tls(f, method = "wald")
  expect_s3_class(r, "tls")
  expect_setequal(r$summary$quantity, c("z", "CTmax"))
  expect_true(all(c("quantity", "median", "lower", "upper") %in% names(r$summary)))
  expect_true(all(r$summary$lower <= r$summary$median &
                  r$summary$median <= r$summary$upper))
  ct <- r$summary[r$summary$quantity == "CTmax", ]
  expect_equal(ct$median, 36, tolerance = 0.3)
  expect_identical(r$meta$mode, "relative")
})

test_that("tls() groups by the moderator with clean factor-level labels", {
  d <- simulate_tls(family = "binomial", group = c("A", "B"),
                    CTmax = c(34, 38), z = c(3, 5), seed = 3)
  s <- standardize_data(d, temp = "temp", duration = "duration",
                        n_total = "total", n_surv = "survived")
  f <- suppressWarnings(fit_4pl(s, ctmax = ~ 0 + group, z = ~ 0 + group,
                                t_ref = 1, family = "binomial", quiet = TRUE))
  r <- tls(f, method = "wald")
  expect_true("group" %in% names(r$summary))
  expect_setequal(unique(r$summary$group), c("A", "B"))   # not "groupA"/"groupB"
  expect_equal(nrow(r$summary), 4L)                       # 2 groups x {z, CTmax}
  # CTmax recovers the per-group truth
  ctA <- r$summary$median[r$summary$group == "A" & r$summary$quantity == "CTmax"]
  expect_equal(ctA, 34, tolerance = 0.5)
})

test_that("tls_z / tls_ctmax select a single quantity", {
  f <- fit_4pl(std_sim(seed = 5), t_ref = 1, family = "binomial", quiet = TRUE)
  expect_setequal(tls_z(f, method = "wald")$summary$quantity, "z")
  expect_setequal(tls_ctmax(f, method = "wald")$summary$quantity, "CTmax")
})

test_that("tls() accepts a bare profile_tls fit; absolute delegates to the bootstrap path", {
  f4 <- fit_4pl(std_sim(seed = 6), t_ref = 1, family = "binomial", quiet = TRUE)
  expect_s3_class(tls(f4$fit, method = "wald"), "tls")     # bare engine fit
  ra <- suppressWarnings(tls(f4, target_surv = "absolute", nboot = 40, seed = 1))
  expect_s3_class(ra, "tls")
  expect_match(ra$meta$mode, "p=0.500")
  expect_identical(ra$meta$method, "bootstrap")
})

test_that("diagnose_tdt_fit reports a one-row convergence summary", {
  f <- fit_4pl(std_sim(seed = 7), t_ref = 1, family = "binomial", quiet = TRUE)
  d <- diagnose_tdt_fit(f)
  expect_equal(nrow(d), 1L)
  expect_true(all(c("converged", "pd_hessian", "max_abs_gradient",
                    "gradient_pass", "all_pass") %in% names(d)))
  expect_true(d$converged)
  expect_true(d$pd_hessian)
  expect_true(d$all_pass)
})

test_that("tdt_parameter_table returns the bayesTLS parameter/median/lower/upper shape", {
  f <- fit_4pl(std_sim(seed = 8), t_ref = 1, family = "binomial", quiet = TRUE)
  pt <- tdt_parameter_table(f, method = "wald")
  expect_setequal(names(pt), c("parameter", "group", "median", "lower", "upper"))
  expect_true(all(c("low", "up", "k", "CTmax", "z") %in% pt$parameter))
})

test_that("tls() delegates absolute / lethal to the bootstrap path", {
  d <- simulate_tls(family = "binomial", group = c("A", "B"),
                    CTmax = c(34, 38), z = c(3, 5), seed = 3)
  s <- standardize_data(d, temp = "temp", duration = "duration",
                        n_total = "total", n_surv = "survived")
  f <- suppressWarnings(fit_4pl(s, ctmax = ~ 0 + group, z = ~ 0 + group,
                                t_ref = 1, family = "binomial", quiet = TRUE))
  r <- suppressWarnings(tls(f, lethal = TRUE, nboot = 49, seed = 1))
  expect_true(all(c("z", "CTmax", "Tcrit") %in% r$summary$quantity))
  expect_identical(r$meta$method, "bootstrap")
  expect_true("group" %in% names(r$summary))
  rt <- suppressWarnings(tls_tcrit(f, nboot = 49, seed = 1))
  expect_setequal(rt$summary$quantity, "Tcrit")
})
