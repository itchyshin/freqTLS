#' Brown shrimp lethal thermal-death-time assay
#'
#' Survival counts from a lethal thermal-death-time (TDT) assay on the brown
#' shrimp *Crangon crangon*: groups of individuals were held at a fixed assay
#' temperature for a fixed exposure duration, and the number surviving was
#' recorded. The data are vendored from the `bayesTLS` package and reshaped into
#' the [fit_tls()] column contract. They are ungrouped (a single 4PL fit).
#'
#' @format A data frame with 148 rows and 5 columns:
#' \describe{
#'   \item{temp}{Assay temperature in degrees Celsius. Six nominal levels
#'     spanning roughly 30--33 C.}
#'   \item{duration}{Exposure duration in **hours** (0.5 to 6 h).}
#'   \item{total}{Number of individuals in the trial (integer; the source
#'     `N_individuals_after_trial`).}
#'   \item{survived}{Number surviving the trial (integer), reconstructed from the
#'     source mortality proportion as `total - round(mortality_prop * total)`
#'     (see *Reconstructed death counts* below).}
#'   \item{mortality_prop}{The original source proportion dead
#'     (`Mortality_after_trial`), retained for provenance.}
#' }
#'
#' @section Reconstructed death counts:
#' The survival counts in this dataset are **reconstructed** from the source CSV
#' rather than read from a precomputed count column. In the `bayesTLS` source CSV
#' (`inst/extdata/data_lethal_TDT_brown_shrimp.csv`) the column
#' `Mortality_after_trial` records the *proportion* dead in each trial (for
#' example `0.0909 = 1/11`, `0.5 = 5/10`). To obtain the integer death and
#' survival counts that `fit_tls()` expects, freqTLS multiplies that
#' proportion by the trial size and rounds: `deaths = round(mortality_prop *
#' total)`, `survived = total - deaths`. The reconstructed deaths span 0--11
#' (summing to 738 across 148 rows). The original proportion is kept as
#' `mortality_prop` for transparency. See `data-raw/make_benchmark_data.R` for
#' the reconstruction script.
#'
#' @source Vendored from the `bayesTLS` package
#'   (\url{https://github.com/daniel1noble/bayesTLS}), file
#'   `inst/extdata/data_lethal_TDT_brown_shrimp.csv`, redistributed under CC BY
#'   4.0. Survival counts reconstructed from the CSV mortality proportions (see
#'   *Reconstructed death counts*).
#'
#' @section Attribution:
#' These data originate from the `bayesTLS` package by Daniel W. A. Noble,
#' Pieter A. Arnold and Patrice Pottier (2026, manuscript in preparation), which
#' introduced the thermal-load-sensitivity framework that freqTLS implements,
#' and from the original *Crangon crangon* lethal assay distributed with it.
#' They are redistributed under the Creative Commons Attribution 4.0
#' International licence (CC BY 4.0). freqTLS code is licensed GPL (>= 3); the
#' CC BY 4.0 licence applies only to the vendored data. Please cite `bayesTLS`
#' (see `citation("freqTLS")`) when you use this dataset.
#'
#' @docType data
#' @keywords datasets
#' @name shrimp_lethal
#' @usage data(shrimp_lethal)
#' @examples
#' data(shrimp_lethal)
#' str(shrimp_lethal)
#' # Reconstructed deaths span the full 0--11 range:
#' table(shrimp_lethal$total - shrimp_lethal$survived)
"shrimp_lethal"

#' Zebrafish lethal thermal-death-time assay, by life stage
#'
#' Survival counts from a lethal thermal-death-time (TDT) assay on zebrafish
#' *Danio rerio* at three life stages. Groups of individuals were held at a fixed
#' assay temperature for a fixed exposure duration, and the number surviving was
#' recorded. The data are vendored from the `bayesTLS` package and reshaped into
#' the [fit_tls()] column contract. They are grouped by `life_stage`, so a fit
#' estimates a separate `CTmax` and `z` per stage with shared `low`, `up`, and
#' `k`.
#'
#' @format A data frame with 323 rows and 5 columns:
#' \describe{
#'   \item{temp}{Assay temperature in degrees Celsius (the source `assay_temp`),
#'     spanning roughly 38--42 C.}
#'   \item{duration}{Exposure duration in **hours** (the source `duration_h`),
#'     0.0167 to 10 h.}
#'   \item{total}{Number of individuals in the trial (integer; the source
#'     `n_total`).}
#'   \item{survived}{Number surviving the trial (integer; the source `n_surv`).}
#'   \item{life_stage}{Life stage, a factor with levels `young_embryos`,
#'     `old_embryos`, `larvae` (118, 106 and 99 rows respectively).}
#' }
#'
#' @details
#' Unlike the shrimp data, the zebrafish survival counts are taken directly from
#' the shipped `bayesTLS::zebrafish_lethal` object: the counts already satisfy
#' `n_surv + n_dead == n_total` for every row, so no reconstruction is needed.
#' Only the shrimp counts require reconstruction from the source proportions (see
#' [shrimp_lethal]).
#'
#' @source Vendored from the `bayesTLS` package
#'   (\url{https://github.com/daniel1noble/bayesTLS}), object `zebrafish_lethal`,
#'   redistributed under CC BY 4.0.
#'
#' @section Attribution:
#' These data originate from the `bayesTLS` package by Daniel W. A. Noble,
#' Pieter A. Arnold and Patrice Pottier (2026, manuscript in preparation), which
#' introduced the thermal-load-sensitivity framework that freqTLS implements,
#' and from the original *Danio rerio* lethal assay distributed with it. They are
#' redistributed under the Creative Commons Attribution 4.0 International licence
#' (CC BY 4.0). freqTLS code is licensed GPL (>= 3); the CC BY 4.0 licence
#' applies only to the vendored data. Please cite `bayesTLS` (see
#' `citation("freqTLS")`) when you use this dataset.
#'
#' @docType data
#' @keywords datasets
#' @name zebrafish_lethal
#' @usage data(zebrafish_lethal)
#' @examples
#' data(zebrafish_lethal)
#' str(zebrafish_lethal)
#' table(zebrafish_lethal$life_stage)
"zebrafish_lethal"

