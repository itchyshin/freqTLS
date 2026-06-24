# data-raw/performance-study.R
#
# Maintainer-run performance study for freqTLS.  No Stan, no bayesTLS.
# Measures speed, accuracy (bias/RMSE), and interval calibration (empirical
# coverage) for freqTLS's own estimator, and saves a compact summary to
# inst/extdata/performance_results.rds for use in vignettes and reports.
#
# Run with:  Rscript data-raw/performance-study.R
#
# ---------------------------------------------------------------------------
# Output: inst/extdata/performance_results.rds -- a list with
#   $meta      list(nsim, seeds, truth, date, note)
#   $speed     tibble(family, design, n_obs, median_fit_ms, median_profile_ms)
#   $accuracy  tibble(family, truth_setting, parameter, bias, rel_bias, rmse,
#                     n_converged)
#   $coverage  tibble(family, method, parameter, coverage, median_width,
#                     n_converged, nominal)
#
# phi convention (R-PHI): phi is the sum of the Beta shape parameters.
# Draws: prob <- rbeta(a = p * phi, b = (1-p) * phi), then rbinom(n, prob).
# Larger phi -> less overdispersion; phi -> Inf recovers the binomial.
# ---------------------------------------------------------------------------

suppressMessages(devtools::load_all(".", quiet = TRUE))

# ============================================================
# Helpers
# ============================================================

covers <- function(ci, target) {
  !is.null(ci) &&
    is.finite(ci$conf.low) && is.finite(ci$conf.high) &&
    ci$conf.low <= target && ci$conf.high >= target
}
ci_width <- function(ci) {
  if (!is.null(ci) && is.finite(ci$conf.low) && is.finite(ci$conf.high))
    ci$conf.high - ci$conf.low
  else NA_real_
}

# ============================================================
# 1. SPEED STUDY
# ============================================================
message("\n=== SPEED STUDY ===")

# Four designs that span a plausible sample-size range.
designs <- list(
  tiny   = list(n_temp = 4L, n_time = 3L, reps = 2L, n = 10L),
  small  = list(n_temp = 7L, n_time = 5L, reps = 3L, n = 20L),
  medium = list(n_temp = 9L, n_time = 7L, reps = 4L, n = 25L),
  large  = list(n_temp = 11L, n_time = 8L, reps = 5L, n = 30L)
)

SPEED_REPS    <- 5L   # repeats per design/family for median time
SPEED_SEED    <- 20260601L
TRUTH_SPEED   <- list(CTmax = 36, z = 4, low = 0.02, up = 0.98, k = 5)
SPEED_PROFILE_PARM <- "CTmax"  # profile CI for one parameter

speed_rows <- list()

for (fam in c("binomial", "beta_binomial")) {
  phi_val <- if (fam == "beta_binomial") 50 else NULL

  for (dname in names(designs)) {
    des <- designs[[dname]]
    temps_v <- seq(30, 42, length.out = des$n_temp)
    times_v  <- 2^seq(-1, des$n_time - 2, length.out = des$n_time)

    # Generate one dataset for this design
    d <- simulate_tls(
      temps = temps_v, times = times_v,
      reps = des$reps, n = des$n,
      CTmax = TRUTH_SPEED$CTmax, z = TRUTH_SPEED$z,
      low = TRUTH_SPEED$low, up = TRUTH_SPEED$up, k = TRUTH_SPEED$k,
      phi = phi_val, family = fam,
      seed = SPEED_SEED
    )
    n_obs <- nrow(d)

    # ---- fit times ----
    fit_times_ms <- numeric(SPEED_REPS)
    for (r in seq_len(SPEED_REPS)) {
      t0 <- proc.time()["elapsed"]
      invisible(suppressWarnings(
        fit_tls(d, y = survived, n = total, time = duration, temp = temp,
                family = fam, tref = 1)
      ))
      fit_times_ms[r] <- (proc.time()["elapsed"] - t0) * 1000
    }

    # ---- profile CI time (one CTmax profile from the last fit) ----
    fit_for_prof <- suppressWarnings(
      fit_tls(d, y = survived, n = total, time = duration, temp = temp,
              family = fam, tref = 1)
    )
    prof_times_ms <- numeric(SPEED_REPS)
    for (r in seq_len(SPEED_REPS)) {
      t0 <- proc.time()["elapsed"]
      suppressWarnings(confint(fit_for_prof, SPEED_PROFILE_PARM, method = "profile",
                               fallback = FALSE))
      prof_times_ms[r] <- (proc.time()["elapsed"] - t0) * 1000
    }

    med_fit_ms   <- median(fit_times_ms)
    med_prof_ms  <- median(prof_times_ms)

    speed_rows[[paste(fam, dname, sep = "_")]] <- data.frame(
      family = fam, design = dname,
      n_obs = n_obs,
      n_temp = des$n_temp, n_time = des$n_time,
      reps = des$reps, n_per_cell = des$n,
      median_fit_ms   = round(med_fit_ms, 1),
      median_profile_ms = round(med_prof_ms, 1),
      stringsAsFactors = FALSE
    )

    message(sprintf("  %-14s  %-10s  n_obs = %4d  fit = %6.1f ms  profile = %6.1f ms",
                    fam, dname, n_obs, med_fit_ms, med_prof_ms))
  }
}

