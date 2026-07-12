# Prediction tests (SPEC.md S11, test-predict). Survival is strictly
# decreasing with duration at fixed temperature and with temperature at fixed
# duration; the newdata path returns probabilities in (0, 1) with the right
# length; type = "midpoint" equals log10(tref) at temp = CTmax; and derive_lt
# round-trips against predict(). One fixed-seed fit keeps the suite fast.

fit_binom <- function(seed = 1) {
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = seed)
  suppressWarnings(
    fit_tls(d, y = survived, n = total, time = duration, temp = temp,
            family = "binomial", tref = 1)
  )
}

test_that("survival decreases with duration at a fixed temperature", {
  fit <- fit_binom()
  s <- predict(fit, data.frame(temp = 36, duration = c(0.5, 1, 2, 4, 8)),
               type = "survival")
  expect_true(all(diff(s) <= 1e-8))
  expect_true(all(s > 0 & s < 1))
})

test_that("survival decreases with temperature at a fixed duration", {
  fit <- fit_binom()
  s <- predict(fit, data.frame(temp = c(32, 34, 36, 38, 40), duration = 2),
               type = "survival")
  expect_true(all(diff(s) <= 1e-8))
  expect_true(all(s > 0 & s < 1))
})

test_that("the newdata path returns probabilities in (0, 1) of the right length", {
  fit <- fit_binom()
  nd <- expand.grid(temp = c(34, 36, 38), duration = c(1, 2, 4))
  ps <- predict(fit, nd, type = "survival")
  expect_length(ps, nrow(nd))
  expect_true(all(ps > 0 & ps < 1))
})

test_that("type = 'link' is the logit of the survival prediction", {
  fit <- fit_binom()
  nd <- expand.grid(temp = c(34, 36, 38), duration = c(1, 2, 4))
  surv <- predict(fit, nd, type = "survival")
  link <- predict(fit, nd, type = "link")
  expect_equal(link, stats::qlogis(surv), tolerance = 1e-10)
})

test_that("midpoint equals log10(tref) at temp = CTmax", {
  fit <- fit_binom()
  ctmax <- fit$estimates$estimate[fit$estimates$parameter == "CTmax"]
  for (tref in c(1, 2)) {
    d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 2)
    f <- suppressWarnings(
      fit_tls(d, y = survived, n = total, time = duration, temp = temp,
              family = "binomial", tref = tref)
    )
    ct <- f$estimates$estimate[f$estimates$parameter == "CTmax"]
    mid <- predict(f, data.frame(temp = ct, duration = 1), type = "midpoint")
    expect_equal(mid, log10(tref), tolerance = 1e-8)
  }
})

test_that("midpoint ignores duration (constant within a temperature)", {
  fit <- fit_binom()
  m1 <- predict(fit, data.frame(temp = 36, duration = 1), type = "midpoint")
  m2 <- predict(fit, data.frame(temp = 36, duration = 99), type = "midpoint")
  expect_equal(m1, m2)
  # duration column may be omitted for the midpoint type.
  m3 <- predict(fit, data.frame(temp = 36), type = "midpoint")
  expect_equal(m1, m3)
})

test_that("derive_lt round-trips: survival at the derived duration equals p", {
  fit <- fit_binom()
  for (p in c(0.25, 0.5, 0.75)) {
    for (tt in c(34, 36, 38)) {
      lt <- derive_lt(fit, p = p, temp = tt)
      expect_true(is.finite(lt) && lt > 0)
      s_back <- predict(fit, data.frame(temp = tt, duration = lt),
                        type = "survival")
      expect_equal(s_back, p, tolerance = 1e-6)
    }
  }
})

test_that("derive_lt(p = 0.5) sits at the 4PL midpoint (log10(duration) = mid)", {
  fit <- fit_binom()
  shape <- fit$estimates
  # At the relative midpoint p = (low + up)/2 the crossing is exactly at the
  # midpoint duration; p = 0.5 is the default relative target.
  low <- shape$estimate[shape$parameter == "low"]
  up <- shape$estimate[shape$parameter == "up"]
  pmid <- (low + up) / 2
  lt <- derive_lt(fit, p = pmid, temp = 36)
  mid <- predict(fit, data.frame(temp = 36), type = "midpoint")
  expect_equal(log10(lt), mid, tolerance = 1e-8)
})

