#' Profile-likelihood curves for a fitted thermal-load-sensitivity model
#'
#' `profile()` computes the profile-likelihood deviance curve for one scalar
#' target of a [fit_tls()] model. For the target it fixes the corresponding
#' internal (unconstrained) coordinate on a grid, re-optimises the remaining
#' coordinates at each grid point, and returns the deviance
#' `D = 2 * (logLik_hat - logLik_profile)` together with the profile-t cutoff and
#' the profile-likelihood confidence interval. Because the profile is taken on the
#' unconstrained coordinate and the endpoints are then transformed by a monotone
#' function, the interval is exactly equivariant: the `z` interval equals `exp()`
#' of the internal `log_z` interval (the headline equivariance check, SPEC.md
#' S10).
#'
#' The algorithm is a map-refit profile: the target coordinate is fixed with
#' TMB's `map` mechanism and the rest re-optimised, mirroring the bracket-then-
#' [stats::uniroot()] endpoint solver in `drmTMB::R/profile.R:2314-2373`. See
#' `docs/design/04-profile-likelihood.md`.
#'
#' @section Targets:
#' \tabular{lll}{
#'   **Target** \tab **Profiled coordinate** \tab **Endpoint transform** \cr
#'   `CTmax`, `CTmax:<grp>` \tab `beta_CT[g]` \tab identity \cr
#'   `z`, `z:<grp>` \tab `beta_logz[g]` \tab `exp` \cr
#'   `log_z`, `log_z:<grp>` \tab `beta_logz[g]` \tab identity \cr
#'   `low` \tab `beta_low` \tab `plogis` \cr
#'   `k` \tab `beta_logk` \tab `exp` \cr
#'   `phi` \tab `log_phi` \tab `exp` \cr
#'   `up` \tab (Wald/delta fallback) \tab -- \cr
#'   `dCTmax:<a>-<b>`, `dlog_z:<a>-<b>` \tab contrast recoding \tab identity \cr
#' }
#'
#' Under the disjoint-bounds parameterisation `up = up_min + up_w * plogis(beta_up)`
#' has its own coordinate `beta_up`, but freqTLS does not yet profile it (the profile
#' path is wired for `low` but not `up` — symmetric work, simply not implemented).
#' freqTLS falls back to the delta-method Wald interval for `up`
#' and says so (SPEC.md S10). Group contrasts (`dCTmax`, `dlog_z`) are profiled
#' directly by recoding the design so the contrast is itself a coordinate.
#'
#' @param fitted A `profile_tls` fit from [fit_tls()].
#' @param parm A single target name (see Targets).
#' @param level Confidence level for the interval and the cutoff line (default
#'   `0.95`).
#' @param npoints Number of grid points for the deviance curve (default `30`).
#' @param trace Logical; print inner-optimisation progress.
#' @param ... Reserved; must be empty.
#'
#' @return An object of class `"profile_tls_profile"`: a list with `parm`,
#'   `profile_value` (grid on the natural scale), `deviance`, `estimate`,
#'   `conf.low`, `conf.high`, `conf.status`, `cutoff`, `level`, `scale`, and
#'   `transformation`.
#'
#' @examples
#' d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
#' fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
#'                family = "binomial", tref = 1)
#' pc <- profile(fit, "CTmax")
#' pc$conf.low
#' pc$conf.high
#'
#' @importFrom stats profile uniroot
#' @export
profile.profile_tls <- function(fitted, parm, level = 0.95, npoints = 30L,
                                trace = FALSE, ...) {
  dots <- list(...)
  if (length(dots) > 0L) {
    cli::cli_abort("{.arg ...} is reserved; pass only documented arguments.")
  }
  if (!inherits(fitted, "profile_tls")) {
    cli::cli_abort("{.arg fitted} must be a {.cls profile_tls} fit from {.fn fit_tls}.")
  }
  if (missing(parm) || is.null(parm) || length(parm) != 1L || !is.character(parm)) {
    cli::cli_abort(c(
      "{.arg parm} must be a single target name.",
      i = "Examples: {.val CTmax}, {.val z}, {.val log_z}, {.val low}, {.val k}, {.val phi}, or grouped/contrast names such as {.val CTmax:A} or {.val dCTmax:A-B}."
    ))
  }
  tls_validate_level(level)
  if (!is.numeric(npoints) || length(npoints) != 1L || npoints < 5) {
    cli::cli_abort("{.arg npoints} must be a single number >= 5.")
  }
  npoints <- as.integer(npoints)
  if (is.null(fitted$obj)) {
    cli::cli_abort("Profiling requires the live TMB object retained in {.code fit$obj}.")
  }

  target <- tls_resolve_target(fitted, parm)

  # A random-effects fit cannot profile a group contrast: the contrast refit
  # recodes the design and drops the random block, which would be silently wrong.
  if (tls_has_re(fitted) && identical(target$kind, "contrast")) {
    cli::cli_abort(c(
      "Contrast profiling under a random effect is not supported.",
      i = "The contrast refit would drop the random block; use {.code confint(fit, method = \"wald\")} for the contrast."
    ))
  }

  # `up` is not yet profiled (disjoint-bounds beta_up); fall back to Wald/delta and say so.
  if (identical(target$kind, "up")) {
    cli::cli_inform(c(
      "{.val {target$parm}} is profiled with the delta-method Wald interval.",
      i = "The profile path is not yet wired for the disjoint-bounds {.val up} coordinate {.code beta_up} (SPEC.md S10)."
    ))
    return(tls_up_wald_profile(fitted, level, target$parm))
  }

  # Contrasts: refit with the contrast as a coordinate, then profile it.
  if (identical(target$kind, "contrast")) {
    recoded <- tls_contrast_refit(fitted, target)
    ci <- tls_profile_ci_curve(recoded$fit, recoded$target, level, npoints, trace)
    ci$parm <- target$parm
    return(ci)
  }

  ci <- tls_profile_ci_curve(fitted, target, level, npoints, trace)
  ci
}

