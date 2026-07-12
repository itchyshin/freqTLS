## Publication plots for freqTLS fits (Phase 4, Florence-owned).
##
## The Confidence Eye is freqTLS's default uncertainty display
## It replaces posterior-density visuals: freqTLS
## intervals are likelihood *confidence* intervals, so all wording is
## "confidence", never "posterior"/"credible". The lens
## geometry adapts gllvmTMB's `.eye_polygon_df()` and
## `plot_loadings_confidence_eye()` (GPL-3; provenance in inst/COPYRIGHTS),
## including the honest fallback that refuses to draw a lens when no finite
## (lower, upper) interval exists -- here keyed off `conf.status` from the
## profile path so a non-closing profile renders a hollow point, never a
## fabricated closed eye.

#' Horizontal eye-ribbon coordinates for a bounded confidence lens
#'
#' Adapted from gllvmTMB's `.eye_polygon_df()` and drmTMB's corpairs eye (GPL-3;
#' see `inst/COPYRIGHTS`). For each item, builds a SHORT, WIDE horizontal lens
#' lying along a forest-plot row: the x-extent is exactly the confidence
#' interval `[lower, upper]`, and the lens half-height is a cosine taper that is
#' tallest at the estimate and falls to zero at each bound (asymmetry-aware).
#' The shallow horizontal aspect (height << width) is what makes it read as a
#' confidence *interval* rather than a posterior density / violin.
#'
#' Items with a missing or degenerate `(lower, upper)` emit no ribbon -- their
#' hollow point is drawn by the caller (the honest non-closing fallback).
#'
#' @param df Data frame with columns `estimate`, `lower`, `upper`, and `row`
#'   (the integer y-position of the forest row).
#' @param half_height Peak half-height of the lens at the estimate, in row units
#'   (default `0.22`).
#' @param n Vertex count along the interval (default `80`).
#' @return A long data frame with columns `.id`, `x`, `ymin`, `ymax`.
#' @keywords internal
#' @noRd
tls_eye_ribbon_df <- function(df, half_height = 0.22, n = 80L) {
  needed <- c("estimate", "lower", "upper", "row")
  if (!all(needed %in% names(df))) {
    cli::cli_abort("{.code df} must have columns {.code {needed}}.")
  }
  eps <- .Machine$double.eps * 10
  out_list <- vector("list", nrow(df))
  for (i in seq_len(nrow(df))) {
    est <- df$estimate[i]
    lo <- df$lower[i]
    hi <- df$upper[i]
    ry <- df$row[i]
    # Skip non-drawable items (open or degenerate interval): the hollow point
    # is drawn by geom_point. This is the honest fallback.
    if (is.na(lo) || is.na(hi) || is.na(est) || (hi - lo) < eps) {
      next
    }
    # Cosine half-height: tallest at the ESTIMATE, zero at each bound
    # (asymmetry-aware). Shallow + horizontal => reads as an interval, never a
    # posterior density.
    x_seq <- seq(lo, hi, length.out = n)
    d_lo <- max(est - lo, .Machine$double.eps)
    d_hi <- max(hi - est, .Machine$double.eps)
    frac <- ifelse(x_seq <= est, (est - x_seq) / d_lo, (x_seq - est) / d_hi)
    frac <- pmin(pmax(frac, 0), 1)
    w <- half_height * cos((pi / 2) * frac)
    out_list[[i]] <- data.frame(.id = i, x = x_seq, ymin = ry - w, ymax = ry + w)
  }
  out_list <- out_list[!vapply(out_list, is.null, logical(1))]
  if (length(out_list) == 0L) {
    return(data.frame(.id = integer(0), x = numeric(0),
                      ymin = numeric(0), ymax = numeric(0)))
  }
  do.call(rbind, out_list)
}

