# Canonical bayesTLS comparator manifest and deterministic data preparation.
#
# This file is deliberately free of Stan/brms calls. The maintainer-only cache
# builder and the package tests both source it so the empirical filters,
# endpoints, formulas, thresholds, and reference times cannot drift apart.

CANONICAL_BAYESTLS_SHA <-
  "76510412e06c594c96894a1baba1f0e1a34a5aea"

CANONICAL_BAYESTLS_RENDER_DATE <- "2026-07-14"

CANONICAL_ANALYSIS_HASHES <- c(
  zebrafish_oxygen = "45fe4fd42c7b4790b9f269a96d1585a6e161c55859728e13e00eec65978c8e3b",
  aphid_age6 = "56b3bb57b9a8843ef1335e168560a89489ca95ede1d1b9d8eeadcf4a302ed771",
  aphid_all_age = "c438c91d51991b4aed9f218e7f0c1ad691f6e05c3a72f6f6109a1e9127a01c00",
  snowgum_psii = "d3bd0e30404c7bcad58342465e4c81bd17bb0bc2852ff60d6712c1bedd211a5c",
  drosophila_mortality = "210baa2d6531fa3375f8ea37e35d04085ac6cc4a05e0c031176fe41fed077e0b",
  drosophila_awake = "6b9ceb30413361c7127e85b7f3aafeab396e8bcbe8c4db07c9356908fb07a98c"
)

