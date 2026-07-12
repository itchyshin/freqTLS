#' Build a freqTLS formula object (brms/drmTMB-style)
#'
#' `tls_bf()` captures the per-sub-parameter formulas that define a `freqTLS`
#' model and returns them, unevaluated, as a `tls_formula` object. It is the
#' formula complement to the column interface of [fit_tls()]: instead of passing
#' bare column names, you write one response formula plus a formula per model
#' sub-parameter.
#'
#' The **first** argument must be the unnamed response-and-axes formula. Its
#' left-hand side names the survival counts, in either the brms idiom
#' `successes | trials(total)` or the `glm` idiom `cbind(successes, failures)`.
#' Its right-hand side names the two thermal-load-sensitivity axes with the
#' tagged markers `time(<duration>)` and `temp(<temperature>)` (order does not
#' matter).
#'
#' The remaining arguments are sub-parameter formulas keyed by their left-hand
#' side, one of `low`, `up`, `log_k`, `CTmax`, or `log_z`. Any sub-parameter you
#' omit defaults to `~ 1`. Each of `low`, `up`, and `log_k` may carry its
#' **own** design independently — a grouping factor (`low ~ group`), a
#' continuous covariate (`log_k ~ body_size`), or an intercept — and need not
#' share one factor or match the headline-parameter grouping. `CTmax` and `log_z`
#' accept fixed-effect formulas but must produce the same model-matrix columns
#' (for example, use `CTmax ~ group, log_z ~ group`); their supported random-
#' intercept groupings may differ. A single random intercept,
#' `<param> ~ <fixed> + (1 | group)`, is accepted on `CTmax`, `log_z`, `low`, and
#' `log_k` (one grouping factor each, intercept only) -- but not on the upper
#' asymptote `up`, for which the compiled objective has no random-intercept term. Putting the same
#' grouping factor on two or more of them fits independent variances (no
#' correlation term) and warns.
#'
#' @section Parser provenance:
#' The shape of the parser (variadic capture via [substitute()], a per-entry
#' formula walk, and random-bar detection) is adapted from drmTMB's
#' `drm_formula()` / `parse_drm_formula_entry()` (GPL-3); see `inst/COPYRIGHTS`.
#' freqTLS writes its own grammar (the `time()` / `temp()` axis markers, the
#' five fixed sub-parameter handles, and the package's supported random-effect
#' grammar).
#'
#' @param ... The response-and-axes formula first (unnamed, with a left-hand
#'   side), then sub-parameter formulas keyed by their left-hand side. See the
#'   grammar above.
#'
#' @return A `tls_formula` object: a list with the captured response formula,
#'   the named sub-parameter formulas, and the calling environment.
#'
#' @seealso [fit_tls()], which accepts either a `tls_formula` or the column
#'   interface.
#'
#' @examples
#' tls_bf(
#'   survived | trials(total) ~ time(duration) + temp(temp),
#'   CTmax ~ life_stage,
#'   log_z ~ life_stage
#' )
#' # cbind() response idiom, ungrouped:
#' tls_bf(cbind(survived, died) ~ time(duration) + temp(temp))
#'
#' @export
tls_bf <- function(...) {
  env <- parent.frame()
  calls <- as.list(substitute(list(...)))[-1L]
  if (length(calls) == 0L) {
    cli::cli_abort("{.fn tls_bf} requires at least the response-and-axes formula.")
  }

  nms <- names(calls)
  if (is.null(nms)) nms <- rep("", length(calls))
  nms[is.na(nms)] <- ""

  # Every argument must be a formula call.
  is_formula <- vapply(calls, tls_is_formula_call, logical(1))
  if (!all(is_formula)) {
    bad <- which(!is_formula)[1L]
    cli::cli_abort(c(
      "{.fn tls_bf} inputs must be formulas.",
      x = "Input {bad} ({.code {deparse1(calls[[bad]])}}) is not a formula."
    ))
  }

  # The first formula is the response-and-axes formula (must have an LHS).
  response_formula <- calls[[1L]]
  if (is.null(tls_formula_lhs(response_formula))) {
    cli::cli_abort(c(
      "The first {.fn tls_bf} formula must be the response-and-axes formula.",
      i = "Write it as {.code successes | trials(total) ~ time(<dur>) + temp(<temp>)} or {.code cbind(successes, failures) ~ time(<dur>) + temp(<temp>)}."
    ))
  }

  # Remaining formulas are sub-parameter formulas keyed by LHS name.
  sub_formulas <- list()
  if (length(calls) > 1L) {
    for (i in seq.int(2L, length(calls))) {
      f <- calls[[i]]
      lhs <- tls_formula_lhs(f)
      if (is.null(lhs)) {
        cli::cli_abort(c(
          "Sub-parameter formulas must name a sub-parameter on the left-hand side.",
          x = "Input {i} ({.code {deparse1(f)}}) has no left-hand side.",
          i = "Use one of {.val {tls_subparam_names()}}, e.g. {.code CTmax ~ group}."
        ))
      }
      handle <- deparse1(lhs)
      if (!handle %in% tls_subparam_names()) {
        cli::cli_abort(c(
          "Unknown sub-parameter handle {.val {handle}}.",
          i = "Valid sub-parameters are {.val {tls_subparam_names()}}."
        ))
      }
      if (!is.null(sub_formulas[[handle]])) {
        cli::cli_abort("Sub-parameter {.val {handle}} is given more than once.")
      }
      sub_formulas[[handle]] <- f
    }
  }

  out <- list(
    response = response_formula,
    sub_formulas = sub_formulas,
    env = env
  )
  class(out) <- "tls_formula"
  out
}

