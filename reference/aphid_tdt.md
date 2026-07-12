# Cereal-aphid lethal-TDT data, three species across three ages

Survival of three cereal-aphid species across a broad range of stressful
high and low temperatures, the model-ready frame for the multi-species
case study. Aphids of three ages (2, 6, 12 days old) were exposed to a
heat branch (34–40 degrees C) or a cold branch (-11 to -3 degrees C) for
a range of durations and scored alive/dead after recovery. One row per
assay group; `branch` flags the heat vs cold series. Subset to one
`branch` (and typically one `age`) and fit `CTmax` and `z` as functions
of `species` in one joint 4PL to compare species with profile-likelihood
confidence intervals on those direct parameters.

## Usage

``` r
aphid_tdt
```

## Format

A data frame with 3041 rows and 7 variables:

- species:

  Species, a factor with levels `M_dirhodum` (*Metopolophium dirhodum*),
  `S_avenae` (*Sitobion avenae*), `R_padi` (*Rhopalosiphum padi*).

- age:

  Age in days, a factor with levels `2`, `6`, `12`.

- branch:

  Stress branch, a factor with levels `heat` (34–40 degrees C), `cold`
  (-11 to -3 degrees C).

- temp:

  Assay temperature (degrees C).

- duration_min:

  Exposure duration (minutes).

- n_total:

  Number of aphids treated.

- n_surv:

  Number surviving after treatment and recovery.

## Source

Li Y-J, Chen S-Y, Jørgensen LB, Overgaard J, Renault D, Colinet H, Ma
C-S (2023). Data for: Interspecific differences in thermal tolerance
landscape explain aphid community abundance under climate change. Dryad,
[doi:10.5061/dryad.mcvdnck4j](https://doi.org/10.5061/dryad.mcvdnck4j)
(Dryad CC0). Associated article: *Journal of Thermal Biology* 114:
103583,
[doi:10.1016/j.jtherbio.2023.103583](https://doi.org/10.1016/j.jtherbio.2023.103583)
. Raw file:
`system.file("extdata", "data_lethal_TDT_aphid.csv", package = "freqTLS")`.

## Examples

``` r
# \donttest{
a <- subset(aphid_tdt, branch == "heat" & age == "6")
std <- standardize_data(a, temp = "temp", duration = "duration_min",
                        n_total = "n_total", n_surv = "n_surv",
                        duration_unit = "minutes")
wf <- fit_4pl(std, ctmax = ~ 0 + species, z = ~ 0 + species, t_ref = 60)
tls(wf, by = "species", lethal = TRUE)   # z, CTmax, T_crit per species
#> <tls> relative threshold; quantities: z, CTmax, Tcrit (bootstrap intervals)
#> # A tibble: 9 × 5
#>   species    quantity median lower upper
#>   <chr>      <chr>     <dbl> <dbl> <dbl>
#> 1 M_dirhodum z          4.55  4.35  4.81
#> 2 S_avenae   z          3.46  3.34  3.61
#> 3 R_padi     z          3.62  3.47  3.79
#> 4 M_dirhodum CTmax     35.4  35.2  35.5 
#> 5 S_avenae   CTmax     36.6  36.5  36.6 
#> 6 R_padi     CTmax     37.2  37.1  37.3 
#> 7 M_dirhodum Tcrit     24.0  21.6  26.2 
#> 8 S_avenae   Tcrit     27.9  26.2  29.6 
#> 9 R_padi     Tcrit     28.1  26.4  29.9 
# }
```