speed_tbl <- do.call(rbind, speed_rows)
rownames(speed_tbl) <- NULL
message("\nSpeed table:")
print(speed_tbl)

# ============================================================
# 2. ACCURACY STUDY
# ============================================================
message("\n=== ACCURACY STUDY ===")

NSIM_ACC  <- 300L
SEED_ACC  <- 20260602L

truth_settings <- list(
  easy   = list(CTmax = 36, z = 4, low = 0.02, up = 0.98, k = 5,
                label = "CTmax=36/z=4 (typical)"),
  harder = list(CTmax = 38, z = 3, low = 0.02, up = 0.98, k = 5,
                label = "CTmax=38/z=3 (shifted CTmax, harder)")
)

# Standard design for accuracy/coverage (moderate, representative)
ACC_TEMPS <- seq(30, 42, by = 2)   # 7 temperatures
ACC_TIMES <- c(0.5, 1, 2, 4, 8)    # 5 durations
ACC_REPS  <- 3L
ACC_N     <- 20L

acc_rows <- list()

for (fam in c("binomial", "beta_binomial")) {
  phi_val <- if (fam == "beta_binomial") 50 else NULL

  for (sname in names(truth_settings)) {
    tr <- truth_settings[[sname]]

    ct_ests <- numeric(NSIM_ACC)
    z_ests  <- numeric(NSIM_ACC)
    conv_ok <- logical(NSIM_ACC)

    for (i in seq_len(NSIM_ACC)) {
      d <- simulate_tls(
        temps = ACC_TEMPS, times = ACC_TIMES,
        reps = ACC_REPS, n = ACC_N,
        CTmax = tr$CTmax, z = tr$z,
        low = tr$low, up = tr$up, k = tr$k,
        phi = phi_val, family = fam,
        seed = SEED_ACC + i
      )
      fit <- tryCatch(
        suppressWarnings(
          fit_tls(d, y = survived, n = total, time = duration, temp = temp,
                  family = fam, tref = 1)
        ),
        error = function(e) NULL
      )
      # A valid recovery = clean interior convergence (code 0 AND a positive-
      # definite Hessian) to a PLAUSIBLE CTmax. A fit that "converges" (code 0)
      # to a boundary solution -- CTmax shooting far outside the assayed range --
      # is an identifiability failure, not a recovery, and must not pollute
      # bias/RMSE. n_converged then reports the clean-recovery rate honestly.
      ct_hat <- if (!is.null(fit)) {
        fit$estimates$estimate[fit$estimates$parameter == "CTmax"]
      } else {
        NA_real_
      }
      plausible_ct <- is.finite(ct_hat) &&
        ct_hat > min(ACC_TEMPS) - 10 && ct_hat < max(ACC_TEMPS) + 10
      if (!is.null(fit) && isTRUE(fit$convergence$code == 0) &&
          isTRUE(fit$convergence$pdHess) && plausible_ct) {
        conv_ok[i] <- TRUE
        est <- fit$estimates
        ct_ests[i] <- est$estimate[est$parameter == "CTmax"]
        z_ests[i]  <- est$estimate[est$parameter == "z"]
      }
    }

    ok <- which(conv_ok)
    n_ok <- length(ok)

    ct_bias  <- mean(ct_ests[ok] - tr$CTmax)
    ct_rbias <- ct_bias / tr$CTmax
    ct_rmse  <- sqrt(mean((ct_ests[ok] - tr$CTmax)^2))

    z_bias   <- mean(z_ests[ok] - tr$z)
    z_rbias  <- z_bias / tr$z
    z_rmse   <- sqrt(mean((z_ests[ok] - tr$z)^2))

    key <- paste(fam, sname, sep = "_")
    acc_rows[[paste0(key, "_CTmax")]] <- data.frame(
      family = fam, truth_setting = sname, parameter = "CTmax",
      truth_value = tr$CTmax, n_converged = n_ok,
      bias = round(ct_bias, 4),
      rel_bias = round(ct_rbias, 5),
      rmse = round(ct_rmse, 4),
      stringsAsFactors = FALSE
    )
    acc_rows[[paste0(key, "_z")]] <- data.frame(
      family = fam, truth_setting = sname, parameter = "z",
      truth_value = tr$z, n_converged = n_ok,
      bias = round(z_bias, 4),
      rel_bias = round(z_rbias, 5),
      rmse = round(z_rmse, 4),
      stringsAsFactors = FALSE
    )

    message(sprintf("  %-14s  %-8s  n_conv=%3d  CTmax: bias=%7.4f rmse=%6.4f  z: bias=%7.4f rmse=%6.4f",
                    fam, sname, n_ok, ct_bias, ct_rmse, z_bias, z_rmse))
  }
}

