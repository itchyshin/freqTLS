#' S3 methods for fitted freqTLS models
#'
#' Standard extractor and display methods for the `profile_tls` object returned
#' by [fit_tls()]: `print`, `summary`, `coef`, `vcov`, `logLik`, `AIC`, and
#' `nobs`. They mirror the drmTMB method idioms
#' (`drmTMB::R/methods.R:2-40,1826-1864,2025-2037`).
#'
#' @name profile_tls-methods
#' @keywords internal
NULL

#' @describeIn profile_tls-methods Print a compact, readable summary: the call,
#'   the family, `tref`, the data summary, the natural-scale estimates table,
#'   and the convergence state.
#' @param x A `profile_tls` fit from [fit_tls()].
#' @param digits Number of significant digits for the estimates table.
#' @param ... Ignored.
#' @return `print` and `summary` return their input invisibly / the summary
#'   object; the extractors return the quantities named in their titles.
#' @export
print.profile_tls <- function(x, digits = 4, ...) {
  cli::cli_text("<freqTLS {x$family$family} 4PL fit>")
  cli::cli_text("Call: {paste(deparse(x$call), collapse = ' ')}")

  ds <- x$data_summary
  group_txt <- if (isTRUE(ds$grouped)) {
    paste0(ds$n_groups, " group", if (ds$n_groups != 1L) "s" else "",
           " (", paste(x$group_levels, collapse = ", "), ")")
  } else {
    "ungrouped"
  }
  cli::cli_text("Reference time (tref): {x$tref}  |  CTmax defined at this time")
  cli::cli_text(
    "Data: {ds$n_obs} observation{?s}, {group_txt}; ",
    "{ds$n_temps} temperature{?s} in [{tls_fmt(ds$temp_range[1], digits)}, ",
    "{tls_fmt(ds$temp_range[2], digits)}], ",
    "{ds$n_times} duration{?s} in [{tls_fmt(ds$time_range[1], digits)}, ",
    "{tls_fmt(ds$time_range[2], digits)}]"
  )
  if (identical(x$family$family, "beta")) {
    cli::cli_text(
      "      mean observed proportion {tls_fmt(ds$total_successes / ds$n_obs, digits)}"
    )
  } else {
    cli::cli_text(
      "      {ds$total_successes} survivor{?s} of {ds$total_trials} trial{?s}"
    )
  }
  for (blk in tls_re_blocks(x)) {
    cli::cli_text(
      "Random intercept on {blk$param}: (1 | {blk$spec$group_var}), {blk$spec$n} group{?s}"
    )
  }

  cat("\n")
  est <- x$estimates
  out <- data.frame(
    parameter = est$parameter,
    group = ifelse(is.na(est$group), "", est$group),
    estimate = signif(est$estimate, digits),
    std.error = signif(est$std.error, digits),
    stringsAsFactors = FALSE
  )
  print(out, row.names = FALSE)

  cat("\n")
  cv <- x$convergence
  ok <- identical(cv$code, 0L) && isTRUE(cv$pdHess)
  status <- if (ok) "converged (pdHess)" else "CHECK CONVERGENCE"
  cli::cli_text(
    "Optimiser: {cv$optimizer} | code {cv$code} | pdHess {cv$pdHess} | {status}"
  )
  if (!is.na(cv$message)) cli::cli_text("Message: {cv$message}")
  cli::cli_text(
    "logLik {tls_fmt(x$logLik, digits)} | df {x$df} | AIC {tls_fmt(x$AIC, digits)}"
  )
  invisible(x)
}

