#' Predict cumulative heat injury under a temperature trace
#'
#' `predict_heat_injury()` is the deterministic, maximum-likelihood **prediction**
#' analogue of `bayesTLS::predict_heat_injury()`: given a fitted thermal-load-
#' sensitivity curve and a temperature time-series (a "trace"), it accumulates
#' thermal damage as a fraction of the lethal dose and reads survival back off the
#' fitted 4PL. It does **not** fit an injury or repair model -- fitting injury /
#' repair dynamics remains a `bayesTLS` concern (the complementary boundary);
#' `predict_heat_injury()` only predicts injury from the already-fitted survival
#' curve. For a random-effects fit it uses the population curve and does not add
#' a fitted group BLUP (best linear unbiased predictor; see [ranef()]).
#'
#' @details
#' ## Dose-accumulation model
#' One **lethal dose** is the thermal load that drives survival to a target set by
#' `target_surv`. With the default `target_surv = NULL` the target is the
#' project-default **relative** threshold -- the curve midpoint `(low + up) / 2`.
#' At temperature `T` the lethal time to the target is
#' `LT(T) = tref * 10^((CTmax - T) / z - q / k)`, with
#' `q = qlogis((target_surv - low) / (up - low))` (so `q = 0` at the midpoint, the
#' same quantity as [derive_lt()] at survival `target_surv`). The instantaneous
#' damage rate is `1 / LT(T)` (lethal doses per time unit). Cumulative dose is
#' accumulated by forward Euler over the trace, using the actual per-step time
#' increments:
#' \deqn{D_j = \max\!\big(0,\; D_{j-1} + (\mathrm{dmg}(T_{j-1}) -
#'   \mathrm{rep}_{j-1})\,\Delta t_j\big),\quad D_1 = 0,}
#' where \eqn{\Delta t_j = t_j - t_{j-1}}. Survival is read back from the 4PL by
#' treating the accumulated dose as an equivalent `log10`-time:
#' `survival(D) = low + (up - low) * plogis(-k * log10(D) + q)`, so `D = 1` (one
#' lethal dose) reaches exactly `target_surv` -- the relative midpoint
#' `(low + up) / 2` by default, or an **absolute** survival threshold when
#' `target_surv` is supplied.
#'
#' The trace `time` and the fit's duration / `tref` **must share a time unit**
#' (the damage rate is per that unit). With `irreversible = TRUE` (default)
#' survival is monotone non-increasing. A damage cutoff `t_c` (for example from
#' [derive_tcrit()]) sets the damage rate to zero at or below `t_c`.
#' Heat-injury prediction currently requires shared fixed-effect shape formulas;
#' a varying shape would need to be re-evaluated along the temperature trace.
#'
#' This integrator is forward Euler (left-endpoint, per actual step), not the
#' single-`dt` scheme some implementations use; irregular traces are integrated
#' with their real increments.
#'
#' ## Repair (optional, not identified by the data)
#' If `repair` is supplied, a Sharpe-Schoolfield repair rate is subtracted each
#' step (scaled by the current survival fraction, so repair shrinks as the
#' population dies). The repair parameters are a **user-supplied scenario layer**:
#' they are not identified by the survival data the model was fitted to, so
#' `predict_heat_injury()` warns when they are used. `repair` is a named list with
#' `r_ref`, `t_a`, `t_al`, `t_ah`, `t_l`, `t_h`, `t_ref`, with the four reference
#' temperatures in **Kelvin**.
#'
#' @param object A `profile_tls` fit from [fit_tls()], or a `freq_tls` workflow
#'   from [fit_4pl()].
#' @param trace A data frame with numeric columns `time` (strictly increasing,
#'   at least two rows) and `temp` (degrees C).
#' @param group Optional single group level (grouped fits only; required when the
#'   fit is grouped).
#' @param target_surv Optional absolute survival threshold defining one lethal
#'   dose: a single probability strictly between the fitted lower and upper
#'   asymptotes. `NULL` (default) uses the project-default relative threshold (the
#'   curve midpoint `(low + up) / 2`), matching [derive_ctmax()] and [derive_lt()].
#'   For a bootstrap envelope the target must also be attainable in every
#'   converged bootstrap refit; otherwise the function aborts rather than clipping
#'   an invalid refit's threshold.
#' @param t_c Optional damage-cutoff temperature (degrees C): at or below it the
#'   damage rate is zero. `NULL` (default) applies no cutoff.
#' @param repair Optional named list of Sharpe-Schoolfield repair parameters (see
#'   Details); `NULL` (default) means no repair.
#' @param irreversible Logical; if `TRUE` (default) survival is monotone
#'   non-increasing (mortality does not reverse even if dose is repaired).
#'
#' @return A data frame with columns `time`, `temp`, `dose` (cumulative, as a
#'   fraction of the lethal dose), `injury` (`dose * 100`, percent), and
#'   `survival`.
#'
#' @seealso [derive_lt()] for the lethal time, [derive_tcrit()] for a damage
#'   cutoff temperature.
#' @examples
#' d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
#' fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
#'                family = "binomial", tref = 60)
#' trace <- data.frame(time = seq(0, 2, by = 0.05),
#'                     temp = 34 + 6 * sin(seq(0, 2, by = 0.05)))
#' head(predict_heat_injury(fit, trace))
#' @export
predict_heat_injury <- function(object, trace, group = NULL, target_surv = NULL,
                                t_c = NULL, repair = NULL, irreversible = TRUE) {
  if (inherits(object, "freq_tls")) object <- object$fit
  if (!inherits(object, "profile_tls")) {
    cli::cli_abort("{.arg object} must be a {.cls profile_tls} fit from {.fn fit_tls} (or a {.cls freq_tls} workflow from {.fn fit_4pl}).")
  }
  varying_shapes <- tls_bootstrap_varying_shapes(object)
  if (length(varying_shapes)) {
    cli::cli_abort(c(
      "Heat-injury prediction is not available when {.val {varying_shapes}} has a varying fixed-effect shape design.",
      i = "This deterministic trajectory currently requires one low, up, and k value over the trace."
    ))
  }
  if (!is.data.frame(trace)) {
    cli::cli_abort("{.arg trace} must be a data frame with columns {.code time} and {.code temp}.")
  }
  missing_cols <- setdiff(c("time", "temp"), names(trace))
  if (length(missing_cols) > 0L) {
    cli::cli_abort("{.arg trace} is missing required column{?s}: {.code {missing_cols}}.")
  }
  time <- trace$time
  temp <- trace$temp
  if (!is.numeric(time) || !is.numeric(temp)) {
    cli::cli_abort("{.code trace$time} and {.code trace$temp} must be numeric.")
  }
  if (anyNA(time) || anyNA(temp)) {
    cli::cli_abort("{.arg trace} must not contain missing values.")
  }
  n <- nrow(trace)
  if (n < 2L) {
    cli::cli_abort("{.arg trace} needs at least two rows to integrate a trajectory.")
  }
  if (any(diff(time) <= 0)) {
    cli::cli_abort("{.code trace$time} must be strictly increasing.")
  }

  # Per-group CTmax / z / low / up / k via the same resolver predict() uses;
  # all are constant within a group, so the group's scalar shape is pars$*[1].
  nd <- data.frame(temp = temp)
  if (!is.null(group)) {
    group <- as.character(group)
    if (length(group) != 1L) cli::cli_abort("{.arg group} must be a single group level.")
    nd$group <- group
  }
  pars <- tls_predict_pars(object, nd)
  low <- pars$low[1L]
  up <- pars$up[1L]
  k <- pars$k[1L]

  # Survival target defining one lethal dose. NULL is the project-default
  # relative threshold (the curve midpoint, q = 0); an explicit target_surv
  # shifts the lethal time and the dose -> survival map by qlogis() / k so that
  # dose = 1 reaches `target_surv` (an absolute threshold).
  if (is.null(target_surv)) {
    q <- 0
  } else {
    if (!is.numeric(target_surv) || length(target_surv) != 1L) {
      cli::cli_abort("{.arg target_surv} must be a single survival probability or {.code NULL}.")
    }
    if (is.na(target_surv) || target_surv <= low || target_surv >= up) {
      cli::cli_abort(c(
        "{.arg target_surv} must lie strictly between the fitted asymptotes.",
        i = "Lower asymptote {.val {round(low, 4)}}, upper asymptote {.val {round(up, 4)}}; got {.val {target_surv}}."
      ))
    }
    q <- stats::qlogis((target_surv - low) / (up - low))
  }

  # Validate the optional damage cutoff (applied inside the integrator).
  if (!is.null(t_c) && (!is.numeric(t_c) || length(t_c) != 1L)) {
    cli::cli_abort("{.arg t_c} must be a single temperature or {.code NULL}.")
  }

  rep_rate <- rep(0, n)
  if (!is.null(repair)) {
    cli::cli_warn(c(
      "Repair parameters are a user-supplied scenario layer and are {.strong not identified} by the survival data this model was fitted to.",
      i = "Treat the repaired trajectory as a what-if, not an estimate."
    ))
    rep_rate <- tls_repair_rate_schoolfield(temp, repair)
  }

  # CTmax / z / shapes are constant within a group; the forward-Euler integrator
  # takes the group's scalar parameters (shared with heat_injury_envelope()).
  traj <- tls_injury_traj(low, up, k, pars$CTmax[1L], pars$z[1L], object$tref,
                          time, temp, q, t_c, rep_rate, irreversible)

  data.frame(
    time = time, temp = temp, dose = traj$dose,
    injury = traj$dose * 100, survival = traj$survival
  )
}

