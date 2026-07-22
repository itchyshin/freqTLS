# After Task: documentation correctness pass

## 1. Goal

Resolve every demonstrated reader-facing defect found before the remaining human
validation review, including the Confidence Eye and the heat-injury article.

## 2. Implemented

The default Confidence Eye is now minimal and independently scaled, with an
opt-in CTmax rug, outlined lenses, visible centre marks, and an unskippable
open-profile warning. The heat-injury article now fits the active CC BY 4.0
oxygen-gradient zebrafish data and applies a clearly hypothetical staged
exposure. Unit, threshold, malformed-input, and R-SHRIMP corrections are also
covered by source and regression tests.

## 3. Mathematical Contract

No 4PL, direct-CTmax/z, disjoint-asymptote, or profile-likelihood equation was
changed. `CTmax` remains defined at literal `tref`; the default heat-injury dose
uses the relative midpoint, while `target_surv = 0.5` is an absolute scenario.

## 3a. Decisions and Rejected Alternatives

Retained the existing ggplot/facet return rather than adding patchwork; facets
already provide independent scales without a new dependency. Used the active,
licensed zebrafish assay rather than excluded environmental traces or legacy
benchmark-only data.

## 4. Files Touched

`R/plotting.R`, `R/fit_tls.R`, `R/fit_4pl.R`, and `R/standardize_data.R`, their
generated Rd files, README/news/design and comparison prose, the heat-injury and
Confidence-Eye articles, the R-SHRIMP collaborator drafts, and targeted tests.

## 5. Checks Run

- `Rscript -e 'devtools::test()'` -> 1,116 pass, 0 fail/warn/skip (135.9 s).
- `Rscript -e 'devtools::document(); devtools::check_man()'` -> clean.
- `Rscript -e 'pkgdown::check_pkgdown()'` -> `No problems found`.
- `Rscript tools/build-site.R .` -> exit 0 after the final source freeze;
  public pages were rebuilt, internal AGENTS/CLAUDE/SPEC pages removed, and
  example alt text filled.
- Rendered Confidence-Eye PNG inspection -> caption, outline, centre mark,
  hollow estimate, and independent panels visible.

## 6. Tests of the Tests

New tests reject malformed column selection and invalid `p`, distinguish one
minute from one hour in hour-valued data, pin direct R-SHRIMP deaths to 0–11 and
738 total, and assert the minimal/default Confidence-Eye layer contract.

## 7a. Issue Ledger

#47 Confidence Eye and #53 real-data heat-injury example are implemented in this
candidate; their prior deferral comments will be superseded by PR evidence.
#14 remains open pending Piet's independent human review.

## 8. Consistency Audit

Exact scans:

```sh
rg -n -i 'one minute|LT50 \(relative midpoint\)|synthetic examples|heat-injury prediction.*\*\*fitted\*\*|tls_eye_polygon_df|round\(\(1 - mortality\)' README.Rmd README.md R man vignettes docs inst pkgdown-site --glob '!docs/dev-log/check-log.md' --glob '!docs/dev-log/recovery-checkpoints/**'
rg -n -i 'posterior|credible' R man README.Rmd README.md vignettes docs pkgdown-site --glob '!pkgdown-site/search.json'
rg -n -i 'relative midpoint|absolute (50%|survival)|tref|t_ref|one hour|Time \(minutes\)' README.Rmd README.md R man vignettes docs pkgdown-site --glob '!pkgdown-site/search.json'
```

The first scan returned only intentional current explanations or historical
after-task records. The Bayesian scan returned only explicit `bayesTLS`
comparisons; no freqTLS output is called posterior or credible. The final scan
confirmed explicit units and the relative-versus-absolute distinction on every
touched reader surface.

## 9. What Did Not Go Smoothly

The first minimal plot caption clipped at standard display size, and the first
centre mark was hidden beneath the white estimate ring. Fresh raster inspection
caught both defects; tests alone did not.

## 10. Known Residuals

The staged heat exposure is hypothetical and extrapolates static-assay fits; it
does not fit injury or repair kinetics. A human review from Piet is still an
external validation gate, not something agents can certify.

## 11. Team Learning

Rose's invariant ledger and Florence's rendered-image check prevented two
plausible but reader-invisible regressions. Public defaults need source, Rd,
rendered output, and visual verification together.

## 12. Cross-Product Coverage

The change was checked in code, roxygen/Rd, README, NEWS, design/capability
prose, vignettes, generated pkgdown pages, screenshots, regression tests, and
the existing GitHub human-validation tracker. It does NOT cover fitted
heat-injury/repair dynamics, a new response family, model-equation changes,
external environmental-trace provenance, or Piet's still-pending independent
human review.

## Next Actions

Commit and open the candidate PR, request the human validation group to review
the same rendered surface, close #47/#53 with exact evidence after merge, and
retain #14 until Piet returns his independent checklist.
