## Parametric bootstrap confidence intervals for freqTLS fits.
##
## The profile likelihood is freqTLS's primary interval, but it can fail to
## close when a parameter is weakly identified, and the Wald/Hessian path is
## undefined when the fitted Hessian is not positive definite (`pdHess = FALSE`).
## A parametric bootstrap fills both gaps while staying prior-free: it regenerates
## survival counts at the OBSERVED design from the fitted 4PL, refits, and reads
## the sampling distribution of each estimator. It is the likelihood-path analogue
## of the bayesTLS posterior -- both summarise estimator uncertainty, but an
## unstable frequentist estimator can still leave an interval unavailable.
##
## The refit reuses the same machinery as the profile path: the clean TMB inputs
## retained in `fit$tmb_inputs`, warm-started at the fitted MLE for speed and
## robustness. No Stan, no recompilation of the model -- only the response vector
## `y` changes between replicates. Percentiles are taken on each parameter's
## construction scale (z/k/phi on log, low on logit, CTmax/up on identity) and
## back-transformed, so the bootstrap is exactly equivariant in the same way the
## profile is: the z interval equals exp() of the log_z interval.
## User-facing behaviour is documented in vignette("profile-likelihood").

#' Parametric bootstrap replicates of the natural-scale parameters
#'
#' Regenerates `y` at the observed design from the fitted survival probabilities
#' (`p_fitted` from the compiled model) under the fit's family, refits each
#' replicate via the retained TMB inputs (warm-started at the MLE), and collects
#' the natural-scale parameter estimates. Non-converged replicates are recorded
#' as `NA` and excluded downstream rather than silently dropped.
#'
#' @param fit A `profile_tls` fit from [fit_tls()].
#' @param nboot Number of bootstrap replicates (default `1000`).
#' @param seed Optional integer seed; when supplied the RNG state is set locally
#'   and restored on exit, so the bootstrap is reproducible without disturbing
#'   the caller's random stream.
#' @param cores Number of CPU cores for the refits (default `1`). With
#'   `cores > 1` the replicates are refitted in parallel via process forking
#'   (`parallel::mclapply`). The responses are pre-drawn sequentially under
#'   `seed`, so results are identical for a given seed regardless of `cores`.
#'   At most two cores are used, as required by CRAN. Requests above two emit a
#'   warning and are capped. Forking is unavailable on Windows, where this
#'   falls back to sequential.
#' @param trace Logical; print inner-optimisation progress.
#' @return A list with `replicates` (an `nboot`-by-parameter numeric matrix whose
#'   columns match `fit$estimates$parameter`), a logical `converged` vector,
#'   `n_converged`, `nboot`, and `param_names`.
#' @keywords internal
#' @noRd
tls_bootstrap_replicates <- function(fit, nboot = 1000L, seed = NULL,
                                     cores = 1L, trace = FALSE) {
  if (!inherits(fit, "profile_tls")) {
    cli::cli_abort("{.arg fit} must be a {.cls profile_tls} fit from {.fn fit_tls}.")
  }
  if (is.null(fit$obj) || is.null(fit$tmb_inputs)) {
    cli::cli_abort(c(
      "The parametric bootstrap needs the live TMB object and inputs retained in the fit.",
      i = "Refit with the current version of {.fn fit_tls}."
    ))
  }
  if (!is.numeric(nboot) || length(nboot) != 1L || nboot < 1) {
    cli::cli_abort("{.arg nboot} must be a single positive integer.")
  }
  nboot <- as.integer(nboot)
  if (!is.numeric(cores) || length(cores) != 1L || !is.finite(cores) || cores < 1) {
    cli::cli_abort("{.arg cores} must be a single positive integer.")
  }
  cores <- as.integer(cores)
  if (cores > 2L) {
    cli::cli_warn(c(
      "!" = "Bootstrap parallelism is limited to 2 cores for CRAN safety.",
      "i" = "Using {.code cores = 2} instead of the requested {cores}."
    ))
    cores <- 2L
  }

  if (!is.null(seed)) {
    if (!is.numeric(seed) || length(seed) != 1L) {
      cli::cli_abort("{.arg seed} must be a single number or {.code NULL}.")
    }
    if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
      old_seed <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
      on.exit(assign(".Random.seed", old_seed, envir = .GlobalEnv), add = TRUE)
    } else {
      on.exit(
        suppressWarnings(rm(".Random.seed", envir = .GlobalEnv)),
        add = TRUE
      )
    }
    set.seed(as.integer(seed))
  }

  inputs <- fit$tmb_inputs
  base_data <- inputs$data
  base_map <- inputs$map %||% list()
  base_par <- tls_mle_par_list(fit, inputs$parameters)

  # Fitted probabilities + dispersion straight from the compiled model at the
  # MLE: guaranteed consistent with the likelihood and the (possibly grouped)
  # design, for both the column and formula interfaces.
  # For an RE fit the optimiser par is fixed-only; report needs the full par
  # vector (fixed + conditional modes).
  rep0 <- fit$obj$report(
    if (tls_has_re(fit)) fit$obj$env$last.par.best else fit$par
  )
  p_hat <- as.numeric(rep0$p_fitted)
  n_trials <- as.numeric(base_data$n)
  nobs <- length(p_hat)
  fam_code <- fit$family$family_code
  phi_hat <- if (fam_code >= 1L) rep0$phi else NULL

  # Random-effects fits are bootstrapped by redrawing the group deviations
  # b_g ~ N(0, sigma_hat) for every active block (CTmax and/or log_z) through the
  # compiled model (a parametric bootstrap of the hierarchical model), then
  # refitting with the random block(s).
  re_blocks <- tls_re_blocks(fit)
  is_re <- length(re_blocks) > 0L
  if (is_re) {
    full_par <- fit$obj$env$last.par.best
    re_random <- vapply(re_blocks, function(bk) bk$b_name, character(1))
    # Per-block: the positions of its b vector in the full par, and its MLE SD.
    re_draw <- lapply(re_blocks, function(bk) {
      list(idx = which(names(full_par) == bk$b_name),
           sigma = rep0[[bk$sigma_report]])
    })
  } else {
    re_random <- NULL
  }

  est <- fit$estimates
  param_names <- est$parameter
  glevels <- fit$group_levels
  ng <- length(glevels)
  ct_names <- if (ng == 1L) "CTmax" else paste0("CTmax:", glevels)
  z_names <- if (ng == 1L) "z" else paste0("z:", glevels)
  # Shapes are shared (one coefficient) or grouped (one per CTmax level).
  n_shape <- length(rep0$low)
  shape_names <- function(base) if (n_shape == 1L) base else paste0(base, ":", glevels)
  low_names <- shape_names("low")
  up_names <- shape_names("up")
  k_names <- shape_names("k")

  out <- matrix(NA_real_, nrow = nboot, ncol = length(param_names),
                dimnames = list(NULL, param_names))
  converged <- logical(nboot)

  draw_from_p <- function(p) {
    if (identical(fam_code, 2L)) {
      # beta: redraw continuous proportions directly, clamped off {0, 1} to
      # match the fit's own beta clamp so a refit never sees a boundary value.
      prop <- stats::rbeta(nobs, p * phi_hat, (1 - p) * phi_hat)
      pmin(pmax(prop, 1e-6), 1 - 1e-6)
    } else if (identical(fam_code, 1L)) {
      prob <- stats::rbeta(nobs, p * phi_hat, (1 - p) * phi_hat)
      stats::rbinom(nobs, size = n_trials, prob = prob)
    } else {
      stats::rbinom(nobs, size = n_trials, prob = p)
    }
  }

  draw_y <- function() {
    if (is_re) {
      # Redraw each block's group deviations, recompute p through the compiled
      # model. Single-block draws keep the previous RNG stream exactly.
      fp <- full_par
      for (blk in re_draw) {
        fp[blk$idx] <- stats::rnorm(length(blk$idx), 0, blk$sigma)
      }
      draw_from_p(as.numeric(fit$obj$report(fp)$p_fitted))
    } else {
      draw_from_p(p_hat)
    }
  }

  refit_one <- function(y_star) {
    d <- base_data
    d$y <- as.numeric(y_star)
    inner <- tryCatch(
      TMB::MakeADFun(data = d, parameters = base_par, map = base_map,
                     random = re_random, DLL = "freqTLS",
                     silent = !isTRUE(trace)),
      error = function(e) e
    )
    if (inherits(inner, "error")) return(NULL)
    # Optimisers can emit low-level NA/NaN trial-step warnings before recovering
    # or returning a non-zero convergence code. The code below classifies that
    # replicate explicitly, so do not leak those implementation warnings into a
    # user's bootstrap fallback.
    opt <- tryCatch(suppressWarnings(stats::nlminb(inner$par, inner$fn, inner$gr)),
                    error = function(e) e)
    ok <- !inherits(opt, "error") && !is.null(opt$convergence) &&
      identical(as.integer(opt$convergence), 0L)
    if (!ok) {
      # Mirror the engine's BFGS fallback so a single optimiser stall does not
      # discard an otherwise informative replicate.
      o <- tryCatch(suppressWarnings(
                      stats::optim(inner$par, inner$fn, inner$gr, method = "BFGS")
                    ),
                    error = function(e) e)
      if (inherits(o, "error") || !identical(as.integer(o$convergence), 0L)) {
        return(NULL)
      }
      opt <- list(par = o$par)
    }
    # Re-pin at the optimum before reading the report. For an RE refit this
    # re-solves the inner Laplace problem (as tls_estimates does); for a no-RE
    # fit report(opt$par) is equivalent.
    if (is_re) {
      inner$fn(opt$par)
      rp <- inner$report()
    } else {
      rp <- inner$report(opt$par)
    }
    vals <- stats::setNames(rep(NA_real_, length(param_names)), param_names)
    vals[low_names] <- as.numeric(rp$low)
    vals[up_names] <- as.numeric(rp$up)
    vals[k_names] <- as.numeric(rp$k)
    if (fam_code >= 1L && "phi" %in% param_names) vals["phi"] <- rp$phi
    vals[ct_names] <- as.numeric(rp$beta_CT)
    vals[z_names] <- as.numeric(rp$z_group)
    if (is_re && "sigma_CTmax" %in% param_names) vals["sigma_CTmax"] <- rp$sigma_CT
    if (is_re && "sigma_logz" %in% param_names) vals["sigma_logz"] <- rp$sigma_logz
    if (is_re && "sigma_low" %in% param_names) vals["sigma_low"] <- rp$sigma_low
    if (is_re && "sigma_logk" %in% param_names) vals["sigma_logk"] <- rp$sigma_logk
    vals
  }

  # Pre-draw every replicate's response vector sequentially under the seed, then
  # parallelise only the deterministic refits (refits consume no RNG). This makes
  # the result identical for a given seed regardless of `cores`, and identical to
  # the sequential path.
  ys <- lapply(seq_len(nboot), function(b) draw_y())

  results <- if (cores > 1L && .Platform$OS.type != "windows") {
    parallel::mclapply(ys, refit_one, mc.cores = cores)
  } else {
    if (cores > 1L) {
      cli::cli_inform(c(
        "i" = "Multicore bootstrap forks processes, which is unavailable on Windows; running sequentially."
      ))
    }
    lapply(ys, refit_one)
  }

  for (b in seq_len(nboot)) {
    v <- results[[b]]
    if (is.numeric(v) && length(v) == length(param_names) &&
        all(is.finite(v[c(ct_names, z_names)]))) {
      out[b, ] <- v
      converged[b] <- TRUE
    }
  }

  list(
    replicates = out,
    converged = converged,
    n_converged = sum(converged),
    nboot = nboot,
    param_names = param_names
  )
}