#' Integrate one heat-injury survival trajectory (scalar parameters)
#'
#' The forward-Euler dose-accumulation core shared by [predict_heat_injury()] (at
#' the fitted parameters) and [heat_injury_envelope()] (at each bootstrap draw).
#' All curve parameters are scalars for one group / one draw; `q` is the
#' target-survival offset (`0` for the relative midpoint), `rep_rate` the per-step
#' repair rate (zeros for none), and `t_c` an optional damage cutoff (degrees C).
#'
#' @return A list with `dose` (cumulative, lethal-dose fraction) and `survival`.
#' @keywords internal
#' @noRd
tls_injury_traj <- function(low, up, k, CTmax, z, tref, time, temp, q,
                            t_c = NULL, rep_rate = NULL, irreversible = TRUE) {
  n <- length(time)
  if (is.null(rep_rate)) rep_rate <- rep(0, n)
  # Lethal time to the survival target at each trace temperature (q = 0 is the
  # relative midpoint), and the damage rate.
  lt <- 10^(log10(tref) - (temp - CTmax) / z - q / k)
  dmg <- 1 / lt
  if (!is.null(t_c)) dmg[temp <= t_c] <- 0

  survival_from_dose <- function(dose) {
    low + (up - low) * stats::plogis(-k * log10(max(dose, 1e-12)) + q)
  }

  dose <- numeric(n)
  surv <- numeric(n)
  dose[1L] <- 0
  surv[1L] <- survival_from_dose(0)
  for (j in seq.int(2L, n)) {
    dt <- time[j] - time[j - 1L]
    # Repair shrinks as the population dies (scaled by the current survival).
    rep_j <- rep_rate[j - 1L] * surv[j - 1L] / up
    net <- dmg[j - 1L] - rep_j
    dose[j] <- max(0, dose[j - 1L] + net * dt)
    s <- survival_from_dose(dose[j])
    surv[j] <- if (isTRUE(irreversible)) min(surv[j - 1L], s) else s
  }

  list(dose = dose, survival = surv)
}

