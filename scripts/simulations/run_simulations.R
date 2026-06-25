#!/usr/bin/env Rscript
# ============================================================================
# Two-stage-bias simulation -- freqTLS (maximum-likelihood / TMB) sanity runner.
#
# The frequentist twin of bayesTLS scripts/simulations/run_simulations.R. It
# reuses the SAME scenarios and DGP (sim_functions.R) but fits the joint 4PL by
# maximum likelihood (freqTLS::fit_4pl) instead of Stan, so it runs in-memory in
# seconds-to-minutes with no cmdstanr and no OSF raw-file cache. Use it to sanity
# check that the freqTLS estimator recovers z_true / CTmax_1hr_true with roughly
# nominal coverage, alongside the classical two-stage estimator.
#
# Run the default sanity subset:
#   Rscript scripts/simulations/run_simulations.R
# Run specific scenarios (or "all"):
#   Rscript scripts/simulations/run_simulations.R scen1_strict_eq_n5 scen3_heat_lowers_u_n5
#   Rscript scripts/simulations/run_simulations.R all
# Tune the work with env vars (defaults shown):
#   N_SIMS=60 NBOOT=300 Rscript scripts/simulations/run_simulations.R
# ============================================================================

suppressPackageStartupMessages({
  library(freqTLS); library(dplyr); library(tibble); library(tidyr)
  library(parallel); library(here)
})
source(here::here("scripts", "simulations", "sim_functions.R"))

# ---- 1. Config -------------------------------------------------------------
OUT_DIR     <- here::here("output", "sim_freq")
dir.create(OUT_DIR, recursive = TRUE, showWarnings = FALSE)
N_SIMS      <- as.integer(Sys.getenv("N_SIMS", "60"))    # simulated datasets / scenario
NBOOT       <- as.integer(Sys.getenv("NBOOT",  "0"))     # bootstrap reps for the
# absolute-threshold + T_crit path; 0 (default) = fast relative-only sanity
# (headline z / CTmax_1hr from the profile path, no resampling).
WORKERS     <- as.integer(Sys.getenv("WORKERS",
                 as.character(max(1L, parallel::detectCores() - 2L))))  # fork pool
MASTER_SEED <- 20260513L                                 # matches the bayesTLS runner

# ---- 2. Scenarios (identical table to the bayesTLS runner) ------------------
scenarios <- tibble::tribble(
  ~label,                   ~dgp,        ~family,         ~n_reps, ~design,   ~u_0,  ~ell_0, ~u_beta1,
  "scen1_strict_eq_n3",     "baseline",  "binomial",      3,  "full",    0.999, 0.001,  NA,
  "scen1_strict_eq_n5",     "baseline",  "binomial",      5,  "full",    0.999, 0.001,  NA,
  "scen2_lik_misspec_n3",   "baseline",  "beta_binomial", 3,  "full",    0.999, 0.001,  NA,
  "scen2_lik_misspec_n5",   "baseline",  "beta_binomial", 5,  "full",    0.999, 0.001,  NA,
  "scen3_heat_lowers_u_n3", "asym_u",    "beta_binomial", 3,  "full",    NA,    NA,     NA,
  "scen3_heat_lowers_u_n5", "asym_u",    "beta_binomial", 5,  "full",    NA,    NA,     NA,
  "scen4_compress_n3",      "sym_ul",    "beta_binomial", 3,  "full",    NA,    NA,     NA,
  "scen4_compress_n5",      "sym_ul",    "beta_binomial", 5,  "full",    NA,    NA,     NA,
  "scen5_sharpen_n3",       "varying_k", "beta_binomial", 3,  "full",    NA,    NA,     NA,
  "scen5_sharpen_n5",       "varying_k", "beta_binomial", 5,  "full",    NA,    NA,     NA,
  "scen6_ub_m005",          "baseline",  "beta_binomial", 5,  "full",    NA,    NA,     -0.005,
  "scen6_ub_m010",          "baseline",  "beta_binomial", 5,  "full",    NA,    NA,     -0.010,
  "scen6_ub_m015",          "baseline",  "beta_binomial", 5,  "full",    NA,    NA,     -0.015,
  "scen6_ub_m019",          "baseline",  "beta_binomial", 5,  "full",    NA,    NA,     -0.019,
  "scen7_u0_099",           "baseline",  "beta_binomial", 5,  "full",    0.99,  NA,     NA,
  "scen7_u0_095",           "baseline",  "beta_binomial", 5,  "full",    0.95,  NA,     NA,
  "scen7_u0_085",           "baseline",  "beta_binomial", 5,  "full",    0.85,  NA,     NA,
  "scen7_u0_075",           "baseline",  "beta_binomial", 5,  "full",    0.75,  NA,     NA,
  "scen7_u0_065",           "baseline",  "beta_binomial", 5,  "full",    0.65,  NA,     NA,
  "scen8_full_n1",          "baseline",  "beta_binomial", 1,  "full",    NA,    NA,     NA,
  "scen8_full_n3",          "baseline",  "beta_binomial", 3,  "full",    NA,    NA,     NA,
  "scen8_full_n5",          "baseline",  "beta_binomial", 5,  "full",    NA,    NA,     NA,
  "scen8_sparse_n1",        "baseline",  "beta_binomial", 1,  "sparse",  NA,    NA,     NA,
  "scen8_sparse_n3",        "baseline",  "beta_binomial", 3,  "sparse",  NA,    NA,     NA,
  "scen8_sparse_n5",        "baseline",  "beta_binomial", 5,  "sparse",  NA,    NA,     NA,
  "scen9_tmax_060",         "baseline",  "beta_binomial", 5,  "tmax060", NA,    NA,     NA,
  "scen9_tmax_120",         "baseline",  "beta_binomial", 5,  "tmax120", NA,    NA,     NA,
  "scen9_tmax_240",         "baseline",  "beta_binomial", 5,  "tmax240", NA,    NA,     NA,
  "scen9_tmax_405",         "baseline",  "beta_binomial", 5,  "tmax405", NA,    NA,     NA,
)
scenarios$index <- seq_len(nrow(scenarios))