#' Map a target name to its bootstrap replicates on the construction scale
#'
#' Returns the replicate values on the scale the percentile is taken on (so the
#' interval respects the parameter's bounds and is exactly equivariant), the
#' monotone `backtransform` to the natural scale, the natural-scale point
#' `estimate`, and a `scale` label. Handles direct parameters (`CTmax`, `z`,
#' `low`, `up`, `k`, `phi`, and grouped names), the `log_z` family, and group
#' contrasts (`dCTmax`, `dz`, `dlog_z`), using the same conventions as the
#' profile path so the two methods agree on what each target means.
#' @keywords internal
#' @noRd
tls_boot_target <- function(parm, fit, reps) {
  cn <- colnames(reps)
  est <- fit$estimates
  est_of <- function(nm) {
    v <- est$estimate[est$parameter == nm]
    if (length(v)) v[1L] else NA_real_
  }
  ident <- function(x) x

  # Group contrasts use their written direction: <a>-<b> means group a minus b.
  if (grepl("^d(CTmax|z|log_z):", parm)) {
    m <- regmatches(parm, regexec("^d(CTmax|z|log_z):(.+)-(.+)$", parm))[[1L]]
    if (length(m) == 4L) {
      base <- m[2L]; a <- m[3L]; b <- m[4L]
      if (identical(base, "CTmax")) {
        na <- paste0("CTmax:", a); nb <- paste0("CTmax:", b)
        if (!all(c(na, nb) %in% cn)) {
          cli::cli_abort("Contrast groups {.val {a}}/{.val {b}} must be levels of the fit.")
        }
        return(list(values = reps[, na] - reps[, nb], backtransform = ident,
                    estimate = est_of(na) - est_of(nb), scale = "identity"))
      }
      # z / log_z contrast: a difference of log z (so the z ratio is exp()).
      na <- paste0("z:", a); nb <- paste0("z:", b)
      if (!all(c(na, nb) %in% cn)) {
        cli::cli_abort("Contrast groups {.val {a}}/{.val {b}} must be levels of the fit.")
      }
      return(list(values = log(reps[, na]) - log(reps[, nb]), backtransform = ident,
                  estimate = log(est_of(na)) - log(est_of(nb)), scale = "log"))
    }
  }

  # log_z family: percentile on log(z) (identity back-transform).
  if (parm == "log_z" || grepl("^log_z:", parm)) {
    zname <- sub("^log_z", "z", parm)
    if (!(zname %in% cn)) {
      cli::cli_abort("Unknown bootstrap target {.val {parm}}.")
    }
    return(list(values = log(reps[, zname]), backtransform = ident,
                estimate = log(est_of(zname)), scale = "log"))
  }

  # Direct natural-scale parameter, taken on its construction scale.
  if (parm %in% cn) {
    base <- sub(":.*$", "", parm)
    spec <- switch(base,
      CTmax = list(fwd = ident, back = ident, scale = "identity"),
      up    = list(fwd = ident, back = ident, scale = "identity"),
      low   = list(fwd = stats::qlogis, back = stats::plogis, scale = "logit"),
      z     = list(fwd = log, back = exp, scale = "log"),
      k     = list(fwd = log, back = exp, scale = "log"),
      phi   = list(fwd = log, back = exp, scale = "log"),
      sigma_CTmax = list(fwd = log, back = exp, scale = "log"),
      sigma_logz  = list(fwd = log, back = exp, scale = "log"),
      sigma_low   = list(fwd = log, back = exp, scale = "log"),
      sigma_logk  = list(fwd = log, back = exp, scale = "log"),
      list(fwd = ident, back = ident, scale = "identity")
    )
    return(list(values = spec$fwd(reps[, parm]), backtransform = spec$back,
                estimate = est_of(parm), scale = spec$scale))
  }

  cli::cli_abort(c(
    "Unknown bootstrap target {.val {parm}}.",
    i = "Valid targets: {.val {cn}} (and {.val log_z} or contrasts such as {.val dCTmax:A-B})."
  ))
}

