# Three-way benchmark: does the freqTLS twin reproduce bayesTLS on shared data?
# Fits one shared dataset (brown shrimp, lethal, ungrouped) with all three
# estimators - freqTLS (TMB/ML), bayesTLS (Stan/MCMC), classical two-stage - and
# compares CTmax and z. Run with: Rscript data-raw/benchmark-vs-bayes.R
suppressMessages(devtools::load_all(here::here(), quiet = TRUE))
options(mc.cores = 2)

d <- shrimp_lethal
args <- list(temp = "Temperature_assay", duration = "Duration_exposure_hours",
             n_total = "N_individuals_after_trial", mortality = "Mortality_after_trial",
             duration_unit = "hours")

## --- freqTLS (TMB / ML) ---------------------------------------------------
std_f <- do.call(freqTLS::standardize_data, c(list(data = d), args))
wf_f  <- freqTLS::fit_4pl(std_f, t_ref = 1, family = "beta_binomial", quiet = TRUE)
tf    <- freqTLS::tls(wf_f, method = "wald")$summary
get_f <- function(q) tf$median[tf$quantity == q]

## --- classical two-stage --------------------------------------------------
st2 <- freqTLS::ts_stage2(freqTLS::ts_stage1(std_f, family = "binomial"),
                          t_ref = 1, time_multiplier = 1)

## --- bayesTLS (Stan / MCMC) ----------------------------------------------
std_b <- do.call(bayesTLS::standardize_data, c(list(data = d), args))
wf_b  <- bayesTLS::fit_4pl(std_b, chains = 2, iter = 1200, warmup = 600,
                           refresh = 0, seed = 1, t_ref = 1)  # default beta_binomial
tb    <- bayesTLS::tls(wf_b, t_ref = 1, time_multiplier = 1)$summary
get_b <- function(q) tb$median[tb$quantity == q]

cmp <- data.frame(
  quantity = c("CTmax", "z"),
  freqTLS  = c(get_f("CTmax"), get_f("z")),
  bayesTLS = c(get_b("CTmax"), get_b("z")),
  two_stage = c(st2$summary$CTmax_1hr, st2$summary$z)
)
cmp$freq_vs_bayes_diff <- cmp$freqTLS - cmp$bayesTLS
print(cmp, row.names = FALSE, digits = 4)
saveRDS(cmp, here::here("inst", "extdata", "benchmark_vs_bayes.rds"))
cat(sprintf("\nfreqTLS vs bayesTLS: CTmax differs by %.3f C, z by %.1f%%\n",
            abs(cmp$freq_vs_bayes_diff[1]),
            100 * abs(cmp$freq_vs_bayes_diff[2]) / cmp$bayesTLS[2]))
