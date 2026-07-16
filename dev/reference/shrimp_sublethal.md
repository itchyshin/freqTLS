# Brown shrimp sublethal time-to-knockdown data

Sublethal TDT trials for brown shrimp (*Crangon crangon*): each cup of
individuals contributes the elapsed time to loss of response to touch
(knockdown) at a fixed assay temperature. Cleaned from the raw
clock-time records (excluded rows dropped; start/stop times parsed to
elapsed minutes). This unpublished object is retained only for
compatibility benchmarking.

## Usage

``` r
shrimp_sublethal
```

## Format

A data frame with 299 rows and 5 variables:

- assay_temp:

  Assay temperature (degrees C).

- time_to_event:

  Time to knockdown (minutes).

- date_experiment:

  Experiment date (grouping factor).

- tank_ID:

  Holding-tank identifier (grouping factor).

- cup_ID:

  Cup identifier, `Trial_ID_Sample` (grouping factor).

## Source

Brown shrimp sublethal time-to-knockdown assay (Case Study 1, sublethal
endpoint), obtained from the bayesTLS package distribution by Noble,
Arnold, and Pottier (2026), licensed CC BY 4.0. freqTLS dropped excluded
rows and converted the clock times to elapsed minutes. Raw file:
`system.file("extdata", "data_sublethal_TDT_brown_shrimp.csv", package = "freqTLS")`.
