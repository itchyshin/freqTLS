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

test_that("tls() also accepts a bare profile_tls fit and rejects absolute for now", {
  f4 <- fit_4pl(std_sim(seed = 6), t_ref = 1, family = "binomial", quiet = TRUE)
  expect_s3_class(tls(f4$fit, method = "wald"), "tls")     # bare engine fit
  expect_error(tls(f4, target_surv = "absolute"), "relative")
})