#' Confidence-Eye (or line) display of headline confidence intervals
#'
#' `plot_confidence_eye()` draws the freqTLS Confidence Eye for one or more
#' headline parameters (`CTmax`, `z`, or any other [confint.profile_tls()]
#' target, including grouped names). It is a HORIZONTAL forest display: each
#' parameter (and group level) is a row, the parameter value runs along the
#' x-axis, and the confidence interval is a short, wide pale lens with a
#' hollow point estimate. The shallow horizontal lens reads as a confidence
#' *interval*, never a posterior density -- freqTLS intervals are likelihood
#' confidence intervals, so the wording is "confidence", never
#' "posterior". The layout follows the gllvmTMB / drmTMB
#' Confidence-Eye contract.
#'
#' @details
#' ## Honest fallback for open profiles
#' When a profile does not close (`conf.status` is `"open_lower"`,
#' `"open_upper"`, `"open_both"`, or a bound is `NA`), no lens is drawn for that
#' row: a hollow point marks the estimate and the subtitle flags the open
#' interval. The eye is never fabricated from an open profile. A
#' `"wald_fallback"` interval (e.g. `up`) still gets a lens, with the source
#' noted in the caption.
#'
#' ## Raw data
#' With `raw_data = TRUE` (default), the observed assay temperatures are drawn as
#' a rug beneath any temperature-scale row (`CTmax`), showing the data support
#' and flagging extrapolation when `CTmax` sits outside the assayed range.
#'
#' Parameters on different scales (temperature for `CTmax`, a positive
#' multiplier for `z`) are stacked in separate panels with a free x-axis.
#'
#' @param fit A `profile_tls` fit from [fit_tls()].
#' @param parm Character vector of target parameter names. Defaults to
#'   `c("CTmax", "z")` (the headline quantities). Grouped names (e.g.
#'   `"CTmax:larva"`) are accepted.
#' @param method One of `"profile"` (default), `"wald"`, or `"bootstrap"`;
#'   forwarded to [confint.profile_tls()].
#' @param level Confidence level (default `0.95`).
#' @param style One of `"eye"` (default; pale horizontal lens + hollow point) or
#'   `"line"` (a confidence-interval bar with caps + hollow point, no lens).
#' @param raw_data Logical; overlay observed assay temperatures as a rug on
#'   temperature-scale rows (default `TRUE`).
#' @param fallback,nboot,boot_seed,cores Forwarded to [confint.profile_tls()]:
#'   control the parametric-bootstrap fallback for non-closing profiles (so the
#'   eye draws an honest bootstrap lens instead of only a hollow point), make it
#'   reproducible, and parallelise the refits. Defaults `TRUE`, `1000`, `NULL`,
#'   and `1`.
#' @param ... Reserved; must be empty.
#'
#' @return A `ggplot` object.
#'
#' @examples
#' d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
#' fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
#'                family = "binomial", tref = 1)
#' plot_confidence_eye(fit, parm = c("CTmax", "z"))
#'
#' @export
plot_confidence_eye <- function(fit, parm = c("CTmax", "z"),
                                method = c("profile", "wald", "bootstrap"),
                                level = 0.95,
                                style = c("eye", "line"),
                                raw_data = TRUE,
                                fallback = TRUE, nboot = 1000L,
                                boot_seed = NULL, cores = 1L, ...) {
  dots <- list(...)
  if (length(dots) > 0L) {
    cli::cli_abort("{.arg ...} is reserved; pass only documented arguments.")
  }
  if (inherits(fit, "freq_tls")) fit <- fit$fit
  if (!inherits(fit, "profile_tls")) {
    cli::cli_abort("{.arg fit} must be a {.cls profile_tls} fit from {.fn fit_tls}.")
  }
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    cli::cli_abort("{.pkg ggplot2} is required for {.fn plot_confidence_eye}.")
  }
  method <- match.arg(method)
  style <- match.arg(style)
  # The Confidence Eye stays on Wald for random-effects fits: a profile under the
  # RE re-runs the Laplace at every grid point for every parameter, which defeats
  # the eye's role as a quick visual. The profile interval is available directly
  # via confint(fit, method = "profile").
  if (tls_has_re(fit) && !identical(method, "wald")) {
    cli::cli_inform(c(
      "i" = "The Confidence Eye uses Wald intervals for random-effects fits (fast).",
      "i" = "Use {.code confint(fit, method = \"profile\")} for the profile interval."
    ))
    method <- "wald"
  }
  # An RE-fit eye drawn on Wald (whether forced above or requested) carries an
  # on-figure note that the calibrated profile interval is one call away, so the
  # narrower interval is never shown without that signpost.
  re_wald <- tls_has_re(fit) && identical(method, "wald")
  if (!is.character(parm) || length(parm) == 0L) {
    cli::cli_abort("{.arg parm} must be a non-empty character vector of target names.")
  }

  # For a grouped fit, expand a bare grouped target (e.g. "CTmax") to its
  # per-group names ("CTmax:<level>") so each group gets its own forest row.
  glevels <- fit$group_levels
  if (isTRUE(fit$data_summary$grouped) || length(glevels) > 1L) {
    grouped_bases <- c("CTmax", "z", "log_z")
    parm <- unlist(lapply(parm, function(p) {
      if (p %in% grouped_bases) paste0(p, ":", glevels) else p
    }), use.names = FALSE)
  }

  # Confidence intervals for the requested targets. Profiling may warn (open
  # intervals) or message (`up` Wald fallback); those are honest signals, so we
  # do not silence them here.
  ci <- confint(fit, parm = parm, level = level, method = method,
                fallback = fallback, nboot = nboot, boot_seed = boot_seed,
                cores = cores)

  # Base parameter (facet) and group level (forest row) from e.g. "CTmax:larva".
  parts <- strsplit(as.character(ci$parameter), ":", fixed = TRUE)
  ci$.base <- vapply(parts, `[`, character(1), 1L)
  ci$.grp <- vapply(parts, function(s) if (length(s) > 1L) s[[2L]] else "",
                    character(1))
  ci$.facet <- factor(ci$.base, levels = unique(ci$.base))
  grpf <- factor(ci$.grp, levels = unique(ci$.grp))
  ci$.row <- as.integer(grpf)
  row_breaks <- seq_along(levels(grpf))
  row_labels <- levels(grpf)

  # Reliability colour: honest about interval status.
  status <- ci$conf.status
  rel <- rep("confidence interval", nrow(ci))
  rel[status %in% c("open_lower", "open_upper", "open_both")] <- "interval open"
  rel[status == "wald_fallback"] <- "Wald/delta interval"
  rel[status == "bootstrap"] <- "bootstrap interval"
  rel[is.na(ci$conf.low) | is.na(ci$conf.high)] <- "interval open"
  ci$.reliability <- factor(
    rel,
    levels = c("interval open", "Wald/delta interval", "bootstrap interval",
               "confidence interval")
  )
  fill_pal <- c(
    "interval open"          = "#d6604d",
    "Wald/delta interval"    = "#377eb8",
    "bootstrap interval"     = "#8073ac",
    "confidence interval" = "#1b7837"
  )

  drawable <- is.finite(ci$conf.low) & is.finite(ci$conf.high)
  any_open <- any(!drawable)
  none_drawable <- !any(drawable)

  g <- ggplot2::ggplot(ci, ggplot2::aes(x = .data$estimate, y = .data$.row))

  # Raw data: observed assay temperatures as a rug on temperature-scale rows.
  if (isTRUE(raw_data) && "CTmax" %in% levels(ci$.facet) &&
      !is.null(fit$diag_data$temp)) {
    rug_df <- data.frame(x = sort(unique(fit$diag_data$temp)))
    rug_df$.facet <- factor("CTmax", levels = levels(ci$.facet))
    g <- g + ggplot2::geom_rug(
      data = rug_df, mapping = ggplot2::aes(x = .data$x),
      sides = "b", alpha = 0.5, colour = "grey45", inherit.aes = FALSE
    )
  }

  if (identical(style, "eye") && !none_drawable) {
    # Shallow horizontal lens per facet (reads as an interval, not a density).
    rib_list <- lapply(split(which(drawable), ci$.facet[drawable]), function(idx) {
      d <- data.frame(estimate = ci$estimate[idx], lower = ci$conf.low[idx],
                      upper = ci$conf.high[idx], row = ci$.row[idx])
      rb <- tls_eye_ribbon_df(d)
      if (nrow(rb) == 0L) return(NULL)
      global <- idx[rb$.id]
      rb$.reliability <- ci$.reliability[global]
      rb$.facet <- ci$.facet[global]
      rb$.gid <- paste(as.character(rb$.facet), rb$.id, sep = ".")
      rb
    })
    rib_df <- do.call(rbind, rib_list[!vapply(rib_list, is.null, logical(1))])
    if (!is.null(rib_df) && nrow(rib_df) > 0L) {
      g <- g + ggplot2::geom_ribbon(
        data = rib_df,
        mapping = ggplot2::aes(x = .data$x, ymin = .data$ymin, ymax = .data$ymax,
                               group = .data$.gid, fill = .data$.reliability),
        colour = NA, alpha = 0.30, inherit.aes = FALSE
      )
    }
  }

  if (identical(style, "line")) {
    # Confidence-interval bar with caps for drawable rows only (no lens).
    line_df <- ci[drawable, , drop = FALSE]
    if (nrow(line_df) > 0L) {
      g <- g + ggplot2::geom_errorbarh(
        data = line_df,
        mapping = ggplot2::aes(xmin = .data$conf.low, xmax = .data$conf.high,
                               y = .data$.row, colour = .data$.reliability),
        height = 0.18, linewidth = 0.8, inherit.aes = FALSE
      )
    }
  }

  # Hollow point estimate on top (white interior, coloured stroke), every row.
  g <- g +
    ggplot2::geom_point(
      ggplot2::aes(colour = .data$.reliability),
      shape = 21, fill = "white", size = 3, stroke = 1
    ) +
    ggplot2::scale_fill_manual(values = fill_pal, name = NULL, drop = TRUE,
                               guide = "none") +
    ggplot2::scale_colour_manual(values = fill_pal, name = NULL, drop = TRUE) +
    ggplot2::scale_y_continuous(breaks = row_breaks, labels = row_labels,
                                expand = ggplot2::expansion(add = 0.6)) +
    ggplot2::facet_wrap(~ .data$.facet, scales = "free_x", ncol = 1L) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      panel.grid.major.y = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank()
    )

  methods_used <- unique(ci$method)
  src_lab <- if (setequal(methods_used, "wald")) {
    "Wald"
  } else if (setequal(methods_used, "bootstrap")) {
    "parametric bootstrap"
  } else if (setequal(methods_used, "profile")) {
    "profile likelihood"
  } else {
    "profile likelihood (with fallback)"
  }
  shape_lab <- if (identical(style, "line")) "bar = interval" else "lens width = interval"
  rug_lab <- if (isTRUE(raw_data) && "CTmax" %in% levels(ci$.facet)) {
    "; ticks = observed assay temperatures"
  } else {
    ""
  }
  caption <- sprintf(
    "%d%% confidence intervals (%s). %s; hollow point = estimate%s.",
    round(100 * level), src_lab, shape_lab, rug_lab
  )
  subtitle <- if (none_drawable) {
    "No interval closed; hollow points only (see `?confint.profile_tls`)."
  } else if (any_open) {
    "Open intervals shown as hollow points without a lens (weakly identified)."
  } else if (re_wald) {
    "Wald intervals (random-effects fit); use method = \"profile\" for the profile interval."
  } else {
    NULL
  }

  g + ggplot2::labs(
    x = NULL, y = NULL,
    title = "Confidence Eyes for headline parameters",
    subtitle = subtitle,
    caption = caption
  )
}

