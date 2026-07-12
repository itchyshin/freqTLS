# The bayesTLS-twin survival-surface predictor. predict_survival_curves() returns
# the fitted survival probability over a temperature x duration grid with
# confidence bands, in bayesTLS's $summary shape (survival_lower/median/upper).
# Bands come from the parametric bootstrap (the freq analogue of posterior draws);
# the per-cell survival is the forward 4PL evaluated at each replicate's natural
# parameters, matching the engine's predict()/src/profile_tls.cpp forward map.

#' Predict the fitted survival surface with bootstrap confidence bands
#'
#' The frequentist twin of `bayesTLS::predict_survival_curves()`. Evaluates the
#' fitted 4PL survival probability over a temperature-by-duration grid and adds
#' parametric-bootstrap confidence bands. For random-effects fits the curves are
#' population-level: random intercepts are integrated during bootstrap refits,
#' but no fitted group BLUP is added to the reported curve.
#'
#' @param object A `freq_tls` fit from [fit_4pl()] (or a `profile_tls` fit).
#' @param temps Temperatures to predict at (default: the observed assay temps).
#' @param durations Exposure durations (default: 100 points log-spaced over the
#'   observed range, in the data's duration unit).
#' @param nboot Number of bootstrap replicates for the bands (default 500).
#' @param level Confidence level (default 0.95).
#' @param seed Optional RNG seed.
#' @param by Optional name for the grouping column.
#' @return A `freq_surv_curves` object: `$summary` (a tibble of
#'   `[<group>,] temp, duration, survival_lower, survival_median, survival_upper`)
#'   and `$meta`.
#' @seealso [fit_4pl()], [predict_survival_surface()], [tls()]
#' @examples
#' \donttest{
#' raw <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
#' dat <- standardize_data(
#'   raw, temp = "temp", duration = "duration",
#'   n_total = "total", n_surv = "survived"
#' )
#' fit <- fit_4pl(dat, family = "binomial", t_ref = 1, quiet = TRUE)
#' curves <- predict_survival_curves(
#'   fit, temps = c(34, 36), durations = c(1, 4), nboot = 10, seed = 1
#' )
#' curves$summary
#' }
#' @export
predict_survival_curves <- function(object, temps = NULL, durations = NULL,
                                    nboot = 500L, level = 0.95, seed = NULL,
                                    by = NULL) {
  if (inherits(object, "freq_tls")) {
    fit <- object$fit; meta <- object$meta
  } else if (inherits(object, "profile_tls")) {
    fit <- object; meta <- list()
  } else {
    cli::cli_abort("{.arg object} must be a {.cls freq_tls} or {.cls profile_tls} fit.")
  }

  ds <- fit$data_summary
  if (is.null(temps)) temps <- sort(unique(fit$diag_data$temp))
  if (is.null(durations))
    durations <- 10^seq(log10(ds$time_range[1L]), log10(ds$time_range[2L]),
                        length.out = 100L)
  if (!is.numeric(temps) || !is.numeric(durations) || any(durations <= 0))
    cli::cli_abort("{.arg temps} and {.arg durations} must be numeric; durations strictly positive.")

  tref <- fit$tref
  est <- fit$estimates
  by_name <- (by %||% meta$moderators %||% "group")[1L]
  grouped <- any(grepl("^CTmax:", est$parameter))

  boot <- tls_bootstrap_replicates(fit, nboot = nboot, seed = seed)
  R <- boot$replicates[boot$converged, , drop = FALSE]
  if (nrow(R) < 2L)
    cli::cli_abort("Too few converged bootstrap replicates ({nrow(R)}); increase {.arg nboot}.")
  low_v <- R[, "low"]; up_v <- R[, "up"]; k_v <- R[, "k"]

  # Forward 4PL (descending), identical to src/profile_tls.cpp:
  #   mid = log10(tref) - (temp - CTmax)/z ; survival = low + (up-low)/(1+exp(k(logd - mid)))
  fwd <- function(temp, dur, CT, z) {
    mid <- log10(tref) - (temp - CT) / z
    low_v + (up_v - low_v) / (1 + exp(k_v * (log10(dur) - mid)))
  }
  alpha <- (1 - level) / 2; qs <- c(alpha, 0.5, 1 - alpha)
  clean <- function(g) if (!is.na(g) && startsWith(g, by_name)) sub(paste0("^", by_name), "", g) else g

  groups <- if (grouped) unique(est$group[grepl("^CTmax", est$parameter)]) else NA_character_
  parts <- vector("list", length(groups))
  for (gi in seq_along(groups)) {
    g <- groups[gi]
    ct_col <- if (grouped) paste0("CTmax:", g) else "CTmax"
    z_col  <- if (grouped) paste0("z:",   g) else "z"
    CT_r <- R[, ct_col]; z_r <- R[, z_col]
    grid <- expand.grid(temp = temps, duration = durations,
                        KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
    qmat <- vapply(seq_len(nrow(grid)), function(i) {
      stats::quantile(fwd(grid$temp[i], grid$duration[i], CT_r, z_r), qs, names = FALSE)
    }, numeric(3))
    d <- data.frame(grid, survival_lower = qmat[1, ], survival_median = qmat[2, ],
                    survival_upper = qmat[3, ], stringsAsFactors = FALSE)
    if (grouped) { d[[by_name]] <- clean(g); d <- d[, c(by_name, setdiff(names(d), by_name))] }
    parts[[gi]] <- d
  }

  out <- list(
    summary = tibble::as_tibble(do.call(rbind, parts)),
    meta = list(nboot = nrow(R), level = level,
                by = if (grouped) by_name else NULL)
  )
  class(out) <- c("freq_surv_curves", "list")
  out
}

#' @export
print.freq_surv_curves <- function(x, ...) {
  cat(sprintf("<freq_surv_curves> %d grid cells; %d bootstrap replicates\n",
              nrow(x$summary), x$meta$nboot))
  print(utils::head(x$summary))
  invisible(x)
}
