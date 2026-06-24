# data-raw/build_benchmark_cache.R
#
# Maintainer-run script. Builds the cached bayesTLS + classical two-stage
# benchmark summaries that freqTLS ships and reads at vignette-build / test
# time, so that neither Stan/cmdstanr nor bayesTLS is needed in CI.
#
# ---------------------------------------------------------------------------
# THIS SCRIPT IS NOT RUN AUTOMATICALLY AND MUST NOT BE RUN IN CI.
# ---------------------------------------------------------------------------
# It requires both bayesTLS and cmdstanr (with a working CmdStan toolchain),
# which are deliberately absent from the test/CI environment. Run it by hand on
# a maintainer machine after a bayesTLS update, then commit the refreshed
# inst/extdata/bayesTLS_benchmark_cache.rds. The guard below stops the script
# immediately if the dependencies are missing.
#
#   Rscript data-raw/build_benchmark_cache.R
#
# Output: inst/extdata/bayesTLS_benchmark_cache.rds, a list with
#   $meta       provenance (bayesTLS_version, git_sha, cmdstan_version,
#               date_built, seed, the shared config, the per-dataset configs,
#               and the R-SHRIMP note)
#   $bayesian   tibble of bayesTLS posterior medians + 95% CrI for CTmax and z,
#               keyed by `dataset`: "shrimp", "zebrafish:<stage>",
#               "dsuzukii:<sex>", and "snowgum"
#   $two_stage  tibble of classical two-stage point estimates + delta-method CIs,
#               for the COUNT datasets only (shrimp, zebrafish, dsuzukii)
#
# Datasets covered (each fitted on its own native time unit and reference time,
# matched to the corresponding freqTLS case-study fit):
#   shrimp      count  (beta-binomial), tref = 1 hour,   ungrouped
#   zebrafish   count  (beta-binomial), tref = 1 hour,   grouped by life_stage
#   dsuzukii    count  (beta-binomial), tref = 240 min,  grouped by sex
#   snowgum     proportion (Beta),      tref = 5 min,     ungrouped
#
# Fairness (see docs/design/06-benchmark-protocol.md): all interval-bearing model
# fits (bayesTLS posterior, freqTLS profile) use the RELATIVE survival
# threshold ((low + up)/2, the freqTLS CTmax PARAMETER) and the CONSTANT-SHAPE
# model (temp_effects = "mid"), with the time unit and reference time matched to
# the freqTLS fit per dataset. The classical two-stage path estimates the
# absolute LT50 by construction; for the near-0/near-1 lethal asymptotes of these
# count datasets the relative midpoint and the absolute LT50 coincide. The
# snow-gum PSII endpoint is a continuous proportion with NO count representation,
# so the count-based two-stage path does not apply there (bayesTLS + freqTLS
# only). freqTLS itself is fitted LIVE in the vignette/test, not cached here.

# ---- 0. hard dependency guard (do not remove) -----------------------------

if (!requireNamespace("bayesTLS", quietly = TRUE) ||
    !requireNamespace("cmdstanr", quietly = TRUE)) {
  stop(
    "build_benchmark_cache.R needs both 'bayesTLS' and 'cmdstanr' (with a ",
    "working CmdStan). They are intentionally absent from CI. Run this script ",
    "by hand on a maintainer machine, then commit the refreshed cache rds.",
    call. = FALSE
  )
}
stopifnot(requireNamespace("brms", quietly = TRUE))

# ---- 1. shared config (matched across all estimators) ---------------------

SEED          <- 123L
TARGET_SURV   <- "relative"   # (low + up)/2 threshold = freqTLS CTmax param
TEMP_EFFECTS  <- "mid"        # constant-shape: shared low/up/k (fair benchmark)
ITER          <- 4000L
CHAINS        <- 4L
NDRAWS        <- 1000L

config <- list(
  seed            = SEED,
  target_surv     = TARGET_SURV,
  temp_effects    = TEMP_EFFECTS,
  iter            = ITER,
  chains          = CHAINS,
  ndraws          = NDRAWS
)

bb_family   <- brms::brmsfamily("beta_binomial", link = "identity")
beta_family <- brms::Beta(link = "identity")

# ---- 2. data (the vendored, R-SHRIMP-corrected datasets) ------------------

# Use the freqTLS datasets so the comparators see EXACTLY the counts /
# proportions freqTLS sees (including the R-SHRIMP fix).
data("shrimp_lethal", package = "freqTLS", envir = environment())
data("zebrafish_lethal", package = "freqTLS", envir = environment())
data("dsuzukii_lethal", package = "freqTLS", envir = environment())
data("snowgum_psii", package = "freqTLS", envir = environment())

# ---- 3. per-dataset benchmark configuration -------------------------------
# Each entry pins the column contract, the native time unit + reference time,
# the response type / family, and whether the count-based two-stage applies.
# `group` NULL fits the whole dataset (keyed "<key>"); otherwise one fit per
# level (keyed "<key>:<level>"), matching the freqTLS case-study fit.

