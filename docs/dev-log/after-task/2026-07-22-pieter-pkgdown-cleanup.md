# After Task: Pieter pkgdown and home-page cleanup

## Goal

Resolve the two follow-up findings from Pieter Arnold's human-validation review:
site-wide unreadable equations and overly prominent names for legacy benchmark
fixtures on the home page.

## Implemented

The pkgdown template now explicitly uses KaTeX. The public-site builder checks
that four representative reference/article pages carry the KaTeX assets after a
full build. The README home-page data-credit text keeps legacy fixtures fully
attributed through `inst/CITATION` and `inst/COPYRIGHTS`, without naming them
alongside the canonical teaching cases.

## Mathematical Contract

No 4PL likelihood, direct `CTmax`/`z` parameterisation, asymptote transform, or
profile algorithm changed. This repair makes the existing equations readable in
the rendered reader surface.

## Files Changed

- `_pkgdown.yml`
- `tools/build-site.R`
- `README.Rmd` and generated `README.md`
- `docs/dev-log/check-log.md`

## Checks Run

- `Rscript tools/build-site.R .` completed a clean full site build; the
  internal-page, legacy-discovery, warning, SVG, and new KaTeX guards passed.
- `Rscript -e 'pkgdown::check_pkgdown()'` returned `No problems found`.
- `Rscript -e 'devtools::test()'` returned 1,120 passing tests with no
  failures, warnings, or skips.
- KaTeX asset scans covered `derive_lt`, `derive_ctmax`, `derive_tcrit`, and
  `model-math`; the home-page legacy-fixture-name scan returned no matches.
- `git diff --check` passed.

## Tests Of The Tests

The new guard reads the generated HTML for pages with actual package equations,
not only the YAML setting. Removing or failing to inject the KaTeX template
assets would make the site builder stop before deployment.

## Consistency Audit

`_pkgdown.yml`, the site builder, README source, and rendered home page now
agree: canonical examples are public; benchmark-only fixtures remain installed
and attributed but are absent from discovery surfaces.

## GitHub Issue Maintenance

PR #57, Pieter's separate BLUP and `T_crit` documentation repair, was merged
after all four platform checks passed. This task resolves #58 and #59; the
human-validation tracker #14 can close after the corresponding issue comments
and cleanup PR are linked.

## What Did Not Go Smoothly

pkgdown's default MathML setting did not provide the client-side renderer needed
for the package's raw TeX equation blocks. The local build exposed the failure
only at the rendered HTML layer, which is now guarded.

## Team Learning

For every public equation surface, inspect the built HTML's renderer assets as
well as the R Markdown/Rd source. A source-valid equation is not necessarily a
site-readable equation.

## Known Limitations

KaTeX assets are loaded from its version-pinned CDN. The local build proves the
template and asset references, while a post-merge GitHub Pages deployment must
still confirm browser delivery from the live site.

## Next Actions

Open and merge the focused cleanup PR, then close #58, #59, and tracker #14
with links to the merged evidence and the pending live-site deployment check.
