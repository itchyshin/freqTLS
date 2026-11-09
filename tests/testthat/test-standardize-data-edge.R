# Input checks, alternative response encodings, and cleaning rules of
# standardize_data() (R/standardize_data.R) not covered by
# test-standardize_data.R.

sd_raw <- function() {
  data.frame(
    temp = rep(c(30, 32, 34), each = 3),
    dur  = rep(c(1, 2, 4), times = 3),
    n    = 20L,
    alive = c(19, 15, 4, 18, 9, 2, 12, 3, 0)
  )
}

std <- function(data = sd_raw(), ...) {
  standardize_data(data, temp = "temp", duration = "dur", ...)
}

test_that("exactly one response encoding must be supplied", {
  expect_error(std(n_total = "n"), "Supply exactly one of")
  expect_error(std(n_total = "n", n_surv = "alive", survival = "alive"),
               "Supply exactly one of")
  expect_error(std(n_surv = "alive"), "require `n_total`")
})

test_that("n_dead, survival, and mortality encodings agree with n_surv", {
  d <- sd_raw()
  d$dead <- d$n - d$alive
  d$surv_prop <- d$alive / d$n
  d$mort_prop <- d$dead / d$n
  ref <- std(d, n_total = "n", n_surv = "alive")
  by_dead <- std(d, n_total = "n", n_dead = "dead")
  by_surv <- std(d, n_total = "n", survival = "surv_prop")
  by_mort <- std(d, n_total = "n", mortality = "mort_prop")
  for (s in list(by_dead, by_surv, by_mort)) {
    expect_identical(s$n_surv, ref$n_surv)
    expect_identical(s$n_dead, ref$n_dead)
    expect_equal(s$survival, ref$survival)
  }
  expect_identical(ref$n_surv, as.integer(d$alive))
})

test_that("proportion columns above 1 are rejected as probable counts", {
  d <- sd_raw()
  d$s <- d$alive
  d$m <- d$n - d$alive
  expect_error(std(d, n_total = "n", survival = "s"), "survivor COUNTS")
  expect_error(std(d, n_total = "n", mortality = "m"), "death COUNTS")
})

test_that("out-of-range survivor counts are clamped with a warning", {
  d <- sd_raw()
  d$alive[1] <- 25
  d$alive[2] <- -2
  expect_warning(s <- std(d, n_total = "n", n_surv = "alive"),
                 "2 cell\\(s\\) had survivor counts outside")
  expect_identical(s$n_surv[1:2], c(20L, 0L))
  expect_true(all(s$n_surv >= 0 & s$n_surv <= s$n_total))
  expect_equal(s$survival[1], 1)
})

test_that("rows with zero trials or non-positive duration are dropped", {
  d <- sd_raw()
  d$n[3] <- 0L
  d$alive[3] <- 0
  d$dur[5] <- 0
  s <- std(d, n_total = "n", n_surv = "alive")
  expect_equal(nrow(s), nrow(d) - 2L)
  expect_true(all(s$n_total > 0 & s$duration > 0))
})

test_that("a single assay temperature warns that z is not identified", {
  d <- sd_raw()
  d <- d[d$temp == 30, ]
  expect_warning(s <- std(d, n_total = "n", n_surv = "alive"),
                 "Only 1 unique assay temperature")
  expect_equal(s$temp_c, rep(0, nrow(s)))
})

test_that("existing standardised column names are not silently overwritten", {
  d <- sd_raw()
  d$logd <- 99
  expect_warning(s <- std(d, n_total = "n", n_surv = "alive"),
                 "overwrites existing column\\(s\\).*logd")
  expect_equal(s$logd, log10(s$duration))
})

test_that("proportion responses are range-checked, clamped, and flagged", {
  d <- sd_raw()
  d$fv <- c(0.95, 0.7, 0.2, 0.9, 0.5, 0.1, 0.6, 0.3, 0.05)
  s <- std(d, proportion = "fv")
  expect_identical(attr(s, "tdt_meta")$response_type, "proportion")
  expect_identical(attr(s, "tdt_meta")$response_var, "survival")
  expect_equal(s$survival, d$fv)
  expect_false("n_total" %in% names(s))

  bad <- d
  bad$fv[2] <- 1.2
  expect_error(std(bad, proportion = "fv"), "outside \\[0, 1\\]")
  neg <- d
  neg$fv[2] <- -0.1
  expect_error(std(neg, proportion = "fv"), "outside \\[0, 1\\]")

  edge <- d
  edge$fv[c(1, 9)] <- c(1, 0)
  expect_warning(s2 <- std(edge, proportion = "fv"),
                 "clamped 2 of 9 finite proportion values into \\[0.001, 0.999\\]")
  expect_equal(s2$survival[c(1, 9)], c(0.999, 0.001))
  expect_equal(attr(s2, "tdt_meta")$proportion_eps, 0.001)

  eps <- std(edge, proportion = "fv", proportion_eps = 0.01) |>
    suppressWarnings()
  expect_equal(eps$survival[c(1, 9)], c(0.99, 0.01))
})

test_that("a pre-existing `survival` column is flagged when a proportion is supplied", {
  d <- sd_raw()
  d$fv <- seq(0.9, 0.1, length.out = 9)
  d$survival <- 7
  expect_warning(s <- std(d, proportion = "fv"),
                 "overwrites the existing `survival` column")
  expect_equal(s$survival, d$fv)
})

test_that("random-effect grouping variables become factors and must exist", {
  d <- sd_raw()
  d$tank <- rep(c("t1", "t2", "t3"), 3)
  s <- std(d, n_total = "n", n_surv = "alive", random_effects = c("tank", "(1 | tank)"))
  expect_s3_class(s$tank, "factor")
  expect_identical(attr(s, "tdt_meta")$random_effects, c("tank", "(1 | tank)"))
  expect_error(std(d, n_total = "n", n_surv = "alive", random_effects = "nosuch"),
               "Missing input columns: nosuch")
})

test_that("an explicit temp_mean centres temperature on that value", {
  s <- std(n_total = "n", n_surv = "alive", temp_mean = 30)
  expect_equal(s$temp_c, s$temp - 30)
  expect_equal(attr(s, "tdt_meta")$temp_mean, 30)
})
