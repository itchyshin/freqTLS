test_that("canonical dataset bytes and subsets are pinned", {
  data_dir <- test_path("..", "..", "data")
  expected_md5 <- c(
    aphid_tdt.rda = "f759d63fe771afe8f0a2b61f5329eba5",
    dsuzukii.rda = "7e8f0813293ed74854585f49516a8dfb",
    zebrafish_o2.rda = "6d1e9b7701ca070a6e6d45f636ecb0d4",
    snowgum_psii.rda = "78b081de3a71f0eb3274bd473d42e538"
  )
  data_paths <- file.path(data_dir, names(expected_md5))
  if (all(file.exists(data_paths))) {
    actual <- unname(tools::md5sum(data_paths))
    expect_identical(actual, unname(expected_md5))
  }

  zf <- droplevels(subset(
    zebrafish_o2,
    ploidy == "diploid" & oxygen %in% c("normoxia", "hyperoxia")
  ))
  expect_identical(nrow(zf), 380L)
  expect_identical(levels(zf$oxygen), c("normoxia", "hyperoxia"))
  expect_identical(sort(unique(zf$temp)), c(26, 38, 39, 40))

  aphid6 <- droplevels(subset(aphid_tdt, branch == "heat" & age == "6"))
  aphid_all <- droplevels(subset(aphid_tdt, branch == "heat"))
  expect_identical(nrow(aphid6), 499L)
  expect_identical(nrow(aphid_all), 1503L)
  expect_identical(nrow(snowgum_psii), 394L)
  expect_identical(length(unique(snowgum_psii$plant)), 6L)
})

test_that("Drosophila mortality and coma endpoints use the pinned aggregations", {
  mort <- stats::aggregate(
    cbind(n_dead = as.integer(dsuzukii$dead),
          n_total = rep.int(1L, nrow(dsuzukii))) ~ temp + time + sex,
    data = dsuzukii,
    FUN = sum
  )
  expect_identical(nrow(mort), 94L)
  expect_identical(sum(mort$n_total), 1407L)
  expect_identical(sum(mort$n_dead), 622L)

  cell <- interaction(dsuzukii$temp, dsuzukii$lvl, dsuzukii$sex, drop = TRUE)
  coma <- do.call(rbind, lapply(split(dsuzukii, cell), function(d) {
    data.frame(
      temp = d$temp[1], lvl = d$lvl[1], sex = d$sex[1],
      duration = d$time[1], n_total = nrow(d),
      n_awake = sum(is.na(d$t_coma))
    )
  }))
  coma <- droplevels(subset(coma, duration > 0))
  expect_identical(nrow(coma), 94L)
  expect_identical(sum(coma$n_total), 1407L)
  expect_identical(sum(coma$n_awake), 583L)
  expect_true(all(coma$duration > 0))
})

test_that("canonical case formulas fit and report only CTmax and z", {
  zf <- droplevels(subset(
    zebrafish_o2,
    ploidy == "diploid" & oxygen %in% c("normoxia", "hyperoxia")
  ))
  zf_std <- standardize_data(
    zf, temp = "temp", duration = "duration_min",
    n_total = "n_total", n_surv = "n_surv", duration_unit = "minutes"
  )
  zf_fit <- suppressWarnings(fit_4pl(
    zf_std, ctmax = ~ 0 + oxygen, z = ~ 0 + oxygen,
    low = ~ 0 + oxygen, up = ~ 1, k = ~ 1,
    family = "beta_binomial", t_ref = 60, method = "wald", quiet = TRUE
  ))

  aphid6 <- droplevels(subset(aphid_tdt, branch == "heat" & age == "6"))
  aphid_std <- standardize_data(
    aphid6, temp = "temp", duration = "duration_min",
    n_total = "n_total", n_surv = "n_surv", duration_unit = "minutes"
  )
  aphid_fit <- suppressWarnings(fit_4pl(
    aphid_std, ctmax = ~ 0 + species, z = ~ 0 + species,
    low = ~ 1, up = ~ 1, k = ~ temp_c,
    family = "beta_binomial", t_ref = 60, method = "wald", quiet = TRUE
  ))
  aphid_all <- droplevels(subset(aphid_tdt, branch == "heat"))
  aphid_all_std <- standardize_data(
    aphid_all, temp = "temp", duration = "duration_min",
    n_total = "n_total", n_surv = "n_surv", duration_unit = "minutes"
  )
  aphid_all_fit <- suppressWarnings(fit_4pl(
    aphid_all_std, ctmax = ~ 1 + species * age,
    z = ~ 1 + species * age,
    low = ~ 1, up = ~ 1, k = ~ temp_c,
    family = "beta_binomial", t_ref = 60, method = "wald", quiet = TRUE
  ))

  leaf_std <- suppressWarnings(standardize_data(
    snowgum_psii, temp = "Temp", duration = "Time",
    proportion = "fvfm_prop", duration_unit = "minutes"
  ))
  leaf_fit <- suppressWarnings(fit_4pl(
    leaf_std, ctmax = ~ 0 + recovery + (1 | plant), z = ~ 0 + recovery,
    low = ~ 1, up = ~ 1, k = ~ 1,
    family = "beta", t_ref = 60, method = "wald", quiet = TRUE
  ))

  for (fit in list(zf_fit, aphid_fit, aphid_all_fit, leaf_fit)) {
    expect_identical(fit$fit$convergence$code, 0L)
    expect_true(fit$fit$convergence$pdHess)
    expect_true(diagnose_tdt_fit(fit)$gradient_pass)
    q <- tls(fit, lethal = FALSE, method = "wald")$summary$quantity
    expect_setequal(unique(q), c("CTmax", "z"))
    expect_false("Tcrit" %in% q)
  }
  expect_true("sigma_CTmax" %in% leaf_fit$fit$estimates$parameter)
  expect_s3_class(plot_tdt_curve(aphid_fit$fit), "ggplot")
  aphid_cells <- expand.grid(
    species = levels(aphid_all$species), age = levels(aphid_all$age),
    temp = mean(aphid_all_std$temp), KEEP.OUT.ATTRS = FALSE
  )
  cell_pars <- predict(aphid_all_fit, aphid_cells, type = "parameters")
  expect_identical(nrow(cell_pars), 9L)
  expect_true(all(is.finite(as.matrix(cell_pars[c("CTmax", "z")]))))
})