accuracy_tbl <- do.call(rbind, acc_rows)
rownames(accuracy_tbl) <- NULL
message("\nAccuracy table:")
print(accuracy_tbl)

# ============================================================
# 3. COVERAGE STUDY  (profile AND Wald, both methods)
# ============================================================
message("\n=== COVERAGE STUDY ===")

# Reuse coverage-study.R truth and design for consistency with the existing rds.
NSIM_COV  <- 300L
SEED_COV  <- 20260616L  # matches coverage-study.R's seed0
LEVEL     <- 0.95
COV_TRUTH <- list(CTmax = 36, z = 4, low = 0.02, up = 0.98, k = 5)
# Same design as coverage-study.R's default simulate_tls() call:
# temps = seq(30, 42, by = 2), times = c(0.5,1,2,4,8), reps=3, n=20

run_one_cov <- function(i, family, phi = NULL) {
  d <- simulate_tls(
    family = family,
    CTmax = COV_TRUTH$CTmax, z = COV_TRUTH$z,
    low = COV_TRUTH$low, up = COV_TRUTH$up, k = COV_TRUTH$k,
    phi = phi, seed = SEED_COV + i
  )
  fit <- tryCatch(
    suppressWarnings(
      fit_tls(d, y = survived, n = total, time = duration, temp = temp,
              family = family, tref = 1)
    ),
    error = function(e) NULL
  )
  if (is.null(fit) || isTRUE(fit$convergence$code != 0)) return(NULL)

  get_ci <- function(p, meth) {
    tryCatch(
      suppressWarnings(
        # fallback = FALSE: measure PURE profile coverage (a non-closing profile
        # counts as a miss), never the v0.2 bootstrap fallback, which would
        # otherwise contaminate the profile method's calibration.
        suppressMessages(confint(fit, p, level = LEVEL, method = meth,
                                 fallback = FALSE))
      ),
      error = function(e) NULL
    )
  }

  list(
    ct_profile = get_ci("CTmax", "profile"),
    z_profile  = get_ci("z",     "profile"),
    ct_wald    = get_ci("CTmax", "wald"),
    z_wald     = get_ci("z",     "wald")
  )
}

cov_rows <- list()