canonical_comparator_specs <- function() {
  list(
    zebrafish_oxygen = list(
      case_id = "zebrafish_oxygen",
      status = "canonical_mirror",
      source_object = "zebrafish_o2",
      licence = "CC BY 4.0",
      endpoint = "survival counts",
      subset = "ploidy == 'diploid' & oxygen %in% c('normoxia', 'hyperoxia')",
      family = "beta_binomial",
      response_type = "count",
      temp = "temp",
      duration = "duration_min",
      n_total = "n_total",
      n_surv = "n_surv",
      duration_unit = "minutes",
      by = "oxygen",
      formulas = list(
        ctmax = "~ 0 + oxygen",
        z = "~ 0 + oxygen",
        low = "~ 0 + oxygen",
        up = "~ 1",
        k = "~ 1"
      ),
      t_ref = 60,
      threshold = "relative",
      lethal = FALSE,
      chains = 4L,
      iter = 4000L,
      warmup = 2000L,
      adapt_delta = 0.95,
      max_treedepth = 12L
    ),
    aphid_age6 = list(
      case_id = "aphid_age6",
      status = "canonical_mirror",
      source_object = "aphid_tdt",
      licence = "CC0 1.0",
      endpoint = "survival counts",
      subset = "branch == 'heat' & age == '6'",
      family = "beta_binomial",
      response_type = "count",
      temp = "temp",
      duration = "duration_min",
      n_total = "n_total",
      n_surv = "n_surv",
      duration_unit = "minutes",
      by = "species",
      formulas = list(
        ctmax = "~ 0 + species",
        z = "~ 0 + species",
        low = "~ 1",
        up = "~ 1",
        k = "~ temp_c"
      ),
      t_ref = 60,
      threshold = "relative",
      lethal = FALSE,
      chains = 4L,
      iter = 4000L,
      warmup = 2000L,
      adapt_delta = 0.95,
      max_treedepth = 12L
    ),
    aphid_all_age = list(
      case_id = "aphid_all_age",
      status = "canonical_mirror",
      source_object = "aphid_tdt",
      licence = "CC0 1.0",
      endpoint = "survival counts",
      subset = "branch == 'heat'",
      family = "beta_binomial",
      response_type = "count",
      temp = "temp",
      duration = "duration_min",
      n_total = "n_total",
      n_surv = "n_surv",
      duration_unit = "minutes",
      by = c("species", "age"),
      formulas = list(
        ctmax = "~ 1 + species * age",
        z = "~ 1 + species * age",
        low = "~ 1",
        up = "~ 1",
        k = "~ temp_c"
      ),
      t_ref = 60,
      threshold = "relative",
      lethal = FALSE,
      chains = 4L,
      iter = 4000L,
      warmup = 2000L,
      adapt_delta = 0.95,
      max_treedepth = 12L
    ),
    snowgum_psii = list(
      case_id = "snowgum_psii",
      status = "frequentist_analogue",
      source_object = "snowgum_psii",
      licence = paste(
        "CC BY-NC 4.0 plus recorded non-commercial GitHub/pkgdown teaching",
        "authorization; CRAN/commercial redistribution remains blocked"
      ),
      endpoint = "retained PSII function proportion",
      subset = "all 394 documented rows",
      family = "beta",
      response_type = "proportion",
      temp = "Temp",
      duration = "Time",
      proportion = "fvfm_prop",
      duration_unit = "minutes",
      by = "recovery",
      formulas = list(
        ctmax = "~ 0 + recovery + (1 | plant)",
        z = "~ 0 + recovery",
        low = "~ 1",
        up = "~ 1",
        k = "~ 1"
      ),
      t_ref = 60,
      threshold = "relative",
      lethal = FALSE,
      pinned_call_difference = paste(
        "Locked freqTLS analogue uses shared low/up/k; the rendered pinned",
        "supplement inherits recovery-by-temperature shape terms."
      ),
      chains = 4L,
      iter = 6000L,
      warmup = 3000L,
      adapt_delta = 0.999,
      max_treedepth = 15L
    ),
    drosophila_mortality = list(
      case_id = "drosophila_mortality",
      status = "frequentist_analogue",
      source_object = "dsuzukii",
      licence = "CC BY 4.0",
      endpoint = "survival counts aggregated from dead",
      subset = "aggregate by temperature x duration x sex",
      family = "beta_binomial",
      response_type = "count",
      temp = "temp",
      duration = "duration",
      n_total = "n_total",
      n_surv = "n_surv",
      duration_unit = "minutes",
      by = "sex",
      formulas = list(
        ctmax = "~ 0 + sex",
        z = "~ 0 + sex",
        low = "~ temp_c",
        up = "~ temp_c",
        k = "~ temp_c"
      ),
      t_ref = 240,
      threshold = "absolute",
      fit_threshold = "relative",
      lethal = FALSE,
      comparison_scope = paste(
        "Joint direct model only; separate-sex teaching fits remain live",
        "example checks rather than additional cached comparator units."
      ),
      pinned_call_difference = paste(
        "Same direct model specification; this cache uses longer, more",
        "conservative sampling controls than the rendered pinned call."
      ),
      chains = 4L,
      iter = 4000L,
      warmup = 2000L,
      adapt_delta = 0.99,
      max_treedepth = 12L
    ),
    drosophila_awake = list(
      case_id = "drosophila_awake",
      status = "canonical_mirror",
      source_object = "dsuzukii",
      licence = "CC BY 4.0",
      endpoint = "awake counts (missing t_coma)",
      subset = paste(
        "aggregate by temperature x exposure level x sex;",
        "duration = first(time); duration > 0"
      ),
      family = "beta_binomial",
      response_type = "count",
      temp = "temp",
      duration = "duration",
      n_total = "n_total",
      n_surv = "n_awake",
      duration_unit = "minutes",
      by = "sex",
      formulas = list(
        ctmax = "~ sex",
        z = "~ sex",
        low = "~ temp_c",
        up = "~ temp_c",
        k = "~ temp_c"
      ),
      t_ref = 60,
      threshold = "relative",
      lethal = FALSE,
      pinned_call_difference = paste(
        "Same likelihood and nonlinear formulas through fit_4pl(); the",
        "rendered pinned supplement writes the equivalent brms::bf by hand."
      ),
      chains = 4L,
      iter = 4000L,
      warmup = 2000L,
      adapt_delta = 0.95,
      max_treedepth = 12L
    )
  )
}

canonical_source_data <- function(name) {
  getExportedValue("freqTLS", name)
}