test_that("derive_lt aborts when the target is outside the asymptotes", {
  fit <- fit_binom()
  # low ~ 0.02, up ~ 0.98 for this DGP; 0.999 is above up.
  expect_error(derive_lt(fit, p = 0.999, temp = 36), "asymptotes|crosses")
})

test_that("predict_survival_surface returns a long survival grid in (0, 1)", {
  fit <- fit_binom()
  surf <- predict_survival_surface(fit, temps = c(34, 36, 38),
                                   times = c(1, 2, 4))
  expect_identical(names(surf), c("temp", "duration", "survival"))
  expect_equal(nrow(surf), 9L)
  expect_true(all(surf$survival > 0 & surf$survival < 1))
})

test_that("predict validates newdata columns and duration positivity", {
  fit <- fit_binom()
  expect_error(predict(fit, data.frame(temp = 36), type = "survival"),
               "duration")
  expect_error(
    predict(fit, data.frame(temp = 36, duration = -1), type = "survival"),
    "positive"
  )
})

test_that("grouped predict resolves per-group CTmax/z and needs a group column", {
  d <- simulate_tls(family = "binomial", group = c("A", "B"),
                    CTmax = c(34, 38), z = c(3, 5), seed = 3)
  fit <- suppressWarnings(
    fit_tls(d, y = survived, n = total, time = duration, temp = temp,
            group = group, family = "binomial", tref = 1)
  )
  # A grouped fit demands a group column.
  expect_error(
    predict(fit, data.frame(temp = 36, duration = 2), type = "survival"),
    "group"
  )
  # The hotter-CTmax group survives longer at the same temp/duration.
  s_A <- predict(fit, data.frame(temp = 36, duration = 2, group = "A"),
                 type = "survival")
  s_B <- predict(fit, data.frame(temp = 36, duration = 2, group = "B"),
                 type = "survival")
  expect_gt(s_B, s_A)
})

test_that("predict rebuilds a matching continuous CTmax/log_z fixed design", {
  set.seed(91)
  d <- expand.grid(temp = c(34, 36, 38), duration = c(0.5, 1, 2, 4),
                   x = seq(-1, 1, length.out = 7))
  CTmax <- 36 + 0.7 * d$x
  log_z <- log(4) - 0.15 * d$x
  mid <- -(d$temp - CTmax) / exp(log_z)
  prob <- 0.02 + 0.96 * stats::plogis(-4 * (log10(d$duration) - mid))
  d$total <- 50
  d$survived <- stats::rbinom(nrow(d), d$total, prob)
  fit <- suppressWarnings(fit_tls(
    tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
           CTmax ~ x, log_z ~ x),
    data = d, family = "binomial", tref = 1
  ))

  nd <- data.frame(temp = 37, duration = 2, x = c(-1, 0, 1))
  got <- predict(fit, nd)
  Xn <- stats::model.matrix(~x, nd)
  ct <- as.numeric(Xn %*% unname(fit$par[names(fit$par) == "beta_CT"]))
  z <- exp(as.numeric(Xn %*% unname(fit$par[names(fit$par) == "beta_logz"])))
  low <- fit$estimates$estimate[fit$estimates$parameter == "low"]
  up <- fit$estimates$estimate[fit$estimates$parameter == "up"]
  k <- fit$estimates$estimate[fit$estimates$parameter == "k"]
  mid <- -(nd$temp - ct) / z
  expected <- low + (up - low) * stats::plogis(-k * (log10(nd$duration) - mid))

  expect_equal(got, expected, tolerance = 1e-10)
  expect_gt(length(unique(round(got, 10))), 1L)
})

