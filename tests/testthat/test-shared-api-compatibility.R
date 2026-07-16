test_that("clock_to_minutes makes the Excel-fraction assumption visible", {
  expect_message(
    expect_equal(clock_to_minutes(c(0.25, 0.5)), c(360, 720)),
    "Excel day-fractions",
    fixed = TRUE
  )
})

test_that("standardize_data records the proportion clamp and warns on overwrite", {
  x <- data.frame(temp_raw = c(30, 31), duration_raw = c(1, 2),
                  response = c(0, 1), survival = c("old", "values"))
  out <- NULL
  expect_warning(
    expect_warning(
      out <- standardize_data(
        x, temp = "temp_raw", duration = "duration_raw",
        proportion = "response", proportion_eps = 0.01
      ),
      "clamped 2 of 2 finite proportion values"
    ),
    "overwrites the existing `survival` column",
    fixed = TRUE
  )
  expect_equal(out$survival, c(0.01, 0.99))
  expect_equal(attr(out, "tdt_meta")$proportion_eps, 0.01)
})

test_that("two-stage helpers reject non-positive time scales", {
  stage1 <- data.frame(
    temp = c(30, 32, 34), log10_lt50 = c(2, 1, 0),
    stage1_ok = TRUE, finite_ok = TRUE
  )
  expect_error(ts_stage2(stage1, t_ref = 0))
  expect_error(ts_stage2(stage1, time_multiplier = 0))
  stage2 <- ts_stage2(stage1)
  expect_error(ts_ci(stage2, t_ref = 0))
  expect_error(ts_ci(stage2, time_multiplier = 0))
})