#' Sharpe-Schoolfield repair rate
#'
#' Optional enzyme-kinetic repair rate for [predict_heat_injury()]. All reference
#' temperatures are in Kelvin; the input temperature is in degrees C. Non-finite
#' or negative rates are coerced to zero.
#'
#' @param temp_c Temperature(s) in degrees C.
#' @param pars Named list with `r_ref`, `t_a`, `t_al`, `t_ah`, `t_l`, `t_h`,
#'   `t_ref`.
#' @return A numeric vector of repair rates.
#' @keywords internal
#' @noRd
tls_repair_rate_schoolfield <- function(temp_c, pars) {
  need <- c("r_ref", "t_a", "t_al", "t_ah", "t_l", "t_h", "t_ref")
  missing_pars <- setdiff(need, names(pars))
  if (length(missing_pars) > 0L) {
    cli::cli_abort(c(
      "{.arg repair} is missing parameter{?s}: {.code {missing_pars}}.",
      i = "Supply a named list with {.code {need}} (reference temperatures in Kelvin)."
    ))
  }
  tk <- temp_c + 273.15
  num <- pars$r_ref * exp(pars$t_a * (1 / pars$t_ref - 1 / tk))
  den <- 1 +
    exp(pars$t_al * (1 / tk - 1 / pars$t_l)) +
    exp(pars$t_ah * (1 / pars$t_h - 1 / tk))
  r <- num / den
  r[!is.finite(r) | r < 0] <- 0
  r
}

