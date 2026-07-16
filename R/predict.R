#' Predict survival, link, or midpoint from a fitted freqTLS model
#'
#' `predict()` evaluates the fitted four-parameter logistic (4PL) thermal-load-
#' sensitivity model at new temperature-by-duration cells, using exactly the
#' same forward map as the TMB engine in `src/profile_tls.cpp`:
#' \deqn{mid = \log_{10}(t_{ref}) - (temp - CTmax_g) / z_g}
#' \deqn{p = low + (up - low)\,\mathrm{plogis}(-k(\log_{10}(duration) - mid)).}
#'
#' @details
#' Four response types are available:
#' * `"survival"` (default) returns the fitted survival probability in `(0, 1)`.
#' * `"link"` returns the logit of the survival probability,
#'   `qlogis(survival)`.
#' * `"midpoint"` returns the temperature-dependent 4PL midpoint `mid` on the
#'   `log10(duration)` axis (constant within a temperature, so the `duration`
#'   column is ignored for this type but a `temp` column is still required).
#' * `"parameters"` returns the row-specific natural-scale `CTmax`, `z`, `low`,
#'   `up`, and `k` values. This is useful for interacted formula designs; the
#'   `duration` column may be omitted.
#'
#' `newdata` must also contain every predictor used by the fitted fixed-effect
#' designs for `CTmax`, `log_z`, `low`, `up`, or `log_k`. For a grouped column-
#' interface fit, supply `group` with values from the fitted `group_levels`.
#' For a formula fit, a literal [tls_bf()] call preserves the fixed-design
#' formulas needed to rebuild transformed or interacted terms. If the model was
#' instead passed through a formula-object variable, `predict()` can rebuild
#' direct numeric design columns but asks the user to refit with a literal
#' [tls_bf()] call when a transformed or interacted design cannot be recovered
#' safely.
#'
#' @param object A `profile_tls` fit from [fit_tls()].
#' @param newdata A data frame with numeric columns `temp` and `duration`, plus
#'   every predictor used in the fitted `CTmax`, `log_z`, `low`, `up`, and
#'   `log_k` fixed designs. Include `group` for a grouped column-interface fit.
#'   Conditional random-effect predictions additionally require every fitted
#'   grouping column. `duration` must be strictly positive (it is
#'   `log10`-transformed). For `type = "midpoint"` or `"parameters"`, `duration`
#'   may be omitted.
#' @param type One of `"survival"` (default), `"link"`, `"midpoint"`, or
#'   `"parameters"`.
#' @param re.form How to handle fitted random intercepts. `"population"`
#'   (default) sets them to zero; `"conditional"` adds the fitted BLUP for each
#'   random-effect grouping column in `newdata`. When omitted for a random-
#'   effects fit, `predict()` warns that it is returning a population prediction.
#' @param ... Reserved; must be empty.
#'
#' @return For `type = "parameters"`, a data frame with one row per row of
#'   `newdata` and columns `CTmax`, `z`, `low`, `up`, and `k`. Otherwise a
#'   numeric vector with one element per row; survival values lie in `(0, 1)`.
#'
#' @examples
#' d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
#' fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
#'                family = "binomial", tref = 1)
#' nd <- expand.grid(temp = c(34, 36, 38), duration = c(1, 2, 4))
#' predict(fit, nd, type = "survival")
#'
#' # A continuous predictor used by CTmax and log_z must also be in newdata.
#' d$x <- rep(c(-1, 1), length.out = nrow(d))
#' fit_x <- fit_tls(
#'   tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
#'          CTmax ~ x, log_z ~ x),
#'   data = d, family = "binomial", tref = 1
#' )
#' predict(fit_x, data.frame(temp = 36, duration = 2, x = c(-1, 1)))
#'
#' \donttest{
#' # Choose population or fitted-group prediction explicitly for an RE fit.
#' dre <- simulate_tls(family = "binomial", CTmax = 36, z = 4,
#'                     re_sd = 1, n_re_groups = 8, seed = 2)
#' fit_re <- fit_tls(
#'   tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
#'          CTmax ~ 1 + (1 | colony)),
#'   data = dre, family = "binomial", tref = 1
#' )
#' colony <- as.character(ranef(fit_re)$group[1])
#' nd_re <- data.frame(temp = 36, duration = 2, colony = colony)
#' predict(fit_re, nd_re, re.form = "population")
#' predict(fit_re, nd_re, re.form = "conditional")
#' }
#'
#' @importFrom stats predict
#' @export
predict.profile_tls <- function(object, newdata,
                                type = c("survival", "link", "midpoint",
                                         "parameters"),
                                re.form = c("population", "conditional"),
                                ...) {
  dots <- list(...)
  if (length(dots) > 0L) {
    cli::cli_abort("{.arg ...} is reserved; pass only documented arguments.")
  }
  if (inherits(object, "freq_tls")) object <- object$fit
  if (!inherits(object, "profile_tls")) {
    cli::cli_abort("{.arg object} must be a {.cls profile_tls} fit from {.fn fit_tls}.")
  }
  type <- match.arg(type)
  re_form_missing <- missing(re.form)
  re.form <- match.arg(re.form)
  if (missing(newdata) || !is.data.frame(newdata)) {
    cli::cli_abort("{.arg newdata} must be a data frame with columns {.code temp} and {.code duration}.")
  }

  needs_duration <- !type %in% c("midpoint", "parameters")
  required <- if (needs_duration) c("temp", "duration") else "temp"
  missing_cols <- setdiff(required, names(newdata))
  if (length(missing_cols) > 0L) {
    cli::cli_abort(
      "{.arg newdata} is missing required column{?s}: {.code {missing_cols}}."
    )
  }

  temp <- newdata$temp
  if (!is.numeric(temp)) {
    cli::cli_abort("{.code newdata$temp} must be numeric.")
  }
  if (anyNA(temp)) {
    cli::cli_abort("{.code newdata$temp} must not contain missing values.")
  }

  # Resolve per-row CTmax and z from the (possibly grouped) fit.
  if (isTRUE(re_form_missing) && tls_has_re(object)) {
    cli::cli_warn(c(
      "Returning a population prediction with fitted random intercepts set to zero.",
      i = "Use {.code re.form = \"conditional\"} and include each fitted random-effect grouping column in {.arg newdata} to add its BLUP.",
      i = "Use {.code re.form = \"population\"} explicitly to silence this warning."
    ))
  }
  pars <- tls_predict_pars(object, newdata, re.form = re.form)

  if (identical(type, "parameters")) {
    return(data.frame(
      CTmax = pars$CTmax,
      z = pars$z,
      low = pars$low,
      up = pars$up,
      k = pars$k,
      row.names = NULL
    ))
  }

  log10_tref <- log10(object$tref)
  mid <- log10_tref - (temp - pars$CTmax) / pars$z

  if (identical(type, "midpoint")) {
    return(mid)
  }

  duration <- newdata$duration
  if (!is.numeric(duration)) {
    cli::cli_abort("{.code newdata$duration} must be numeric.")
  }
  if (anyNA(duration)) {
    cli::cli_abort("{.code newdata$duration} must not contain missing values.")
  }
  if (any(duration <= 0)) {
    cli::cli_abort("{.code newdata$duration} must be strictly positive (it is log10-transformed).")
  }

  # Per-row shape (constant for shared shapes; per-group for grouped shapes).
  eta <- pars$k * (log10(duration) - mid)
  surv <- pars$low + (pars$up - pars$low) * stats::plogis(-eta)

  if (identical(type, "link")) {
    return(stats::qlogis(surv))
  }
  surv
}

