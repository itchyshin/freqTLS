# extract_tdt() + accessors — the bayesTLS-twin comprehensive extractor
# (parametric-bootstrap replicates as the per-draw analogue). Small nboot for
# speed; these check structure, the column contract, and basic recovery.

std_sim <- function(seed = 1, ...) {
  standardize_data(simulate_tls(family = "binomial", seed = seed, ...),
                   temp = "temp", duration = "duration",
                   n_total = "total", n_surv = "survived")
}

test_that("extract_tdt returns nested z/CTmax with the bayesTLS column contract", {
  f <- fit_4pl(std_sim(1, CTmax = 36, z = 4), t_ref = 1, family = "binomial",
               quiet = TRUE)
  et <- suppressWarnings(extract_tdt(f, nboot = 60, seed = 1))
  expect_s3_class(et, "freq_tdt")
  expect_named(et, c("z", "CTmax", "T_crit", "meta"))
  expect_null(et$T_crit)
  expect_setequal(names(get_z_summary(et)), c("z_median", "z_lower", "z_upper"))
  expect_setequal(names(get_ctmax_summary(et)),
                  c("temp_median", "temp_lower", "temp_upper"))
  expect_true("z" %in% names(get_z_draws(et)))
  expect_true("CTmax" %in% names(get_ctmax_draws(et)))   # temp -> CTmax rename
  s <- get_ctmax_summary(et)
  expect_equal(s$temp_median, 36, tolerance = 0.3)
  expect_true(s$temp_lower < s$temp_median && s$temp_median < s$temp_upper)
  expect_equal(nrow(get_z_draws(et)), et$meta$nboot)
})

test_that("extract_tdt groups and adds T_crit (below CTmax) when lethal", {
  d <- simulate_tls(family = "binomial", group = c("A", "B"),
                    CTmax = c(34, 38), z = c(3, 5), seed = 3)
  s <- standardize_data(d, temp = "temp", duration = "duration",
                        n_total = "total", n_surv = "survived")
  f <- suppressWarnings(fit_4pl(s, ctmax = ~ 0 + group, z = ~ 0 + group,
                                t_ref = 1, family = "binomial", quiet = TRUE))
  et <- suppressWarnings(extract_tdt(f, lethal = TRUE, nboot = 60, seed = 1))
  zs <- get_z_summary(et)
  expect_true("group" %in% names(zs))
  expect_setequal(unique(zs$group), c("A", "B"))
  expect_equal(nrow(zs), 2L)
  expect_true(all(get_tcrit_summary(et)$temp_median <
                  get_ctmax_summary(et)$temp_median))   # T_crit < CTmax
  expect_true("T_crit" %in% names(get_tcrit_draws(et))) # temp -> T_crit rename
})

test_that("get_tcrit errors without lethal; absolute ~= relative for symmetric data", {
  f <- fit_4pl(std_sim(2, CTmax = 36, z = 4, low = 0.02, up = 0.98), t_ref = 1,
               family = "binomial", quiet = TRUE)
  et <- suppressWarnings(extract_tdt(f, nboot = 40, seed = 1))
  expect_error(get_tcrit_summary(et), "lethal")
  eta <- suppressWarnings(extract_tdt(f, target_surv = "absolute",
                                      nboot = 40, seed = 1))
  expect_equal(get_ctmax_summary(eta)$temp_median,
               get_ctmax_summary(et)$temp_median, tolerance = 0.2)
  expect_match(eta$meta$target_surv, "p=0.500")
})
