# Resolve the model-to-output time multiplier for TDT helpers

If `time_multiplier` is supplied it is returned unchanged (explicit
override). Otherwise it is derived from the workflow's
`meta$duration_unit` (the unit of the model's `duration` column) and the
requested `output_time_unit`, so that `model_time * time_multiplier` is
in `output_time_unit`. Falls back to `1` (with a message) when the units
cannot be resolved.

## Usage

``` r
tdt_resolve_time_multiplier(time_multiplier, meta, output_time_unit)
```

## Arguments

- time_multiplier:

  Numeric scalar or `NULL`.

- meta:

  A `bayes_tls` workflow's `meta` list (uses `duration_unit`).

- output_time_unit:

  Target output time unit (e.g. `"min"`).

## Value

Numeric scalar multiplier.
