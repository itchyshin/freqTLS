#' Tidy the parameters of a fitted freqTLS model
#'
#' `tidy_parameters()` returns a broom-style tibble of the natural-scale
#' parameter estimates with optional Wald confidence intervals. The intervals
#' are computed on the internal (unconstrained / link) scale as
#' `estimate +/- z * std.error` and then back-transformed to the natural scale,
#' so they respect each parameter's bounds (for example `z > 0`, `0 < low < up`)
#' and are equivariant under the link. For `CTmax` (identity link) this is the
#' usual symmetric Wald interval.
#'
#' With `method = "profile"` the intervals are profile-likelihood confidence
#' intervals (see [confint.profile_tls()]); with `method = "wald"` (default) they
#' are the back-transformed internal-link Wald intervals. The returned shape is
#' identical; only `interval_type` and the interval values differ. A profile that
#' does not close returns `NA` on the open side (never a fabricated bound).
#'
#' @param fit A `profile_tls` fit from [fit_tls()].
#' @param conf.int Logical; include `conf.low` / `conf.high` columns (default
#'   `TRUE`).
#' @param conf.level Confidence level for the interval (default `0.95`).
#' @param method Either `"wald"` (default) or `"profile"`.
#'
#' @return A [tibble][tibble::tibble] with one row per natural-scale parameter
#'   and the columns `parameter`, `group`, `estimate`, `std.error`,
#'   `conf.low`, `conf.high`, `interval_type`, and `scale`. `scale` is the link
#'   on which the interval was constructed (`"identity"`, `"log"`, or
#'   `"logit"`); `interval_type` is `"wald"` or `"profile"`.
#'
#' @examples
#' d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
#' fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
#'                family = "binomial", tref = 60)
#' tidy_parameters(fit)
#' tidy_parameters(fit, method = "profile")
#'
#' @export
tidy_parameters <- function(fit, conf.int = TRUE, conf.level = 0.95,
                            method = c("wald", "profile")) {
  if (inherits(fit, "freq_tls")) fit <- fit$fit
  if (!inherits(fit, "profile_tls")) {
    cli::cli_abort("{.arg fit} must be a {.cls profile_tls} object from {.fn fit_tls}.")
  }
  if (!is.numeric(conf.level) || length(conf.level) != 1L ||
      conf.level <= 0 || conf.level >= 1) {
    cli::cli_abort("{.arg conf.level} must be a single number in (0, 1).")
  }
  method <- match.arg(method)

  est <- fit$estimates
  scale <- tls_param_scale(est$parameter, fit$name_map)

  conf.low <- rep(NA_real_, nrow(est))
  conf.high <- rep(NA_real_, nrow(est))
  interval_type <- rep(if (isTRUE(conf.int)) method else "none", nrow(est))

  if (isTRUE(conf.int) && identical(method, "wald")) {
    wald <- tls_wald_natural(fit, conf.level)
    idx <- match(est$parameter, wald$parameter)
    conf.low <- wald$conf.low[idx]
    conf.high <- wald$conf.high[idx]
  } else if (isTRUE(conf.int) && identical(method, "profile")) {
    ci <- confint(fit, parm = est$parameter, level = conf.level, method = "profile")
    idx <- match(est$parameter, ci$parameter)
    conf.low <- ci$conf.low[idx]
    conf.high <- ci$conf.high[idx]
    # Per-row honesty: `up` falls back to Wald/delta even under method="profile".
    interval_type <- ci$method[idx]
  }

  tibble::tibble(
    parameter = est$parameter,
    group = est$group,
    estimate = est$estimate,
    std.error = est$std.error,
    conf.low = conf.low,
    conf.high = conf.high,
    interval_type = interval_type,
    scale = scale
  )
}

