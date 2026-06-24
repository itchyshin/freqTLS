# predict_survival_curves() — the bayesTLS-twin survival-surface predictor with
# parametric-bootstrap confidence bands.

test_that("predict_survival_curves gives an ordered survival surface; forward map matches the engine", {
  s <- standardize_data(simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1),
                        temp = "temp", duration = "duration",
                        n_total = "total", n_surv = "survived")
  f <- fit_4pl(s, t_ref = 1, family = "binomial", quiet = TRUE)
  pc <- suppressWarnings(predict_survival_curves(
    f, temps = c(33, 36, 39), durations = c(0.5, 1, 2, 4), nboot = 40, seed = 1))
  expect_s3_class(pc, "freq_surv_curves")
  sm <- pc$summary
  expect_true(all(c("temp", "duration", "survival_lower", "survival_median",
                    "survival_upper") %in% names(sm)))
  expect_true(all(sm$survival_median >= 0 & sm$survival_median <= 1))
  expect_true(all(sm$survival_lower <= sm$survival_median + 1e-9 &
                  sm$survival_median <= sm$survival_upper + 1e-9))

  # The internal forward 4PL must equal the engine's predict() at the MLE.
  e <- f$fit$estimates; g <- function(p) e$estimate[e$parameter == p]
  tref <- f$fit$tref
  fwd <- function(temp, dur) g("low") + (g("up") - g("low")) /
    (1 + exp(g("k") * (log10(dur) - (log10(tref) - (temp - g("CTmax")) / g("z")))))
  ss <- predict_survival_surface(f$fit, temps = c(33, 36, 39), times = c(0.5, 1, 2, 4))
  expect_equal(ss$survival, mapply(fwd, ss$temp, ss$duration), tolerance = 1e-8)
})

test_that("predict_survival_curves groups by the moderator", {
  d <- simulate_tls(family = "binomial", group = c("A", "B"),
                    CTmax = c(34, 38), z = c(3, 5), seed = 3)
  s <- standardize_data(d, temp = "temp", duration = "duration",
                        n_total = "total", n_surv = "survived")
  f <- suppressWarnings(fit_4pl(s, ctmax = ~ 0 + group, z = ~ 0 + group,
                                t_ref = 1, family = "binomial", quiet = TRUE))
  pc <- suppressWarnings(predict_survival_curves(
    f, temps = c(34, 38), durations = c(1, 4), nboot = 30, seed = 1))
  expect_true("group" %in% names(pc$summary))
  expect_setequal(unique(pc$summary$group), c("A", "B"))
})
