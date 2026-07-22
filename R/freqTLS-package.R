#' freqTLS: Frequentist Inference for Thermal Load Sensitivity Models
#'
#' `freqTLS` is a maximum-likelihood / profile-likelihood complement to the
#' Bayesian `bayesTLS` package. It fits single-stage four-parameter logistic
#' (4PL) thermal-load-sensitivity (thermal death-time) models via Template Model
#' Builder (`TMB`), parameterised directly in `CTmax` and `z`
#' (thermal sensitivity), so that both quantities can be profiled. It
#' returns prior-free Wald, profile-likelihood, or parametric-bootstrap
#' confidence intervals for binomial and beta-binomial survival counts and the
#' experimental Beta continuous-proportion family. Formula shape effects,
#' limited random intercepts, and deterministic heat-injury prediction are also
#' experimental; censored-time, hurdle-productivity, posterior, and fitted
#' repair models remain outside freqTLS.
#'
#' @section Experimental software:
#' **Use freqTLS at your own risk.** Results and APIs may be incorrect or
#' change. Users are responsible for checking their data, design, model
#' specification, convergence, identifiability, diagnostics, and
#' interpretation. Important analyses should be independently refitted and
#' cross-checked with the Bayesian sister package
#' [bayesTLS](https://daniel1noble.github.io/bayesTLS/) ([source
#' repository](https://github.com/daniel1noble/bayesTLS)). Agreement is a
#' cross-check, not proof of correctness; shared data or model errors can make
#' both packages agree.
#'
#' @section Credit and origins:
#' The thermal-load-sensitivity modelling framework and the direct mapping from
#' the 4PL midpoint slope to `z` and `CTmax` are from Noble, Arnold, Nakagawa
#' and Pottier (the `bayesTLS` package). `freqTLS` contributes the TMB maximum-likelihood
#' likelihood, the direct `CTmax`/`log_z` reparameterisation, and the
#' profile-likelihood machinery. Engineering patterns are adapted from `drmTMB`
#' (GPL-3) with attribution in the relevant source files.
#'
#' @keywords internal
#' @importFrom cli cli_abort cli_inform cli_warn
#' @importFrom rlang enquo eval_tidy quo_is_null .data
#' @importFrom stats AIC coef confint logLik median model.matrix nlminb nobs optim plogis pnorm profile qchisq qlogis qnorm rbeta rbinom relevel setNames terms uniroot vcov
#' @importFrom tibble tibble
#' @importFrom TMB MakeADFun sdreport
#' @importFrom utils packageVersion
#' @useDynLib freqTLS, .registration = TRUE
"_PACKAGE"

## usethis namespace: start
## usethis namespace: end
NULL
