#' Build the CTmax / log(z) design matrices from a grouping vector
#'
#' Constructs the per-observation design matrices for `CTmax` and `log(z)`. With
#' no grouping every observation loads on a single "all" level; with a grouping
#' factor the design is `model.matrix(~ 0 + group)`, so each group gets its own
#' direct, profile-able `CTmax` and `z`.
#'
#' @param group A factor / vector of group labels, or `NULL` for the ungrouped
#'   case. Length must equal the number of observations.
#' @param n_obs Number of observations (used when `group` is `NULL`).
#' @return A list with `X_CT`, `X_logz` (identical numeric matrices), the group
#'   `levels`, and a `grouped` flag.
#' @keywords internal
#' @noRd
build_tls_design <- function(group, n_obs) {
  if (is.null(group)) {
    X <- matrix(1, nrow = n_obs, ncol = 1L,
                dimnames = list(NULL, "all"))
    return(list(
      X_CT = X, X_logz = X,
      levels = "all", grouped = FALSE
    ))
  }

  if (length(group) != n_obs) {
    cli::cli_abort(c(
      "{.arg group} must have one entry per observation.",
      i = "Got {length(group)} group value{?s} for {n_obs} observation{?s}."
    ))
  }

  g <- factor(group)
  if (any(is.na(g))) {
    cli::cli_abort("{.arg group} must not contain missing values.")
  }

  X <- stats::model.matrix(~ 0 + g)
  colnames(X) <- levels(g)
  attr(X, "assign") <- NULL
  attr(X, "contrasts") <- NULL

  list(
    X_CT = X, X_logz = X,
    levels = levels(g), grouped = TRUE
  )
}