#' Validate a confidence level
#' @keywords internal
#' @noRd
tls_validate_level <- function(level) {
  if (!is.numeric(level) || length(level) != 1L || !is.finite(level) ||
      level <= 0 || level >= 1) {
    cli::cli_abort("{.arg level} must be a single number in (0, 1).")
  }
}

# ---- target resolution ------------------------------------------------------

#' Resolve a human-facing target name to an internal profiling target
#'
#' Returns a list describing how to profile `parm`: its `kind`
#' (`"coord"`, `"contrast"`, or `"up"`), the natural-scale `transformation`
#' (`"identity"`, `"exp"`, `"plogis"`), the `link`/`scale` label, the MLE
#' `estimate` on the natural scale, the internal position(s) involved, and the
#' fitted MLE value of the profiled coordinate.
#'
#' @param fit A `profile_tls` fit.
#' @param parm A single target name.
#' @return A target description list.
#' @keywords internal
#' @noRd
tls_resolve_target <- function(fit, parm) {
  nm <- fit$name_map
  par <- fit$par
  par_names <- names(par)
  levels_g <- fit$group_levels
  ng <- length(levels_g)

  # Contrast targets: dCTmax:<a>-<b> and dlog_z:<a>-<b> (also accept dz:<a>-<b>).
  if (grepl("^d", parm)) {
    return(tls_resolve_contrast(fit, parm))
  }

  # up (or up:<g>): handled specially (beta_up not yet profiled; Wald).
  if (parm == "up" || grepl("^up:", parm)) {
    return(list(kind = "up", parm = parm, transformation = "identity"))
  }

  # log_z family: profile beta_logz[g] on the identity (log) scale.
  if (parm == "log_z" || grepl("^log_z:", parm)) {
    g <- tls_group_index(parm, "log_z", levels_g)
    coord <- paste0("beta_logz[", g, "]")
    pos <- tls_coord_position(par_names, "beta_logz", g)
    est <- unname(par[pos])
    return(list(
      kind = "coord", parm = parm,
      tmb_parameter = "beta_logz", index = g, position = pos,
      theta_hat = est, transformation = "identity",
      link = "identity", scale = "log",
      estimate = est, natural_name = parm
    ))
  }

  # z family: profile beta_logz[g], transform with exp.
  if (parm == "z" || grepl("^z:", parm)) {
    g <- tls_group_index(parm, "z", levels_g)
    pos <- tls_coord_position(par_names, "beta_logz", g)
    theta_hat <- unname(par[pos])
    return(list(
      kind = "coord", parm = parm,
      tmb_parameter = "beta_logz", index = g, position = pos,
      theta_hat = theta_hat, transformation = "exp",
      link = "log", scale = "log",
      estimate = exp(theta_hat), natural_name = parm
    ))
  }

  # CTmax family: profile beta_CT[g], identity.
  if (parm == "CTmax" || grepl("^CTmax:", parm)) {
    g <- tls_group_index(parm, "CTmax", levels_g)
    pos <- tls_coord_position(par_names, "beta_CT", g)
    theta_hat <- unname(par[pos])
    return(list(
      kind = "coord", parm = parm,
      tmb_parameter = "beta_CT", index = g, position = pos,
      theta_hat = theta_hat, transformation = "identity",
      link = "identity", scale = "identity",
      estimate = theta_hat, natural_name = parm
    ))
  }

  # low family: profile beta_low[g] on the logit scale (shared or grouped).
  if (parm == "low" || grepl("^low:", parm)) {
    g <- tls_shape_index(parm, "low", "beta_low", par_names, levels_g)
    pos <- tls_coord_position(par_names, "beta_low", g)
    theta_hat <- unname(par[pos])
    return(list(
      kind = "coord", parm = parm,
      tmb_parameter = "beta_low", index = g, position = pos,
      theta_hat = theta_hat, transformation = "plogis",
      link = "logit", scale = "logit",
      estimate = stats::plogis(theta_hat), natural_name = parm
    ))
  }

  # k family: profile beta_logk[g], transform with exp (shared or grouped).
  if (parm == "k" || grepl("^k:", parm)) {
    g <- tls_shape_index(parm, "k", "beta_logk", par_names, levels_g)
    pos <- tls_coord_position(par_names, "beta_logk", g)
    theta_hat <- unname(par[pos])
    return(list(
      kind = "coord", parm = parm,
      tmb_parameter = "beta_logk", index = g, position = pos,
      theta_hat = theta_hat, transformation = "exp",
      link = "log", scale = "log",
      estimate = exp(theta_hat), natural_name = parm
    ))
  }

  scalar_map <- list(
    phi = list(coord = "log_phi", transformation = "exp",
               link = "log", scale = "log")
  )
  if (parm %in% names(scalar_map)) {
    m <- scalar_map[[parm]]
    if (!(m$coord %in% par_names)) {
      if (identical(parm, "phi")) {
        cli::cli_abort(c(
          "{.val phi} is only defined for the beta-binomial family.",
          i = "This fit is binomial; there is no overdispersion parameter to profile."
        ))
      }
      cli::cli_abort("Internal coordinate {.val {m$coord}} is not in this fit.")
    }
    pos <- which(par_names == m$coord)[1L]
    theta_hat <- unname(par[pos])
    return(list(
      kind = "coord", parm = parm,
      tmb_parameter = m$coord, index = 1L, position = pos,
      theta_hat = theta_hat, transformation = m$transformation,
      link = m$link, scale = m$scale,
      estimate = tls_backtransform(theta_hat, m$link), natural_name = parm
    ))
  }

  cli::cli_abort(c(
    "Unknown profile target {.val {parm}}.",
    i = "Valid targets: {.val CTmax}, {.val z}, {.val log_z}, {.val low}, {.val k}{if (fit$family$family_code >= 1L) ', {.val phi}' else ''}, {.val up}, grouped names such as {.val CTmax:{levels_g[1]}}, or contrasts such as {.val dCTmax:{levels_g[1]}-{levels_g[min(2, ng)]}}."
  ))
}