for (fam in c("binomial", "beta_binomial")) {
  phi_val <- if (fam == "beta_binomial") 50 else NULL
  message(sprintf("  coverage: %s ...", fam))

  results <- lapply(seq_len(NSIM_COV), run_one_cov, family = fam, phi = phi_val)
  ok_idx  <- which(!vapply(results, is.null, logical(1)))
  n_ok    <- length(ok_idx)

  for (meth in c("profile", "wald")) {
    slot_ct <- paste0("ct_", meth)
    slot_z  <- paste0("z_",  meth)

    ct_cov <- mean(vapply(ok_idx, function(i) covers(results[[i]][[slot_ct]], COV_TRUTH$CTmax), logical(1)), na.rm = TRUE)
    z_cov  <- mean(vapply(ok_idx, function(i) covers(results[[i]][[slot_z]],  COV_TRUTH$z),    logical(1)), na.rm = TRUE)
    ct_w   <- median(vapply(ok_idx, function(i) ci_width(results[[i]][[slot_ct]]), numeric(1)), na.rm = TRUE)
    z_w    <- median(vapply(ok_idx, function(i) ci_width(results[[i]][[slot_z]]),  numeric(1)), na.rm = TRUE)

    cov_rows[[paste(fam, meth, "CTmax", sep = "_")]] <- data.frame(
      family = fam, method = meth, parameter = "CTmax",
      nominal = LEVEL, n_converged = n_ok,
      coverage = round(ct_cov, 3),
      median_width = round(ct_w, 3),
      stringsAsFactors = FALSE
    )
    cov_rows[[paste(fam, meth, "z", sep = "_")]] <- data.frame(
      family = fam, method = meth, parameter = "z",
      nominal = LEVEL, n_converged = n_ok,
      coverage = round(z_cov, 3),
      median_width = round(z_w, 3),
      stringsAsFactors = FALSE
    )

    message(sprintf("    %-7s  CTmax cov=%.3f w=%.3f  z cov=%.3f w=%.3f",
                    meth, ct_cov, ct_w, z_cov, z_w))
  }
}

coverage_tbl <- do.call(rbind, cov_rows)
rownames(coverage_tbl) <- NULL
message("\nCoverage table:")
print(coverage_tbl)

# ============================================================
# 4. SAVE
# ============================================================

meta <- list(
  nsim_accuracy  = NSIM_ACC,
  nsim_coverage  = NSIM_COV,
  seeds = list(
    accuracy = SEED_ACC,
    coverage = SEED_COV,
    speed    = SPEED_SEED
  ),
  truth = list(
    accuracy_easy   = truth_settings$easy,
    accuracy_harder = truth_settings$harder,   # CTmax=38/z=3 (shifted, harder).
                                               # Beta-binomial occasionally hits
                                               # boundary solutions here; the
                                               # accuracy validity filter (code 0 +
                                               # pdHess + plausible CTmax) excludes
                                               # them so n_converged is the clean rate.
    coverage        = COV_TRUTH
  ),
  phi_convention = paste(
    "R-PHI: phi is the sum of Beta shape parameters.",
    "Draws: prob <- rbeta(a = p*phi, b = (1-p)*phi), then rbinom(n, prob).",
    "Larger phi -> less overdispersion; phi -> Inf recovers the binomial.",
    "Beta-binomial runs used phi = 50."
  ),
  level = LEVEL,
  date  = as.character(Sys.Date()),
  note  = paste(
    "Performance study: speed (wall-clock fit + one CTmax profile CI),",
    "accuracy (bias/RMSE for CTmax and z), and coverage (profile and Wald",
    "95% CIs for CTmax and z), under binomial and beta-binomial families.",
    "No Stan or bayesTLS required. See data-raw/performance-study.R."
  )
)

out <- list(meta = meta, speed = speed_tbl, accuracy = accuracy_tbl,
            coverage = coverage_tbl)

dir.create("inst/extdata", recursive = TRUE, showWarnings = FALSE)
saveRDS(out, "inst/extdata/performance_results.rds")
cat("saved inst/extdata/performance_results.rds\n")

# ============================================================
# 5. SUMMARY PRINT
# ============================================================
message("\n=== SUMMARY ===")
message("\n--- Speed ---")
print(speed_tbl[, c("family","design","n_obs","median_fit_ms","median_profile_ms")])
message("\n--- Accuracy (nsim=", NSIM_ACC, ") ---")
print(accuracy_tbl)
message("\n--- Coverage (nsim=", NSIM_COV, ") ---")
print(coverage_tbl)
message(
  "\nNote: beta-binomial coverage < 0.95 is expected and reported honestly.",
  "\nProfile CIs are more accurate than Wald for small n and asymmetric profiles."
)
