# The bayesTLS-twin fitting facade. fit_4pl() mirrors bayesTLS::fit_4pl()'s
# user-facing API (the direct CTmax/z formula interface, `by`, `threshold`,
# `t_ref`, `bounds`, `family`) but fits by maximum likelihood through the freqTLS
# TMB engine (fit_tls) and returns a `freq_tls` workflow object that the quantity
# twins (tls / extract_tdt / predict_*) read. A bayesTLS script should run on
# freqTLS by changing only the package the data + functions come from.

#' Build a freqTLS 4PL formula from the direct CTmax/z interface
#'
#' Translates the bayesTLS-style direct-mode arguments (`ctmax`, `z`, `up`,
#' `low`, `k`, `by`) into the engine's [tls_bf()] `tls_formula` object. Supplying
#' a `ctmax` and/or `z` formula is the direct parameterisation; `by` is shorthand
#' for grouping CTmax and z by a single moderator (`~ 0 + by`).
#'
#' Following the freqTLS constant-shape invariant, the asymptotes and steepness
#' (`up`, `low`, `k`) default to **shared** (`~ 1`) so the temperature effect runs
#' through the midpoint (CTmax / z) only; pass an explicit formula to let a shape
#' vary. Random effects go inside the `ctmax`/`z`/`up`/`low`/`k` formulas, e.g.
#' `ctmax = ~ 0 + grp + (1 | batch)`.
#'
#' @param ctmax,z,up,low,k One-sided formulas (or `NULL`). `ctmax`/`z` set the
#'   CTmax / thermal-sensitivity structure; `up`/`low`/`k` the 4PL shape.
#' @param by Optional single moderator column name; shorthand for
#'   `ctmax = z = ~ 0 + by` when those are not given explicitly.
#' @param family `"beta_binomial"`, `"binomial"`, or `"beta"` (selects the
#'   response idiom: `n_surv | trials(n_total)` for counts, bare `survival` for
#'   the continuous-proportion beta family).
#' @return A `tls_formula` object (as built by [tls_bf()]).
#' @seealso [fit_4pl()], [tls_bf()], [standardize_data()]
#' @export
make_4pl_formula <- function(ctmax = NULL, z = NULL, up = NULL, low = NULL,
                             k = NULL, by = NULL, family = "beta_binomial") {
  fam_name <- if (is.character(family)) family[1L] else family$family
  rhs <- function(f, default = "1") {
    if (is.null(f)) return(default)
    if (!inherits(f, "formula"))
      cli::cli_abort(c("{.arg ctmax}/{.arg z}/{.arg up}/{.arg low}/{.arg k} must be one-sided formulas or {.code NULL}.",
                       x = "Got {.cls {class(f)}}."))
    paste(deparse(f[[length(f)]]), collapse = " ")
  }
  if (!is.null(by)) {
    by_rhs <- paste0("0 + ", paste(by, collapse = ":"))
    if (is.null(ctmax)) ctmax <- stats::reformulate(by_rhs)
    if (is.null(z))     z     <- stats::reformulate(by_rhs)
  }
  resp <- if (identical(fam_name, "beta"))
    "survival ~ time(duration) + temp(temp)"
  else
    "n_surv | trials(n_total) ~ time(duration) + temp(temp)"
  structure(
    list(
      response = stats::as.formula(resp),
      sub_formulas = list(
        low   = stats::as.formula(paste("low   ~", rhs(low))),
        up    = stats::as.formula(paste("up    ~", rhs(up))),
        log_k = stats::as.formula(paste("log_k ~", rhs(k))),
        CTmax = stats::as.formula(paste("CTmax ~", rhs(ctmax))),
        log_z = stats::as.formula(paste("log_z ~", rhs(z)))
      ),
      env = parent.frame()
    ),
    class = "tls_formula"
  )
}

