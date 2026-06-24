# After Task: Phase 4 -- Prediction + Confidence-Eye plotting

## Date

2026-06-16

## Task

Implement the forward-prediction surface and the publication plots, with the
Confidence Eye as profileTLS's default uncertainty display (SPEC.md S9 forward
map, S13 Confidence-Eye contract, S11 test-predict). Deliverables (Phase 4,
Florence + Darwin): `R/predict.R` (`predict.profile_tls`,
`predict_survival_surface`, `derive_lt`), `R/plotting.R`
(`plot_survival_curves`, `plot_tdt_curve`, `plot_survival_surface`,
`plot_confidence_eye` with a `style = c("eye","line")` switch and the honest
`conf.status` fallback), and `tests/testthat/test-predict.R`. Gate: survival
strictly decreasing with duration and with temperature; `newdata` path returns
probabilities in (0,1) of the right length; `type = "midpoint"` equals
`log10(tref)` at `temp = CTmax`; `derive_lt` round-trips; both the survival and
eye PNGs render and were inspected.

## Created / Changed

Created:

- `R/predict.R` -- `predict.profile_tls(object, newdata, type =
  c("survival","link","midpoint"))` using the engine forward map
  `mid = log10(tref) - (temp - CTmax_g)/z_g`, `p = low + (up-low)*plogis(-k(log10(duration)-mid))`;
  `predict_survival_surface()` (long temp x duration x survival grid, per group);
  `derive_lt(p, temp, group)` solving the 4PL for the duration where survival
  crosses `p` (`log10(dur) = mid - qlogis((p-low)/(up-low))/k`); the per-row
  group resolver `tls_predict_pars()` and the shape extractor
  `tls_shape_estimates()`.
- `R/plotting.R` -- `tls_eye_polygon_df()` (the gllvmTMB lens helper, adapted;
  GPL-3 provenance in `inst/COPYRIGHTS`); `plot_confidence_eye()` (pale lens +
  hollow point, `style = "eye"/"line"`, honest `conf.status` fallback);
  `plot_survival_curves()` (fitted curves + observed points, log-x);
  `plot_tdt_curve()` (LT/midpoint vs temperature via `derive_lt`, log-y);
  `plot_survival_surface()` (heatmap + contours).
- `tests/testthat/test-predict.R` -- 38 tests covering the SPEC S11 assertions
  plus link = qlogis(survival), midpoint constancy/omission, derive_lt at the
  relative midpoint, out-of-asymptote abort, surface shape, input validation,
  and the grouped per-group resolution.

Changed:

- `NAMESPACE` (via `devtools::document()`) -- gains `S3method(predict,
  profile_tls)`, `export(derive_lt)`, `export(predict_survival_surface)`,
  `export(plot_confidence_eye)`, `export(plot_survival_curves)`,
  `export(plot_tdt_curve)`, `export(plot_survival_surface)`,
  `importFrom(stats, predict)`.
- `man/` -- new `.Rd` for each exported function.
- `inst/COPYRIGHTS` -- the gllvmTMB Confidence-Eye note moves from "planned,
  Phase 4" to the implemented `R/plotting.R` helper `tls_eye_polygon_df()`.
- `docs/dev-log/check-log.md`, `docs/dev-log/dashboard/status.json`,
  `docs/dev-log/figure-audits/2026-06-16-eye.md` -- Phase 4 evidence + status +
  the rendered-PNG inspection record.

## Checks Performed (exact commands + counts)

- `R -q -e 'roxygen2::roxygenise(".")'` -> NAMESPACE gains the seven Phase-4
  exports above. (Three pre-existing `@noRd` link warnings from
  confint.R/diagnostics.R/profile.R are unchanged Phase 2-3 notes, not from this
  phase.)
