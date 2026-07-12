# Environmental traces pending redistribution clearance

These two files are retained for private provenance and possible future
validation, but they are excluded from the R package build and have no installed
consumer.

- `data_temp_trace_aphid_summer2016.csv` was derived from an Open-Meteo
  Historical Weather API / ERA5 workflow.
- `orsted_2024/orsted2024_nichemapr_rennes_2018_hourly.csv.gz` was regenerated
  from the Orsted et al. (2024) NicheMapR/NCEP workflow archived at Zenodo
  `10.5281/zenodo.10821572`.

The records reviewed for freqTLS 0.1.0 did not establish a complete compatible
redistribution chain for every underlying environmental-data provider. Do not
restore either file to `inst/extdata/`, an installed vignette, a cache, or an
example until compatible primary terms or written redistribution permission and
the required attribution have been recorded in `inst/COPYRIGHTS` and the
component ledger.
