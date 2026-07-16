# Build the pinned canonical bayesTLS comparator cache for experimental freqTLS 0.1.0.
#
# MAINTAINER ONLY. This script runs Stan and must never run on GitHub Actions.
# Raw brms fits and the first curated candidate are written outside the
# repository. Only a reviewed, small summary cache can be copied to
# inst/extdata/canonical_bayesTLS_cache.rds.
#
# Exact Totoro candidate-build invocation from a clean freqTLS checkout:
#
#   env OPENBLAS_NUM_THREADS=1 \
#     BAYESTLS_SOURCE_DIR="$HOME/bayesTLS-pinned" \
#     FREQTLS_BAYES_CORES=4 \
#     FREQTLS_CANONICAL_RAW_DIR="$HOME/freqtls-cache/76510412" \
#     Rscript data-raw/build_canonical_comparator_cache.R
#
# `FREQTLS_BAYES_CORES` is capped at 16 (well below Totoro's shared-server
# ceiling of 100). This script never publishes into inst/extdata. After an
# independent review, use publish_canonical_comparator_cache.R with the exact
# candidate SHA-256. Publication fails closed if any sampler diagnostic failed.

if (
  identical(Sys.getenv("CI"), "true") ||
    identical(Sys.getenv("GITHUB_ACTIONS"), "true")
) {
  stop(
    "Canonical bayesTLS cache construction is forbidden in CI.",
    call. = FALSE
  )
}

if (!identical(Sys.getenv("OPENBLAS_NUM_THREADS"), "1")) {
  stop("Set OPENBLAS_NUM_THREADS=1 before starting R on Totoro.", call. = FALSE)
}

needed <- c("brms", "cmdstanr", "digest", "dplyr", "pkgload", "posterior")
missing <- needed[!vapply(needed, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) {
  stop(
    "Missing maintainer dependencies: ",
    paste(missing, collapse = ", "),
    call. = FALSE
  )
}

source(file.path("data-raw", "canonical_comparator_manifest.R"))

cmdstan_version <- tryCatch(
  as.character(cmdstanr::cmdstan_version()),
  error = function(e) NA_character_
)
if (
  length(cmdstan_version) != 1L ||
    !nzchar(cmdstan_version) ||
    is.na(cmdstan_version)
) {
  stop("cmdstanr cannot find a working CmdStan installation.", call. = FALSE)
}

cores <- suppressWarnings(as.integer(Sys.getenv("FREQTLS_BAYES_CORES", "4")))
if (!is.finite(cores) || cores < 1L || cores > 16L) {
  stop(
    "FREQTLS_BAYES_CORES must be an integer from 1 through 16.",
    call. = FALSE
  )
}
options(mc.cores = cores)

raw_dir <- path.expand(Sys.getenv(
  "FREQTLS_CANONICAL_RAW_DIR",
  file.path("~", "freqtls-cache", substr(CANONICAL_BAYESTLS_SHA, 1, 12))
))
repo_root <- normalizePath(".", winslash = "/", mustWork = TRUE)
raw_parent <- normalizePath(dirname(raw_dir), winslash = "/", mustWork = FALSE)
if (startsWith(raw_parent, repo_root)) {
  stop(
    "FREQTLS_CANONICAL_RAW_DIR must be outside the repository.",
    call. = FALSE
  )
}
dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)

git_sha <- function(path = ".") {
  out <- tryCatch(
    system2(
      "git",
      c("-C", path, "rev-parse", "HEAD"),
      stdout = TRUE,
      stderr = FALSE
    ),
    error = function(e) NA_character_
  )
  if (length(out) == 1L && grepl("^[0-9a-f]{40}$", out)) out else NA_character_
}

freqtls_sha <- git_sha()
if (is.na(freqtls_sha)) {
  stop("Cannot record the exact freqTLS source commit.", call. = FALSE)
}

tracked_changes <- tryCatch(
  system2(
    "git",
    c("status", "--porcelain", "--untracked-files=all"),
    stdout = TRUE,
    stderr = FALSE
  ),
  error = function(e) "unknown"
)
if (length(tracked_changes) && any(nzchar(tracked_changes))) {
  stop(
    "Build from a clean, committed freqTLS worktree so the recorded SHA ",
    "identifies the manifest exactly.",
    call. = FALSE
  )
}

freqtls_version <- read.dcf(file.path(repo_root, "DESCRIPTION"))[, "Version"]
if (!identical(unname(freqtls_version), "0.1.0")) {
  stop(
    "Install the experimental freqTLS 0.1.0 candidate first.",
    call. = FALSE
  )
}

