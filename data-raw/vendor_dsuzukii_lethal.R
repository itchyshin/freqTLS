# data-raw/vendor_dsuzukii_lethal.R
#
# Maintainer-run script. Vendors the lethal-by-sex thermal-death-time counts for
# the vinegar fly Drosophila suzukii:
#
#   dsuzukii_lethal -- D. suzukii lethal mortality aggregated to counts per
#                      (temp, time, sex) cell, for the grouped-by-sex case study
#                      (Article E; see docs/dev-log/comparator-results/
#                      2026-06-17-bayesTLS-supplement-coverage-map.md, Part 5).
#
# The raw individual-level data ship inside the bayesTLS package (Noble, Arnold &
# Pottier, https://github.com/daniel1noble/bayesTLS) as data(dsuzukii); the
# primary deposit is Zenodo 10.5281/zenodo.10602268 (Orsted, Hoffmann, Sgro et
# al. 2024), licensed CC BY 4.0. They are redistributed here under CC BY 4.0; the
# data licence applies only to this dataset, while freqTLS code is GPL (>= 3).
# Attribution: R/data.R, inst/CITATION, inst/COPYRIGHTS, README.
#
# Like data-raw/make_benchmark_data.R, this script needs only curl + base R +
# usethis. It does NOT need Stan or bayesTLS. It downloads the public source file
# from the bayesTLS GitHub at HEAD, aggregates the LETHAL endpoint to counts, and
# reshapes into the freqTLS column contract
#   fit_tls(y = survived, n = total, time = time, temp = temp, group = sex)
# then writes data/dsuzukii_lethal.rda via usethis::use_data(overwrite = TRUE).
#
# Run from the package root:
#   Rscript data-raw/vendor_dsuzukii_lethal.R
# or
#   source("data-raw/vendor_dsuzukii_lethal.R")
#
# ---------------------------------------------------------------------------
# Lethal-endpoint aggregation (matches the bayesTLS supplement, lines 5436-5439)
# ---------------------------------------------------------------------------
# The raw dsuzukii object is long: one row per individual fly, with a binary
# mortality indicator `dead` (0/1), the assay temperature `temp` (C), the
# exposure duration `time` (MINUTES), and `sex` ("F"/"M"). The lethal endpoint is
# obtained by summing individuals to counts per (temp, time, sex) cell:
#   n_total = number of flies in the cell, n_dead = number that died.
# freqTLS additionally records survived = n_total - n_dead and ships the
# columns (temp, time, sex, total, survived) to match the shrimp/zebrafish
# contract (total/survived; sex as a factor). Time stays in MINUTES; the case
# study fits at tref = 4 h = 240 min with the absolute LT50 threshold, following
# Orsted Table 1. (The raw object also carries coma/productivity columns -- t_coma,
# prod, lvl -- which belong to the sublethal endpoints that are freqTLS
# non-goals and are dropped here.)

# ---- 0. setup -------------------------------------------------------------

stopifnot(requireNamespace("usethis", quietly = TRUE))

base_url <- "https://raw.githubusercontent.com/daniel1noble/bayesTLS/HEAD"
dsuzukii_rda_url <- file.path(base_url, "data/dsuzukii.rda")

# Download into a local cache under data-raw/ rather than tempdir(): some
# sandboxed build environments block writes to the system temp directory.
# data-raw/.cache/ is git-ignored (see .gitignore) and may be deleted freely.
tmp <- file.path("data-raw", ".cache")
dir.create(tmp, showWarnings = FALSE, recursive = TRUE)

dsuzukii_rda_path <- file.path(tmp, "dsuzukii.rda")

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

message("Downloading bayesTLS dsuzukii from ", base_url, " ...")
dl(dsuzukii_rda_url, dsuzukii_rda_path)

# ---- 1. load the raw individual-level object ------------------------------

dros_env <- new.env()
load(dsuzukii_rda_path, envir = dros_env)
dsuzukii_raw <- dros_env$dsuzukii

dneeded <- c("temp", "time", "sex", "dead")
dmissing <- setdiff(dneeded, names(dsuzukii_raw))
if (length(dmissing)) {
  stop("dsuzukii object is missing expected columns: ",
       paste(dmissing, collapse = ", "))
}