#' The set of valid sub-parameter handles
#' @keywords internal
#' @noRd
tls_subparam_names <- function() {
  c("low", "up", "log_k", "CTmax", "log_z")
}

#' @export
print.tls_formula <- function(x, ...) {
  cli::cli_text("<tls_formula>")
  cli::cli_text("  {deparse1(x$response)}")
  for (handle in names(x$sub_formulas)) {
    cli::cli_text("  {deparse1(x$sub_formulas[[handle]])}")
  }
  invisible(x)
}

# ---- formula primitives -----------------------------------------------------
# These mirror the small formula-walking helpers in drmTMB's parse-formula.R
# (GPL-3; see inst/COPYRIGHTS).

#' Is `expr` a formula call (`~`)?
#' @keywords internal
#' @noRd
tls_is_formula_call <- function(expr) {
  is.call(expr) && identical(expr[[1L]], as.name("~"))
}

#' Left-hand side of a formula call, or `NULL` for a one-sided formula.
#' @keywords internal
#' @noRd
tls_formula_lhs <- function(expr) {
  if (length(expr) < 3L) return(NULL)
  expr[[2L]]
}

#' Right-hand side of a formula call.
#' @keywords internal
#' @noRd
tls_formula_rhs <- function(expr) {
  expr[[length(expr)]]
}

#' Does `expr` contain a random-effect bar (`a | b`) as a call?
#'
#' Detects the `lme4`/`brms` random-effect grouping operator. A bare `successes
#' | trials(total)` response is handled separately (we only call this on
#' sub-parameter right-hand sides), so any `|` here is a random effect.
#' @keywords internal
#' @noRd
tls_contains_random_bar <- function(expr) {
  if (is.call(expr)) {
    if (identical(expr[[1L]], as.name("|"))) return(TRUE)
    return(any(vapply(as.list(expr)[-1L], tls_contains_random_bar, logical(1))))
  }
  FALSE
}

#' Is `term` a top-level random-effects term, i.e. `(a | b)` or `a | b`?
#' @keywords internal
#' @noRd
tls_is_re_bar <- function(term) {
  if (is.call(term) && identical(term[[1L]], as.name("("))) {
    inner <- term[[2L]]
    return(is.call(inner) && identical(inner[[1L]], as.name("|")))
  }
  is.call(term) && identical(term[[1L]], as.name("|"))
}

#' The `a | b` call inside a (possibly parenthesised) random-effects term.
#' @keywords internal
#' @noRd
tls_re_bar_inner <- function(term) {
  if (identical(term[[1L]], as.name("("))) term[[2L]] else term
}

