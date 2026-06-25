# Convert various clock formats to minutes

Accepts POSIXt, hms / difftime, numeric fractions of a day (Excel time)
or bare numeric minutes, and character strings: `"HH:MM:SS"`, `"HH:MM"`,
bare numeric strings (minutes), and durations beyond 24 h (e.g.
`"25:30:00"`). Character strings are parsed element-wise; malformed
entries become `NA`.

## Usage

``` r
clock_to_minutes(x)
```

## Arguments

- x:

  Time value(s).

## Value

Numeric vector of minutes.

## Examples

``` r
clock_to_minutes("08:30:00")
#> [1] 510
clock_to_minutes("25:30")   # 25 h 30 min = 1530 min
#> [1] 1530
clock_to_minutes(0.5)       # half a day = 720 min
#> [1] 720
```
