#' Identifiability and data-adequacy diagnostics for thermal-load-sensitivity fits
#'
#' freqTLS emits explicit identifiability warnings rather than letting weak
#' data quietly produce confident-looking estimates. This is the package's
#' clearest value-add over the Bayesian path. The diagnostic contract splits into
#' two groups:
#'
#' * **Data-adequacy (1-8)** depend only on the data and design and are checked by
#'   `check_tls_data()`, which [fit_tls()] runs before optimising. They are also
#'   surfaced after the fact by [check_tls()].
#' * **Profile-geometry (9-12)** depend on the profile likelihood and are emitted
#'   by the profiling code in `R/profile.R` / `R/confint.R`.
#'
#' All warnings use [cli::cli_warn()] so they can be caught with
#' [withCallingHandlers()] / [tryCatch()] and silenced with
#' [suppressWarnings()].
#'
#' @name tls-diagnostics
#' @keywords internal
NULL

#' Run the data-adequacy diagnostics (warnings 1-8)
#'
#' Inspects the raw data and design and emits a [cli::cli_warn()] for each
#' data-adequacy concern it finds. Called by [fit_tls()]
#' on the assembled vectors; also callable directly. Returns a character vector
#' of the warning codes that fired (invisibly when called for its side effects),
#' which [check_tls()] reuses.
#'
#' @param y Numeric vector of successes (survivors).
#' @param n Numeric vector of trials.
#' @param time Numeric vector of exposure durations in minutes.
#' @param temp Numeric vector of assay temperatures.
#' @param group Optional grouping vector (or `NULL`).
#' @param ctmax Optional numeric vector of fitted `CTmax` value(s); when supplied,
#'   the `CTmax`-extrapolation check (item 7) is evaluated. `fit_tls()` does not
#'   pass this (the fit is not yet available), so item 7 is surfaced post-fit by
#'   [check_tls()].
#' @param phi Optional fitted `phi` (item 8, beta-binomial only); surfaced post-fit
#'   by [check_tls()].
#' @return Invisibly, a character vector of the warning codes that fired.
#' @keywords internal
#' @noRd
check_tls_data <- function(y, n, time, temp, group = NULL,
                           ctmax = NULL, phi = NULL) {
  fired <- character(0)
  warn <- function(code, ...) {
    fired <<- c(fired, code)
    cli::cli_warn(...)
  }

  # 1. Fewer than 3 unique temperatures: CTmax / z slope is barely identified.
  n_temp <- length(unique(temp))
  if (n_temp < 3L) {
    warn("temps", c(
      "Fewer than 3 unique temperatures ({n_temp} found).",
      i = "CTmax and z are determined by how the survival midpoint shifts with temperature; with < 3 temperatures the slope is weakly identified.",
      i = "Add at least one distinct assay temperature and span the survival transition before interpreting CTmax or z; otherwise report the design limitation and expect wide or open intervals."
    ))
  }

  # 2. Fewer than 3 unique durations, overall and within any temperature.
  n_time <- length(unique(time))
  if (n_time < 3L) {
    warn("durations", c(
      "Fewer than 3 unique durations ({n_time} found) overall.",
      i = "The within-temperature dose-response (low, up, k) is weakly identified with < 3 durations.",
      i = "Add durations on both sides of the survival transition at each temperature; otherwise avoid interpreting the shape parameters."
    ))
  } else {
    per_temp <- tapply(time, temp, function(tt) length(unique(tt)))
    thin <- names(per_temp)[per_temp < 3L]
    if (length(thin) > 0L) {
      warn("durations_per_temp", c(
        "Fewer than 3 unique durations at {cli::qty(length(thin))} temperature{?s} {.val {thin}}.",
        i = "The dose-response curve is weakly identified at those temperatures.",
        i = "Add durations at the listed temperatures so each has at least three distinct exposure times spanning the transition."
      ))
    }
  }

  # 3. No mortality anywhere: every individual survived.
  if (all(y >= n)) {
    warn("no_mortality", c(
      "No mortality anywhere: every individual survived in every cell.",
      i = "The lower asymptote and the temperature at which survival drops are not identified.",
      i = "Extend temperature or duration until some mortality is observed, then refit; CTmax and z cannot be recovered from the current data."
    ))
  }

  # 4. All mortality anywhere: every individual died.
  if (all(y <= 0)) {
    warn("all_mortality", c(
      "All mortality anywhere: no individual survived in any cell.",
      i = "The upper asymptote and the temperature at which survival drops are not identified.",
      i = "Include lower temperatures or shorter durations that retain some survivors, then refit."
    ))
  }

  # 5. The mortality threshold is never crossed: survival never transitions from
  #    high to low across the observed duration / temperature span. We flag the
  #    case where the observed proportion survived stays on one side of 0.5.
  prop <- y / n
  if (all(y < n) && all(y > 0)) {
    # only meaningful when there is partial mortality somewhere
    if (all(prop > 0.5) || all(prop < 0.5)) {
      warn("threshold", c(
        "The 50% survival threshold is never crossed in the observed data.",
        i = "Observed survival proportions are all {if (all(prop > 0.5)) 'above' else 'below'} 0.5, so the midpoint (and hence CTmax) is extrapolated.",
        i = "Extend the temperature-duration design until observed survival lies on both sides of 0.5; until then, label CTmax as extrapolated."
      ))
    }
  }

  # 6. An asymptote is never approached: survival never reaches near 0 or near 1,
  #    so the corresponding asymptote (low / up) is poorly determined.
  hi <- max(prop)
  lo <- min(prop)
  if (hi < 0.8) {
    warn("up_not_approached", c(
      "The upper survival asymptote is never approached (max observed survival {round(hi, 2)} < 0.80).",
      i = "The upper asymptote `up` is weakly identified.",
      i = "Add milder conditions (lower temperature or shorter duration) that produce survival near 1, or avoid interpreting `up`."
    ))
  }
  if (lo > 0.2) {
    warn("low_not_approached", c(
      "The lower survival asymptote is never approached (min observed survival {round(lo, 2)} > 0.20).",
      i = "The lower asymptote `low` is weakly identified.",
      i = "Add harsher conditions (higher temperature or longer duration) that produce survival near 0, or avoid interpreting `low`."
    ))
  }

  # 7. CTmax extrapolated beyond the assayed temperatures (post-fit only).
  if (!is.null(ctmax)) {
    tr <- range(temp)
    out <- ctmax[ctmax < tr[1] | ctmax > tr[2]]
    if (length(out) > 0L) {
      warn("ctmax_extrapolated", c(
        "A fitted CTmax ({paste(round(out, 2), collapse = ', ')}) lies outside the assayed temperature range [{round(tr[1], 2)}, {round(tr[2], 2)}].",
        i = "Expand the assay range to bracket CTmax and refit; if that is impossible, report CTmax explicitly as an extrapolation and do not treat its interval as design-supported."
      ))
    }
  }

  # 8. phi at the binomial limit (post-fit only): very large phi means the
  #    beta-binomial has collapsed to a binomial.
  if (!is.null(phi) && is.finite(phi) && phi > 1e4) {
    warn("phi_binomial_limit", c(
      "The overdispersion parameter phi ({signif(phi, 3)}) is at the binomial limit.",
      i = "The beta-binomial has effectively collapsed to a binomial; consider `family = \"binomial\"`."
    ))
  }

  invisible(fired)
}

