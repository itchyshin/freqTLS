# Benchmark sanity tripwire (SPEC.md S11/S12, R-STALE).
#
# This is a guard, not a coverage study: when the maintainer-built bayesTLS
# benchmark cache is present, it checks that a LIVE freqTLS point estimate
# lands within a loose tolerance of the cached bayesTLS posterior median for the
# same dataset and the same (relative-threshold, constant-shape, tref = 60 min)
# configuration. The tolerances are deliberately wide (CTmax within ~1 C, z
# within ~25%) -- a likelihood point estimate and a Bayesian posterior median on
# the same model and data should agree at this level; a larger gap signals a
# config mismatch or cache drift, not a method difference.
#
# Stan and bayesTLS are not required in CI: tests read the installed maintainer
# cache and fit freqTLS live. The cache-presence guard remains for deliberately
# stripped installations.

cache_path <- system.file("extdata", "bayesTLS_benchmark_cache.rds",
                          package = "freqTLS")

# Fit freqTLS live on standardised data and return CTmax + z point estimates.
profile_tls_points <- function(data) {
  fit <- suppressWarnings(
    fit_4pl(data, family = "beta_binomial", t_ref = 60, quiet = TRUE)
  )
  ct <- get_ctmax(fit, conf.int = FALSE)
  z  <- get_z(fit, conf.int = FALSE)
  list(CTmax = ct$estimate[1], z = z$estimate[1])
}

test_that("live freqTLS point estimates match the cached bayesTLS medians", {
  skip_if_not(file.exists(cache_path) && nzchar(cache_path),
              "bayesTLS benchmark cache absent from this stripped installation")

  cache <- readRDS(cache_path)
  expect_true(all(c("meta", "bayesian", "two_stage") %in% names(cache)))
  expect_match(cache$meta$git_sha, "^[0-9a-f]{40}$")
  expect_identical(grepl(cache$meta$git_sha, cache$meta$source_url, fixed = TRUE),
                   TRUE)
  expect_identical(cache$meta$config$target_surv, "relative")
  expect_identical(cache$meta$config$temp_effects, "mid")
  expect_match(cache$meta$freqTLS_note, "absolute LT50", fixed = TRUE)
  expect_match(cache$meta$freqTLS_note, "approximate comparator", fixed = TRUE)
  expect_match(cache$meta$rshrimp_note, "installed shrimp_lethal help topic",
               fixed = TRUE)
  expect_false(grepl("docs/design", cache$meta$rshrimp_note, fixed = TRUE))
  expect_setequal(names(cache$meta$datasets),
                  c("shrimp", "zebrafish", "dsuzukii"))
  expect_identical(any(grepl("snowgum", capture.output(str(cache)),
                              ignore.case = TRUE)), FALSE)
  bayes <- cache$bayesian
  expect_setequal(
    unique(sub(":.*$", "", bayes$dataset)),
    c("shrimp", "zebrafish", "dsuzukii")
  )

  data("shrimp_lethal", package = "freqTLS", envir = environment())
  data("zebrafish_lethal", package = "freqTLS", envir = environment())

  # ---- shrimp (ungrouped) -------------------------------------------------
  shrimp <- standardize_data(
    shrimp_lethal,
    temp = "Temperature_assay",
    duration = "Duration_exposure_hours",
    n_total = "N_individuals_after_trial",
    mortality = "Mortality_after_trial",
    duration_unit = "hours"
  )
  sp <- profile_tls_points(shrimp)
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
    sub <- standardize_data(
      sub,
      temp = "assay_temp",
      duration = "duration_h",
      n_total = "n_total",
      n_surv = "n_surv",
      duration_unit = "hours"
    )
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
