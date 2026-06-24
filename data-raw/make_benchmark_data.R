# data-raw/make_benchmark_data.R
#
# Maintainer-run script. Builds the three vendored benchmark datasets that ship
# with freqTLS:
#
#   shrimp_lethal     -- brown shrimp (Crangon crangon) lethal thermal-death-time
#                        assay, R-SHRIMP-corrected counts (see below).
#   zebrafish_lethal  -- zebrafish (Danio rerio) lethal assay, by life stage.
#   snowgum_psii      -- snowgum (Eucalyptus pauciflora) PSII thermal-tolerance
#                        assay; a continuous proportion response (retained PSII
#                        function in (0, 1)) for the v0.2 beta family.
#
# All three datasets originate from the bayesTLS package (Noble, Arnold & Pottier,
# manuscript in preparation, https://github.com/daniel1noble/bayesTLS) and are
# redistributed here under CC BY 4.0. freqTLS code is GPL (>= 3); the data
# licence applies only to these datasets. Attribution: R/data.R, inst/CITATION,
# inst/COPYRIGHTS, README.
#
# This script needs only curl + base R + usethis. It does NOT need Stan or
# bayesTLS, so it can be run anywhere. It downloads the public source files from
# the bayesTLS GitHub at HEAD, reshapes them into the freqTLS column contract
#   fit_tls(y = survived, n = total, time = duration, temp = temp, group = )
# and writes data/shrimp_lethal.rda + data/zebrafish_lethal.rda via
# usethis::use_data(..., overwrite = TRUE).
#
# Run from the package root:
#   Rscript data-raw/make_benchmark_data.R
# or
#   source("data-raw/make_benchmark_data.R")
#
# ---------------------------------------------------------------------------
# The R-SHRIMP data bug (verified 2026-06-16 against bayesTLS @HEAD)
# ---------------------------------------------------------------------------
# The bayesTLS source CSV column `Mortality_after_trial` is a PROPORTION dead
# (e.g. 0.0909 = 1/11, 0.5 = 5/10, 0.9 = 9/10), not a count. The upstream
# build script data-raw/make_datasets.R mislabels it a "death count" (line ~25)
# and applies as.integer(...) (line ~34), which TRUNCATES every proportion
# below 1 to 0. The shipped bayesTLS `shrimp_lethal$Mortality_after_trial` is
# therefore an integer taking only the values {0, 1}: of 148 rows, 113 are 0 and
# 35 are 1, summing to 35 deaths. The CSV-correct reconstruction
# `round(proportion * N)` spans 0..11 and sums to 738 deaths -- i.e. the shipped
# data drops ~95% of the observed mortality, and 86 rows with a genuine non-zero
# death proportion < 1 are floored to zero.
#
# freqTLS fix: reconstruct deaths from the CSV proportion,
#   deaths   = round(Mortality_after_trial * N_individuals_after_trial)
#   survived = N_individuals_after_trial - deaths
# We keep the original proportion as `mortality_prop` for provenance, assert the
# rebuilt death distribution is sane (spans a real range, not collapsed to 0/1),
# and record the discrepancy here and in the benchmark cache meta block. A
# friendly upstream report is drafted in
# docs/dev-log/comparator-results/ (text only; not sent).
#
# Zebrafish is NOT affected: its upstream build sums daily mortality correctly,
# so we take the shipped object as-is.

# ---- 0. setup -------------------------------------------------------------

stopifnot(requireNamespace("usethis", quietly = TRUE))

base_url <- "https://raw.githubusercontent.com/daniel1noble/bayesTLS/HEAD"
shrimp_csv_url <- file.path(base_url, "inst/extdata/data_lethal_TDT_brown_shrimp.csv")
shrimp_rda_url <- file.path(base_url, "data/shrimp_lethal.rda")
zebra_rda_url  <- file.path(base_url, "data/zebrafish_lethal.rda")
snow_csv_url   <- file.path(base_url, "inst/extdata/data_function_PSII_TDT_snowgum.csv")

# Download into a local cache under data-raw/ rather than tempdir(): some
# sandboxed build environments block writes to the system temp directory.
# data-raw/.cache/ is git-ignored (see .gitignore) and may be deleted freely.
tmp <- file.path("data-raw", ".cache")
dir.create(tmp, showWarnings = FALSE, recursive = TRUE)