#' Plot fitted survival curves against duration
#'
#' `plot_survival_curves()` draws the fitted survival probability as a function
#' of exposure duration (on a log10 x-axis), one curve per temperature, with the
#' observed survival proportions overlaid as points. For a grouped fit the
#' curves are faceted by group.
#'
#' @param fit A `profile_tls` fit from [fit_tls()].
#' @param temps Numeric vector of temperatures to draw curves for. Defaults to
#'   the distinct observed temperatures (capped at a readable number).
#' @param times Numeric vector of durations to evaluate the smooth curve over.
#'   Defaults to a log-spaced sequence over the observed duration range.
#' @param ... Reserved; must be empty.
#'
#' @return A `ggplot` object.
#'
#' @examples
#' d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
#' fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
#'                family = "binomial", tref = 1)
#' plot_survival_curves(fit)
#'
#' @export
plot_survival_curves <- function(fit, temps = NULL, times = NULL, ...) {
  dots <- list(...)
  if (length(dots) > 0L) {
    cli::cli_abort("{.arg ...} is reserved; pass only documented arguments.")
  }
  if (inherits(fit, "freq_tls")) fit <- fit$fit
  if (!inherits(fit, "profile_tls")) {
    cli::cli_abort("{.arg fit} must be a {.cls profile_tls} fit from {.fn fit_tls}.")
  }
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    cli::cli_abort("{.pkg ggplot2} is required for {.fn plot_survival_curves}.")
  }

  obs <- fit$diag_data
  grouped <- isTRUE(fit$data_summary$grouped)
  ds <- fit$data_summary

  obs_temps <- sort(unique(obs$temp))
  if (is.null(temps)) {
    # Cap the legend at a readable number of temperatures.
    temps <- if (length(obs_temps) > 7L) {
      obs_temps[round(seq(1, length(obs_temps), length.out = 7L))]
    } else {
      obs_temps
    }
  }
  if (is.null(times)) {
    times <- 10^seq(log10(ds$time_range[1L]), log10(ds$time_range[2L]),
                    length.out = 80L)
  }

  levels_g <- fit$group_levels

  # Smooth fitted curves.
  curve_grid <- expand.grid(temp = temps, duration = times,
                            KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
  build_curve <- function(lev) {
    nd <- curve_grid
    if (grouped) nd$group <- lev
    out <- curve_grid
    out$survival <- predict(fit, nd, type = "survival")
    if (grouped) out$group <- lev
    out
  }
  curve_df <- if (grouped) {
    do.call(rbind, lapply(levels_g, build_curve))
  } else {
    build_curve(NA_character_)
  }
  curve_df$temp_f <- factor(curve_df$temp)

  # Observed survival proportions.
  obs_df <- data.frame(
    temp = obs$temp,
    duration = obs$time,
    survival = obs$y / obs$n,
    stringsAsFactors = FALSE
  )
  if (grouped) obs_df$group <- as.character(obs$group)
  obs_df <- obs_df[obs_df$temp %in% temps, , drop = FALSE]
  obs_df$temp_f <- factor(obs_df$temp, levels = levels(curve_df$temp_f))

  p <- ggplot2::ggplot(
    curve_df,
    ggplot2::aes(x = .data$duration, y = .data$survival,
                 colour = .data$temp_f, group = .data$temp_f)
  ) +
    ggplot2::geom_line(linewidth = 0.8) +
    ggplot2::geom_point(
      data = obs_df,
      mapping = ggplot2::aes(x = .data$duration, y = .data$survival,
                             colour = .data$temp_f),
      shape = 16, size = 1.4, alpha = 0.7, inherit.aes = FALSE
    ) +
    ggplot2::scale_x_log10() +
    ggplot2::coord_cartesian(ylim = c(0, 1)) +
    ggplot2::scale_colour_viridis_d(name = "Temp (\u00b0C)", option = "C",
                                    end = 0.9) +
    ggplot2::theme_minimal() +
    ggplot2::labs(
      x = "Exposure duration (log scale)",
      y = "Survival probability",
      title = "Fitted survival vs duration",
      caption = sprintf(
        "Fitted 4PL survival; points are observed proportions. CTmax defined at tref = %s.",
        format(fit$tref)
      )
    )

  if (grouped) {
    p <- p + ggplot2::facet_wrap(~ .data$group)
  }
  p
}