#' Group index for a grouped target name like "z:A"
#' @keywords internal
#' @noRd
tls_group_index <- function(parm, base, levels_g) {
  if (identical(parm, base)) {
    if (length(levels_g) != 1L) {
      cli::cli_abort(c(
        "{.val {base}} is ambiguous in a grouped fit.",
        i = "Use a grouped name such as {.val {base}:{levels_g[1]}}."
      ))
    }
    return(1L)
  }
  lvl <- sub(paste0("^", base, ":"), "", parm)
  g <- match(lvl, levels_g)
  if (is.na(g)) {
    cli::cli_abort(c(
      "Group {.val {lvl}} is not a level of this fit.",
      i = "Levels: {.val {levels_g}}."
    ))
  }
  g
}

#' Positional index of the g-th occurrence of an internal coordinate base name
#'
#' The optimised parameter vector repeats names such as `beta_CT` once per group;
#' this returns the position of the g-th occurrence (matching the positional
#' extraction used elsewhere in the package).
#' @keywords internal
#' @noRd
tls_coord_position <- function(par_names, base, g) {
  hits <- which(par_names == base)
  if (length(hits) < g) {
    cli::cli_abort("Internal error: coordinate {.val {base}} has no index {g}.")
  }
  hits[g]
}

#' Resolve the coordinate index of a shape parameter (shared or grouped)
#'
#' Shapes may be a single shared coefficient (even when `CTmax` is grouped) or one
#' per group. A bare name (`low`) is the shared coefficient when there is exactly
#' one, and ambiguous when there are several; a grouped name (`low:<g>`) is the
#' group's coefficient. `internal_base` is the TMB coordinate (`beta_low` /
#' `beta_logk`); the shape design shares the `CTmax` / `log_z` group levels.
#' @keywords internal
#' @noRd
tls_shape_index <- function(parm, base, internal_base, par_names, levels_g) {
  n_coef <- sum(par_names == internal_base)
  if (n_coef == 1L) {
    if (!identical(parm, base)) {
      cli::cli_abort(c(
        "{.val {parm}}: {.code {base}} is a single shared shape in this fit.",
        i = "Use {.val {base}} (the shapes are not grouped)."
      ))
    }
    return(1L)
  }
  tls_group_index(parm, base, levels_g)
}

# ---- map-refit profile evaluator --------------------------------------------

#' Build a profile NLL evaluator that fixes one internal coordinate
#'
#' Returns a function `f(value)` giving the profile negative log-likelihood with
#' the target coordinate fixed at `value` and all other coordinates re-optimised
#' from the fitted MLE (warm start). Inner non-convergence yields `NA` (SPEC.md
#' S10, warning 12) rather than a misleading finite value.
#'
#' @param fit A `profile_tls` fit.
#' @param target A target description (`kind = "coord"`).
#' @param trace Logical; print inner-optimisation progress.
#' @return A function of one numeric argument returning the profile NLL.
#' @keywords internal
#' @noRd
tls_profile_nll_fun <- function(fit, target, trace = FALSE) {
  inputs <- fit$tmb_inputs
  if (is.null(inputs)) {
    cli::cli_abort(c(
      "Profiling needs the TMB inputs retained in the fit.",
      i = "Refit with the current version of {.fn fit_tls}."
    ))
  }
  base_data <- inputs$data
  base_map <- inputs$map %||% list()
  # Warm-start the inner optimisation at the fitted MLE (much faster + more
  # robust than the cold starts).
  base_par <- tls_mle_par_list(fit, inputs$parameters)

  tmb_par_name <- target$tmb_parameter
  idx <- target$index

  function(value) {
    par_init <- base_par
    # Set the fixed coordinate's start to `value`.
    if (length(par_init[[tmb_par_name]]) >= idx) {
      par_init[[tmb_par_name]][idx] <- value
    } else {
      par_init[[tmb_par_name]] <- value
    }

    # Map: fix this coordinate (and re-apply any pre-existing maps, e.g. log_phi
    # for the binomial family).
    map <- base_map
    coord_len <- length(par_init[[tmb_par_name]])
    fac <- rep(NA_integer_, coord_len)
    if (coord_len > 1L) {
      free <- seq_len(coord_len)[-idx]
      fac[free] <- seq_along(free)
    }
    map[[tmb_par_name]] <- factor(fac)

    inner <- tryCatch(
      TMB::MakeADFun(
        data = base_data,
        parameters = par_init,
        map = map,
        random = inputs$random,   # "b_CT" for an RE fit (Laplace at each point); NULL otherwise
        DLL = "freqTLS",
        silent = !isTRUE(trace)
      ),
      error = function(e) e
    )
    if (inherits(inner, "error")) return(NA_real_)

    opt <- tryCatch(
      stats::nlminb(inner$par, inner$fn, inner$gr),
      error = function(e) e
    )
    if (inherits(opt, "error")) {
      opt <- tryCatch(
        {
          o <- stats::optim(inner$par, inner$fn, inner$gr, method = "BFGS")
          list(objective = o$value, convergence = o$convergence)
        },
        error = function(e) e
      )
    }
    if (inherits(opt, "error")) return(NA_real_)
    conv <- opt$convergence
    if (is.null(conv) || !identical(as.integer(conv), 0L)) {
      # Inner did not converge cleanly: NA (warning 12 surfaced upstream).
      return(NA_real_)
    }
    opt$objective
  }
}

