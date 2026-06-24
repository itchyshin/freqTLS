# data-raw/beta-binomial-phi-study.R
#
# Characterises the beta-binomial profile under-coverage reported by
# performance-study.R. Empirical coverage of profile vs Wald vs bootstrap 95% CIs
# for CTmax and z, as the dispersion phi moves from strong (well-identified)
# overdispersion to mild (weakly-identified, near-binomial) overdispersion.
#
# Finding: as phi grows the data approach the binomial limit, phi becomes weakly
# identified (phi_hat runs away, its relative SE blows up), and the PROFILE
# interval collapses (it profiles the runaway phi out to the binomial limit, so it
# goes too narrow). Wald stays calibrated because the joint Hessian propagates the
# flat-phi uncertainty; the parametric bootstrap is a middle ground. This is NOT a
# clamping artefact -- the likelihood clamps (1e-12, 1e-8) never activate here.
#
# Maintainer-run. NOT in CI. Re-run from the package root:
#   Rscript data-raw/beta-binomial-phi-study.R          # full (~20 min)
#   Rscript data-raw/beta-binomial-phi-study.R smoke     # tiny smoke run
# Output: inst/extdata/beta_binomial_phi_results.rds (read by comparing-to-bayesTLS).
# ---------------------------------------------------------------------------

if (requireNamespace("pkgload", quietly = TRUE) && file.exists("DESCRIPTION")) {
  suppressMessages(pkgload::load_all(".", quiet = TRUE))
} else {
  library(freqTLS)
}

args  <- commandArgs(trailingOnly = TRUE)
SMOKE <- length(args) >= 1L && identical(args[1], "smoke")
NSIM  <- if (SMOKE)  6L else 120L
NBOOT <- if (SMOKE) 49L else 149L
LEVEL <- 0.95
TR <- list(CTmax = 36, z = 4, low = 0.02, up = 0.98, k = 5)
PHIS <- c(5, 50, 200)            # strong -> mild -> very-mild overdispersion
PARAMS <- c("CTmax", "z")
covers <- function(lo, hi, t) is.finite(lo) && is.finite(hi) && lo <= t && hi >= t
wd <- function(lo, hi) if (is.finite(lo) && is.finite(hi)) hi - lo else NA_real_

cov_rows <- list(); phi_rows <- list()
t0 <- Sys.time()
for (phi in PHIS) {
  phat <- prelse <- rep(NA_real_, NSIM)
  # coverage[param, method] and width[param, method] accumulators
  cov <- array(NA, dim = c(NSIM, length(PARAMS), 3),
               dimnames = list(NULL, PARAMS, c("profile", "wald", "bootstrap")))
  wdt <- cov
  for (i in seq_len(NSIM)) {
    d <- tryCatch(simulate_tls(family = "beta_binomial", CTmax = TR$CTmax, z = TR$z,
                               low = TR$low, up = TR$up, k = TR$k, phi = phi,
                               seed = 20000L + as.integer(phi) * 137L + i),
                  error = function(e) NULL)
    if (is.null(d)) next
    fit <- tryCatch(fit_tls(d, y = survived, n = total, time = duration, temp = temp,
                            family = "beta_binomial", tref = 1, quiet = TRUE),
                    error = function(e) NULL)
    if (is.null(fit) || !isTRUE(fit$convergence$code == 0) ||
        !isTRUE(fit$convergence$pdHess)) next
    e <- fit$estimates; pr <- e[e$parameter == "phi", ]
    if (nrow(pr) == 1L && is.finite(pr$estimate) && pr$estimate > 0) {
      phat[i] <- pr$estimate; prelse[i] <- pr$std.error / pr$estimate
    }
    gp <- function(meth) tryCatch(suppressWarnings(suppressMessages(
      confint(fit, PARAMS, level = LEVEL, method = meth,
              fallback = FALSE, nboot = NBOOT, boot_seed = as.integer(phi) * 7L + i))),
      error = function(e) NULL)
    for (meth in c("profile", "wald", "bootstrap")) {
      ci <- gp(meth); if (is.null(ci)) next
      for (pm in PARAMS) {
        r <- ci[ci$parameter == pm, , drop = FALSE]; if (!nrow(r)) next
        cov[i, pm, meth] <- covers(r$conf.low[1], r$conf.high[1], TR[[pm]])
        wdt[i, pm, meth] <- wd(r$conf.low[1], r$conf.high[1])
      }
    }
  }
  ok <- !is.na(phat)
  phi_rows[[as.character(phi)]] <- data.frame(
    phi_true = phi, n_ok = sum(ok),
    phi_hat_median = round(median(phat[ok]), 1),
    phi_rel_se_median = round(median(prelse[ok], na.rm = TRUE), 2),
    pct_phi_gt_2x = round(mean(phat[ok] > 2 * phi), 2), stringsAsFactors = FALSE)
  for (pm in PARAMS) for (meth in c("profile", "wald", "bootstrap")) {
    cov_rows[[paste(phi, pm, meth)]] <- data.frame(
      phi_true = phi, parameter = pm, method = meth, nominal = LEVEL,
      coverage = round(mean(cov[ok, pm, meth], na.rm = TRUE), 3),
      median_width = round(median(wdt[ok, pm, meth], na.rm = TRUE), 3),
      n_rep = sum(!is.na(cov[ok, pm, meth])), stringsAsFactors = FALSE)
  }
  cat(sprintf("phi=%3d done (n=%d, phi_hat med=%.0f, rel_se med=%.2f)\n",
              phi, sum(ok), median(phat[ok]), median(prelse[ok], na.rm = TRUE)))
}
coverage <- do.call(rbind, cov_rows); rownames(coverage) <- NULL
phi_summary <- do.call(rbind, phi_rows); rownames(phi_summary) <- NULL
elapsed <- as.numeric(difftime(Sys.time(), t0, units = "mins"))

out <- list(
  coverage = coverage, phi_summary = phi_summary,
  meta = list(date = as.character(Sys.Date()),
              freqTLS_version = as.character(utils::packageVersion("freqTLS")),
              smoke = SMOKE, nsim = NSIM, nboot = NBOOT, level = LEVEL,
              truth = TR, phis = PHIS, elapsed_min = round(elapsed, 1),
              design = "temps seq(30,42,by=2), times c(0.5,1,2,4,8), reps=3, n=20 (105 obs)",
              note = paste(
                "Beta-binomial coverage of profile/Wald/bootstrap CIs vs the",
                "dispersion phi. Larger phi = milder overdispersion = weaker phi",
                "identification. Profile collapses as phi grows; Wald is robust;",
                "bootstrap is a middle ground. Not a clamping artefact.")))

dir.create("inst/extdata", showWarnings = FALSE, recursive = TRUE)
saveRDS(out, "inst/extdata/beta_binomial_phi_results.rds")
cat(sprintf("\nwrote inst/extdata/beta_binomial_phi_results.rds (%.1f min)\n", elapsed))
cat("\n--- phi summary ---\n"); print(phi_summary, row.names = FALSE)
cat("\n--- coverage ---\n"); print(coverage, row.names = FALSE)