#' Extract the CTmax estimate(s)
#'
#' @param fit A `profile_tls` fit from [fit_tls()].
#' @param conf.int Logical; include confidence-interval columns (default
#'   `TRUE`).
#' @param conf.level Confidence level for the interval (default `0.95`).
#' @param method Either `"wald"` (default) or `"profile"`.
#' @return A [tibble][tibble::tibble] of the `CTmax` row(s) from
#'   [tidy_parameters()].
#' @examples
#' d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
#' fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
#'                family = "binomial", tref = 60)
#' get_ctmax(fit)
#' @export
get_ctmax <- function(fit, conf.int = TRUE, conf.level = 0.95,
                      method = c("wald", "profile")) {
  method <- match.arg(method)
  tidy <- tidy_parameters(fit, conf.int = conf.int, conf.level = conf.level,
                          method = method)
  tidy[startsWith(tidy$parameter, "CTmax"), , drop = FALSE]
}

#' Extract the thermal-sensitivity (z) estimate(s)
#'
#' @inheritParams get_ctmax
#' @return A [tibble][tibble::tibble] of the `z` row(s) from
#'   [tidy_parameters()].
#' @examples
#' d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
#' fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
#'                family = "binomial", tref = 60)
#' get_z(fit)
#' @export
get_z <- function(fit, conf.int = TRUE, conf.level = 0.95,
                  method = c("wald", "profile")) {
  method <- match.arg(method)
  tidy <- tidy_parameters(fit, conf.int = conf.int, conf.level = conf.level,
                          method = method)
  tidy[startsWith(tidy$parameter, "z"), , drop = FALSE]
}

#' Extract the shape parameters (low, up, k, and phi)
#'
#' @inheritParams get_ctmax
#' @details With `method = "profile"`, a shape parameter receives a profile
#'   interval only where [tidy_parameters()] supports that coordinate; `up` and
#'   unsupported shape coordinates retain their documented Wald route.
#' @return A [tibble][tibble::tibble] of the shape rows (`low`, `up`, `k`, and
#'   `phi` for the beta-binomial family) from [tidy_parameters()].
#' @examples
#' d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
#' fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
#'                family = "binomial", tref = 60)
#' get_shape(fit)
#' @export
get_shape <- function(fit, conf.int = TRUE, conf.level = 0.95,
                      method = c("wald", "profile")) {
  method <- match.arg(method)
  tidy <- tidy_parameters(fit, conf.int = conf.int, conf.level = conf.level,
                          method = method)
  tidy[tidy$parameter %in% c("low", "up", "k", "phi"), , drop = FALSE]
}

#' Natural-scale link for each natural-scale parameter
#'
#' Maps each human-facing parameter name to the link on which its Wald interval
#' is constructed, using the fit's `name_map`. `up` is reported on the identity
#' scale here because its Wald interval is delta-method based (freqTLS does not yet
#' profile the disjoint-bounds `up` coordinate `beta_up`; its interval comes from the
#' ADREPORTed `up` SE).
#'
#' @param parameter Character vector of natural-scale parameter names.
#' @param name_map The fit's `name_map` data frame.
#' @return Character vector of link names aligned with `parameter`.
#' @keywords internal
#' @noRd
tls_param_scale <- function(parameter, name_map) {
  vapply(parameter, function(p) {
    if (identical(p, "up")) return("identity")
    hit <- which(name_map$natural == p)
    if (length(hit) == 0L) return(NA_character_)
    name_map$link[hit[1L]]
  }, character(1L), USE.NAMES = FALSE)
}

