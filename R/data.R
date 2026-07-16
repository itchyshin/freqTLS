# Documentation for the case-study datasets shipped with freqTLS.
# The datasets are derived from the raw CSVs in inst/extdata/ using the
# transformations recorded in the component ledger and each help topic. Each is
# analysis-ready for standardize_data() -> fit_4pl() -> extract_tdt().

#' Brown shrimp lethal thermal-death-time data
#'
#' Replicate lethal-TDT trials for brown shrimp (\emph{Crangon crangon}). Each
#' row is one tank of individuals exposed to a fixed assay temperature for a
#' fixed duration; the response is the proportion that died. The model-ready
#' fixture retained for compatibility benchmarking. It is unpublished and is
#' not an active teaching example.
#'
#' @format A data frame with 148 rows and 6 variables:
#' \describe{
#'   \item{Date}{Experiment date (use as a grouping factor).}
#'   \item{Tank}{Holding-tank identifier (use as a grouping factor).}
#'   \item{Temperature_assay}{Assay temperature (degrees C).}
#'   \item{Duration_exposure_hours}{Exposure duration (hours).}
#'   \item{N_individuals_after_trial}{Number of individuals in the trial.}
#'   \item{Mortality_after_trial}{Proportion that died during the trial
#'         (deaths / \code{N_individuals_after_trial}), in the unit interval.
#'         Consumed by
#'         \code{standardize_data(mortality = "Mortality_after_trial")}.}
#' }
#' @source Brown shrimp lethal-TDT assay (Case Study 1), obtained from the
#'   \pkg{bayesTLS} package distribution by Noble, Arnold, and Pottier (2026),
#'   licensed CC BY 4.0. freqTLS retains the mortality proportion and documents
#'   its count reconstruction above. Raw file:
#'   \code{system.file("extdata", "data_lethal_TDT_brown_shrimp.csv", package = "freqTLS")}.
#' @keywords datasets internal
"shrimp_lethal"

#' Brown shrimp sublethal time-to-knockdown data
#'
#' Sublethal TDT trials for brown shrimp (\emph{Crangon crangon}): each cup of
#' individuals contributes the elapsed time to loss of response to touch
#' (knockdown) at a fixed assay temperature. Cleaned from the raw clock-time
#' records (excluded rows dropped; start/stop times parsed to elapsed minutes).
#' This unpublished object is retained only for compatibility benchmarking.
#'
#' @format A data frame with 299 rows and 5 variables:
#' \describe{
#'   \item{assay_temp}{Assay temperature (degrees C).}
#'   \item{time_to_event}{Time to knockdown (minutes).}
#'   \item{date_experiment}{Experiment date (grouping factor).}
#'   \item{tank_ID}{Holding-tank identifier (grouping factor).}
#'   \item{cup_ID}{Cup identifier, \code{Trial_ID_Sample} (grouping factor).}
#' }
#' @source Brown shrimp sublethal time-to-knockdown assay (Case Study 1,
#'   sublethal endpoint), obtained from the \pkg{bayesTLS} package distribution
#'   by Noble, Arnold, and Pottier (2026), licensed CC BY 4.0. freqTLS dropped
#'   excluded rows and converted the clock times to elapsed minutes. Raw file:
#'   \code{system.file("extdata", "data_sublethal_TDT_brown_shrimp.csv", package = "freqTLS")}.
#' @keywords datasets internal
"shrimp_sublethal"