#' Reconstruct the full parameter list at the fitted MLE
#'
#' The optimiser's `par` is a flat, named vector of the *free* coordinates in
#' declaration order (mapped-out coordinates such as `log_phi` for the binomial
#' family are absent). This re-inserts the MLE values into the original list
#' shape, leaving mapped-out coordinates at their starting placeholder so the
#' rebuilt objective re-applies the same map.
#'
#' @param fit A `profile_tls` fit.
#' @param template The original parameter list (for shapes / mapped-out slots).
#' @return A parameter list with MLE values in the free slots.
#' @keywords internal
#' @noRd
tls_mle_par_list <- function(fit, template) {
  out <- template
  flat <- fit$opt$par
  flat_names <- names(flat)
  # Fill each parameter in declaration order from the free values that carry its
  # name; mapped-out parameters have no entries in `flat` and stay as-is.
  for (nm in names(out)) {
    hits <- which(flat_names == nm)
    if (length(hits) == length(out[[nm]]) && length(hits) > 0L) {
      out[[nm]][] <- unname(flat[hits])
    }
  }
  out
}

# ---- curve + CI construction ------------------------------------------------

#' Build the deviance curve and profile CI for a coordinate target
#'
#' @param fit A `profile_tls` fit.
#' @param target A target description (`kind = "coord"`).
#' @param level Confidence level.
#' @param npoints Number of grid points.
#' @param trace Logical; inner-optimisation trace.
#' @return A `"profile_tls_profile"` object.
#' @keywords internal
#' @noRd
tls_profile_ci_curve <- function(fit, target, level, npoints, trace) {
  nll_hat <- -fit$logLik
  df_t <- tls_ci_df(fit)
  # Bates-Watts profile-t: compare the deviance to t^2 (not chi-square_1) so the
  # interval is small-sample calibrated (t^2 -> chi-square_1 as df -> Inf).
  cutoff <- stats::qt(1 - (1 - level) / 2, df = df_t)^2
  nll_fun <- tls_profile_nll_fun(fit, target, trace)
  theta_hat <- target$theta_hat

  # Deviance evaluator on the internal coordinate.
  dev_fun <- function(theta) {
    nll_p <- nll_fun(theta)
    if (!is.finite(nll_p)) return(NA_real_)
    2 * (nll_p - nll_hat)
  }

  # ---- grid for the curve (curvature-scaled span) --------------------------
  se <- tls_target_curvature_se(fit, target)
  span <- if (is.finite(se) && se > 0) {
    # Reach past the (heavier-tailed) t cutoff: the endpoint is ~ t_df SE from the
    # MLE, so (t_df + margin) * se brackets it (-> ~3.5 SE for large df).
    (stats::qt(1 - (1 - level) / 2, df = df_t) + 1.5) * se
  } else {
    max(0.5, 0.25 * abs(theta_hat))
  }
  grid <- seq(theta_hat - span, theta_hat + span, length.out = npoints)
  # Guarantee the MLE is on the grid (deviance minimum should be ~0 there).
  grid <- sort(unique(c(grid, theta_hat)))
  dev <- vapply(grid, dev_fun, numeric(1L))

  # warning 12: inner non-convergence somewhere on the grid.
  if (anyNA(dev)) {
    cli::cli_warn(c(
      "Inner re-optimisation did not converge at {sum(is.na(dev))} grid point{?s} while profiling {.val {target$parm}}.",
      i = "Those points are reported as {.val NA}; the interval is taken from the points that did converge (SPEC.md S10, warning 12)."
    ))
  }

  # warning 10: MLE on a boundary -> interval calibration unreliable. The
  # deviance at the MLE should be ~0; a clearly negative minimum elsewhere
  # signals the reported MLE is not the profile optimum.
  dev_at_hat <- dev_fun(theta_hat)
  min_dev <- suppressWarnings(min(dev, na.rm = TRUE))
  if (is.finite(min_dev) && min_dev < -1e-3) {
    cli::cli_warn(c(
      "The profile deviance for {.val {target$parm}} dips below zero away from the reported MLE (min {signif(min_dev, 3)}).",
      i = "The reported optimum may be on a boundary or not a true interior maximum; the profile-t calibration of the interval is unreliable (SPEC.md S10, warning 10)."
    ))
  }

  # warning 11: non-monotone / multimodal profile. On each side of the MLE the
  # deviance should rise monotonically; count sign changes in the diff of the
  # side-specific deviance to detect multimodality.
  status_multimodal <- tls_profile_multimodal(grid, dev, theta_hat)
  if (status_multimodal) {
    cli::cli_warn(c(
      "The profile deviance for {.val {target$parm}} is non-monotone (multiple local minima).",
      i = "The interval may not be a single connected region; inspect {.code plot(profile(fit, \"{target$parm}\"))} (SPEC.md S10, warning 11)."
    ))
  }

  # ---- endpoints via bracket-then-uniroot ----------------------------------
  lo <- tls_profile_endpoint(dev_fun, theta_hat, -1, cutoff, se, grid, dev)
  hi <- tls_profile_endpoint(dev_fun, theta_hat, +1, cutoff, se, grid, dev)

  conf.status <- "ok"
  open_side <- character(0)
  if (!is.finite(lo)) open_side <- c(open_side, "lower")
  if (!is.finite(hi)) open_side <- c(open_side, "upper")
  if (length(open_side) > 0L) {
    conf.status <- if (length(open_side) == 2L) "open_both" else paste0("open_", open_side)
    # warning 9: profile did not close.
    cli::cli_warn(c(
      "The profile likelihood for {.val {target$parm}} did not close on the {open_side} side{?s}: {.val {target$parm}} is weakly identified.",
      i = "Returning {.val NA} on the open side rather than a fabricated bound (R-PROFILE).",
      i = "Consider {.pkg bayesTLS} or a bootstrap for this parameter (SPEC.md S10, warning 9)."
    ))
  }

  # Transform endpoints + estimate to the natural scale.
  trf <- function(x) if (is.finite(x)) tls_apply_transform(x, target$transformation) else NA_real_
  conf.low <- trf(lo)
  conf.high <- trf(hi)
  # exp / plogis are increasing, so order is preserved; guard anyway.
  if (is.finite(conf.low) && is.finite(conf.high) && conf.low > conf.high) {
    tmp <- conf.low; conf.low <- conf.high; conf.high <- tmp
  }

  profile_value <- vapply(grid, function(x) tls_apply_transform(x, target$transformation),
                          numeric(1L))

  structure(
    list(
      parm = target$parm,
      profile_value = profile_value,
      deviance = dev,
      estimate = target$estimate,
      conf.low = conf.low,
      conf.high = conf.high,
      conf.status = conf.status,
      cutoff = cutoff,
      level = level,
      scale = target$scale,
      transformation = target$transformation
    ),
    class = "profile_tls_profile"
  )
}

