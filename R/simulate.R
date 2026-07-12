#' Simulate survival-count data from the 4PL thermal-load-sensitivity model
#'
#' `simulate_tls()` draws survival counts from the locked data-generating
#' process used throughout the freqTLS test suite and benchmarks. It builds a
#' factorial grid of temperatures by durations by replicates, computes the true
#' survival probability under the direct-`CTmax`/`z` 4PL (the same forward map as
#' the TMB engine in `src/profile_tls.cpp`), and draws binomial or beta-binomial
#' counts. The simulating truth is attached as `attr(, "truth")`.
#'
#' @details
#' ## The `phi` convention
#' For the beta-binomial family, `phi` is the **sum of the Beta shape
#' parameters**: counts are drawn as `prob <- rbeta(a = p * phi, b = (1 - p) *
#' phi)` followed by `rbinom(n, prob)`. The Beta mean is `p` and its variance is
#' `p (1 - p) / (phi + 1)`, so **larger `phi` means less overdispersion** and the
#' binomial is recovered as `phi -> Inf`. This matches the engine's
#' parameterisation in [beta_binomial_tls()].
#'
#' @param temps Numeric vector of assay temperatures (degrees C).
#' @param times Numeric vector of exposure durations (native unit, e.g. hours).
#' @param reps Number of replicate observations per temperature-by-duration
#'   cell (per group).
#' @param n Number of individuals per observation (binomial size).
#' @param low,up Lower and upper survival asymptotes (`0 < low < up < 1`). A
#'   scalar (shared) or, for a grouped simulation, one value per group.
#' @param k Steepness of the logistic on the `log10(duration)` scale (`k > 0`). A
#'   scalar (shared) or, for a grouped simulation, one value per group.
#' @param CTmax Critical thermal maximum at `tref`. A scalar (ungrouped) or, for
#'   a grouped simulation, a vector with one value per group.
#' @param z Thermal sensitivity (`z > 0`). A scalar or, when grouped, a vector
#'   with one value per group.
#' @param phi Dispersion (sum of Beta shapes); `NULL` for the binomial family.
#'   Required when `family = "beta_binomial"` or `family = "beta"`.
#' @param family One of `"binomial"`, `"beta_binomial"`, or `"beta"` (a
#'   continuous proportion in `(0, 1)`, returned in a `prop` column).
#' @param group Optional **atomic** vector of group labels (character, factor,
#'   or numeric). When supplied, `CTmax` and `z` must each be either a single
#'   scalar (shared across groups) or a vector with one value per *distinct*
#'   group level, in the order the levels first appear. Passing a list (for
#'   example `group = list(A = list(CTmax = 34))`) is an error: use the parallel
#'   vector API instead, e.g.
#'   `simulate_tls(group = c("A", "B"), CTmax = c(34, 38), z = c(3, 5))`.
#' @param re_sd Optional standard deviation of a **random intercept on `CTmax`**.
#'   When supplied (with `n_re_groups`), `n_re_groups` group-level deviations
#'   `b_g ~ N(0, re_sd)` are drawn and each group's data is generated with
#'   `CTmax_g = CTmax + b_g`. This is the data-generating analogue of the
#'   `CTmax ~ 1 + (1 | group)` engine; `CTmax` and `z` must be scalars and it
#'   cannot be combined with a fixed `group`. The realised deviations are
#'   returned in `attr(, "truth")$b`.
#' @param re_sd_z Optional standard deviation of a **random intercept on
#'   `log(z)`**. When supplied (with `n_re_groups`), `n_re_groups` group-level
#'   deviations `c_g ~ N(0, re_sd_z)` are drawn on the log scale and each group's
#'   data is generated with `z_g = exp(log(z) + c_g)` (a multiplicative spread on
#'   `z`). This is the data-generating analogue of the `log_z ~ 1 + (1 | group)`
#'   engine. It may be combined with `re_sd` (both intercepts share the one
#'   `re_group_name` grouping); the realised log-z deviations are returned in
#'   `attr(, "truth")$b_logz`.
#' @param re_sd_low,re_sd_logk Optional standard deviations of **random
#'   intercepts on the lower asymptote `low` (logit scale)** and on the steepness
#'   **`log(k)`** — the shape-coordinate analogues of `re_sd` / `re_sd_z`
#'   (`low_g = plogis(qlogis(low) + d_g)`, `k_g = exp(log(k) + e_g)`; `up` tracks
#'   `low` by a fixed head-room fraction). The simulator can generate these
#'   deviations alongside `re_sd` / `re_sd_z`; realised deviations are in
#'   `attr(, "truth")$b_low` / `$b_logk`.
#' @param n_re_groups Number of random-effect groups (required with any `re_sd*`).
#' @param re_group_name Name of the grouping column added to the output for the
#'   random-effect mode (default `"colony"`).
#' @param tref Reference time at which `CTmax` is defined (default `1`).
#' @param seed Optional integer seed for reproducibility.
#'
#' @return A base `data.frame` with columns `temp`, `duration`, the true
#'   probability `p`, and (when grouped) `group`. The count families
#'   (`binomial`, `beta_binomial`) add `total` and `survived`; the `beta` family
#'   instead adds a single continuous proportion column `prop`. The
#'   data-generating parameters are attached as `attr(, "truth")`.
#'
#' @examples
#' d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
#' head(d)
#' attr(d, "truth")$CTmax
#'
#' @export
simulate_tls <- function(temps = seq(30, 42, by = 2),
                         times = c(0.5, 1, 2, 4, 8),
                         reps = 3, n = 20,
                         low = 0.02, up = 0.98, k = 5,
                         CTmax = 36, z = 3, phi = NULL,
                         family = c("binomial", "beta_binomial", "beta"),
                         group = NULL, re_sd = NULL, re_sd_z = NULL,
                         re_sd_low = NULL, re_sd_logk = NULL,
                         n_re_groups = NULL,
                         re_group_name = "colony", tref = 1, seed = NULL) {
  family <- match.arg(family)
  if (!is.null(seed)) set.seed(seed)

  if (!all(low > 0 & up < 1 & low < up)) {
    cli::cli_abort("Asymptotes must satisfy {.code 0 < low < up < 1}.")
  }
  if (!is.numeric(CTmax) || !is.numeric(z)) {
    cli::cli_abort("{.arg CTmax} and {.arg z} must be numeric.")
  }
  if (any(k <= 0) || any(z <= 0) || tref <= 0) {
    cli::cli_abort("{.arg k}, {.arg z}, and {.arg tref} must be positive.")
  }
  if (family %in% c("beta_binomial", "beta") && is.null(phi)) {
    cli::cli_abort("{.arg phi} is required for the {.val {family}} family.")
  }

  grouped <- !is.null(group)
  if (grouped) {
    # Footgun guard: a list (or other non-atomic) group must not silently fall
    # through to default CTmax/z. Direct the user to the parallel vector API.
    if (!is.atomic(group) || is.list(group)) {
      cli::cli_abort(c(
        "{.arg group} must be an atomic vector of group labels, not a {.cls {class(group)[1]}}.",
        i = "Use the parallel vector API, e.g. {.code simulate_tls(group = c(\"A\", \"B\"), CTmax = c(34, 38), z = c(5, 3))}.",
        i = "Each of {.arg CTmax} and {.arg z} is then a scalar (shared) or one value per group."
      ))
    }
    if (anyNA(group)) {
      cli::cli_abort("{.arg group} must not contain missing values.")
    }
  }

  # Distinct group levels in first-appearance order, matching the `~ 0 + group`
  # design that `fit_tls()` builds (so simulate and fit agree on level order).
  levels_g <- if (grouped) unique(as.character(group)) else "all"
  ng <- length(levels_g)

  CTmax <- tls_recycle_param(CTmax, ng, "CTmax", grouped)
  z <- tls_recycle_param(z, ng, "z", grouped)
  # Shapes may also vary per group (v0.2 covariate effects on low/up/log_k); a
  # scalar is the shared default.
  low <- tls_recycle_param(low, ng, "low", grouped)
  up <- tls_recycle_param(up, ng, "up", grouped)
  k <- tls_recycle_param(k, ng, "k", grouped)

  log10_tref <- log10(tref)

  # ---- random-intercept mode (CTmax/log_z/low/log_k ~ 1 + (1 | group)) -------
  # Draw n_re_groups group-level deviations on the requested coordinate(s):
  # b ~ N(0, re_sd) on CTmax, c ~ N(0, re_sd_z) on log(z), d ~ N(0, re_sd_low) on
  # the logit of low, e ~ N(0, re_sd_logk) on log(k); build the full grid per group
  # with the shifted parameters. Mirrors the engine's random intercepts. A
  # deviation that is not requested is exactly zero and draws no RNG, so a call
  # using only some of them is bit-identical to the previous behaviour.
  if (!is.null(re_sd) || !is.null(re_sd_z) || !is.null(re_sd_low) || !is.null(re_sd_logk)) {
    if (grouped) {
      cli::cli_abort(c(
        "The {.arg re_sd*} random intercepts cannot be combined with fixed {.arg group}.",
        i = "Use {.arg group} for fixed per-group values, or the {.arg re_sd*} arguments for random intercepts."
      ))
    }
    if (length(CTmax) != 1L || length(z) != 1L) {
      cli::cli_abort("With a random intercept, {.arg CTmax} and {.arg z} must be scalars.")
    }
    chk_sd <- function(v, nm) {
      if (!is.null(v) && (!is.numeric(v) || length(v) != 1L || v < 0)) {
        cli::cli_abort("{.arg {nm}} must be a single non-negative number.")
      }
    }
    chk_sd(re_sd, "re_sd")
    chk_sd(re_sd_z, "re_sd_z")
    chk_sd(re_sd_low, "re_sd_low")
    chk_sd(re_sd_logk, "re_sd_logk")
    if (is.null(n_re_groups) || !is.numeric(n_re_groups) || length(n_re_groups) != 1L ||
        n_re_groups < 1) {
      cli::cli_abort("A random intercept requires {.arg n_re_groups}, the number of random-effect groups.")
    }
    n_re_groups <- as.integer(n_re_groups)
    # Draw RNG only for the requested deviation(s) so a call using a subset keeps
    # the exact random stream of the previous implementation.
    b_ct   <- if (!is.null(re_sd))      stats::rnorm(n_re_groups, 0, re_sd)      else rep(0, n_re_groups)
    c_logz <- if (!is.null(re_sd_z))    stats::rnorm(n_re_groups, 0, re_sd_z)    else rep(0, n_re_groups)
    d_low  <- if (!is.null(re_sd_low))  stats::rnorm(n_re_groups, 0, re_sd_low)  else rep(0, n_re_groups)
    e_logk <- if (!is.null(re_sd_logk)) stats::rnorm(n_re_groups, 0, re_sd_logk) else rep(0, n_re_groups)
    gap_frac <- (up[1] - low[1]) / (1 - low[1])   # up tracks low by a fixed head-room fraction
    re_levels <- paste0("g", seq_len(n_re_groups))

    build_re <- function(gi) {
      grid <- expand.grid(temp = temps, duration = times, rep = seq_len(reps),
                          KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
      log_time <- log10(grid$duration)
      CTmax_g <- CTmax[1] + b_ct[gi]
      # Round-trip transforms (exp(log(.)), plogis(qlogis(.))) are not bit-identical,
      # so keep each parameter EXACTLY at its scalar value when its RE is absent.
      z_g   <- if (!is.null(re_sd_z))    exp(log(z[1]) + c_logz[gi])                      else z[1]
      low_g <- if (!is.null(re_sd_low))  stats::plogis(stats::qlogis(low[1]) + d_low[gi]) else low[1]
      up_g  <- if (!is.null(re_sd_low))  low_g + (1 - low_g) * gap_frac                   else up[1]
      k_g   <- if (!is.null(re_sd_logk)) exp(log(k[1]) + e_logk[gi])                      else k[1]
      mid <- log10_tref - (grid$temp - CTmax_g) / z_g
      eta <- k_g * (log_time - mid)
      p <- low_g + (up_g - low_g) * stats::plogis(-eta)
      if (family == "binomial") {
        survived <- stats::rbinom(nrow(grid), size = n, prob = p)
        out <- data.frame(temp = grid$temp, duration = grid$duration,
                          total = n, survived = survived, p = p,
                          stringsAsFactors = FALSE)
      } else if (family == "beta_binomial") {
        prob <- stats::rbeta(nrow(grid), p * phi, (1 - p) * phi)
        survived <- stats::rbinom(nrow(grid), size = n, prob = prob)
        out <- data.frame(temp = grid$temp, duration = grid$duration,
                          total = n, survived = survived, p = p,
                          stringsAsFactors = FALSE)
      } else {
        prop <- stats::rbeta(nrow(grid), p * phi, (1 - p) * phi)
        out <- data.frame(temp = grid$temp, duration = grid$duration,
                          prop = prop, p = p, stringsAsFactors = FALSE)
      }
      out[[re_group_name]] <- re_levels[gi]
      out
    }
    dat <- do.call(rbind, lapply(seq_len(n_re_groups), build_re))
    rownames(dat) <- NULL
    attr(dat, "truth") <- list(
      family = family, low = low[1], up = up[1], k = k[1],
      CTmax = CTmax[1], z = z[1], phi = phi, tref = tref,
      re_sd = re_sd, re_sd_z = re_sd_z, re_sd_low = re_sd_low,
      re_sd_logk = re_sd_logk, n_re_groups = n_re_groups,
      b = stats::setNames(b_ct, re_levels),
      b_logz = stats::setNames(c_logz, re_levels),
      b_low = stats::setNames(d_low, re_levels),
      b_logk = stats::setNames(e_logk, re_levels),
      re_group_name = re_group_name,
      grouped = FALSE, temps = temps, times = times, reps = reps, n = n
    )
    return(dat)
  }

  build_one <- function(gi) {
    grid <- expand.grid(
      temp = temps,
      duration = times,
      rep = seq_len(reps),
      KEEP.OUT.ATTRS = FALSE,
      stringsAsFactors = FALSE
    )
    log_time <- log10(grid$duration)
    # Same forward map as src/profile_tls.cpp (descending in log10 duration).
    mid <- log10_tref - (grid$temp - CTmax[gi]) / z[gi]
    eta <- k[gi] * (log_time - mid)
    p <- low[gi] + (up[gi] - low[gi]) * stats::plogis(-eta)

    if (family == "binomial") {
      survived <- stats::rbinom(nrow(grid), size = n, prob = p)
      out <- data.frame(
        temp = grid$temp,
        duration = grid$duration,
        total = n,
        survived = survived,
        p = p,
        stringsAsFactors = FALSE
      )
    } else if (family == "beta_binomial") {
      a <- p * phi
      b <- (1 - p) * phi
      prob <- stats::rbeta(nrow(grid), a, b)
      survived <- stats::rbinom(nrow(grid), size = n, prob = prob)
      out <- data.frame(
        temp = grid$temp,
        duration = grid$duration,
        total = n,
        survived = survived,
        p = p,
        stringsAsFactors = FALSE
      )
    } else {
      prop <- stats::rbeta(nrow(grid), p * phi, (1 - p) * phi)
      out <- data.frame(
        temp = grid$temp,
        duration = grid$duration,
        prop = prop,
        p = p,
        stringsAsFactors = FALSE
      )
    }
    if (grouped) out$group <- levels_g[gi]
    out
  }

  parts <- lapply(seq_len(ng), build_one)
  dat <- do.call(rbind, parts)
  rownames(dat) <- NULL

  truth <- list(
    family = family,
    low = if (grouped) stats::setNames(low, levels_g) else low[1],
    up = if (grouped) stats::setNames(up, levels_g) else up[1],
    k = if (grouped) stats::setNames(k, levels_g) else k[1],
    CTmax = if (grouped) stats::setNames(CTmax, levels_g) else CTmax[1],
    z = if (grouped) stats::setNames(z, levels_g) else z[1],
    phi = phi,
    tref = tref,
    grouped = grouped,
    group_levels = levels_g,
    temps = temps, times = times, reps = reps, n = n
  )
  attr(dat, "truth") <- truth
  dat
}

#' Recycle a per-group parameter for `simulate_tls()`
#'
#' A scalar is recycled across all `ng` groups (an explicit "shared" recycle);
#' a length-`ng` vector is matched one-to-one to the (de-duplicated) group
#' levels; any other length is an error, so a mismatched vector cannot silently
#' recycle to the wrong groups.
#'
#' @param value The parameter vector (`CTmax` or `z`).
#' @param ng Number of distinct group levels.
#' @param nm Parameter name, for the error message.
#' @param grouped Whether a grouped simulation was requested.
#' @return A length-`ng` numeric vector.
#' @keywords internal
#' @noRd
tls_recycle_param <- function(value, ng, nm, grouped) {
  len <- length(value)
  if (len == 1L) {
    return(rep(value, ng))
  }
  if (len == ng) {
    return(value)
  }
  if (grouped) {
    cli::cli_abort(c(
      "{.arg {nm}} must be a single scalar or have one value per group.",
      i = "There are {cli::qty(ng)} {ng} distinct group level{?s}, but {.arg {nm}} has length {len}.",
      i = "Pass {.arg {nm}} as a length-{ng} vector aligned with the groups, or a single shared value."
    ))
  }
  cli::cli_abort(c(
    "{.arg {nm}} must be a single value for an ungrouped simulation.",
    i = "Got a length-{len} {.arg {nm}}; supply {.arg group} to simulate per-group values."
  ))
}