- Verification gate (`devtools::load_all(".")` then the SPEC block):
  - `predict(f, expand.grid(temp=c(34,36,38), duration=c(1,2,4)), "survival")`
    -> survival range `[0.0239, 0.8945]` (in (0,1)).
  - `all(diff(predict(f, data.frame(temp=36, duration=c(0.5,1,2,4,8)),
    "survival")) <= 1e-8)` -> `TRUE` (decreasing with duration).
  - `all(diff(predict(f, data.frame(temp=c(32,34,36,38,40), duration=2),
    "survival")) <= 1e-8)` -> `TRUE` (decreasing with temperature).
  - `ggsave("/tmp/ptls_survival_p4.png", plot_survival_curves(f))` and
    `ggsave("/tmp/ptls_eye_p4.png", plot_confidence_eye(f, parm=c("CTmax","z")))`
    both wrote.
- Render-proof (Read the actual PNGs; see `figure-audits/2026-06-16-eye.md`):
  - survival PNG: seven viridis curves, each monotone-declining on the log-x
    axis, 30C near 1.0 and 42C near 0.0, observed points overlaid, y in [0,1].
  - eye PNG: pale-green lens + hollow white/dark-green point per facet (CTmax,
    z), lens tapering from the centre to the bounds, "compatibility" caption,
    no posterior wording, no filled points.
  - open-profile PNG (`/tmp/ptls_eye_open_p4.png`, sparse fit): subtitle "No
    interval closed; hollow points only"; hollow red points, NO polygon layer
    (`any(GeomPolygon) == FALSE`) -- the honest fallback.
  - line-style, surface, TDT PNGs all render correctly (TDT is log-linear with
    slope -1/z, the classic thermal-death-time line).
- `R -q -e 'devtools::test(".")'` -> `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 201 ]`
  (fit-beta-binomial 15, fit-binomial 13, group 21, methods 36,
  parameter-transforms 17, predict 38, profile 35, simulate 26).

## Outcomes

- Prediction uses exactly the engine forward map, verified two ways: monotone in
  both axes, and `type = "midpoint"` returns `log10(tref)` at `temp = CTmax`
  (tested at tref = 1 and 2 to 1e-8), pinning the reparameterisation end to end.
- `derive_lt()` round-trips: `predict(temp, derive_lt(p, temp)) == p` to 1e-6 at
  p in {0.25, 0.5, 0.75} and temp in {34, 36, 38}; at the *relative* midpoint
  p = (low+up)/2 the crossing is exactly the 4PL midpoint duration
  (`log10(LT) == mid`), which is why the TDT line is log-linear in temperature.
- The Confidence Eye honours the S13 contract: pale lens (`geom_polygon`,
  alpha 0.35, colour NA), hollow point (`shape = 21`, white fill, stroke 0.9),
  compatibility/confidence language only, caption exposing interval source +
  scale. The honest fallback is data-driven off `conf.status`: an open or NA
  interval draws a hollow point with no lens (verified by inspecting the
  sparse-fit PNG and by asserting the built plot has no polygon layer).
- All five plots render and were visually confirmed, not merely produced.

## Consistency Review

- `rg "posterior|credible"` over `R/predict.R R/plotting.R
  tests/testthat/test-predict.R`: none in user-facing strings. The eye captions
  use "compatibility intervals" and "compatibility/confidence"; the fallback
  subtitle points to `?confint.profile_tls`.
- The forward map in `R/predict.R` is identical to `R/simulate.R:112-114` and to
  `src/profile_tls.cpp` (mid, then `plogis(-eta)`), so simulate, fit, and predict
  share one map. `derive_lt` inverts the same map (no separate formula to drift).
- The dashboard matrix "Confidence-Eye uncertainty display" row moves
  planned -> implemented; the `inst/COPYRIGHTS` gllvmTMB note moves planned ->
  implemented with the concrete helper name.
- README / ROADMAP / NEWS / known-limitations: Phase 4 adds prediction + plots,
  which are forward-only conveniences over the already-documented model; no
  capability claim in those files needed revising (the plotting/predict surface
  was already listed as planned for Phase 4). Left untouched per the
  surgical-change rule; Phase 6 owns the README/vignette prose.

## Tests Of The Tests

