# Zebrafish lethal thermal-death-time data across life stages

Lethal-TDT trials for zebrafish (*Danio rerio*) at three life stages.
Built from the raw daily survival sheet by summing the per-day
morning/afternoon mortality counts into one death count per trial and
dropping excluded rows. One row per assay trial. The model-ready frame
for Case Study 2.

## Usage

``` r
zebrafish_lethal
```

## Format

A data frame with 323 rows and 7 variables:

- assay_temp:

  Assay temperature (degrees C).

- duration_h:

  Exposure duration (hours).

- n_total:

  Number of individuals in the trial.

- n_surv:

  Number that survived.

- n_dead:

  Number that died (`n_total - n_surv`).

- life_stage:

  Life stage, a factor with levels `young_embryos`, `old_embryos`,
  `larvae`.

- Date_experiment:

  Experiment date (grouping factor).

## Source

Zebrafish lethal-TDT assay (Case Study 2). Raw file:
`system.file("extdata", "data_lethal_TDT_zebrafish.csv", package = "freqTLS")`.
