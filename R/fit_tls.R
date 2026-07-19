#' Fit a single-stage 4PL thermal-load-sensitivity model by maximum likelihood
#'
#' `fit_tls()` fits the descending four-parameter logistic (4PL) thermal
#' death-time model to survival-count data, parameterised **directly in `CTmax`
#' (the critical thermal maximum at the reference time `tref`) and `z` (thermal
#' sensitivity, degrees Celsius per decade of duration) so that both headline
#' quantities can be profiled. Survival is modelled as a function of
#' `log10(duration)`; the midpoint moves with temperature through `CTmax` and `z`
#' (see `vignette("model-math")`). The thermal-load-sensitivity modelling framework
#' was introduced by Daniel W. A. Noble, Pieter A. Arnold, and Patrice Pottier in
#' [bayesTLS](https://daniel1noble.github.io/bayesTLS/).
#'
#' There are two equivalent interfaces. In the **column interface**, columns are
#' referenced with tidy evaluation: pass the bare column names of `data` (as in
#' `dplyr`), not strings. In the **formula interface**, pass a [tls_bf()] object
#' as `x` and the data frame as `data`; the brms/drmTMB-style grammar names the
#' response, the two axes, and the `CTmax` / `log_z` predictors. Both interfaces
#' feed the same likelihood engine, so a grouped formula fit and the matching
#' `group =` column fit are numerically identical.
#'
#' @section Experimental software:
#' **Use freqTLS at your own risk.** Results and APIs may be incorrect or
#' change. Users are responsible for checking their data, design, model
#' specification, convergence, identifiability, diagnostics, and
#' interpretation. Important analyses should be independently refitted and
#' cross-checked with [bayesTLS](https://daniel1noble.github.io/bayesTLS/)
#' ([source repository](https://github.com/daniel1noble/bayesTLS)). Agreement
#' is a cross-check, not proof of correctness; shared data or model errors can
#' make both packages agree.
#'
#' @param x Either a data frame (column interface) or a `tls_formula` from
#'   [tls_bf()] (formula interface). For back-compatibility the first argument is
#'   still positional, so `fit_tls(my_data, y = survived, ...)` continues to
#'   work.
#' @param data Used only in the formula interface: the data frame the
#'   [tls_bf()] columns are resolved against. Ignored in the column interface
#'   (where the data frame is `x`).
#' @param y <[`data-masked`][rlang::args_data_masking]> Column of successes
#'   (survivors), or, for the `beta` family, the response proportion in
#'   `(0, 1)`.
#' @param n <[`data-masked`][rlang::args_data_masking]> Column of trials (total
#'   individuals). Required for the binomial and beta-binomial families; omit it
#'   for the `beta` family, whose response is already a proportion.
#' @param time <[`data-masked`][rlang::args_data_masking]> Column of exposure
#'   durations in the data's native unit (e.g. hours); used as
#'   `log10(duration)` internally.
#' @param temp <[`data-masked`][rlang::args_data_masking]> Column of assay
#'   temperatures (degrees C).
#' @param group <[`data-masked`][rlang::args_data_masking]> Optional grouping
#'   column. When supplied, each group gets its own direct, profile-able `CTmax`
#'   and `z` with shared `low`, `up`, and `k`. Defaults to `NULL` (a single
#'   ungrouped fit).
#' @param family One of `"beta_binomial"` (default), `"binomial"`, or `"beta"`
#'   (a continuous proportion in `(0, 1)`), or a `tls_family` object from
#'   [beta_binomial_tls()] / [binomial_tls()] / [beta_tls()].
#' @param tref Reference time at which `CTmax` is defined, in the same unit as
#'   `time` (default `1`, i.e. CTmax at one time unit).
#' @param start Optional named list of starting values on the internal
#'   (unconstrained) scale, overriding the defaults. Names must match the
#'   parameters in `src/profile_tls.cpp` (`beta_low`, `beta_up`, `beta_logk`,
#'   `beta_CT`, `beta_logz`, `log_phi`).
#' @param control List of optimiser controls; `optimizer` is passed to
#'   [stats::nlminb()]'s `control`, and `trace` toggles optimiser output.
#' @param trace Logical; print optimiser progress. A shortcut for
#'   `control$trace`.
#' @param quiet Logical; if `TRUE`, suppress freqTLS's own data-adequacy and
#'   identifiability diagnostic warnings and messages (the few-groups, beta
#'   boundary-clamp, and same-grouping notes). Genuine errors and optimiser
#'   warnings still surface, and [check_tls()] reports the diagnostics on demand.
#'   Default `FALSE`.
#'
#' @return An object of class `c("profile_tls", "tls_fit")`: a list with the
#'   call, the resolved `family`, `tref`, `group_levels`, a `data_summary`, the
#'   internal-scale MLE `par`, an `estimates` data frame of natural-scale
#'   parameters with standard errors, the `vcov` of the internal coordinates,
#'   the `logLik`, residual `df`, `AIC`, a `convergence` list
#'   (`code`/`pdHess`/`message`), the `name_map`, and the underlying TMB `obj`,
#'   optimiser `opt`, and `sdreport`.
#'
#' @section Before interpretation:
#' Run [check_tls()] on the fitted object. Its help page maps every
#' data-adequacy warning to a concrete design or analysis response.
#' `vignette("profile-likelihood")` explains strict open profiles and the
#' default bootstrap recovery attempt.
#'
#' @seealso [check_tls()], [confint.profile_tls()]
#'
#' @examples
#' d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
#' fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
#'                family = "binomial", tref = 1)
#' fit$estimates
#'
#' # The same fit through the formula interface:
#' fit2 <- fit_tls(
#'   tls_bf(survived | trials(total) ~ time(duration) + temp(temp)),
#'   data = d, family = "binomial", tref = 1
#' )
#'
#' @export
fit_tls <- function(x, y, n, time, temp, group = NULL,
                    family = c("beta_binomial", "binomial", "beta"),
                    tref = 1, start = NULL, control = list(),
                    trace = FALSE, quiet = FALSE, data = NULL) {
  call <- match.call()

  if (!is.numeric(tref) || length(tref) != 1L || tref <= 0) {
    cli::cli_abort("{.arg tref} must be a single positive number.")
  }
  fam <- resolve_tls_family(family)

  # When `quiet`, suppress freqTLS's own diagnostic warnings/messages (run
  # check_tls() for them on demand); genuine errors and optimiser warnings still
  # surface.
  maybe_quiet <- function(expr) {
    if (isTRUE(quiet)) suppressWarnings(suppressMessages(expr)) else expr
  }

  # ---- resolve inputs: formula interface vs. column interface ---------------
  # The first argument `x` is polymorphic: a `tls_formula` from tls_bf() selects
  # the formula interface; a data frame selects the column interface. Both paths
  # converge on the same resolved vectors (y_v/n_v/time_v/temp_v), a `design`
  # list (X_CT/X_logz/levels/grouped), and `group_v` for diagnostics.
  if (inherits(x, "tls_formula")) {
    if (is.null(data)) {
      cli::cli_abort(c(
        "The formula interface needs a {.arg data} frame.",
        i = "Call {.code fit_tls(tls_bf(...), data = your_data, ...)}."
      ))
    }
    spec <- tls_parse_formula(x, data, quiet = quiet)
    tdt_meta <- attr(data, "tdt_meta")
    temp_center <- tdt_meta$temp_mean %||% {
      if (all(c("temp", "temp_c") %in% names(data))) {
        delta <- unique(as.numeric(data$temp) - as.numeric(data$temp_c))
        if (length(delta) == 1L && is.finite(delta)) delta else NULL
      } else NULL
    }
    y_v <- spec$y
    n_v <- spec$n
    time_v <- spec$time
    temp_v <- spec$temp
    # Single-factor grouping (`CTmax ~ group`) reconstructs the per-row labels so
    # the group-aware diagnostics, `diag_data`, and plots match the column
    # interface. A general multi-predictor design has no single grouping label,
    # so this is NULL there; the fit itself is unaffected (it uses the design
    # matrices below).
    group_v <- spec$group
    design <- list(
      X_CT = spec$X_CT, X_logz = spec$X_logz,
      X_low = spec$X_low, X_up = spec$X_up, X_logk = spec$X_logk,
      levels = spec$levels, grouped = spec$grouped,
      fixed_terms = spec$fixed_terms,
      shape_terms = spec$shape_terms,
      re = spec$re,
      re_logz = spec$re_logz,
      re_low = spec$re_low,
      re_logk = spec$re_logk
    )
  } else {
    if (!is.data.frame(x)) {
      cli::cli_abort(c(
        "{.arg x} must be a data frame (column interface) or a {.cls tls_formula} from {.fn tls_bf} (formula interface).",
        i = "Got {.cls {class(x)}}."
      ))
    }
    data <- x
    temp_center <- NULL

    # ---- tidy-eval the columns ----------------------------------------------
    y_q <- rlang::enquo(y)
    n_q <- rlang::enquo(n)
    time_q <- rlang::enquo(time)
    temp_q <- rlang::enquo(temp)
    group_q <- rlang::enquo(group)

    y_v <- rlang::eval_tidy(y_q, data)
    n_v <- if (rlang::quo_is_missing(n_q)) NULL else rlang::eval_tidy(n_q, data)
    time_v <- rlang::eval_tidy(time_q, data)
    temp_v <- rlang::eval_tidy(temp_q, data)
    group_v <- if (rlang::quo_is_null(group_q)) {
      NULL
    } else {
      rlang::eval_tidy(group_q, data)
    }

    design <- build_tls_design(group_v, length(y_v))
  }

  # `n` (trials) is optional for the beta family, whose response is already a
  # proportion: supply a dummy the beta likelihood ignores. The count families
  # still require it, with a clear error rather than a cryptic eval failure.
  n_obs <- length(y_v)
  if (is.null(n_v)) {
    if (identical(fam$family, "beta")) {
      n_v <- rep(1, n_obs)
    } else {
      cli::cli_abort("{.arg n} (trials) is required for the {.val {fam$family}} family.")
    }
  }

  for (nm in c("y", "n", "time", "temp")) {
    v <- get(paste0(nm, "_v"))
    if (!is.numeric(v)) {
      cli::cli_abort("Column {.arg {nm}} must be numeric.")
    }
  }
  lengths_ok <- all(c(length(n_v), length(time_v), length(temp_v)) == n_obs)
  if (!lengths_ok) {
    cli::cli_abort("{.arg y}, {.arg n}, {.arg time}, and {.arg temp} must have equal length.")
  }
  if (anyNA(y_v) || anyNA(n_v) || anyNA(time_v) || anyNA(temp_v)) {
    cli::cli_abort("{.arg y}, {.arg n}, {.arg time}, and {.arg temp} must not contain missing values.")
  }
  if (any(time_v <= 0)) {
    cli::cli_abort("{.arg time} (duration) must be strictly positive (it is log10-transformed).")
  }
  if (identical(fam$family, "beta")) {
    n_bad <- sum(y_v < 0 | y_v > 1)
    if (n_bad > 0L) {
      cli::cli_abort(c(
        "For the {.val beta} family the response must be a proportion in [0, 1].",
        i = "Found {n_bad} value{?s} outside [0, 1]; rescale the response to a proportion."
      ))
    }
    on_boundary <- y_v <= 0 | y_v >= 1
    if (any(on_boundary)) {
      eps <- 1e-6
      n_clamped <- sum(on_boundary)
      y_v <- pmin(pmax(y_v, eps), 1 - eps)
      if (!isTRUE(quiet)) {
        cli::cli_warn(c(
          "Clamped {n_clamped} boundary proportion{?s} (exactly 0 or 1) to ({eps}, {1 - eps}) for the beta likelihood.",
          i = "The beta density is undefined at 0 and 1; clamp inward, or model bounded counts with {.code family = \"beta_binomial\"}."
        ))
      }
    }
  } else if (any(y_v < 0) || any(n_v <= 0) || any(y_v > n_v)) {
    cli::cli_abort("Counts must satisfy {.code 0 <= y <= n} with {.code n > 0}.")
  }

  # ---- data-adequacy diagnostics --------------------------------------------
  # Emitted before fitting; the post-fit checks (7-8) are surfaced by
  # check_tls(). Never silent.
  maybe_quiet(check_tls_data(y = y_v, n = n_v, time = time_v, temp = temp_v, group = group_v))

  # ---- design matrices ------------------------------------------------------
  ng <- length(design$levels)

  log_time <- log10(time_v)
  log10_tref <- log10(tref)

  # Random intercepts on CTmax and/or log_z (formula `(1|group)`); NULL for the
  # column interface and any fixed-only fit. Each `re_index*` is 0-based, length
  # n_obs. When a block is absent its b vector is empty and its log_sd is mapped
  # out, so the fit is byte-identical to the fixed-effects model; `random` names
  # only the active blocks (NULL when there are none).
  re_spec <- design$re
  re_logz_spec <- design$re_logz
  re_random <- character(0)
  if (is.null(re_spec)) {
    re_index <- rep(0L, n_obs)
    b_CT_start <- numeric(0)
  } else {
    re_index <- as.integer(re_spec$index)
    b_CT_start <- rep(0, re_spec$n)
    re_random <- c(re_random, "b_CT")
  }
  if (is.null(re_logz_spec)) {
    re_index_logz <- rep(0L, n_obs)
    b_logz_start <- numeric(0)
  } else {
    re_index_logz <- as.integer(re_logz_spec$index)
    b_logz_start <- rep(0, re_logz_spec$n)
    re_random <- c(re_random, "b_logz")
  }
  # Random intercepts on the shape coordinates low / log_k (not the upper asymptote
  # `up`, which has no random-intercept term). Same byte-identical guard: an empty b_*
  # vector + a mapped log_sd_* when the block is absent.
  re_low_spec <- design$re_low
  if (is.null(re_low_spec)) {
    re_index_low <- rep(0L, n_obs)
    b_low_start <- numeric(0)
  } else {
    re_index_low <- as.integer(re_low_spec$index)
    b_low_start <- rep(0, re_low_spec$n)
    re_random <- c(re_random, "b_low")
  }
  re_logk_spec <- design$re_logk
  if (is.null(re_logk_spec)) {
    re_index_logk <- rep(0L, n_obs)
    b_logk_start <- numeric(0)
  } else {
    re_index_logk <- as.integer(re_logk_spec$index)
    b_logk_start <- rep(0, re_logk_spec$n)
    re_random <- c(re_random, "b_logk")
  }
  if (length(re_random) == 0L) re_random <- NULL

  # Shape-parameter designs (low, up via disjoint bounds, log_k). Intercept-only
  # by default (a single column of ones) so the fit is byte-identical to the
  # shared-shape model; the formula interface may supply grouped shape designs.
  X_shape_default <- matrix(1, nrow = n_obs, ncol = 1L,
                            dimnames = list(NULL, "all"))
  X_low <- design$X_low %||% X_shape_default
  X_up <- design$X_up %||% X_shape_default
  X_logk <- design$X_logk %||% X_shape_default
  # Each shape sub-parameter may now have an independent design width (e.g. a
  # continuous covariate on `log_k` only); the engine handles them separately.
  n_low <- ncol(X_low)
  n_up <- ncol(X_up)
  n_logk <- ncol(X_logk)

  # Disjoint-bounds asymptote scalars. P1 fixes bounds to c(0, 1); the `bounds`
  # argument is wired through with the fit_4pl facade (P3).
  b4 <- compute_4pl_bounds(0, 1)
  tmb_data <- list(
    y = as.numeric(y_v),
    n = as.numeric(n_v),
    log_time = as.numeric(log_time),
    temp = as.numeric(temp_v),
    X_CT = design$X_CT,
    X_logz = design$X_logz,
    X_low = X_low,
    X_up = X_up,
    X_logk = X_logk,
    family_code = fam$family_code,
    log10_tref = log10_tref,
    low_min = b4$low_min, low_w = b4$low_w,
    up_min = b4$up_min, up_w = b4$up_w,
    re_index = re_index,
    re_index_logz = re_index_logz,
    re_index_low = re_index_low,
    re_index_logk = re_index_logk
  )

  # ---- starting values ------------------------------------------------------
  parameters <- tls_default_start(
    temp_v,
    X_CT = design$X_CT,
    X_logz = design$X_logz,
    X_low = X_low,
    X_up = X_up,
    X_logk = X_logk,
    bounds = b4
  )
  if (!is.null(start)) {
    if (!is.list(start)) cli::cli_abort("{.arg start} must be a named list.")
    parameters[names(start)] <- start[names(start)]
  }
  # Random-intercept parameters appended after any `start` override so the
  # documented `start` names are unaffected: b_CT / b_logz (possibly empty) and
  # their log SDs.
  parameters$b_CT <- b_CT_start
  parameters$log_sd_CT <- 0   # log(sd) = 0 -> sd = 1 start
  parameters$b_logz <- b_logz_start
  parameters$log_sd_logz <- 0
  parameters$b_low <- b_low_start
  parameters$log_sd_low <- 0
  parameters$b_logk <- b_logk_start
  parameters$log_sd_logk <- 0

  # ---- map (fix log_phi out for the binomial family) ------------------------
  map <- list()
  if (fam$family_code == 0L) {
    map$log_phi <- factor(NA)
  }
  # No RE on a block: fix its log SD (its b vector is empty, nothing to
  # integrate). With an RE, the log SD is free and the b vector is the random
  # effect (named in `re_random`).
  if (is.null(re_spec)) {
    map$log_sd_CT <- factor(NA)
  }
  if (is.null(re_logz_spec)) {
    map$log_sd_logz <- factor(NA)
  }
  if (is.null(re_low_spec)) {
    map$log_sd_low <- factor(NA)
  }
  if (is.null(re_logk_spec)) {
    map$log_sd_logk <- factor(NA)
  }

  control$trace <- isTRUE(control$trace) || isTRUE(trace)

  # ---- fit ------------------------------------------------------------------
  engine <- fit_tls_engine(
    tmb_data = tmb_data,
    parameters = parameters,
    map = map,
    control = control,
    random = re_random
  )

  name_map <- tls_name_map(design$levels, fam, X_low, X_up, X_logk)

  # number of free parameters (df = length of optimised par)
  df <- length(engine$par)
  logLik_val <- -engine$opt$objective
  aic_val <- -2 * logLik_val + 2 * df

  estimates <- tls_estimates(engine, fam, design$levels, X_low, X_up, X_logk)
  vcov_mat <- tls_internal_vcov(engine)

  # Beta-binomial weak-dispersion advisory. When overdispersion is mild (phi
  # large, approaching the binomial limit) phi is weakly identified and its
  # relative SE blows up. The PROFILE interval for CTmax / z can then under-cover,
  # because the profiled-out phi runs to the binomial limit and the interval goes
  # too narrow; the Wald interval propagates the flat-phi uncertainty through the
  # joint Hessian and stays calibrated. Point users there. Advisory; gated by
  # `quiet`. (Relative SE of phi is the delta-method SE of log phi.)
  if (!isTRUE(quiet) && isTRUE(fam$family_code == 1L)) {
    phi_rel_se <- tls_phi_rel_se(estimates)
    if (is.finite(phi_rel_se) && phi_rel_se > 1) {
      cli::cli_warn(c(
        "The beta-binomial dispersion {.code phi} is weakly identified (relative SE {round(phi_rel_se, 1)}): the data are close to binomial.",
        i = "A {.strong profile} confidence interval for {.code CTmax} / {.code z} can under-cover in this regime; prefer {.code confint(method = \"wald\")} (the {.code fallback = TRUE} default does this automatically).",
        i = "If overdispersion is negligible, {.code family = \"binomial\"} may be the better model."
      ))
    }
  }

  data_summary <- list(
    n_obs = n_obs,
    n_groups = ng,
    grouped = design$grouped,
    temp_range = range(temp_v),
    time_range = range(time_v),
    n_temps = length(unique(temp_v)),
    n_times = length(unique(time_v)),
    total_trials = sum(n_v),
    total_successes = sum(y_v)
  )

  fit <- list(
    call = call,
    family = fam,
    tref = tref,
    group_levels = design$levels,
    # Per-shape right-hand sides for rebuilding shape designs from newdata in
    # predict() (NULL for the column interface, whose shapes are intercept-only).
    fixed_terms = design$fixed_terms,
    shape_terms = design$shape_terms,
    prediction_meta = list(temp_center = temp_center),
    re = re_spec,
    re_logz = re_logz_spec,
    re_low = re_low_spec,
    re_logk = re_logk_spec,
    data_summary = data_summary,
    par = engine$par,
    estimates = estimates,
    vcov = vcov_mat,
    logLik = logLik_val,
    df = df,
    AIC = aic_val,
    convergence = list(
      code = engine$convergence$code,
      pdHess = engine$convergence$pdHess,
      message = engine$convergence$message,
      optimizer = engine$convergence$optimizer
    ),
    name_map = name_map,
    obj = engine$obj,
    opt = engine$opt,
    sdreport = engine$sdreport,
    # Clean TMB inputs for map-refit profiling.
    tmb_inputs = engine$tmb_inputs,
    # Retained for the post-fit identifiability diagnostics (check_tls()).
    diag_data = list(
      y = as.numeric(y_v), n = as.numeric(n_v),
      time = as.numeric(time_v), temp = as.numeric(temp_v),
      group = group_v
    )
  )
  class(fit) <- c("profile_tls", "tls_fit")
  fit
}

