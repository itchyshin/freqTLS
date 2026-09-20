# After Task: pkgdown logo, verified badges, and phylogenetic RE boundary

## Goal

Put Daniel W. A. Noble's supplied freqTLS logo and verified status badges on the
pkgdown home page, and turn the reported phylogenetic random-effect failure into
a clear pre-fit limitation message.

## Implemented

- Added `man/figures/logo.png`, configured pkgdown to use it on the home page,
  and generated the matching favicon bundle in `pkgdown/favicon/`.
- Added a pkgdown `Status` component and matching README badges: experimental,
  R-CMD-check, pkgdown, GPL-3.0-or-later, questions welcome (GitHub Issues), and
  open source.
- Rejected `(1 | gr(species, cov = tree))` during formula parsing with an
  actionable message directing users to `bayesTLS`; documented and tested the
  boundary.

## Mathematical Contract

The single-stage 4PL likelihood and direct `CTmax`/`z` parameterisation are
unchanged. The new parser error protects the existing contract: freqTLS fits
only independent random intercepts, not a phylogenetic covariance matrix.

## Files Changed

`_pkgdown.yml`, `README.Rmd`, `README.md`, `R/formula.R`, `man/tls_bf.Rd`,
`tests/testthat/test-formula.R`, `docs/design/08-random-effects.md`,
`docs/design/46-capability-matrix.md`, `docs/dev-log/known-limitations.md`,
`inst/COPYRIGHTS`, this report, the check log, `man/figures/logo.png`, and
`pkgdown/favicon/`, and `.github/workflows/R-CMD-check.yaml`.

## Checks Run

- `Rscript -e 'devtools::document(); devtools::test()'` completed with exit
  status 0.
- `Rscript tools/build-site.R .` completed with exit status 0; its sitrep found
  valid URLs, favicons, Open Graph metadata, article metadata, and reference
  metadata.
- Rendered-home-page inspection found `logo.png` plus all six active badges.
- `git diff --check` completed cleanly.
- The initial GitHub Actions run exposed an ARM macOS R 4.6 binary-download
  failure for `knitr` before package installation. The macOS release check now
  targets GitHub's supported `macos-15-intel` runner; its CRAN binary endpoint
  returned a gzip response in a direct check.

## Tests Of The Tests

The added deterministic `test-formula.R` case calls the parser with
`gr(species, cov = phylo_covariance)` and asserts the specific
phylogenetic-covariance error before an optimizer can run. The full suite ran
that negative path together with the existing formula tests.

## Consistency Audit

`rg -n 'gr\\(species, cov = tree\\)|Phylogenetic covariance' README.Rmd ROADMAP.md
NEWS.md docs R man tests` found the explicit boundary in code, generated help,
the README, limitations, capability matrix, design note, and regression test.
`ROADMAP.md` and `NEWS.md` need no status change: no supported capability was
added or removed. The README, `_pkgdown.yml`, limitations, capability matrix,
and random-effects design note were updated for the clarified behaviour.

## GitHub Issue Maintenance

`gh issue list --repo itchyshin/freqTLS --state open --limit 100` returned no
open issue. No duplicate issue was created or updated.

## What Did Not Go Smoothly

pkgdown requires each custom sidebar item to be declared under
`home.sidebar.components`; the first local build exposed that configuration
requirement. Adding the named `badges` component fixed it, after which the site
build passed. GitHub's current ARM macOS runner also returned an invalid
dependency archive before the package check; the CI job was moved to the
supported Intel macOS release runner and requires a fresh four-platform run.

## Team Learning

For an experimental package, badges should be verified service by service:
workflow and GPL badges are supported now, but CRAN, downloads, Codecov, and an
AMA badge require a CRAN release, coverage integration, and Discussions (or an
equivalent) respectively.

## Known Limitations

freqTLS remains experimental and does not support phylogenetic, correlated,
crossed, nested, or random-slope random effects. It is not currently released
on CRAN and has no configured public coverage service.

## Next Actions

Merge the focused pull request to `main`; the existing pkgdown workflow will
then deploy the logo, favicon, and badge component to the public site. Enable a
coverage service and release to CRAN before adding their live badges.
