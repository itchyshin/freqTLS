# Recovery and model-selection tests for the beta-binomial 4PL fit. SPEC.md S11:
# recover (wider tolerances); on overdispersed data the beta-binomial must beat
# the binomial on logLik and AIC; on clean data it collapses to near-binomial.
# Fast: a handful of fits at fixed seeds.

test_that("beta-binomial fit recovers the simulating truth (wider tolerances)", {
  d <- simulate_tls(family = "beta_binomial", CTmax = 36, z = 4, phi = 15,
                    seed = 3)
  truth <- attr(d, "truth")
  fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
                 family = "beta_binomial", tref = 1)

  expect_identical(fit$convergence$code, 0L)
  expect_true(isTRUE(fit$convergence$pdHess))

  est <- stats::setNames(fit$estimates$estimate, fit$estimates$parameter)

  # Wider than the binomial test: overdispersion inflates uncertainty.
  expect_lt(abs(est[["CTmax"]] - truth$CTmax), 0.6)
  expect_lt(abs(est[["z"]] - truth$z), 1.0)
  expect_lt(abs(est[["low"]] - truth$low), 0.05)
  expect_lt(abs(est[["up"]] - truth$up), 0.05)
  # phi is hard to pin down; check it is positive and within an order of
  # magnitude of the truth (on the log scale).
  expect_true(est[["phi"]] > 0)
  expect_lt(abs(log(est[["phi"]]) - log(truth$phi)), 1.0)
})

test_that("beta-binomial beats binomial on overdispersed data (logLik and AIC)", {
  d <- simulate_tls(family = "beta_binomial", CTmax = 36, z = 4, phi = 8,
                    seed = 10)
  bb <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
                family = "beta_binomial", tref = 1)
  binom <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
                   family = "binomial", tref = 1)

  expect_identical(bb$convergence$code, 0L)
  expect_identical(binom$convergence$code, 0L)

  # The richer family fits strictly better and is preferred by AIC.
  expect_gt(as.numeric(logLik(bb)), as.numeric(logLik(binom)))
  expect_lt(AIC(bb), AIC(binom))
})

test_that("beta-binomial collapses to near-binomial on clean (binomial) data", {
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 11)
  # On truly binomial data phi runs to the binomial limit and is weakly
  # identified, so fit_tls() flags it (asserted in test-beta-binomial-phi.R); quiet here.
  bb <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
                family = "beta_binomial", tref = 1, quiet = TRUE)
  binom <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
                   family = "binomial", tref = 1)

  # phi heads toward the binomial limit (very large) on truly binomial data.
  phi_hat <- bb$estimates$estimate[bb$estimates$parameter == "phi"]
  expect_gt(phi_hat, 1000)

  # The two log-likelihoods are essentially identical; AIC favours the simpler
  # binomial because the extra phi is not earning its penalty.
  expect_lt(abs(as.numeric(logLik(bb)) - as.numeric(logLik(binom))), 0.01)
  expect_lt(AIC(binom), AIC(bb))
})
