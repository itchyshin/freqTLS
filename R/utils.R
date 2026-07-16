#' Default value for `NULL`
#'
#' Returns `x` unless it is `NULL`, in which case it returns `y`.
#'
#' @param x,y Values; `x` is returned unless `NULL`.
#' @return `x` if not `NULL`, otherwise `y`.
#' @keywords internal
#' @noRd
`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

# ---- link / back-transform helpers -----------------------------------------
# Internal parameters are unconstrained; these map to / from the natural scale.

#' Residual degrees of freedom for the t-based interval calibration
#'
#' Bates-Watts profile-t / Wald-t intervals compare the (signed-root) statistic
#' to a t distribution with `n - p` degrees of freedom: `n` data rows, `p`
#' estimated parameters. This is the small-sample correction the asymptotic
#' chi-square / normal calibration lacks (it converges to it as `df -> Inf`). For
#' random-effects fits the conditional modes are integrated out, so `n - p`
#' over-states the df (approximate; the coverage simulation validates it).
#' @keywords internal
#' @noRd
tls_ci_df <- function(fit) {
  n_obs <- length(fit$diag_data$y)
  p <- length(fit$par)
  max(n_obs - p, 1L)
}

#' Back-transform an internal coordinate to its natural scale
#'
#' @param x Numeric value(s) on the internal (unconstrained) scale.
#' @param link One of "log", "logit", or "identity".
#' @return Numeric value(s) on the natural scale.
#' @keywords internal
#' @noRd
tls_backtransform <- function(x, link) {
  switch(link,
    log = exp(x),
    logit = stats::plogis(x),
    identity = x,
    cli::cli_abort("Unknown link {.val {link}}.")
  )
}

#' Transform a natural-scale value to its internal coordinate
#'
#' @param x Numeric value(s) on the natural scale.
#' @param link One of "log", "logit", or "identity".
#' @return Numeric value(s) on the internal (unconstrained) scale.
#' @keywords internal
#' @noRd
tls_link <- function(x, link) {
  switch(link,
    log = log(x),
    logit = stats::qlogis(x),
    identity = x,
    cli::cli_abort("Unknown link {.val {link}}.")
  )
}

#' Is a design matrix a one-hot factor indicator?
#'
#' Distinguishes a grouped (factor) shape design -- a clean 0/1 indicator with
#' exactly one 1 per row and no intercept, whose columns are group levels -- from
#' a general design (e.g. a continuous covariate, which carries an intercept so
#' the row sums are not all 1). A single-column (intercept-only) design is not a
#' one-hot grouping; callers handle that as the scalar shared case first.
#' @param X A design matrix.
#' @return `TRUE` for a multi-column one-hot indicator, else `FALSE`.
#' @keywords internal
#' @noRd
tls_is_onehot <- function(X) {
  ncol(X) > 1L && all(X %in% c(0, 1)) && all(abs(rowSums(X) - 1) < 1e-9)
}

#' Does a fit carry any random-effects block?
#'
#' `TRUE` when the fit has a random intercept on `CTmax` (`fit$re`) and/or on
#' `log_z` (`fit$re_logz`). Routing code (confint / profile / bootstrap /
#' plotting) keys "is this a random-effects fit?" on this rather than on a single
#' sub-parameter, so a `log_z`-only RE fit is not silently treated as
#' fixed-effects-only.
#' @param fit A `profile_tls` fit.
#' @return Logical scalar.
#' @keywords internal
#' @noRd
tls_has_re <- function(fit) {
  !is.null(fit$re) || !is.null(fit$re_logz) ||
    !is.null(fit$re_low) || !is.null(fit$re_logk)
}

#' Describe the active random-effects blocks of a fit
#'
#' Returns one descriptor per active random-intercept block (`CTmax` first, then
#' `log_z`), the single source of truth for the per-block bookkeeping that ranef,
#' the `sigma_*` rows, the profile re-Laplace, and the bootstrap redraw all share.
#' Each descriptor names the engine vector (`b_name`), its log-SD parameter
#' (`sd_name`), the REPORTed SD (`sigma_report`), the human-facing SD label
#' (`sigma_label`), the BLUP term label (`term`), and the parsed `spec`
#' (`index` / `n` / `group_levels` / `group_var`).
#' @param fit A `profile_tls` fit.
#' @return A list of block descriptors (empty for a fixed-effects-only fit).
#' @keywords internal
#' @noRd
tls_re_blocks <- function(fit) {
  blocks <- list()
  if (!is.null(fit$re)) {
    blocks[[length(blocks) + 1L]] <- list(
      param = "CTmax", b_name = "b_CT", sd_name = "log_sd_CT",
      sigma_report = "sigma_CT", sigma_label = "sigma_CTmax",
      term = "CTmax", spec = fit$re
    )
  }
  if (!is.null(fit$re_logz)) {
    blocks[[length(blocks) + 1L]] <- list(
      param = "log_z", b_name = "b_logz", sd_name = "log_sd_logz",
      sigma_report = "sigma_logz", sigma_label = "sigma_logz",
      term = "log_z", spec = fit$re_logz
    )
  }
  if (!is.null(fit$re_low)) {
    blocks[[length(blocks) + 1L]] <- list(
      param = "low", b_name = "b_low", sd_name = "log_sd_low",
      sigma_report = "sigma_low", sigma_label = "sigma_low",
      term = "low", spec = fit$re_low
    )
  }
  if (!is.null(fit$re_logk)) {
    blocks[[length(blocks) + 1L]] <- list(
      param = "log_k", b_name = "b_logk", sd_name = "log_sd_logk",
      sigma_report = "sigma_logk", sigma_label = "sigma_logk",
      term = "log_k", spec = fit$re_logk
    )
  }
  blocks
}

#' Build the parameter name map for a fitted model
#'
#' Connects each internal parameter coordinate to a natural-scale name, its
#' link, and (for grouped coordinates) the group level it refers to. This is the
#' contract used by profiling and printing.
#'
#' @param group_levels Character vector of group levels (length >= 1).
#' @param family A `tls_family` object (controls whether `phi` is present).
#' @return A `data.frame` with one row per internal coordinate.
#' @keywords internal
#' @noRd
tls_name_map <- function(group_levels, family, X_low, X_up, X_logk) {
  ng <- length(group_levels)

  # Shape coordinates. Each shape design is classified by its own columns:
  #   1 column                 -> the scalar shared `low` / `k`;
  #   >1 column, one-hot factor -> per-group `low:<level>` / `k:<level>` (natural);
  #   >1 column, general design -> per-coefficient `low:<col>` / `k:<col>` (link
  #                                scale, e.g. a continuous covariate slope).
  # `up` is reported via the ADREPORTed `up` SE (delta-method Wald), not a profile
  # coordinate, so it is surfaced separately from the shape coordinates.
  shape_block <- function(base, natural_base, link, X) {
    nc <- ncol(X)
    if (nc == 1L) {
      data.frame(internal = paste0(base, "[1]"), natural = natural_base,
                 link = link, group = NA_character_, stringsAsFactors = FALSE)
    } else {
      grp <- if (tls_is_onehot(X)) colnames(X) else NA_character_
      data.frame(internal = paste0(base, "[", seq_len(nc), "]"),
                 natural = paste0(natural_base, ":", colnames(X)),
                 link = link, group = grp, stringsAsFactors = FALSE)
    }
  }
  scalar <- rbind(
    shape_block("beta_low", "low", "logit", X_low),
    data.frame(internal = paste0("beta_up[", seq_len(ncol(X_up)), "]"),
               natural = "gap", link = "identity", group = NA_character_,
               stringsAsFactors = FALSE),
    shape_block("beta_logk", "k", "log", X_logk)
  )

  ct <- data.frame(
    internal = paste0("beta_CT[", seq_len(ng), "]"),
    natural = if (ng == 1L) "CTmax" else paste0("CTmax:", group_levels),
    link = "identity",
    group = group_levels,
    stringsAsFactors = FALSE
  )
  logz <- data.frame(
    internal = paste0("beta_logz[", seq_len(ng), "]"),
    natural = if (ng == 1L) "z" else paste0("z:", group_levels),
    link = "log",
    group = group_levels,
    stringsAsFactors = FALSE
  )

  out <- rbind(scalar, ct, logz)
  if (family$family_code >= 1L) {
    out <- rbind(
      out,
      data.frame(
        internal = "log_phi", natural = "phi", link = "log",
        group = NA_character_, stringsAsFactors = FALSE
      )
    )
  }
  out
}