#' Parametric-bootstrap confidence envelope for a heat-injury trajectory
#'
#' `heat_injury_envelope()` is the uncertainty counterpart of
#' [predict_heat_injury()]: it redraws the fitted curve parameters by parametric
#' bootstrap (the same machinery [confint()] uses), re-integrates the survival
#' trajectory under the temperature `trace` for each draw with the documented
#' dose-accumulation map, and returns a pointwise confidence band around the
#' point-estimate survival curve. The band is **prior-free** -- it carries no
#' prior and makes no probability statement about the parameters; it is the
#' likelihood-path analogue of the `bayesTLS` posterior survival band, **not** a
#' credible band.
#'
#' @inheritParams predict_heat_injury
#' @param nboot Number of bootstrap replicates (default `1000`).
#' @param conf.level Width of the pointwise confidence band (default `0.95`).
#' @param seed Optional integer seed; when supplied the bootstrap is reproducible
#'   without disturbing the caller's random stream.
#'
#' @return A [tibble][tibble::tibble] with `time`, `temp`, `survival` (the
#'   point-estimate trajectory from [predict_heat_injury()]), and `conf.low` /
#'   `conf.high` (the pointwise parametric-bootstrap confidence band).
#'
#' @seealso [predict_heat_injury()] for the point trajectory, [plot_heat_injury()]
#'   to draw the band.
#' @examples
#' d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
#' fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
#'                family = "binomial", tref = 60)
#' trace <- data.frame(time = seq(0, 2, by = 0.1),
#'                     temp = 34 + 6 * sin(seq(0, 2, by = 0.1)))
#' heat_injury_envelope(fit, trace, nboot = 50, seed = 1)
#' @export
heat_injury_envelope <- function(object, trace, group = NULL, target_surv = NULL,
                                 t_c = NULL, repair = NULL, irreversible = TRUE,
                                 nboot = 1000L, conf.level = 0.95, seed = NULL) {
  if (inherits(object, "freq_tls")) object <- object$fit
  if (!is.numeric(conf.level) || length(conf.level) != 1L ||
      conf.level <= 0 || conf.level >= 1) {
    cli::cli_abort("{.arg conf.level} must be a single number in (0, 1).")
  }
  # The point trajectory also validates object / trace / group / target_surv and
  # emits the single repair warning (suppressed below for the per-draw refits).
  point <- predict_heat_injury(object, trace, group = group,
                               target_surv = target_surv, t_c = t_c,
                               repair = repair, irreversible = irreversible)
  time <- trace$time
  temp <- trace$temp
  # The repair rate depends only on temperature + the user scenario (not the
  # curve parameters), so it is the same for every bootstrap draw.
  rep_rate <- rep(0, length(time))
  if (!is.null(repair)) {
    rep_rate <- suppressWarnings(tls_repair_rate_schoolfield(temp, repair))
  }

  # Bootstrap parameter draws (the machinery confint(method = "bootstrap") uses).
  boot <- tls_bootstrap_replicates(object, nboot = nboot, seed = seed)
  reps <- boot$replicates[boot$converged, , drop = FALSE]
  if (nrow(reps) < 2L) {
    cli::cli_abort(c(
      "Too few converged bootstrap replicates ({nrow(reps)}) to form an envelope.",
      i = "Increase {.arg nboot}, or check the fit's stability ({.code summary(fit)})."
    ))
  }

  # Resolve each curve parameter to its replicate column (shared or per-group).
  cn <- colnames(reps)
  col_for <- function(base) {
    if (base %in% cn) return(base)
    if (!is.null(group)) {
      g_col <- paste0(base, ":", as.character(group))
      if (g_col %in% cn) return(g_col)
    }
    g_cols <- grep(paste0("^", base, ":"), cn, value = TRUE)
    if (length(g_cols) == 1L) return(g_cols)
    cli::cli_abort(c(
      "Cannot resolve the {.code {base}} bootstrap column for the envelope.",
      i = "For a grouped fit, pass the {.arg group} whose trajectory you want."
    ))
  }
  cc <- vapply(c("low", "up", "k", "CTmax", "z"), col_for, character(1))

  if (!is.null(target_surv)) {
    lo <- reps[, cc[["low"]]]
    hi <- reps[, cc[["up"]]]
    valid_target <- is.finite(lo) & is.finite(hi) &
      target_surv > lo & target_surv < hi
    if (!all(valid_target)) {
      cli::cli_abort(c(
        "The absolute {.arg target_surv} {.val {target_surv}} is not attainable in {sum(!valid_target)} of {nrow(reps)} converged bootstrap refits.",
        i = "Choose a target farther from the fitted asymptotes, or use the relative midpoint threshold."
      ))
    }
  }

  # Re-integrate the survival trajectory for each converged draw.
  mat <- vapply(seq_len(nrow(reps)), function(i) {
    p <- reps[i, ]
    lo_i <- p[[cc[["low"]]]]; up_i <- p[[cc[["up"]]]]
    q_b <- if (is.null(target_surv)) {
      0
    } else {
      r <- (target_surv - lo_i) / (up_i - lo_i)
      stats::qlogis(r)
    }
    tls_injury_traj(lo_i, up_i, p[[cc[["k"]]]], p[[cc[["CTmax"]]]], p[[cc[["z"]]]],
                    object$tref, time, temp, q_b, t_c, rep_rate, irreversible)$survival
  }, numeric(length(time)))

  a <- (1 - conf.level) / 2
  band <- t(apply(mat, 1L, stats::quantile, probs = c(a, 1 - a), na.rm = TRUE))

  tibble::tibble(
    time = time, temp = temp, survival = point$survival,
    conf.low = band[, 1L], conf.high = band[, 2L]
  )
}

