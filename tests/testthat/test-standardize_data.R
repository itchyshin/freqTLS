# standardize_data() — the single raw-data entry point (twinned from bayesTLS).

raw_count <- data.frame(
  temperature_C = rep(c(30, 32, 34), each = 4),
  exposure_h    = rep(c(1, 2, 4, 8), times = 3),
  n             = 30L,
  alive         = c(29, 28, 25, 5, 30, 27, 18, 2, 28, 22, 10, 1),
  batch         = rep(c("a", "b"), 6)
)

test_that("count path builds the standard schema and centres temperature", {
  s <- standardize_data(raw_count, temp = "temperature_C", duration = "exposure_h",
                        n_total = "n", n_surv = "alive", random_effects = "batch",
                        duration_unit = "hours")
  expect_true(all(c("temp", "duration", "logd", "temp_c", "n_total", "n_surv",
                    "n_dead", "survival") %in% names(s)))
  expect_equal(s$logd, log10(s$duration))
  expect_equal(s$duration, 60 * raw_count$exposure_h)
  expect_identical(attr(s, "tdt_meta")$duration_unit, "minutes")
  expect_identical(attr(s, "tdt_meta")$input_duration_unit, "hours")
  expect_equal(mean(s$temp_c), 0, tolerance = 1e-8)          # centred at mean
  expect_equal(s$n_dead, s$n_total - s$n_surv)
  expect_s3_class(s$batch, "factor")                          # RE -> factor
  expect_identical(attr(s, "tdt_meta")$response_type, "count")
})

test_that("mortality and survival proportions convert to counts consistently", {
  rm <- raw_count; rm$mort <- 1 - rm$alive / rm$n
  sm <- standardize_data(rm, temp = "temperature_C", duration = "exposure_h",
                         n_total = "n", mortality = "mort", duration_unit = "hours")
  expect_equal(sm$n_surv, raw_count$alive)
})

test_that("proportion path flags a continuous Beta response and clamps to (0,1)", {
  rp <- data.frame(tC = c(30, 32, 34), eh = c(1, 2, 4), fv = c(1, 0.5, 0))
  expect_warning(
    s <- standardize_data(
      rp, temp = "tC", duration = "eh", proportion = "fv"
    ),
    "clamped 2 of 3 finite proportion values.*0.001.*0.999"
  )
  expect_identical(attr(s, "tdt_meta")$response_type, "proportion")
  expect_true(all(s$survival > 0 & s$survival < 1))           # clamped off 0/1
})

test_that("Snow-gum boundary adjustment is counted and visible", {
  data("snowgum_psii", package = "freqTLS")
  expect_warning(
    out <- standardize_data(
      snowgum_psii,
      temp = "Temp", duration = "Time", proportion = "fvfm_prop",
      duration_unit = "minutes"
    ),
    "clamped 90 of 394 finite proportion values.*0.001.*0.999"
  )
  expect_identical(sum(out$survival == 0.001), 89L)
  expect_identical(sum(out$survival == 0.999), 1L)
})

test_that("exactly one response must be supplied", {
  expect_error(standardize_data(raw_count, temp = "temperature_C",
                                duration = "exposure_h", n_total = "n"),
               "exactly one")
  expect_error(standardize_data(raw_count, temp = "temperature_C",
                                duration = "exposure_h", n_total = "n",
                                n_surv = "alive", mortality = "alive"),
               "exactly one")
})

test_that("compute_4pl_bounds gives disjoint low/up intervals splitting [0,1]", {
  b <- compute_4pl_bounds(0, 1)
  expect_lt(b$low_max, b$up_min)             # disjoint
  expect_equal(b$midpoint, 0.5)
  expect_equal(b$low_w, b$low_max - b$low_min)
})
