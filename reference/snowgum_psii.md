# Snow-gum retained PSII after heat exposure

Retained photosystem-II function for snow gum (*Eucalyptus pauciflora*)
leaf sections after a temperature x duration heat dose and either Dark
or Light recovery. `fvfm_prop` is post-exposure Fv/Fm divided by the
pre-exposure value. It is a continuous proportion, so the canonical
model uses the experimental Beta family rather than a count likelihood.

## Usage

``` r
snowgum_psii
```

## Format

A data frame with 394 rows and 8 variables:

- Temp:

  Assay temperature (degrees C).

- Time:

  Exposure duration (minutes).

- recovery:

  Recovery condition: `Dark` or `Light`.

- plant:

  Plant identifier for the CTmax random intercept.

- meas_day:

  Measurement-day identifier.

- initial_fvfm:

  Pre-exposure Fv/Fm.

- final_fvfm:

  Post-exposure Fv/Fm.

- fvfm_prop:

  Retained PSII proportion.

## Source

Arnold et al. (2026),
[doi:10.64898/2026.04.09.717599](https://doi.org/10.64898/2026.04.09.717599)
. The development copy is redistributed under CC BY-NC 4.0 with
attribution. A maintainer attestation records coauthor permission for
the current non-commercial GitHub/pkgdown teaching use.
Unrestricted/commercial downstream redistribution and CRAN remain
blocked until a written rights-holder grant is archived; see
`inst/COPYRIGHTS`.

## Examples

``` r
# \donttest{
std <- standardize_data(snowgum_psii, temp = "Temp", duration = "Time",
                        proportion = "fvfm_prop", duration_unit = "minutes")
#> Warning: standardize_data() clamped 90 of 394 finite proportion values into [0.001, 0.999] for the Beta likelihood. Check whether boundary values and this epsilon are scientifically appropriate.
wf <- fit_4pl(std, ctmax = ~ 0 + recovery + (1 | plant),
              z = ~ 0 + recovery, low = ~ 1, up = ~ 1, k = ~ 1,
              family = "beta", t_ref = 60, method = "wald", quiet = TRUE)
tls(wf, by = "recovery", lethal = FALSE, method = "wald")
#> <tls> relative threshold; quantities: z, CTmax (wald intervals)
#> # A tibble: 4 × 5
#>   recovery quantity median lower upper
#>   <chr>    <chr>     <dbl> <dbl> <dbl>
#> 1 Dark     CTmax     45.7  45.2  46.3 
#> 2 Light    CTmax     44.1  43.6  44.6 
#> 3 Dark     z          4.71  4.29  5.16
#> 4 Light    z          3.64  3.20  4.14
# }
```