#' Snowgum photosystem-II thermal-tolerance assay (continuous proportion)
#'
#' A **functional** (not lethal) thermal-tolerance assay on snowgum *Eucalyptus
#' pauciflora*: leaf-disc photosystem-II efficiency (`Fv/Fm`) was measured before
#' and after a fixed assay temperature and exposure duration. The response is the
#' **retained PSII proportion** `prop = final_fvfm / initial_fvfm`, a continuous
#' value in `[0, 1]`. This is the real-data showcase for the v0.2 **beta** family:
#' `fit_tls(y = prop, time = duration, temp = temp, family = "beta")` (no trials
#' column `n`). The data are vendored from the `bayesTLS` package and reshaped
#' into the [fit_tls()] column contract.
#'
#' @format A data frame with 319 rows and 3 columns:
#' \describe{
#'   \item{temp}{Assay temperature in degrees Celsius. Six levels: 28, 34, 39,
#'     42, 45, 48 C.}
#'   \item{duration}{Exposure duration in **minutes** (5, 15, 30, 60, 120) --
#'     note: minutes, not hours. Set `tref` to a value on this scale (for example
#'     `tref = 5`) when fitting.}
#'   \item{prop}{Retained PSII function, the proportion `final_fvfm /
#'     initial_fvfm` in `[0, 1]` (1 = full retention, 0 = complete loss).}
#' }
#'
#' @section Boundary values:
#' 60 of the 319 rows have `final_fvfm == 0` (complete PSII loss at the hottest /
#' longest exposures), so `prop` sits exactly at the `0` boundary. The beta
#' likelihood is undefined at `0` and `1`, so `fit_tls(family = "beta")` clamps
#' those values inward (to `1e-6` / `1 - 1e-6`) and emits a warning. The raw
#' proportion is vendored unchanged (zeros included) so the complete-loss
#' observations remain visible rather than being hidden by pre-clamping.
#'
#' @source Vendored from the `bayesTLS` package
#'   (\url{https://github.com/daniel1noble/bayesTLS}), file
#'   `inst/extdata/data_function_PSII_TDT_snowgum.csv`, redistributed under CC BY
#'   4.0. The retained-PSII proportion is computed as `final_fvfm / initial_fvfm`
#'   from the source columns (see `data-raw/make_benchmark_data.R`).
#'
#' @section Attribution:
#' These data originate from the `bayesTLS` package by Daniel W. A. Noble,
#' Pieter A. Arnold and Patrice Pottier (2026, manuscript in preparation), which
#' introduced the thermal-load-sensitivity framework that freqTLS implements,
#' and from the original *Eucalyptus pauciflora* PSII assay distributed with it.
#' They are redistributed under the Creative Commons Attribution 4.0 International
#' licence (CC BY 4.0). freqTLS code is licensed GPL (>= 3); the CC BY 4.0
#' licence applies only to the vendored data. Please cite `bayesTLS` (see
#' `citation("freqTLS")`) when you use this dataset.
#'
#' @docType data
#' @keywords datasets
#' @name snowgum_psii
#' @usage data(snowgum_psii)
#' @examples
#' data(snowgum_psii)
#' str(snowgum_psii)
#' # A continuous proportion in [0, 1]; complete-loss rows sit at the 0 boundary.
#' summary(snowgum_psii$prop)
#' # Fit the v0.2 beta family (boundary zeros are clamped inward with a warning):
#' fit <- suppressWarnings(
#'   fit_tls(snowgum_psii, y = prop, time = duration, temp = temp,
#'           family = "beta", tref = 5)
#' )
#' coef(fit)[c("CTmax", "z")]
"snowgum_psii"