#' @rdname predict.profile_tls
#' @export
predict.freq_tls <- function(object, newdata,
                             type = c("survival", "link", "midpoint",
                                      "parameters"),
                             re.form = c("population", "conditional"),
                             ...) {
  predict.profile_tls(
    object = object,
    newdata = newdata,
    type = type,
    re.form = re.form,
    ...
  )
}

#' Resolve per-row CTmax, z, low, up, and k for a prediction
#'
#' Maps each row of `newdata` to its group's parameter values (or the single
#' ungrouped / shared estimate). A shared parameter is recycled across rows; a
#' grouped one (`nm:<level>`) is indexed by the row's group. Validates that any
#' supplied group is a known level. With shared shapes (the default) `low` / `up`
#' / `k` are constant across rows; with grouped shapes they vary by group.
#'
#' @param fit A `profile_tls` fit.
#' @param newdata The prediction data frame.
#' @return A list with numeric vectors `CTmax`, `z`, `low`, `up`, `k`, one element
#'   per row of `newdata`.
#' @keywords internal
#' @noRd
tls_predict_pars <- function(fit, newdata, re.form = "population") {
  est <- fit$estimates
  levels_g <- fit$group_levels
  ng <- length(levels_g)
  n_row <- nrow(newdata)
  shape_vars <- unique(unlist(lapply(fit$shape_terms %||% list(), all.vars)))
  if ("temp_c" %in% shape_vars && !"temp_c" %in% names(newdata)) {
    center <- fit$prediction_meta$temp_center %||% NULL
    if (!"temp" %in% names(newdata) || is.null(center) || !is.finite(center)) {
      cli::cli_abort(c(
        "Prediction must rebuild the fitted {.code temp_c} shape covariate.",
        i = "Supply {.code temp_c} in {.arg newdata}, or fit standardized data whose {.code tdt_meta$temp_mean} is available."
      ))
    }
    newdata$temp_c <- as.numeric(newdata$temp) - center
  }
  X_CT_fit <- fit$tmb_inputs$data$X_CT
  X_logz_fit <- fit$tmb_inputs$data$X_logz
  general_fixed <- ncol(X_CT_fit) > 1L && is.null(fit$diag_data$group)

  # Per-row group index: 1 for an ungrouped fit, else resolved and validated
  # from newdata$group.
  if (ng == 1L || general_fixed) {
    gi <- rep(1L, n_row)
  } else {
    if (is.null(newdata$group)) {
      cli::cli_abort(c(
        "{.arg newdata} must include a {.code group} column for a grouped fit.",
        i = "Fitted group levels: {.val {levels_g}}."
      ))
    }
    g <- as.character(newdata$group)
    if (anyNA(g)) {
      cli::cli_abort("{.code newdata$group} must not contain missing values.")
    }
    unknown <- setdiff(unique(g), levels_g)
    if (length(unknown) > 0L) {
      cli::cli_abort(c(
        "{.code newdata$group} has level{?s} not in the fit: {.val {unknown}}.",
        i = "Fitted group levels: {.val {levels_g}}."
      ))
    }
    gi <- match(g, levels_g)
  }

  # A shared parameter (one `nm` row) is recycled; a grouped one (`nm:<level>`)
  # is indexed by the row's group.
  resolve <- function(nm) {
    scalar <- est$estimate[est$parameter == nm]
    if (length(scalar) >= 1L) return(rep(scalar[1L], n_row))
    keyed <- est$parameter[startsWith(est$parameter, paste0(nm, ":"))]
    vals <- stats::setNames(
      est$estimate[startsWith(est$parameter, paste0(nm, ":"))],
      sub(paste0("^", nm, ":"), "", keyed)
    )
    unname(vals[levels_g][gi])
  }

  # Shape sub-parameters honour their OWN design. A scalar (1 column) or one-hot
  # grouping is resolved by the group lookup above (byte-identical to before); a
  # general (continuous) design is rebuilt from newdata and its link-scale
  # coefficients applied through the same forward map the engine uses.
  beta_of <- function(nm) {
    p <- fit$par
    unname(p[names(p) == nm])
  }
  X_low_fit  <- fit$tmb_inputs$data$X_low
  X_up_fit  <- fit$tmb_inputs$data$X_up
  X_logk_fit <- fit$tmb_inputs$data$X_logk
  # A shape needs the design-rebuild path when its design is not a scalar and not
  # the same one-hot grouping as CTmax/log_z (whose group lookup above handles it,
  # byte-identically). That covers continuous covariates and shapes grouped by a
  # factor other than the CTmax grouping. `shape_terms` is NULL for the column
  # interface, whose shapes are always intercept-only (scalar).
  needs_rebuild <- function(X_fit) {
    ncol(X_fit) > 1L && !identical(colnames(X_fit), levels_g)
  }
  rebuild_eta <- function(role, beta_name) {
    if (is.null(fit$shape_terms[[role]])) {
      cli::cli_abort("This fit has no stored design for {.code {role}}; predict needs the formula interface.")
    }
    Xn <- tls_design_from_rhs(fit$shape_terms[[role]], newdata, role)$X
    as.numeric(Xn %*% beta_of(beta_name))
  }

  # CTmax and log_z share a fixed design. The legacy grouped-factor path above
  # remains authoritative for cell means; a general design must instead be
  # rebuilt from newdata and multiplied by the fitted link-scale coefficients.
  # Literal tls_bf() calls retain the exact RHS. For fits made from a formula
  # object, direct numeric columns can still be reconstructed from the stored
  # design labels; transformed/interacted designs fail loudly rather than
  # silently returning an intercept-only prediction.
  fixed_rhs <- function(role) {
    stored <- fit$fixed_terms[[role]] %||% NULL
    if (!is.null(stored)) return(stored)
    x_call <- fit$call$x
    if (!is.call(x_call)) return(NULL)
    head <- x_call[[1L]]
    fun <- if (is.symbol(head)) as.character(head) else if (is.call(head)) {
      as.character(head[[length(head)]])
    } else ""
    if (!identical(fun, "tls_bf")) return(NULL)
    tf <- eval(x_call, envir = environment(predict.profile_tls))
    f <- tf$sub_formulas[[role]]
    if (is.null(f)) return(~1)
    rhs <- tls_formula_rhs(f)
    stats::as.formula(paste("~", deparse1(rhs)), env = tf$env)
  }
  rebuild_fixed_eta <- function(role, X_fit, beta_name) {
    rhs <- fixed_rhs(role)
    if (!is.null(rhs)) {
      Xn <- tls_design_from_rhs(rhs, newdata, role)$X
    } else {
      cols <- colnames(X_fit)
      direct <- setdiff(cols, "(Intercept)")
      missing_direct <- setdiff(direct, names(newdata))
      if (length(missing_direct) > 0L ||
          any(!vapply(newdata[direct], is.numeric, logical(1)))) {
        cli::cli_abort(c(
          "Cannot rebuild the fitted {.code {role}} design from {.arg newdata}.",
          i = "Refit with a literal {.fn tls_bf} call, or supply direct numeric design columns: {.val {direct}}."
        ))
      }
      Xn <- matrix(1, nrow = n_row, ncol = length(cols),
                   dimnames = list(NULL, cols))
      if (length(direct) > 0L) Xn[, direct] <- as.matrix(newdata[direct])
    }
    if (!identical(colnames(Xn), colnames(X_fit))) {
      cli::cli_abort(c(
        "The {.code {role}} design in {.arg newdata} does not match the fitted design.",
        x = "Fitted columns: {.val {colnames(X_fit)}}.",
        x = "Prediction columns: {.val {colnames(Xn)}}."
      ))
    }
    as.numeric(Xn %*% beta_of(beta_name))
  }

  CTmax <- if (general_fixed) {
    rebuild_fixed_eta("CTmax", X_CT_fit, "beta_CT")
  } else {
    resolve("CTmax")
  }
  log_z <- if (general_fixed) {
    rebuild_fixed_eta("log_z", X_logz_fit, "beta_logz")
  } else {
    log(resolve("z"))
  }

  bb <- fit$tmb_inputs$data
  low <- if (needs_rebuild(X_low_fit)) {
    bb$low_min + bb$low_w * stats::plogis(rebuild_eta("low", "beta_low"))
  } else {
    resolve("low")
  }
  k <- if (needs_rebuild(X_logk_fit)) {
    exp(rebuild_eta("log_k", "beta_logk"))
  } else {
    resolve("k")
  }
  up <- if (needs_rebuild(X_up_fit)) {
    bb$up_min + bb$up_w * stats::plogis(rebuild_eta("up", "beta_up"))
  } else {
    resolve("up")
  }

  # Conditional predictions add the fitted group-level modes on the same scale
  # used by the TMB objective. Population predictions leave all deviations at
  # zero. Unknown/new groups are not silently assigned a zero BLUP.
  if (identical(re.form, "conditional")) {
    sdr <- fit$sdreport
    if (is.null(sdr)) {
      cli::cli_abort("Conditional prediction needs an available {.code sdreport}; refit and check convergence.")
    }
    sm <- summary(sdr, select = "random")
    for (bk in tls_re_blocks(fit)) {
      gv <- bk$spec$group_var
      if (!gv %in% names(newdata)) {
        cli::cli_abort(c(
          "Conditional prediction needs grouping column {.code {gv}} in {.arg newdata}.",
          i = "Use {.code re.form = \"population\"} for a prediction with random intercepts set to zero."
        ))
      }
      g <- as.character(newdata[[gv]])
      if (anyNA(g)) {
        cli::cli_abort("{.code newdata${gv}} must not contain missing values for conditional prediction.")
      }
      unknown <- setdiff(unique(g), bk$spec$group_levels)
      if (length(unknown) > 0L) {
        cli::cli_abort(c(
          "Conditional prediction cannot use unseen {.code {gv}} level{?s}: {.val {unknown}}.",
          i = "Use {.code re.form = \"population\"} for new groups."
        ))
      }
      rows <- which(rownames(sm) == bk$b_name)
      b <- stats::setNames(unname(sm[rows, "Estimate"]), bk$spec$group_levels)
      bi <- unname(b[g])
      if (identical(bk$param, "CTmax")) CTmax <- CTmax + bi
      if (identical(bk$param, "log_z")) log_z <- log_z + bi
      if (identical(bk$param, "low")) {
        eta_low <- if (ncol(X_low_fit) == 1L) {
          rep(beta_of("beta_low")[1L], n_row)
        } else {
          rebuild_eta("low", "beta_low")
        }
        low <- bb$low_min + bb$low_w * stats::plogis(eta_low + bi)
      }
      if (identical(bk$param, "log_k")) {
        eta_logk <- if (ncol(X_logk_fit) == 1L) {
          rep(beta_of("beta_logk")[1L], n_row)
        } else {
          rebuild_eta("log_k", "beta_logk")
        }
        k <- exp(eta_logk + bi)
      }
    }
  }

  list(CTmax = CTmax, z = exp(log_z), low = low, up = up, k = k)
}

