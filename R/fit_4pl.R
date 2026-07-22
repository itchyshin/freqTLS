# The bayesTLS-analogue fitting facade. fit_4pl() shares bayesTLS::fit_4pl()'s
# user-facing API (the direct CTmax/z formula interface, `by`, `threshold`,
# `t_ref`, `bounds`, `family`) but fits by maximum likelihood through the freqTLS
# TMB engine (fit_tls) and returns a `freq_tls` workflow object that the quantity
# analogues (tls / extract_tdt / predict_*) read. The supported surface is similar to,
# but not a drop-in replacement for, bayesTLS.

#' Build a freqTLS 4PL formula from the direct CTmax/z interface
#'
#' Translates the bayesTLS-style direct-mode arguments (`ctmax`, `z`, `up`,
#' `low`, `k`, `by`) into the engine's [tls_bf()] `tls_formula` object. Supplying
#' a `ctmax` and/or `z` formula is the direct parameterisation; `by` is shorthand
#' for fixed cell means of CTmax and z by one moderator (`~ 0 + by`); it does
#' not add random effects or modify the shape formulas.
#'
#' Following the freqTLS constant-shape invariant, the asymptotes and steepness
#' (`up`, `low`, `k`) default to **shared** (`~ 1`) so the temperature effect runs
#' through the midpoint (CTmax / z) only; pass an explicit formula to let a shape
#' vary. `ctmax` and `z` must produce the same fixed-effect model-matrix columns.
#' Supported random intercepts go inside the `ctmax`/`z`/`low`/`k` formulas;
#' `up` random effects are not supported. For example,
#' `ctmax = ~ 1 + (1 | batch)` keeps the same intercept-only fixed design as the
#' default `z = ~ 1` while adding a `CTmax` random intercept.
#'
#' @param ctmax,z,up,low,k One-sided formulas (or `NULL`). `ctmax`/`z` set the
#'   CTmax / thermal-sensitivity structure and must have the same fixed-effect
#'   model-matrix columns; `up`/`low`/`k` set the 4PL shape. Random intercepts
#'   are supported on `ctmax`, `z`, `low`, and `k`, but not `up`.
#' @param by Optional single, non-missing moderator column name. It is shorthand
#'   for `ctmax = z = ~ 0 + by` when those are not given explicitly; it does not
#'   add random effects or modify `low`, `up`, or `k`.
#' @param family `"beta_binomial"`, `"binomial"`, or `"beta"` (selects the
#'   response idiom: `n_surv | trials(n_total)` for counts, bare `survival` for
#'   the continuous-proportion beta family).
#' @return A `tls_formula` object (as built by [tls_bf()]).
#' @seealso [fit_4pl()], [tls_bf()], [standardize_data()]
#' @examples
#' make_4pl_formula()
#' make_4pl_formula(by = "population", family = "binomial")
#' @export
make_4pl_formula <- function(ctmax = NULL, z = NULL, up = NULL, low = NULL,
                             k = NULL, by = NULL, family = "beta_binomial") {
  if (!is.null(by) && (!is.character(by) || length(by) != 1L || is.na(by) ||
                      !nzchar(by))) {
    cli::cli_abort(c(
      "{.arg by} must be one non-missing column name or {.code NULL}.",
      i = "For an interaction, create one moderator column in {.arg data} first."
    ))
  }
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
#' The frequentist analogue of `bayesTLS::fit_4pl()`. Consumes [standardize_data()]
#' output and fits the single-stage 4PL thermal-load-sensitivity model, parameterised
#' directly in CTmax and thermal sensitivity (z), via the freqTLS TMB engine.
#' Returns a `freq_tls` workflow object; uncertainty (Wald / profile / bootstrap)
#' is computed on demand by the quantity analogues ([tls()], `confint()`).
#'
#' @section Experimental software:
#' **Use freqTLS at your own risk.** Results and APIs may be incorrect or
#' change. Users are responsible for checking their data, design, model
#' specification, convergence, identifiability, diagnostics, and
#' interpretation. Important analyses should be independently refitted and
#' cross-checked with [bayesTLS](https://daniel1noble.github.io/bayesTLS/)
#' ([source repository](https://github.com/daniel1noble/bayesTLS)). Agreement
#' is a cross-check, not proof of correctness; shared data or model errors can
#' make both packages agree.
#'
#' @param data Output of [standardize_data()].
#' @param ctmax,z,up,low,k,by Direct-mode formula interface; see
#'   [make_4pl_formula()]. `by` gives fixed cell means for both `ctmax` and `z`.
#'   When `ctmax` and `z` are both supplied, their fixed-effect right-hand sides
#'   must produce the same model-matrix columns; their optional random-intercept
#'   terms may differ.
#' @param threshold `"relative"` (default; CTmax/z at the curve midpoint) or
#'   `"absolute"` (at the `p`-survival level). The fitting backbone currently
#'   accepts only `"relative"`; obtain absolute-threshold quantities post fit
#'   with [extract_tdt()] and `target_surv = "absolute"`.
#' @param p Survival level for the absolute threshold (default 0.5).
#' @param t_ref Positive reference exposure time at which CTmax is reported,
#'   in minutes. When `NULL` (the default), it is `60` minutes (one hour).
#'   [standardize_data()] converts the input duration to minutes; supply a
#'   numeric value such as `240` for a non-hour reference.
#' @param bounds Asymptote range. Only `c(0, 1)` is currently accepted. Supply
#'   survival as a probability in `[0, 1]` and let the model estimate `low` and
#'   `up` within that range; non-default bounds stop with an error.
#' @param family `"beta_binomial"` (default for counts), `"binomial"`, or
#'   `"beta"`. `NULL` picks beta for a proportion response, else beta-binomial.
#' @param method Default interval method for downstream extraction
#'   (`"profile"`, `"wald"`, or `"bootstrap"`); stored in the object.
#' @param start,control,trace,quiet Passed to the engine [fit_tls()].
#' @return A `freq_tls` object: a list with `$fit` (the engine fit), `$data`,
#'   `$formula`, and `$meta` (threshold, t_ref, bounds, temp_mean, response_type,
#'   family, grouped, moderators, method).
#' @section Before interpretation:
#' Run [check_tls()] before interpreting the fit. It gives a concrete recovery
#' action for each data-adequacy warning; `vignette("profile-likelihood")`
#' explains open profiles and the bootstrap fallback.
#'
#' @seealso [standardize_data()], [make_4pl_formula()], [fit_tls()], [check_tls()]
#' @examples
#' raw <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
#' dat <- standardize_data(
#'   raw, temp = "temp", duration = "duration",
#'   n_total = "total", n_surv = "survived"
#' )
#' fit <- fit_4pl(
#'   dat, family = "binomial", t_ref = 60, method = "wald", quiet = TRUE
#' )
#' coef(fit)
#' @export
fit_4pl <- function(data,
                    ctmax = NULL, z = NULL, up = NULL, low = NULL, k = NULL,
                    by = NULL,
                    threshold = c("relative", "absolute"),
                    p = 0.5, t_ref = NULL, bounds = c(0, 1),
                    family = NULL,
                    method = c("profile", "wald", "bootstrap"),
                    start = NULL, control = list(), trace = FALSE,
                    quiet = FALSE) {
  threshold <- match.arg(threshold)
  method <- match.arg(method)
  if (!is.numeric(p) || length(p) != 1L || !is.finite(p) || p <= 0 || p >= 1) {
    cli::cli_abort("{.arg p} must be one finite survival probability strictly between 0 and 1.")
  }

  meta_in <- attr(data, "tdt_meta")
  if (is.null(meta_in))
    cli::cli_abort(c(
      "{.arg data} must be the output of {.fn standardize_data}.",
      i = "Call {.code fit_4pl(standardize_data(raw, ...), ...)}."
    ))

  t_ref <- tls_resolve_tref(t_ref, meta_in)

  if (is.null(family))
    family <- if (identical(meta_in$response_type, "proportion"))
      "beta" else "beta_binomial"
  fam_name <- if (is.character(family)) family[1L] else family$family

  if (!identical(threshold, "relative"))
    cli::cli_abort(c(
      "{.code threshold = \"absolute\"} is not yet wired into the TMB backbone.",
      i = "Fit with {.code threshold = \"relative\"} (the default), then use {.fn extract_tdt} with {.code target_surv = \"absolute\"} for post-fit absolute-threshold quantities."
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
      input_duration_unit = meta_in$input_duration_unit,
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

#' @export
ranef.freq_tls <- function(object, ...) ranef(object$fit, ...)
