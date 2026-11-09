# Argument validation, target resolution, and small-sample behaviour of the
# parametric bootstrap (R/bootstrap.R). The routing into confint() is covered
# by test-bootstrap.R; here the replicate engine and target resolver are tested
# directly with tiny nboot so the file stays fast.

be_fit <- function() {
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
  suppressWarnings(
    fit_tls(d, y = survived, n = total, time = duration, temp = temp,
            family = "binomial", tref = 1)
  )
}

be_grouped <- function() {
  d <- simulate_tls(family = "binomial", group = c("A", "B"),
                    CTmax = c(34, 38), z = c(3, 5), seed = 2)
  suppressWarnings(
    fit_tls(d, y = survived, n = total, time = duration, temp = temp,
            group = group, family = "binomial", tref = 1)
  )
}

test_that("tls_bootstrap_replicates validates the fit and its tuning arguments", {
  fit <- be_fit()
  expect_error(tls_bootstrap_replicates(list()), "profile_tls")
  no_obj <- fit
  no_obj$obj <- NULL
  expect_error(tls_bootstrap_replicates(no_obj, nboot = 2),
               "needs the live TMB object")
  expect_error(tls_bootstrap_replicates(fit, nboot = 0), "single positive integer")
  expect_error(tls_bootstrap_replicates(fit, nboot = c(2, 3)),
               "single positive integer")
  expect_error(tls_bootstrap_replicates(fit, nboot = "a"),
               "single positive integer")
  expect_error(tls_bootstrap_replicates(fit, nboot = 2, cores = 0),
               "single positive integer")
  expect_error(tls_bootstrap_replicates(fit, nboot = 2, cores = NA),
               "single positive integer")
  expect_error(tls_bootstrap_replicates(fit, nboot = 2, seed = "a"),
               "single number or")
  expect_error(tls_bootstrap_replicates(fit, nboot = 2, seed = c(1, 2)),
               "single number or")
})

test_that("tls_bootstrap_replicates is reproducible and restores the RNG state", {
  fit <- be_fit()
  set.seed(99)
  before <- get(".Random.seed", envir = .GlobalEnv)
  a <- tls_bootstrap_replicates(fit, nboot = 4, seed = 7)
  expect_identical(get(".Random.seed", envir = .GlobalEnv), before)
  b <- tls_bootstrap_replicates(fit, nboot = 4, seed = 7)
  expect_equal(a$replicates, b$replicates)
  expect_identical(a$nboot, 4L)
  expect_identical(colnames(a$replicates), fit$estimates$parameter)
  expect_equal(a$n_converged, sum(a$converged))
  expect_true(any(a$converged))
  c2 <- tls_bootstrap_replicates(fit, nboot = 4, seed = 8)
  expect_false(isTRUE(all.equal(a$replicates, c2$replicates)))
})

test_that("a seeded bootstrap leaves no .Random.seed behind when none existed", {
  fit <- be_fit()
  had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  old <- if (had_seed) get(".Random.seed", envir = .GlobalEnv)
  on.exit(if (had_seed) assign(".Random.seed", old, envir = .GlobalEnv),
          add = TRUE)
  rm(".Random.seed", envir = .GlobalEnv)
  res <- tls_bootstrap_replicates(fit, nboot = 2, seed = 3)
  expect_false(exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE))
  expect_identical(res$nboot, 2L)
})

test_that("bootstrap replicates cluster around the fitted values", {
  fit <- be_fit()
  est <- stats::setNames(fit$estimates$estimate, fit$estimates$parameter)
  rep <- tls_bootstrap_replicates(fit, nboot = 30, seed = 11)
  r <- rep$replicates[rep$converged, , drop = FALSE]
  expect_gte(nrow(r), 25L)
  se <- stats::setNames(fit$estimates$std.error, fit$estimates$parameter)
  # Mean of parametric-bootstrap CTmax / z within a few Wald SEs of the fit.
  expect_lt(abs(mean(r[, "CTmax"]) - est[["CTmax"]]), 3 * se[["CTmax"]])
  expect_lt(abs(mean(r[, "z"]) - est[["z"]]), 3 * se[["z"]])
  expect_gt(stats::sd(r[, "CTmax"]), 0)
})

