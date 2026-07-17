# Cross-checking freqTLS with bayesTLS

The packages teach the same canonical empirical examples but answer them
with different inference engines. `bayesTLS` uses posterior sampling;
`freqTLS` uses maximum likelihood with profile, Wald, or bootstrap
confidence intervals. Neither package’s uncertainty object is a drop-in
replacement for the other.

**Experimental-software warning:** this comparison does not validate
freqTLS. Users remain responsible for checking the data, design, model
specification, convergence, identifiability, diagnostics, and
interpretation. Independently refit important analyses with
[`bayesTLS`](https://daniel1noble.github.io/bayesTLS/). Agreement is a
cross-check, not proof of correctness; shared mistakes can make both
packages agree.

## Fair-comparison contract

A numerical difference is interpretable only when all of the following
are identical:

1.  exact dataset bytes and filter;
2.  response endpoint and family;
3.  every `ctmax`, `z`, `low`, `up`, and `k` formula;
4.  grouping and random-effect structure;
5.  resolved reference-time unit;
6.  relative or absolute threshold and reported estimand.

The pinned baseline is the [`bayesTLS`
supplement](https://daniel1noble.github.io/bayesTLS/) rendered
2026-07-14 from commit
[`76510412`](https://github.com/daniel1noble/bayesTLS/tree/76510412e06c594c96894a1baba1f0e1a34a5aea).

## Pinned comparator evidence

The curated cache was built on Totoro with four chains per fit, bounded
parallelism, and `OPENBLAS_NUM_THREADS=1`. Raw posterior fits remain
outside the repository. The cache records exact analysis hashes,
formulas, filters, thresholds, reference times, seeds, package versions,
both source commits, and sampler diagnostics.

``` r

data.frame(
  item = c(
    "bayesTLS", "freqTLS cache-build source", "CmdStan", "R", "built (UTC)",
    "OpenBLAS threads", "bounded cores"
  ),
  recorded_value = c(
    paste0(bayes_cache$meta$bayesTLS_version, " @ ",
           substr(bayes_cache$meta$bayesTLS_git_sha, 1, 12)),
    paste0("pre-release source @ ",
           substr(bayes_cache$meta$freqTLS_git_sha, 1, 12)),
    bayes_cache$meta$cmdstan_version,
    bayes_cache$meta$R_version,
    bayes_cache$meta$date_built_utc,
    bayes_cache$meta$openblas_num_threads,
    bayes_cache$meta$bounded_cores
  ),
  check.names = FALSE
)
#>                         item                    recorded_value
#> 1                   bayesTLS              1.0.0 @ 76510412e06c
#> 2 freqTLS cache-build source pre-release source @ b32c86001a7e
#> 3                    CmdStan                            2.39.0
#> 4                          R                             4.5.3
#> 5                built (UTC)           2026-07-16 15:48:18 UTC
#> 6           OpenBLAS threads                                 1
#> 7              bounded cores                                 4
```

Every Bayesian fit passed the recorded R-hat, effective-sample-size,
divergence, tree-depth, and BFMI gates.

``` r

bayes_cache$diagnostics[c(
  "case_id", "rhat_max", "ess_bulk_min", "ess_tail_min", "divergences",
  "treedepth_hits", "bfmi_min", "all_pass"
)]
#>                case_id rhat_max ess_bulk_min ess_tail_min divergences
#> 1     zebrafish_oxygen   1.0017         2507         1750           0
#> 2           aphid_age6   1.0016         3546         4500           0
#> 3        aphid_all_age   1.0019         2205         3027           0
#> 4         snowgum_psii   1.0009         3432         4687           0
#> 5 drosophila_mortality   1.0014         2822         4680           0
#> 6     drosophila_awake   1.0013         2964         4053           0
#>   treedepth_hits bfmi_min all_pass
#> 1              0   0.8577     TRUE
#> 2              0   0.9824     TRUE
#> 3              0   0.9556     TRUE
#> 4              0   0.8033     TRUE
#> 5              0   0.8929     TRUE
#> 6              0   0.9163     TRUE
```

## Refit the same frequentist specifications

The code below refits the exact current freqTLS specifications from the
installed datasets. The fitting output is suppressed because the
diagnostic table follows, but the code remains visible and copyable. The
five case articles explain each preparation and fit in smaller steps.

``` r

data(zebrafish_o2)
zf <- droplevels(subset(
  zebrafish_o2,
  ploidy == "diploid" & oxygen %in% c("normoxia", "hyperoxia")
))
zf_fit <- fit_4pl(
  standardize_data(
    zf, temp = "temp", duration = "duration_min",
    n_total = "n_total", n_surv = "n_surv", duration_unit = "minutes"
  ),
  ctmax = ~ 0 + oxygen, z = ~ 0 + oxygen, low = ~ 0 + oxygen,
  up = ~ 1, k = ~ 1, family = "beta_binomial", t_ref = 60,
  method = "wald", quiet = TRUE
)

data(aphid_tdt)
aphid6 <- droplevels(subset(aphid_tdt, branch == "heat" & age == "6"))
aphid6_fit <- fit_4pl(
  standardize_data(
    aphid6, temp = "temp", duration = "duration_min",
    n_total = "n_total", n_surv = "n_surv", duration_unit = "minutes"
  ),
  ctmax = ~ 0 + species, z = ~ 0 + species, low = ~ 1, up = ~ 1,
  k = ~ temp_c, family = "beta_binomial", t_ref = 60,
  method = "wald", quiet = TRUE
)

aphid_all <- droplevels(subset(aphid_tdt, branch == "heat"))
aphid_all_std <- standardize_data(
  aphid_all, temp = "temp", duration = "duration_min",
  n_total = "n_total", n_surv = "n_surv", duration_unit = "minutes"
)
aphid_all_fit <- fit_4pl(
  aphid_all_std,
  ctmax = ~ 1 + species * age, z = ~ 1 + species * age,
  low = ~ 1, up = ~ 1, k = ~ temp_c, family = "beta_binomial",
  t_ref = 60, method = "wald", quiet = TRUE
)

data(snowgum_psii)
snowgum_fit <- fit_4pl(
  standardize_data(
    snowgum_psii, temp = "Temp", duration = "Time",
    proportion = "fvfm_prop", duration_unit = "minutes"
  ),
  ctmax = ~ 0 + recovery + (1 | plant), z = ~ 0 + recovery,
  low = ~ 1, up = ~ 1, k = ~ 1, family = "beta", t_ref = 60,
  method = "wald", quiet = TRUE
)

data(dsuzukii)
mort <- stats::aggregate(
  cbind(
    n_dead = as.integer(dsuzukii$dead),
    n_total = rep.int(1L, nrow(dsuzukii))
  ) ~ temp + time + sex,
  data = dsuzukii,
  FUN = sum
)
mort$n_surv <- mort$n_total - mort$n_dead
mort_fit <- fit_4pl(
  standardize_data(
    mort, temp = "temp", duration = "time",
    n_total = "n_total", n_surv = "n_surv", duration_unit = "minutes"
  ),
  ctmax = ~ 0 + sex, z = ~ 0 + sex,
  low = ~ temp_c, up = ~ temp_c, k = ~ temp_c,
  family = "beta_binomial", t_ref = 240, method = "wald", quiet = TRUE
)

coma_cell <- interaction(
  dsuzukii$temp, dsuzukii$lvl, dsuzukii$sex, drop = TRUE
)
coma <- do.call(rbind, lapply(split(dsuzukii, coma_cell), function(d) {
  data.frame(
    temp = d$temp[1], lvl = d$lvl[1], sex = d$sex[1],
    duration = d$time[1], n_total = nrow(d),
    n_awake = sum(is.na(d$t_coma))
  )
}))
coma <- droplevels(subset(coma, duration > 0))
coma_fit <- fit_4pl(
  standardize_data(
    coma, temp = "temp", duration = "duration",
    n_total = "n_total", n_surv = "n_awake", duration_unit = "minutes"
  ),
  ctmax = ~ sex, z = ~ sex,
  low = ~ temp_c, up = ~ temp_c, k = ~ temp_c,
  family = "beta_binomial", t_ref = 60, method = "wald", quiet = TRUE
)
```

All displayed ML fits converged with a positive-definite Hessian and
passed the package’s raw-gradient gate. The interval method for the
direct-coordinate rows below is Wald; the all-age aphid cell values and
mortality absolute-LT50 values are point predictions and are labelled
accordingly. Shape-identification warnings remain visible in the
organism-specific articles.

``` r

fit_list <- list(
  zebrafish_oxygen = zf_fit,
  aphid_age6 = aphid6_fit,
  aphid_all_age = aphid_all_fit,
  snowgum_psii = snowgum_fit,
  drosophila_mortality = mort_fit,
  drosophila_awake = coma_fit
)
freq_diagnostics <- do.call(rbind, lapply(names(fit_list), function(case_id) {
  ans <- diagnose_tdt_fit(fit_list[[case_id]])
  data.frame(
    case_id = case_id,
    converged = ans$converged,
    pd_hessian = ans$pd_hessian,
    max_abs_gradient = ans$max_abs_gradient,
    gradient_pass = ans$gradient_pass,
    interval_method = if (case_id == "aphid_all_age") {
      "ML point prediction"
    } else if (case_id == "drosophila_mortality") {
      "Wald direct coordinates; absolute LT50 point only"
    } else {
      "Wald 95% confidence interval"
    }
  )
}))
rownames(freq_diagnostics) <- NULL
freq_diagnostics
#>                case_id converged pd_hessian max_abs_gradient gradient_pass
#> 1     zebrafish_oxygen      TRUE       TRUE     1.948692e-04          TRUE
#> 2           aphid_age6      TRUE       TRUE     2.091929e-06          TRUE
#> 3        aphid_all_age      TRUE       TRUE     9.832409e-06          TRUE
#> 4         snowgum_psii      TRUE       TRUE     2.898515e-04          TRUE
#> 5 drosophila_mortality      TRUE       TRUE     7.996796e-05          TRUE
#> 6     drosophila_awake      TRUE       TRUE     1.204766e-05          TRUE
#>                                     interval_method
#> 1                      Wald 95% confidence interval
#> 2                      Wald 95% confidence interval
#> 3                               ML point prediction
#> 4                      Wald 95% confidence interval
#> 5 Wald direct coordinates; absolute LT50 point only
#> 6                      Wald 95% confidence interval
```

## Actual paired differences

The primary table compares the frequentist point estimate with the
Bayesian posterior median. Positive values mean the freqTLS estimate is
larger. The interval columns are shown side by side without pretending
that a confidence interval and a credible interval have the same
interpretation.

``` r

as_freq_rows <- function(fit, case_id, by, endpoint, t_ref) {
  out <- tls(fit, by = by, lethal = FALSE, method = "wald")$summary
  data.frame(
    case_id = case_id,
    endpoint = endpoint,
    threshold = "relative",
    t_ref = t_ref,
    group = as.character(out[[by]]),
    parameter = out$quantity,
    freq_estimate = out$median,
    freq_lower = out$lower,
    freq_upper = out$upper,
    freq_interval = "Wald 95% confidence interval"
  )
}

freq_rows <- rbind(
  as_freq_rows(
    zf_fit, "zebrafish_oxygen", "oxygen", "survival counts", 60
  ),
  as_freq_rows(
    aphid6_fit, "aphid_age6", "species", "survival counts", 60
  ),
  as_freq_rows(
    snowgum_fit, "snowgum_psii", "recovery",
    "retained PSII function proportion", 60
  ),
  as_freq_rows(
    coma_fit, "drosophila_awake", "sex",
    "awake counts (missing t_coma)", 60
  )
)

bayes_rows <- bayes_cache$summaries
bayes_rows$group <- ifelse(
  !is.na(bayes_rows$oxygen), as.character(bayes_rows$oxygen),
  ifelse(
    !is.na(bayes_rows$recovery), as.character(bayes_rows$recovery),
    ifelse(
      !is.na(bayes_rows$sex), as.character(bayes_rows$sex),
      as.character(bayes_rows$species)
    )
  )
)

paired <- merge(
  freq_rows,
  bayes_rows[c(
    "case_id", "endpoint", "threshold", "t_ref", "group", "parameter",
    "median", "lower", "upper", "interval_method"
  )],
  by = c("case_id", "endpoint", "threshold", "t_ref", "group", "parameter"),
  all = FALSE,
  sort = FALSE
)
names(paired)[names(paired) == "median"] <- "bayes_median"
names(paired)[names(paired) == "lower"] <- "bayes_lower"
names(paired)[names(paired) == "upper"] <- "bayes_upper"
names(paired)[names(paired) == "interval_method"] <- "bayes_interval"
paired$difference_freq_minus_bayes <- paired$freq_estimate - paired$bayes_median
stopifnot(nrow(paired) == 18L)

paired[c(
  "case_id", "endpoint", "threshold", "t_ref", "group", "parameter",
  "freq_estimate", "freq_lower", "freq_upper", "bayes_median",
  "bayes_lower", "bayes_upper", "difference_freq_minus_bayes"
)]
#>             case_id                          endpoint threshold t_ref
#> 1  zebrafish_oxygen                   survival counts  relative    60
#> 2  zebrafish_oxygen                   survival counts  relative    60
#> 3  zebrafish_oxygen                   survival counts  relative    60
#> 4  zebrafish_oxygen                   survival counts  relative    60
#> 5        aphid_age6                   survival counts  relative    60
#> 6        aphid_age6                   survival counts  relative    60
#> 7        aphid_age6                   survival counts  relative    60
#> 8        aphid_age6                   survival counts  relative    60
#> 9        aphid_age6                   survival counts  relative    60
#> 10       aphid_age6                   survival counts  relative    60
#> 11     snowgum_psii retained PSII function proportion  relative    60
#> 12     snowgum_psii retained PSII function proportion  relative    60
#> 13     snowgum_psii retained PSII function proportion  relative    60
#> 14     snowgum_psii retained PSII function proportion  relative    60
#> 15 drosophila_awake     awake counts (missing t_coma)  relative    60
#> 16 drosophila_awake     awake counts (missing t_coma)  relative    60
#> 17 drosophila_awake     awake counts (missing t_coma)  relative    60
#> 18 drosophila_awake     awake counts (missing t_coma)  relative    60
#>         group parameter freq_estimate freq_lower freq_upper bayes_median
#> 1    normoxia     CTmax     38.739774  38.431850  39.047698    38.889462
#> 2   hyperoxia     CTmax     39.301410  39.059733  39.543086    39.348350
#> 3    normoxia         z      6.005753   4.371361   8.251220     5.586819
#> 4   hyperoxia         z      2.500556   2.139219   2.922927     2.488053
#> 5  M_dirhodum     CTmax     35.215425  35.025354  35.405496    35.172826
#> 6    S_avenae     CTmax     36.527458  36.431472  36.623444    36.508723
#> 7      R_padi     CTmax     37.169857  37.063139  37.276575    37.145179
#> 8  M_dirhodum         z      4.747335   4.505357   5.002309     4.775438
#> 9    S_avenae         z      3.609898   3.460681   3.765549     3.623531
#> 10     R_padi         z      3.965377   3.698215   4.251839     3.958519
#> 11       Dark     CTmax     45.720851  45.178128  46.263574    45.694884
#> 12      Light     CTmax     44.075183  43.557764  44.592603    44.053744
#> 13       Dark         z      4.707002   4.289897   5.164663     4.673517
#> 14      Light         z      3.640602   3.201761   4.139591     3.624133
#> 15          F     CTmax     36.497021  36.392973  36.601068    36.480047
#> 16          M     CTmax     36.295991  36.203030  36.388953    36.269671
#> 17          F         z      2.432835   2.288082   2.586746     2.413440
#> 18          M         z      2.393259   2.261891   2.532257     2.404374
#>    bayes_lower bayes_upper difference_freq_minus_bayes
#> 1    38.557733   39.374728                 -0.14968745
#> 2    39.169796   39.499437                 -0.04694048
#> 3     4.055890    7.754303                  0.41893351
#> 4     2.048057    2.932714                  0.01250305
#> 5    34.971922   35.352795                  0.04259915
#> 6    36.410246   36.599680                  0.01873529
#> 7    37.043699   37.250706                  0.02467830
#> 8     4.529840    5.043446                 -0.02810253
#> 9     3.470673    3.780992                 -0.01363301
#> 10    3.685519    4.247040                  0.00685783
#> 11   45.045874   46.290603                  0.02596675
#> 12   43.433298   44.697975                  0.02143955
#> 13    4.229605    5.122288                  0.03348486
#> 14    3.178338    4.105518                  0.01646914
#> 15   36.362822   36.586969                  0.01697342
#> 16   36.158873   36.372444                  0.02632053
#> 17    2.253667    2.581269                  0.01939477
#> 18    2.259329    2.568861                 -0.01111458
```

The age-six aphid row is also one cell of the all-age extension, but the
two fits are intentionally distinct. For all nine species-by-age cells,
the largest absolute freqTLS-minus-bayesTLS point difference is reported
separately rather than printing another 18-row table.

``` r

aphid_cells <- expand.grid(
  species = levels(aphid_all$species),
  age = levels(aphid_all$age),
  temp = mean(aphid_all_std$temp),
  KEEP.OUT.ATTRS = FALSE
)
aphid_pred <- predict(aphid_all_fit, aphid_cells, type = "parameters")
aphid_freq <- rbind(
  data.frame(
    species = aphid_cells$species, age = aphid_cells$age,
    parameter = "CTmax", freq_estimate = aphid_pred$CTmax
  ),
  data.frame(
    species = aphid_cells$species, age = aphid_cells$age,
    parameter = "z", freq_estimate = aphid_pred$z
  )
)
aphid_bayes <- subset(bayes_rows, case_id == "aphid_all_age")
aphid_join <- merge(
  aphid_freq,
  aphid_bayes[c("species", "age", "parameter", "median")],
  by = c("species", "age", "parameter")
)
aphid_join$difference_freq_minus_bayes <-
  aphid_join$freq_estimate - aphid_join$median
stopifnot(nrow(aphid_join) == 18L)
aggregate(
  abs(difference_freq_minus_bayes) ~ parameter,
  data = aphid_join,
  FUN = max
)
#>   parameter abs(difference_freq_minus_bayes)
#> 1     CTmax                       0.02725888
#> 2         z                       0.02246847
```

Snow-gum is a paired refit of the locked shared-shape analogue. It is
not a claim that freqTLS reproduces the richer recovery-by-temperature
shape model displayed in the pinned supplement.

### Drosophila mortality: do not mix estimands

The pinned mortality summary uses the absolute 50% threshold. The direct
freqTLS `CTmax` and `z` coordinates are relative-midpoint quantities, so
they must not be subtracted from the Bayesian absolute values. Only the
absolute 240-minute LT50 point is comparable without silently changing
the estimand.

``` r

mort_lt50 <- data.frame(
  group = mort_fit$fit$group_levels,
  freq_estimate = vapply(mort_fit$fit$group_levels, function(sex_level) {
    temp_grid <- seq(min(mort$temp), max(mort$temp), length.out = 1001)
    grid_difference <- predict(
      mort_fit,
      data.frame(temp = temp_grid, duration = 240, group = sex_level),
      type = "survival"
    ) - 0.5
    crossing <- which(
      grid_difference[-length(grid_difference)] *
        grid_difference[-1L] <= 0
    )
    stopifnot(length(crossing) == 1L)
    objective <- function(temp) {
      predict(
        mort_fit,
        data.frame(temp = temp, duration = 240, group = sex_level),
        type = "survival"
      ) - 0.5
    }
    uniroot(
      objective,
      temp_grid[c(crossing, crossing + 1L)],
      tol = 1e-10
    )$root
  }, numeric(1))
)
mort_bayes <- subset(
  bayes_rows,
  case_id == "drosophila_mortality" & parameter == "CTmax"
)
mort_compare <- merge(
  mort_lt50,
  mort_bayes[c("group", "median", "lower", "upper")],
  by = "group"
)
names(mort_compare)[names(mort_compare) == "median"] <- "bayes_median"
mort_compare$difference_freq_minus_bayes <-
  mort_compare$freq_estimate - mort_compare$bayes_median
mort_compare$freq_interval <- "none: exact-model bootstrap unstable"
stopifnot(nrow(mort_compare) == 2L)
mort_compare
#>   group freq_estimate bayes_median    lower    upper
#> 1     F      35.15584     35.13553 35.01181 35.24284
#> 2     M      35.17396     35.16390 35.04825 35.26617
#>   difference_freq_minus_bayes                        freq_interval
#> 1                  0.02031098 none: exact-model bootstrap unstable
#> 2                  0.01005650 none: exact-model bootstrap unstable
```

The Bayesian cache also contains absolute-threshold `z`. freqTLS does
not print an allegedly equivalent absolute `z` from this
temperature-varying shape model; its direct `z` remains the relative
coordinate. The mortality case article shows that relative result
explicitly.

## What agreement means

Maximum-likelihood estimates and posterior medians need not be
numerically identical. Priors, finite-sample skew, boundary behaviour,
random effects, and weak identification can produce legitimate
differences. The audit confirms the data and model specification first,
reports the actual difference, and never averages estimates or hides a
discrepancy.

## Frequentist extensions and unsupported analyses

Confidence Eyes, open-profile status, likelihood contrasts, bootstrap
failure provenance, and explicit convergence/Hessian/gradient
diagnostics are freqTLS distinctions. Simulations, profile theory,
survival surfaces, limited random intercepts, and deterministic
heat-injury scenarios remain separate extension pages with synthetic
examples.

Censored-time, hurdle-productivity, posterior inference, and fitted
repair dynamics remain bayesTLS-only. Brown shrimp and life-stage
zebrafish remain unpublished benchmark-only compatibility fixtures and
do not enter this comparison, site navigation, search results, sitemap,
or current summaries.
