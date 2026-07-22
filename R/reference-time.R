# Reference-time resolution for the public fitting interfaces.
#
# CTmax is conventionally reported at one physical hour. standardize_data()
# converts supplied durations to minutes, so the public reference-time contract
# has one unambiguous unit: minutes.

#' Convert a recognised duration unit to minutes
#'
#' @param duration_unit A recognised unit label.
#' @return A positive multiplier that converts the input unit to minutes.
#' @keywords internal
#' @noRd
tls_minutes_multiplier <- function(duration_unit) {
  if (!is.character(duration_unit) || length(duration_unit) != 1L ||
      is.na(duration_unit) || !nzchar(trimws(duration_unit))) {
    cli::cli_abort("{.arg duration_unit} must name the unit of the input duration column.")
  }
  unit <- tolower(trimws(duration_unit))
  multipliers <- c(
    second = 1 / 60, seconds = 1 / 60, sec = 1 / 60, secs = 1 / 60,
    minute = 1, minutes = 1, min = 1, mins = 1,
    hour = 60, hours = 60, hr = 60, hrs = 60,
    day = 1440, days = 1440
  )
  if (!unit %in% names(multipliers)) {
    cli::cli_abort(c(
      "Cannot convert {.arg duration_unit} = {.val {duration_unit}} to minutes.",
      i = "Use seconds, minutes, hours, days, or a documented abbreviation."
    ))
  }
  unname(multipliers[[unit]])
}

#' Resolve the one-hour CTmax reference in minutes
#'
#' @param tref Optional positive numeric reference time.
#' @param tdt_meta Optional metadata attached by [standardize_data()].
#' @return A single positive numeric reference time.
#' @keywords internal
#' @noRd
tls_resolve_tref <- function(tref, tdt_meta = NULL) {
  if (!is.null(tref)) {
    if (!is.numeric(tref) || length(tref) != 1L || !is.finite(tref) || tref <= 0) {
      cli::cli_abort("{.arg tref} must be a single finite positive number or {.code NULL}.")
    }
    return(as.numeric(tref))
  }

  duration_unit <- if (is.null(tdt_meta)) NULL else tdt_meta$duration_unit
  if (is.null(duration_unit)) {
    cli::cli_warn(c(
      "No standardised duration metadata was available, so {.arg tref} defaults to 60 minutes.",
      i = "Supply {.code tref} explicitly in minutes, or use {.fn standardize_data} to convert the duration column to minutes."
    ))
    return(60)
  }
  if (!identical(duration_unit, "minutes"))
    cli::cli_abort("Standardized durations must be recorded in minutes.")
  60
}
