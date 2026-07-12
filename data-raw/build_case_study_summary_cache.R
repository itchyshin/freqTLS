# Maintainer-only builder for the cross-case-study vignette cache.
# Run from the package root after changing the model, data, or profile algorithm.

devtools::load_all(".", quiet = TRUE)

load("data/shrimp_lethal.rda")
load("data/zebrafish_lethal.rda")
load("data/dsuzukii.rda")

shrimp_fit <- suppressWarnings(fit_4pl(standardize_data(
  shrimp_lethal,
  temp = "Temperature_assay", duration = "Duration_exposure_hours",
  n_total = "N_individuals_after_trial", mortality = "Mortality_after_trial",
  duration_unit = "hours"
), t_ref = 1, family = "beta_binomial", quiet = TRUE))$fit

zebra_fit <- suppressWarnings(fit_4pl(standardize_data(
  zebrafish_lethal,
  temp = "assay_temp", duration = "duration_h",
  n_total = "n_total", n_surv = "n_surv", duration_unit = "hours"
), by = "life_stage", t_ref = 1, family = "beta_binomial", quiet = TRUE))$fit

.nd <- aggregate(
  list(n_dead = dsuzukii$dead), dsuzukii[c("temp", "time", "sex")], sum
)
.nt <- aggregate(
  list(n_total = dsuzukii$dead), dsuzukii[c("temp", "time", "sex")], length
)
fly_fit <- suppressWarnings(fit_4pl(standardize_data(
  merge(.nd, .nt), temp = "temp", duration = "time",
  n_total = "n_total", n_dead = "n_dead", duration_unit = "minutes"
), by = "sex", t_ref = 240, family = "beta_binomial", quiet = TRUE))$fit

eye_rows <- function(fit, taxon, parms, labels) {
  ci <- suppressWarnings(suppressMessages(
    confint(fit, parm = parms, method = "profile", fallback = FALSE)
  ))
  data.frame(
    taxon = taxon,
    label = labels[match(ci$parameter, parms)],
    parameter = sub(":.*$", "", ci$parameter),
    estimate = ci$estimate,
    conf.low = ci$conf.low,
    conf.high = ci$conf.high,
    method = ci$method,
    status = ci$conf.status,
    stringsAsFactors = FALSE
  )
}

panel <- rbind(
  eye_rows(
    shrimp_fit, "Shrimp (1 h)", c("CTmax", "z"), c("Shrimp", "Shrimp")
  ),
  eye_rows(
    zebra_fit, "Zebrafish (1 h)",
    c(
      "CTmax:young_embryos", "CTmax:old_embryos", "CTmax:larvae",
      "z:young_embryos", "z:old_embryos", "z:larvae"
    ),
    c(
      "Zebrafish: young embryos", "Zebrafish: old embryos",
      "Zebrafish: larvae", "Zebrafish: young embryos",
      "Zebrafish: old embryos", "Zebrafish: larvae"
    )
  ),
  eye_rows(
    fly_fit, "D. suzukii (4 h)",
    c("CTmax:F", "CTmax:M", "z:F", "z:M"),
    c(
      "D. suzukii: female", "D. suzukii: male",
      "D. suzukii: female", "D. suzukii: male"
    )
  )
)

zebra_contrasts <- suppressWarnings(suppressMessages(confint(
  zebra_fit,
  parm = c(
    "dCTmax:old_embryos-young_embryos",
    "dCTmax:larvae-young_embryos",
    "dCTmax:larvae-old_embryos",
    "dz:old_embryos-young_embryos",
    "dz:larvae-young_embryos",
    "dz:larvae-old_embryos"
  ),
  method = "profile", fallback = TRUE, nboot = 1000L, boot_seed = 20260712L
)))
fly_contrasts <- suppressWarnings(suppressMessages(confint(
  fly_fit, parm = c("dCTmax:M-F", "dz:M-F"), method = "profile",
  fallback = TRUE, nboot = 1000L, boot_seed = 20260713L
)))

keep <- c(
  "parameter", "estimate", "conf.low", "conf.high", "method", "conf.status"
)
contrasts <- rbind(zebra_contrasts[, keep], fly_contrasts[, keep])

source_commit <- trimws(system("git rev-parse HEAD", intern = TRUE))
stopifnot(length(source_commit) == 1L, grepl("^[0-9a-f]{40}$", source_commit))

cache <- list(
  meta = list(
    schema_version = 1L,
    generated_on = "2026-07-12",
    freqTLS_version = as.character(utils::packageVersion("freqTLS")),
    freqTLS_source_commit = source_commit,
    R_version = R.version.string,
    TMB_version = as.character(utils::packageVersion("TMB")),
    input_md5 = as.list(tools::md5sum(c(
      "data/shrimp_lethal.rda", "data/zebrafish_lethal.rda", "data/dsuzukii.rda"
    ))),
    configuration = list(
      family = "beta_binomial",
      threshold = "relative midpoint",
      shape = "constant within each fit",
      shrimp = list(group = NULL, tref = 1, duration_unit = "hours"),
      zebrafish = list(group = "life_stage", tref = 1, duration_unit = "hours"),
      dsuzukii = list(group = "sex", tref = 240, duration_unit = "minutes"),
      headline_interval = list(method = "profile", fallback = FALSE),
      contrast_interval = list(
        method = "profile", fallback = TRUE, nboot = 1000L,
        seeds = list(zebrafish = 20260712L, dsuzukii = 20260713L)
      )
    )
  ),
  panel = panel,
  contrasts = contrasts
)

stopifnot(
  nrow(cache$panel) == 12L,
  nrow(cache$contrasts) == 8L,
  all(is.finite(cache$panel$estimate)),
  all(is.finite(cache$panel$conf.low)),
  all(is.finite(cache$panel$conf.high)),
  all(is.finite(cache$contrasts$estimate)),
  all(is.finite(cache$contrasts$conf.low)),
  all(is.finite(cache$contrasts$conf.high))
)

saveRDS(cache, "inst/extdata/case_study_summary_cache.rds", version = 3)