test_that("random-effect prediction distinguishes population and conditional values", {
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4,
                    re_sd = 1.5, n_re_groups = 10, seed = 42)
  fit <- suppressWarnings(fit_tls(
    tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
           CTmax ~ 1 + (1 | colony)),
    data = d, family = "binomial", tref = 1
  ))
  lev <- ranef(fit)$group[which.max(abs(ranef(fit)$estimate))]
  nd <- data.frame(temp = 36, duration = 2, colony = lev)

  population <- predict(fit, nd, re.form = "population")
  conditional <- predict(fit, nd, re.form = "conditional")
  expect_false(isTRUE(all.equal(population, conditional)))
  expect_warning(default <- predict(fit, nd), "population prediction")
  expect_equal(default, population)
  expect_error(
    predict(fit, data.frame(temp = 36, duration = 2),
            re.form = "conditional"),
    "grouping column.*colony"
  )
  expect_error(
    predict(fit, data.frame(temp = 36, duration = 2, colony = "new-colony"),
            re.form = "conditional"),
    "unseen.*colony"
  )
})

test_that("derive_ctmax inverts the curve and defaults to CTmax", {
  fit <- fit_binom()
  ct <- fit$estimates$estimate[fit$estimates$parameter == "CTmax"]
  # Default (relative midpoint at tref) reproduces CTmax.
  expect_equal(derive_ctmax(fit), ct, tolerance = 1e-6)
  # Round-trip: predict at the derived temperature returns the target survival.
  for (s in c(0.3, 0.6)) {
    for (dd in c(1, 4)) {
      tt <- derive_ctmax(fit, surv = s, duration = dd)
      back <- predict(fit, data.frame(temp = tt, duration = dd), type = "survival")
      expect_equal(back, s, tolerance = 1e-6)
    }
  }
  # Vectorised over duration; out-of-range target errors.
  expect_length(derive_ctmax(fit, surv = 0.5, duration = c(1, 2, 4)), 3L)
  expect_error(derive_ctmax(fit, surv = 1.5), "between the fitted asymptotes")
})

test_that("derive_ctmax resolves per group", {
  dg <- simulate_tls(group = c("A", "B"), CTmax = c(35, 38), z = c(4, 3),
                     family = "binomial", seed = 2)
  fg <- suppressWarnings(fit_tls(dg, y = survived, n = total, time = duration,
                                 temp = temp, group = group, family = "binomial",
                                 tref = 1))
  expect_lt(derive_ctmax(fg, group = "A"), derive_ctmax(fg, group = "B"))
})

test_that("derive_tcrit = CTmax + z*log10(rate/100) and reduces to CTmax at rate 100", {
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
  fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
                 family = "binomial", tref = 1)
  est <- stats::setNames(fit$estimates$estimate, fit$estimates$parameter)
  ctmax <- unname(est[["CTmax"]])
  z <- unname(est[["z"]])
  # rate = 100% of the lethal dose per hour -> log10(1) = 0 -> T_crit == CTmax.
  expect_equal(suppressMessages(derive_tcrit(fit, rate = 100)), ctmax,
               tolerance = 1e-8)
  expect_equal(suppressMessages(derive_tcrit(fit, rate = 1)),
               ctmax + z * log10(1 / 100), tolerance = 1e-8)
  # Below CTmax for a sub-100 rate, and monotone increasing in rate.
  tc <- suppressMessages(derive_tcrit(fit, rate = c(0.1, 1, 10)))
  expect_length(tc, 3L)
  expect_true(all(tc < ctmax))
  expect_true(all(diff(tc) > 0))
})

test_that("derive_tcrit resolves per group and validates the rate", {
  dg <- simulate_tls(group = c("A", "B"), CTmax = c(34, 38), z = c(3, 5),
                     family = "binomial", seed = 2)
  fg <- suppressWarnings(fit_tls(dg, y = survived, n = total, time = duration,
                                 temp = temp, group = group, family = "binomial",
                                 tref = 1))
  expect_lt(suppressMessages(derive_tcrit(fg, rate = 1, group = "A")),
            suppressMessages(derive_tcrit(fg, rate = 1, group = "B")))
  expect_error(derive_tcrit(fg, rate = 0, group = "A"), "positive")
})

test_that("derive_tcrit flags the lethal-endpoint assumption", {
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
  fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
                 family = "binomial", tref = 1)
  expect_message(derive_tcrit(fit, rate = 1), "lethal")
})
