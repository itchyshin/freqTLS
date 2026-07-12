# Cross-case-study summary: three taxa, one panel

This vignette mirrors Manuscript Figure 5 of the `bayesTLS` supplement –
a single multi-taxon panel of the thermal-sensitivity parameter `z` and
the critical temperature `CTmax` across the three redistributable case
studies – but draws the `freqTLS` **Confidence Eye** for each estimate
instead of a Bayesian posterior ridge. Each row is a likelihood
**confidence interval** (a pale lens with a hollow point estimate),
never a posterior density.

**This vignette builds without Stan.** Every fit here is the `freqTLS`
maximum-likelihood path (TMB), run live as the page renders. The
Bayesian multi-taxon ridge plot is the `bayesTLS` complement; see the
closing note.

``` r

library(freqTLS)
```

## The three taxa and the cross-study question

The three shared case-study datasets span three corners of thermal
physiology:

- **brown shrimp** *Crangon crangon* – a crustacean, lethal mortality,
  ungrouped;
- **zebrafish** *Danio rerio* – a fish, lethal mortality, across three
  life stages (young embryos, old embryos, larvae); this panel uses the
  `zebrafish_lethal` life-stage dataset — a *separate* experiment from
  the oxygen-gradient `zebrafish_o2` data in
  [`vignette("case-study-zebrafish")`](https://itchyshin.github.io/freqTLS/articles/case-study-zebrafish.md);
- **vinegar fly** *Drosophila suzukii* – an insect, lethal mortality,
  across the two sexes.

The cross-study question is descriptive: laid side by side, how do
thermal limits compare across a crustacean, a fish (resolved by
developmental stage), and an insect (resolved by sex)? `CTmax` (the
critical temperature at a fixed reference exposure) places each taxon on
the temperature axis; `z` (the change in temperature, in degrees
Celsius, that multiplies tolerated exposure time tenfold) measures how
sharply tolerated exposure responds to temperature: a *smaller* `z` is a
steeper response (a small warming sharply cuts tolerated time), a
*larger* `z` a more gradual one.

**One caveat governs the whole panel.** The reference exposures differ
by study, because each follows the convention of its source assay:

| Taxon | Endpoint | Reference exposure (`tref`) | Threshold |
|----|----|----|----|
| Shrimp | lethal | 1 hour | relative midpoint |
| Zebrafish (per stage) | lethal | 1 hour | relative midpoint |
| *D. suzukii* (per sex) | lethal | 4 hours (240 min) | relative midpoint |

Because a `CTmax` is defined *at* its reference exposure, the four
`CTmax` values are **not** on a single common time scale: the fly number
is the fitted relative midpoint temperature at 4 hours, whereas the
shrimp and zebrafish fits use a 1-hour reference. The panel is therefore
an **illustrative cross-taxon synthesis**, not a single common-scale
comparison. `z`, by contrast, is a slope – degrees per tenfold change in
time – and is comparable across taxa regardless of the reference
exposure. Read the `CTmax` facet as four study-specific anchors and the
`z` facet as a like-with-like comparison of duration sensitivity.

## The three fits (run live)

Each fit uses the configuration locked for its case study. The grouped
fits (zebrafish, fly) estimate a separate `CTmax` and `z` per level with
a shared shape (`low`, `up`, `k`); the ungrouped shrimp fit estimates
one of each. All three use **beta-binomial** survival counts. All fits
are wrapped in
[`suppressWarnings()`](https://rdrr.io/r/base/warning.html) to swallow
the honest data-adequacy notes (for example, temperatures with few
durations) that `freqTLS` raises – those signals are covered in the
per-study vignettes.

The vinegar-fly data ships per-individual (`dsuzukii`); we aggregate it
to `(temp, time, sex)` counts in base R, exactly as the per-study
vignette does.

``` r

# Each taxon: standardize_data() its raw table, then fit_4pl(); $fit is the
# engine fit the panel below reads.

# Shrimp: ungrouped, 1-hour reference.
data(shrimp_lethal)
shrimp_fit <- suppressWarnings(fit_4pl(standardize_data(
  shrimp_lethal, temp = "Temperature_assay", duration = "Duration_exposure_hours",
  n_total = "N_individuals_after_trial", mortality = "Mortality_after_trial",
  duration_unit = "hours"), t_ref = 1, family = "beta_binomial", quiet = TRUE))$fit

# Zebrafish: grouped by life stage, 1-hour reference.
data(zebrafish_lethal)
zebra_fit <- suppressWarnings(fit_4pl(standardize_data(
  zebrafish_lethal, temp = "assay_temp", duration = "duration_h",
  n_total = "n_total", n_surv = "n_surv", duration_unit = "hours"),
  by = "life_stage", t_ref = 1, family = "beta_binomial", quiet = TRUE))$fit

# D. suzukii: per-individual -> (temp, time, sex) counts; grouped by sex, 4-hour ref.
data(dsuzukii)
.nd <- aggregate(list(n_dead  = dsuzukii$dead), dsuzukii[c("temp", "time", "sex")], sum)
.nt <- aggregate(list(n_total = dsuzukii$dead), dsuzukii[c("temp", "time", "sex")], length)
fly_fit <- suppressWarnings(fit_4pl(standardize_data(
  merge(.nd, .nt), temp = "temp", duration = "time",
  n_total = "n_total", n_dead = "n_dead", duration_unit = "minutes"),
  by = "sex", t_ref = 240, family = "beta_binomial", quiet = TRUE))$fit
```

## Assembling the cross-study table

The panel is built from one combined data frame of
`(label, parameter, estimate, conf.low, conf.high)`, obtained by calling
`confint(..., method = "profile")` on each fit. For the grouped fits we
ask for the per-level parameter names (`CTmax:young_embryos`, `z:M`, and
so on); for the ungrouped fits we ask for the bare `CTmax` and `z`.
Every interval here is a profile-likelihood confidence interval, and –
as the `conf.status` column confirms – every profile closes.

``` r

# A small helper: pull profile CIs for the requested parameters from one fit and
# tag each row with a human-readable taxon/group label.
eye_rows <- function(fit, taxon, parms, labels) {
  ci <- suppressWarnings(suppressMessages(
    confint(fit, parm = parms, method = "profile")
  ))
  base <- sub(":.*$", "", ci$parameter)            # "CTmax:M" -> "CTmax"
  data.frame(
    taxon     = taxon,
    label     = labels[match(ci$parameter, parms)],
    parameter = base,
    estimate  = ci$estimate,
    conf.low  = ci$conf.low,
    conf.high = ci$conf.high,
    status    = ci$conf.status,
    stringsAsFactors = FALSE
  )
}

panel <- rbind(
  eye_rows(shrimp_fit, "Shrimp (1 h)",
           c("CTmax", "z"),
           c("Shrimp", "Shrimp")),
  eye_rows(zebra_fit, "Zebrafish (1 h)",
           c("CTmax:young_embryos", "CTmax:old_embryos", "CTmax:larvae",
             "z:young_embryos", "z:old_embryos", "z:larvae"),
           c("Zebrafish: young embryos", "Zebrafish: old embryos",
             "Zebrafish: larvae", "Zebrafish: young embryos",
             "Zebrafish: old embryos", "Zebrafish: larvae")),
  eye_rows(fly_fit, "D. suzukii (4 h)",
           c("CTmax:F", "CTmax:M", "z:F", "z:M"),
           c("D. suzukii: female", "D. suzukii: male",
             "D. suzukii: female", "D. suzukii: male"))
)

# Six rows, two parameters: a tidy printout of the headline numbers.
panel_wide <- data.frame(
  Group           = panel$label[panel$parameter == "CTmax"],
  `CTmax estimate` = round(panel$estimate[panel$parameter == "CTmax"], 2),
  `CTmax 95% CI`  = sprintf("[%.2f, %.2f]",
                            panel$conf.low[panel$parameter == "CTmax"],
                            panel$conf.high[panel$parameter == "CTmax"]),
  `z estimate`     = round(panel$estimate[panel$parameter == "z"], 2),
  `z 95% CI`       = sprintf("[%.2f, %.2f]",
                            panel$conf.low[panel$parameter == "z"],
                            panel$conf.high[panel$parameter == "z"]),
  check.names = FALSE
)
knitr::kable(
  panel_wide,
  caption = "Six taxon/group rows: CTmax (at the study reference exposure) and z, each with its profile-likelihood 95% confidence interval."
)
```

| Group | CTmax estimate | CTmax 95% CI | z estimate | z 95% CI |
|:---|---:|:---|---:|:---|
| Shrimp | 31.77 | \[31.63, 31.92\] | 2.19 | \[1.96, 2.46\] |
| Zebrafish: young embryos | 39.92 | \[39.79, 40.04\] | 2.00 | \[1.82, 2.19\] |
| Zebrafish: old embryos | 41.38 | \[41.23, 41.61\] | 1.80 | \[1.53, 2.16\] |
| Zebrafish: larvae | 39.79 | \[39.67, 39.92\] | 1.98 | \[1.76, 2.22\] |
| D. suzukii: female | 35.23 | \[35.12, 35.32\] | 3.01 | \[2.86, 3.18\] |
| D. suzukii: male | 35.25 | \[35.16, 35.34\] | 3.18 | \[3.01, 3.36\] |

Six taxon/group rows: CTmax (at the study reference exposure) and z,
each with its profile-likelihood 95% confidence interval. {.table}

## Cross-taxon validation against bayesTLS and the two-stage estimator

The same headline numbers are shown beside the classical two-stage
estimator and the `bayesTLS` posterior, read from the maintainer-built
benchmark cache. The `freqTLS` and `bayesTLS` fits use the matched
relative-midpoint, constant-shape configuration and the same per-study
reference exposure. The classical estimator uses absolute LT50 and is
therefore an approximate comparator for these lethal datasets, whose
asymptotes lie near zero and one.

| Group | Quantity | Two-stage (delta CI) | bayesTLS (95% CrI) | freqTLS (profile CI) |
|:---|:---|:---|:---|:---|
| Shrimp | CTmax (°C) | 31.62 \[31.34, 31.89\] | 31.72 \[31.60, 31.85\] | 31.77 \[31.63, 31.92\] |
| Shrimp | z (°C / decade) | 2.04 \[1.49, 2.60\] | 2.17 \[1.95, 2.43\] | 2.19 \[1.96, 2.46\] |
| Zebrafish: young embryos | CTmax (°C) | 39.61 \[39.34, 39.87\] | 39.97 \[39.82, 40.10\] | 39.92 \[39.79, 40.04\] |
| Zebrafish: young embryos | z (°C / decade) | 2.22 \[1.72, 2.71\] | 1.93 \[1.73, 2.13\] | 2.00 \[1.82, 2.19\] |
| Zebrafish: old embryos | CTmax (°C) | 41.39 \[40.88, 41.91\] | 41.34 \[41.19, 41.56\] | 41.38 \[41.23, 41.61\] |
| Zebrafish: old embryos | z (°C / decade) | 2.33 \[1.69, 2.96\] | 1.90 \[1.62, 2.24\] | 1.80 \[1.53, 2.16\] |
| Zebrafish: larvae | CTmax (°C) | 39.82 \[39.61, 40.02\] | 39.73 \[39.59, 39.85\] | 39.79 \[39.67, 39.92\] |
| Zebrafish: larvae | z (°C / decade) | 2.16 \[1.75, 2.57\] | 2.02 \[1.78, 2.26\] | 1.98 \[1.76, 2.22\] |
| D. suzukii: female | CTmax (°C) | 34.80 \[34.56, 35.04\] | 35.20 \[35.08, 35.30\] | 35.23 \[35.12, 35.32\] |
| D. suzukii: female | z (°C / decade) | 2.99 \[2.60, 3.38\] | 3.02 \[2.88, 3.18\] | 3.01 \[2.86, 3.18\] |
| D. suzukii: male | CTmax (°C) | 34.98 \[34.34, 35.62\] | 35.22 \[35.10, 35.32\] | 35.25 \[35.16, 35.34\] |
| D. suzukii: male | z (°C / decade) | 3.40 \[2.15, 4.65\] | 3.18 \[2.98, 3.39\] | 3.18 \[3.01, 3.36\] |

Cross-taxon three-way comparison: CTmax and z per taxon/group from the
classical two-stage estimator, bayesTLS (posterior median + 95% CrI),
and freqTLS (profile-likelihood estimate + 95% CI). The two model fits
share each study’s relative-threshold, constant-shape configuration; the
two-stage estimate is an absolute-LT50 approximation for these
near-0/near-1 lethal curves. {.table}

## The panel: a Confidence Eye per taxon and group

Each row is drawn as an honest Confidence Eye – a pale, shallow
horizontal lens whose width is exactly the 95% confidence interval and
whose cosine taper is tallest at the estimate, with a hollow point
marking the estimate itself. The two facets carry independent x-axes
(`CTmax` in degrees Celsius; `z` in degrees Celsius per tenfold change
in exposure time), because the two parameters live on different scales
and, for `CTmax`, on different reference exposures.

The geometry follows the `freqTLS` Confidence-Eye contract: the shallow,
wide lens reads as a confidence *interval*, not a probability density,
and a profile that did not close would render as a hollow point with
**no** lens. All six profiles here close, so every row carries a lens.

``` r

# Build the honest Confidence-Eye geometry by hand so all three fits share one
# cross-taxon panel: a cosine-tapered pale lens (width = confidence interval)
# plus a hollow point, faceted by parameter with free x-axes. This reuses the
# package lens shape (see ?plot_confidence_eye) but spans every fit in one figure.
stopifnot(requireNamespace("ggplot2", quietly = TRUE))

# Fixed top-to-bottom row order (shrimp, zebrafish stages, fly sexes).
row_order <- c(
  "Shrimp",
  "Zebrafish: young embryos", "Zebrafish: old embryos", "Zebrafish: larvae",
  "D. suzukii: female", "D. suzukii: male"
)
panel$row <- match(panel$label, row_order)
panel$parameter <- factor(panel$parameter, levels = c("CTmax", "z"),
                          labels = c("CTmax (°C)", "z (°C / decade)"))

# One cosine-tapered lens polygon per row (tallest at the estimate, zero at each
# bound), built per facet so the free x-axes do not distort the taper.
lens_df <- do.call(rbind, lapply(seq_len(nrow(panel)), function(i) {
  x <- seq(panel$conf.low[i], panel$conf.high[i], length.out = 80)
  d_lo <- max(panel$estimate[i] - panel$conf.low[i], .Machine$double.eps)
  d_hi <- max(panel$conf.high[i] - panel$estimate[i], .Machine$double.eps)
  frac <- ifelse(x <= panel$estimate[i], (panel$estimate[i] - x) / d_lo,
                 (x - panel$estimate[i]) / d_hi)
  w <- 0.32 * cos((pi / 2) * pmin(pmax(frac, 0), 1))
  data.frame(id = i, parameter = panel$parameter[i], x = x,
             ymin = panel$row[i] - w, ymax = panel$row[i] + w)
}))

# Reference-exposure annotation for the CTmax facet only.
tref_lab <- data.frame(
  parameter = factor("CTmax (°C)",
                     levels = levels(panel$parameter)),
  row = panel$row[panel$parameter == "CTmax (°C)"],
  x   = panel$conf.high[panel$parameter == "CTmax (°C)"],
  lab = c("1 h", "1 h", "1 h", "1 h", "4 h", "4 h")
)

ggplot2::ggplot() +
  ggplot2::geom_ribbon(
    data = lens_df,
    ggplot2::aes(x = x, ymin = ymin, ymax = ymax, group = id),
    fill = "#1b7837", colour = NA, alpha = 0.30
  ) +
  ggplot2::geom_point(
    data = panel,
    ggplot2::aes(x = estimate, y = row),
    shape = 21, fill = "white", colour = "#1b7837", size = 3, stroke = 1
  ) +
  ggplot2::geom_text(
    data = tref_lab,
    ggplot2::aes(x = x, y = row, label = lab),
    hjust = -0.25, size = 2.7, colour = "grey35"
  ) +
  ggplot2::scale_y_continuous(
    breaks = seq_along(row_order), labels = row_order,
    trans = "reverse", expand = ggplot2::expansion(add = 0.7)
  ) +
  ggplot2::scale_x_continuous(
    expand = ggplot2::expansion(mult = c(0.05, 0.20))
  ) +
  ggplot2::facet_wrap(~ parameter, scales = "free_x") +
  ggplot2::labs(
    x = NULL, y = NULL,
    title = "Thermal limits across three taxa: CTmax and z",
    subtitle = "Confidence Eyes: pale lens = 95% confidence interval; hollow point = estimate.",
    caption = paste(
      "Profile-likelihood confidence intervals (freqTLS, no Stan).",
      "CTmax reference exposure differs by study (annotated): not a common time scale."
    )
  ) +
  ggplot2::theme_minimal() +
  ggplot2::theme(
    panel.grid.major.y = ggplot2::element_blank(),
    panel.grid.minor = ggplot2::element_blank(),
    plot.caption = ggplot2::element_text(hjust = 0)
  )
```

![Two-facet Confidence-Eye panel. Left facet, CTmax in degrees Celsius:
six pale horizontal confidence-interval lenses with hollow point
estimates, ordered top to bottom as shrimp near 31.8, the three
zebrafish stages near 39.8 to 41.4, and the two D. suzukii sexes near
35.2. Right facet, z in degrees Celsius per tenfold time change:
matching lenses with shrimp near 2.2, zebrafish stages near 1.8 to 2.0,
and the two fly sexes near 3.0 to 3.2. Each CTmax row is annotated with
its reference exposure (1 hour or 4 hours), underscoring that the CTmax
values are not on a common time
scale.](case-study-summary_files/figure-html/panel-1.png)

## Within-taxon contrasts

The two grouped studies invite a within-taxon comparison: do the
zebrafish life stages differ, and do the fly sexes differ? `freqTLS`
answers these with a profile-likelihood interval **on the difference**
(`dCTmax:A-B`, `dz:A-B`) – a prior-free, frequentist counterpart to the
`bayesTLS` pMCMC bracket. A difference interval that excludes zero is a
clear separation; one that spans zero is not.

``` r

zebra_contrasts <- suppressWarnings(suppressMessages(confint(
  zebra_fit,
  parm = c("dCTmax:old_embryos-young_embryos",
           "dCTmax:larvae-young_embryos",
           "dCTmax:larvae-old_embryos",
           "dz:old_embryos-young_embryos",
           "dz:larvae-young_embryos",
           "dz:larvae-old_embryos"),
  method = "profile"
)))

fly_contrasts <- suppressWarnings(suppressMessages(confint(
  fly_fit,
  parm = c("dCTmax:M-F", "dz:M-F"),
  method = "profile"
)))

contrast_tbl <- rbind(zebra_contrasts, fly_contrasts)
knitr::kable(
  data.frame(
    Contrast   = contrast_tbl$parameter,
    Difference = round(contrast_tbl$estimate, 3),
    `95% CI`   = sprintf("[%.3f, %.3f]",
                         contrast_tbl$conf.low, contrast_tbl$conf.high),
    `Excludes 0` = ifelse(
      contrast_tbl$conf.low > 0 | contrast_tbl$conf.high < 0, "yes", "no"
    ),
    check.names = FALSE
  ),
  caption = "Within-taxon contrasts: profile-likelihood 95% confidence intervals on the CTmax and z differences."
)
```

| Contrast                         | Difference | 95% CI             | Excludes 0 |
|:---------------------------------|-----------:|:-------------------|:-----------|
| dCTmax:old_embryos-young_embryos |     -1.459 | \[-1.644, -1.289\] | yes        |
| dCTmax:larvae-young_embryos      |      0.128 | \[-1.760, 2.078\]  | no         |
| dCTmax:larvae-old_embryos        |      1.587 | \[1.403, 1.802\]   | yes        |
| dz:old_embryos-young_embryos     |      0.106 | \[-0.071, 0.272\]  | no         |
| dz:larvae-young_embryos          |      0.008 | \[-1.598, 1.661\]  | no         |
| dz:larvae-old_embryos            |     -0.098 | \[-0.278, 0.093\]  | no         |
| dCTmax:M-F                       |     -0.024 | \[-0.149, 0.093\]  | no         |
| dz:M-F                           |     -0.054 | \[-0.125, 0.024\]  | no         |

Within-taxon contrasts: profile-likelihood 95% confidence intervals on
the CTmax and z differences. {.table}

For zebrafish, the one clear separation in `CTmax` is **old embryos
versus young embryos** and **larvae versus old embryos**: old embryos
sit about 1.46 degrees Celsius above young embryos, with a confidence
interval well clear of zero, while larvae are essentially
indistinguishable from young embryos in `CTmax`. None of the `z`
contrasts excludes zero, so the three stages share a common duration
sensitivity even where their critical temperatures differ. For *D.
suzukii*, both the `CTmax` and the `z` sex contrasts span zero: there is
no clear sex difference in either thermal limit, the same conclusion
Ørsted et al. (2024) reached for these data.

## What this shows

Two things stand out from the panel:

- **Resolving a taxon by an internal axis can matter or not.** Zebrafish
  life stage shifts `CTmax` by over a degree (old embryos are the most
  heat-tolerant stage), whereas *D. suzukii* sex shifts neither `CTmax`
  nor `z` detectably. The Confidence Eyes make this visible at a glance:
  the zebrafish lenses separate on the `CTmax` axis, while the two fly
  lenses overlap almost completely.

- **Every estimate carries an honest, prior-free interval.** All six
  profiles close, so each row is a closed lens rather than a hollow
  point. Where a profile did **not** close (a weakly identified design
  or a boundary asymptote), the same display would show a hollow point
  with no lens – never a fabricated closed eye.

These are confidence intervals throughout: they summarise the
likelihood’s support for each parameter and make no probability
statement about the parameter itself.

## See bayesTLS for the Bayesian multi-taxon ridge

This panel is the `freqTLS` (likelihood) counterpart to Manuscript
Figure 5 of the `bayesTLS` supplement. Its full figure also includes the
snow-gum PSII dataset, which is not redistributed here because its
source is CC BY-NC 4.0. The Bayesian supplement draws the taxa as
posterior **ridge densities** with median points and 95% credible bars.
The two displays answer the same cross-study question from complementary
inferential engines: the `bayesTLS` ridge is a posterior density shaped
by priors and the data, whereas the `freqTLS` Confidence Eye is a
prior-free likelihood interval that cannot be read as a posterior. For
the Bayesian multi-taxon ridge plot, the within-taxon pMCMC contrasts,
and the full posterior workflow, see `bayesTLS`
(<https://github.com/daniel1noble/bayesTLS>); for the side-by-side
posterior-versus-Confidence-Eye contrast on a single dataset, see
[`vignette("comparing-to-bayesTLS")`](https://itchyshin.github.io/freqTLS/articles/comparing-to-bayesTLS.md).
