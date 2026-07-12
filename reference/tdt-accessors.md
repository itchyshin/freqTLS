# Accessors for an extract_tdt() result

Twins of the bayesTLS `get_*_summary` / `get_*_draws` accessors.
`*_summary` returns the median + interval tibble; `*_draws` returns the
per-replicate (bootstrap) tibble — the frequentist analogue of posterior
draws.

## Usage

``` r
get_z_summary(et)

get_z_draws(et)

get_ctmax_summary(et)

get_ctmax_draws(et)

get_tcrit_summary(et)

get_tcrit_draws(et)
```

## Arguments

- et:

  An
  [`extract_tdt()`](https://itchyshin.github.io/freqTLS/reference/extract_tdt.md)
  result.

## Value

A tibble (see
[`extract_tdt()`](https://itchyshin.github.io/freqTLS/reference/extract_tdt.md)
for the column contract).
