# ============================================================================
# Canonical classical two-stage TDT pipeline.
#
# One implementation, used by the manuscript tutorial, every case study, and the
# bias simulation (via scripts/simulations/sim_functions.R). Stage 1 fits a
# per-temperature dose-response curve and reads off log10(LT50); Stage 2
# regresses those on temperature to give z, CTmax, and T_crit. Beta-binomial
# Stage 1 uses glmmTMB (the maintained, standard tool) everywhere.
#
# See notes/2026-06-11-unify-two-stage.qmd for the consolidation decision.
# ============================================================================

#' Stage 1 of the classical two-stage TDT pipeline
#'
#' Fits a separate logistic dose-response curve at each assay temperature and
#' reads off `log10(LT50)` (the duration at 50% survival). The binomial family
#' uses [stats::glm]; the beta-binomial family uses
#' [glmmTMB::glmmTMB] with a `betabinomial` family (overdispersion at Stage 1).
#'
#' Two validity flags are returned so callers can choose their own success rule:
#' `finite_ok` (finite coefficients, negative non-trivial slope) and `bracket_ok`
#' (the fitted LT50 lies within the observed duration range, padded by 0.5 on the
#' log10 scale). `stage1_ok` is their conjunction.
#'
#' @param data Data frame with one row per (temperature, duration) replicate.
#' @param temp,duration,n_surv,n_total Column names (strings) for assay
#'   temperature (°C), exposure duration, survivors, and trials.
#' @param family `"binomial"` or `"betabinomial"`.
#' @return A tibble with one row per temperature: `temp`, `log10_lt50`,
#'   `se_log10_lt50`, `slope`, `phi` (beta-binomial precision, else `NA`),
#'   `finite_ok`, `bracket_ok`, `stage1_ok`.
#' @examples
#' d <- simulate_tls(
#'   family = "binomial", temps = seq(30, 42, by = 2),
#'   times = c(0.01, 0.03, 0.1, 0.3, 1, 3, 10, 30, 100),
#'   reps = 4, n = 50, CTmax = 36, z = 4, seed = 42
#' )
#' ts_stage1(d, "temp", "duration", "survived", "total", family = "binomial")
#' @export
ts_stage1 <- function(data, temp = "temp", duration = "duration",
                      n_surv = "n_surv", n_total = "n_total",
                      family = c("binomial", "betabinomial")) {
  family <- match.arg(family)
  if (family == "betabinomial" && !requireNamespace("glmmTMB", quietly = TRUE))
    stop("ts_stage1(family = 'betabinomial') needs the glmmTMB package.",
         call. = FALSE)

  d <- data.frame(
    .temp  = data[[temp]],
    .logd  = log10(data[[duration]]),
    .surv  = data[[n_surv]],
    .dead  = data[[n_total]] - data[[n_surv]],
    stringsAsFactors = FALSE)

  na_row <- function(t) tibble::tibble(
    temp = t, log10_lt50 = NA_real_, se_log10_lt50 = NA_real_,
    slope = NA_real_, phi = NA_real_,
    finite_ok = FALSE, bracket_ok = FALSE, stage1_ok = FALSE)

  temps <- sort(unique(d$.temp))
  rows <- lapply(temps, function(t) {
    di <- d[d$.temp == t, , drop = FALSE]
    if (length(unique(di$.logd)) < 3) return(na_row(t))

    if (family == "binomial") {
      fit <- tryCatch(suppressWarnings(
        stats::glm(cbind(.surv, .dead) ~ .logd, data = di,
                   family = stats::binomial())), error = function(e) e)
      if (inherits(fit, "error") || any(!is.finite(stats::coef(fit))))
        return(na_row(t))
      co <- stats::coef(fit); V <- stats::vcov(fit); phi <- NA_real_
    } else {
      fit <- tryCatch(suppressWarnings(suppressMessages(
        glmmTMB::glmmTMB(cbind(.surv, .dead) ~ .logd, data = di,
                         family = glmmTMB::betabinomial(link = "logit")))),
        error = function(e) e)
      if (inherits(fit, "error")) return(na_row(t))
      co <- tryCatch(glmmTMB::fixef(fit)$cond, error = function(e) NULL)
      V  <- tryCatch(stats::vcov(fit)$cond,    error = function(e) NULL)
      if (is.null(co) || is.null(V) || any(!is.finite(co))) return(na_row(t))
      # Beta-binomial overdispersion (reported only; not used by Stage 2).
      # glmmTMB exposes it via sigma(); near-binomial data pushes it large.
      phi <- tryCatch(stats::sigma(fit), error = function(e) NA_real_)
    }

    b0 <- co[["(Intercept)"]]; b1 <- co[[".logd"]]
    lt <- -b0 / b1
    g  <- c(-1 / b1, b0 / b1^2)                       # d(log10 LT50)/d(b0, b1)
    se <- sqrt(as.numeric(t(g) %*% V %*% g))
    finite_ok  <- is.finite(b1) && b1 < 0 && abs(b1) > 1e-4 && is.finite(b0)
    bracket_ok <- is.finite(lt) &&
      lt >= min(di$.logd, na.rm = TRUE) - 0.5 &&
      lt <= max(di$.logd, na.rm = TRUE) + 0.5
    tibble::tibble(
      temp = t, log10_lt50 = lt, se_log10_lt50 = se, slope = b1, phi = phi,
      finite_ok = finite_ok, bracket_ok = bracket_ok,
      stage1_ok = finite_ok && bracket_ok)
  })
  do.call(rbind, rows)
}

