# Formula-interface tests (tls_bf + fit_tls dispatch). The grammar is a thin,
# label-preserving front-end to the column interface, so the central contract is
# numerical identity: a formula fit must equal the matching column fit to
# optimiser tolerance. The error tests pin the supported shape/random-effect
# boundaries and the helpful axis/handle diagnostics. One fit per shape, fixed
# data, so the file stays fast.

test_that("a grouped formula fit equals the matching column fit", {
  data(zebrafish_lethal)
  # The shipped dataset uses bayesTLS raw column names; alias them to the generic
  # names these formula-mechanics tests reference (the real case-study workflow
  # goes through standardize_data()).
  zebrafish_lethal$survived <- zebrafish_lethal$n_surv
  zebrafish_lethal$total    <- zebrafish_lethal$n_total
  zebrafish_lethal$duration <- 60 * zebrafish_lethal$duration_h
  zebrafish_lethal$temp     <- zebrafish_lethal$assay_temp

  f_col <- suppressWarnings(fit_tls(
    zebrafish_lethal,
    y = survived, n = total, time = duration, temp = temp,
    group = life_stage, family = "beta_binomial", tref = 60
  ))
  f_frm <- suppressWarnings(fit_tls(
    tls_bf(
      survived | trials(total) ~ time(duration) + temp(temp),
      low ~ 1, up ~ 1, log_k ~ 1, CTmax ~ life_stage, log_z ~ life_stage
    ),
    data = zebrafish_lethal, family = "beta_binomial", tref = 60
  ))

  expect_equal(as.numeric(logLik(f_frm)), as.numeric(logLik(f_col)),
               tolerance = 1e-6)
  # Same coefficient labels (CTmax:<level> / z:<level>) and values.
  expect_identical(f_frm$estimates$parameter, f_col$estimates$parameter)
  expect_equal(f_frm$estimates$estimate, f_col$estimates$estimate,
               tolerance = 1e-6)
  expect_identical(f_frm$group_levels, f_col$group_levels)
  expect_true(isTRUE(f_frm$data_summary$grouped))
})

test_that("an ungrouped formula fit equals the ungrouped column fit", {
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 11)

  f_col <- suppressWarnings(fit_tls(
    d, y = survived, n = total, time = duration, temp = temp,
    family = "binomial", tref = 1
  ))
  f_frm <- suppressWarnings(fit_tls(
    tls_bf(survived | trials(total) ~ time(duration) + temp(temp)),
    data = d, family = "binomial", tref = 1
  ))

  expect_equal(as.numeric(logLik(f_frm)), as.numeric(logLik(f_col)),
               tolerance = 1e-6)
  expect_equal(unname(coef(f_frm)), unname(coef(f_col)), tolerance = 1e-6)
  # Ungrouped formula keeps the bare CTmax / z labels.
  expect_true(all(c("CTmax", "z") %in% f_frm$estimates$parameter))
  expect_false(isTRUE(f_frm$data_summary$grouped))
})

test_that("CTmax and log_z reject mismatched fixed-effect columns", {
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 19)
  d$x <- seq_len(nrow(d)) / nrow(d)

  expect_error(
    freqTLS:::tls_parse_formula(
      tls_bf(
        survived | trials(total) ~ time(duration) + temp(temp),
        CTmax ~ x, log_z ~ 1
      ),
      d, quiet = TRUE
    ),
    "must use the same fixed-effect predictors",
    fixed = TRUE
  )
})

test_that("cbind() and successes | trials() responses agree", {
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 12)
  d$dead <- d$total - d$survived

  f_trials <- suppressWarnings(fit_tls(
    tls_bf(survived | trials(total) ~ time(duration) + temp(temp)),
    data = d, family = "binomial", tref = 1
  ))
  f_cbind <- suppressWarnings(fit_tls(
    tls_bf(cbind(survived, dead) ~ time(duration) + temp(temp)),
    data = d, family = "binomial", tref = 1
  ))

  expect_equal(as.numeric(logLik(f_cbind)), as.numeric(logLik(f_trials)),
               tolerance = 1e-6)
  expect_equal(unname(coef(f_cbind)), unname(coef(f_trials)), tolerance = 1e-6)
})

test_that("an independent continuous shape predictor is allowed", {
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 8)
  d$bs <- stats::runif(nrow(d), -1, 1)
  # v0.2: each shape may carry its OWN design; `log_k ~ bs` alone (low / up shared,
  # CTmax / log_z intercept-only) is no longer rejected by a same-design constraint.
  fit <- fit_tls(
    tls_bf(survived | trials(total) ~ time(duration) + temp(temp), log_k ~ bs),
    data = d, family = "binomial", tref = 1)
  expect_identical(fit$convergence$code, 0L)
  expect_true("k:bs" %in% fit$estimates$parameter)
})

