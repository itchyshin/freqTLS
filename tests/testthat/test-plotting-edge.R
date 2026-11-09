# Argument validation, drawing rules, and honest-uncertainty behaviour of the
# plotting helpers in R/plotting.R: the Confidence Eye, survival curves, TDT
# curve, and survival surface.

pl_fit <- function(temps = seq(30, 42, by = 2)) {
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, temps = temps, seed = 1)
  suppressWarnings(
    fit_tls(d, y = survived, n = total, time = duration, temp = temp,
            family = "binomial", tref = 1)
  )
}

pl_grouped <- function() {
  d <- simulate_tls(family = "binomial", group = c("A", "B"),
                    CTmax = c(34, 38), z = c(3, 5), seed = 2)
  suppressWarnings(
    fit_tls(d, y = survived, n = total, time = duration, temp = temp,
            group = group, family = "binomial", tref = 1)
  )
}

layer_geoms <- function(p) vapply(p$layers, function(l) class(l$geom)[1L], "")

test_that("tls_eye_ribbon_df draws a lens that spans the interval and skips open rows", {
  df <- data.frame(estimate = c(1, 5, 9), lower = c(0, 4, NA),
                   upper = c(3, NA, 10), row = 1:3)
  rb <- tls_eye_ribbon_df(df, half_height = 0.2, n = 41L)
  # Only the first row is drawable (the others have an open or missing bound).
  expect_identical(sort(unique(rb$.id)), 1L)
  expect_equal(range(rb$x), c(0, 3))
  # The lens is tallest at the estimate and shrinks to zero at the bounds.
  peak <- rb$x[which.max(rb$ymax - rb$ymin)]
  expect_equal(peak, 1, tolerance = 0.05)
  expect_equal(rb$ymax[1] - rb$ymin[1], 0, tolerance = 1e-12)
  expect_equal(max(rb$ymax - rb$ymin), 0.4, tolerance = 1e-3)

  none <- tls_eye_ribbon_df(df[2:3, ])
  expect_identical(nrow(none), 0L)
  expect_named(none, c(".id", "x", "ymin", "ymax"))

  degenerate <- data.frame(estimate = 1, lower = 1, upper = 1, row = 1)
  expect_identical(nrow(tls_eye_ribbon_df(degenerate)), 0L)

  expect_error(tls_eye_ribbon_df(data.frame(estimate = 1)),
               "must have columns")
})

test_that("plot_confidence_eye validates its arguments", {
  fit <- pl_fit()
  expect_error(plot_confidence_eye(fit, extra = 1), "reserved")
  expect_error(plot_confidence_eye(list()), "profile_tls")
  expect_error(plot_confidence_eye(fit, raw_data = NA), "raw_data.*TRUE or FALSE")
  expect_error(plot_confidence_eye(fit, annotate = "yes"), "annotate.*TRUE or FALSE")
  expect_error(plot_confidence_eye(fit, legend = c(TRUE, FALSE)),
               "legend.*TRUE or FALSE")
  expect_error(plot_confidence_eye(fit, parm = character()),
               "non-empty character vector")
  expect_error(plot_confidence_eye(fit, style = "violin"), "should be one of")
})

test_that("raw_data adds an assay-temperature rug and the caption says so", {
  fit <- pl_fit()
  base <- plot_confidence_eye(fit, method = "wald")
  rug <- plot_confidence_eye(fit, method = "wald", raw_data = TRUE)
  expect_false("GeomRug" %in% layer_geoms(base))
  expect_true("GeomRug" %in% layer_geoms(rug))
  expect_match(rug$labels$caption, "ticks = observed assay temperatures")
  expect_no_match(base$labels$caption, "ticks =")
  rug_df <- rug$layers[[which(layer_geoms(rug) == "GeomRug")]]$data
  expect_equal(rug_df$x, sort(unique(fit$diag_data$temp)))
})