#' Zebrafish lethal thermal-death-time data across life stages
#'
#' Lethal-TDT trials for zebrafish (\emph{Danio rerio}) at three life stages.
#' Built from the raw daily survival sheet by summing the per-day
#' morning/afternoon mortality counts into one death count per trial and dropping
#' excluded rows. One row per assay trial. This unpublished life-stage object is
#' retained only for compatibility benchmarking; the active zebrafish example
#' is the oxygen-gradient \code{zebrafish_o2} dataset.
#'
#' @format A data frame with 323 rows and 7 variables:
#' \describe{
#'   \item{assay_temp}{Assay temperature (degrees C).}
#'   \item{duration_h}{Exposure duration (hours).}
#'   \item{n_total}{Number of individuals in the trial.}
#'   \item{n_surv}{Number that survived.}
#'   \item{n_dead}{Number that died (\code{n_total - n_surv}).}
#'   \item{life_stage}{Life stage, a factor with levels \code{young_embryos},
#'         \code{old_embryos}, \code{larvae}.}
#'   \item{Date_experiment}{Experiment date (grouping factor).}
#' }
#' @source Zebrafish lethal-TDT assay across life stages (Case Study 2),
#'   obtained from the \pkg{bayesTLS} package distribution by Noble, Arnold, and
#'   Pottier (2026), licensed CC BY 4.0. freqTLS removed excluded trials,
#'   aggregated daily mortality counts, and derived survivors as documented
#'   above. Raw file:
#'   \code{system.file("extdata", "data_lethal_TDT_zebrafish.csv", package = "freqTLS")}.
#' @keywords datasets internal
"zebrafish_lethal"

#' Drosophila suzukii multi-trait thermal-tolerance data
#'
#' Per-individual thermal-tolerance assays for the spotted-wing fly
#' (\emph{Drosophila suzukii}), one row per fly, carrying three thermal-tolerance
#' endpoints measured under static heat exposures at 34--38 degrees C:
#' a lethal endpoint (\code{dead}), a sublethal knockdown time-to-event
#' (\code{t_coma}), and a sublethal reproductive endpoint (\code{prod}).
#' Aggregate \code{dead} to mortality/survival counts for Case 4. For the
#' supported awake/coma arm of Case 4.2, aggregate \code{is.na(t_coma)} to an
#' awake count at each temperature x level x sex cell. freqTLS does not fit the
#' censored time-to-coma response or the hurdle productivity response; those
#' analyses remain in bayesTLS. \code{lvl} indexes the exposure-duration grid as a
#' percentage of the estimated median time-to-coma from the authors' initial TDT
#' curves; \code{time} is the realised duration in minutes.
#'
#' @format A data frame with 1407 rows and 9 variables:
#' \describe{
#'   \item{id}{Unique individual identifier (\code{temp-lvl-sex-rep}).}
#'   \item{temp}{Assay temperature (degrees C).}
#'   \item{lvl}{Exposure duration as a percentage of the estimated median
#'         time-to-coma from the authors' initial TDT curves.}
#'   \item{time}{Exposure duration (minutes).}
#'   \item{sex}{Sex, a factor with levels \code{F}, \code{M}.}
#'   \item{rep}{Replicate vial within a temperature x lvl x sex cell.}
#'   \item{prod}{Reproductive productivity (offspring per female per day).}
#'   \item{dead}{Mortality indicator: \code{1} = died, \code{0} = survived.}
#'   \item{t_coma}{Time to heat coma (minutes); \code{NA} where no coma was
#'         recorded for that individual.}
#' }
#' @source \enc{Ørsted}{Orsted} M, Willot Q, Olsen AK, Kongsgaard V, Overgaard J
#'   (2024). Data for: Thermal limits of survival and reproduction depend on
#'   stress duration: a case study of \emph{Drosophila suzukii}. Zenodo,
#'   \doi{10.5281/zenodo.10602268} (distributed under CC BY 4.0). Associated
#'   article: \doi{10.1111/ele.14421}. Raw file:
#'   \code{system.file("extdata", "data_multitrait_TDT_drosophila_suzukii.csv", package = "freqTLS")}.
#' @examples
#' # Lethal endpoint: aggregate per-individual deaths to cell counts, then
#' # prepare the data for a beta-binomial 4PL.
#' cells <- stats::aggregate(
#'   cbind(n_total = rep.int(1L, nrow(dsuzukii)), n_dead = dead) ~
#'     temp + time + sex,
#'   data = dsuzukii,
#'   FUN = sum
#' )
#' std <- standardize_data(cells, temp = "temp", duration = "time",
#'                         n_total = "n_total", n_dead = "n_dead",
#'                         duration_unit = "minutes")
"dsuzukii"

