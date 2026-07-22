# Brown shrimp lethal thermal-death-time data

Replicate lethal-TDT trials for brown shrimp (*Crangon crangon*). Each
row is one tank of individuals exposed to a fixed assay temperature for
a fixed duration; the response is the proportion that died. The
model-ready fixture retained for compatibility benchmarking. It is
unpublished and is not an active teaching example.

## Usage

``` r
shrimp_lethal
```

## Format

A data frame with 148 rows and 6 variables:

- Date:

  Experiment date (use as a grouping factor).

- Tank:

  Holding-tank identifier (use as a grouping factor).

- Temperature_assay:

  Assay temperature (degrees C).

- Duration_exposure_hours:

  Exposure duration (hours).

- N_individuals_after_trial:

  Number of individuals in the trial.

- Mortality_after_trial:

  Proportion that died during the trial (deaths /
  `N_individuals_after_trial`), in the unit interval. Consumed by
  `standardize_data(mortality = "Mortality_after_trial")`.

## Source

Brown shrimp lethal-TDT assay (Case Study 1), obtained from the bayesTLS
package distribution by Noble, Arnold, Nakagawa, and Pottier (2026),
licensed CC BY 4.0. freqTLS retains the mortality proportion and
documents its count reconstruction above. Raw file:
`system.file("extdata", "data_lethal_TDT_brown_shrimp.csv", package = "freqTLS")`.
