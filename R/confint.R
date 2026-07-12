#' Confidence intervals for a fitted thermal-load-sensitivity model
#'
#' `confint()` returns confidence intervals for the natural-scale parameters of a
#' [fit_tls()] model. Three methods are available:
#'
#' * `method = "profile"` (default) computes profile-likelihood confidence
#'   intervals by inverting the likelihood-ratio test: the interval is
#'   `{psi : D(psi) <= qt(1 - alpha/2, df)^2}`, found by [stats::uniroot()] on each
#'   side of the MLE on the unconstrained internal coordinate, with the endpoints
#'   transformed to the natural scale. The cutoff is the squared profile-t
#'   quantile on `df = n - p` residual degrees of freedom (Bates-Watts profile-t),
#'   not `qchisq(level, 1)`; the two coincide as `df -> Inf`. These intervals are
#'   prior-free and respect asymmetry. They are equivariant under monotone
#'   reparameterisation, so the `z` interval equals `exp()` of the internal
#'   `log_z` interval.
#' * `method = "wald"` reuses the Phase-2 Wald path: `estimate +/- t * se` (with
#'   `t = qt(1 - alpha/2, df)` on `df = n - p`) on the internal (link) scale,
#'   back-transformed.
#' * `method = "bootstrap"` returns prior-free parametric-bootstrap percentile
#'   intervals: survival counts are regenerated at the observed design from the
#'   fitted 4PL, the model is refitted `nboot` times, and the interval is the
#'   percentile range of the replicate estimates. This is the likelihood-path
#'   analogue of the bayesTLS posterior interval. It returns a finite interval
#'   only when enough stable, non-degenerate refits remain.
#'
#' When a profile does not close on one side, or the fitted Hessian is not
#' positive definite (`pdHess = FALSE`), `confint()` falls back to the parametric
#' bootstrap for the affected parameters (with a message). The fallback can still
#' return `NA` when too few valid refits remain. Set `fallback = FALSE` to keep
#' the strict profile behaviour, which returns `NA` on
#' the open side (never a fabricated bound) with a warning that the parameter is
#' weakly identified (see `vignette("profile-likelihood")`). The upper asymptote `up` has its own
#' coordinate `beta_up` under disjoint bounds but is not yet profiled, so it is
#' reported with the delta-method Wald interval under the profile/Wald methods,
#' with a message.
#'
#' For a fit with a random intercept (`CTmax ~ <fixed> + (1 | group)`),
#' `method = "profile"` profiles the fixed-effect coordinates by re-running the
#' Laplace approximation at each grid point, which is slower than a fixed-effects
#' profile. Variance components keep their log-scale Wald intervals under the
#' profile method, and a non-closing random-effects profile falls back to Wald.
#' `method = "bootstrap"` instead redraws every active random-intercept block and
#' refits with the Laplace approximation, returning percentile intervals when
#' enough stable refits remain.
#'
#' @param object A `profile_tls` fit from [fit_tls()].
#' @param parm Character vector of target names (for example `"CTmax"`, `"z"`,
#'   `"log_z"`, `"low"`, `"k"`, `"phi"`, grouped names such as `"CTmax:A"`, or
#'   contrasts such as `"dCTmax:A-B"`, which means group A minus group B).
#'   `NULL` (default) returns intervals for the natural-scale parameters of the
#'   fit.
#' @param level Confidence level (default `0.95`).
#' @param method One of `"profile"` (default), `"wald"`, or `"bootstrap"`.
#' @param npoints Number of grid points used per profile (default `30`); ignored
#'   for `method = "wald"` and `method = "bootstrap"`.
#' @param trace Logical; print inner-optimisation progress (profile/bootstrap).
#' @param fallback Logical; when `method = "profile"` (the default), fall back to
#'   the parametric bootstrap for any parameter whose profile does not close, and
#'   for all parameters when the fit's Hessian is not positive definite
#'   (`pdHess = FALSE`). Default `TRUE`.
#' @param nboot Number of bootstrap replicates for `method = "bootstrap"` or the
#'   fallback (default `1000`).
#' @param boot_seed Optional integer seed making the bootstrap reproducible
#'   without disturbing the caller's random stream (default `NULL`).
#' @param cores Number of CPU cores for the bootstrap refits (default `1`, maximum
#'   `2`). Requests above two warn and use two. `cores > 1` refits replicates in
#'   parallel by forking (Unix; sequential on Windows). Results are identical for
#'   a given `boot_seed` regardless of `cores`.
#' @param ... Reserved; must be empty.
#'
#' @return A [tibble][tibble::tibble] with one row per target and columns
#'   `parameter`, `conf.low`, `conf.high`, `estimate`, `level`, `method`,
#'   `scale`, and `conf.status`.
#'
#' @examples
#' d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
#' fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
#'                family = "binomial", tref = 1)
#' confint(fit, "CTmax", method = "profile")
#' confint(fit, "z", method = "profile")
#'
#' @importFrom stats confint
#' @export
confint.profile_tls <- function(object, parm = NULL, level = 0.95,
                                method = c("profile", "wald", "bootstrap"),
                                npoints = 30L, trace = FALSE,
                                fallback = TRUE, nboot = 1000L,
                                boot_seed = NULL, cores = 1L, ...) {
  dots <- list(...)
  if (length(dots) > 0L) {
    cli::cli_abort("{.arg ...} is reserved; pass only documented arguments.")
  }
  if (!inherits(object, "profile_tls")) {
    cli::cli_abort("{.arg object} must be a {.cls profile_tls} fit from {.fn fit_tls}.")
  }
  method <- match.arg(method)
  tls_validate_level(level)

  # Random-effects fits: profile intervals are available for fixed-effect
  # coordinates (each grid point re-runs the Laplace), while variance components
  # use log-scale Wald intervals under the profile method. The explicit bootstrap
  # path redraws all active random blocks and refits them.
  if (tls_has_re(object) && identical(method, "bootstrap")) {
    cli::cli_inform(
      "Bootstrapping a random-effects fit redraws the group deviations and refits with the Laplace approximation per replicate (slow); consider a smaller {.arg nboot}."
    )
  }

  if (is.null(parm)) {
    parm <- unique(object$estimates$parameter)
  }
  if (!is.character(parm)) {
    cli::cli_abort("{.arg parm} must be a character vector of target names.")
  }

  if (identical(method, "wald")) {
    return(tls_confint_wald(object, parm, level))
  }
  if (identical(method, "bootstrap")) {
    return(tls_confint_bootstrap(object, parm, level, nboot = nboot,
                                 seed = boot_seed, cores = cores))
  }

  # Random-effects fits profile through a selective router (Laplace-refit profile
  # for the fixed effects; Wald for the variance components and the non-closing
  # fallback).
  if (tls_has_re(object)) {
    return(tls_confint_profile_re(object, parm, level, npoints, trace, fallback))
  }

  # General (continuous-covariate) shape coefficients have no group level, so the
  # map-refit profile target resolver cannot address them; route them to Wald
  # (like `up` and `sigma_CTmax`). Scalar and one-hot grouped coords still profile.
  est <- object$estimates
  is_general_coef <- function(p) {
    i <- match(p, est$parameter)
    !is.na(i) && grepl("^(low|up|k):", p) && is.na(est$group[i])
  }
  general_parm <- parm[vapply(parm, is_general_coef, logical(1))]
  prof_parm <- setdiff(parm, general_parm)

  # Weak-phi fallback. Profiling CTmax / z / log_z under a weakly-identified
  # beta-binomial dispersion under-covers: the profiled-out phi runs to the
  # binomial limit and the interval goes too narrow, while the Wald interval stays
  # calibrated (the joint Hessian propagates the flat-phi uncertainty). Route the
  # affected coordinates to Wald when `fallback = TRUE`, mirroring the
  # non-closing -> bootstrap fallback below. This alters no likelihood -- it is
  # purely interval-method routing -- and `fallback = FALSE` keeps the raw profile.
  if (isTRUE(fallback) && isTRUE(object$family$family_code == 1L)) {
    rel_se <- tls_phi_rel_se(object$estimates)
    if (is.finite(rel_se) && rel_se > 1) {
      weak <- intersect(prof_parm, c("CTmax", "z", "log_z"))
      if (length(weak)) {
        cli::cli_inform(c(
          "!" = "The beta-binomial dispersion {.code phi} is weakly identified (relative SE {round(rel_se, 1)}).",
          "i" = "The profile for {.val {weak}} can under-cover; returning the calibrated Wald interval{?s} instead. Set {.code fallback = FALSE} for the raw profile."
        ))
        general_parm <- union(general_parm, weak)
        prof_parm <- setdiff(prof_parm, weak)
      }
    }
  }

  rows <- lapply(prof_parm, function(p) {
    pr <- profile(object, p, level = level, npoints = npoints, trace = trace)
    tibble::tibble(
      parameter = p,
      conf.low = pr$conf.low,
      conf.high = pr$conf.high,
      estimate = pr$estimate,
      level = level,
      method = if (identical(pr$conf.status, "wald_fallback")) "wald" else "profile",
      scale = pr$scale,
      conf.status = pr$conf.status
    )
  })
  out <- if (length(rows)) do.call(rbind, rows) else NULL
  if (length(general_parm)) {
    w <- tls_confint_wald(object, general_parm, level)
    out <- if (is.null(out)) w else rbind(out, w[, names(out)])
  }
  out <- out[match(parm, out$parameter), , drop = FALSE]

  # Auto-fallback: a non-closing profile (or a non-positive-definite Hessian)
  # leaves prior-free, Hessian-free uncertainty on the table. Attempt a
  # parametric-bootstrap fallback; unstable refits remain explicitly unavailable.
  if (isTRUE(fallback)) {
    pdhess_bad <- !isTRUE(object$convergence$pdHess)
    open <- out$conf.status %in% c("open_lower", "open_upper", "open_both") |
      is.na(out$conf.low) | is.na(out$conf.high)
    need <- open | pdhess_bad
    if (any(need)) {
      cli::cli_inform(c(
        "!" = "Using a parametric bootstrap for {sum(need)} parameter{?s} where the profile did not close{if (pdhess_bad) ' or the Hessian was not positive definite' else ''}.",
        "i" = "Set {.code fallback = FALSE} to keep the profile-only behaviour ({.val NA} on a non-closing side)."
      ))
      boot <- tls_confint_bootstrap(object, out$parameter[need], level,
                                    nboot = nboot, seed = boot_seed, cores = cores)
      keep <- out[!need, , drop = FALSE]
      out <- rbind(keep, boot[, names(out)])
      out <- out[match(parm, out$parameter), , drop = FALSE]
    }
  }
  out
}