datasets <- list(
  list(key = "shrimp",    data = shrimp_lethal,    temp = "temp",
       duration = "duration", time_unit = "hours",   tref = 1,
       group = NULL,          response = "count",      n_total = "total",
       n_surv = "survived",   family = bb_family,      two_stage = TRUE),
  list(key = "zebrafish", data = zebrafish_lethal, temp = "temp",
       duration = "duration", time_unit = "hours",   tref = 1,
       group = "life_stage",  response = "count",      n_total = "total",
       n_surv = "survived",   family = bb_family,      two_stage = TRUE),
  list(key = "dsuzukii",  data = dsuzukii_lethal,  temp = "temp",
       duration = "time",     time_unit = "minutes", tref = 240,
       group = "sex",         response = "count",      n_total = "total",
       n_surv = "survived",   family = bb_family,      two_stage = TRUE),
  list(key = "snowgum",   data = snowgum_psii,     temp = "temp",
       duration = "duration", time_unit = "minutes", tref = 5,
       group = NULL,          response = "proportion", proportion = "prop",
       family = beta_family,  two_stage = FALSE)
)

# ---- 4. Bayesian path: fit_4pl(temp_effects = "mid") -> extract_tdt --------

# Fit one (sub)dataset under its configured family/threshold and pull CTmax + z.
fit_bayes_one <- function(df, label, cfg) {
  std_args <- list(
    data          = df,
    temp          = cfg$temp,
    duration      = cfg$duration,
    duration_unit = cfg$time_unit
  )
  if (identical(cfg$response, "proportion")) {
    std_args$proportion <- cfg$proportion           # continuous (0, 1), Beta
  } else {
    std_args$n_total <- cfg$n_total                 # counts, beta-binomial
    std_args$n_surv  <- cfg$n_surv
  }
  std <- do.call(bayesTLS::standardize_data, std_args)
  fit <- bayesTLS::fit_4pl(
    data         = std,
    temp_effects = TEMP_EFFECTS,
    family       = cfg$family,
    chains       = CHAINS,
    iter         = ITER,
    seed         = SEED,
    backend      = "cmdstanr"
  )
  tdt <- bayesTLS::extract_tdt(
    fit,
    target_surv      = TARGET_SURV,
    t_ref            = cfg$tref,
    time_multiplier  = 1,                # duration already in cfg$time_unit
    output_time_unit = cfg$time_unit,
    ndraws           = NDRAWS,
    lethal           = FALSE
  )
  summarise_tdt(tdt, label)
}

# Reduce an extract_tdt() result to one row each for CTmax and z, using the
# official bayesTLS extractors. extract_tdt() returns a NESTED list, and its
# summary tibbles use different column names for the two quantities (verified
# against bayesTLS 1.0.0): CTmax -> temp_lower/temp_median/temp_upper;
# z -> z_median/z_lower/z_upper. get_ctmax_summary()/get_z_summary() return
# those summary tibbles directly.
summarise_tdt <- function(tdt, label) {
  ct <- bayesTLS::get_ctmax_summary(tdt)  # temp_lower, temp_median, temp_upper
  z  <- bayesTLS::get_z_summary(tdt)      # z_median, z_lower, z_upper
  tibble::tibble(
    dataset   = label,
    parameter = c("CTmax", "z"),
    median    = c(ct$temp_median, z$z_median),
    lower     = c(ct$temp_lower,  z$z_lower),
    upper     = c(ct$temp_upper,  z$z_upper)
  )
}
`%||%` <- function(x, y) if (is.null(x)) y else x

# ---- 5. Classical two-stage path: ts_stage1 -> ts_stage2 -> ts_ci ---------

# Count datasets only (a continuous proportion has no count representation, so
# ts_stage1's n_surv/n_total contract does not apply).
twostage_one <- function(df, label, cfg) {
  s1 <- bayesTLS::ts_stage1(
    data     = df,
    temp     = cfg$temp,
    duration = cfg$duration,
    n_surv   = cfg$n_surv,
    n_total  = cfg$n_total,
    family   = "betabinomial"
  )
  s2 <- bayesTLS::ts_stage2(s1, t_ref = cfg$tref, time_multiplier = 1)
  ci <- bayesTLS::ts_ci(s2, method = "delta", level = 0.95,
                        t_ref = cfg$tref, time_multiplier = 1, seed = SEED)
  # ts_ci(method = "delta") returns a NAMED LIST (verified against bayesTLS
  # 1.0.0): $z and $CTmax_1hr are each list(point, lower, upper, lower_t,
  # upper_t, se), plus $df_resid. The "$CTmax_1hr" name is a STATIC label; the
  # value is CTmax at the t_ref passed above (e.g. 240 min for dsuzukii). We use
  # the asymptotic-normal lower/upper (the textbook delta-method CI).
  ct <- ci$CTmax_1hr
  z  <- ci$z
  tibble::tibble(
    dataset   = label,
    parameter = c("CTmax", "z"),
    estimate  = c(ct$point, z$point),
    lower     = c(ct$lower, z$lower),
    upper     = c(ct$upper, z$upper)
  )
}

