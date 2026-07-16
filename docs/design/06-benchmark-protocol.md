# Canonical bayesTLS comparison protocol

## Purpose

freqTLS uses the pinned bayesTLS supplement as its empirical teaching template.
The comparison asks whether both engines received the same scientific analysis;
it does not require a maximum-likelihood estimate to equal a posterior median.
Agreement is a cross-check, not proof of correctness, because shared errors can
make both packages agree.

The authoritative Bayesian baseline is bayesTLS commit
`76510412e06c594c96894a1baba1f0e1a34a5aea`, rendered 2026-07-14. The exact
machine-readable contract is `data-raw/canonical_comparator_manifest.R`.

## Active analysis units

| ID | Exact analysis | Family | Formula and estimand |
| --- | --- | --- | --- |
| `zebrafish_oxygen` | `zebrafish_o2`; diploid; normoxia + hyperoxia | beta-binomial | `ctmax/z = ~ 0 + oxygen`, `low = ~ 0 + oxygen`, shared `up/k`; relative; `t_ref = 60` |
| `aphid_age6` | `aphid_tdt`; heat; age 6 | beta-binomial | `ctmax/z = ~ 0 + species`, `k = ~ temp_c`, shared `low/up`; relative; `t_ref = 60` |
| `aphid_all_age` | `aphid_tdt`; all heat-branch ages | beta-binomial | `ctmax/z = ~ 1 + species * age`, `k = ~ temp_c`, shared `low/up`; relative; `t_ref = 60` |
| `snowgum_psii` | retained PSII proportion; Dark vs Light; plant random intercept | Beta | `ctmax = ~ 0 + recovery + (1 | plant)`, `z = ~ 0 + recovery`, shared shape; relative; `t_ref = 60` |
| `drosophila_mortality` | aggregate `dead` by temperature x duration x sex | beta-binomial | `ctmax/z = ~ 0 + sex`, `low/up/k = ~ temp_c`; absolute LT50 report at `t_ref = 240` from a relative direct-coordinate fit |
| `drosophila_awake` | aggregate missing `t_coma` by temperature x level x sex; duration zero removed | beta-binomial | `ctmax/z = ~ sex`, `low/up/k = ~ temp_c`; relative; `t_ref = 60` |

Snow-gum is a transparent frequentist analogue: the active paired cache refits
the locked shared-shape specification in bayesTLS. It does not claim to
reproduce the richer recovery-by-temperature shape terms displayed in the
pinned supplement.

For Drosophila mortality, the direct freqTLS `CTmax` and `z` coordinates are
relative-midpoint quantities, while the pinned reported pair is absolute. The
public comparison therefore derives and compares only the absolute 240-minute
LT50 point. It withholds an allegedly equivalent absolute `z` rather than
subtracting unlike estimands.

## Data and specification gates

Every analysis unit records and tests:

- the source-object SHA-256 and deterministic analysis-subset SHA-256;
- the row filter or aggregation and response endpoint;
- the family and all five nonlinear formulas;
- grouping and random-effect structure;
- duration unit, resolved `t_ref`, fit threshold, reported threshold, and
  extracted quantities;
- source-data licence and public classification.

`test-canonical-case-specifications.R` exercises the live freqTLS fits and
requires convergence, a positive-definite Hessian, and the raw-gradient gate.
`test-canonical-comparator-cache.R` verifies the manifest, hashes, cache
coverage, diagnostics, and legacy exclusion.

## Totoro construction and publication

Stan and simulation campaigns never run in GitHub Actions. The maintainer-only
builder runs on Totoro with `OPENBLAS_NUM_THREADS=1`, four cores by default, and
a hard 16-core cap. It refuses CI, a dirty checkout, a different bayesTLS
commit, an unverified installed namespace, or an output directory inside the
repository.

The builder writes raw fits and
`canonical_bayesTLS_cache-candidate.rds` outside the repository. Publication is
a separate command that requires the independently reviewed candidate SHA-256
and rechecks both source commits, complete case coverage, every analysis hash,
and all sampler diagnostics before copying the exact bytes to
`inst/extdata/canonical_bayesTLS_cache.rds`.

The 2026-07-16 published cache has SHA-256
`3b04bb161250abb1628e3018ff25648984b7c6a4131272e6e9c0557b15c3b2f0`. It was
built with bayesTLS 1.0.0, the pre-release freqTLS implementation at `b32c860`, CmdStan 2.39.0,
R 4.5.3, four bounded cores, and one OpenBLAS thread. Across all six fits,
maximum R-hat was 1.0019, divergences and tree-depth hits were zero, and every
ESS and BFMI gate passed. Raw posterior fits remain maintainer-local.

## Public comparison rule

`vignettes/comparing-to-bayesTLS.Rmd` reads the immutable Bayesian summaries,
refits the current freqTLS specifications, prints convergence/Hessian/gradient
evidence, and reports actual point differences. Confidence intervals and
credible intervals remain separately named and interpreted. Inner joins have
fail-closed cardinality checks so a missing group or parameter cannot silently
disappear.

A discrepancy triggers an audit of hashes, filters, formulas, factor levels,
centring, units, thresholds, convergence, identifiability, and sampler
diagnostics. Estimates are never averaged, tolerances are never widened to hide
a result, and a difficult case is never silently replaced.

## Legacy compatibility boundary

Brown shrimp and life-stage zebrafish are unpublished benchmark-only fixtures.
Their data objects, R-SHRIMP repair test, and historical cache remain installed
for compatibility regression testing, but they are absent from active examples,
navigation, search, sitemap, LLM discovery, current summaries, and comparator
tables. Historical evidence is not current parity evidence.

## Licence boundary

The component ledger at `docs/design/47-data-license-ledger.md` is authoritative.
The canonical cache inherits every input's terms. In particular, the Snow-gum
object and its cached summaries are currently authorized only for the
non-commercial GitHub/pkgdown development teaching use. CRAN, commercial
downstream redistribution, and adaptations remain blocked until a broader
written rights-holder grant is archived or the data are compatibly relicensed.
