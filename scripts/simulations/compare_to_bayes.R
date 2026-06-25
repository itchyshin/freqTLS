#!/usr/bin/env Rscript
# ============================================================================
# Compare the freqTLS (ML/TMB) simulation against the bayesTLS (Stan) results
# pulled from OSF (node c6dxy). Both runners share sim_functions.R's scoring, so
# their summaries have identical columns -- we merge on (scenario, quantity) and
# put freqTLS's joint_4pl beside bayesTLS's joint_4pl. The two-stage methods are
# byte-identical code in both, so they serve as a cross-check that the shared
# harness agrees.
#
#   Rscript scripts/simulations/compare_to_bayes.R
#   BAYES_DIR=/path/to/bayesTLS/output/sim_twostage Rscript scripts/simulations/compare_to_bayes.R
# ============================================================================
suppressPackageStartupMessages({ library(dplyr); library(tidyr); library(here) })

FREQ      <- here::here("output", "sim_freq", "summary_sanity.rds")
BAYES_DIR <- Sys.getenv("BAYES_DIR",
  file.path(dirname(here::here()), "bayesTLS", "output", "sim_twostage"))

if (!file.exists(FREQ))
  stop("No freqTLS summary at ", FREQ, " -- run run_simulations.R first.", call. = FALSE)
bfiles <- Sys.glob(file.path(BAYES_DIR, "summary_*.rds"))
if (!length(bfiles))
  stop("No bayesTLS summaries in ", BAYES_DIR,
       " -- fetch them with bayesTLS `make data` (OSF).", call. = FALSE)

keep <- c("joint_4pl", "two_stage_bb_t")
fr <- readRDS(FREQ)                       |> dplyr::filter(method %in% keep)
ba <- dplyr::bind_rows(lapply(bfiles, readRDS)) |> dplyr::filter(method %in% keep)

scen <- intersect(unique(fr$scenario), unique(ba$scenario))
pick <- function(d, p) d |> dplyr::filter(scenario %in% scen) |>
  dplyr::transmute(scenario, quantity, method, pkg = p, n, mean_bias, coverage, med_width)
cmp <- dplyr::bind_rows(pick(fr, "freqTLS"), pick(ba, "bayesTLS"))

# joint_4pl is the estimator that genuinely differs (ML vs posterior) -- the
# headline comparison. Put the two packages side by side.
joint <- cmp |>
  dplyr::filter(method == "joint_4pl") |>
  tidyr::pivot_wider(id_cols = c(scenario, quantity), names_from = pkg,
                     values_from = c(mean_bias, coverage, med_width)) |>
  dplyr::arrange(scenario, quantity)

cat("================ joint_4pl: freqTLS (ML) vs bayesTLS (posterior) ===========\n")
cat("(bias near 0 and coverage near 0.95 = the freqTLS twin recovers the truth\n",
    " as the Bayesian fit does; boundary-asymptote scenarios -- scen1, scen7 high\n",
    " u0 -- are expected to be harder for ML.)\n\n", sep = "")
print(as.data.frame(joint), row.names = FALSE)

# Two-stage as a harness cross-check (identical code in both packages).
cat("\n---- two_stage_bb_t cross-check (same code both pkgs; should match within MC noise) ----\n")
ts <- cmp |>
  dplyr::filter(method == "two_stage_bb_t", quantity == "z") |>
  tidyr::pivot_wider(id_cols = scenario, names_from = pkg,
                     values_from = coverage) |>
  dplyr::arrange(scenario)
print(as.data.frame(ts), row.names = FALSE)
