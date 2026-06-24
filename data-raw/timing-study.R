# data-raw/timing-study.R
#
# Maintainer-run. Records the wall-clock of the Stan/glmmTMB-dependent comparators
# (bayesTLS MCMC, classical two-stage) on a representative benchmark dataset, so
# vignette("comparing-to-bayesTLS") can show a real head-to-head against the LIVE
# freqTLS timing. freqTLS is fast enough to time in the vignette itself;
# bayesTLS + two-stage need Suggests that are absent from CI, so their times are
# cached here.
#
# ---------------------------------------------------------------------------
# NOT run in CI (needs bayesTLS + cmdstanr + a CmdStan toolchain). Re-run by hand:
#   Rscript data-raw/timing-study.R
# then commit inst/extdata/timing_results.rds.
# ---------------------------------------------------------------------------

if (!requireNamespace("bayesTLS", quietly = TRUE) ||
    !requireNamespace("cmdstanr", quietly = TRUE)) {
  stop("timing-study.R needs both 'bayesTLS' and 'cmdstanr' (with CmdStan). ",
       "Run it by hand on a maintainer machine, then commit timing_results.rds.",
       call. = FALSE)
}
stopifnot(requireNamespace("brms", quietly = TRUE))

SEED <- 123L
data("shrimp_lethal", package = "freqTLS", envir = environment())
bb <- brms::brmsfamily("beta_binomial", link = "identity")

std <- bayesTLS::standardize_data(
  shrimp_lethal, temp = "temp", duration = "duration",
  n_total = "total", n_surv = "survived", duration_unit = "hours"
)

# Warm up the Stan compile so the recorded bayesTLS time is sampling + brms
# overhead, NOT the one-time model compilation.
message("warming up Stan compile ...")
invisible(bayesTLS::fit_4pl(std, temp_effects = "mid", family = bb,
                            chains = 1, iter = 200, seed = SEED,
                            backend = "cmdstanr"))

message("timing bayesTLS fit (4 x 4000) ...")
t_bayes <- system.time(
  bayesTLS::fit_4pl(std, temp_effects = "mid", family = bb,
                    chains = 4, iter = 4000, seed = SEED, backend = "cmdstanr")
)[["elapsed"]]

message("timing classical two-stage ...")
t_ts <- system.time({
  s1 <- bayesTLS::ts_stage1(shrimp_lethal, temp = "temp", duration = "duration",
          n_surv = "survived", n_total = "total", family = "betabinomial")
  s2 <- bayesTLS::ts_stage2(s1, t_ref = 1, time_multiplier = 1)
  bayesTLS::ts_ci(s2, method = "delta", level = 0.95, t_ref = 1,
                  time_multiplier = 1, seed = SEED)
})[["elapsed"]]

timing <- data.frame(
  dataset = "shrimp",
  method  = c("bayesTLS", "two_stage"),
  task    = c("fit (4 chains x 4000, post-compile)", "fit + delta CI"),
  seconds = c(t_bayes, t_ts),
  stringsAsFactors = FALSE
)

out <- list(
  timing = timing,
  meta = list(
    date             = as.character(Sys.Date()),
    bayesTLS_version = as.character(utils::packageVersion("bayesTLS")),
    cmdstan_version  = tryCatch(as.character(cmdstanr::cmdstan_version()),
                                error = function(e) NA_character_),
    dataset          = "shrimp (ungrouped, tref = 1 h, beta-binomial)",
    note = paste(
      "Wall-clock seconds on one maintainer machine; indicative, not a benchmark.",
      "The bayesTLS time is sampling + brms overhead AFTER a one-time Stan compile",
      "(warmed up before timing). freqTLS is timed live in the vignette."
    )
  )
)

dir.create(file.path("inst", "extdata"), showWarnings = FALSE, recursive = TRUE)
saveRDS(out, file.path("inst", "extdata", "timing_results.rds"))
message("wrote inst/extdata/timing_results.rds")
print(timing)
