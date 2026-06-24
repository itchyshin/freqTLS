# Profile-likelihood CI coverage study for freqTLS (maintainer-run; no Stan).
#
# Simulates many datasets at a known (CTmax, z) under both families, fits each by
# ML, computes 95% PROFILE confidence intervals for CTmax and z, and reports the
# empirical (frequentist) coverage and median interval width. This is the
# coverage evidence that backs the package's interval claims; results are saved
# to inst/extdata/coverage_results.rds and summarised in the profile-likelihood
# vignette. Re-run with: Rscript data-raw/coverage-study.R
suppressMessages(devtools::load_all(".", quiet = TRUE))

nsim  <- 200L
level <- 0.95
seed0 <- 20260616L
truth <- list(CTmax = 36, z = 4, low = 0.02, up = 0.98, k = 5)

covers <- function(ci, target) {
  !is.null(ci) && is.finite(ci$conf.low) && is.finite(ci$conf.high) &&
    ci$conf.low <= target && ci$conf.high >= target
}
width <- function(ci) if (!is.null(ci) && is.finite(ci$conf.low) && is.finite(ci$conf.high)) ci$conf.high - ci$conf.low else NA_real_

run_one <- function(i, family, phi = NULL) {
  d <- simulate_tls(family = family, CTmax = truth$CTmax, z = truth$z,
                    low = truth$low, up = truth$up, k = truth$k, phi = phi,
                    seed = seed0 + i)
  fit <- tryCatch(suppressWarnings(
    fit_tls(d, y = survived, n = total, time = duration, temp = temp,
            family = family, tref = 1)), error = function(e) NULL)
  if (is.null(fit) || isTRUE(fit$convergence$code != 0)) return(NULL)
  ci <- function(p) tryCatch(suppressWarnings(
    confint(fit, p, level = level, method = "profile")), error = function(e) NULL)
  cC <- ci("CTmax"); cZ <- ci("z")
  data.frame(i = i,
             ctmax_cov = covers(cC, truth$CTmax), ctmax_width = width(cC),
             z_cov = covers(cZ, truth$z),         z_width = width(cZ),
             ctmax_open = !is.null(cC) && cC$conf.status != "ok",
             z_open = !is.null(cZ) && cZ$conf.status != "ok")
}

message("coverage study: binomial ...")
res_binom <- do.call(rbind, lapply(seq_len(nsim), run_one, family = "binomial"))
message("coverage study: beta_binomial ...")
res_bb <- do.call(rbind, lapply(seq_len(nsim), run_one, family = "beta_binomial", phi = 50))

summ <- function(r, fam) data.frame(
  family = fam, n_converged = nrow(r),
  CTmax_coverage = mean(r$ctmax_cov, na.rm = TRUE),
  CTmax_median_width = median(r$ctmax_width, na.rm = TRUE),
  z_coverage = mean(r$z_cov, na.rm = TRUE),
  z_median_width = median(r$z_width, na.rm = TRUE),
  open_profiles = mean(r$ctmax_open | r$z_open, na.rm = TRUE))
coverage <- rbind(summ(res_binom, "binomial"), summ(res_bb, "beta_binomial"))
print(coverage)

out <- list(
  meta = list(nsim = nsim, level = level, seed = seed0, truth = truth,
              date = as.character(Sys.Date()),
              note = "Empirical coverage of 95% profile-likelihood CIs; nominal 0.95. Finite-sample under-coverage is expected and reported honestly."),
  coverage = coverage,
  raw = list(binomial = res_binom, beta_binomial = res_bb))
dir.create("inst/extdata", recursive = TRUE, showWarnings = FALSE)
saveRDS(out, "inst/extdata/coverage_results.rds")
cat("saved inst/extdata/coverage_results.rds\n")
