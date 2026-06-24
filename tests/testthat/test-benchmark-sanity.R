# Benchmark sanity tripwire (SPEC.md S11/S12, R-STALE).
#
# This is a guard, not a coverage study: when the maintainer-built bayesTLS
# benchmark cache is present, it checks that a LIVE freqTLS point estimate
# lands within a loose tolerance of the cached bayesTLS posterior median for the
# same dataset and the same (relative-threshold, constant-shape, tref = 1 hour)
# configuration. The tolerances are deliberately wide (CTmax within ~1 C, z
# within ~25%) -- a likelihood point estimate and a Bayesian posterior median on
# the same model and data should agree at this level; a larger gap signals a
# config mismatch or cache drift, not a method difference.
#
# Stan and bayesTLS are NOT available in CI, so the cache rds is absent there and
# this whole file SKIPS. It only runs on a maintainer machine after
# data-raw/build_benchmark_cache.R has produced the cache.

cache_path <- system.file("extdata", "bayesTLS_benchmark_cache.rds",
                          package = "freqTLS")

# Fit freqTLS live on a (sub)dataset and return CTmax + z point estimates.
profile_tls_points <- function(df) {
  fit <- suppressWarnings(
    fit_tls(df, y = survived, n = total, time = duration, temp = temp,
            family = "beta_binomial", tref = 1)
  )
  ct <- get_ctmax(fit, conf.int = FALSE)
  z  <- get_z(fit, conf.int = FALSE)
  list(CTmax = ct$estimate[1], z = z$estimate[1])
}

test_that("live freqTLS point estimates match the cached bayesTLS medians", {
  skip_if_not(file.exists(cache_path) && nzchar(cache_path),
              "bayesTLS benchmark cache absent (needs Stan + bayesTLS to build)")

  cache <- readRDS(cache_path)
  expect_true(all(c("meta", "bayesian", "two_stage") %in% names(cache)))
  bayes <- cache$bayesian

  data("shrimp_lethal", package = "freqTLS", envir = environment())
  data("zebrafish_lethal", package = "freqTLS", envir = environment())

  # ---- shrimp (ungrouped) -------------------------------------------------
  sp <- profile_tls_points(shrimp_lethal)
  b_sh_ct <- bayes$median[bayes$dataset == "shrimp" & bayes$parameter == "CTmax"]
  b_sh_z  <- bayes$median[bayes$dataset == "shrimp" & bayes$parameter == "z"]
  if (length(b_sh_ct) == 1L && is.finite(b_sh_ct)) {
    expect_lt(abs(sp$CTmax - b_sh_ct), 1)          # CTmax within ~1 C
  }
  if (length(b_sh_z) == 1L && is.finite(b_sh_z)) {
    expect_lt(abs(sp$z - b_sh_z) / b_sh_z, 0.25)   # z within ~25%
  }

  # ---- zebrafish (per life stage) -----------------------------------------
  for (st in levels(zebrafish_lethal$life_stage)) {
    sub <- zebrafish_lethal[zebrafish_lethal$life_stage == st, , drop = FALSE]
    label <- paste0("zebrafish:", st)
    bp_ct <- bayes$median[bayes$dataset == label & bayes$parameter == "CTmax"]
    bp_z  <- bayes$median[bayes$dataset == label & bayes$parameter == "z"]
    if (length(bp_ct) != 1L || !is.finite(bp_ct)) next
    pp <- profile_tls_points(sub)
    expect_lt(abs(pp$CTmax - bp_ct), 1)
    if (length(bp_z) == 1L && is.finite(bp_z)) {
      expect_lt(abs(pp$z - bp_z) / bp_z, 0.25)
    }
  }
})