#' Stage 2 of the classical two-stage TDT pipeline
#'
#' Regresses the valid Stage-1 `log10(LT50)` estimates on assay temperature by
#' ordinary least squares and derives the classical quantities. `z = -1/slope`;
#' `CTmax(t_ref) = (log10(t_ref) - intercept) / slope`; `T_crit` follows the
#' rate-multiplier definition, `CTmax + z * mean(log10(TC_rate_range/100))`.
#' `t_ref` is expressed in minutes and is recorded in the returned `$settings`.
#' Thus `summary$CTmax` is always CTmax at the explicitly recorded reference
#' duration, not necessarily CTmax at one hour. Stage 2 retains only rows chosen
#' by `rows`; if fewer than three valid Stage-1 temperatures remain, it returns
#' a `NULL` fit and an `NA` summary rather than extrapolating a TDT line.
#'
#' @param stage1 Output of [ts_stage1()].
#' @param t_ref Reference exposure duration for CTmax (minutes). Default 60.
#' @param time_multiplier Multiplier from the Stage-1 duration unit to minutes
#'   (e.g. 60 if durations are in hours). Default 1.
#' @param TC_rate_range Length-2 HI-rate range (% per hour) for T_crit.
#' @param rows Which Stage-1 rows to keep: `"stage1_ok"` (bracketing validation,
#'   the case-study default) or `"finite_ok"` (finite/negative slope only, the
#'   simulation's looser rule).
#' @return `list(fit, summary, settings)`; `fit` is `NULL` if fewer than 3 valid
#'   Stage-1 estimates remain. `summary` has `intercept`, `slope_T`, `z`,
#'   `CTmax`, `T_crit`, `r_squared`, `n_stage1`, `n_excluded`. `$settings`
#'   records `t_ref`, `time_multiplier`, and `TC_rate_range`; downstream
#'   [ts_ci()] and [ts_curve()] inherit these settings by default.
#'   For compatibility, when `t_ref = 60` exactly, `summary` also contains a
#'   truthful `CTmax_1hr` alias for `CTmax`; it is absent at every other
#'   reference duration.
#' @examples
#' d <- simulate_tls(
#'   family = "binomial", temps = seq(30, 42, by = 2),
#'   times = c(0.01, 0.03, 0.1, 0.3, 1, 3, 10, 30, 100),
#'   reps = 4, n = 50, CTmax = 36, z = 4, seed = 42
#' )
#' s1 <- ts_stage1(d, "temp", "duration", "survived", "total")
#' ts_stage2(s1, t_ref = 60, time_multiplier = 60)$summary
#' @export
ts_stage2 <- function(stage1, t_ref = 60, time_multiplier = 1,
                      TC_rate_range = c(0.1, 1),
                      rows = c("stage1_ok", "finite_ok")) {
  rows <- match.arg(rows)
  stopifnot(t_ref > 0, time_multiplier > 0)
  keep <- stage1[stage1[[rows]] & is.finite(stage1$log10_lt50), , drop = FALSE]
  n_excluded <- nrow(stage1) - nrow(keep)

  settings <- list(
    t_ref = t_ref, time_multiplier = time_multiplier,
    TC_rate_range = TC_rate_range
  )
  empty <- ts_add_one_hour_alias(tibble::tibble(
    intercept = NA_real_, slope_T = NA_real_, z = NA_real_,
    CTmax = NA_real_, T_crit = NA_real_, r_squared = NA_real_,
    n_stage1 = nrow(keep), n_excluded = n_excluded), settings)
  if (nrow(keep) < 3) return(list(fit = NULL, summary = empty, settings = settings))

  fit <- stats::lm(log10_lt50 ~ temp, data = keep)
  co  <- stats::coef(fit)
  slope <- as.numeric(co[["temp"]])
  # A valid TDT line decreases with temperature (slope < 0). A non-negative or
  # ~zero slope makes z = -1/slope and CTmax nonsensical (negative or +/-Inf), so
  # return the NA summary -- matching the bias simulation's fit_two_stage guard --
  # rather than propagating garbage downstream.
  if (!is.finite(slope) || slope >= -1e-8) {
    empty$slope_T <- slope
    return(list(fit = fit, summary = empty, settings = settings))
  }
  intercept <- as.numeric(co[["(Intercept)"]] + log10(time_multiplier))
  z         <- -1 / slope
  ctmax     <- (log10(t_ref) - intercept) / slope   # CTmax at the chosen t_ref
  # T_crit uses the rate-multiplier definition anchored at the 1 h CTmax, so it
  # is invariant to t_ref (matching extract_tdt()); only the reported CTmax
  # tracks t_ref. At the default t_ref = 60 the two anchors coincide.
  ctmax_1hr <- (log10(60) - intercept) / slope
  list(
    fit = fit,
    summary = ts_add_one_hour_alias(tibble::tibble(
      intercept = intercept, slope_T = slope, z = z, CTmax = ctmax,
      T_crit = ctmax_1hr + z * mean(log10(TC_rate_range / 100)),
      r_squared = summary(fit)$r.squared,
      n_stage1 = nrow(keep), n_excluded = n_excluded), settings),
    settings = settings)
}