#' Report identifiability diagnostics for a fitted model
#'
#' `check_tls()` re-runs the data-adequacy diagnostics
#' on a fitted `profile_tls` object, including the two post-fit checks that
#' [fit_tls()] cannot run before the model exists: whether any fitted `CTmax` is
#' extrapolated beyond the assayed temperatures (item 7), and whether `phi` has
#' reached the binomial limit (item 8). Each concern is emitted as a
#' [cli::cli_warn()]. Use it to audit a fit, or after [suppressWarnings()] around
#' [fit_tls()].
#'
#' The profile-geometry diagnostics (items 9-12) are emitted by [confint()] and
#' [profile()] when those are called, not here, because they require the profile
#' likelihood.
#'
#' @section Recovery guide:
#' The warning code returned by `check_tls()` identifies the next action:
#'
#' * `temps`: assay at least three distinct temperatures spanning the survival
#'   transition.
#' * `durations` / `durations_per_temp`: assay at least three distinct durations
#'   per temperature, with times on both sides of the transition.
#' * `no_mortality`: extend to hotter or longer exposures until mortality occurs.
#' * `all_mortality`: add cooler or shorter exposures that retain survivors.
#' * `threshold`: extend the design until observed survival straddles 0.5.
#' * `up_not_approached` / `low_not_approached`: add milder / harsher conditions
#'   approaching survival 1 / 0, or do not interpret that asymptote.
#' * `ctmax_extrapolated`: expand the assayed temperature range to bracket CTmax;
#'   otherwise report it explicitly as extrapolated.
#' * `phi_binomial_limit`: consider the simpler binomial family.
#'
#' After changing the design or family, refit and rerun `check_tls()`. For an
#' existing data set that cannot be augmented, use the warning to limit the
#' scientific claim; `vignette("profile-likelihood")` explains the strict
#' `fallback = FALSE` diagnostic and the default bootstrap recovery attempt.
#'
#' @param fit A `profile_tls` fit from [fit_tls()], or a `freq_tls` workflow from
#'   [fit_4pl()].
#' @return Invisibly, a character vector of the diagnostic codes that fired.
#' @examples
#' d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
#' fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
#'                family = "binomial", tref = 60)
#' codes <- check_tls(fit)
#' codes # character(0) means no data-adequacy diagnostic fired
#' @export
check_tls <- function(fit) {
  if (inherits(fit, "freq_tls")) fit <- fit$fit
  if (!inherits(fit, "profile_tls")) {
    cli::cli_abort("{.arg fit} must be a {.cls profile_tls} object from {.fn fit_tls} (or a {.cls freq_tls} workflow from {.fn fit_4pl}).")
  }
  d <- fit$diag_data
  if (is.null(d)) {
    cli::cli_abort(c(
      "This fit does not carry the data needed for diagnostics.",
      i = "Refit with the current version of {.fn fit_tls}."
    ))
  }
  ctmax <- fit$estimates$estimate[startsWith(fit$estimates$parameter, "CTmax")]
  phi <- if (fit$family$family_code >= 1L) {
    fit$estimates$estimate[fit$estimates$parameter == "phi"]
  } else {
    NULL
  }
  check_tls_data(
    y = d$y, n = d$n, time = d$time, temp = d$temp, group = d$group,
    ctmax = ctmax, phi = phi
  )
}