bayestls_source <- Sys.getenv("BAYESTLS_SOURCE_DIR")
if (!nzchar(bayestls_source) || !dir.exists(bayestls_source)) {
  stop(
    "BAYESTLS_SOURCE_DIR must point to the clean pinned bayesTLS checkout.",
    call. = FALSE
  )
}
bayestls_source <- normalizePath(
  bayestls_source,
  winslash = "/",
  mustWork = TRUE
)
bayestls_sha <- git_sha(bayestls_source)
if (!identical(bayestls_sha, CANONICAL_BAYESTLS_SHA)) {
  stop(
    "BAYESTLS_SOURCE_DIR is not at the pinned commit ",
    CANONICAL_BAYESTLS_SHA,
    ".",
    call. = FALSE
  )
}
bayestls_changes <- system2(
  "git",
  c("-C", bayestls_source, "status", "--porcelain", "--untracked-files=all"),
  stdout = TRUE,
  stderr = FALSE
)
if (length(bayestls_changes) && any(nzchar(bayestls_changes))) {
  stop(
    "BAYESTLS_SOURCE_DIR has tracked changes; provenance is not exact.",
    call. = FALSE
  )
}

# Load both packages from the verified source trees. This prevents a different
# installed namespace from being labelled with either recorded Git commit.
pkgload::load_all(repo_root, quiet = TRUE, export_all = FALSE, helpers = FALSE)
pkgload::load_all(
  bayestls_source,
  quiet = TRUE,
  export_all = FALSE,
  helpers = FALSE
)

specs <- canonical_comparator_specs()
seeds <- setNames(20260716L + seq_along(specs), names(specs))

as_formula <- function(x) stats::as.formula(x, env = baseenv())

standardize_case <- function(spec, dat) {
  args <- list(
    data = dat,
    temp = spec$temp,
    duration = spec$duration,
    duration_unit = spec$duration_unit
  )
  if (identical(spec$response_type, "proportion")) {
    args$proportion <- spec$proportion
  } else {
    args$n_total <- spec$n_total
    args$n_surv <- spec$n_surv
  }
  do.call(bayesTLS::standardize_data, args)
}

fit_case <- function(spec, dat, seed) {
  std <- standardize_case(spec, dat)
  fit_args <- list(
    data = std,
    ctmax = as_formula(spec$formulas$ctmax),
    z = as_formula(spec$formulas$z),
    low = as_formula(spec$formulas$low),
    up = as_formula(spec$formulas$up),
    k = as_formula(spec$formulas$k),
    threshold = spec$fit_threshold %||% "relative",
    t_ref = spec$t_ref,
    chains = spec$chains,
    iter = spec$iter,
    warmup = spec$warmup,
    cores = min(cores, spec$chains),
    seed = seed,
    backend = "cmdstanr",
    control = list(
      adapt_delta = spec$adapt_delta,
      max_treedepth = spec$max_treedepth
    ),
    file = file.path(raw_dir, paste0(spec$case_id, "-fit")),
    file_refit = "on_change",
    silent = 2,
    refresh = 100
  )
  if (identical(spec$family, "beta")) {
    fit_args$family <- brms::Beta(link = "identity")
  } else {
    fit_args$family <- brms::beta_binomial(link = "identity")
  }
  do.call(bayesTLS::fit_4pl, fit_args)
}

`%||%` <- function(x, y) if (is.null(x)) y else x

summarize_case <- function(fit, spec, seed) {
  out <- bayesTLS::tls(
    fit,
    by = spec$by,
    params = c("z", "ctmax"),
    target_surv = spec$threshold,
    t_ref = spec$t_ref,
    lethal = FALSE,
    ndraws = 2000,
    seed = seed
  )$summary
  names(out)[names(out) == "quantity"] <- "parameter"
  out$case_id <- spec$case_id
  out$endpoint <- spec$endpoint
  out$threshold <- spec$threshold
  out$t_ref <- spec$t_ref
  out$interval_method <- "bayesTLS posterior 95% credible interval"
  lead <- c("case_id", "endpoint", "threshold", "t_ref", "interval_method")
  out[c(lead, setdiff(names(out), lead))]
}

summary_rows <- list()
diagnostic_rows <- list()
case_meta <- list()