#' Relative standard error of the beta-binomial dispersion (~ SE of log phi)
#'
#' Returns `SE(phi) / phi_hat` from the estimates table -- the delta-method SE of
#' `log phi`. A value above 1 flags a weakly-identified dispersion (mild
#' overdispersion, data near the binomial limit), where the profile interval for
#' `CTmax` / `z` under-covers and Wald is preferred. `NA` when there is no `phi`
#' row or its standard error is unavailable.
#' @keywords internal
#' @noRd
tls_phi_rel_se <- function(estimates) {
  r <- estimates[estimates$parameter == "phi", , drop = FALSE]
  if (nrow(r) != 1L || !is.finite(r$estimate) || !is.finite(r$std.error) ||
      r$estimate <= 0) {
    return(NA_real_)
  }
  r$std.error / r$estimate
}

#' Profile confidence intervals for a random-effects fit (selective routing)
#'
#' Profiles the fixed-effect coordinates -- each grid point re-runs the Laplace
#' approximation through `tls_profile_nll_fun()` -- and keeps variance components
#' on log-scale Wald intervals because they have no profile coordinates yet. A
#' non-closing profile falls back to Wald; users can request the explicit
#' random-effects-aware bootstrap method separately. Same 8-column tibble as the
#' fixed-effects profile path, reordered to `parm`.
#' @keywords internal
#' @noRd
tls_confint_profile_re <- function(object, parm, level, npoints, trace, fallback) {
  wald_targets <- intersect(parm,
    c("sigma_CTmax", "sigma_logz", "sigma_low", "sigma_logk"))
  prof_targets <- setdiff(parm, wald_targets)

  if (length(prof_targets)) {
    cli::cli_inform(c(
      "i" = "Profiling under the random effect re-runs the Laplace approximation at each grid point, so it is slower than a fixed-effects profile.",
      "i" = "The variance components ({.code sigma_*}) use their log-scale Wald intervals; the Confidence Eye stays on Wald for speed."
    ))
  }

  rows <- lapply(prof_targets, function(p) {
    pr <- profile(object, p, level = level, npoints = npoints, trace = trace)
    tibble::tibble(
      parameter = p,
      conf.low = pr$conf.low,
      conf.high = pr$conf.high,
      estimate = pr$estimate,
      level = level,
      method = if (identical(pr$conf.status, "wald_fallback")) "wald" else "profile",
      scale = pr$scale,
      conf.status = pr$conf.status
    )
  })
  out <- if (length(rows)) do.call(rbind, rows) else NULL
  if (length(wald_targets)) {
    w <- tls_confint_wald(object, wald_targets, level)
    out <- if (is.null(out)) w else rbind(out, w[, names(out)])
  }

  # Fallback for a non-closing profile (or a non-positive-definite Hessian): use
  # Wald. Users can request the explicit RE-aware bootstrap separately. Only
  # profiled rows can need this fallback (variance components are already Wald).
  if (isTRUE(fallback) && !is.null(out)) {
    pdhess_bad <- !isTRUE(object$convergence$pdHess)
    open <- out$conf.status %in% c("open_lower", "open_upper", "open_both") |
      is.na(out$conf.low) | is.na(out$conf.high)
    need <- (open | pdhess_bad) & out$parameter %in% prof_targets
    if (any(need)) {
      cli::cli_inform(c(
        "!" = "Using Wald/delta intervals for {sum(need)} random-effects parameter{?s} where the profile did not close{if (pdhess_bad) ' or the Hessian was not positive definite' else ''}."
      ))
      repl <- tls_confint_wald(object, out$parameter[need], level)
      keep <- out[!need, , drop = FALSE]
      out <- rbind(keep, repl[, names(out)])
    }
  }
  out[match(parm, out$parameter), , drop = FALSE]
}