# `dead` must be a clean 0/1 mortality indicator and `sex` exactly {F, M}.
dead_vals <- sort(unique(dsuzukii_raw$dead))
if (!all(dead_vals %in% c(0, 1))) {
  stop("dsuzukii$dead is not a binary 0/1 indicator; got values {",
       paste(dead_vals, collapse = ", "), "}. Re-inspect before vendoring.")
}
sex_vals <- sort(unique(as.character(dsuzukii_raw$sex)))
if (!identical(sex_vals, c("F", "M"))) {
  stop("dsuzukii$sex is not exactly {F, M}; got {",
       paste(sex_vals, collapse = ", "), "}. Re-inspect before vendoring.")
}

# ---- 2. aggregate the LETHAL endpoint to counts per (temp, time, sex) -----

agg <- stats::aggregate(
  cbind(n_total = rep(1L, nrow(dsuzukii_raw)), n_dead = dsuzukii_raw$dead) ~
    temp + time + sex,
  data = dsuzukii_raw, FUN = sum
)
agg <- agg[order(agg$temp, agg$time, agg$sex), , drop = FALSE]

dsuzukii_lethal <- data.frame(
  temp     = as.numeric(agg$temp),
  time     = as.numeric(agg$time),          # MINUTES
  sex      = factor(as.character(agg$sex), levels = c("F", "M")),
  total    = as.integer(agg$n_total),
  survived = as.integer(agg$n_total - agg$n_dead),
  stringsAsFactors = FALSE
)
rownames(dsuzukii_lethal) <- NULL

# ---- 2a. sanity assertions ------------------------------------------------

n_dead <- dsuzukii_lethal$total - dsuzukii_lethal$survived

# Counts must be sane: every cell has at least one fly, and deaths are bounded
# by the cell size (0 <= n_dead <= n_total).
if (any(dsuzukii_lethal$total <= 0L)) {
  stop("Some (temp, time, sex) cells have n_total <= 0. Refusing to ship.")
}
if (any(n_dead < 0L) || any(n_dead > dsuzukii_lethal$total)) {
  stop("Some cells violate 0 <= n_dead <= n_total. Refusing to ship.")
}

# The design must span multiple temperatures and times for BOTH sexes -- a
# grouped-by-sex 4PL needs more than a single cell per group.
n_temps <- length(unique(dsuzukii_lethal$temp))
n_times <- length(unique(dsuzukii_lethal$time))
n_sexes <- nlevels(dsuzukii_lethal$sex)
if (n_temps < 2L || n_times < 2L || n_sexes != 2L) {
  stop("Expected multiple temps x multiple times x 2 sexes; got ",
       n_temps, " temps, ", n_times, " times, ", n_sexes, " sexes.")
}
cells_per_sex <- table(dsuzukii_lethal$sex)
if (any(cells_per_sex < 2L)) {
  stop("Each sex needs >= 2 cells to fit; got ",
       paste(names(cells_per_sex), as.integer(cells_per_sex), collapse = ", "), ".")
}

message("dsuzukii_lethal: ", nrow(dsuzukii_lethal), " cells; ",
        n_temps, " temps (", paste(range(dsuzukii_lethal$temp), collapse = "-"),
        " C), ", n_times, " times (", paste(round(range(dsuzukii_lethal$time)), collapse = "-"),
        " min), ", n_sexes, " sexes (F: ", cells_per_sex[["F"]], ", M: ",
        cells_per_sex[["M"]], " cells).")
message("  cell sizes: n_total range [", paste(range(dsuzukii_lethal$total), collapse = ", "),
        "], n_dead range [", paste(range(n_dead), collapse = ", "), "], ",
        sum(dsuzukii_lethal$total), " flies, ", sum(n_dead), " deaths total.")

# ---- 3. write the vendored dataset ----------------------------------------

usethis::use_data(dsuzukii_lethal, overwrite = TRUE)

message("Wrote data/dsuzukii_lethal.rda (", nrow(dsuzukii_lethal), " rows).")