test_that("random intercepts on CTmax / log_z / low / log_k are parsed; up is rejected", {
  data(zebrafish_lethal)
  # The shipped dataset uses bayesTLS raw column names; alias them to the generic
  # names these formula-mechanics tests reference (the real case-study workflow
  # goes through standardize_data()).
  zebrafish_lethal$survived <- zebrafish_lethal$n_surv
  zebrafish_lethal$total    <- zebrafish_lethal$n_total
  zebrafish_lethal$duration <- 60 * zebrafish_lethal$duration_h
  zebrafish_lethal$temp     <- zebrafish_lethal$assay_temp
  # `(1 | group)` on CTmax yields a CTmax RE spec ($re).
  spec <- freqTLS:::tls_parse_formula(
    tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
           CTmax ~ (1 | life_stage)),
    zebrafish_lethal, quiet = TRUE)
  expect_false(is.null(spec$re))
  expect_identical(spec$re$group_var, "life_stage")
  # A bar on log_z yields a log_z RE spec ($re_logz) (item 5).
  spec_z <- freqTLS:::tls_parse_formula(
    tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
           log_z ~ (1 | life_stage)),
    zebrafish_lethal, quiet = TRUE)
  expect_false(is.null(spec_z$re_logz))
  expect_true(is.null(spec_z$re))
  expect_identical(spec_z$re_logz$group_var, "life_stage")
  # Bars on the shape coordinates low / log_k yield re_low / re_logk specs.
  spec_low <- freqTLS:::tls_parse_formula(
    tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
           low ~ (1 | life_stage)),
    zebrafish_lethal, quiet = TRUE)
  expect_false(is.null(spec_low$re_low))
  expect_identical(spec_low$re_low$group_var, "life_stage")
  spec_logk <- freqTLS:::tls_parse_formula(
    tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
           log_k ~ (1 | life_stage)),
    zebrafish_lethal, quiet = TRUE)
  expect_false(is.null(spec_logk$re_logk))
  # A bar on the upper asymptote `up` (nested gap, no single coordinate) is rejected.
  expect_error(
    freqTLS:::tls_parse_formula(
      tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
             up ~ (1 | life_stage)),
      zebrafish_lethal),
    "up|CTmax|log_z|low|log_k"
  )
})

test_that("an unknown sub-parameter handle is an error", {
  expect_error(
    tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
           slope ~ temp),
    "[Uu]nknown sub-parameter"
  )
})

test_that("a missing time() or temp() axis is an error", {
  d <- simulate_tls(family = "binomial", seed = 13)
  expect_error(
    suppressWarnings(fit_tls(
      tls_bf(survived | trials(total) ~ temp(temp)),
      data = d, family = "binomial", tref = 1
    )),
    "time"
  )
  expect_error(
    suppressWarnings(fit_tls(
      tls_bf(survived | trials(total) ~ time(duration)),
      data = d, family = "binomial", tref = 1
    )),
    "temp"
  )
})

test_that("a single-factor formula-grouped fit carries the per-row group vector", {
  d <- simulate_tls(family = "binomial", group = c("A", "B"),
                    CTmax = c(35, 38), z = c(4, 3), seed = 2)
  fit <- suppressWarnings(fit_tls(
    tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
           CTmax ~ group, log_z ~ group),
    data = d, family = "binomial", tref = 1))
  # The formula path must reconstruct the per-row group labels (previously NULL)
  # so the group-aware diagnostics and plots match the column interface.
  expect_length(fit$diag_data$group, nrow(d))
  expect_identical(as.character(fit$diag_data$group), as.character(d$group))
})

test_that("an ungrouped formula fit keeps a NULL group vector", {
  d <- simulate_tls(family = "binomial", seed = 13)
  fit <- fit_tls(
    tls_bf(survived | trials(total) ~ time(duration) + temp(temp)),
    data = d, family = "binomial", tref = 1)
  expect_null(fit$diag_data$group)
})

test_that("plot_survival_curves() works on a formula-grouped fit", {
  skip_if_not_installed("ggplot2")
  d <- simulate_tls(family = "binomial", group = c("A", "B"),
                    CTmax = c(35, 38), z = c(4, 3), seed = 2)
  fit <- suppressWarnings(fit_tls(
    tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
           CTmax ~ group, log_z ~ group),
    data = d, family = "binomial", tref = 1))
  p <- plot_survival_curves(fit)
  expect_s3_class(p, "ggplot")
})

test_that("formula starts put baselines on intercepts, not slopes or contrasts", {
  d <- data.frame(
    species = factor(rep(c("a", "b"), each = 3)),
    age = factor(rep(c("young", "old", "young"), 2)),
    temp_c = seq(-1, 1, length.out = 6)
  )
  X_factorial <- model.matrix(~ species * age, d)
  X_shape <- model.matrix(~ temp_c, d)
  X_onehot <- model.matrix(~ 0 + species, d)

  expect_equal(
    freqTLS:::tls_formula_start(X_factorial, 36),
    c(36, rep(0, ncol(X_factorial) - 1L))
  )
  expect_equal(freqTLS:::tls_formula_start(X_shape, log(5)), c(log(5), 0))
  expect_equal(freqTLS:::tls_formula_start(X_onehot, 36), c(36, 36))
})
