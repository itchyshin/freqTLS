# Parameter-transform and forward-map invariants for the freqTLS 4PL.
# These are pure-R checks of the algebra the TMB engine implements; they do not
# fit a model, so they are fast and deterministic. SPEC.md S11.

test_that("link round-trips are exact (1e-8)", {
  # logit
  p <- c(0.01, 0.1, 0.5, 0.9, 0.99)
  expect_equal(tls_backtransform(tls_link(p, "logit"), "logit"), p,
               tolerance = 1e-8)
  # log
  x <- c(0.5, 1, 3, 30, 100)
  expect_equal(tls_backtransform(tls_link(x, "log"), "log"), x,
               tolerance = 1e-8)
  # identity
  v <- c(-5, 0, 36.2)
  expect_equal(tls_backtransform(tls_link(v, "identity"), "identity"), v,
               tolerance = 1e-8)
})

test_that("disjoint-bounds asymptotes always satisfy 0 < low < up < 1", {
  inv_logit <- function(x) 1 / (1 + exp(-x))
  b <- compute_4pl_bounds(0, 1)
  set.seed(1)
  beta_low <- runif(500, -8, 8)
  beta_up  <- runif(500, -8, 8)
  low <- b$low_min + b$low_w * inv_logit(beta_low)
  up  <- b$up_min  + b$up_w  * inv_logit(beta_up)
  expect_true(all(low >= b$low_min & low <= b$low_max))  # low within its interval
  expect_true(all(up  >= b$up_min  & up  <= b$up_max))   # up within its interval
  expect_true(all(low > 0 & low < up & up < 1))          # disjoint split => low < up
})

test_that("fitted probability stays in (0, 1) across the design", {
  # forward map identical to src/profile_tls.cpp
  low <- 0.02; up <- 0.98; k <- 5; CTmax <- 36; z <- 3; tref <- 1
  grid <- expand.grid(temp = seq(20, 50, by = 1),
                      duration = c(0.1, 0.5, 1, 4, 24, 168))
  log10_tref <- log10(tref)
  mid <- log10_tref - (grid$temp - CTmax) / z
  eta <- k * (log10(grid$duration) - mid)
  p <- low + (up - low) * stats::plogis(-eta)
  expect_true(all(p > 0 & p < 1))
  # bounded by the asymptotes
  expect_true(all(p >= low - 1e-12 & p <= up + 1e-12))
})

test_that("midpoint equals log10(tref) when temp == CTmax", {
  for (tref in c(0.5, 1, 2)) {
    CTmax <- 36; z <- 4
    mid <- log10(tref) - (CTmax - CTmax) / z
    expect_equal(mid, log10(tref), tolerance = 1e-12)
  }
})

test_that("d mid / d temp == -1 / z", {
  z <- 3.7; CTmax <- 35; tref <- 1
  mid <- function(T) log10(tref) - (T - CTmax) / z
  # analytic slope
  expect_equal(-1 / z, (mid(31) - mid(30)) / (31 - 30), tolerance = 1e-12)
  # numeric derivative at a few temperatures
  h <- 1e-6
  for (T0 in c(30, 35, 40)) {
    num <- (mid(T0 + h) - mid(T0 - h)) / (2 * h)
    expect_equal(num, -1 / z, tolerance = 1e-6)
  }
})

test_that("survival is descending in duration and in temperature", {
  low <- 0.02; up <- 0.98; k <- 5; CTmax <- 36; z <- 3; tref <- 1
  p_of <- function(T, dur) {
    mid <- log10(tref) - (T - CTmax) / z
    eta <- k * (log10(dur) - mid)
    low + (up - low) * stats::plogis(-eta)
  }
  # longer exposure -> lower survival (fixed temp)
  durs <- c(0.5, 1, 2, 4, 8)
  p_dur <- p_of(36, durs)
  expect_true(all(diff(p_dur) < 0))
  # hotter -> lower survival (fixed duration)
  temps <- seq(30, 42, by = 2)
  p_temp <- p_of(temps, 2)
  expect_true(all(diff(p_temp) < 0))
})
