# data-raw/re-recovery-study.R
#
# Random-effect variance-recovery study for freqTLS.
#
# Quantifies how the CTmax random-intercept SD (sigma_CTmax) and the fixed-effect
# CTmax interval behave as the number of grouping levels shrinks. This is the
# empirical basis for the "< ~8 groups" advisory that fit_tls() emits: a variance
# component is biased LOW with few groups, and the fixed-effect interval can
# under-cover. Complements performance-study.R / coverage-study.R, which cover the
# fixed-effects model.
#
# Maintainer-run. NOT in CI. Re-run from the package root:
#   Rscript data-raw/re-recovery-study.R          # full (~10 min)
#   Rscript data-raw/re-recovery-study.R smoke     # tiny smoke run
# Output: inst/extdata/re_recovery_results.rds (read by vignette("random-effects")).
# ---------------------------------------------------------------------------

if (requireNamespace("pkgload", quietly = TRUE) && file.exists("DESCRIPTION")) {
  suppressMessages(pkgload::load_all(".", quiet = TRUE))
} else {
  library(freqTLS)
}

args  <- commandArgs(trailingOnly = TRUE)
SMOKE <- length(args) >= 1L && identical(args[1], "smoke")
NSIM  <- if (SMOKE) 6L else 150L
LEVEL <- 0.95
RE_SD <- 1.5          # true sigma_CTmax
CT    <- 36; Z <- 4
NGROUPS <- c(3L, 5L, 8L, 14L, 30L)
covers <- function(lo, hi, t) is.finite(lo) && is.finite(hi) && lo <= t && hi >= t

bf <- tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
             CTmax ~ 1 + (1 | colony))

rows <- list()
t0 <- Sys.time()
for (ng in NGROUPS) {
  sig <- ct <- rep(NA_real_, NSIM); ct_cov <- rep(NA, NSIM)
  for (i in seq_len(NSIM)) {
    d <- tryCatch(
      simulate_tls(family = "binomial", CTmax = CT, z = Z,
                   re_sd = RE_SD, n_re_groups = ng, seed = 4000L + ng * 131L + i),
      error = function(e) NULL)
    if (is.null(d)) next
    fit <- tryCatch(
      fit_tls(bf, data = d, family = "binomial", tref = 1, quiet = TRUE),
      error = function(e) NULL)
    if (is.null(fit) || !isTRUE(fit$convergence$code == 0)) next
    e <- fit$estimates
    s  <- e$estimate[e$parameter == "sigma_CTmax"]
    c0 <- e$estimate[e$parameter == "CTmax"]
    if (!length(s) || !is.finite(s[1])) next
    sig[i] <- s[1]; ct[i] <- c0[1]
    ci <- tryCatch(suppressWarnings(suppressMessages(
      confint(fit, "CTmax", level = LEVEL, method = "wald"))), error = function(e) NULL)
    if (!is.null(ci) && nrow(ci)) ct_cov[i] <- covers(ci$conf.low[1], ci$conf.high[1], CT)
  }
  ok <- !is.na(sig)
  rows[[as.character(ng)]] <- data.frame(
    n_groups = ng, n_ok = sum(ok), truth_sigma = RE_SD,
    mean_sigma = round(mean(sig[ok]), 3),
    median_sigma = round(median(sig[ok]), 3),
    rel_bias = round((mean(sig[ok]) - RE_SD) / RE_SD, 3),
    rmse = round(sqrt(mean((sig[ok] - RE_SD)^2)), 3),
    CTmax_wald_coverage = round(mean(ct_cov[ok], na.rm = TRUE), 3),
    stringsAsFactors = FALSE)
  cat(sprintf("n_groups=%2d n=%3d | sigma mean=%.2f rel_bias=%+.2f | CTmax wald cov=%.3f\n",
              ng, sum(ok), mean(sig[ok]), (mean(sig[ok]) - RE_SD) / RE_SD,
              mean(ct_cov[ok], na.rm = TRUE)))
}
re_recovery <- do.call(rbind, rows); rownames(re_recovery) <- NULL
elapsed <- as.numeric(difftime(Sys.time(), t0, units = "mins"))

out <- list(
  re_recovery = re_recovery,
  meta = list(
    date = as.character(Sys.Date()),
    freqTLS_version = as.character(utils::packageVersion("freqTLS")),
    smoke = SMOKE, nsim = NSIM, truth_sigma = RE_SD, CTmax = CT, z = Z,
    n_groups = NGROUPS, level = LEVEL, elapsed_min = round(elapsed, 1),
    note = paste(
      "Random-effect variance recovery vs number of grouping levels:",
      "sigma_CTmax bias/RMSE and fixed-effect CTmax Wald coverage, true",
      "sigma_CTmax = 1.5. Empirical basis for the < ~8-group advisory.",
      "Maintainer-run, not in CI.")))

dir.create("inst/extdata", showWarnings = FALSE, recursive = TRUE)
saveRDS(out, "inst/extdata/re_recovery_results.rds")
cat(sprintf("\nwrote inst/extdata/re_recovery_results.rds (%.1f min)\n", elapsed))
print(re_recovery, row.names = FALSE)
