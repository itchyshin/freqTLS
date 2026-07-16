# The bayesTLS-analogue comprehensive extractor. extract_tdt() returns the nested
# $z / $CTmax / $T_crit structure (draws + summary) bayesTLS produces, but the
# per-"draw" rows are parametric-bootstrap replicates (the frequentist analogue
# of posterior draws) rather than MCMC draws. Point estimates (`*_median`) are the
# MLE; intervals are bootstrap percentiles. z is threshold-invariant under the
# constant-shape model; CTmax shifts with the survival threshold; T_crit is the
# damage-rate-floor critical temperature derived per replicate.

#' Extract z, CTmax and (optionally) T_crit with bootstrap confidence intervals
#'
#' The frequentist analogue of `bayesTLS::extract_tdt()`. Runs a parametric bootstrap
#' (via the freqTLS engine), derives the thermal-death-time quantities on each
#' replicate, and returns the same nested `$z` / `$CTmax` / `$T_crit` structure
#' (each a list of `draws` + `summary`). The per-replicate tables are the
#' frequentist analogue of posterior draws; `*_median` is the maximum-likelihood
#' point estimate and `*_lower` / `*_upper` are bootstrap percentiles.
#'
#' @param object A `freq_tls` fit from [fit_4pl()] (or a `profile_tls` fit).
#' @param target_surv `"relative"` (curve midpoint, default), `"absolute"`
#'   (50% survival), or a numeric survival level in `(0, 1)` for an LTx CTmax.
#' @param lethal If `TRUE`, also derive `T_crit` (the damage-rate-floor critical
#'   temperature, `CTmax + z * log10(rate / 100)`, `rate` log-uniform over
#'   `TC_rate_range`), anchored at the fit's reference time.
#' @param TC_rate_range Damage-rate floor range (percent of lethal dose per hour)
#'   for `T_crit`. Default `c(0.1, 1)`.
#' @param nboot Number of bootstrap replicates (default 1000; smaller is faster).
#' @param level Confidence level (default 0.95).
#' @param seed Optional RNG seed for reproducible replicates / rate draws.
#' @param by Optional name for the grouping column; defaults to the fit moderator.
#' @return A list with `$z`, `$CTmax`, (`$T_crit` when `lethal`), and `$meta`.
#'   Each quantity is `list(draws = <tibble>, summary = <tibble>)`. Column names
#'   follow bayesTLS: `z_median/z_lower/z_upper` for z; `temp_median/temp_lower/
#'   temp_upper` for CTmax and T_crit; per-draw value columns are `z` / `temp`.
#' @seealso [fit_4pl()], [tls()], [get_z_summary()], [get_ctmax_summary()]
#' @examples
#' \donttest{
#' raw <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
#' dat <- standardize_data(
#'   raw, temp = "temp", duration = "duration",
#'   n_total = "total", n_surv = "survived"
#' )
#' fit <- fit_4pl(dat, family = "binomial", t_ref = 1, quiet = TRUE)
#' tdt <- extract_tdt(fit, nboot = 10, seed = 1)
#' tdt$CTmax$summary
#' }
#' @export
extract_tdt <- function(object, target_surv = "relative", lethal = FALSE,
                        TC_rate_range = c(0.1, 1), nboot = 1000L,
                        level = 0.95, seed = NULL, by = NULL) {
  if (inherits(object, "freq_tls")) {
    fit <- object$fit; meta <- object$meta
  } else if (inherits(object, "profile_tls")) {
    fit <- object; meta <- list()
  } else {
    cli::cli_abort("{.arg object} must be a {.cls freq_tls} or {.cls profile_tls} fit.")
  }

  if (is.character(target_surv)) {
    target_surv <- match.arg(target_surv, c("relative", "absolute"))
    mode <- target_surv
    p <- if (identical(mode, "absolute")) 0.5 else NA_real_
  } else if (is.numeric(target_surv) && length(target_surv) == 1L &&
             target_surv > 0 && target_surv < 1) {
    mode <- "absolute"; p <- as.numeric(target_surv)
  } else {
    cli::cli_abort('{.arg target_surv} must be "relative", "absolute", or a number in (0, 1).')
  }

  alpha <- (1 - level) / 2; qs <- c(alpha, 1 - alpha)
  boot <- tls_bootstrap_replicates(fit, nboot = nboot, seed = seed)
  R <- boot$replicates[boot$converged, , drop = FALSE]
  if (nrow(R) < 2L)
    cli::cli_abort("Too few converged bootstrap replicates ({nrow(R)}); increase {.arg nboot}.")

  est <- fit$estimates
  by_name <- (by %||% meta$moderators %||% "group")[1L]
  clean <- function(g) {
    if (is.na(g)) return(NA_character_)
    if (startsWith(g, by_name)) sub(paste0("^", by_name), "", g) else g
  }
  mk_draws <- function(gl, v, value_name, extra = NULL) {
    cols <- list()
    if (!is.na(gl)) cols[[by_name]] <- gl
    cols$.draw <- seq_along(v)
    cols[[value_name]] <- v
    if (!is.null(extra)) cols <- c(cols, extra)
    as.data.frame(cols, stringsAsFactors = FALSE)
  }
  mk_summ <- function(gl, med, q2, nms) {
    cols <- list()
    if (!is.na(gl)) cols[[by_name]] <- gl
    cols[[nms[1L]]] <- med; cols[[nms[2L]]] <- q2[[1L]]; cols[[nms[3L]]] <- q2[[2L]]
    as.data.frame(cols, stringsAsFactors = FALSE)
  }

  ct_rows <- est[grepl("^CTmax(:|$)", est$parameter), , drop = FALSE]
  z_rows  <- est[grepl("^z(:|$)",   est$parameter), , drop = FALSE]
  low_v <- R[, "low"]; up_v <- R[, "up"]; k_v <- R[, "k"]
  low_mle <- est$estimate[est$parameter == "low"][1L]
  up_mle  <- est$estimate[est$parameter == "up"][1L]
  k_mle   <- est$estimate[est$parameter == "k"][1L]

  # Grouped iff coefficients are level-tagged ("CTmax:lvl"); an ungrouped fit's
  # single "all"/intercept level is not surfaced as a group column.
  grouped <- any(grepl(":", ct_rows$parameter))
  z_d <- z_s <- c_d <- c_s <- t_d <- t_s <- vector("list", nrow(ct_rows))
  for (i in seq_len(nrow(ct_rows))) {
    g  <- ct_rows$group[i]; gl <- if (grouped) clean(g) else NA_character_
    zi <- if (is.na(g)) 1L else match(g, z_rows$group)
    z_v <- R[, z_rows$parameter[zi]]; z_mle <- z_rows$estimate[zi]
    ctr_v <- R[, ct_rows$parameter[i]]; ctr_mle <- ct_rows$estimate[i]

    z_d[[i]] <- mk_draws(gl, z_v, "z")
    z_s[[i]] <- mk_summ(gl, z_mle, stats::quantile(z_v, qs, names = FALSE),
                        c("z_median", "z_lower", "z_upper"))

    if (identical(mode, "absolute")) {
      ct_v   <- ctr_v   - z_v   * stats::qlogis((p - low_v)  / (up_v  - low_v))  / k_v
      ct_mle <- ctr_mle - z_mle * stats::qlogis((p - low_mle) / (up_mle - low_mle)) / k_mle
    } else {
      ct_v <- ctr_v; ct_mle <- ctr_mle
    }
    c_d[[i]] <- mk_draws(gl, ct_v, "temp")
    c_s[[i]] <- mk_summ(gl, ct_mle, stats::quantile(ct_v, qs, names = FALSE),
                        c("temp_median", "temp_lower", "temp_upper"))

    if (isTRUE(lethal)) {
      rate <- exp(stats::runif(length(z_v), log(TC_rate_range[1L]), log(TC_rate_range[2L])))
      tc_v <- ctr_v + z_v * log10(rate / 100)
      rate_mid <- sqrt(prod(TC_rate_range))
      tc_mle <- ctr_mle + z_mle * log10(rate_mid / 100)
      t_d[[i]] <- mk_draws(gl, tc_v, "temp", extra = list(log10_rate = log10(rate)))
      t_s[[i]] <- mk_summ(gl, tc_mle, stats::quantile(tc_v, qs, names = FALSE),
                          c("temp_median", "temp_lower", "temp_upper"))
    }
  }

  bind <- function(l) tibble::as_tibble(do.call(rbind, l))
  out <- list(
    z     = list(draws = bind(z_d), summary = bind(z_s)),
    CTmax = list(draws = bind(c_d), summary = bind(c_s)),
    T_crit = if (isTRUE(lethal)) list(draws = bind(t_d), summary = bind(t_s)) else NULL,
    meta = list(
      target_surv = if (identical(mode, "relative")) "relative" else sprintf("p=%.3f", p),
      mode = mode, p = p, lethal = lethal, TC_rate_range = TC_rate_range,
      by = if (grouped) by_name else NULL,
      nboot = nrow(R), level = level
    )
  )
  class(out) <- c("freq_tdt", "list")
  out
}