#' Plot the thermal death-time (TDT) curve: survival-threshold time vs temperature
#'
#' `plot_tdt_curve()` draws the duration at which survival crosses a target
#' probability `p` (default the relative midpoint, `p = 0.5`) against
#' temperature -- the classic thermal-death-time line, here read directly off the
#' fitted 4PL via [derive_lt()]. Time is shown on a log10 axis. For a grouped fit
#' a line is drawn per group.
#'
#' @param fit A `profile_tls` fit from [fit_tls()].
#' @param p Target survival probability for the threshold (default `0.5`).
#' @param temps Numeric vector of temperatures. Defaults to a sequence over the
#'   observed temperature range.
#' @param ... Reserved; must be empty.
#'
#' @return A `ggplot` object.
#'
#' @examples
#' d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
#' fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
#'                family = "binomial", tref = 1)
#' plot_tdt_curve(fit)
#'
#' @export
plot_tdt_curve <- function(fit, p = 0.5, temps = NULL, ...) {
  dots <- list(...)
  if (length(dots) > 0L) {
    cli::cli_abort("{.arg ...} is reserved; pass only documented arguments.")
  }
  if (inherits(fit, "freq_tls")) fit <- fit$fit
  if (!inherits(fit, "profile_tls")) {
    cli::cli_abort("{.arg fit} must be a {.cls profile_tls} fit from {.fn fit_tls}.")
  }
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    cli::cli_abort("{.pkg ggplot2} is required for {.fn plot_tdt_curve}.")
  }
  ds <- fit$data_summary
  if (is.null(temps)) {
    temps <- seq(ds$temp_range[1L], ds$temp_range[2L], length.out = 60L)
  }

  grouped <- isTRUE(fit$data_summary$grouped)
  levels_g <- fit$group_levels

  build_line <- function(lev) {
    grp <- if (grouped) lev else NULL
    data.frame(
      temp = temps,
      lt = derive_lt(fit, p = p, temp = temps, group = grp),
      group = if (grouped) lev else NA_character_,
      stringsAsFactors = FALSE
    )
  }
  line_df <- if (grouped) {
    do.call(rbind, lapply(levels_g, build_line))
  } else {
    build_line(NA_character_)
  }

  pct <- round(100 * p)
  aes_line <- if (grouped) {
    ggplot2::aes(x = .data$temp, y = .data$lt, colour = .data$group)
  } else {
    ggplot2::aes(x = .data$temp, y = .data$lt)
  }

  p_plot <- ggplot2::ggplot(line_df, aes_line) +
    ggplot2::geom_line(linewidth = 0.9) +
    ggplot2::scale_y_log10() +
    ggplot2::theme_minimal() +
    ggplot2::labs(
      x = "Temperature (\u00b0C)",
      y = sprintf("Duration to %d%% survival (log scale)", pct),
      title = "Thermal death-time curve",
      caption = sprintf(
        "Duration at which fitted survival crosses %.2f (relative threshold), read off the 4PL midpoint at tref = %s.",
        p, format(fit$tref)
      )
    )
  if (grouped) {
    p_plot <- p_plot +
      ggplot2::scale_colour_viridis_d(name = NULL, option = "D", end = 0.85)
  }
  p_plot
}