shrimp_csv_path <- file.path(tmp, "shrimp.csv")
shrimp_rda_path <- file.path(tmp, "shrimp_lethal.rda")
zebra_rda_path  <- file.path(tmp, "zebrafish_lethal.rda")
snow_csv_path   <- file.path(tmp, "snowgum.csv")

dl <- function(url, dest) {
  # Call the curl CLI directly (system2). The default download.file() libcurl
  # method can be blocked in sandboxed build environments; curl -o is robust.
  status <- system2("curl", c("-sSL", "-o", shQuote(dest), shQuote(url)))
  if (!identical(status, 0L) || !file.exists(dest) ||
      file.info(dest)$size == 0) {
    stop("Download failed or empty: ", url)
  }
  invisible(dest)
}

message("Downloading bayesTLS source files from ", base_url, " ...")
dl(shrimp_csv_url, shrimp_csv_path)
dl(shrimp_rda_url, shrimp_rda_path)
dl(zebra_rda_url,  zebra_rda_path)
dl(snow_csv_url,   snow_csv_path)

# ---- 1. shrimp: R-SHRIMP-corrected reconstruction from the CSV ------------

# fileEncoding handles the UTF-8 BOM on the first column name.
shrimp_raw <- utils::read.csv(shrimp_csv_path, fileEncoding = "UTF-8-BOM",
                              stringsAsFactors = FALSE)

needed <- c("Temperature_assay", "Duration_exposure_hours",
            "N_individuals_after_trial", "Mortality_after_trial")
missing <- setdiff(needed, names(shrimp_raw))
if (length(missing)) {
  stop("Shrimp CSV is missing expected columns: ",
       paste(missing, collapse = ", "))
}

prop  <- as.numeric(shrimp_raw$Mortality_after_trial)
total <- as.integer(shrimp_raw$N_individuals_after_trial)

# Sanity: the column really is a proportion in [0, 1], not a count.
if (any(prop < 0 | prop > 1, na.rm = TRUE)) {
  stop("Mortality_after_trial is outside [0, 1]; the R-SHRIMP assumption that ",
       "it is a proportion no longer holds. Re-inspect the upstream CSV before ",
       "rebuilding.")
}

deaths   <- round(prop * total)
survived <- total - deaths

shrimp_lethal <- data.frame(
  temp          = as.numeric(shrimp_raw$Temperature_assay),
  duration      = as.numeric(shrimp_raw$Duration_exposure_hours), # hours
  total         = total,
  survived      = as.integer(survived),
  mortality_prop = prop,   # provenance: the original CSV proportion
  stringsAsFactors = FALSE
)

# Drop rows with missing essentials (none expected, but be defensive).
ok <- stats::complete.cases(shrimp_lethal[, c("temp", "duration", "total", "survived")])
shrimp_lethal <- shrimp_lethal[ok, , drop = FALSE]
rownames(shrimp_lethal) <- NULL

# ---- 1a. R-SHRIMP assertion + before/after record ------------------------

# Compare against the SHIPPED (buggy) object to document the discrepancy.
shipped_env <- new.env()
load(shrimp_rda_path, envir = shipped_env)
shipped_shrimp <- shipped_env$shrimp_lethal
shipped_deaths <- shipped_shrimp$Mortality_after_trial

corrected_deaths <- shrimp_lethal$total - shrimp_lethal$survived

message("R-SHRIMP before/after:")
message("  shipped deaths: range [", paste(range(shipped_deaths), collapse = ", "),
        "], sum ", sum(shipped_deaths),
        ", unique values {", paste(sort(unique(shipped_deaths)), collapse = ", "), "}")
message("  corrected deaths: range [", paste(range(corrected_deaths), collapse = ", "),
        "], sum ", sum(corrected_deaths),
        ", ", length(unique(corrected_deaths)), " distinct values")

# The corrected counts MUST span a real range -- not collapse to {0, 1} as the
# shipped object does. If this assertion fires, the rebuild has silently
# regressed and the data must not be shipped.
if (length(unique(corrected_deaths)) <= 2L ||
    max(corrected_deaths) <= 1L) {
  stop("R-SHRIMP rebuild produced a collapsed death distribution ",
       "(<= 2 distinct values or max <= 1). Refusing to ship.")
}

