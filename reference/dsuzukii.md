# Drosophila suzukii multi-trait thermal-tolerance data

Per-individual thermal-tolerance assays for the spotted-wing fly
(*Drosophila suzukii*), one row per fly, carrying three
thermal-tolerance endpoints measured under static heat exposures at
34–38 degrees C: a lethal endpoint (`dead`), a sublethal knockdown
time-to-event (`t_coma`), and a sublethal reproductive endpoint
(`prod`). Only `dead` is a valid freqTLS response: aggregate it to
counts for the beta-binomial lethal fit. The `t_coma` and `prod` columns
are retained to preserve the deposited record and provide study context;
they require time-to-event and reproductive-response models that freqTLS
does not fit. `lvl` indexes the exposure-duration grid as a percentage
of the estimated median time-to-coma from the authors' initial TDT
curves; `time` is the realised duration in minutes.

## Usage

``` r
dsuzukii
```

## Format

A data frame with 1407 rows and 9 variables:

- id:

  Unique individual identifier (`temp-lvl-sex-rep`).

- temp:

  Assay temperature (degrees C).

- lvl:

  Exposure duration as a percentage of the estimated median time-to-coma
  from the authors' initial TDT curves.

- time:

  Exposure duration (minutes).

- sex:

  Sex, a factor with levels `F`, `M`.

- rep:

  Replicate vial within a temperature x lvl x sex cell.

- prod:

  Reproductive productivity (offspring per female per day).

- dead:

  Mortality indicator: `1` = died, `0` = survived.

- t_coma:

  Time to heat coma (minutes); `NA` where no coma was recorded for that
  individual.

## Source

Ørsted M, Willot Q, Olsen AK, Kongsgaard V, Overgaard J (2024). Data
for: Thermal limits of survival and reproduction depend on stress
duration: a case study of *Drosophila suzukii*. Zenodo,
[doi:10.5281/zenodo.10602268](https://doi.org/10.5281/zenodo.10602268)
(distributed under CC BY 4.0). Associated article:
[doi:10.1111/ele.14421](https://doi.org/10.1111/ele.14421) . Raw file:
`system.file("extdata", "data_multitrait_TDT_drosophila_suzukii.csv", package = "freqTLS")`.

## Examples

``` r
# Lethal endpoint: aggregate per-individual deaths to cell counts, then
# prepare the data for a beta-binomial 4PL.
cells <- stats::aggregate(
  cbind(n_total = rep.int(1L, nrow(dsuzukii)), n_dead = dead) ~
    temp + time + sex,
  data = dsuzukii,
  FUN = sum
)
std <- standardize_data(cells, temp = "temp", duration = "time",
                        n_total = "n_total", n_dead = "n_dead",
                        duration_unit = "minutes")
```