#' Uncertainty for the classical two-stage TDT quantities
#'
#' Two propagation methods on the Stage-2 fit:
#' \itemize{
#'   \item `"delta"` — delta-method standard errors for `z` and `CTmax`, with
#'     **both Normal and t quantiles** (the t-quantile is the small-sample
#'     correction for the few Stage-2 residual degrees of freedom). This is the
#'     method the bias simulation reports.
#'   \item `"mvn"` — slope-CI inversion for `z` (defined only when the slope CI
#'     is wholly negative) plus MVN simulation of the Stage-2 coefficients for
#'     `CTmax` and `T_crit`, and a `predict.lm` confidence band for the LT-vs-T
#'     line over `temp_grid`. This is the method the case studies report.
#' }
#'
#' @param stage2 Output of [ts_stage2()].
#' @param method `"delta"` or `"mvn"`.
#' @param level Confidence level. Default 0.95.
#' @param t_ref,time_multiplier,TC_rate_range Optional explicit checks against
#'   the settings recorded by [ts_stage2()]. By default they are inherited. A
#'   value that disagrees with the Stage-2 fit errors rather than silently
#'   changing the CTmax convention.
#' @param temp_grid Temperatures for the line band (`"mvn"` only).
#' @param n_sim MVN draws (`"mvn"` only). Default 1000.
#' @param seed RNG seed (`"mvn"` only). Default 123.
#' @return For `"delta"`, a list with `z` and `CTmax`, each
#'   `list(point, lower, upper, lower_t, upper_t, se)`, plus `df_resid`.
#'   When the recorded `t_ref` is exactly 60 minutes, the list also contains the
#'   compatibility alias `CTmax_1hr`, identical to `CTmax`; it is absent for
#'   other reference durations.
#'   For `"mvn"`, a list with `summary_ci` (z/CTmax/T_crit bounds) and
#'   `curve_ci` (per-`temp_grid` line band).
#' @examples
#' d <- simulate_tls(
#'   family = "binomial", temps = seq(30, 42, by = 2),
#'   times = c(0.01, 0.03, 0.1, 0.3, 1, 3, 10, 30, 100),
#'   reps = 4, n = 50, CTmax = 36, z = 4, seed = 42
#' )
#' s2 <- ts_stage2(ts_stage1(d, "temp", "duration", "survived", "total"),
#'                 t_ref = 60, time_multiplier = 60)
#' ts_ci(s2, method = "delta")$z
#' @export
ts_ci <- function(stage2, method = c("delta", "mvn"), level = 0.95,
                  t_ref = NULL, time_multiplier = NULL, TC_rate_range = NULL,
                  temp_grid = NULL, n_sim = 1000, seed = 123) {
  method <- match.arg(method)
  settings <- ts_stage2_settings(stage2, t_ref, time_multiplier, TC_rate_range)
  t_ref <- settings$t_ref
  time_multiplier <- settings$time_multiplier
  TC_rate_range <- settings$TC_rate_range
  fit <- stage2$fit
  a   <- (1 - level) / 2

  if (method == "delta") {
    na_blk <- list(point = NA_real_, lower = NA_real_, upper = NA_real_,
                   lower_t = NA_real_, upper_t = NA_real_, se = NA_real_)
    if (is.null(fit)) return(ts_add_one_hour_ci_alias(
      list(z = na_blk, CTmax = na_blk, df_resid = NA), settings
    ))
    co <- stats::coef(fit); V <- stats::vcov(fit)
    b0 <- co[["(Intercept)"]]; b1 <- co[["temp"]]
    log10_tr <- log10(t_ref) - log10(time_multiplier)
    z_pt  <- -1 / b1
    z_se  <- abs(1 / b1^2) * sqrt(V["temp", "temp"])
    ct_pt <- (log10_tr - b0) / b1
    gC    <- c(-1 / b1, -(log10_tr - b0) / b1^2)
    ct_se <- sqrt(as.numeric(t(gC) %*% V %*% gC))
    df    <- stats::df.residual(fit)
    qn    <- stats::qnorm(1 - a)
    qt    <- if (is.finite(df) && df > 0) stats::qt(1 - a, df = df) else NA_real_
    blk <- function(pt, se) list(point = pt, lower = pt - qn * se,
      upper = pt + qn * se, lower_t = pt - qt * se, upper_t = pt + qt * se, se = se)
    return(ts_add_one_hour_ci_alias(
      list(z = blk(z_pt, z_se), CTmax = blk(ct_pt, ct_se), df_resid = df), settings
    ))
  }

  # ---- method == "mvn" ----
  if (is.null(fit)) {
    na_summary <- tibble::tibble(
      z_lower = NA_real_, z_upper = NA_real_, CTmax_lower = NA_real_,
      CTmax_upper = NA_real_, Tcrit_lower = NA_real_, Tcrit_upper = NA_real_)
    na_curve <- tibble::tibble(temp = temp_grid %||% numeric(0),
      duration_lower = NA_real_, duration_upper = NA_real_)
    return(list(summary_ci = na_summary, curve_ci = na_curve))
  }
  set.seed(seed)
  log_rate_mid <- mean(log10(TC_rate_range / 100))
  log10_tr     <- log10(t_ref)

  # z via slope-CI inversion (defined only when the slope CI is wholly negative;
  # z = -1/slope is monotone in slope on (-Inf, 0)).
  bci <- stats::confint(fit, "temp", level = level)
  slo <- as.numeric(bci[1, 1]); shi <- as.numeric(bci[1, 2])
  if (is.finite(slo) && is.finite(shi) && shi < 0) {
    z_lower <- -1 / slo; z_upper <- -1 / shi
  } else { z_lower <- NA_real_; z_upper <- NA_real_ }

  draws <- MASS::mvrnorm(n_sim, mu = stats::coef(fit), Sigma = stats::vcov(fit))
  alpha <- draws[, "(Intercept)"]; beta <- draws[, "temp"]
  ctmax_d <- (log10_tr - (alpha + log10(time_multiplier))) / beta
  # T_crit anchored at the 1 h CTmax (invariant to t_ref), matching ts_stage2()
  # and extract_tdt(); the reported CTmax bounds still track t_ref.
  ctmax1h_d <- (log10(60) - (alpha + log10(time_multiplier))) / beta
  tcrit_d   <- ctmax1h_d + (-1 / beta) * log_rate_mid
  q <- function(x, p) stats::quantile(x, p, na.rm = TRUE, names = FALSE)
  summary_ci <- tibble::tibble(
    z_lower = z_lower, z_upper = z_upper,
    CTmax_lower = q(ctmax_d, a), CTmax_upper = q(ctmax_d, 1 - a),
    Tcrit_lower = q(tcrit_d, a), Tcrit_upper = q(tcrit_d, 1 - a))

  curve_ci <- if (is.null(temp_grid)) {
    tibble::tibble(temp = numeric(0), duration_lower = numeric(0),
                   duration_upper = numeric(0))
  } else {
    pr <- stats::predict(fit, newdata = data.frame(temp = temp_grid),
                          interval = "confidence", level = level)
    tibble::tibble(temp = temp_grid,
      duration_lower = 10 ^ as.numeric(pr[, "lwr"]) * time_multiplier,
      duration_upper = 10 ^ as.numeric(pr[, "upr"]) * time_multiplier)
  }
  list(summary_ci = summary_ci, curve_ci = curve_ci)
}