#' Apply a natural-scale transform to a single value
#' @keywords internal
#' @noRd
tls_apply_transform <- function(x, transformation) {
  switch(transformation,
    identity = x,
    exp = exp(x),
    plogis = stats::plogis(x),
    cli::cli_abort("Unknown transformation {.val {transformation}}.")
  )
}

#' Curvature-based SE of the profiled internal coordinate (for grid/step scaling)
#'
#' Reads the SE of the internal coordinate from the fixed-effect part of the
#' sdreport positionally (grouped fits repeat row names). Returns `NA` when the
#' sdreport is unavailable.
#' @keywords internal
#' @noRd
tls_target_curvature_se <- function(fit, target) {
  sdr <- fit$sdreport
  if (is.null(sdr)) return(NA_real_)
  fixed <- tryCatch(summary(sdr, select = "fixed"), error = function(e) NULL)
  if (is.null(fixed)) return(NA_real_)
  rows <- which(rownames(fixed) == target$tmb_parameter)
  if (length(rows) < target$index) return(NA_real_)
  unname(fixed[rows[target$index], "Std. Error"])
}

#' Detect a non-monotone / multimodal profile deviance
#'
#' On each side of the MLE the deviance should increase monotonically. Returns
#' `TRUE` if either side has an interior local minimum (the deviance decreases
#' after having increased), which signals multimodality.
#' @keywords internal
#' @noRd
tls_profile_multimodal <- function(grid, dev, theta_hat) {
  ok <- is.finite(dev)
  g <- grid[ok]; d <- dev[ok]
  if (length(g) < 4L) return(FALSE)
  check_side <- function(gs, ds) {
    if (length(ds) < 3L) return(FALSE)
    dd <- diff(ds)
    # tolerance to ignore tiny numerical wiggles near the floor
    dd[abs(dd) < 1e-4] <- 0
    # after the deviance has started rising, it should not fall again
    risen <- FALSE
    for (i in seq_along(dd)) {
      if (dd[i] > 0) risen <- TRUE
      if (risen && dd[i] < 0) return(TRUE)
    }
    FALSE
  }
  left <- g <= theta_hat
  right <- g >= theta_hat
  # left side read outward from the MLE => reverse
  bad_left <- check_side(rev(g[left]), rev(d[left]))
  bad_right <- check_side(g[right], d[right])
  isTRUE(bad_left) || isTRUE(bad_right)
}