#' @export
print.freq_tdt <- function(x, ...) {
  cat(sprintf("<freq_tdt> %s threshold; %d bootstrap replicates%s\n",
              x$meta$target_surv, x$meta$nboot,
              if (isTRUE(x$meta$lethal)) "; T_crit included" else ""))
  cat("  $z, $CTmax", if (!is.null(x$T_crit)) ", $T_crit" else "", " (each $draws + $summary)\n", sep = "")
  invisible(x)
}

# ---- accessors (analogues of bayesTLS get_*_summary / get_*_draws) ------------

stop_if_not_freq_tdt <- function(et) {
  if (!is.list(et) || is.null(et$z) || is.null(et$CTmax))
    cli::cli_abort("{.arg et} must be an {.fn extract_tdt} result (with {.field $z} and {.field $CTmax}).")
}

#' Accessors for an extract_tdt() result
#'
#' Analogues of the bayesTLS `get_*_summary` / `get_*_draws` accessors. `*_summary`
#' returns the median + interval tibble; `*_draws` returns the per-replicate
#' (bootstrap) tibble — the frequentist analogue of posterior draws.
#'
#' @param et An [extract_tdt()] result.
#' @return A tibble (see [extract_tdt()] for the column contract).
#' @examples
#' \donttest{
#' raw <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
#' dat <- standardize_data(
#'   raw, temp = "temp", duration = "duration",
#'   n_total = "total", n_surv = "survived"
#' )
#' fit <- fit_4pl(dat, family = "binomial", t_ref = 1, quiet = TRUE)
#' tdt <- extract_tdt(fit, nboot = 10, seed = 1)
#' get_z_summary(tdt)
#' get_ctmax_draws(tdt)
#' }
#' @name tdt-accessors
NULL