# Note: `%||%` is provided package-internally by R/utils.R.

#' Median LT-vs-temperature line from a two-stage fit
#'
#' @param stage2 Output of [ts_stage2()].
#' @param temp_grid Temperatures (°C) to evaluate.
#' @param time_multiplier Optional explicit check against the setting recorded by
#'   [ts_stage2()]. By default the Stage-2 setting is inherited.
#' @return A tibble with `temp` and `duration_median` (minutes).
#' @examples
#' d <- simulate_tls(
#'   family = "binomial", temps = seq(30, 42, by = 2),
#'   times = c(0.01, 0.03, 0.1, 0.3, 1, 3, 10, 30, 100),
#'   reps = 4, n = 50, CTmax = 36, z = 4, seed = 42
#' )
#' s2 <- ts_stage2(ts_stage1(d, "temp", "duration", "survived", "total"),
#'                 t_ref = 60, time_multiplier = 60)
#' ts_curve(s2, temp_grid = seq(30, 42, 1))
#' @export
ts_curve <- function(stage2, temp_grid, time_multiplier = NULL) {
  settings <- ts_stage2_settings(stage2, time_multiplier = time_multiplier)
  time_multiplier <- settings$time_multiplier
  if (is.null(stage2$fit))
    return(tibble::tibble(temp = temp_grid, duration_median = NA_real_))
  co <- stats::coef(stage2$fit)
  tibble::tibble(
    temp = temp_grid,
    duration_median = 10 ^ (as.numeric(co[["(Intercept)"]]) +
                            as.numeric(co[["temp"]]) * temp_grid) * time_multiplier)
}

