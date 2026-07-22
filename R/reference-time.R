# Reference-time resolution for the public fitting interfaces.
#
# CTmax is conventionally reported at one physical hour. A standardized data
# object records the native duration unit, so an omitted reference time can be
# resolved safely without rewriting the observed durations.

#' Resolve the one-hour CTmax reference in a data object's native time unit
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
  if (is.null(duration_unit) || length(duration_unit) != 1L ||
      is.na(duration_unit) || !nzchar(trimws(as.character(duration_unit)))) {
    cli::cli_warn(c(
      "No {.arg duration_unit} metadata was available, so {.arg tref} defaults to 1 native time unit.",
      i = "Supply {.code tref} explicitly, or use {.fn standardize_data} with a recognised {.arg duration_unit}, to report CTmax at one physical hour."
    ))
    return(1)
  }

  unit <- tolower(trimws(as.character(duration_unit)))
  one_hour <- c(
    second = 3600, seconds = 3600, sec = 3600, secs = 3600,
    minute = 60, minutes = 60, min = 60, mins = 60,
    hour = 1, hours = 1, hr = 1, hrs = 1,
    day = 1 / 24, days = 1 / 24
  )
  if (!unit %in% names(one_hour)) {
    cli::cli_abort(c(
      "Cannot resolve a one-hour {.arg tref} from {.arg duration_unit} = {.val {duration_unit}}.",
      i = "Supply a positive numeric {.arg tref} in the duration column's unit."
    ))
  }
  unname(one_hour[[unit]])
}