canonical_prepare_data <- function(case_id) {
  specs <- canonical_comparator_specs()
  if (!case_id %in% names(specs)) {
    stop("Unknown canonical comparator case: ", case_id, call. = FALSE)
  }

  if (identical(case_id, "zebrafish_oxygen")) {
    x <- canonical_source_data("zebrafish_o2")
    x <- x[
      x$ploidy == "diploid" &
        x$oxygen %in% c("normoxia", "hyperoxia"),
      ,
      drop = FALSE
    ]
    x$ploidy <- droplevels(x$ploidy)
    x$oxygen <- droplevels(x$oxygen)
    return(x[order(x$oxygen, x$temp, x$duration_min, x$cohort), , drop = FALSE])
  }

  if (identical(case_id, "aphid_age6")) {
    x <- canonical_source_data("aphid_tdt")
    x <- x[x$branch == "heat" & x$age == "6", , drop = FALSE]
    x <- droplevels(x)
    return(x[order(x$species, x$temp, x$duration_min), , drop = FALSE])
  }

  if (identical(case_id, "aphid_all_age")) {
    x <- canonical_source_data("aphid_tdt")
    x <- droplevels(x[x$branch == "heat", , drop = FALSE])
    return(x[order(x$species, x$age, x$temp, x$duration_min), , drop = FALSE])
  }

  if (identical(case_id, "snowgum_psii")) {
    x <- canonical_source_data("snowgum_psii")
    return(x[order(x$recovery, x$plant, x$Temp, x$Time), , drop = FALSE])
  }

  if (identical(case_id, "drosophila_mortality")) {
    x <- canonical_source_data("dsuzukii")
    key <- interaction(x$temp, x$time, x$sex, drop = TRUE)
    out <- do.call(
      rbind,
      lapply(split(x, key), function(d) {
        data.frame(
          temp = d$temp[1],
          duration = d$time[1],
          sex = d$sex[1],
          n_total = nrow(d),
          n_surv = sum(d$dead == 0L)
        )
      })
    )
    rownames(out) <- NULL
    out$sex <- factor(out$sex, levels = levels(x$sex))
    return(out[order(out$sex, out$temp, out$duration), , drop = FALSE])
  }

  x <- canonical_source_data("dsuzukii")
  key <- interaction(x$temp, x$lvl, x$sex, drop = TRUE)
  out <- do.call(
    rbind,
    lapply(split(x, key), function(d) {
      data.frame(
        temp = d$temp[1],
        lvl = d$lvl[1],
        sex = d$sex[1],
        duration = d$time[1],
        n_total = nrow(d),
        n_awake = sum(is.na(d$t_coma))
      )
    })
  )
  rownames(out) <- NULL
  out <- out[out$duration > 0, , drop = FALSE]
  out$sex <- factor(out$sex, levels = levels(x$sex))
  out[order(out$sex, out$temp, out$lvl), , drop = FALSE]
}

canonical_hash <- function(x) {
  if (!requireNamespace("digest", quietly = TRUE)) {
    stop(
      "Canonical SHA-256 hashing requires the maintainer package 'digest'.",
      call. = FALSE
    )
  }
  if (!is.data.frame(x)) {
    stop(
      "Canonical comparator hashes are defined only for data frames.",
      call. = FALSE
    )
  }

  escape_text <- function(value) {
    value <- gsub("\\", "\\\\", value, fixed = TRUE)
    value <- gsub("\t", "\\t", value, fixed = TRUE)
    value <- gsub("\r", "\\r", value, fixed = TRUE)
    gsub("\n", "\\n", value, fixed = TRUE)
  }
  encode_column <- function(value) {
    if (is.factor(value) || is.character(value)) {
      out <- escape_text(as.character(value))
    } else if (is.double(value)) {
      out <- sprintf("%.17g", value)
    } else if (is.integer(value)) {
      out <- as.character(value)
    } else if (is.logical(value)) {
      out <- ifelse(value, "TRUE", "FALSE")
    } else {
      out <- escape_text(as.character(value))
    }
    out[is.na(value)] <- "<NA>"
    out
  }
  describe_column <- function(value, name) {
    type <- paste(class(value), collapse = "/")
    levels <- if (is.factor(value)) {
      paste0(";levels=", paste(escape_text(levels(value)), collapse = "|"))
    } else {
      ""
    }
    paste0(escape_text(name), "{", type, levels, "}")
  }

  encoded <- lapply(x, encode_column)
  rows <- if (nrow(x)) {
    do.call(paste, c(encoded, sep = "\t"))
  } else {
    character()
  }
  header <- paste(
    Map(describe_column, x, names(x)),
    collapse = "\t"
  )
  payload <- enc2utf8(paste(c(header, rows), collapse = "\n"))
  digest::digest(charToRaw(payload), algo = "sha256", serialize = FALSE)
}
