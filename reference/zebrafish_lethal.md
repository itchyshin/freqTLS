# Zebrafish lethal thermal-death-time data across life stages

Lethal-TDT trials for zebrafish (*Danio rerio*) at three life stages.
Built from the raw daily survival sheet by summing the per-day
morning/afternoon mortality counts into one death count per trial and
dropping excluded rows. One row per assay trial. This unpublished
life-stage object is retained only for compatibility benchmarking; the
active zebrafish example is the oxygen-gradient `zebrafish_o2` dataset.

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

Zebrafish lethal-TDT assay across life stages (Case Study 2), obtained
from the bayesTLS package distribution by Noble, Arnold, Nakagawa, and
Pottier (2026), licensed CC BY 4.0. freqTLS removed excluded trials,
aggregated daily mortality counts, and derived survivors as documented
above. Raw file:
`system.file("extdata", "data_lethal_TDT_zebrafish.csv", package = "freqTLS")`.
