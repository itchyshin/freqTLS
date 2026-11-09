# Tests for the small TDT utilities in R/tdt-utils.R: quantile and interval
# formatting, clock parsing, column checks, random-effect term helpers, 4PL
# asymptote bounds, and time-unit conversion.

test_that("tdt_quantile returns the requested quantiles and drops NA", {
  x <- c(1:100, NA)
  expect_equal(tdt_quantile(x), c(3.475, 50.5, 97.525))
  expect_null(names(tdt_quantile(x)))
  expect_equal(tdt_quantile(x, probs = 0.5), 50.5)
  expect_length(tdt_quantile(1:10, probs = c(0.1, 0.9)), 2L)
})

test_that("format_interval formats finite values and blanks non-finite medians", {
  expect_identical(format_interval(5.123, 4.872, 5.401), "5.12 [4.87, 5.4]")
  expect_identical(format_interval(5.123, 4.872, 5.401, digits = 1),
                   "5.1 [4.9, 5.4]")
  expect_identical(format_interval(NA_real_, 1, 2), NA_character_)
  expect_identical(format_interval(Inf, 1, 2), NA_character_)
  # A non-finite bound is rendered as an en dash, not "NA" or "Inf".
  expect_identical(format_interval(3, NA_real_, Inf), "3 [\u2013, \u2013]")
  # Vectorised: only the non-finite median becomes NA.
  out <- format_interval(c(1, NA), c(0, 0), c(2, 2))
  expect_identical(out, c("1 [0, 2]", NA_character_))
})

test_that("`%||%` falls back only for NULL", {
  expect_identical(NULL %||% 3, 3)
  expect_identical(0 %||% 3, 0)
  expect_identical(NA %||% 3, NA)
})

test_that("clock_to_minutes handles POSIXt, difftime, numeric, and character input", {
  tm <- as.POSIXct("2024-05-01 08:30:30", tz = "UTC")
  expect_equal(clock_to_minutes(tm), 8 * 60 + 30 + 30 / 60)

  expect_equal(clock_to_minutes(as.difftime(2, units = "hours")), 120)
  expect_equal(clock_to_minutes(as.difftime(90, units = "secs")), 1.5)

  # Numeric values already in minutes are returned unchanged.
  expect_identical(clock_to_minutes(c(10, 30, 720)), c(10, 30, 720))
  expect_identical(clock_to_minutes(numeric(0)), numeric(0))
  expect_identical(clock_to_minutes(c(5, NA, 20)), c(5, NA, 20))

  # Character strings: HH:MM:SS, HH:MM, > 24 h, bare numbers, and malformed.
  expect_equal(clock_to_minutes("08:30:00"), 510)
  expect_equal(clock_to_minutes("08:30"), 510)
  expect_equal(clock_to_minutes("25:30"), 1530)
  expect_equal(clock_to_minutes("25:30:30"), 1530.5)
  expect_equal(clock_to_minutes("45"), 45)
  expect_equal(clock_to_minutes(" 7.5 "), 7.5)
  expect_equal(clock_to_minutes(c("01:00", "00:30:30")), c(60, 30.5))
  expect_true(is.na(clock_to_minutes("")))
  expect_true(is.na(clock_to_minutes(NA_character_)))
  expect_true(is.na(clock_to_minutes("abc")))
  expect_true(is.na(clock_to_minutes("1:2:3:4")))
  expect_true(is.na(clock_to_minutes("08:xx")))
})

test_that("clock_to_minutes treats an all-[0, 1] numeric vector as Excel day fractions", {
  expect_message(out <- clock_to_minutes(c(0.5, 0.25)), "Excel day-fractions")
  expect_equal(out, c(720, 360))
})

test_that("clock_to_minutes warns when numeric input mixes fractions and minutes", {
  expect_warning(out <- clock_to_minutes(c(0.5, 720)),
                 "mixes values < 1 and > 1")
  expect_identical(out, c(0.5, 720))
})

test_that("tdt_check_columns names every missing column and ignores blanks", {
  d <- data.frame(a = 1, b = 2)
  expect_true(tdt_check_columns(d, c("a", "b")))
  expect_invisible(tdt_check_columns(d, "a"))
  expect_true(tdt_check_columns(d, c("a", NA, "")))
  expect_error(tdt_check_columns(d, c("a", "x", "y"), arg_name = "response"),
               "Missing response: x, y", fixed = TRUE)
  expect_error(tdt_check_columns(d, "q"), "Missing columns: q", fixed = TRUE)
})