#' Plot a heat-injury survival trajectory with a bootstrap confidence band
#'
#' `plot_heat_injury()` draws the point-estimate survival trajectory from
#' [predict_heat_injury()] inside the pointwise parametric-bootstrap confidence
#' band from [heat_injury_envelope()]. The band is prior-free -- a confidence
#' band, never a posterior or credible band.
#'
#' @inheritParams heat_injury_envelope
#' @param time_div Optional positive divisor applied to `time` on the x-axis (for
#'   example `24` to show days when the trace is in hours); default `1`.
#' @param xlab,ylab Axis labels.
#'
#' @return A `ggplot` object.
#' @seealso [heat_injury_envelope()] for the band data, [predict_heat_injury()]
#'   for the point trajectory.
#' @examples
#' d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
#' fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
#'                family = "binomial", tref = 60)
#' trace <- data.frame(time = seq(0, 2, by = 0.1),
#'                     temp = 34 + 6 * sin(seq(0, 2, by = 0.1)))
#' plot_heat_injury(fit, trace, nboot = 50, seed = 1)
#' @export
plot_heat_injury <- function(object, trace, group = NULL, target_surv = NULL,
                             t_c = NULL, repair = NULL, irreversible = TRUE,
                             nboot = 1000L, conf.level = 0.95, seed = NULL,
                             time_div = 1, xlab = "Time", ylab = "Survival") {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    cli::cli_abort("{.pkg ggplot2} is required for {.fn plot_heat_injury}.")
  }
  if (!is.numeric(time_div) || length(time_div) != 1L || time_div <= 0) {
    cli::cli_abort("{.arg time_div} must be a single positive number.")
  }
  env <- heat_injury_envelope(object, trace, group = group,
                              target_surv = target_surv, t_c = t_c,
                              repair = repair, irreversible = irreversible,
                              nboot = nboot, conf.level = conf.level, seed = seed)
  env$x <- env$time / time_div
  pct <- round(100 * conf.level)
  ggplot2::ggplot(env, ggplot2::aes(x = .data$x)) +
    ggplot2::geom_ribbon(
      ggplot2::aes(ymin = .data$conf.low, ymax = .data$conf.high),
      fill = "#1B7837", alpha = 0.18
    ) +
    ggplot2::geom_line(ggplot2::aes(y = .data$survival), colour = "#1B7837",
                       linewidth = 0.6) +
    ggplot2::ylim(0, 1) +
    ggplot2::labs(
      x = xlab, y = ylab,
      caption = paste(strwrap(paste0(
        "Shaded: ", pct,
        "% pointwise parametric-bootstrap confidence band ",
        "(prior-free; curve parameters redrawn from the fitted model; B = ",
        nboot, ")."
      ), width = 96L), collapse = "\n")
    ) +
    ggplot2::theme_bw(base_size = 11) +
    ggplot2::theme(
      plot.caption = ggplot2::element_text(hjust = 0),
      plot.margin = ggplot2::margin(5.5, 12, 16, 12)
    )
}