for (case_id in names(specs)) {
  spec <- specs[[case_id]]
  dat <- canonical_prepare_data(case_id)
  source_dat <- canonical_source_data(spec$source_object)
  observed_hash <- canonical_hash(dat)
  if (!identical(observed_hash, unname(CANONICAL_ANALYSIS_HASHES[[case_id]]))) {
    stop(
      "Canonical analysis hash changed for ",
      case_id,
      ". Audit the data/filter/aggregation before fitting.",
      call. = FALSE
    )
  }
  message("Fitting pinned bayesTLS canonical case: ", case_id)
  fit <- fit_case(spec, dat, seeds[[case_id]])
  summary_rows[[case_id]] <- summarize_case(fit, spec, seeds[[case_id]])

  diag <- as.data.frame(bayesTLS::diagnose_tdt_fit(fit))
  diag$case_id <- case_id
  diagnostic_rows[[case_id]] <- diag[c(
    "case_id",
    setdiff(names(diag), "case_id")
  )]

  case_meta[[case_id]] <- list(
    case_id = case_id,
    status = spec$status,
    source_object = spec$source_object,
    source_hash_sha256 = canonical_hash(source_dat),
    analysis_hash_sha256 = observed_hash,
    source_rows = nrow(source_dat),
    analysis_rows = nrow(dat),
    endpoint = spec$endpoint,
    licence = spec$licence,
    comparison_scope = spec$comparison_scope %||% "whole fitted unit",
    pinned_call_difference = spec$pinned_call_difference %||% "none",
    subset = spec$subset,
    family = spec$family,
    formulas = spec$formulas,
    grouping = spec$by,
    duration_unit = spec$duration_unit,
    t_ref = spec$t_ref,
    fit_threshold = spec$fit_threshold %||% "relative",
    reported_threshold = spec$threshold,
    reported_quantities = c("CTmax", "z"),
    seed = seeds[[case_id]],
    chains = spec$chains,
    iter = spec$iter,
    warmup = spec$warmup,
    adapt_delta = spec$adapt_delta,
    max_treedepth = spec$max_treedepth
  )
}

summaries <- dplyr::bind_rows(summary_rows)
rownames(summaries) <- NULL
diagnostics <- dplyr::bind_rows(diagnostic_rows)
rownames(diagnostics) <- NULL

diagnostic_failures <- diagnostics$case_id[!diagnostics$all_pass]
diagnostic_failures <- unique(as.character(diagnostic_failures))

cache <- list(
  meta = list(
    schema_version = 1L,
    purpose = paste(
      "Pinned canonical bayesTLS summaries for independent cross-checking;",
      "agreement with freqTLS is not proof of correctness."
    ),
    bayesTLS_version = as.character(utils::packageVersion("bayesTLS")),
    bayesTLS_git_sha = CANONICAL_BAYESTLS_SHA,
    bayesTLS_source_url = paste0(
      "https://github.com/daniel1noble/bayesTLS/tree/",
      CANONICAL_BAYESTLS_SHA
    ),
    supplement_url = "https://daniel1noble.github.io/bayesTLS/",
    supplement_render_date = CANONICAL_BAYESTLS_RENDER_DATE,
    freqTLS_version = unname(freqtls_version),
    freqTLS_git_sha = freqtls_sha,
    package_versions = vapply(
      c("bayesTLS", "brms", "cmdstanr", "posterior", "digest", "freqTLS"),
      function(pkg) as.character(utils::packageVersion(pkg)),
      character(1)
    ),
    cmdstan_version = cmdstan_version,
    R_version = as.character(getRversion()),
    platform = R.version$platform,
    date_built_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
    openblas_num_threads = Sys.getenv("OPENBLAS_NUM_THREADS"),
    bounded_cores = cores,
    cases = case_meta,
    diagnostic_all_pass = !length(diagnostic_failures),
    diagnostic_failures = diagnostic_failures,
    raw_fit_location = paste0(
      "Maintainer-local external directory; raw fits are not distributed. ",
      "Build root basename: ",
      basename(raw_dir),
      "."
    ),
    legacy_exclusion = paste(
      "Shrimp and life-stage zebrafish are unpublished benchmark-only legacy",
      "fixtures and are intentionally absent from this active cache."
    )
  ),
  summaries = summaries,
  diagnostics = diagnostics
)

candidate_path <- file.path(raw_dir, "canonical_bayesTLS_cache-candidate.rds")
saveRDS(cache, candidate_path, version = 3)
message("Wrote external review candidate: ", candidate_path)
message(
  "Candidate SHA-256: ",
  digest::digest(file = candidate_path, algo = "sha256")
)
if (length(diagnostic_failures)) {
  message(
    "NOT PUBLISHABLE: sampler diagnostics failed for ",
    paste(diagnostic_failures, collapse = ", "),
    ". Investigate and rebuild."
  )
} else {
  message(
    "Diagnostics pass. Review the candidate, then publish its exact SHA-256 ",
    "with data-raw/publish_canonical_comparator_cache.R."
  )
}