#' Zebrafish lethal-TDT data across an oxygen gradient
#'
#' Survival of zebrafish (\emph{Danio rerio}) larvae assayed for upper thermal
#' tolerance under three oxygen treatments, the model-ready frame for the
#' oxygen-gradient case study. Diploid and triploid larvae were held at assay
#' temperatures of 26 (control), 38, 39 and 40 degrees C for 3.8--240 minutes
#' under hypoxia, normoxia or hyperoxia, and scored alive/dead. One row per
#' assay group; \code{oxygen} is the categorical moderator. Fit \code{CTmax} and
#' \code{z} as functions of \code{oxygen} (optionally \code{ploidy}) in one joint
#' 4PL to compare thermal tolerance across the gradient with profile-likelihood
#' confidence intervals on those direct parameters.
#'
#' @format A data frame with 905 rows and 10 variables:
#' \describe{
#'   \item{cohort}{Larval cohort identifier.}
#'   \item{ploidy}{Ploidy, a factor with levels \code{diploid}, \code{triploid}.}
#'   \item{oxygen}{Oxygen treatment, a factor with levels \code{hypoxia},
#'         \code{normoxia}, \code{hyperoxia} (the modelling moderator).}
#'   \item{o2_nominal}{Nominal oxygen target as percent air saturation
#'         (25 / 100 / 225).}
#'   \item{o2_measured}{Measured oxygen level (percent air saturation).}
#'   \item{temp}{Target assay temperature (degrees C).}
#'   \item{temp_measured}{Measured assay temperature (degrees C).}
#'   \item{duration_min}{Exposure duration (minutes).}
#'   \item{n_total}{Number of larvae in the assay group.}
#'   \item{n_surv}{Number surviving after exposure and recovery.}
#' }
#' @source Saruhashi S, Boerrigter JGJ, Hooymans MHL, Sinclair BJ, Verberk WCEP
#'   (2026). Data and code for: Oxygen availability and oxygen delivery but not
#'   oxidative stress shape heat tolerance in diploid and triploid zebrafish
#'   larvae. Zenodo, \doi{10.5281/zenodo.20075355} (distributed under CC BY 4.0).
#'   Associated article: \emph{Journal of Experimental Biology} 229(10): jeb251548,
#'   \doi{10.1242/jeb.251548}. Raw file:
#'   \code{system.file("extdata", "data_lethal_TDT_zebrafish_oxygen.csv", package = "freqTLS")}.
#' @examples
#' \donttest{
#' zf <- droplevels(subset(zebrafish_o2,
#'   ploidy == "diploid" & oxygen %in% c("normoxia", "hyperoxia")))
#' std <- standardize_data(zf, temp = "temp", duration = "duration_min",
#'                         n_total = "n_total", n_surv = "n_surv",
#'                         duration_unit = "minutes")
#' wf <- fit_4pl(std, ctmax = ~ 0 + oxygen, z = ~ 0 + oxygen,
#'               low = ~ 0 + oxygen, up = ~ 1, k = ~ 1, t_ref = 60)
#' tls(wf, by = "oxygen", lethal = FALSE)  # z and CTmax; no Tcrit
#' }
"zebrafish_o2"