#' Parametric bootstrap confidence-interval tibble for named targets
#'
#' Returns the same tibble shape as the profile and Wald paths, with
#' `method = "bootstrap"` and `conf.status = "bootstrap"`. Percentile intervals
#' are taken over the converged, finite replicates on each target's construction
#' scale and back-transformed. A target with too few usable replicates returns
#' `NA` with `conf.status = "bootstrap_unstable"` and a warning rather than a
#' fabricated bound.
#'
#' @param fit A `profile_tls` fit.
#' @param parm Character vector of target names.
#' @param level Confidence level.
#' @param nboot Number of replicates (ignored when `replicates` is supplied).
#' @param seed Optional integer seed (ignored when `replicates` is supplied).
#' @param cores Number of CPU cores for the refits (ignored when `replicates` is
#'   supplied).
#' @param replicates Optional precomputed result of `tls_bootstrap_replicates()`
#'   (so a single set of refits serves many targets, e.g. the fallback path).
#' @keywords internal
#' @noRd
tls_confint_bootstrap <- function(fit, parm, level, nboot = 1000L, seed = NULL,
                                  cores = 1L, replicates = NULL) {
  boot <- replicates %||%
    tls_bootstrap_replicates(fit, nboot = nboot, seed = seed, cores = cores)
  reps <- boot$replicates
  alpha <- 1 - level
  floor_n <- 20L

  rows <- lapply(parm, function(p) {
    tg <- tls_boot_target(p, fit, reps)
    vals <- tg$values[boot$converged]
    vals <- vals[is.finite(vals)]
    n_use <- length(vals)
    if (n_use < floor_n) {
      cli::cli_warn(c(
        "The parametric bootstrap for {.val {p}} produced only {n_use} usable replicate{?s} of {boot$nboot}.",
        i = "Returning {.val NA}; the estimator is too unstable to summarise (consider {.pkg bayesTLS})."
      ))
      return(tibble::tibble(
        parameter = p, conf.low = NA_real_, conf.high = NA_real_,
        estimate = tg$estimate, level = level, method = "bootstrap",
        scale = tg$scale, conf.status = "bootstrap_unstable"
      ))
    }
    if (n_use < 0.5 * boot$nboot) {
      cli::cli_inform(c(
        "i" = "Only {n_use} of {boot$nboot} bootstrap replicates for {.val {p}} converged; the interval uses those."
      ))
    }
    q <- stats::quantile(vals, c(alpha / 2, 1 - alpha / 2), names = FALSE,
                         na.rm = TRUE)
    lo <- tg$backtransform(q[1L])
    hi <- tg$backtransform(q[2L])
    tibble::tibble(
      parameter = p, conf.low = lo, conf.high = hi,
      estimate = tg$estimate, level = level, method = "bootstrap",
      scale = tg$scale, conf.status = "bootstrap"
    )
  })
  do.call(rbind, rows)
}