#' Wald confidence intervals on the natural scale
#'
#' Builds confidence intervals on the internal (link) scale from the fixed-effect
#' part of the [TMB::sdreport()] and back-transforms the endpoints. `up` uses a
#' delta-method interval on the natural scale taken from the ADREPORTed `up`
#' standard error (freqTLS does not yet profile the disjoint-bounds `up`
#' coordinate `beta_up`).
#'
#' @param fit A `profile_tls` fit.
#' @param conf.level Confidence level.
#' @return A data frame with `parameter`, `conf.low`, `conf.high`.
#' @keywords internal
#' @noRd
tls_wald_natural <- function(fit, conf.level) {
  est <- fit$estimates
  zq <- stats::qt(1 - (1 - conf.level) / 2, df = tls_ci_df(fit))

  conf.low <- rep(NA_real_, nrow(est))
  conf.high <- rep(NA_real_, nrow(est))

  sdr <- fit$sdreport
  if (is.null(sdr)) {
    return(data.frame(
      parameter = est$parameter, conf.low = conf.low, conf.high = conf.high,
      stringsAsFactors = FALSE
    ))
  }

  # Internal-scale estimates + SEs, indexed positionally to match name_map
  # (grouped fits repeat row names such as "beta_CT").
  fixed <- summary(sdr, select = "fixed")
  nm <- fit$name_map

  # Position of each internal coordinate within the fixed-effect summary, in
  # name_map order. log_phi is mapped out for the binomial family and absent
  # from name_map there, so this stays aligned.
  link_endpoints <- function(internal_name, link, occurrence) {
    rows <- which(rownames(fixed) == internal_name)
    if (length(rows) < occurrence) return(c(NA_real_, NA_real_))
    r <- rows[occurrence]
    e <- fixed[r, "Estimate"]
    se <- fixed[r, "Std. Error"]
    lo_i <- e - zq * se
    hi_i <- e + zq * se
    # `low` lives on a disjoint-bounds logit: low = low_min + low_w * plogis(beta_low),
    # so its Wald endpoints must be rescaled to the natural scale (not plain plogis).
    if (internal_name == "beta_low") {
      bb <- fit$tmb_inputs$data
      return(c(bb$low_min + bb$low_w * stats::plogis(lo_i),
               bb$low_min + bb$low_w * stats::plogis(hi_i)))
    }
    c(tls_backtransform(lo_i, link), tls_backtransform(hi_i, link))
  }

  # Track how many times we have seen each internal base name (for the repeated
  # beta_CT / beta_logz rows in grouped fits).
  seen <- list()
  for (i in seq_len(nrow(nm))) {
    base <- sub("\\[.*$", "", nm$internal[i])
    occ <- (seen[[base]] %||% 0L) + 1L
    seen[[base]] <- occ
    natural <- nm$natural[i]
    if (identical(natural, "gap")) next  # `up` handled separately below
    target_rows <- which(est$parameter == natural)
    if (length(target_rows) == 0L) next
    ep <- link_endpoints(base, nm$link[i], occ)
    conf.low[target_rows] <- ep[1L]
    conf.high[target_rows] <- ep[2L]
  }

  # `up` (or per-group `up:<level>`): delta-method Wald on the natural scale from
  # the ADREPORTed `up` SE (disjoint-bounds beta_up not yet profiled).
  # The ADREPORT `up` order matches the estimates-table `up` rows (both in the
  # shape-design / group-level order).
  rep_sum <- summary(sdr, select = "report")
  up_hits <- which(rownames(rep_sum) == "up")
  up_rows_idx <- which(est$parameter == "up" | startsWith(est$parameter, "up:"))
  if (length(up_hits) == length(up_rows_idx) && length(up_hits) >= 1L) {
    for (j in seq_along(up_hits)) {
      r <- up_rows_idx[j]
      up_est <- rep_sum[up_hits[j], "Estimate"]
      up_se <- rep_sum[up_hits[j], "Std. Error"]
      conf.low[r] <- up_est - zq * up_se
      conf.high[r] <- up_est + zq * up_se
    }
  }

  # Random-effects SDs (`sigma_CTmax` / `sigma_logz`): Wald interval on the log
  # scale, exp() of log_sd_* +/- z * se, so the interval stays positive. The
  # profile / bootstrap paths are the RE-aware alternatives for the fixed effects;
  # the variance components themselves keep this log-scale Wald interval.
  for (sg in list(c("sigma_CTmax", "log_sd_CT"), c("sigma_logz", "log_sd_logz"),
                  c("sigma_low", "log_sd_low"), c("sigma_logk", "log_sd_logk"))) {
    sig_row <- which(est$parameter == sg[1L])
    if (length(sig_row) == 1L) {
      rows <- which(rownames(fixed) == sg[2L])
      if (length(rows) >= 1L) {
        ls_est <- fixed[rows[1L], "Estimate"]
        ls_se <- fixed[rows[1L], "Std. Error"]
        conf.low[sig_row] <- exp(ls_est - zq * ls_se)
        conf.high[sig_row] <- exp(ls_est + zq * ls_se)
      }
    }
  }

  data.frame(
    parameter = est$parameter, conf.low = conf.low, conf.high = conf.high,
    stringsAsFactors = FALSE
  )
}