#' Split a sub-parameter right-hand side into its fixed part and a random intercept
#'
#' freqTLS supports a single random intercept on `CTmax`, `log_z`, `low`, and
#' `log_k`, `<param> ~ <fixed> + (1 | group)`. This separates the `(1 | group)` term from
#' the fixed terms, validates the scope (one grouping factor, intercept only, the
#' column exists), and returns the fixed-effect right-hand side plus an `re` spec
#' (or `NULL`). `param` is the sub-parameter name (`"CTmax"`, `"log_z"`, `"low"`,
#' or `"log_k"`), used in the messages and to name the affected variance component.
#' @keywords internal
#' @noRd
tls_extract_re <- function(rhs_expr, data, param = "CTmax", quiet = FALSE) {
  sig_label <- switch(param, log_z = "sigma_logz", low = "sigma_low",
                      log_k = "sigma_logk", "sigma_CTmax")
  terms <- tls_flatten_plus(rhs_expr)
  is_bar <- vapply(terms, tls_is_re_bar, logical(1))

  re <- NULL
  if (any(is_bar)) {
    bars <- terms[is_bar]
    if (length(bars) > 1L) {
      cli::cli_abort(c(
        "Only one random-effects term is supported on {.code {param}} (a single {.code (1 | group)}).",
        i = "Crossed or multiple grouping factors on one sub-parameter are not supported."
      ))
    }
    inner <- tls_re_bar_inner(bars[[1L]])
    re_lhs <- inner[[2L]]
    re_group <- inner[[3L]]
    if (!identical(deparse1(re_lhs), "1")) {
      cli::cli_abort(c(
        "Only a random intercept {.code (1 | group)} is supported on {.code {param}}.",
        x = "Got {.code ({deparse1(re_lhs)} | {deparse1(re_group)})}; random slopes are not supported."
      ))
    }
    if (!is.name(re_group)) {
      cli::cli_abort(c(
        "The random-effects grouping must be a single column, e.g. {.code (1 | colony)}.",
        x = "Got {.code {deparse1(re_group)}}; nested / interaction groupings are not supported."
      ))
    }
    gname <- deparse1(re_group)
    if (!gname %in% names(data)) {
      cli::cli_abort("The random-effects grouping column {.code {gname}} is not in {.arg data}.")
    }
    g <- factor(data[[gname]])
    if (anyNA(g)) {
      cli::cli_abort("The random-effects grouping column {.code {gname}} must not contain missing values.")
    }
    if (!isTRUE(quiet) && nlevels(g) < 8L) {
      cli::cli_warn(c(
        "The random-effects grouping {.code {gname}} has only {nlevels(g)} level{?s}.",
        i = "With fewer than ~8 groups a variance component is weakly identified and biased low; treat {.code {sig_label}} cautiously.",
        i = "For the fixed-effect intervals, prefer {.code confint(method = \"bootstrap\")} (or {.pkg bayesTLS}); a Wald or profile interval can under-cover with this few groups."
      ))
    }
    re <- list(index = as.integer(g) - 1L, n = nlevels(g),
               group_levels = levels(g), group_var = gname)
  }

  fixed_terms <- terms[!is_bar]
  fixed_rhs <- if (length(fixed_terms) == 0L) {
    ~1
  } else {
    stats::reformulate(vapply(fixed_terms, deparse1, character(1)))
  }
  list(fixed_rhs = fixed_rhs, re = re)
}

# ---- the parser -------------------------------------------------------------