#' @describeIn profile_tls-methods Build a `summary.profile_tls` object carrying
#'   the estimates table (with Wald z-statistics and p-values), the family,
#'   `tref`, the data summary, and the convergence state.
#' @param object A `profile_tls` fit from [fit_tls()].
#' @export
summary.profile_tls <- function(object, ...) {
  est <- object$estimates
  z <- est$estimate / est$std.error
  pval <- 2 * stats::pnorm(abs(z), lower.tail = FALSE)
  coefficients <- data.frame(
    parameter = est$parameter,
    group = est$group,
    estimate = est$estimate,
    std.error = est$std.error,
    statistic = z,
    p.value = pval,
    stringsAsFactors = FALSE
  )
  structure(
    list(
      call = object$call,
      family = object$family,
      tref = object$tref,
      group_levels = object$group_levels,
      data_summary = object$data_summary,
      coefficients = coefficients,
      logLik = object$logLik,
      df = object$df,
      AIC = object$AIC,
      convergence = object$convergence
    ),
    class = "summary.profile_tls"
  )
}

#' @describeIn profile_tls-methods Print a `summary.profile_tls` object.
#' @export
print.summary.profile_tls <- function(x, digits = 4, ...) {
  cli::cli_text("<freqTLS {x$family$family} 4PL fit>  summary")
  cli::cli_text("Call: {paste(deparse(x$call), collapse = ' ')}")

  ds <- x$data_summary
  group_txt <- if (isTRUE(ds$grouped)) {
    paste0(ds$n_groups, " group", if (ds$n_groups != 1L) "s" else "",
           " (", paste(x$group_levels, collapse = ", "), ")")
  } else {
    "ungrouped"
  }
  cli::cli_text("Reference time (tref): {x$tref}  |  family: {x$family$family}")
  cli::cli_text("Data: {ds$n_obs} observation{?s}, {group_txt}")

  cat("\nCoefficients (natural scale; Wald z-test):\n")
  co <- x$coefficients
  out <- data.frame(
    parameter = co$parameter,
    group = ifelse(is.na(co$group), "", co$group),
    estimate = signif(co$estimate, digits),
    std.error = signif(co$std.error, digits),
    `z value` = signif(co$statistic, digits),
    `Pr(>|z|)` = signif(co$p.value, digits),
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  print(out, row.names = FALSE)

  cat("\n")
  cv <- x$convergence
  ok <- identical(cv$code, 0L) && isTRUE(cv$pdHess)
  status <- if (ok) "converged (pdHess)" else "CHECK CONVERGENCE"
  cli::cli_text(
    "Optimiser: {cv$optimizer} | code {cv$code} | pdHess {cv$pdHess} | {status}"
  )
  cli::cli_text(
    "logLik {tls_fmt(x$logLik, digits)} | df {x$df} | AIC {tls_fmt(x$AIC, digits)}"
  )
  invisible(x)
}

#' @describeIn profile_tls-methods Extract natural-scale point estimates. With
#'   `complete = FALSE` (default) a named numeric vector; with `complete = TRUE`
#'   the full `estimates` data frame (parameter, group, estimate, std.error).
#' @param complete Logical; return the full estimates data frame instead of a
#'   named vector.
#' @export
coef.profile_tls <- function(object, complete = FALSE, ...) {
  est <- object$estimates
  if (isTRUE(complete)) {
    return(est)
  }
  stats::setNames(est$estimate, est$parameter)
}

#' @describeIn profile_tls-methods The variance-covariance matrix of the
#'   internal (unconstrained) coordinates, from [TMB::sdreport()]. Returns
#'   `NULL` (with a warning) when the `sdreport` did not produce a covariance.
#' @export
vcov.profile_tls <- function(object, ...) {
  vc <- object$vcov
  if (is.null(vc)) {
    cli::cli_warn(c(
      "The standard-error report (sdreport) did not produce a covariance.",
      i = "The Hessian was not positive-definite at the optimum; refit and check convergence."
    ))
    return(NULL)
  }
  vc
}

#' @describeIn profile_tls-methods The maximised log-likelihood, as a `logLik`
#'   object with `df` and `nobs` attributes so [stats::AIC()] and
#'   [stats::BIC()] work.
#' @export
logLik.profile_tls <- function(object, ...) {
  val <- object$logLik
  attr(val, "df") <- object$df
  attr(val, "nobs") <- object$data_summary$n_obs
  class(val) <- "logLik"
  val
}

#' @describeIn profile_tls-methods Akaike's An Information Criterion. With the
#'   default `k = 2` this returns the stored `AIC`; other `k` are computed from
#'   the log-likelihood and `df`.
#' @param k Penalty per parameter (default `2`, giving the AIC).
#' @export
AIC.profile_tls <- function(object, ..., k = 2) {
  if (isTRUE(all.equal(k, 2))) {
    return(object$AIC)
  }
  -2 * object$logLik + k * object$df
}

#' @describeIn profile_tls-methods The number of observations (temperature-by-
#'   duration cells) used in the fit.
#' @export
nobs.profile_tls <- function(object, ...) {
  object$data_summary$n_obs
}

#' Random-effect BLUPs (conditional modes) for a freqTLS fit
#'
#' `ranef()` returns the predicted random intercepts (the conditional modes /
#' BLUPs) with their conditional standard errors, for a fit with a random
#' intercept on any of `CTmax`, `log_z`, `low`, or `log_k`
#' (`<param> ~ <fixed> + (1 | group)`). It errors for a fixed-effects-only fit.
#' Each BLUP is a deviation on its coordinate's internal scale: `CTmax` in degrees
#' C, `log_z` on `log(z)`, `low` on `logit(low)`, `log_k` on `log(k)`. When several
#' REs are present the rows are stacked in `CTmax`, `log_z`, `low`, `log_k` order.
#'
#' @param object A `profile_tls` fit from [fit_tls()] with a random intercept.
#' @param ... Reserved; must be empty.
#' @return A [tibble][tibble::tibble] with one row per group level (per RE term):
#'   `group`, `term` (`"CTmax"`, `"log_z"`, `"low"`, or `"log_k"`), `estimate` (the
#'   BLUP), and `std.error` (the conditional SE).
#' @examples
#' d <- simulate_tls(family = "binomial", CTmax = 36, z = 4,
#'                   re_sd = 1.5, n_re_groups = 12, seed = 42)
#' fit <- fit_tls(
#'   tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
#'          CTmax ~ 1 + (1 | colony)),
#'   data = d, family = "binomial", tref = 1)
#' ranef(fit)
#' @export
ranef <- function(object, ...) {
  UseMethod("ranef")
}

#' @rdname ranef
#' @export
ranef.profile_tls <- function(object, ...) {
  dots <- list(...)
  if (length(dots) > 0L) {
    cli::cli_abort("{.arg ...} is reserved; pass only documented arguments.")
  }
  blocks <- tls_re_blocks(object)
  if (length(blocks) == 0L) {
    cli::cli_abort(c(
      "This fit has no random effects.",
      i = "Add a random intercept on `CTmax`, `log_z`, `low`, or `log_k`, e.g. {.code CTmax ~ <fixed> + (1 | group)}."
    ))
  }
  sdr <- object$sdreport
  if (is.null(sdr)) {
    cli::cli_abort(c(
      "The standard-error report (sdreport) is unavailable for this fit.",
      i = "Refit and check convergence (pdHess)."
    ))
  }
  sm <- summary(sdr, select = "random")
  parts <- lapply(blocks, function(bk) {
    rows <- which(rownames(sm) == bk$b_name)
    if (length(rows) != bk$spec$n) {
      cli::cli_abort("Internal: expected {bk$spec$n} {bk$term} random intercept{?s}, found {length(rows)}.")
    }
    tibble::tibble(
      group = bk$spec$group_levels,
      term = bk$term,
      estimate = unname(sm[rows, "Estimate"]),
      std.error = unname(sm[rows, "Std. Error"])
    )
  })
  tibble::as_tibble(do.call(rbind, parts))
}

#' Format a numeric scalar for printed method output
#'
#' @param x Numeric scalar (or `NA`).
#' @param digits Significant digits.
#' @return A length-1 character string.
#' @keywords internal
#' @noRd
tls_fmt <- function(x, digits = 4) {
  if (length(x) == 0L || is.na(x)) return("NA")
  format(signif(x, digits), trim = TRUE)
}