#' Find one profile-interval endpoint by bracketing then uniroot
#'
#' Steps outward from the MLE along `direction` until the deviance rises above
#' `cutoff` (a closed side), then solves `D(theta) = cutoff` with
#' [stats::uniroot()]. Returns `NA` when no bracket is found within the search
#' (an open / non-closing side, SPEC.md S10 warning 9). Adapted from the
#' bracket-then-uniroot endpoint solver in `drmTMB::R/profile.R:2314-2363`.
#'
#' @param dev_fun Deviance function on the internal coordinate.
#' @param theta_hat Fitted MLE of the coordinate.
#' @param direction `-1` (lower) or `+1` (upper).
#' @param cutoff Deviance cutoff `qt(1 - alpha/2, df)^2` (profile-t).
#' @param se Curvature SE (for the initial step); may be `NA`.
#' @param grid,dev Pre-computed grid and deviance (used to seed the bracket).
#' @return The internal-coordinate endpoint, or `NA_real_`.
#' @keywords internal
#' @noRd
tls_profile_endpoint <- function(dev_fun, theta_hat, direction, cutoff, se,
                                 grid, dev) {
  f <- function(theta) {
    d <- dev_fun(theta)
    if (!is.finite(d)) return(NA_real_)
    d - cutoff
  }

  # Seed the outer bracket from the pre-computed grid when a crossing is present
  # on this side (cheap; avoids extra refits).
  on_side <- if (direction < 0) grid < theta_hat else grid > theta_hat
  outer <- NA_real_
  outer_value <- NA_real_
  if (any(on_side)) {
    gs <- grid[on_side]; ds <- dev[on_side]
    ord <- order(abs(gs - theta_hat))  # nearest-out first
    gs <- gs[ord]; ds <- ds[ord]
    crossed <- which(is.finite(ds) & ds >= cutoff)
    if (length(crossed) > 0L) {
      outer <- gs[crossed[1L]]
      outer_value <- ds[crossed[1L]] - cutoff
    }
  }

  # If the grid did not bracket, step outward geometrically.
  if (!is.finite(outer) || outer_value < 0) {
    step <- if (is.finite(se) && se > 0) max(se, 1e-3) else max(0.1, 0.05 * abs(theta_hat) + 0.1)
    max_steps <- 60L
    cur <- theta_hat
    found <- FALSE
    for (i in seq_len(max_steps)) {
      cur <- theta_hat + direction * step
      v <- f(cur)
      if (is.finite(v) && v >= 0) {
        outer <- cur
        outer_value <- v
        found <- TRUE
        break
      }
      step <- step * 1.6
    }
    if (!found) return(NA_real_)  # open side: no bracket within search
  }

  interval <- sort(c(theta_hat, outer))
  root <- tryCatch(
    stats::uniroot(
      f,
      interval = interval,
      f.lower = if (direction < 0) outer_value else -cutoff,
      f.upper = if (direction < 0) -cutoff else outer_value,
      tol = 1e-6
    ),
    error = function(e) NULL
  )
  if (is.null(root)) return(NA_real_)
  if (!is.finite(root$f.root) || abs(root$f.root) > 1e-2) return(NA_real_)
  root$root
}

# ---- group contrasts --------------------------------------------------------

#' Resolve and profile a group contrast (dCTmax / dlog_z / dz)
#'
#' Recodes the design so the contrast (group `b` minus reference group `a`) is
#' itself a coordinate, refits, and profiles that coordinate directly. This gives
#' a genuine profile interval for `dCTmax = CTmax_b - CTmax_a` and
#' `dlog_z = log z_b - log z_a` (so the z ratio is `exp(dlog_z)`).
#'
#' @param fit A `profile_tls` fit.
#' @param parm A contrast name like `dCTmax:A-B` or `dlog_z:A-B` (also `dz:A-B`).
#' @return A target description with `kind = "contrast"` carrying a recoded fit.
#' @keywords internal
#' @noRd
tls_resolve_contrast <- function(fit, parm) {
  levels_g <- fit$group_levels
  if (length(levels_g) < 2L) {
    cli::cli_abort(c(
      "Contrasts require a grouped fit with at least two groups.",
      i = "This fit is ungrouped."
    ))
  }
  m <- regmatches(parm, regexec("^(dCTmax|dlog_z|dz):(.+)-(.+)$", parm))[[1L]]
  if (length(m) != 4L) {
    cli::cli_abort(c(
      "Could not parse contrast {.val {parm}}.",
      i = "Use {.val dCTmax:<a>-<b>}, {.val dlog_z:<a>-<b>}, or {.val dz:<a>-<b>} where {.val <a>} is the reference."
    ))
  }
  which_par <- m[2L]
  a <- m[3L]; b <- m[4L]
  if (!(a %in% levels_g) || !(b %in% levels_g)) {
    cli::cli_abort(c(
      "Contrast groups {.val {a}} and {.val {b}} must both be levels of the fit.",
      i = "Levels: {.val {levels_g}}."
    ))
  }
  if (identical(a, b)) {
    cli::cli_abort("A contrast needs two different groups.")
  }
  list(
    kind = "contrast",
    parm = parm,
    which_par = which_par,  # "dCTmax", "dlog_z", or "dz"
    ref = a, alt = b,
    transformation = "identity"
  )
}

