# After Task: Generalized remediation of Daniel Noble's review

## 1. Goal

Resolve issues #27, #29, #31, #34, #35, #37, #38, and #39 as one coherent
reader and numerical contract, rather than accepting narrow editorial changes
that would leave the same errors in neighbouring APIs, examples, figures, or
articles.

## 2. Implemented

Duration remains in the caller's native unit throughout `fit_tls()`, `fit_4pl()`,
`tls()`, `extract_tdt()`, heat-injury prediction, plots, and the two-stage
helpers. `t_ref` is now consistently documented and displayed in that same
unit: `60` denotes an hour only for minute data, and `1` denotes an hour only
for hour data. Two-stage output reports `CTmax`; `CTmax_1hr` is a compatibility
alias only when its premise (`t_ref = 60`) is true.

The public examples now simulate a real 4PL curve instead of independent
binomial draws. Target-survival requests are validated against the fitted
asymptotes and each converged bootstrap refit. Bootstrap storage preserves all
fixed shape coefficients. Derived routes that require scalar shapes at an
unknown temperature—absolute `extract_tdt()`, bootstrap survival-curve bands,
and deterministic heat-injury trajectories—now fail early with a concrete next
step when shapes vary.

README, reference help, plots, the benchmark script, and the affected articles
were synchronized. The comparison text distinguishes an ML estimate and
confidence interval from a Bayesian median and credible interval, and explains
that a shared absolute mortality point estimand does not make the two inference
workflows identical.

## 3. Mathematical Contract

The fitted 4PL is unchanged:

`p = low + (up - low) / (1 + exp(k * (log10(duration) - mid)))`, with
`mid = log10(t_ref) - (temperature - CTmax) / z`.

`CTmax` is the critical thermal maximum at `t_ref`, and `z` is thermal
sensitivity in degrees per decade of duration. The reference time must use the
same duration unit supplied to the model; no conversion occurs internally.
Relative targets are fractions between the fitted `low` and `up` asymptotes.
Numeric targets are absolute probabilities and must lie strictly between those
asymptotes. These distinctions make the target transform and its bootstrap
counterpart defined before logarithms are evaluated.

## 3a. Decisions and Rejected Alternatives

The remediation keeps the expanded experimental 0.1.0 surface. It does not
introduce a hidden minutes-to-hours conversion, default temperature-varying
shapes, a local absolute `z`, a fit-time absolute-threshold mode, or a
consolidated replacement API. Replacing valid varying-shape bootstrap refits
with a blanket prohibition was rejected: the collector now retains their
coefficients, and only derived scalar transforms that cannot evaluate those
shapes safely reject their unsupported request.

## 4. Files Touched

The implementation spans `R/bootstrap.R`, `R/extract_tdt.R`, `R/fit_4pl.R`,
`R/fit_tls.R`, `R/heat_injury.R`, `R/plotting.R`,
`R/predict_survival_curves.R`, `R/standardize_data.R`, `R/tls.R`, and
`R/two_stage.R`; generated Rd files and README figures; focused tests; the
benchmark script; README; and the affected pkgdown vignettes.

## 5. Checks Run

- `Rscript --vanilla -e 'devtools::document(); devtools::build_readme(); devtools::check_man(); devtools::test()'` completed with 1,076 passes, 0 failures, 0 warnings, and 0 skips in 132.2 seconds.
- `Rscript tools/build-site.R .` completed and performed the existing
  internal-page cleanup and reference-figure alt-text pass.
- `Rscript --vanilla -e 'pkgdown::check_pkgdown()'` reported `No problems found.`
- `git diff --check` was clean.
- The precise stale-surface and internal-page scans are recorded in
  `docs/dev-log/check-log.md` under 2026-07-19.

## 6. Tests of the Tests

New tests use seeded 4PL simulations, so they exercise a meaningful Stage 1
and Stage 2 relationship rather than random independent proportions. They
compare minute and hour parameterizations, assert that a conflicting Stage 2
reference-time override fails, assert scalar-only `by` input, and assert that
varying fixed-effect shape coefficients survive bootstrap collection. Target
validation has a negative path: impossible fitted or bootstrap targets stop
before `qlogis()` can return a misleading numerical result.

## 7a. Issue Ledger

The integrated pull request will close #27, #29, #31, #34, #35, #37, #38, and
#39. Daniel's smaller editorial pull requests are intentionally not treated as
complete fixes; the overlapping ones will be marked superseded by the merged
integrated change so their discussion remains auditable.

## 8. Consistency Audit

The status inventory was inspected with the active-release boundary in
`README.Rmd`, `ROADMAP.md`, `NEWS.md`, `docs/dev-log/known-limitations.md`,
`docs/design/46-capability-matrix.md`, the model/profile design notes, and
`_pkgdown.yml`. This task clarifies semantics within the existing 0.1.0 scope;
it does not add a response family, random-effect structure, fit-time
absolute-threshold mode, or heat-injury fitting capability. The generated site
contains no internal governance pages, and the targeted stale scan left only
the truthful compatibility alias and historical roadmap record.

## 9. What Did Not Go Smoothly

The first apparent problem looked like prose: a misleading one-hour label.
The Rose sweep found the same assumption in two-stage results, a raw benchmark
script, plot labels, multiple articles, bootstrap derived quantities, and
examples. The safe fix therefore required one native-unit contract, not a
global text substitution.

## 10. Known Residuals

Fixed varying shapes are supported in the fitted model and bootstrap refits,
but not in the three derived routes that need to evaluate an asymptote at an
unknown temperature. They now explain that boundary instead of silently using
the wrong scalar. Author order remains a separate metadata decision.

## 11. Team Learning

For a direct `CTmax`/`z` model, every reader-facing time label is part of the
statistical contract. A review finding about units or relative/absolute targets
should trigger a search across transformations, bootstrap post-processing,
visuals, examples, and comparator text before it is called resolved.

## 12. Cross-Product Coverage

Fixed varying shapes are supported in the fitted model and bootstrap refits,
but not in the three derived routes that need to evaluate an asymptote at an
unknown temperature. They now explain that boundary instead of silently using
the wrong scalar. This task does NOT cover default temperature-varying shapes,
local absolute `z`, fit-time absolute-threshold mode, random slopes, correlated
random effects, author-order selection, CRAN upload, or CRAN acceptance.

## Next Actions

Publish the integrated change, obtain checks on the exact commit, merge it if
they pass, close the linked issues, and record that the pre-existing author
order remains a separate metadata decision.