# ---- 2. zebrafish: take the shipped object (build is correct) -------------

zebra_env <- new.env()
load(zebra_rda_path, envir = zebra_env)
zebra_raw <- zebra_env$zebrafish_lethal

zneeded <- c("assay_temp", "duration_h", "n_total", "n_surv", "n_dead", "life_stage")
zmissing <- setdiff(zneeded, names(zebra_raw))
if (length(zmissing)) {
  stop("Zebrafish object is missing expected columns: ",
       paste(zmissing, collapse = ", "))
}

# n_surv + n_dead must equal n_total (shipped build is correct).
if (!all(zebra_raw$n_surv + zebra_raw$n_dead == zebra_raw$n_total)) {
  stop("Zebrafish n_surv + n_dead != n_total; the shipped object is not as ",
       "expected. Re-inspect before vendoring.")
}

zebrafish_lethal <- data.frame(
  temp       = as.numeric(zebra_raw$assay_temp),
  duration   = as.numeric(zebra_raw$duration_h),  # hours
  total      = as.integer(zebra_raw$n_total),
  survived   = as.integer(zebra_raw$n_surv),
  life_stage = factor(zebra_raw$life_stage,
                      levels = c("young_embryos", "old_embryos", "larvae")),
  stringsAsFactors = FALSE
)
rownames(zebrafish_lethal) <- NULL

# ---- 2a. snowgum PSII: continuous proportion for the beta family ----------
#
# Unlike the lethal count assays, the snowgum data are a FUNCTIONAL endpoint:
# photosystem-II efficiency (Fv/Fm) before and after a temperature x duration
# exposure. The response is the RETAINED PSII proportion
#   prop = final_fvfm / initial_fvfm
# a continuous value in [0, 1] -- the natural input to the v0.2 beta family
# (fit_tls(y = prop, time = duration, temp = temp, family = "beta")). Duration is
# in MINUTES here (5-120), not hours; set `tref` accordingly when fitting.
#
# 60 of 319 rows have final_fvfm == 0 (complete PSII loss), so prop sits exactly
# at the 0 boundary; the beta likelihood is undefined at 0/1 and clamps those
# inward with a warning. We vendor the RAW proportion (zeros included) so the
# complete-loss observations are visible, not hidden by pre-clamping.

snow_raw <- utils::read.csv(snow_csv_path, stringsAsFactors = FALSE)

sneeded <- c("Temp", "Time", "initial_fvfm", "final_fvfm")
smissing <- setdiff(sneeded, names(snow_raw))
if (length(smissing)) {
  stop("Snowgum CSV is missing expected columns: ",
       paste(smissing, collapse = ", "))
}

snow_prop <- snow_raw$final_fvfm / snow_raw$initial_fvfm
if (any(snow_prop < 0 | snow_prop > 1, na.rm = TRUE)) {
  stop("Retained PSII proportion (final/initial Fv/Fm) is outside [0, 1]; ",
       "re-inspect the upstream snowgum CSV before rebuilding.")
}

snowgum_psii <- data.frame(
  temp     = as.numeric(snow_raw$Temp),
  duration = as.numeric(snow_raw$Time),   # MINUTES
  prop     = as.numeric(snow_prop),       # retained PSII = final/initial Fv/Fm
  stringsAsFactors = FALSE
)
ok_s <- stats::complete.cases(snowgum_psii)
snowgum_psii <- snowgum_psii[ok_s, , drop = FALSE]
rownames(snowgum_psii) <- NULL

message("Snowgum: ", nrow(snowgum_psii), " rows; ",
        sum(snowgum_psii$prop == 0), " complete-loss rows at prop == 0.")

# ---- 3. write the vendored datasets ---------------------------------------

usethis::use_data(shrimp_lethal, overwrite = TRUE)
usethis::use_data(zebrafish_lethal, overwrite = TRUE)
usethis::use_data(snowgum_psii, overwrite = TRUE)

message("Wrote data/shrimp_lethal.rda (", nrow(shrimp_lethal),
        " rows), data/zebrafish_lethal.rda (", nrow(zebrafish_lethal),
        " rows), and data/snowgum_psii.rda (", nrow(snowgum_psii), " rows).")