test_that("a bootstrap with fewer than 20 usable replicates returns NA and warns", {
  fit <- be_fit()
  boot <- tls_bootstrap_replicates(fit, nboot = 5, seed = 1)
  expect_warning(
    out <- tls_confint_bootstrap(fit, "CTmax", level = 0.95, replicates = boot),
    "only [0-9]+ usable replicate"
  )
  expect_true(is.na(out$conf.low))
  expect_true(is.na(out$conf.high))
  expect_identical(out$conf.status, "bootstrap_unstable")
  expect_identical(out$method, "bootstrap")
  est <- fit$estimates$estimate[fit$estimates$parameter == "CTmax"]
  expect_equal(out$estimate, est)
})

test_that("bootstrap intervals bracket the estimate and respect the level", {
  fit <- be_fit()
  boot <- tls_bootstrap_replicates(fit, nboot = 40, seed = 2)
  b95 <- tls_confint_bootstrap(fit, c("CTmax", "z", "log_z", "low", "k"),
                               level = 0.95, replicates = boot)
  b50 <- tls_confint_bootstrap(fit, "CTmax", level = 0.5, replicates = boot)
  expect_identical(b95$conf.status, rep("bootstrap", 5L))
  expect_true(all(b95$conf.low < b95$conf.high))
  ct <- b95[b95$parameter == "CTmax", ]
  expect_lt(ct$conf.low, ct$estimate)
  expect_gt(ct$conf.high, ct$estimate)
  expect_lt(b50$conf.high - b50$conf.low, ct$conf.high - ct$conf.low)
  # log_z interval is the log of the z interval (equivariant percentile).
  z <- b95[b95$parameter == "z", ]
  lz <- b95[b95$parameter == "log_z", ]
  expect_equal(lz$conf.low, log(z$conf.low), tolerance = 1e-8)
  expect_equal(lz$conf.high, log(z$conf.high), tolerance = 1e-8)
})

test_that("bootstrap targets resolve grouped names and contrasts, and reject unknown ones", {
  fg <- be_grouped()
  boot <- tls_bootstrap_replicates(fg, nboot = 4, seed = 1)
  reps <- boot$replicates
  ct <- tls_boot_target("dCTmax:B-A", fg, reps)
  expect_equal(ct$values, reps[, "CTmax:B"] - reps[, "CTmax:A"])
  expect_equal(ct$scale, "identity")
  dz <- tls_boot_target("dz:B-A", fg, reps)
  expect_equal(dz$values, log(reps[, "z:B"]) - log(reps[, "z:A"]))
  expect_equal(dz$scale, "log")
  lz <- tls_boot_target("log_z:A", fg, reps)
  expect_equal(lz$values, log(reps[, "z:A"]))

  expect_error(tls_boot_target("dCTmax:A-Z", fg, reps), "must be levels of the fit")
  expect_error(tls_boot_target("dz:A-Z", fg, reps), "must be levels of the fit")
  expect_error(tls_boot_target("log_z:Z", fg, reps), "Unknown bootstrap target")
  expect_error(tls_boot_target("banana", fg, reps), "Unknown bootstrap target")
})

test_that("bootstrap replicates carry random-intercept variance components", {
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, low = 0.1, up = 0.98,
                    temps = seq(33, 39, by = 1.5), times = c(1, 2, 4, 8, 16),
                    reps = 3, n = 30, re_sd_low = 0.6, n_re_groups = 8,
                    seed = 101)
  fit <- suppressWarnings(fit_tls(
    tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
           low ~ 1 + (1 | colony)),
    data = d, family = "binomial", tref = 1))
  boot <- tls_bootstrap_replicates(fit, nboot = 3, seed = 5)
  expect_true("sigma_low" %in% colnames(boot$replicates))
  ok <- boot$replicates[boot$converged, "sigma_low"]
  expect_gt(length(ok), 0L)
  expect_true(all(is.finite(ok) & ok >= 0))
})

test_that("bootstrap replicates carry a log_k random-intercept variance component", {
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, k = 5,
                    temps = seq(33, 39, by = 1.5), times = c(1, 2, 4, 8, 16),
                    reps = 3, n = 30, re_sd_logk = 0.4, n_re_groups = 8,
                    seed = 202)
  fit <- suppressWarnings(fit_tls(
    tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
           log_k ~ 1 + (1 | colony)),
    data = d, family = "binomial", tref = 1))
  boot <- tls_bootstrap_replicates(fit, nboot = 3, seed = 5)
  expect_true("sigma_logk" %in% colnames(boot$replicates))
  ok <- boot$replicates[boot$converged, "sigma_logk"]
  expect_gt(length(ok), 0L)
  expect_true(all(is.finite(ok) & ok >= 0))
})
