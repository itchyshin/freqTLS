---
name: figure-visual-audit
description: Audit and improve freqTLS figures, galleries, pkgdown articles, and ggplot recipes, enforcing the Confidence-Eye uncertainty contract, before Florence, Rose, Pat, Fisher, and Grace call a figure done.
---

# Figure Visual Audit

Use this skill before declaring visualization work complete, and whenever a
reader says a rendered figure looks strange, ugly, inconsistent, too sparse, or
misleading.

## Shared Accountability

Do not treat poor figures as Florence's fault alone. Florence owns the final
scientific-figure standard and the Confidence-Eye gate, but the gate fails
earlier if the statistical, reader, systems, and reproducibility checks let an
incomplete plot through. A useful scientific figure helps users understand the
model, helps reviewers see the evidence, and helps the team catch wrong
assumptions before they become text.

## Standing Roles

- Ada coordinates the audit and decides what changes before merge.
- Florence reviews the rendered image as a scientific figure: composition,
  hierarchy, labels, accessibility, and whether the Confidence Eye is drawn
  correctly.
- Rose searches for repeated failure patterns across figures, prose, NEWS,
  ROADMAP, after-task reports, and check logs, including any stray
  "posterior"/"credible" language.
- Pat checks whether an applied reader can decode the figure without knowing the
  implementation history.
- Fisher checks that the visual data grain matches the claim: raw survival
  proportions, fitted curves, profile intervals, and missing cells must not be
  blurred together.
- Grace verifies renderability, pkgdown readiness, and reproducibility.
- Boole, Noether, Curie, and Darwin check syntax honesty, label-estimand match,
  simulation grain, and biological legibility respectively.

Say explicitly when these are role perspectives rather than spawned agents.

## The Confidence-Eye Contract

freqTLS intervals are likelihood compatibility intervals, not posteriors. The
default uncertainty display is the Confidence Eye:

- a pale, low-alpha compatibility region (lens), `geom_polygon(alpha ~ 0.35,
  colour = NA)`;
- a darker interval outline;
- an emphasized centre mark;
- a hollow point-estimate circle, `geom_point(shape = 21, fill = "white",
  stroke ~ 0.9)`.

Prohibited by default (only in explicit variants): filled points, horizontal CI
bars, centre lines through the eye, and row guide-lines through the eye.

- Language must be "confidence" / "compatibility", never "posterior" /
  "credible".
- Captions must expose the interval source (profile or Wald) and the
  transformation scale.
- Honest fallback (ties R-PROFILE): a non-closing profile renders a hollow point
  with no lens, never a fabricated closed eye. Reuse the gllvmTMB behaviour
  where the eye refuses to draw a lens when no finite `(lower, upper)` exists.
- The comparison vignette may place a bayesTLS posterior density beside the
  freqTLS Confidence Eye for the same `CTmax`/`z` as a deliberate teaching
  device; label both clearly.

The Confidence-Eye geometry is adapted from gllvmTMB (`plot_loadings_confidence_eye()`
and the `.eye_polygon_df(width_max = 0.70)` helper, GPL-3); record provenance in
`inst/COPYRIGHTS`.

## Workflow

1. Inventory the target figures and the claims they make (search the Rmd, NEWS,
   ROADMAP, design notes, check log, and after-task reports for figure titles
   and words like "confidence", "compatibility", "profile", "eye",
   "non-closing").
2. Render the actual article or report (`pkgdown::build_article()` or
   `rmarkdown::render(...)`).
3. Extract the rendered PNGs and inspect them one by one; a contact sheet is a
   navigation aid only.
4. Write or update a per-figure audit table: figure title or chunk, source
   object, data grain, interval source (profile/Wald), non-closing handling,
   reader risk, verdict, and fix.
5. Run Rose's pattern scan before editing:
   `rg "posterior|credible" R vignettes README.Rmd docs` and a Confidence-Eye
   element scan over the plotting code.
6. Edit the smallest recipe or prose needed; do not add a new exported plotting
   helper unless the table contract is stable and tested.
7. Re-render and inspect every changed figure directly. Save durable evidence
   under `docs/dev-log/figure-audits/<date-or-slice>/` when the gate is part of a
   meaningful task.
8. Close with a check-log entry and after-task report naming the figures
   inspected and the remaining limitations.

## Hard Gates

- Do not call a figure done from source inspection alone.
- Do not draw a filled point, a horizontal bar, or any closed eye for a
  non-closing profile.
- Do not use posterior or credible language for a freqTLS figure.
- Do not draw an interval without naming its source (profile / Wald) and its
  transformation scale in the caption.
- Use at most 10 cores for render, simulation, or profile work.