#' Parse a `tls_formula` against a data frame into a fit specification
#'
#' Resolves the response counts, the time / temperature axes, and the `CTmax` /
#' `log_z` design matrices from a [tls_bf()] object. The returned spec carries
#' exactly what [fit_tls()] needs to run the existing engine: the count vectors,
#' the axis vectors, the (shared) design matrix and its column labels, and a
#' `grouped` flag.
#'
#' Restrictions enforced here:
#' * each sub-parameter takes its own fixed-effect design (intercept, grouping
#'   factor, or continuous covariate).
#' * random-effect bars (`(1 | group)`) are parsed on `CTmax`, `log_z`, `low`, and
#'   `log_k` (upstream, by `tls_extract_re()`), one grouping factor each; a bar on
#'   the upper asymptote `up` is rejected (no random-intercept term in the objective).
#' * the `CTmax` and `log_z` FIXED designs must produce the same columns (the
#'   engine accepts independent lengths, but the downstream profile / contrast /
#'   print machinery is keyed on one shared label set); their RE groupings may
#'   differ.
#'
#' @param formula A `tls_formula` from [tls_bf()].
#' @param data A data frame to resolve columns against.
#' @return A list with `y`, `n`, `time`, `temp` (numeric vectors), `X_CT`,
#'   `X_logz` (numeric matrices), `levels` (design column labels), and `grouped`.
#' @keywords internal
#' @noRd
tls_parse_formula <- function(formula, data, quiet = FALSE) {
  if (!inherits(formula, "tls_formula")) {
    cli::cli_abort("{.arg formula} must be a {.cls tls_formula} from {.fn tls_bf}.")
  }
  if (!is.data.frame(data)) {
    cli::cli_abort("{.arg data} must be a data frame when using {.fn tls_bf}.")
  }

  # ---- response counts -----------------------------------------------------
  counts <- tls_parse_response(formula$response, data)

  # ---- axes ----------------------------------------------------------------
  axes <- tls_parse_axes(formula$response, data)

  # ---- CTmax / log_z design matrices ---------------------------------------
  ct_f <- formula$sub_formulas[["CTmax"]]
  lz_f <- formula$sub_formulas[["log_z"]]

  # CTmax and log_z may each carry a single random intercept `(1 | group)`. The
  # bar is stripped here, so the shared-design comparison below sees only the
  # fixed parts.
  ct_rhs_expr <- if (is.null(ct_f)) quote(1) else tls_formula_rhs(ct_f)
  lz_rhs_expr <- if (is.null(lz_f)) quote(1) else tls_formula_rhs(lz_f)
  ct_re <- tls_extract_re(ct_rhs_expr, data, "CTmax", quiet = quiet)
  lz_re <- tls_extract_re(lz_rhs_expr, data, "log_z", quiet = quiet)

  # (The same-grouping independent-variance warning is emitted once below, after
  # all four possible RE blocks -- CTmax, log_z, low, log_k -- have been parsed.)

  ct_design <- tls_design_from_rhs(ct_re$fixed_rhs, data, "CTmax")
  lz_design <- tls_design_from_rhs(lz_re$fixed_rhs, data, "log_z")

  # CTmax and log_z share one fixed-effect label set downstream. The engine
  # accepts different lengths, but the profile / contrast / print machinery does
  # not. Only the FIXED parts must match here; the random-effect bars were stripped
  # above, so the two RE groupings may differ.
  if (!identical(colnames(ct_design$X), colnames(lz_design$X))) {
    cli::cli_abort(c(
      "{.code CTmax} and {.code log_z} must use the same fixed-effect predictors.",
      x = "{.code CTmax} columns: {.val {colnames(ct_design$X)}}.",
      x = "{.code log_z} columns: {.val {colnames(lz_design$X)}}.",
      i = "Give them the same right-hand side; their random-effect groupings may still differ."
    ))
  }

  # ---- shape sub-parameter designs (low, up via disjoint bounds, log_k) -----
  # Intercept-only by default; each may be grouped or carry a continuous covariate
  # and `low` and `log_k` may also carry a single random intercept `(1 | group)`
  # (the RE bar is stripped here and the fixed design built from the
  # fixed part). Under disjoint bounds `up` has its own coordinate `beta_up`, but
  # the compiled objective has no random-intercept term for it, so a RE bar on `up`
  # is rejected by tls_design_from_rhs (as `up` is for profiling).
  shape_rhs_expr <- function(handle) {
    f <- formula$sub_formulas[[handle]]
    if (is.null(f)) quote(1) else tls_formula_rhs(f)
  }
  low_re <- tls_extract_re(shape_rhs_expr("low"), data, "low", quiet = quiet)
  logk_re <- tls_extract_re(shape_rhs_expr("log_k"), data, "log_k", quiet = quiet)
  low_rhs <- low_re$fixed_rhs
  logk_rhs <- logk_re$fixed_rhs
  up_expr <- shape_rhs_expr("up")
  up_rhs <- if (identical(up_expr, quote(1))) ~1 else stats::reformulate(deparse1(up_expr))
  low_design <- tls_design_from_rhs(low_rhs, data, "low")
  gap_design <- tls_design_from_rhs(up_rhs, data, "up")
  logk_design <- tls_design_from_rhs(logk_rhs, data, "log_k")
  # Each shape sub-parameter carries its own design INDEPENDENTLY (intercept,
  # grouping factor, or continuous covariate); `low` and `log_k` may additionally
  # carry a random intercept. predict() rebuilds each shape design from `newdata`
  # via `shape_terms` (the fixed part); no same-predictor / match-CTmax constraint.

  # Independent REs only: when two or more random intercepts share a grouping
  # factor, freqTLS fits them as INDEPENDENT variances (no correlation term).
  # The group-level deviations are usually correlated, and that correlation is then
  # absorbed into the marginal SDs and the fixed-effect intervals -- an honest
  # hazard, so warn (once per shared grouping).
  re_present <- Filter(Negate(is.null),
    list(CTmax = ct_re$re, log_z = lz_re$re, low = low_re$re, log_k = logk_re$re))
  if (!isTRUE(quiet) && length(re_present) >= 2L) {
    gvars <- vapply(re_present, function(s) s$group_var, character(1))
    for (gv in unique(gvars[duplicated(gvars)])) {
      shared <- names(re_present)[gvars == gv]
      cli::cli_warn(c(
        "Random intercepts on {.val {shared}} share the grouping {.code {gv}}.",
        i = "freqTLS fits these as {.strong independent} variances (no correlation term); any true correlation between the group-level deviations is absorbed into the marginal SDs and the fixed-effect intervals.",
        i = "For a correlated random effect, use {.pkg bayesTLS}."
      ))
    }
  }

  list(
    y = counts$y,
    n = counts$n,
    time = axes$time,
    temp = axes$temp,
    X_CT = ct_design$X,
    X_logz = lz_design$X,
    X_low = low_design$X,
    X_up = gap_design$X,
    X_logk = logk_design$X,
    levels = colnames(ct_design$X),
    grouped = ct_design$grouped,
    # `[[` (exact) not `$`: an ungrouped design has `grouped` but no `group` key,
    # and `$` would partial-match `group` to `grouped` (FALSE).
    group = ct_design[["group"]],
    # Per-shape right-hand sides, so predict() can rebuild the shape designs from
    # newdata (NULL-safe: an intercept-only shape rebuilds to a column of ones).
    shape_terms = list(low = low_rhs, up = up_rhs, log_k = logk_rhs),
    re = ct_re$re,
    re_logz = lz_re$re,
    re_low = low_re$re,
    re_logk = logk_re$re
  )
}