#' Drosophila suzukii lethal thermal-death-time assay, by sex
#'
#' Survival counts from a lethal thermal-death-time (TDT) assay on the vinegar
#' fly *Drosophila suzukii*, separated by sex. Individual flies were held at a
#' fixed assay temperature for a fixed exposure duration and scored alive or dead;
#' the raw `bayesTLS::dsuzukii` object is long (one row per fly), and this dataset
#' is the **lethal endpoint aggregated to counts** per `(temp, time, sex)` cell
#' (`n_total = flies in the cell`, `n_dead = number that died`), reshaped into the
#' [fit_tls()] column contract. It is grouped by `sex`, so a fit estimates a
#' separate `CTmax` and `z` per sex with shared `low`, `up`, and `k`.
#'
#' Time is in **minutes**. The original study (and the `bayesTLS` supplement)
#' summarise `CTmax` at a **4-hour reference** (`tref = 240`) under the
#' **absolute** LT50 threshold, following Ørsted et al. (2024); set `tref = 240`
#' (minutes = 4 h) when fitting to match those numbers.
#'
#' @format A data frame with 94 rows and 5 columns:
#' \describe{
#'   \item{temp}{Assay temperature in degrees Celsius. Five levels: 34, 35, 36,
#'     37, 38 C.}
#'   \item{time}{Exposure duration in **minutes** -- note: minutes, not hours.
#'     Set `tref` to a value on this scale (for example `tref = 240`, i.e. 4 h)
#'     when fitting.}
#'   \item{sex}{Sex, a factor with levels `F` (45 rows) and `M` (49 rows).}
#'   \item{total}{Number of individuals in the cell (integer), the count of flies
#'     at that `(temp, time, sex)`.}
#'   \item{survived}{Number surviving (integer), `total - n_dead` where `n_dead`
#'     is the count of dead flies in the cell.}
#' }
#'
#' @details
#' The lethal counts are aggregated from the individual-level `bayesTLS::dsuzukii`
#' object exactly as in the `bayesTLS` supplement: `n_total = n()`, `n_dead =
#' sum(dead)` grouped by `(temp, time, sex)`, then `survived = n_total - n_dead`.
#' Each cell holds 9--24 flies (1407 flies and 622 deaths in total). The raw
#' object also carries the sublethal heat-coma (`t_coma`) and productivity
#' (`prod`) endpoints; those use time-to-event and hurdle models that are
#' freqTLS non-goals (see `docs/dev-log/known-limitations.md`), so only the
#' lethal-by-sex subset is vendored here. See `data-raw/vendor_dsuzukii_lethal.R`
#' for the aggregation script.
#'
#' @source Vendored from the `bayesTLS` package
#'   (\url{https://github.com/daniel1noble/bayesTLS}), object `dsuzukii`,
#'   redistributed under CC BY 4.0. The primary deposit is Zenodo
#'   \doi{10.5281/zenodo.10602268} (Ørsted, Hoffmann, Sgrò et al. 2024,
#'   *Global Change Biology*). The lethal-endpoint counts are aggregated to
#'   `(temp, time, sex)` cells (see *Details* and
#'   `data-raw/vendor_dsuzukii_lethal.R`).
#'
#' @section Attribution:
#' These data originate from the `bayesTLS` package by Daniel W. A. Noble,
#' Pieter A. Arnold and Patrice Pottier (2026, manuscript in preparation), which
#' introduced the thermal-load-sensitivity framework that freqTLS implements,
#' and from the original *Drosophila suzukii* multi-trait thermal-tolerance assay
#' of Ørsted et al. (2024), deposited on Zenodo
#' (\doi{10.5281/zenodo.10602268}). They are redistributed under the Creative
#' Commons Attribution 4.0 International licence (CC BY 4.0). freqTLS code is
#' licensed GPL (>= 3); the CC BY 4.0 licence applies only to the vendored data.
#' Please cite `bayesTLS` (see `citation("freqTLS")`) when you use this
#' dataset.
#'
#' @docType data
#' @keywords datasets
#' @name dsuzukii_lethal
#' @usage data(dsuzukii_lethal)
#' @examples
#' data(dsuzukii_lethal)
#' str(dsuzukii_lethal)
#' table(dsuzukii_lethal$sex)
#' # Fit a separate CTmax and z per sex (shared shape) at a 4-hour reference
#' # (time is in minutes, so tref = 240 = 4 h, matching Ørsted's absolute
#' # threshold). Wrap in suppressWarnings to swallow any data-adequacy notes.
#' fit <- suppressWarnings(
#'   fit_tls(dsuzukii_lethal, y = survived, n = total, time = time, temp = temp,
#'           group = sex, family = "beta_binomial", tref = 240)
#' )
#' fit$estimates[grepl("CTmax|^z", fit$estimates$parameter), ]
"dsuzukii_lethal"
