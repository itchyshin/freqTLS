# Calibration evidence: does the t(df = n - p) correction restore nominal
# coverage where the asymptotic normal (z) calibration under-covers at small n?
# Wald coverage is cheap (fit + sdreport SE, no profiling), so we sweep many
# replicates over a small-n and a large-n design and compare z vs t coverage and
# width for CTmax and z. (Profile-t tracks Wald-t but is far slower; spot-checked
# separately.) Run with: Rscript data-raw/calibration-study.R
suppressMessages(devtools::load_all(here::here(), quiet = TRUE))

TRUTH <- list(CTmax = 36, z = 4)
cells <- list(
  small = list(temps = c(33, 36, 39), times = c(0.5, 1, 2, 4, 8), reps = 1),
  mid   = list(temps = c(32, 34, 36, 38), times = c(0.5, 1, 2, 4, 8), reps = 2),
  large = list(temps = seq(30, 42, 2), times = c(0.5, 1, 2, 4, 8), reps = 3)
)
n_sim <- 500L

cover_cell <- function(spec, n_sim, seed0) {
  zc <- stats::qnorm(0.975)
  rows <- vector("list", n_sim)
  for (i in seq_len(n_sim)) {
    d <- simulate_tls(family = "binomial", temps = spec$temps, times = spec$times,
                      reps = spec$reps, CTmax = TRUTH$CTmax, z = TRUTH$z,
                      seed = seed0 + i)
    s <- standardize_data(d, temp = "temp", duration = "duration",
                          n_total = "total", n_surv = "survived")
    f <- tryCatch(suppressWarnings(fit_4pl(s, t_ref = 1, family = "binomial",
                                           quiet = TRUE)), error = function(e) NULL)
    if (is.null(f) || !identical(f$fit$convergence$code, 0L) ||
        !isTRUE(f$fit$convergence$pdHess)) next
    fit <- f$fit
    df  <- freqTLS:::tls_ci_df(fit)
    tc  <- stats::qt(0.975, df)
    fx  <- summary(fit$sdreport, select = "fixed")
    ct <- fx["beta_CT", "Estimate"];   se_ct <- fx["beta_CT", "Std. Error"]
    lz <- fx["beta_logz", "Estimate"]; se_lz <- fx["beta_logz", "Std. Error"]
    if (!is.finite(se_ct) || !is.finite(se_lz)) next
    rows[[i]] <- data.frame(
      df = df,
      cov_z_ct = abs(TRUTH$CTmax - ct) <= zc * se_ct,
      cov_t_ct = abs(TRUTH$CTmax - ct) <= tc * se_ct,
      cov_z_z  = abs(log(TRUTH$z) - lz) <= zc * se_lz,
      cov_t_z  = abs(log(TRUTH$z) - lz) <= tc * se_lz,
      w_z_ct = 2 * zc * se_ct, w_t_ct = 2 * tc * se_ct)
  }
  do.call(rbind, rows)
}

mcse <- function(p, n) sqrt(p * (1 - p) / n)
summary_row <- function(name, r) {
  n <- nrow(r)
  data.frame(
    cell = name, n_ok = n, median_df = stats::median(r$df),
    cov_CTmax_z = mean(r$cov_z_ct), cov_CTmax_t = mean(r$cov_t_ct),
    cov_z_z = mean(r$cov_z_z), cov_z_t = mean(r$cov_t_z),
    mcse = round(mcse(0.95, n), 3),
    width_CTmax_z = round(mean(r$w_z_ct), 3), width_CTmax_t = round(mean(r$w_t_ct), 3))
}

res <- Map(function(nm, sp) summary_row(nm, cover_cell(sp, n_sim, seed0 = 1000)),
           names(cells), cells)
out <- do.call(rbind, res)
print(out, row.names = FALSE)
saveRDS(out, here::here("inst", "extdata", "calibration_results.rds"))
cat("\nNominal = 0.95; MC-SE shown. z = asymptotic normal, t = small-sample qt(df).\n")