#' Resolve the response left-hand side into successes / trials vectors
#'
#' Accepts `successes | trials(total)` (brms idiom: successes + trials columns)
#' or `cbind(successes, failures)` (glm idiom: total = successes + failures).
#' @keywords internal
#' @noRd
tls_parse_response <- function(response_formula, data) {
  lhs <- tls_formula_lhs(response_formula)

  eval_col <- function(expr, role) {
    v <- tryCatch(
      eval(expr, envir = data, enclos = parent.frame()),
      error = function(e) {
        cli::cli_abort(c(
          "Could not find the {role} column {.code {deparse1(expr)}} in {.arg data}.",
          x = conditionMessage(e)
        ))
      }
    )
    if (!is.numeric(v)) {
      cli::cli_abort("The {role} column {.code {deparse1(expr)}} must be numeric.")
    }
    v
  }

  # brms idiom: successes | trials(total)
  if (is.call(lhs) && identical(lhs[[1L]], as.name("|"))) {
    successes_expr <- lhs[[2L]]
    rhs_marker <- lhs[[3L]]
    if (!is.call(rhs_marker) || !identical(rhs_marker[[1L]], as.name("trials"))) {
      cli::cli_abort(c(
        "The response after {.code |} must be {.fn trials}.",
        i = "Write the response as {.code successes | trials(total)}."
      ))
    }
    if (length(rhs_marker) != 2L) {
      cli::cli_abort("{.fn trials} takes exactly one column, e.g. {.code trials(total)}.")
    }
    y <- eval_col(successes_expr, "successes")
    n <- eval_col(rhs_marker[[2L]], "trials")
    return(list(y = as.numeric(y), n = as.numeric(n)))
  }

  # glm idiom: cbind(successes, failures)
  if (is.call(lhs) && identical(lhs[[1L]], as.name("cbind"))) {
    if (length(lhs) != 3L) {
      cli::cli_abort(c(
        "{.fn cbind} response needs exactly two columns.",
        i = "Write it as {.code cbind(successes, failures)}."
      ))
    }
    y <- eval_col(lhs[[2L]], "successes")
    failures <- eval_col(lhs[[3L]], "failures")
    if (length(y) != length(failures)) {
      cli::cli_abort("The two {.fn cbind} columns must have equal length.")
    }
    return(list(y = as.numeric(y), n = as.numeric(y) + as.numeric(failures)))
  }

  # Bare-name response: a continuous proportion in (0, 1) for the beta family.
  # There is no trials column; fit_tls() supplies a dummy `n` and validates the
  # (0, 1) range. A bare name combined with a count family then triggers the
  # clear "`n` (trials) is required" error downstream.
  if (is.name(lhs)) {
    y <- eval_col(lhs, "response")
    return(list(y = as.numeric(y), n = NULL))
  }

  cli::cli_abort(c(
    "Unrecognised response specification {.code {deparse1(lhs)}}.",
    i = "Use {.code successes | trials(total)}, {.code cbind(successes, failures)}, or a bare proportion column for {.code family = \"beta\"}."
  ))
}