# A representative sanity subset: strict-equivalence (binomial), likelihood
# misspecification (beta-binomial), an asymmetric-u DGP (where the relative
# threshold is expected to be biased -- the point of the study), a sparse design,
# and the shortest exposure window.
SANITY <- c("scen1_strict_eq_n5", "scen2_lik_misspec_n5", "scen3_heat_lowers_u_n5",
            "scen8_sparse_n5", "scen9_tmax_060")

cli <- commandArgs(trailingOnly = TRUE)
sel <- if (length(cli) == 0) SANITY else if (identical(cli, "all")) scenarios$label else cli
to_run <- dplyr::filter(scenarios, label %in% sel)
if (nrow(to_run) == 0L) stop("No scenarios matched: ", paste(sel, collapse = ", "))

# ---- 3. One scenario, in memory --------------------------------------------
# simulate -> two-stage x2 (binomial / beta-binomial) -> freqTLS joint 4PL ->
# score against the truth. No raw files: freqTLS is fast enough to regenerate.
run_scenario <- function(sc) {
  truth <- sim_truth(dgp = sc$dgp, family = sc$family, design = sc$design,
                     u_0 = na_to_null(sc$u_0), ell_0 = na_to_null(sc$ell_0),
                     u_beta1 = na_to_null(sc$u_beta1))
  message(sprintf("\n=== %s  (z_true=%.3f  CTmax_1hr_true=%.3f) ===",
                  sc$label, truth$z_true, truth$CTmax_1hr_true))
  t0 <- Sys.time()
  one <- function(sim_id) tryCatch({
    seed   <- MASTER_SEED + 1000L * sc$index + sim_id
    data   <- sim_dataset(n_reps = sc$n_reps, seed = seed, truth = truth)
    ts_bin <- fit_two_stage(data, stage1 = "binomial")
    ts_bb  <- fit_two_stage(data, stage1 = "betabinomial")
    joint  <- fit_joint_4pl(data, nboot = NBOOT, seed = seed)  # freqTLS ML/TMB
    score_run(joint, ts_bin, ts_bb, truth, sim_id, sc$label, seed)$row
  }, error = function(e) NULL)
  # fork pool (freqTLS/TMB is fork-safe, unlike cmdstanr). WORKERS = 1 runs
  # serially for easy debugging. NULLs (a dead worker) are dropped by bind_rows.
  rows <- if (WORKERS > 1L)
    parallel::mclapply(seq_len(N_SIMS), one, mc.cores = WORKERS)
  else lapply(seq_len(N_SIMS), one)
  per_sim <- dplyr::bind_rows(rows)
  summ <- summarise_mcse(per_sim)
  message(sprintf("  %d sims in %.1f s", N_SIMS,
                  as.numeric(difftime(Sys.time(), t0, units = "secs"))))
  print(as.data.frame(summ))
  list(per_sim = per_sim, summary = summ)
}

# ---- 4. Run, aggregate, save ------------------------------------------------
message(sprintf("freqTLS sanity sim: %d scenario(s), N_SIMS=%d, NBOOT=%d",
                nrow(to_run), N_SIMS, NBOOT))
tryCatch(preflight(to_run),
         error = function(e) message("preflight note: ", conditionMessage(e)))

res <- lapply(seq_len(nrow(to_run)), function(i) run_scenario(to_run[i, ]))
per_sim_all <- dplyr::bind_rows(lapply(res, `[[`, "per_sim"))
summary_all <- dplyr::bind_rows(lapply(res, `[[`, "summary"))

# OUT_TAG keys the output files, so a SLURM job array (one scenario per task) can
# write side by side without clobbering. Default "sanity" for an interactive run.
TAG <- Sys.getenv("OUT_TAG", "sanity")
saveRDS(per_sim_all, file.path(OUT_DIR, paste0("per_sim_", TAG, ".rds")))
saveRDS(summary_all, file.path(OUT_DIR, paste0("summary_", TAG, ".rds")))

# Headline: freqTLS recovery & coverage vs the t-corrected classical two-stage.
cat("\n=========== freqTLS sanity: recovery & 95% coverage by method ===========\n")
cat("(joint_4pl = freqTLS ML/TMB, relative threshold, profile CI;",
    "two_stage_*_t = classical, t-corrected CI)\n")
keep <- c("joint_4pl", if (NBOOT > 0L) "joint_4pl_abs",
          "two_stage_bin_t", "two_stage_bb_t")
print(as.data.frame(
  summary_all |>
    dplyr::filter(method %in% keep) |>
    dplyr::arrange(scenario, quantity, method) |>
    dplyr::select(scenario, quantity, method, n, mean_bias, mcse_bias,
                  coverage, med_width)
), row.names = FALSE)
cat("\nSaved per-sim + summary to", OUT_DIR, "\n")