#' Default starting values on the internal scale
#'
#' @param temp_v Numeric temperature vector (for the `CTmax` start).
#' @param ng Number of groups (length of `beta_CT` / `beta_logz`).
#' @param n_shape Number of shape-design columns (length of `beta_low` /
#'   `beta_up` / `beta_logk`); `1` for the shared-shape default.
#' @return Named list of starts matching `src/profile_tls.cpp` parameters.
#' @keywords internal
#' @noRd
tls_formula_start <- function(X, baseline) {
  out <- rep(0, ncol(X))
  intercept <- which(colnames(X) %in% "(Intercept)")
  if (length(intercept) == 1L) {
    out[intercept] <- baseline
  } else {
    # No-intercept factor designs are one-hot: every level needs the natural
    # baseline. Retain the previous all-baseline behaviour for other
    # no-intercept designs because they have no separate intercept coordinate.
    out[] <- baseline
  }
  out
}

tls_default_start <- function(temp_v, X_CT, X_logz, X_low, X_up, X_logk,
                              bounds = compute_4pl_bounds(0, 1)) {
  # Central-ish asymptote starts (low ~ 0.05, up ~ 0.95) on the disjoint-bounds
  # logit: extreme starts near the interval edges can make the RE Laplace inner
  # solve ill-conditioned and the gradient non-finite at iteration 0.
  beta_low0 <- stats::qlogis((0.05 - bounds$low_min) / bounds$low_w)
  beta_up0  <- stats::qlogis((0.95 - bounds$up_min) / bounds$up_w)
  list(
    beta_low = tls_formula_start(X_low, beta_low0),
    beta_up = tls_formula_start(X_up, beta_up0),
    beta_logk = tls_formula_start(X_logk, log(5)),
    beta_CT = tls_formula_start(X_CT, stats::median(temp_v)),
    beta_logz = tls_formula_start(X_logz, log(3)),
    log_phi = log(100)
  )
}