# Resolve the time convention once, at Stage 2. Older hand-built Stage-2 objects
# get the historical defaults; ordinary ts_stage2() objects always carry settings.
ts_stage2_settings <- function(stage2, t_ref = NULL, time_multiplier = NULL,
                               TC_rate_range = NULL) {
  recorded <- stage2$settings %||% list(
    t_ref = 60, time_multiplier = 1, TC_rate_range = c(0.1, 1)
  )
  supplied <- list(
    t_ref = t_ref, time_multiplier = time_multiplier,
    TC_rate_range = TC_rate_range
  )
  for (nm in names(supplied)) {
    value <- supplied[[nm]]
    if (!is.null(value) && !isTRUE(all.equal(as.numeric(value), as.numeric(recorded[[nm]])))) {
      cli::cli_abort(c(
        "{.arg {nm}} must match the convention used in {.fn ts_stage2}.",
        i = "Stage 2 used {.code {nm} = {paste(recorded[[nm]], collapse = ', ')}}; omit {.arg {nm}} to inherit it."
      ))
    }
  }
  if (!is.numeric(recorded$t_ref) || length(recorded$t_ref) != 1L || recorded$t_ref <= 0 ||
      !is.numeric(recorded$time_multiplier) || length(recorded$time_multiplier) != 1L ||
      recorded$time_multiplier <= 0) {
    cli::cli_abort("The Stage-2 time convention is invalid.")
  }
  recorded
}

# A legacy one-hour label is only mathematically truthful for t_ref = 60 min.
ts_add_one_hour_alias <- function(summary, settings) {
  if (isTRUE(all.equal(as.numeric(settings$t_ref), 60))) {
    summary$CTmax_1hr <- summary$CTmax
  }
  summary
}

ts_add_one_hour_ci_alias <- function(ci, settings) {
  if (isTRUE(all.equal(as.numeric(settings$t_ref), 60))) {
    ci$CTmax_1hr <- ci$CTmax
  }
  ci
}