- The midpoint test would fail if the forward map dropped the `log10(tref)`
  offset or mis-signed the `(temp - CTmax)/z` term; it asserts `mid == log10(tref)`
  at `temp = CTmax` for two distinct `tref`, so a unit/offset bug fails.
- The derive_lt round-trip is a true inverse check: a wrong rearrangement (e.g.
  forgetting the `/k` or the asymptote rescaling) would not return `p` to 1e-6.
- The monotonicity tests use `<= 1e-8` (not `< 0`) so a flat or numerically
  tied step passes but any increase fails -- a sign flip in the temperature or
  duration term would fail immediately.
- The open-profile fallback is checked structurally (no `GeomPolygon` layer when
  no interval closes), so a regression that fabricated a lens from NA bounds
  would be caught, not just visually missed.
- The out-of-asymptote `derive_lt(p = 0.999)` test asserts an abort, so silently
  returning `Inf`/`NaN` for an unreachable target would fail.

## What Did Not Go Smoothly

- The eye-polygon `.id` indexing needed care: gllvmTMB encodes `x_pos` as the
  trait integer within a facet, but profileTLS draws one parameter per facet, so
  each lens is centred at `x = 1` and the `.id` returned by the helper indexes
  into the *per-facet* subset. I mapped `.id` back to the global row
  (`global <- idx[poly$.id]`) before attaching reliability/facet, otherwise the
  colour aesthetic would have mis-aligned on multi-parameter calls.
- `geom_raster(interpolate = TRUE)` needs an evenly spaced grid; the default
  surface uses a log-spaced `times`, which raster treats as evenly spaced on the
  raw scale then `scale_y_log10()` re-maps -- visually fine here (the cells are
  monotone), but a future audit may prefer `geom_tile` if cell edges matter.
  Left as raster for v0.1 since the inspected render is clean.

## Team Learning

- Reuse the real gllvmTMB lens geometry rather than reinventing it: the
  Gaussian-width taper (`width_max * exp(-((y-est)^2)/(2 se_eff^2))`) and the
  CI-half-width fallback for the missing SE (`(hi-lo)/(2*1.96)`) both transfer
  directly to profile intervals, which carry no delta-method SE. (Florence.)
- Drive the honest fallback off the *data* (`is.finite(conf.low/high)` /
  `conf.status`), never off the fit's pdHess flag -- the profile path produces
  valid intervals on a non-PD fit, and an NA-bound profile must show a hollow
  point, not a fabricated eye. This mirrors gllvmTMB's data-driven gate. (Florence
  / Fisher.)
- Keep one forward map. predict, simulate, and derive_lt all read
  `mid = log10(tref) - (temp - CTmax)/z`; inverting it in place (rather than
  writing a second LT formula) means there is nothing to drift. (Darwin / Emmy.)

## Known Limitations

- `plot_survival_surface()` uses `geom_raster(interpolate = TRUE)` on a
  log-spaced duration grid; cell edges are approximate on the log axis (the fill
  gradient and contours are correct). A future phase may switch to `geom_tile`
  if exact cell boundaries are wanted.
- `derive_lt()` requires the target `p` strictly inside `(low, up)`; an
  extrapolated temperature (outside the fitted range) is not flagged here --
  CTmax-extrapolation warnings live in `check_tls()` (Phase 3), not in the
  forward-prediction helpers.
- The eye facets use `scales = "free"`, so the visual lens *width* is not
  comparable across parameters on different scales (only the vertical interval
  is meaningful per facet) -- intended, but worth a caption note in the Phase 6
  vignette.

## Next Best Task

- Phase 5 (Curie + Jason + Rose): the benchmark harness. `confint(method =
  "profile")` widths/asymmetry and `predict_survival_surface()` can now be
  compared against the cached bayesTLS posterior summaries; the comparison
  vignette's teaching device (posterior density beside the Confidence Eye) can
  reuse `plot_confidence_eye(style = "eye")`.
- Phase 6 (docs/site): the homepage survival plot and the headline Confidence-Eye
  profile plot are ready to embed; `plot_confidence_eye` and
  `plot_survival_curves` are the two homepage figures named in S13.