#' Fit the 4PL thermal-load-sensitivity model by maximum likelihood (TMB)
#'
#' The frequentist twin of `bayesTLS::fit_4pl()`. Consumes [standardize_data()]
#' output and fits the single-stage 4PL thermal death-time model, parameterised
#' directly in CTmax and thermal sensitivity (z), via the freqTLS TMB engine.
#' Returns a `freq_tls` workflow object; uncertainty (Wald / profile / bootstrap)
#' is computed on demand by the quantity twins ([tls()], `confint()`).
#'
#' @param data Output of [standardize_data()].
#' @param ctmax,z,up,low,k,by Direct-mode formula interface; see
#'   [make_4pl_formula()]. Supplying `ctmax`/`z` (or `by`) fits per-group CTmax/z.
#' @param threshold `"relative"` (default; CTmax/z at the curve midpoint) or
#'   `"absolute"` (at the `p`-survival level). *Absolute is wired into the
#'   backbone in a later step; for now use `"relative"` and convert post hoc.*
#' @param p Survival level for the absolute threshold (default 0.5).
#' @param t_ref Reference exposure time (in the data's `duration_unit`) at which
#'   CTmax is reported. Default 60 (e.g. minutes); use `t_ref = 1` for hours.
#' @param bounds Length-2 asymptote range `c(lower, upper)` (default `c(0, 1)`).
#' @param family `"beta_binomial"` (default for counts), `"binomial"`, or
#'   `"beta"`. `NULL` picks beta for a proportion response, else beta-binomial.
#' @param method Default interval method for downstream extraction
#'   (`"profile"`, `"wald"`, or `"bootstrap"`); stored in the object.
#' @param start,control,trace,quiet Passed to the engine [fit_tls()].
#' @return A `freq_tls` object: a list with `$fit` (the engine fit), `$data`,
#'   `$formula`, and `$meta` (threshold, t_ref, bounds, temp_mean, response_type,
#'   family, grouped, moderators, method).
#' @seealso [standardize_data()], [make_4pl_formula()], [fit_tls()]
#' @export
fit_4pl <- function(data,
                    ctmax = NULL, z = NULL, up = NULL, low = NULL, k = NULL,
                    by = NULL,
                    threshold = c("relative", "absolute"),
                    p = 0.5, t_ref = 60, bounds = c(0, 1),
                    family = NULL,
                    method = c("profile", "wald", "bootstrap"),
                    start = NULL, control = list(), trace = FALSE,
                    quiet = FALSE) {
  threshold <- match.arg(threshold)
  method <- match.arg(method)

  meta_in <- attr(data, "tdt_meta")
  if (is.null(meta_in))
    cli::cli_abort(c(
      "{.arg data} must be the output of {.fn standardize_data}.",
      i = "Call {.code fit_4pl(standardize_data(raw, ...), ...)}."
    ))

  if (is.null(family))
    family <- if (identical(meta_in$response_type, "proportion"))
      "beta" else "beta_binomial"
  fam_name <- if (is.character(family)) family[1L] else family$family

  if (!identical(threshold, "relative"))
    cli::cli_abort(c(
      "{.code threshold = \"absolute\"} is not yet wired into the TMB backbone.",
      i = "Fit with {.code threshold = \"relative\"} (the default); the absolute (p-survival) CTmax/z will be available via {.fn extract_tdt} once that path lands."
    ))
  if (!isTRUE(all.equal(as.numeric(bounds), c(0, 1))))
    cli::cli_abort(c(
      "Non-default {.arg bounds} are not yet wired through the engine.",
      i = "Use the default {.code bounds = c(0, 1)} for now."
    ))

  ff <- make_4pl_formula(ctmax = ctmax, z = z, up = up, low = low, k = k,
                         by = by, family = fam_name)
  fit <- fit_tls(ff, data = data, family = fam_name, tref = t_ref,
                 start = start, control = control, trace = trace, quiet = quiet)

  moderators <- by
  if (is.null(moderators) && !is.null(ctmax))
    moderators <- setdiff(all.vars(ctmax), c("temp_c", "temp"))
  out <- list(
    fit = fit,
    data = data,
    formula = ff,
    meta = list(
      threshold     = threshold,
      p             = p,
      t_ref         = t_ref,
      bounds        = bounds,
      temp_mean     = meta_in$temp_mean,
      duration_unit = meta_in$duration_unit,
      response_type = meta_in$response_type,
      family        = fam_name,
      grouped       = isTRUE(fit$data_summary$grouped),
      moderators    = moderators,
      method        = method
    )
  )
  class(out) <- "freq_tls"
  out
}

#' @export
print.freq_tls <- function(x, ...) {
  m <- x$meta
  cat("<freq_tls>\n")
  cat(sprintf("  Data:    %d rows; %d temperatures; %d durations\n",
              nrow(x$data), length(unique(x$data$temp)),
              length(unique(x$data$duration))))
  cat(sprintf("  T_bar:   %.2f\n", m$temp_mean))
  cat(sprintf("  Family:  %s (%s threshold, t_ref = %g %s)\n",
              m$family, m$threshold, m$t_ref, m$duration_unit %||% "units"))
  if (!is.null(m$moderators))
    cat(sprintf("  By:      %s\n", paste(m$moderators, collapse = ", ")))
  conv <- x$fit$convergence
  cat(sprintf("  Fit:     %s (pdHess = %s); default CI method = %s\n",
              if (isTRUE(conv$code == 0)) "converged" else "NOT converged",
              isTRUE(conv$pdHess), m$method))
  invisible(x)
}

# S3 generics delegate from the freq_tls workflow to its engine fit, so
# coef()/logLik()/vcov()/nobs()/confint()/summary() work on the object
# fit_4pl() returns.

#' @importFrom stats coef
#' @export
coef.freq_tls <- function(object, ...) stats::coef(object$fit, ...)

#' @importFrom stats logLik
#' @export
logLik.freq_tls <- function(object, ...) stats::logLik(object$fit, ...)

#' @importFrom stats vcov
#' @export
vcov.freq_tls <- function(object, ...) stats::vcov(object$fit, ...)

#' @importFrom stats nobs
#' @export
nobs.freq_tls <- function(object, ...) stats::nobs(object$fit, ...)

#' @importFrom stats confint
#' @export
confint.freq_tls <- function(object, ...) stats::confint(object$fit, ...)

#' @export
summary.freq_tls <- function(object, ...) summary(object$fit, ...)