test_that("both Drosophila direct models fit the locked endpoints", {
  mort <- stats::aggregate(
    cbind(n_dead = as.integer(dsuzukii$dead),
          n_total = rep.int(1L, nrow(dsuzukii))) ~ temp + time + sex,
    data = dsuzukii, FUN = sum
  )
  mort$n_surv <- mort$n_total - mort$n_dead
  mort_std <- standardize_data(
    mort, temp = "temp", duration = "time",
    n_total = "n_total", n_surv = "n_surv", duration_unit = "minutes"
  )
  mort_fit <- suppressWarnings(fit_4pl(
    mort_std, ctmax = ~ 0 + sex, z = ~ 0 + sex,
    low = ~ temp_c, up = ~ temp_c, k = ~ temp_c,
    family = "beta_binomial", t_ref = 240, method = "wald", quiet = TRUE
  ))

  cell <- interaction(dsuzukii$temp, dsuzukii$lvl, dsuzukii$sex, drop = TRUE)
  coma <- do.call(rbind, lapply(split(dsuzukii, cell), function(d) {
    data.frame(temp = d$temp[1], lvl = d$lvl[1], sex = d$sex[1],
               duration = d$time[1], n_total = nrow(d),
               n_awake = sum(is.na(d$t_coma)))
  }))
  coma <- droplevels(subset(coma, duration > 0))
  coma_std <- standardize_data(
    coma, temp = "temp", duration = "duration",
    n_total = "n_total", n_surv = "n_awake", duration_unit = "minutes"
  )
  coma_fit <- suppressWarnings(fit_4pl(
    coma_std, ctmax = ~ sex, z = ~ sex,
    low = ~ temp_c, up = ~ temp_c, k = ~ temp_c,
    family = "beta_binomial", t_ref = 60, method = "wald", quiet = TRUE
  ))

  for (fit in list(mort_fit, coma_fit)) {
    expect_identical(fit$fit$convergence$code, 0L)
    expect_true(fit$fit$convergence$pdHess)
    q <- tls(fit, by = "sex", lethal = FALSE, method = "wald")$summary$quantity
    expect_setequal(unique(q), c("CTmax", "z"))
    expect_false("Tcrit" %in% q)
  }
  expect_identical(mort_fit$meta$t_ref, 240)
  expect_identical(coma_fit$meta$t_ref, 60)

  lt50 <- vapply(mort_fit$fit$group_levels, function(sex_level) {
    objective <- function(temp) {
      predict(
        mort_fit,
        data.frame(temp = temp, duration = 240, group = sex_level),
        type = "survival"
      ) - 0.5
    }
    stats::uniroot(objective, range(mort$temp), tol = 1e-10)$root
  }, numeric(1))
  expect_true(all(is.finite(lt50)))
  expect_true(all(lt50 > min(mort$temp) & lt50 < max(mort$temp)))
  for (i in seq_along(lt50)) {
    p <- predict(
      mort_fit,
      data.frame(temp = lt50[[i]], duration = 240,
                 group = mort_fit$fit$group_levels[[i]]),
      type = "survival"
    )
    expect_equal(unname(p), 0.5, tolerance = 1e-6)
  }
})

test_that("active navigation excludes benchmark-only teaching fixtures", {
  cfg_path <- test_path("..", "..", "_pkgdown.yml")
  vignette_dir <- test_path("..", "..", "vignettes")
  skip_if_not(
    file.exists(cfg_path) && dir.exists(vignette_dir),
    "pkgdown and vignette source are excluded from the built package"
  )
  cfg <- paste(readLines(cfg_path, warn = FALSE),
               collapse = "\n")
  canonical_nav <- sub(".*- title: Canonical empirical examples", "", cfg)
  canonical_nav <- sub("- title: Frequentist extensions.*", "", canonical_nav)
  expect_false(grepl("case-study-shrimp", canonical_nav, fixed = TRUE))
  expect_match(cfg, "Legacy notices", fixed = TRUE)
  expect_false(grepl("shrimp_lethal", cfg, fixed = TRUE))
  expect_false(grepl("shrimp_sublethal", cfg, fixed = TRUE))
  expect_false(grepl("zebrafish_lethal", cfg, fixed = TRUE))

  active <- c(
    "case-study-zebrafish.Rmd", "case-study-li-aphids.Rmd",
    "case-study-snowgum.Rmd", "case-study-suzukii.Rmd",
    "case-study-suzukii-coma.Rmd", "case-study-summary.Rmd"
  )
  txt <- paste(unlist(lapply(file.path(vignette_dir, active),
                            readLines, warn = FALSE)), collapse = "\n")
  expect_false(grepl("data(shrimp", txt, fixed = TRUE))
  expect_false(grepl("data(zebrafish_lethal", txt, fixed = TRUE))
  expect_false(grepl("tls_tcrit", txt, fixed = TRUE))
  expect_false(grepl("derive_tcrit", txt, fixed = TRUE))
})