#' Build the natural-scale estimates table from the sdreport
#'
#' Reads the `ADREPORT`ed natural-scale parameters (and standard errors when
#' the `sdreport` succeeded) into a tidy table keyed by the human-facing
#' parameter names.
#'
#' @param engine The list returned by `fit_tls_engine()`.
#' @param fam The resolved `tls_family`.
#' @param group_levels Character vector of `CTmax` / `log_z` group levels.
#' @param X_low,X_up,X_logk The shape design matrices (used to classify each
#'   shape as a scalar, a one-hot grouping, or a general/continuous design).
#' @return A data frame with `parameter`, `group`, `estimate`, `std.error`.
#' @keywords internal
#' @noRd
tls_estimates <- function(engine, fam, group_levels, X_low, X_up, X_logk) {
  # Re-pin the objective at the MLE before reading the report: TMB::sdreport()
  # (run by the engine just before this) can leave the AD object at a non-optimal
  # parameter, and report() reads the current parameters. obj$fn(opt$par) restores
  # the optimum; for a random-effects fit it also re-solves the inner problem so
  # the report reflects the conditional modes. (opt$par is the fixed-effect MLE;
  # for a no-RE fit this reproduces the previous report(par) exactly.)
  engine$obj$fn(engine$opt$par)
  rep <- engine$obj$report()
  ng <- length(group_levels)

  # Link-scale coefficient vectors (for general shape designs whose per-column
  # natural report values are not meaningful -- a slope cannot be back-transformed).
  beta_of <- function(nm) {
    p <- engine$opt$par
    unname(p[names(p) == nm])
  }

  # Shape rows, classified by each design's own columns:
  #   scalar  (1 col)         -> the natural shared value, SE from the report block;
  #   one-hot (grouped)       -> natural per-group, named by the group columns;
  #   general (continuous)    -> LINK-scale coefficients (beta_*), named by the
  #                              design columns, SE from the sdreport FIXED block.
  shape_rows <- function(natural, beta_name, X, rep_vals, beta_vals) {
    nc <- ncol(X)
    if (nc == 1L) {
      data.frame(parameter = natural, group = NA_character_,
                 estimate = as.numeric(rep_vals[1L]), .se_block = "report",
                 .se_name = natural, .idx = 1L, stringsAsFactors = FALSE)
    } else if (tls_is_onehot(X)) {
      data.frame(parameter = paste0(natural, ":", colnames(X)),
                 group = colnames(X), estimate = as.numeric(rep_vals),
                 .se_block = "report", .se_name = natural, .idx = seq_len(nc),
                 stringsAsFactors = FALSE)
    } else {
      data.frame(parameter = paste0(natural, ":", colnames(X)),
                 group = NA_character_, estimate = as.numeric(beta_vals),
                 .se_block = "fixed", .se_name = beta_name, .idx = seq_len(nc),
                 stringsAsFactors = FALSE)
    }
  }
  rows <- list(
    shape_rows("low", "beta_low",  X_low,  rep$low, beta_of("beta_low")),
    shape_rows("up",  "beta_up",  X_up,  rep$up,  beta_of("beta_up")),
    shape_rows("k",   "beta_logk", X_logk, rep$k,   beta_of("beta_logk"))
  )

  ctmax_label <- if (ng == 1L) "CTmax" else paste0("CTmax:", group_levels)
  z_label <- if (ng == 1L) "z" else paste0("z:", group_levels)
  rows <- c(rows, list(
    data.frame(parameter = ctmax_label, group = group_levels,
               estimate = as.numeric(rep$beta_CT), .se_block = "report",
               .se_name = "beta_CT", .idx = seq_len(ng), stringsAsFactors = FALSE),
    data.frame(parameter = z_label, group = group_levels,
               estimate = as.numeric(rep$z_group), .se_block = "report",
               .se_name = "z_group", .idx = seq_len(ng), stringsAsFactors = FALSE)
  ))

  if (fam$family_code >= 1L) {
    rows <- c(rows, list(
      data.frame(parameter = "phi", group = NA_character_, estimate = rep$phi,
                 .se_block = "report", .se_name = "phi", .idx = 1L,
                 stringsAsFactors = FALSE)
    ))
  }
  # Random-intercept SDs, present only when the fit has the corresponding RE term.
  if (!is.null(rep$sigma_CT)) {
    rows <- c(rows, list(
      data.frame(parameter = "sigma_CTmax", group = NA_character_,
                 estimate = rep$sigma_CT, .se_block = "report",
                 .se_name = "sigma_CT", .idx = 1L, stringsAsFactors = FALSE)
    ))
  }
  if (!is.null(rep$sigma_logz)) {
    rows <- c(rows, list(
      data.frame(parameter = "sigma_logz", group = NA_character_,
                 estimate = rep$sigma_logz, .se_block = "report",
                 .se_name = "sigma_logz", .idx = 1L, stringsAsFactors = FALSE)
    ))
  }
  if (!is.null(rep$sigma_low)) {
    rows <- c(rows, list(
      data.frame(parameter = "sigma_low", group = NA_character_,
                 estimate = rep$sigma_low, .se_block = "report",
                 .se_name = "sigma_low", .idx = 1L, stringsAsFactors = FALSE)
    ))
  }
  if (!is.null(rep$sigma_logk)) {
    rows <- c(rows, list(
      data.frame(parameter = "sigma_logk", group = NA_character_,
                 estimate = rep$sigma_logk, .se_block = "report",
                 .se_name = "sigma_logk", .idx = 1L, stringsAsFactors = FALSE)
    ))
  }

  est <- do.call(rbind, rows)

  # Standard errors: the report (ADREPORT) block for natural-scale values, the
  # fixed (parameter) block for general link-scale coefficients.
  est$std.error <- NA_real_
  sdr <- engine$sdreport
  if (!is.null(sdr)) {
    sv_rep <- summary(sdr, select = "report")
    sv_fix <- tryCatch(summary(sdr, select = "fixed"), error = function(e) NULL)
    for (i in seq_len(nrow(est))) {
      sv <- if (identical(est$.se_block[i], "fixed")) sv_fix else sv_rep
      if (is.null(sv)) next
      hits <- which(rownames(sv) == est$.se_name[i])
      if (length(hits) >= est$.idx[i]) {
        est$std.error[i] <- sv[hits[est$.idx[i]], "Std. Error"]
      }
    }
  }

  rownames(est) <- NULL
  est[, c("parameter", "group", "estimate", "std.error")]
}

#' Variance-covariance of the internal coordinates
#'
#' @param engine The list returned by `fit_tls_engine()`.
#' @return The fixed-effect vcov matrix, or `NULL` if the `sdreport` failed.
#' @keywords internal
#' @noRd
tls_internal_vcov <- function(engine) {
  sdr <- engine$sdreport
  if (is.null(sdr)) return(NULL)
  vc <- tryCatch(sdr$cov.fixed, error = function(e) NULL)
  vc
}