#' @rdname tdt-accessors
#' @export
get_z_summary <- function(et) { stop_if_not_freq_tdt(et); et$z$summary }

#' @rdname tdt-accessors
#' @export
get_z_draws <- function(et) { stop_if_not_freq_tdt(et); et$z$draws }

#' @rdname tdt-accessors
#' @export
get_ctmax_summary <- function(et) { stop_if_not_freq_tdt(et); et$CTmax$summary }

#' @rdname tdt-accessors
#' @export
get_ctmax_draws <- function(et) {
  stop_if_not_freq_tdt(et)
  d <- et$CTmax$draws
  names(d)[names(d) == "temp"] <- "CTmax"
  d
}

#' @rdname tdt-accessors
#' @export
get_tcrit_summary <- function(et) {
  stop_if_not_freq_tdt(et)
  if (is.null(et$T_crit))
    cli::cli_abort("This {.fn extract_tdt} result has no T_crit; call with {.code lethal = TRUE}.")
  et$T_crit$summary
}

#' @rdname tdt-accessors
#' @export
get_tcrit_draws <- function(et) {
  stop_if_not_freq_tdt(et)
  if (is.null(et$T_crit))
    cli::cli_abort("This {.fn extract_tdt} result has no T_crit; call with {.code lethal = TRUE}.")
  d <- et$T_crit$draws
  names(d)[names(d) == "temp"] <- "T_crit"
  d
}
