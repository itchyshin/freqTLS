# Parametric bootstrap confidence intervals (R/bootstrap.R) and the
# auto-fallback wired into confint() (R/confint.R).

fit_boot_binom <- function(seed = 101) {
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = seed)
  suppressWarnings(fit_tls(d, y = survived, n = total, time = duration,
                           temp = temp, family = "binomial", tref = 1))
}

sparse_fit <- function(seed = 9) {
  ds <- simulate_tls(family = "binomial", temps = c(35, 36), times = c(1, 2),
                     reps = 2, n = 10, CTmax = 36, z = 4, seed = seed)
  suppressWarnings(fit_tls(ds, y = survived, n = total, time = duration,
                           temp = temp, family = "binomial", tref = 1))
}

test_that("method = 'bootstrap' returns a finite percentile interval around the estimate", {
  fit <- fit_boot_binom()
  ci <- suppressMessages(
    confint(fit, "CTmax", method = "bootstrap", nboot = 200L, boot_seed = 1L)
  )
  expect_s3_class(ci, "tbl_df")
  expect_identical(
    names(ci),
    c("parameter", "conf.low", "conf.high", "estimate", "level", "method",
      "scale", "conf.status")
  )
  expect_identical(ci$method, "bootstrap")
  expect_identical(ci$conf.status, "bootstrap")
  expect_true(is.finite(ci$conf.low) && is.finite(ci$conf.high))
  expect_true(ci$conf.low <= ci$estimate && ci$estimate <= ci$conf.high)
})

test_that("the bootstrap is reproducible with boot_seed and leaves the RNG untouched", {
  fit <- fit_boot_binom()
  set.seed(999)
  before <- .Random.seed
  a <- suppressMessages(
    confint(fit, c("CTmax", "z"), method = "bootstrap", nboot = 200L, boot_seed = 42L)
  )
  b <- suppressMessages(
    confint(fit, c("CTmax", "z"), method = "bootstrap", nboot = 200L, boot_seed = 42L)
  )
  expect_equal(a$conf.low, b$conf.low)
  expect_equal(a$conf.high, b$conf.high)
  # The caller's RNG stream is restored (boot_seed sets the seed locally).
  expect_identical(.Random.seed, before)
})

test_that("bootstrap percentile intervals are exactly equivariant: z == exp(log_z)", {
  fit <- fit_boot_binom()
  cz <- suppressMessages(
    confint(fit, "z", method = "bootstrap", nboot = 300L, boot_seed = 7L)
  )
  clz <- suppressMessages(
    confint(fit, "log_z", method = "bootstrap", nboot = 300L, boot_seed = 7L)
  )
  expect_equal(cz$conf.low, exp(clz$conf.low), tolerance = 1e-10)
  expect_equal(cz$conf.high, exp(clz$conf.high), tolerance = 1e-10)
})

test_that("the bootstrap CTmax interval covers the simulating truth", {
  fit <- fit_boot_binom(seed = 202)
  ci <- suppressMessages(
    confint(fit, "CTmax", method = "bootstrap", nboot = 400L, boot_seed = 3L)
  )
  expect_true(ci$conf.low <= 36 && 36 <= ci$conf.high)
})

test_that("a non-closing profile auto-falls back to a finite bootstrap interval", {
  fs <- sparse_fit()
  expect_message(
    suppressWarnings(
      confint(fs, "z", method = "profile", nboot = 200L, boot_seed = 5L)
    ),
    "parametric bootstrap"
  )
  ci <- suppressWarnings(suppressMessages(
    confint(fs, "z", method = "profile", nboot = 200L, boot_seed = 5L)
  ))
  expect_identical(ci$method, "bootstrap")
  expect_identical(ci$conf.status, "bootstrap")
  expect_true(is.finite(ci$conf.low) && is.finite(ci$conf.high))
})

test_that("fallback = FALSE keeps the strict profile NA on a non-closing side", {
  fs <- sparse_fit()
  ci <- suppressWarnings(
    confint(fs, "z", method = "profile", fallback = FALSE)
  )
  expect_true(is.na(ci$conf.low) || is.na(ci$conf.high))
  expect_match(ci$conf.status, "open")
})

test_that("bootstrap works per group on a grouped fit", {
  d <- simulate_tls(group = c("A", "B"), CTmax = c(35, 38), z = c(4, 3),
                    family = "binomial", seed = 11)
  fg <- suppressWarnings(fit_tls(d, y = survived, n = total, time = duration,
                                 temp = temp, group = group,
                                 family = "binomial", tref = 1))
  ci <- suppressMessages(
    confint(fg, c("CTmax:A", "CTmax:B"), method = "bootstrap",
            nboot = 200L, boot_seed = 2L)
  )
  expect_identical(nrow(ci), 2L)
  expect_true(all(is.finite(ci$conf.low)) && all(is.finite(ci$conf.high)))
  # The per-group point estimates are ordered A < B (truth 35 < 38).
  expect_lt(ci$estimate[ci$parameter == "CTmax:A"],
            ci$estimate[ci$parameter == "CTmax:B"])
})

test_that("beta-binomial bootstrap draws and refits without error", {
  d <- simulate_tls(family = "beta_binomial", phi = 50, CTmax = 36, z = 4,
                    seed = 13)
  fit <- suppressWarnings(fit_tls(d, y = survived, n = total, time = duration,
                                  temp = temp, family = "beta_binomial", tref = 1))
  ci <- suppressMessages(
    confint(fit, "CTmax", method = "bootstrap", nboot = 200L, boot_seed = 4L)
  )
  expect_true(is.finite(ci$conf.low) && is.finite(ci$conf.high))
  expect_true(ci$conf.low <= ci$estimate && ci$estimate <= ci$conf.high)
})

test_that("multicore bootstrap matches single-core for the same seed", {
  fit <- fit_boot_binom()
  one <- suppressMessages(confint(fit, c("CTmax", "z"), method = "bootstrap",
                                  nboot = 200L, boot_seed = 8L, cores = 1L))
  two <- suppressMessages(confint(fit, c("CTmax", "z"), method = "bootstrap",
                                  nboot = 200L, boot_seed = 8L, cores = 2L))
  # Responses are pre-drawn under the seed and refits are deterministic, so the
  # interval is identical regardless of cores (forking on Unix; sequential on
  # Windows, which still matches).
  expect_equal(one$conf.low, two$conf.low)
  expect_equal(one$conf.high, two$conf.high)
})
