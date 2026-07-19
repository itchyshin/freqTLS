# The bayesTLS-analogue quantity extractor. tls() reshapes the freqTLS engine's
# CTmax / z estimates + confidence intervals into bayesTLS's tls() output
# contract (a `$summary` with quantity / median / lower / upper, one row per
# group x quantity, plus `$meta`). Shared names express a common scientific
# step, not drop-in object or uncertainty compatibility.

#' Thermal-load-sensitivity quantities (z, CTmax) with confidence intervals
#'
#' The frequentist analogue of `bayesTLS::tls()`. Reads a [fit_4pl()] (`freq_tls`)
#' fit and returns the headline thermal-load-sensitivity quantities — thermal
#' sensitivity `z` and `CTmax` — as point estimates with confidence intervals,
#' one row per group when the fit is grouped. Uncertainty uses the engine's
#' profile-likelihood intervals by default (or Wald / bootstrap via `method`).
#'
#' @param object A `freq_tls` fit from [fit_4pl()] (or a bare `profile_tls` fit
#'   from [fit_tls()]).
#' @param by Optional name for the grouping column in `$summary`; defaults to the
#'   fit's moderator (e.g. the `ctmax`/`z`/`by` factor).
#' @param params `"all"` (z and CTmax, the default), `"z"`, or `"ctmax"`.
#'   This selects only the returned headline quantities; use
#'   [tdt_parameter_table()] or [get_shape()] for `low`, `up`, and `k`.
#' @param target_surv Survival threshold for CTmax: `"relative"` (the curve
#'   midpoint, the default), `"absolute"` (50% survival), or a number in `(0, 1)`
#'   for an LTx. An absolute target must lie strictly between the fitted
#'   asymptotes for every reported group. Non-relative thresholds and `lethal`
#'   are derived per bootstrap replicate via [extract_tdt()].
#' @param lethal If `TRUE`, also report `T_crit` (the damage-rate-floor critical
#'   temperature); uses the bootstrap path.
#' @param method Interval method for the relative path: `"profile"` (default,
#'   from the fit's stored default), `"wald"`, or `"bootstrap"`. Absolute /
#'   `lethal` always use bootstrap.
#' @param level Confidence level (default 0.95).
#' @param nboot,TC_rate_range,seed Passed to [extract_tdt()] for the bootstrap
#'   path (absolute / LTx / `lethal`).
#' @param ... Passed from [tls_z()] / [tls_ctmax()] / [tls_tcrit()] to [tls()].
#' @return A `tls` object: a list with `$summary` (a tibble of
#'   `[<group>,] quantity, median, lower, upper`) and `$meta`.
#' @seealso [fit_4pl()], [tls_z()], [tls_ctmax()], [confint.profile_tls()]
#' @examples
#' raw <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
#' dat <- standardize_data(
#'   raw, temp = "temp", duration = "duration",
#'   n_total = "total", n_surv = "survived"
#' )
#' fit <- fit_4pl(
#'   dat, family = "binomial", t_ref = 1, method = "wald", quiet = TRUE
#' )
#' tls(fit)
#' tls_z(fit)
#' tls_ctmax(fit)
#' @export
tls <- function(object, by = NULL, params = c("all", "z", "ctmax"),
                target_surv = "relative", lethal = FALSE, method = NULL,
                level = 0.95, nboot = 1000L, TC_rate_range = c(0.1, 1),
                seed = NULL) {
  if (inherits(object, "freq_tls")) {
    fit <- object$fit; meta <- object$meta
  } else if (inherits(object, "profile_tls")) {
    fit <- object; meta <- list()
  } else {
    cli::cli_abort("{.arg object} must be a {.cls freq_tls} fit from {.fn fit_4pl} (or a {.cls profile_tls} fit).")
  }
  params <- match.arg(params)
  method <- method %||% meta$method %||% "profile"
  qsel <- switch(params, all = c("z", "CTmax"), z = "z", ctmax = "CTmax")

  # Absolute / LTx thresholds and T_crit are derived per bootstrap replicate;
  # delegate to extract_tdt() and flatten its nested summaries into the flat
  # tls() shape. The fast relative path below uses the profile/Wald coordinate CIs.
  if (!identical(target_surv, "relative") || isTRUE(lethal)) {
    et <- extract_tdt(object, target_surv = target_surv, lethal = lethal,
                      TC_rate_range = TC_rate_range, nboot = nboot,
                      level = level, seed = seed, by = by)
    summ <- tls_flatten_tdt(et, qsel, lethal)
    out <- list(
      summary = summ,
      meta = list(params = c(qsel, if (isTRUE(lethal)) "Tcrit"),
                  mode = et$meta$target_surv, method = "bootstrap", level = level,
                  by = et$meta$by, tref = fit$tref,
                  t_ref = meta$t_ref %||% fit$tref,
                  duration_unit = et$meta$duration_unit %||% meta$duration_unit,
                  temp_mean = meta$temp_mean)
    )
    class(out) <- c("tls", "list")
    return(out)
  }

  est <- fit$estimates
  pat <- paste0("^(", paste(qsel, collapse = "|"), ")(:|$)")
  rows <- est[grepl(pat, est$parameter), , drop = FALSE]
  ci <- suppressWarnings(
    confint(fit, parm = rows$parameter, level = level, method = method))
  idx <- match(rows$parameter, ci$parameter)

  quantity <- sub(":.*$", "", rows$parameter)
  by_name <- by %||% meta$moderators %||% "group"
  by_name <- by_name[1L]
  # A fit is grouped iff its quantity coefficients are level-tagged ("CTmax:lvl").
  # An ungrouped fit's single "all"/intercept level is NOT surfaced as a column.
  grouped <- any(grepl(":", rows$parameter))
  if (grouped) {
    # Clean cell-means coefficient labels (e.g. "speciesR_padi" -> "R_padi").
    grp <- rows$group
    if (!is.null(by_name)) {
      pre <- !is.na(grp) & startsWith(grp, by_name)
      grp[pre] <- sub(paste0("^", by_name), "", grp[pre])
    }
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
                level = level, by = if (grouped) by_name else NULL,
                tref = fit$tref, t_ref = meta$t_ref %||% fit$tref,
                duration_unit = meta$duration_unit %||% NULL,
                temp_mean = meta$temp_mean)
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

#' @rdname tls
#' @export
tls_tcrit <- function(object, ...) {
  r <- tls(object, params = "ctmax", lethal = TRUE, ...)
  r$summary <- r$summary[r$summary$quantity == "Tcrit", , drop = FALSE]
  r$meta$params <- "Tcrit"
  r
}

# Flatten an extract_tdt() result into the flat tls() $summary shape
# (quantity / [group] / median / lower / upper).
tls_flatten_tdt <- function(et, qsel, lethal) {
  byc <- et$meta$by
  one <- function(s, label, prefix) {
    cols <- list()
    if (!is.null(byc)) cols[[byc]] <- s[[byc]]
    cols$quantity <- label
    cols$median <- s[[paste0(prefix, "_median")]]
    cols$lower  <- s[[paste0(prefix, "_lower")]]
    cols$upper  <- s[[paste0(prefix, "_upper")]]
    as.data.frame(cols, stringsAsFactors = FALSE)
  }
  parts <- list()
  if ("z" %in% qsel)     parts <- c(parts, list(one(et$z$summary, "z", "z")))
  if ("CTmax" %in% qsel) parts <- c(parts, list(one(et$CTmax$summary, "CTmax", "temp")))
  if (isTRUE(lethal))    parts <- c(parts, list(one(et$T_crit$summary, "Tcrit", "temp")))
  tibble::as_tibble(do.call(rbind, parts))
}

#' @export
print.tls <- function(x, ...) {
  cat(sprintf("<tls> %s threshold; quantities: %s (%s intervals)\n",
              x$meta$mode, paste(x$meta$params, collapse = ", "), x$meta$method))
  print(x$summary)
  invisible(x)
}

#' Diagnose a freqTLS fit (frequentist analogue of `diagnose_tdt_fit`)
#'
#' The maximum-likelihood analogue of `bayesTLS::diagnose_tdt_fit()`: where the
#' Bayesian version reports Rhat / ESS / divergences, the freqTLS version reports
#' optimiser convergence, a positive-definite Hessian, and the gradient norm at
#' the optimum, with a single `all_pass` flag.
#'
#' @param object A `freq_tls` fit from [fit_4pl()] (or a `profile_tls` fit).
#' @return A one-row tibble of convergence diagnostics.
#' @seealso [fit_4pl()], [check_tls()]
#' @examples
#' raw <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
#' dat <- standardize_data(
#'   raw, temp = "temp", duration = "duration",
#'   n_total = "total", n_surv = "survived"
#' )
#' fit <- fit_4pl(dat, family = "binomial", t_ref = 1, quiet = TRUE)
#' diagnose_tdt_fit(fit)
#' @export
diagnose_tdt_fit <- function(object) {
  fit <- if (inherits(object, "freq_tls")) object$fit else object
  if (!inherits(fit, "profile_tls"))
    cli::cli_abort("{.arg object} must be a {.cls freq_tls} or {.cls profile_tls} fit.")
  conv <- fit$convergence
  g <- tryCatch(max(abs(fit$obj$gr(fit$opt$par))),
                error = function(e) NA_real_)
  converged    <- isTRUE(conv$code == 0L)
  pd_hessian   <- isTRUE(conv$pdHess)
  gradient_pass <- is.finite(g) && g < 1e-3
  tibble::tibble(
    converged        = converged,
    pd_hessian       = pd_hessian,
    max_abs_gradient = g,
    gradient_pass    = gradient_pass,
    optimizer        = conv$optimizer %||% NA_character_,
    logLik           = as.numeric(fit$logLik),
    n_params         = fit$df,
    AIC              = fit$AIC,
    all_pass         = converged && pd_hessian && gradient_pass
  )
}

#' 4PL parameter table (frequentist analogue of `tdt_parameter_table`)
#'
#' Returns the fitted 4PL parameters (`low`, `up`, `k`, `CTmax`, `z`, and `phi`
#' for over-dispersed families) as point estimates with confidence intervals, in
#' bayesTLS's `parameter / [group] / median / lower / upper` shape. `low` and
#' `up` are the fitted survival asymptotes, `k` is curve steepness, `CTmax` is
#' the critical thermal maximum at the reference time, `z` is thermal sensitivity
#' in degrees per decade of duration, and `phi` is beta/beta-binomial precision
#' or overdispersion. The `median` name is retained for table compatibility; for
#' frequentist Wald or profile output it contains the maximum-likelihood point
#' estimate, not a posterior median.
#'
#' @param object A `freq_tls` fit from [fit_4pl()] (or a `profile_tls` fit).
#' @param method Interval method: `"wald"` (default) or `"profile"`.
#' @param level Confidence level (default 0.95).
#' @return A tibble with `parameter`, `group`, `median`, `lower`, `upper`.
#' @seealso [tls()], [tidy_parameters()]
#' @examples
#' raw <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
#' dat <- standardize_data(
#'   raw, temp = "temp", duration = "duration",
#'   n_total = "total", n_surv = "survived"
#' )
#' fit <- fit_4pl(dat, family = "binomial", t_ref = 1, quiet = TRUE)
#' tdt_parameter_table(fit, method = "wald")
#' @export
tdt_parameter_table <- function(object, method = NULL, level = 0.95) {
  fit <- if (inherits(object, "freq_tls")) object$fit else object
  meta <- if (inherits(object, "freq_tls")) object$meta else list()
  method <- method %||% meta$method %||% "wald"
  method <- if (identical(method, "profile")) "profile" else "wald"
  tp <- tidy_parameters(fit, conf.int = TRUE, conf.level = level, method = method)
  tibble::tibble(parameter = tp$parameter, group = tp$group,
                 median = tp$estimate, lower = tp$conf.low, upper = tp$conf.high)
}