#' Plot the fitted survival surface over temperature and duration
#'
#' `plot_survival_surface()` draws the fitted survival probability as a filled
#' heatmap over a temperature-by-duration grid, with contour lines, using
#' [predict_survival_surface()]. Duration is on a log10 axis. For a grouped fit
#' the surface is faceted by group.
#'
#' @param fit A `profile_tls` fit from [fit_tls()].
#' @param temps,times Numeric grids passed to [predict_survival_surface()].
#'   Defaults span the observed ranges.
#' @param contour Logical; overlay contour lines (default `TRUE`).
#' @param ... Reserved; must be empty.
#'
#' @return A `ggplot` object.
#'
#' @examples
#' d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
#' fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
#'                family = "binomial", tref = 1)
#' plot_survival_surface(fit)
#'
#' @export
plot_survival_surface <- function(fit, temps = NULL, times = NULL,
                                  contour = TRUE, ...) {
  dots <- list(...)
  if (length(dots) > 0L) {
    cli::cli_abort("{.arg ...} is reserved; pass only documented arguments.")
  }
  if (inherits(fit, "freq_tls")) fit <- fit$fit
  if (!inherits(fit, "profile_tls")) {
    cli::cli_abort("{.arg fit} must be a {.cls profile_tls} fit from {.fn fit_tls}.")
  }
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    cli::cli_abort("{.pkg ggplot2} is required for {.fn plot_survival_surface}.")
  }

  surf <- predict_survival_surface(fit, temps = temps, times = times)
  grouped <- isTRUE(fit$data_summary$grouped)

  p <- ggplot2::ggplot(
    surf,
    ggplot2::aes(x = .data$temp, y = .data$duration, z = .data$survival)
  ) +
    ggplot2::geom_raster(ggplot2::aes(fill = .data$survival),
                         interpolate = TRUE) +
    ggplot2::scale_y_log10() +
    ggplot2::scale_fill_viridis_c(name = "Survival", option = "D",
                                  limits = c(0, 1)) +
    ggplot2::theme_minimal() +
    ggplot2::labs(
      x = "Temperature (\u00b0C)",
      y = "Exposure duration (log scale)",
      title = "Fitted survival surface",
      caption = sprintf("Fitted 4PL survival probability. CTmax defined at tref = %s.",
                        format(fit$tref))
    )

  if (isTRUE(contour)) {
    p <- p + ggplot2::geom_contour(colour = "white", alpha = 0.5,
                                   linewidth = 0.3)
  }
  if (grouped) {
    p <- p + ggplot2::facet_wrap(~ .data$group)
  }
  p
}