# ---- 6. build both paths over every dataset (and group level) -------------

# Expand a dataset config into the (sub-data, label) units the fits run on: the
# whole frame for an ungrouped dataset, or one unit per group level otherwise.
expand_units <- function(cfg) {
  if (is.null(cfg$group)) {
    return(list(list(df = cfg$data, label = cfg$key)))
  }
  g <- factor(cfg$data[[cfg$group]])
  lapply(levels(g), function(lv) {
    list(df = cfg$data[as.character(g) == lv, , drop = FALSE],
         label = paste0(cfg$key, ":", lv))
  })
}

bayes_rows <- list()
ts_rows    <- list()
for (cfg in datasets) {
  for (u in expand_units(cfg)) {
    message("Fitting bayesTLS: ", u$label)
    bayes_rows[[u$label]] <- fit_bayes_one(u$df, u$label, cfg)
    if (isTRUE(cfg$two_stage)) {
      message("Fitting two-stage: ", u$label)
      ts_rows[[u$label]] <- twostage_one(u$df, u$label, cfg)
    }
  }
}
bayesian  <- do.call(rbind, bayes_rows)
two_stage <- do.call(rbind, ts_rows)

# ---- 7. provenance meta ----------------------------------------------------

git_sha <- tryCatch(
  system2("git", c("-C", system.file(package = "bayesTLS"), "rev-parse", "HEAD"),
          stdout = TRUE, stderr = FALSE),
  error = function(e) NA_character_
)
if (length(git_sha) != 1L || !nzchar(git_sha)) {
  git_sha <- "unknown (install bayesTLS from a git checkout to record the SHA)"
}

cmdstan_version <- tryCatch(as.character(cmdstanr::cmdstan_version()),
                            error = function(e) NA_character_)

# Per-dataset provenance: the exact config each cached row was built under.
dataset_meta <- lapply(datasets, function(cfg) {
  list(
    key         = cfg$key,
    response    = cfg$response,
    family      = cfg$family$family %||% as.character(cfg$family),
    tref        = cfg$tref,
    time_unit   = cfg$time_unit,
    group       = cfg$group %||% NA_character_,
    target_surv = TARGET_SURV,
    two_stage   = isTRUE(cfg$two_stage)
  )
})
names(dataset_meta) <- vapply(datasets, function(cfg) cfg$key, character(1))

# Realized R-SHRIMP distribution (the corrected shrimp deaths the comparators
# were actually fitted to) -- a provenance tripwire against silent regression.
shrimp_deaths <- shrimp_lethal$total - shrimp_lethal$survived
rshrimp_note <- paste0(
  "Shrimp death counts are the R-SHRIMP-corrected reconstruction ",
  "(deaths = round(mortality_prop * total)); realized deaths range [",
  paste(range(shrimp_deaths), collapse = ", "), "], sum ", sum(shrimp_deaths),
  ", ", length(unique(shrimp_deaths)), " distinct values. The shipped bayesTLS ",
  "shrimp_lethal deaths collapse to {0, 1} (sum 35); see ",
  "data-raw/make_benchmark_data.R and R/data.R."
)

meta <- list(
  bayesTLS_version = as.character(utils::packageVersion("bayesTLS")),
  git_sha          = git_sha,
  cmdstan_version  = cmdstan_version,
  date_built       = as.character(Sys.Date()),
  seed             = SEED,
  config           = config,
  datasets         = dataset_meta,
  rshrimp_note     = rshrimp_note,
  freqTLS_note  = paste(
    "freqTLS is fitted LIVE in the vignette/test, not cached here. This",
    "cache holds only the bayesTLS posterior summaries and the classical",
    "two-stage summaries, both on the relative threshold + constant-shape",
    "config, with the reference time matched per dataset. The snow-gum PSII",
    "continuous-proportion endpoint has no count two-stage (bayesTLS only)."
  )
)

# ---- 8. write the cache ----------------------------------------------------

cache <- list(meta = meta, bayesian = bayesian, two_stage = two_stage)

out_dir <- file.path("inst", "extdata")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
out_path <- file.path(out_dir, "bayesTLS_benchmark_cache.rds")
saveRDS(cache, out_path)

message("Wrote ", out_path)
message("  bayesTLS_version: ", meta$bayesTLS_version,
        " | cmdstan: ", meta$cmdstan_version,
        " | git_sha: ", substr(meta$git_sha, 1, 12))
message("  ", rshrimp_note)
print(bayesian)
print(two_stage)