test_that("random-effect helpers wrap bare names and extract grouping variables", {
  expect_identical(tdt_format_random_effects(NULL), character())
  expect_identical(tdt_format_random_effects(character()), character())
  expect_identical(tdt_format_random_effects(c("tank", "(1 | site)")),
                   c("(1 | tank)", "(1 | site)"))
  expect_identical(tdt_format_random_effects("  species "), "(1 | species)")

  expect_setequal(tdt_random_effect_variables(c("tank", "(1 | site)", "tank")),
                  c("tank", "site"))
  expect_null(tdt_random_effect_variables(NULL))
})

test_that("compute_4pl_bounds returns disjoint low/up intervals around the midpoint", {
  b <- compute_4pl_bounds()
  expect_equal(b$midpoint, 0.5)
  expect_equal(b$low_min, 0.001)
  expect_equal(b$low_max, 0.499)
  expect_equal(b$up_min, 0.501)
  expect_equal(b$up_max, 0.999)
  expect_equal(b$low_w, b$low_max - b$low_min)
  expect_equal(b$up_w, b$up_max - b$up_min)
  expect_lt(b$low_max, b$up_min)

  b2 <- compute_4pl_bounds(lower = 0.85, upper = 1, pad = 0.01, gap = 0.02)
  expect_equal(b2$midpoint, 0.925)
  expect_equal(b2$low_min, 0.86)
  expect_equal(b2$up_max, 0.99)
  expect_equal(b2$up_min - b2$low_max, 0.02)
})

test_that("compute_4pl_bounds rejects impossible ranges", {
  expect_error(compute_4pl_bounds(lower = 1, upper = 1),
               "upper must be strictly greater than lower")
  expect_error(compute_4pl_bounds(lower = 0.9, upper = 0.1),
               "upper must be strictly greater than lower")
  expect_error(compute_4pl_bounds(lower = 0, upper = 1, pad = 0.5, gap = 0.1),
               "leave no room for asymptote intervals")
})

test_that("tdt_unit_to_minutes maps unit labels to minutes and rejects the rest", {
  expect_equal(tdt_unit_to_minutes("seconds"), 1 / 60)
  expect_equal(tdt_unit_to_minutes("s"), 1 / 60)
  expect_equal(tdt_unit_to_minutes("min"), 1)
  expect_equal(tdt_unit_to_minutes("Minutes"), 1)
  expect_equal(tdt_unit_to_minutes(" HOURS "), 60)
  expect_equal(tdt_unit_to_minutes("hr"), 60)
  expect_equal(tdt_unit_to_minutes("days"), 1440)

  expect_error(tdt_unit_to_minutes(NULL), "time unit is NULL/NA")
  expect_error(tdt_unit_to_minutes(NA_character_), "time unit is NULL/NA")
  expect_error(tdt_unit_to_minutes(c("min", "h")), "time unit is NULL/NA")
  expect_error(tdt_unit_to_minutes("fortnight"),
               "Unrecognised time unit: 'fortnight'")
})

test_that("tdt_resolve_time_multiplier honours overrides and derives from units", {
  expect_equal(tdt_resolve_time_multiplier(2.5, list(duration_unit = "h"), "min"),
               2.5)
  # model time in hours, output in minutes: 1 model unit = 60 output units.
  expect_equal(tdt_resolve_time_multiplier(NULL, list(duration_unit = "hours"),
                                           "min"), 60)
  # model time in minutes, output in hours.
  expect_equal(tdt_resolve_time_multiplier(NULL, list(duration_unit = "min"),
                                           "hours"), 1 / 60)
  expect_equal(tdt_resolve_time_multiplier(NULL, list(duration_unit = "days"),
                                           "hours"), 24)
})

test_that("tdt_resolve_time_multiplier falls back to 1 with a message", {
  expect_message(
    m <- tdt_resolve_time_multiplier(NULL, list(duration_unit = "fortnight"),
                                     "min"),
    "assuming model time unit == output unit")
  expect_identical(m, 1)
  expect_message(
    m2 <- tdt_resolve_time_multiplier(NULL, list(), "min"),
    "duration_unit \\('NULL'\\)")
  expect_identical(m2, 1)
  expect_message(
    tdt_resolve_time_multiplier(NULL, list(duration_unit = "min"), "eons"),
    "output_time_unit \\('eons'\\)")
})

test_that("tdt_is_grouped reads meta$grouped strictly", {
  expect_true(tdt_is_grouped(list(meta = list(grouped = TRUE))))
  expect_false(tdt_is_grouped(list(meta = list(grouped = FALSE))))
  expect_false(tdt_is_grouped(list(meta = list())))
  expect_false(tdt_is_grouped(list(meta = list(grouped = "yes"))))
})
