# Brown shrimp lethal thermal-death-time data

Replicate lethal-TDT trials for brown shrimp (*Crangon crangon*). Each
row is one tank of individuals exposed to a fixed assay temperature for
a fixed duration; the response is the proportion that died. The
model-ready frame for Case Study 1 (lethal endpoint).

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

Brown shrimp lethal-TDT assay (Case Study 1). Raw file:
`system.file("extdata", "data_lethal_TDT_brown_shrimp.csv", package = "freqTLS")`.

## Examples

``` r
std <- standardize_data(shrimp_lethal, temp = "Temperature_assay",
                        duration = "Duration_exposure_hours",
                        n_total = "N_individuals_after_trial",
                        mortality = "Mortality_after_trial",
                        random_effects = c("Date", "Tank"),
                        duration_unit = "hours")
```
