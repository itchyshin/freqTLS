#' Response families for thermal-load-sensitivity models
#'
#' `binomial_tls()` and `beta_binomial_tls()` describe the count response
#' distribution for [fit_tls()], and `beta_tls()` the continuous-proportion
#' response in `(0, 1)` (e.g. PSII operating efficiency or relative chlorophyll
#' fluorescence). All three model survival as a four-parameter logistic function
#' of log10 duration; the beta-binomial and beta families add a dispersion
#' parameter `phi`.
#'
#' @details
#' The `phi` convention for the beta-binomial family is the **sum of the Beta
#' shape parameters**: for fitted survival probability `p`, counts are
#' Beta-Binomial with shapes `a = p * phi` and `b = (1 - p) * phi`. Larger `phi`
#' means *less* overdispersion (the binomial is recovered as `phi` grows). This
#' matches the simulation convention in [simulate_tls()] and differs from the
#' precision/size parameterisations used by some other packages. The `beta`
#' family uses the **same shapes** for the continuous proportion, `y ~
#' Beta(p * phi, (1 - p) * phi)`, so `phi` carries the identical meaning and a
#' larger `phi` again means a tighter response around the fitted curve.
#'
#' @return A `tls_family` object: a list with `family`, `family_code`
#'   (0 binomial, 1 beta-binomial, 2 beta), and `links` for the natural-scale
#'   parameters.
#' @name tls_family
#' @examples
#' binomial_tls()
#' beta_binomial_tls()
#' beta_tls()
NULL

#' @rdname tls_family
#' @export
binomial_tls <- function() {
  structure(
    list(
      family = "binomial",
      family_code = 0L,
      links = c(low = "logit", up = "logit", k = "log",
                CTmax = "identity", z = "log")
    ),
    class = "tls_family"
  )
}

#' @rdname tls_family
#' @export
beta_binomial_tls <- function() {
  structure(
    list(
      family = "beta_binomial",
      family_code = 1L,
      links = c(low = "logit", up = "logit", k = "log",
                CTmax = "identity", z = "log", phi = "log")
    ),
    class = "tls_family"
  )
}

#' @rdname tls_family
#' @export
beta_tls <- function() {
  structure(
    list(
      family = "beta",
      family_code = 2L,
      links = c(low = "logit", up = "logit", k = "log",
                CTmax = "identity", z = "log", phi = "log")
    ),
    class = "tls_family"
  )
}

#' Resolve a family argument to a `tls_family` object
#'
#' @param family A `tls_family` object or a string ("binomial" /
#'   "beta_binomial" / "beta").
#' @return A `tls_family` object.
#' @keywords internal
#' @noRd
resolve_tls_family <- function(family) {
  if (inherits(family, "tls_family")) {
    return(family)
  }
  family <- match.arg(family, c("beta_binomial", "binomial", "beta"))
  switch(family,
    binomial = binomial_tls(),
    beta_binomial = beta_binomial_tls(),
    beta = beta_tls()
  )
}