#' Refit a model with a group contrast as a direct coordinate
#'
#' Rebuilds the TMB objective on a treatment-coded design where the contrast
#' parameter (`group b` minus reference `group a`, with all other groups also
#' contrasted against the reference) is itself a coefficient. The contrast can
#' then be profiled by the standard coordinate path. The recoded objective has
#' the same likelihood and MLE as the original `~ 0 + group` fit; only the
#' coordinates are reparameterised, which is exactly the equivariant move that
#' makes the contrast profile-able.
#'
#' Both `dCTmax` and `dlog_z`/`dz` are differences on the *internal* coordinate
#' scale: `dCTmax` is a difference of `CTmax` (identity), and `dlog_z`/`dz` is a
#' difference of `log z`, so the z ratio is `exp(dlog_z)`. The contrast coordinate
#' is profiled on the identity scale in both cases.
#'
#' @param fit A grouped `profile_tls` fit.
#' @param target A contrast target from `tls_resolve_contrast()`.
#' @return A list with the recoded `fit` (a minimal `profile_tls`) and the
#'   coordinate `target` to profile within it.
#' @keywords internal
#' @noRd
tls_contrast_refit <- function(fit, target) {
  d <- fit$diag_data
  if (is.null(d) || is.null(d$group)) {
    cli::cli_abort(c(
      "Contrast profiling needs the grouping data retained in the fit.",
      i = "Refit with the current version of {.fn fit_tls}."
    ))
  }
  fam <- fit$family
  # Order the factor so the reference group is the baseline of the treatment
  # contrasts; then beta_CT/beta_logz[2..] are differences vs the reference.
  g <- stats::relevel(factor(d$group), ref = target$ref)
  X <- stats::model.matrix(~ g)
  colnames(X) <- c("ref", paste0("d:", levels(g)[-1L]))
  attr(X, "assign") <- NULL
  attr(X, "contrasts") <- NULL
  n_obs <- length(d$y)
  ncol_X <- ncol(X)

  b4c <- compute_4pl_bounds(0, 1)
  tmb_data <- list(
    y = d$y, n = d$n,
    log_time = log10(d$time), temp = d$temp,
    X_CT = X, X_logz = X,
    X_low = matrix(1, n_obs, 1L),    # shapes are shared on the contrast refit
    X_up = matrix(1, n_obs, 1L),
    X_logk = matrix(1, n_obs, 1L),
    family_code = fam$family_code,
    log10_tref = log10(fit$tref),
    low_min = b4c$low_min, low_w = b4c$low_w,
    up_min = b4c$up_min, up_w = b4c$up_w,
    re_index = rep(0L, n_obs),   # contrasts are fixed-group fits: no RE
    re_index_logz = rep(0L, n_obs),
    re_index_low = rep(0L, n_obs),
    re_index_logk = rep(0L, n_obs)
  )

  # Starts: re-use the fitted per-group MLEs mapped to the contrast basis.
  est <- fit$estimates
  ct_by_grp <- stats::setNames(
    est$estimate[startsWith(est$parameter, "CTmax")], fit$group_levels
  )
  logz_by_grp <- log(stats::setNames(
    est$estimate[startsWith(est$parameter, "z:") | est$parameter == "z"],
    fit$group_levels
  ))
  lvl <- levels(g)
  ct_start <- c(ct_by_grp[[target$ref]], ct_by_grp[lvl[-1L]] - ct_by_grp[[target$ref]])
  logz_start <- c(logz_by_grp[[target$ref]], logz_by_grp[lvl[-1L]] - logz_by_grp[[target$ref]])

  parameters <- list(
    beta_low = stats::qlogis((est$estimate[est$parameter == "low"] - b4c$low_min) / b4c$low_w),
    beta_up = stats::qlogis(0.95),
    beta_logk = log(est$estimate[est$parameter == "k"]),
    beta_CT = unname(ct_start),
    beta_logz = unname(logz_start),
    log_phi = if (fam$family_code >= 1L) {
      log(est$estimate[est$parameter == "phi"])
    } else {
      log(100)
    },
    b_CT = numeric(0),   # no RE on the contrast refit
    log_sd_CT = 0,
    b_logz = numeric(0),
    log_sd_logz = 0,
    b_low = numeric(0),
    log_sd_low = 0,
    b_logk = numeric(0),
    log_sd_logk = 0
  )
  # Recover beta_up exactly from up so the start sits at the MLE (disjoint bounds).
  up_hat <- est$estimate[est$parameter == "up"]
  up_frac <- (up_hat - b4c$up_min) / b4c$up_w
  parameters$beta_up <- stats::qlogis(min(max(up_frac, 1e-6), 1 - 1e-6))

  map <- list()
  if (identical(fam$family_code, 0L)) map$log_phi <- factor(NA)
  map$log_sd_CT <- factor(NA)   # no RE on the contrast refit
  map$log_sd_logz <- factor(NA)
  map$log_sd_low <- factor(NA)
  map$log_sd_logk <- factor(NA)

  engine <- fit_tls_engine(
    tmb_data = tmb_data, parameters = parameters, map = map, control = list()
  )

  recoded_fit <- list(
    family = fam,
    tref = fit$tref,
    group_levels = colnames(X),
    par = engine$par,
    logLik = -engine$opt$objective,
    obj = engine$obj,
    opt = engine$opt,
    sdreport = engine$sdreport,
    tmb_inputs = engine$tmb_inputs
  )
  class(recoded_fit) <- c("profile_tls", "tls_fit")

  # The contrast coordinate is the alt group's column: index = position of
  # `target$alt` among the non-reference levels, + 1 (the intercept column).
  alt_idx <- match(target$alt, lvl[-1L]) + 1L
  tmb_par <- if (identical(target$which_par, "dCTmax")) "beta_CT" else "beta_logz"
  par_names <- names(engine$par)
  pos <- tls_coord_position(par_names, tmb_par, alt_idx)
  theta_hat <- unname(engine$par[pos])

  coord_target <- list(
    kind = "coord", parm = target$parm,
    tmb_parameter = tmb_par, index = alt_idx, position = pos,
    theta_hat = theta_hat, transformation = "identity",
    link = "identity", scale = "identity",
    estimate = theta_hat, natural_name = target$parm
  )
  list(fit = recoded_fit, target = coord_target)
}

# ---- up fallback ------------------------------------------------------------

