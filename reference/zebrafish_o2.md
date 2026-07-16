# Zebrafish lethal-TDT data across an oxygen gradient

Survival of zebrafish (*Danio rerio*) larvae assayed for upper thermal
tolerance under three oxygen treatments, the model-ready frame for the
oxygen-gradient case study. Diploid and triploid larvae were held at
assay temperatures of 26 (control), 38, 39 and 40 degrees C for 3.8–240
minutes under hypoxia, normoxia or hyperoxia, and scored alive/dead. One
row per assay group; `oxygen` is the categorical moderator. Fit `CTmax`
and `z` as functions of `oxygen` (optionally `ploidy`) in one joint 4PL
to compare thermal tolerance across the gradient with profile-likelihood
confidence intervals on every quantity.

## Usage

``` r
zebrafish_o2
```

## Format

A data frame with 905 rows and 10 variables:

- cohort:

  Larval cohort identifier.

- ploidy:

  Ploidy, a factor with levels `diploid`, `triploid`.

- oxygen:

  Oxygen treatment, a factor with levels `hypoxia`, `normoxia`,
  `hyperoxia` (the modelling moderator).

- o2_nominal:

  Nominal oxygen target as percent air saturation (25 / 100 / 225).

- o2_measured:

  Measured oxygen level (percent air saturation).

- temp:

  Target assay temperature (degrees C).

- temp_measured:

  Measured assay temperature (degrees C).

- duration_min:

  Exposure duration (minutes).

- n_total:

  Number of larvae in the assay group.

- n_surv:

  Number surviving after exposure and recovery.

## Source

Saruhashi S, Boerrigter JGJ, Hooymans MHL, Sinclair BJ, Verberk WCEP
(2026). Data and code for: Oxygen availability and oxygen delivery but
not oxidative stress shape heat tolerance in diploid and triploid
zebrafish larvae. Zenodo,
[doi:10.5281/zenodo.20075355](https://doi.org/10.5281/zenodo.20075355)
(distributed under CC BY 4.0). Associated article: *Journal of
Experimental Biology* 229(10): jeb251548,
[doi:10.1242/jeb.251548](https://doi.org/10.1242/jeb.251548) . Raw file:
`system.file("extdata", "data_lethal_TDT_zebrafish_oxygen.csv", package = "freqTLS")`.

## Examples

``` r
if (FALSE) { # \dontrun{
std <- standardize_data(zebrafish_o2, temp = "temp", duration = "duration_min",
                        n_total = "n_total", n_surv = "n_surv",
                        duration_unit = "minutes")
wf <- fit_4pl(std, ctmax = ~ 0 + oxygen, z = ~ 0 + oxygen, t_ref = 60)
tls(wf, by = "oxygen", lethal = TRUE)   # z, CTmax, T_crit per oxygen treatment
} # }
```
