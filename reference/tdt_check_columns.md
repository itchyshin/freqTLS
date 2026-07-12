# Error on missing columns

Error on missing columns

## Usage

``` r
tdt_check_columns(data, cols, arg_name = "columns")
```

## Arguments

- data:

  A data frame or data-frame-like object whose column names are checked.

- cols:

  Character vector of required column names. Missing values and empty
  strings are ignored.

- arg_name:

  Label used in the error message when columns are missing.

## Value

`TRUE`, invisibly, when every requested column is present; otherwise the
function raises an error naming the missing columns.