#' Resolve the time() and temp() axis markers into numeric vectors
#' @keywords internal
#' @noRd
tls_parse_axes <- function(response_formula, data) {
  rhs <- tls_formula_rhs(response_formula)
  terms <- tls_flatten_plus(rhs)

  time_expr <- NULL
  temp_expr <- NULL
  for (term in terms) {
    if (is.call(term) && identical(term[[1L]], as.name("time"))) {
      if (!is.null(time_expr)) cli::cli_abort("{.fn time} axis is given more than once.")
      if (length(term) != 2L) {
        cli::cli_abort("{.fn time} takes exactly one column, e.g. {.code time(duration)}.")
      }
      time_expr <- term[[2L]]
    } else if (is.call(term) && identical(term[[1L]], as.name("temp"))) {
      if (!is.null(temp_expr)) cli::cli_abort("{.fn temp} axis is given more than once.")
      if (length(term) != 2L) {
        cli::cli_abort("{.fn temp} takes exactly one column, e.g. {.code temp(temperature)}.")
      }
      temp_expr <- term[[2L]]
    } else {
      cli::cli_abort(c(
        "Untagged term {.code {deparse1(term)}} on the response right-hand side.",
        i = "Name the axes with the markers {.code time(<duration>)} and {.code temp(<temperature>)}."
      ))
    }
  }

  if (is.null(time_expr)) {
    cli::cli_abort(c(
      "The response formula is missing the {.fn time} axis.",
      i = "Add {.code time(<duration>)} to the right-hand side."
    ))
  }
  if (is.null(temp_expr)) {
    cli::cli_abort(c(
      "The response formula is missing the {.fn temp} axis.",
      i = "Add {.code temp(<temperature>)} to the right-hand side."
    ))
  }

  eval_axis <- function(expr, role) {
    v <- tryCatch(
      eval(expr, envir = data, enclos = parent.frame()),
      error = function(e) {
        cli::cli_abort(c(
          "Could not find the {role} column {.code {deparse1(expr)}} in {.arg data}.",
          x = conditionMessage(e)
        ))
      }
    )
    if (!is.numeric(v)) {
      cli::cli_abort("The {role} column {.code {deparse1(expr)}} must be numeric.")
    }
    as.numeric(v)
  }

  list(
    time = eval_axis(time_expr, "time"),
    temp = eval_axis(temp_expr, "temp")
  )
}