#' Wald/delta-method "profile" object for the upper asymptote `up`
#'
#' Under disjoint bounds `up` has its own coordinate `beta_up`, but freqTLS does not
#' yet profile it, so it reports the delta-method Wald interval for `up` (SPEC.md S10). The
#' returned object has the `"profile_tls_profile"` shape but carries no deviance
#' curve (`deviance` is empty) and an `interval_type`/`scale` of `"wald"`.
#'
#' @param fit A `profile_tls` fit.
#' @param level Confidence level.
#' @return A `"profile_tls_profile"` object for `up`.
#' @keywords internal
#' @noRd
tls_up_wald_profile <- function(fit, level, parm = "up") {
  wald <- tls_wald_natural(fit, level)
  row <- wald[wald$parameter == parm, , drop = FALSE]
  est <- fit$estimates$estimate[fit$estimates$parameter == parm]
  structure(
    list(
      parm = parm,
      profile_value = numeric(0),
      deviance = numeric(0),
      estimate = est,
      conf.low = if (nrow(row)) row$conf.low[1L] else NA_real_,
      conf.high = if (nrow(row)) row$conf.high[1L] else NA_real_,
      conf.status = "wald_fallback",
      cutoff = stats::qt(1 - (1 - level) / 2, df = tls_ci_df(fit))^2,
      level = level,
      scale = "identity",
      transformation = "identity"
    ),
    class = "profile_tls_profile"
  )
}

# ---- print ------------------------------------------------------------------

#' @describeIn profile.profile_tls Print a compact summary of the profile.
#' @param x A `"profile_tls_profile"` object.
#' @param digits Number of significant digits for the printed summary (default
#'   `4`).
#' @export
print.profile_tls_profile <- function(x, digits = 4, ...) {
  cli::cli_text("<freqTLS profile: {.val {x$parm}}>")
  cli::cli_text(
    "estimate {tls_fmt(x$estimate, digits)} | {round(100 * x$level)}% interval [",
    "{tls_fmt(x$conf.low, digits)}, {tls_fmt(x$conf.high, digits)}]"
  )
  type <- if (identical(x$conf.status, "wald_fallback")) "Wald/delta" else "profile"
  cli::cli_text("interval type: {type} | scale: {x$scale} | status: {x$conf.status}")
  if (length(x$deviance) > 0L) {
    cli::cli_text(
      "deviance grid: {length(x$deviance)} points | min D {tls_fmt(suppressWarnings(min(x$deviance, na.rm = TRUE)), digits)} | cutoff {tls_fmt(x$cutoff, digits)}"
    )
  }
  invisible(x)
}

#' Plot a profile-likelihood deviance curve
#'
#' `plot()` for a `"profile_tls_profile"` object draws the likelihood-ratio
#' deviance curve against the natural-scale parameter. A dotted horizontal line
#' marks the profile-t cutoff `qt(1 - alpha/2, df)^2`; a solid vertical line marks the
#' point estimate; dashed vertical lines mark the interval endpoints when they
#' are finite. The wording is deliberately "confidence" -- this
#' is a likelihood curve, never a posterior (SPEC.md S13). A non-closing side is
#' annotated rather than drawn as a closed bound.
#'
#' This is the per-parameter profile curve; the full Confidence-Eye interval
#' displays are added in Phase 4.
#'
#' @param x A `"profile_tls_profile"` object from [profile.profile_tls()].
#' @param ... Reserved; must be empty.
#' @return A `ggplot` object (invisibly when printed for its side effect).
#' @examples
#' d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
#' fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
#'                family = "binomial", tref = 1)
#' plot(profile(fit, "CTmax"))
#' @export
plot.profile_tls_profile <- function(x, ...) {
  dots <- list(...)
  if (length(dots) > 0L) {
    cli::cli_abort("{.arg ...} is reserved for future options.")
  }
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    cli::cli_abort("Plotting profile curves requires the {.pkg ggplot2} package.")
  }
  if (length(x$deviance) == 0L) {
    cli::cli_abort(c(
      "There is no deviance curve to plot for {.val {x$parm}}.",
      i = "{.val up} uses a Wald/delta interval and has no profile curve."
    ))
  }

  ok <- is.finite(x$deviance)
  df <- data.frame(value = x$profile_value[ok], deviance = x$deviance[ok])
  df <- df[order(df$value), , drop = FALSE]

  endpoints <- c(x$conf.low, x$conf.high)
  endpoints <- endpoints[is.finite(endpoints)]

  open_note <- switch(x$conf.status,
    open_both = "interval open on both sides (weakly identified)",
    open_lower = "interval open on the lower side (weakly identified)",
    open_upper = "interval open on the upper side (weakly identified)",
    NULL
  )

  caption <- paste0(
    "Profile likelihood-ratio confidence interval at ",
    round(100 * x$level), "% (profile-t). Scale: ", x$scale, "."
  )
  if (!is.null(open_note)) caption <- paste0(caption, " ", open_note, ".")

  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$value, y = .data$deviance)) +
    ggplot2::geom_hline(yintercept = x$cutoff, linetype = "dotted",
                        colour = "grey40") +
    ggplot2::geom_line(linewidth = 0.7, colour = "#377eb8") +
    ggplot2::geom_vline(xintercept = x$estimate, linewidth = 0.7) +
    ggplot2::labs(
      x = x$parm,
      y = "Deviance  2 * (logLik_hat - logLik_profile)",
      title = paste0("Profile likelihood for ", x$parm),
      caption = caption
    ) +
    ggplot2::theme_minimal()

  if (length(endpoints) > 0L) {
    p <- p + ggplot2::geom_vline(xintercept = endpoints, linetype = "dashed",
                                 colour = "grey30")
  }
  p
}
