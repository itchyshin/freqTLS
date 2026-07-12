# Snow gum leaf PSII functional-impairment thermal-tolerance data

Chlorophyll-fluorescence (\\F_v/F_m\\) measurements on excised snow gum
(*Eucalyptus pauciflora*) leaf sections before and 16–24 h after heat
exposure, from Experiment 1 (post-heat light vs dark recovery) of Arnold
et al. (2026). Short branches were cut from six mature trees grown
outdoors in Canberra, ACT; \\\sim\\1 cm\\^2\\ leaf sections were
dark-adapted, given an initial \\F_v/F_m\\, then submerged in a
temperature-controlled water bath under sub-saturating light across a
grid of assay temperatures (30–56 degrees C) and exposure durations
(5–120 min). After heat, paired arrays were held for 90 min in moderate
light (`recovery = "Light"`) or in darkness (`recovery = "Dark"`); a
final \\F_v/F_m\\ was taken 16–24 h later. The response is the
continuous proportion `fvfm_prop` (post/pre ratio), modelled with a Beta
likelihood. The model-ready frame for the leaf PSII case study
(sublethal, continuous-proportion endpoint). The light/dark contrast is
a two-group categorical moderator; in the source experiment post-heat
light lowered apparent heat tolerance.

## Usage

``` r
snowgum_psii
```

## Format

A data frame with 394 rows and 8 variables:

- Temp:

  Assay temperature (degrees C); 30, 35, 40, 44, 48, 52, 56.

- Time:

  Exposure duration (minutes); 5, 15, 30, 60, 120.

- recovery:

  Post-heat recovery light condition: `"Dark"` (darkness immediately
  after heat) or `"Light"` (90 min moderate light post-heat). A
  two-level moderator.

- plant:

  Replicate mature tree (factor, 6 levels); the natural random-effect
  grouping.

- meas_day:

  Assay day (factor, 2 levels). Two levels only, so a poor random-effect
  grouping; better treated as fixed or omitted.

- initial_fvfm:

  \\F_v/F_m\\ measured before heat exposure.

- final_fvfm:

  \\F_v/F_m\\ measured 16–24 h after heat exposure.

- fvfm_prop:

  Retained PSII function, `final_fvfm / initial_fvfm` (a proportion in
  the unit interval; 0 indicates complete loss of measurable PSII
  function).

## Source

Arnold PA, Harris RJ, Aitken SM, Hoek MM, Cook AM, Leigh A, Nicotra AB
(2026) Towards a standard approach to investigating the thermal load
sensitivity of photosystem II via chlorophyll fluorescence. bioRxiv
[doi:10.64898/2026.04.09.717599](https://doi.org/10.64898/2026.04.09.717599)
(CC BY-NC 4.0), Experiment 1, snow gum slice. Raw file:
`system.file("extdata", "data_function_PSII_TDT_snowgum.csv", package = "freqTLS")`.

## Details

Two of the 396 raw rows have post/pre \\F_v/F_m\\ marginally above 1
(both Dark, low dose) where a leaf measured slightly higher after heat
than before; retained function cannot exceed 1, so these are treated as
measurement noise and excluded, leaving 394 rows.

## Examples

``` r
std <- standardize_data(snowgum_psii, temp = "Temp", duration = "Time",
                        proportion = "fvfm_prop",
                        random_effects = "plant",
                        duration_unit = "minutes")
```
