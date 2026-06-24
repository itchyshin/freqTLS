# The shipped case-study datasets (twinned from bayesTLS). Raw form: each needs
# standardize_data() before fitting. These checks pin the column contract the
# case studies and standardize_data() examples rely on.

test_that("all seven case-study datasets load with their key columns", {
  spec <- list(
    shrimp_lethal    = c("Temperature_assay", "Duration_exposure_hours",
                         "N_individuals_after_trial", "Mortality_after_trial"),
    shrimp_sublethal = c("assay_temp", "time_to_event"),
    zebrafish_lethal = c("assay_temp", "duration_h", "n_total", "n_surv", "life_stage"),
    snowgum_psii     = c("Temp", "Time", "fvfm_prop"),
    dsuzukii         = c("temp", "time", "sex", "dead"),
    zebrafish_o2     = c("oxygen", "temp", "duration_min", "n_total", "n_surv"),
    aphid_tdt        = c("species", "age", "branch", "temp", "duration_min",
                         "n_total", "n_surv")
  )
  for (nm in names(spec)) {
    obj <- get(nm, envir = asNamespace("freqTLS"))
    expect_s3_class(obj, "data.frame")
    expect_gt(nrow(obj), 0L)
    expect_true(all(spec[[nm]] %in% names(obj)),
                info = paste(nm, "missing:",
                             paste(setdiff(spec[[nm]], names(obj)), collapse = ", ")))
  }
})

test_that("the two new datasets carry the documented grouping levels", {
  expect_setequal(levels(factor(zebrafish_o2$oxygen)),
                  c("hypoxia", "normoxia", "hyperoxia"))
  expect_setequal(levels(factor(aphid_tdt$species)),
                  c("M_dirhodum", "R_padi", "S_avenae"))
  expect_true(all(c("heat", "cold") %in% levels(factor(aphid_tdt$branch))))
})
