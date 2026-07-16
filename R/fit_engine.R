#' Fit the freqTLS TMB objective and extract its state
#'
#' Internal engine: assembles the TMB AD function, optimises it with
#' [stats::nlminb()] (falling back to [stats::optim()] with `method = "BFGS"`
#' if `nlminb` fails to converge), refines a nominal solution whose raw
#' gradient remains above `1e-3` with `nloptr`'s preconditioned truncated-Newton
#' method, runs [TMB::sdreport()] for standard errors,
#' and reports convergence with the positive-definite-Hessian flag. This is the
#' single place that talks to `MakeADFun`; [fit_tls()] assembles the data,
#' parameters, and map and hands them here.
#'
#' The structure mirrors the drmTMB fit pipeline
#' (`drmTMB::R/drmTMB.R:350-440`): `MakeADFun` -> optimiser -> `sdreport`
#' wrapped in `tryCatch`, with a convergence state object.
#'
#' @param tmb_data List of `DATA_*` inputs for `src/profile_tls.cpp`.
#' @param parameters List of starting `PARAMETER`/`PARAMETER_VECTOR` values.
#' @param map Named list of `factor()` maps fixing parameters (e.g. `log_phi`
#'   for the binomial family); may be empty.
#' @param control List with optional `optimizer` (passed to `nlminb`'s
#'   `control`) and `trace` (logical; printed optimiser progress).
#' @return A list with `obj` (the AD function), `opt` (the optimiser result),
#'   `sdreport` (an `sdreport` object or `NULL`), `par` (the named MLE on the
#'   internal scale), and `convergence` (a list with `code`, `pdHess`, and
#'   `message`).
#' @keywords internal
#' @noRd
fit_tls_engine <- function(tmb_data, parameters, map = list(), control = list(),
                           random = NULL) {
  silent <- !isTRUE(control$trace)

  obj <- TMB::MakeADFun(
    data = tmb_data,
    parameters = parameters,
    map = map,
    random = random,
    DLL = "freqTLS",
    silent = silent
  )

  opt <- tryCatch(
    stats::nlminb(
      start = obj$par,
      objective = obj$fn,
      gradient = obj$gr,
      control = control$optimizer %||% list()
    ),
    error = function(e) e
  )

  optimizer <- "nlminb"
  # Fall back to BFGS if nlminb errored or did not converge cleanly.
  nlminb_failed <- inherits(opt, "error") ||
    is.null(opt$convergence) || opt$convergence != 0
  if (nlminb_failed) {
    opt_bfgs <- tryCatch(
      stats::optim(
        par = obj$par,
        fn = obj$fn,
        gr = obj$gr,
        method = "BFGS",
        control = list(trace = if (isTRUE(control$trace)) 1L else 0L)
      ),
      error = function(e) e
    )
    if (!inherits(opt_bfgs, "error")) {
      # Normalise optim's result to the nlminb shape (objective / convergence).
      opt <- list(
        par = opt_bfgs$par,
        objective = opt_bfgs$value,
        convergence = opt_bfgs$convergence,
        iterations = opt_bfgs$counts[["function"]],
        message = opt_bfgs$message,
        optimizer = "optim_BFGS"
      )
      optimizer <- "optim_BFGS"
    } else if (inherits(opt, "error")) {
      # Both optimisers errored: surface the nlminb error.
      cli::cli_abort(c(
        "The optimiser failed to fit the model.",
        x = "nlminb error: {conditionMessage(opt)}",
        x = "optim(BFGS) error: {conditionMessage(opt_bfgs)}"
      ))
    }
  }

  # A large formula can satisfy nlminb's relative objective criterion while a
  # few contrast/slope coordinates still have a material raw gradient. Refine
  # only in that case. NLopt may report its generic line-search failure at a
  # stationary point; accept the refinement based on the package's explicit
  # objective/gradient contract, not that status code alone.
  grad_before <- tryCatch(max(abs(obj$gr(opt$par))), error = function(e) Inf)
  if (is.finite(grad_before) && grad_before >= 1e-3) {
    refined <- tryCatch(
      nloptr::nloptr(
        x0 = opt$par,
        eval_f = function(x) list(objective = obj$fn(x), gradient = obj$gr(x)),
        opts = list(
          algorithm = "NLOPT_LD_TNEWTON_PRECOND_RESTART",
          xtol_rel = 1e-12,
          ftol_rel = 1e-14,
          maxeval = 5000L,
          print_level = if (isTRUE(control$trace)) 1L else 0L
        )
      ),
      error = function(e) e
    )
    if (!inherits(refined, "error")) {
      grad_after <- tryCatch(max(abs(obj$gr(refined$solution))),
                             error = function(e) Inf)
      objective_before <- opt$objective %||% opt$value %||% obj$fn(opt$par)
      objective_after <- refined$objective
      objective_ok <- is.finite(objective_after) &&
        objective_after <= objective_before + 1e-7 * (1 + abs(objective_before))
      if (objective_ok && is.finite(grad_after) && grad_after < grad_before) {
        solution <- refined$solution
        names(solution) <- names(opt$par)
        opt <- list(
          par = solution,
          objective = objective_after,
          convergence = if (grad_after < 1e-3) 0L else refined$status,
          iterations = refined$iterations,
          message = paste0(
            "Refined stationary point accepted by the freqTLS objective/gradient ",
            "contract (NLopt status ", refined$status, "); max|gradient| = ",
            signif(grad_after, 4)
          ),
          optimizer = "nloptr_TNEWTON"
        )
        optimizer <- "nloptr_TNEWTON"
      }
    }
  }
  opt$optimizer <- optimizer

  # Pin the AD function to the optimum so REPORT()/last.par.best are consistent.
  obj$fn(opt$par)

  sdr <- tryCatch(
    TMB::sdreport(obj, par.fixed = opt$par),
    error = function(e) e
  )
  if (inherits(sdr, "error")) {
    sd_message <- paste("TMB::sdreport() failed:", conditionMessage(sdr))
    sdr <- NULL
    pdHess <- FALSE
  } else {
    sd_message <- "TMB::sdreport() completed."
    pdHess <- isTRUE(sdr$pdHess)
  }

  code <- opt$convergence %||% NA_integer_
  conv_message <- opt$message %||% NA_character_

  list(
    obj = obj,
    opt = opt,
    sdreport = sdr,
    par = opt$par,
    # Clean inputs retained for profiling (map-refit needs to rebuild the
    # objective with the original data/parameters, not the mutated obj$env).
    tmb_inputs = list(data = tmb_data, parameters = parameters, map = map,
                      random = random),
    convergence = list(
      code = code,
      pdHess = pdHess,
      optimizer = optimizer,
      message = conv_message,
      sdreport_message = sd_message
    )
  )
}
