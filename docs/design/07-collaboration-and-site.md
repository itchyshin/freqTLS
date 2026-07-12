# Collaboration and Site

This document records the visual identity (the Confidence Eye), the documentation
and pkgdown plan, and the CI policy. Florence owns the Confidence-Eye gate; Grace
owns CI and the site build. The figure review checklist is the
`figure-visual-audit` skill.

## Visual identity: the Confidence Eye

The Confidence Eye is freqTLS's default uncertainty display, replacing
posterior-density visuals. freqTLS intervals are likelihood confidence
intervals; a posterior visual would imply a posterior the package does not
compute.

Elements:

- a pale, low-alpha confidence region (lens): `geom_polygon(alpha ~ 0.35,
  colour = NA)`;
- a darker interval outline;
- an emphasized centre mark;
- a hollow point-estimate circle: `geom_point(shape = 21, fill = "white",
  stroke ~ 0.9)`;
- an optional negligible-band `geom_rect` and a `geom_hline(0)` reference.

Prohibited by default (explicit variants only): filled points, horizontal CI
bars, centre lines through the eye, and row guide-lines through the eye.

Rules:

- Language is "confidence", never "posterior" / "credible".
- Captions expose the interval source (profile or Wald) and the transformation
  scale. Render-proof: a fresh PNG filename, with the rendered image inspected
  directly.
- Used for `CTmax` and `z` interval displays, group comparisons,
  `plot.profile_tls_profile`, and the homepage profile plot, with a
  `style = c("eye", "line")` switch (default `"eye"`) and a `conf.status` marker.
- Reliability palette (pinned): `grey50` for an estimated value, `#d6604d` when
  the CI overlaps the null, `#1b7837` when the CI excludes the null, `#377eb8`
  for an estimate marker.

Honest fallback (R-PROFILE): a non-closing profile renders a hollow point with
no lens, never a fabricated interval shape. This reuses the gllvmTMB behaviour
where the eye refuses to draw a lens when no finite `(lower, upper)` exists.

Reuse source: the geometry is adapted from gllvmTMB (GPL-3),
`plot_loadings_confidence_eye()` and the lens helper `.eye_polygon_df(width_max =
0.70)` in `gllvmTMB/R/loading-uncertainty-helpers.R`; provenance is recorded in
`inst/COPYRIGHTS`.

Teaching device: the comparison vignette may place a bayesTLS posterior density
beside the freqTLS Confidence Eye for the same `CTmax`/`z`, to visualise the
Bayesian-versus-likelihood contrast; both are labelled clearly.

## Documentation

- README: start-here links, the bayesTLS framework credit, the bounded preview
  status, install, a quick example, the model equation, the experimental
  lifecycle badge, and the data credits.
- Vignettes: `freqTLS`; `model-math` (the 4PL, the direct `CTmax`/`z`
  map, relative-vs-absolute, the bridge identities); `profile-likelihood` (LR
  profiles, asymmetry, profile vs Wald, the non-closing case); and
  `comparing-to-bayesTLS` (the cached three-way comparison).

## pkgdown

`_pkgdown.yml` uses Bootstrap 5 with the flatly bootswatch. The navbar groups
intro, reference, articles, and news; the reference index groups fitting,
post-fit tools, simulation, visualization, and data. References to functions that
do not exist yet are commented out so the config stays valid until the function
lands. The homepage is the tagline, the equation, a quick-start, one survival
plot, one Confidence-Eye profile plot, the comparison table, and the experimental
badge. The site is built to `pkgdown-site/` (kept out of the package build) so it
does not collide with this `docs/` governance tree.

## CI

`R-CMD-check.yaml` runs on main pushes, pull requests, and manual dispatch across
Ubuntu release/devel, Windows release, and macOS release, with
a concurrency group and a 30-minute timeout, and no Stan / cmdstanr. `pkgdown.yaml`
runs only after a successful trusted main-branch check (`workflow_run`); the
benchmark article builds from the cached summaries only. Local checks (`devtools::check()`,
`devtools::test()`, `pkgdown::build_site()`) come first; CI is the cross-PR and
on-demand safety net, not the routine check.