#' Wald confidence-interval tibble for named targets
#'
#' Reuses the Phase-2 Wald path (`tls_wald_natural()`) and selects the requested
#' targets, returning the same tibble shape as the profile path.
#' @keywords internal
#' @noRd
tls_confint_wald <- function(fit, parm, level) {
  wald <- tls_wald_natural(fit, level)
  est <- fit$estimates
  scale_for <- function(p) {
    # log_z(:grp) reported on the log scale; otherwise use the natural link.
    if (p == "log_z" || grepl("^log_z", p)) return("log")
    s <- tls_param_scale(p, fit$name_map)
    if (is.na(s)) "identity" else s
  }
  rows <- lapply(parm, function(p) {
    # Allow log_z(:grp) as a Wald target by transforming the z row's endpoints.
    if (p == "log_z" || grepl("^log_z", p)) {
      zname <- sub("^log_", "", p)
      r <- wald[wald$parameter == zname, , drop = FALSE]
      e <- est$estimate[est$parameter == zname]
      return(tibble::tibble(
        parameter = p,
        conf.low = if (nrow(r)) log(r$conf.low[1L]) else NA_real_,
        conf.high = if (nrow(r)) log(r$conf.high[1L]) else NA_real_,
        estimate = if (length(e)) log(e) else NA_real_,
        level = level, method = "wald", scale = "log", conf.status = "ok"
      ))
    }
    # General (continuous-covariate) shape coefficient: a LINK-scale slope or
    # intercept (group is NA in the estimates). Its estimate is already on the
    # link scale -- do NOT back-transform it -- so the Wald interval is the
    # symmetric `estimate +/- z * se` from the estimates table.
    ei <- match(p, est$parameter)
    if (!is.na(ei) && grepl("^(low|up|k):", p) && is.na(est$group[ei])) {
      zc <- stats::qt(1 - (1 - level) / 2, df = tls_ci_df(fit))
      e <- est$estimate[ei]
      se <- est$std.error[ei]
      return(tibble::tibble(
        parameter = p, conf.low = e - zc * se, conf.high = e + zc * se,
        estimate = e, level = level, method = "wald",
        scale = if (grepl("^k:", p)) "log" else "logit", conf.status = "ok"
      ))
    }
    r <- wald[wald$parameter == p, , drop = FALSE]
    e <- est$estimate[est$parameter == p]
    if (nrow(r) == 0L) {
      cli::cli_abort(c(
        "Unknown Wald target {.val {p}}.",
        i = "Valid targets: {.val {unique(est$parameter)}} (and {.val log_z})."
      ))
    }
    tibble::tibble(
      parameter = p,
      conf.low = r$conf.low[1L],
      conf.high = r$conf.high[1L],
      estimate = if (length(e)) e[1L] else NA_real_,
      level = level, method = "wald",
      scale = scale_for(p), conf.status = "ok"
    )
  })
  do.call(rbind, rows)
}