#' Cereal-aphid lethal-TDT data, three species across three ages
#'
#' Survival of three cereal-aphid species across a broad range of stressful high
#' and low temperatures, the model-ready frame for the multi-species case study.
#' Aphids of three ages (2, 6, 12 days old) were exposed to a heat branch
#' (34--40 degrees C) or a cold branch (-11 to -3 degrees C) for a range of
#' durations and scored alive/dead after recovery. One row per assay group;
#' \code{branch} flags the heat vs cold series. Subset to one \code{branch} (and
#' typically one \code{age}) and fit \code{CTmax} and \code{z} as functions of
#' \code{species} in one joint 4PL to compare species with profile-likelihood
#' confidence intervals on those direct parameters.
#'
#' @format A data frame with 3041 rows and 7 variables:
#' \describe{
#'   \item{species}{Species, a factor with levels \code{M_dirhodum}
#'         (\emph{Metopolophium dirhodum}), \code{S_avenae}
#'         (\emph{Sitobion avenae}), \code{R_padi}
#'         (\emph{Rhopalosiphum padi}).}
#'   \item{age}{Age in days, a factor with levels \code{2}, \code{6}, \code{12}.}
#'   \item{branch}{Stress branch, a factor with levels \code{heat}
#'         (34--40 degrees C), \code{cold} (-11 to -3 degrees C).}
#'   \item{temp}{Assay temperature (degrees C).}
#'   \item{duration_min}{Exposure duration (minutes).}
#'   \item{n_total}{Number of aphids treated.}
#'   \item{n_surv}{Number surviving after treatment and recovery.}
#' }
#' @source Li Y-J, Chen S-Y, \enc{Jørgensen}{Jorgensen} LB, Overgaard J, Renault D,
#'   Colinet H, Ma C-S (2023). Data for: Interspecific differences in thermal
#'   tolerance landscape explain aphid community abundance under climate change.
#'   Dryad, \doi{10.5061/dryad.mcvdnck4j} (Dryad CC0). Associated article:
#'   \emph{Journal of Thermal Biology} 114: 103583, \doi{10.1016/j.jtherbio.2023.103583}.
#'   Raw file:
#'   \code{system.file("extdata", "data_lethal_TDT_aphid.csv", package = "freqTLS")}.
#' @examples
#' \donttest{
#' a <- subset(aphid_tdt, branch == "heat" & age == "6")
#' std <- standardize_data(a, temp = "temp", duration = "duration_min",
#'                         n_total = "n_total", n_surv = "n_surv",
#'                         duration_unit = "minutes")
#' wf <- fit_4pl(std, ctmax = ~ 0 + species, z = ~ 0 + species,
#'               low = ~ 1, up = ~ 1, k = ~ temp_c, t_ref = 60)
#' tls(wf, by = "species", lethal = FALSE)  # z and CTmax; no Tcrit here
#' }
"aphid_tdt"

#' Snow-gum retained PSII after heat exposure
#'
#' Retained photosystem-II function for snow gum (\emph{Eucalyptus pauciflora})
#' leaf sections after a temperature x duration heat dose and either Dark or
#' Light recovery. \code{fvfm_prop} is post-exposure Fv/Fm divided by the
#' pre-exposure value. It is a continuous proportion, so the canonical model
#' uses the experimental Beta family rather than a count likelihood.
#'
#' @format A data frame with 394 rows and 8 variables:
#' \describe{
#'   \item{Temp}{Assay temperature (degrees C).}
#'   \item{Time}{Exposure duration (minutes).}
#'   \item{recovery}{Recovery condition: \code{Dark} or \code{Light}.}
#'   \item{plant}{Plant identifier for the CTmax random intercept.}
#'   \item{meas_day}{Measurement-day identifier.}
#'   \item{initial_fvfm}{Pre-exposure Fv/Fm.}
#'   \item{final_fvfm}{Post-exposure Fv/Fm.}
#'   \item{fvfm_prop}{Retained PSII proportion.}
#' }
#' @source Arnold et al. (2026), \doi{10.64898/2026.04.09.717599}. The
#'   development copy is redistributed under CC BY-NC 4.0 with attribution.
#'   A maintainer attestation records coauthor permission for the current
#'   non-commercial GitHub/pkgdown teaching use. Unrestricted/commercial
#'   downstream redistribution and CRAN remain blocked until a written
#'   rights-holder grant is archived; see \file{inst/COPYRIGHTS}.
#' @examples
#' \donttest{
#' std <- standardize_data(snowgum_psii, temp = "Temp", duration = "Time",
#'                         proportion = "fvfm_prop", duration_unit = "minutes")
#' wf <- fit_4pl(std, ctmax = ~ 0 + recovery + (1 | plant),
#'               z = ~ 0 + recovery, low = ~ 1, up = ~ 1, k = ~ 1,
#'               family = "beta", t_ref = 60, method = "wald", quiet = TRUE)
#' tls(wf, by = "recovery", lethal = FALSE, method = "wald")
#' }
"snowgum_psii"