test_that("the line style draws interval bars instead of lenses", {
  fit <- pl_fit()
  # geom_errorbarh() is deprecated in ggplot2 >= 4.0; the deprecation notice is
  # not what is under test here.
  p <- suppressWarnings(plot_confidence_eye(fit, method = "wald", style = "line"))
  geoms <- layer_geoms(p)
  expect_false("GeomRibbon" %in% geoms)
  expect_true(any(grepl("Errorbar", geoms)))
  expect_match(p$labels$caption, "bar = interval")
  expect_match(p$labels$caption, "(Wald)", fixed = TRUE)
})

test_that("the Confidence Eye caption names the interval source and avoids posterior language", {
  fit <- pl_fit()
  w <- plot_confidence_eye(fit, method = "wald")
  expect_match(w$labels$caption, "95% confidence intervals (Wald)", fixed = TRUE)
  expect_match(w$labels$caption, "lens width = interval")
  expect_no_match(w$labels$caption, "posterior|credible")
  expect_equal(sort(as.character(unique(w$data$parameter))), c("CTmax", "z"))
  est <- fit$estimates
  expect_equal(w$data$estimate[w$data$parameter == "CTmax"],
               est$estimate[est$parameter == "CTmax"])
})

test_that("grouped fits expand bare targets to one row per group", {
  fg <- pl_grouped()
  p <- plot_confidence_eye(fg, parm = c("CTmax", "z"), method = "wald")
  expect_setequal(as.character(p$data$parameter),
                  c("CTmax:A", "CTmax:B", "z:A", "z:B"))
  ct <- p$data[p$data$parameter == "CTmax:B", ]
  expect_gt(ct$estimate, p$data$estimate[p$data$parameter == "CTmax:A"])
})

test_that("random-effect fits use Wald intervals in the Confidence Eye and say so", {
  d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, re_sd = 1.5,
                    n_re_groups = 10, seed = 42)
  fr <- suppressWarnings(fit_tls(
    tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
           CTmax ~ 1 + (1 | colony)),
    data = d, family = "binomial", tref = 1))
  expect_message(p <- plot_confidence_eye(fr, parm = "CTmax"),
                 "uses Wald intervals for random-effects fits")
  expect_true(all(p$data$method == "wald"))
  expect_match(p$labels$subtitle, "Wald intervals \\(random-effects fit\\)")
})

test_that("survival-curve, TDT-curve, and surface plots validate their inputs", {
  fit <- pl_fit()
  expect_error(plot_survival_curves(fit, extra = 1), "reserved")
  expect_error(plot_survival_curves(list()), "profile_tls")
  expect_error(plot_tdt_curve(fit, extra = 1), "reserved")
  expect_error(plot_tdt_curve(list()), "profile_tls")
  expect_error(plot_tdt_curve(fit, p = 1.5), "absolute survival probability")
  expect_error(plot_tdt_curve(fit, p = c(0.2, 0.4)), "absolute survival probability")
  expect_error(plot_tdt_curve(fit, p = NA_real_), "absolute survival probability")
  expect_error(plot_survival_surface(fit, extra = 1), "reserved")
  expect_error(plot_survival_surface(list()), "profile_tls")
})

test_that("plot_survival_curves thins a long temperature list to seven curves", {
  fit <- pl_fit(temps = seq(28, 44, by = 2))
  expect_gt(length(unique(fit$diag_data$temp)), 7L)
  p <- plot_survival_curves(fit)
  expect_s3_class(p, "ggplot")
  temp_col <- intersect(c("temp", "temperature"), names(p$data))[1L]
  skip_if(is.na(temp_col), "curve data do not expose a temperature column")
  expect_lte(length(unique(p$data[[temp_col]])), 7L)
})

test_that("plot_survival_surface facets by group and can draw contours", {
  fg <- pl_grouped()
  p <- plot_survival_surface(fg, temps = c(32, 36, 40), times = c(1, 2, 4))
  expect_s3_class(p$facet, "FacetWrap")
  expect_true("GeomContour" %in% layer_geoms(p))
  p_nc <- plot_survival_surface(fg, temps = c(32, 36, 40), times = c(1, 2, 4),
                                contour = FALSE)
  expect_false("GeomContour" %in% layer_geoms(p_nc))
})
