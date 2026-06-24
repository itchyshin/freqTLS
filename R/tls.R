# The bayesTLS-twin quantity extractor. tls() reshapes the freqTLS engine's
# CTmax / z estimates + confidence intervals into bayesTLS's tls() output
# contract (a `$summary` with quantity / median / lower / upper, one row per
# group x quantity, plus `$meta`). A bayesTLS script's tls() call should run on
# freqTLS unchanged for the relative-threshold quantities.

#' Thermal-load-sensitivity quantities (z, CTmax) with confidence intervals
#'
#' The frequentist twin of `bayesTLS::tls()`. Reads a [fit_4pl()] (`freq_tls`)
#' fit and returns the headline thermal-death-time quantities — thermal
#' sensitivity `z` and `CTmax` — as point estimates with confidence intervals,
#' one row per group when the fit is grouped. Uncertainty uses the engine's
#' profile-likelihood intervals by default (or Wald / bootstrap via `method`).
#'
#' @param object A `freq_tls` fit from [fit_4pl()] (or a bare `profile_tls` fit
#'   from [fit_tls()]).
#' @param by Optional name for the grouping column in `$summary`; defaults to the
#'   fit's moderator (e.g. the `ctmax`/`z`/`by` factor).
#' @param params `"all"` (z and CTmax, the default), `"z"`, or `"ctmax"`.
#' @param target_surv Survival threshold for CTmax: `"relative"` (the curve
#'   midpoint, the default). Absolute / LTx thresholds arrive with
#'   [extract_tdt()].
#' @param method Interval method: `"profile"` (default, from the fit's stored
#'   default), `"wald"`, or `"bootstrap"`.
#' @param level Confidence level (default 0.95).
#' @param ... Passed from [tls_z()] / [tls_ctmax()] to [tls()].
#' @return A `tls` object: a list with `$summary` (a tibble of
#'   `[<group>,] quantity, median, lower, upper`) and `$meta`.
#' @seealso [fit_4pl()], [tls_z()], [tls_ctmax()], [confint.profile_tls()]
#' @export
tls <- function(object, by = NULL, params = c("all", "z", "ctmax"),
                target_surv = "relative", method = NULL, level = 0.95) {
  if (inherits(object, "freq_tls")) {
    fit <- object$fit; meta <- object$meta
  } else if (inherits(object, "profile_tls")) {
    fit <- object; meta <- list()
  } else {
    cli::cli_abort("{.arg object} must be a {.cls freq_tls} fit from {.fn fit_4pl} (or a {.cls profile_tls} fit).")
  }
  params <- match.arg(params)
  method <- method %||% meta$method %||% "profile"
  if (!identical(target_surv, "relative"))
    cli::cli_abort(c(
      "Only {.code target_surv = \"relative\"} is available from {.fn tls} so far.",
      i = "Absolute (LT50) and LTx thresholds arrive with {.fn extract_tdt}."
    ))

  qsel <- switch(params, all = c("z", "CTmax"), z = "z", ctmax = "CTmax")
  est <- fit$estimates
  pat <- paste0("^(", paste(qsel, collapse = "|"), ")(:|$)")
  rows <- est[grepl(pat, est$parameter), , drop = FALSE]
  ci <- suppressWarnings(
    confint(fit, parm = rows$parameter, level = level, method = method))
  idx <- match(rows$parameter, ci$parameter)

  quantity <- sub(":.*$", "", rows$parameter)
  by_name <- by %||% meta$moderators %||% "group"
  by_name <- by_name[1L]
  # Clean cell-means coefficient labels (e.g. "speciesR_padi" -> "R_padi") to the
  # bare factor level when the moderator name is a clean prefix of every label.
  grp <- rows$group
  nn <- !is.na(grp)
  if (any(nn) && !is.null(by_name) && all(startsWith(grp[nn], by_name)))
    grp[nn] <- sub(paste0("^", by_name), "", grp[nn])
  if (any(nn)) {
    df <- data.frame(grp, quantity = quantity, median = rows$estimate,
                     lower = ci$conf.low[idx], upper = ci$conf.high[idx],
                     stringsAsFactors = FALSE)
    names(df)[1L] <- by_name
    summ <- tibble::as_tibble(df)
  } else {
    summ <- tibble::tibble(quantity = quantity, median = rows$estimate,
                           lower = ci$conf.low[idx], upper = ci$conf.high[idx])
  }

  out <- list(
    summary = summ,
    meta = list(params = qsel, mode = target_surv, method = method,
                level = level, by = if (any(!is.na(rows$group))) by_name else NULL,
                t_ref = meta$t_ref, temp_mean = meta$temp_mean)
  )
  class(out) <- c("tls", "list")
  out
}

#' @rdname tls
#' @export
tls_z <- function(object, ...) tls(object, params = "z", ...)

#' @rdname tls
#' @export
tls_ctmax <- function(object, ...) tls(object, params = "ctmax", ...)

#' @export
print.tls <- function(x, ...) {
  cat(sprintf("<tls> %s threshold; quantities: %s (%s intervals)\n",
              x$meta$mode, paste(x$meta$params, collapse = ", "), x$meta$method))
  print(x$summary)
  invisible(x)
}
