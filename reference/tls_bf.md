# Build a freqTLS formula object (brms/drmTMB-style)

`tls_bf()` captures the per-sub-parameter formulas that define a
`freqTLS` model and returns them, unevaluated, as a `tls_formula`
object. It is the formula complement to the column interface of
[`fit_tls()`](https://itchyshin.github.io/freqTLS/reference/fit_tls.md):
instead of passing bare column names, you write one response formula
plus a formula per model sub-parameter.

## Usage

``` r
tls_bf(...)
```

## Arguments

- ...:

  The response-and-axes formula first (unnamed, with a left-hand side),
  then sub-parameter formulas keyed by their left-hand side. See the
  grammar above.

## Value

A `tls_formula` object: a list with the captured response formula, the
named sub-parameter formulas, and the calling environment.

## Details

The **first** argument must be the unnamed response-and-axes formula.
Its left-hand side names the survival counts, in either the brms idiom
`successes | trials(total)` or the `glm` idiom
`cbind(successes, failures)`. Its right-hand side names the two
thermal-load-sensitivity axes with the tagged markers `time(<duration>)`
and `temp(<temperature>)` (order does not matter).

The remaining arguments are sub-parameter formulas keyed by their
left-hand side, one of `low`, `up`, `log_k`, `CTmax`, or `log_z`. Any
sub-parameter you omit defaults to `~ 1`. Each of `low`, `up`, and
`log_k` may carry its **own** design independently — a grouping factor
(`low ~ group`), a continuous covariate (`log_k ~ body_size`), or an
intercept — and need not share one factor or match the
headline-parameter grouping. `CTmax` and `log_z` accept fixed-effect
formulas but must produce the same model-matrix columns (for example,
use `CTmax ~ group, log_z ~ group`); their supported random- intercept
groupings may differ. A single random intercept,
`<param> ~ <fixed> + (1 | group)`, is accepted on `CTmax`, `log_z`,
`low`, and `log_k` (one grouping factor each, intercept only) – but not
on the upper asymptote `up`, for which the compiled objective has no
random-intercept term. Putting the same grouping factor on two or more
of them fits independent variances (no correlation term) and warns.

## Parser provenance

The shape of the parser (variadic capture via
[`substitute()`](https://rdrr.io/r/base/substitute.html), a per-entry
formula walk, and random-bar detection) is adapted from drmTMB's
`drm_formula()` / `parse_drm_formula_entry()` (GPL-3); see
`inst/COPYRIGHTS`. freqTLS writes its own grammar (the
[`time()`](https://rdrr.io/r/stats/time.html) / `temp()` axis markers,
the five fixed sub-parameter handles, and the package's supported
random-effect grammar).

## See also

[`fit_tls()`](https://itchyshin.github.io/freqTLS/reference/fit_tls.md),
which accepts either a `tls_formula` or the column interface.

## Examples

``` r
tls_bf(
  survived | trials(total) ~ time(duration) + temp(temp),
  CTmax ~ life_stage,
  log_z ~ life_stage
)
#> <tls_formula>
#> survived | trials(total) ~ time(duration) + temp(temp)
#> CTmax ~ life_stage
#> log_z ~ life_stage
# cbind() response idiom, ungrouped:
tls_bf(cbind(survived, died) ~ time(duration) + temp(temp))
#> <tls_formula>
#> cbind(survived, died) ~ time(duration) + temp(temp)
```
