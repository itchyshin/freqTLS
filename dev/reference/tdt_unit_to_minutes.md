# Convert a time-unit label to minutes

Maps a free-text duration/time unit (e.g. `"hours"`, `"min"`, `"s"`) to
its length in minutes. Used to derive the model-to-output
`time_multiplier` in
[`extract_tdt()`](https://itchyshin.github.io/freqTLS/dev/reference/extract_tdt.md)
from a workflow's `duration_unit`.

## Usage

``` r
tdt_unit_to_minutes(unit)
```

## Arguments

- unit:

  Character scalar time-unit label.

## Value

Numeric scalar: the unit's length in minutes.