#' Predict a survival surface over a temperature-by-duration grid
#'
#' `predict_survival_surface()` evaluates the fitted survival probability on a
#' factorial grid of temperatures by durations, returning a long data frame
#' suitable for a heatmap or contour plot (see [plot_survival_surface()]).
#' For random-effects fits this helper returns population-level predictions
#' (random intercepts set to zero); use `predict(..., re.form = "conditional")`
#' for known-group conditional predictions. General continuous fixed designs
#' require `predict()` with their covariate columns supplied in `newdata`.
#'
#' @param object A `profile_tls` fit from [fit_tls()].
#' @param temps Numeric vector of temperatures. Defaults to a length-60
#'   sequence spanning the fit's observed temperature range.
#' @param times Numeric vector of durations (strictly positive). Defaults to a
#'   length-60 log-spaced sequence spanning the fit's observed duration range.
#' @param group Optional single group level (grouped fits only). When `NULL`
#'   (default) the surface is built for every group level and the result
#'   carries a `group` column.
#'
#' @return A long `data.frame` with columns `temp`, `duration`, `survival`
#'   (and `group` when the fit is grouped).
#'
#' @examples
#' d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
#' fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
#'                family = "binomial", tref = 1)
#' head(predict_survival_surface(fit, temps = c(34, 36, 38), times = c(1, 2, 4)))
#'
#' @export
predict_survival_surface <- function(object, temps = NULL, times = NULL,
                                     group = NULL) {
  if (inherits(object, "freq_tls")) object <- object$fit
  if (!inherits(object, "profile_tls")) {
    cli::cli_abort("{.arg object} must be a {.cls profile_tls} fit from {.fn fit_tls}.")
  }
  ds <- object$data_summary
  if (is.null(temps)) {
    temps <- seq(ds$temp_range[1L], ds$temp_range[2L], length.out = 60L)
  }
  if (is.null(times)) {
    # Log-spaced over the observed duration range (durations are on a log axis).
    times <- 10^seq(log10(ds$time_range[1L]), log10(ds$time_range[2L]),
                    length.out = 60L)
  }
  if (!is.numeric(temps) || !is.numeric(times)) {
    cli::cli_abort("{.arg temps} and {.arg times} must be numeric.")
  }
  if (any(times <= 0)) {
    cli::cli_abort("{.arg times} must be strictly positive.")
  }

  levels_g <- object$group_levels
  grouped <- isTRUE(object$data_summary$grouped)

  if (!is.null(group)) {
    if (!grouped) {
      cli::cli_abort("{.arg group} is only meaningful for a grouped fit.")
    }
    group <- as.character(group)
    if (length(group) != 1L || !group %in% levels_g) {
      cli::cli_abort(c(
        "{.arg group} must be a single fitted group level.",
        i = "Fitted group levels: {.val {levels_g}}."
      ))
    }
    use_levels <- group
  } else {
    use_levels <- if (grouped) levels_g else NA_character_
  }

  build_one <- function(lev) {
    grid <- expand.grid(temp = temps, duration = times,
                        KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
    nd <- grid
    if (grouped) nd$group <- lev
    grid$survival <- predict(object, nd, type = "survival")
    if (grouped) grid$group <- lev
    grid
  }

  parts <- lapply(use_levels, build_one)
  out <- do.call(rbind, parts)
  rownames(out) <- NULL
  if (grouped) {
    out[, c("temp", "duration", "group", "survival")]
  } else {
    out[, c("temp", "duration", "survival")]
  }
}

#' Derive the lethal / survival-threshold duration at a temperature
#'
#' `derive_lt()` solves the fitted 4PL for the duration at which survival
#' crosses a target probability `p` at a given temperature (an "LT" / lethal-
#' time-style quantity, e.g. `p = 0.5` gives the median survival time). Because
#' the threshold is interpreted *relative to the asymptotes*, the default
#' `p = 0.5` returns the curve's midpoint duration, where
#' `log10(duration) = mid` exactly.
#'
#' @details
#' Survival follows
#' `p = low + (up - low) * plogis(-k (log10(duration) - mid))`, so the duration
#' at which survival equals a target `p` solves
#' \deqn{\log_{10}(duration) = mid - \mathrm{qlogis}\!\left(\frac{p - low}{up - low}\right) / k.}
#' The target must lie strictly between `low` and `up` for a finite crossing;
#' otherwise the survival curve never reaches `p` and `derive_lt()` aborts with
#' an explanatory message (confidence-language, never silent).
#' For a random-effects fit this is a population-level derived quantity; it does
#' not add a group BLUP.
#'
#' @param object A `profile_tls` fit from [fit_tls()].
#' @param p Target survival probability in `(low, up)` (default `0.5`).
#' @param temp Numeric temperature(s) at which to solve.
#' @param group Optional single group level (grouped fits only). Required when
#'   the fit is grouped.
#'
#' @return A numeric vector of durations (same length as `temp`) on the data's
#'   native time unit.
#'
#' @examples
#' d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
#' fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
#'                family = "binomial", tref = 1)
#' # Median survival duration at 36 C:
#' derive_lt(fit, p = 0.5, temp = 36)
#'
#' @export
derive_lt <- function(object, p = 0.5, temp, group = NULL) {
  if (inherits(object, "freq_tls")) object <- object$fit
  if (!inherits(object, "profile_tls")) {
    cli::cli_abort("{.arg object} must be a {.cls profile_tls} fit from {.fn fit_tls}.")
  }
  if (!is.numeric(p) || length(p) != 1L || p <= 0 || p >= 1) {
    cli::cli_abort("{.arg p} must be a single number in (0, 1).")
  }
  if (missing(temp) || !is.numeric(temp) || length(temp) == 0L) {
    cli::cli_abort("{.arg temp} must be a non-empty numeric vector.")
  }
  if (anyNA(temp)) {
    cli::cli_abort("{.arg temp} must not contain missing values.")
  }

  # Resolve per-row CTmax/z and the group's shape via the same resolver predict()
  # uses (for a grouped-shape fit low/up/k are the group's values).
  nd <- data.frame(temp = temp)
  if (!is.null(group)) {
    group <- as.character(group)
    if (length(group) != 1L) {
      cli::cli_abort("{.arg group} must be a single group level.")
    }
    nd$group <- group
  }
  pars <- tls_predict_pars(object, nd)
  low <- pars$low[1L]; up <- pars$up[1L]; k <- pars$k[1L]
  if (!(p > low && p < up)) {
    cli::cli_abort(c(
      "Target survival {.val {p}} is not between the fitted asymptotes.",
      i = "Survival ranges in ({round(low, 3)}, {round(up, 3)}); the curve never crosses {.val {p}}.",
      i = "Pick a {.arg p} strictly inside that range."
    ))
  }

  log10_tref <- log10(object$tref)
  mid <- log10_tref - (temp - pars$CTmax) / pars$z
  # plogis(-k (logd - mid)) = (p - low)/(up - low)
  #   => logd = mid - qlogis((p - low)/(up - low)) / k
  frac <- (p - low) / (up - low)
  log_dur <- mid - stats::qlogis(frac) / k
  10^log_dur
}

#' Derive the temperature giving a target survival at a fixed exposure
#'
#' `derive_ctmax()` inverts the fitted 4PL for **temperature**: it returns the
#' assay temperature at which survival equals a target `surv` after exposure
#' `duration`. By default `surv` is the *relative* midpoint threshold
#' `(low + up) / 2` and `duration` is `tref`, so `derive_ctmax(fit)` reproduces
#' the fitted `CTmax`. Supplying an **absolute** `surv` gives the absolute-
#' threshold critical temperature (the analogue of the `bayesTLS`
#' `extract_tdt()` absolute mode), with the asymmetry correction
#' `qlogis((surv - low) / (up - low)) / k` built in.
#'
#' @details
#' Solving `surv = low + (up - low) * plogis(-k (log10(duration) - mid))` with
#' `mid = log10(tref) - (temp - CTmax) / z` for the temperature gives
#' \deqn{temp = CTmax - z\Big(\log_{10} duration - \log_{10} t_{ref} +
#'   \mathrm{qlogis}\!\big(\tfrac{surv - low}{up - low}\big) / k\Big).}
#' The target `surv` must lie strictly between `low` and `up`.
#' For a random-effects fit this is a population-level derived quantity; it does
#' not add a group BLUP.
#'
#' @param object A `profile_tls` fit from [fit_tls()].
#' @param surv Target survival probability in `(low, up)`. `NULL` (default) uses
#'   the relative midpoint `(low + up) / 2`, reproducing `CTmax` at `tref`.
#' @param duration Exposure duration(s) (native time unit; strictly positive).
#'   Defaults to the fit's `tref`.
#' @param group Optional single group level (grouped fits only).
#' @return A numeric vector of temperatures (degrees C), one per `duration`.
#' @examples
#' d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
#' fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
#'                family = "binomial", tref = 1)
#' derive_ctmax(fit)                                  # ~ CTmax (relative, at tref)
#' derive_ctmax(fit, surv = 0.5, duration = c(1, 4))  # absolute 50% survival
#' @export
derive_ctmax <- function(object, surv = NULL, duration = NULL, group = NULL) {
  if (inherits(object, "freq_tls")) object <- object$fit
  if (!inherits(object, "profile_tls")) {
    cli::cli_abort("{.arg object} must be a {.cls profile_tls} fit from {.fn fit_tls}.")
  }
  if (is.null(duration)) duration <- object$tref
  if (!is.numeric(duration) || length(duration) == 0L) {
    cli::cli_abort("{.arg duration} must be a non-empty numeric vector.")
  }
  if (anyNA(duration) || any(duration <= 0)) {
    cli::cli_abort("{.arg duration} must be strictly positive (it is log10-transformed).")
  }

  # Resolve per-row CTmax/z and the group's shape via the same resolver
  # predict()/derive_lt() use.
  nd <- data.frame(temp = rep(NA_real_, length(duration)))
  if (!is.null(group)) {
    group <- as.character(group)
    if (length(group) != 1L) cli::cli_abort("{.arg group} must be a single group level.")
    nd$group <- group
  }
  pars <- tls_predict_pars(object, nd)
  low <- pars$low[1L]; up <- pars$up[1L]; k <- pars$k[1L]

  if (is.null(surv)) surv <- (low + up) / 2
  if (!is.numeric(surv) || length(surv) != 1L) {
    cli::cli_abort("{.arg surv} must be a single number (or {.code NULL}).")
  }
  if (!(surv > low && surv < up)) {
    cli::cli_abort(c(
      "Target survival {.val {surv}} is not between the fitted asymptotes.",
      i = "Survival ranges in ({round(low, 3)}, {round(up, 3)}); pick a {.arg surv} strictly inside that range."
    ))
  }

  log10_tref <- log10(object$tref)
  q <- (surv - low) / (up - low)
  pars$CTmax - pars$z * (log10(duration) - log10_tref + stats::qlogis(q) / k)
}

#' Derive the critical temperature at a damage-rate floor (T_crit)
#'
#' `derive_tcrit()` returns the rate-multiplier critical temperature `T_crit`: the
#' temperature at which the thermal-damage rate falls to a chosen low floor
#' `rate`. It is the maximum-likelihood analogue of the `bayesTLS`
#' `extract_tdt()` absolute-family `T_crit`, and follows directly from the fitted
#' `CTmax` and `z`:
#' \deqn{T_{crit} = CTmax + z \, \log_{10}(rate / 100).}
#' Because `rate < 100` makes `log10(rate / 100) < 0` and `z > 0`, `T_crit` sits
#' below `CTmax`: it is the lower thermal threshold at which damage becomes
#' negligible (the temperature cutoff a heat-injury accumulation model treats as
#' "no damage").
#'
#' @details
#' `rate` is a damage-rate floor expressed as a **percentage of the lethal dose
#' per hour**; `bayesTLS` brackets observed breakpoints with a default range of
#' `0.1`--`1` %/hour. Unlike the Bayesian path, which samples `rate` to fold an
#' operational choice into the posterior, freqTLS treats `rate` as a fixed
#' input and returns the deterministic transform of the fitted `CTmax` and `z`
#' (combine their confidence intervals if you need to propagate uncertainty).
#' For a random-effects fit this is a population-level derived quantity; it does
#' not add a group BLUP.
#'
#' `T_crit` assumes a **lethal endpoint**: it is a damage-accumulation concept, so
#' for sublethal endpoints (knockdown, photosynthetic failure) the steeper `z`
#' drives it implausibly low. `derive_tcrit()` says so, once per call.
#'
#' @param object A `profile_tls` fit from [fit_tls()].
#' @param rate Damage-rate floor(s), a percentage of the lethal dose per hour
#'   (strictly positive). A scalar or a vector; default `1`.
#' @param group Optional single group level (grouped fits only; required when the
#'   fit is grouped).
#' @return A numeric vector of critical temperatures (degrees C), one per `rate`.
#' @seealso [derive_ctmax()] for the absolute-threshold critical temperature.
#' @examples
#' d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
#' fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
#'                family = "binomial", tref = 1)
#' derive_tcrit(fit, rate = c(0.1, 1)) # lower thermal thresholds
#' @export
derive_tcrit <- function(object, rate = 1, group = NULL) {
  if (inherits(object, "freq_tls")) object <- object$fit
  if (!inherits(object, "profile_tls")) {
    cli::cli_abort("{.arg object} must be a {.cls profile_tls} fit from {.fn fit_tls}.")
  }
  if (!is.numeric(rate) || length(rate) == 0L || anyNA(rate) || any(rate <= 0)) {
    cli::cli_abort(c(
      "{.arg rate} must be a non-empty vector of strictly positive damage-rate floors.",
      i = "It is a percentage of the lethal dose per hour (the {.code bayesTLS} default range is 0.1-1)."
    ))
  }

  # Resolve CTmax and z for the requested group via the same resolver predict()
  # and derive_ctmax() use; one row is enough since T_crit varies only with rate.
  nd <- data.frame(temp = NA_real_)
  if (!is.null(group)) {
    group <- as.character(group)
    if (length(group) != 1L) cli::cli_abort("{.arg group} must be a single group level.")
    nd$group <- group
  }
  pars <- tls_predict_pars(object, nd)
  ctmax <- pars$CTmax[1L]
  z <- pars$z[1L]

  cli::cli_inform(
    "{.code T_crit} assumes a lethal endpoint; for sublethal data its steeper {.code z} makes it implausibly low."
  )
  ctmax + z * log10(rate / 100)
}