#' Flatten an additive (`+`) right-hand side into a list of terms
#' @keywords internal
#' @noRd
tls_flatten_plus <- function(expr) {
  if (is.call(expr) && identical(expr[[1L]], as.name("+"))) {
    return(c(tls_flatten_plus(expr[[2L]]), tls_flatten_plus(expr[[3L]])))
  }
  list(expr)
}

#' Build a CTmax / log_z design matrix from a sub-parameter right-hand side
#'
#' Mirrors the column-interface behaviour: the special case `~ group` for a
#' single factor emits `~ 0 + group` (so labels and the fit are byte-identical to
#' the column interface). Any other formula keeps the intercept and labels
#' columns by their model-matrix names.
#' @keywords internal
#' @noRd
tls_design_from_rhs <- function(rhs, data, role) {
  if (tls_contains_random_bar(tls_formula_rhs(rhs))) {
    cli::cli_abort(c(
      "Random effects are supported on {.code CTmax}, {.code log_z}, {.code low}, and {.code log_k} (a single {.code (1 | group)} each), not the upper-asymptote gap {.code up}.",
      i = "{.code up} has no random-intercept term in the compiled objective; put the random intercept on {.code low} / {.code log_k} / {.code CTmax} / {.code log_z}, or use {.code {role} ~ block} for grouped fixed effects."
    ))
  }

  rhs_terms <- attr(stats::terms(rhs), "term.labels")
  has_intercept <- attr(stats::terms(rhs), "intercept") == 1L

  # Intercept-only: a single "(Intercept)" column, ungrouped.
  if (length(rhs_terms) == 0L) {
    if (!has_intercept) {
      cli::cli_abort("A {.code {role}} formula must have at least an intercept or a predictor.")
    }
    X <- matrix(1, nrow = nrow(data), ncol = 1L,
                dimnames = list(NULL, "all"))
    return(list(X = X, grouped = FALSE))
  }

  # Special case a single factor term, with OR without an intercept -- `~ factor`
  # and the `by=` cell-means form `~ 0 + factor` both resolve to per-group
  # cell-means here, labelled by the bare factor levels so the design and labels
  # match the column interface exactly (clean `<level>`, not model.matrix's
  # `<factorname><level>`). Continuous `~ 0 + x` terms are excluded by the
  # factor/character test and fall through to the general path below.
  single_factor <- length(rhs_terms) == 1L &&
    rhs_terms[[1L]] %in% names(data) &&
    (is.factor(data[[rhs_terms[[1L]]]]) || is.character(data[[rhs_terms[[1L]]]]))

  if (single_factor) {
    g <- factor(data[[rhs_terms[[1L]]]])
    if (any(is.na(g))) {
      cli::cli_abort("The {.code {role}} grouping column must not contain missing values.")
    }
    X <- stats::model.matrix(
      stats::reformulate(rhs_terms[[1L]], intercept = FALSE),
      data = data
    )
    colnames(X) <- levels(g)
    attr(X, "assign") <- NULL
    attr(X, "contrasts") <- NULL
    # Surface the per-row labels so the formula interface can carry a grouping
    # vector for diagnostics / diag_data, matching the column interface.
    return(list(X = X, grouped = TRUE, group = as.character(g)))
  }

  # General fixed-effect formula: keep the intercept, label by model-matrix
  # column names. Coefficients are surfaced downstream as CTmax:<colname>.
  X <- stats::model.matrix(rhs, data = data)
  if (anyNA(X)) {
    cli::cli_abort("The {.code {role}} design matrix has missing values; check for {.code NA} predictors.")
  }
  attr(X, "assign") <- NULL
  attr(X, "contrasts") <- NULL
  list(X = X, grouped = ncol(X) > 1L)
}
