# Canonical bayesTLS comparator cache

## Purpose and boundary

The active comparator cache cross-checks the experimental freqTLS v0.2
empirical examples against the bayesTLS supplement rendered on 2026-07-14 and
pinned at commit `76510412e06c594c96894a1baba1f0e1a34a5aea`. It is a
specification and discrepancy check, not a requirement that maximum-likelihood
estimates equal Bayesian posterior medians. Agreement is not proof of
correctness because shared data or model errors can make both packages agree.

The cache covers oxygen-gradient zebrafish, cereal aphids at age 6, the
all-age aphid extension, Snow-gum PSII, Drosophila mortality, and Drosophila
awake/coma counts. Shrimp and life-stage zebrafish remain in the old internal
legacy cache only; they cannot enter the active cache or its public comparison
tables.

The Drosophila mortality fit uses the relative direct-coordinate backbone and
reports the absolute LT50 transform at 240 minutes. The Snow-gum cache fits the
locked shared-shape freqTLS analogue, not the broader shape formulas in the
pinned Bayesian tutorial. These distinctions are recorded in the manifest
rather than hidden as method differences.

## Single source of truth

`data-raw/canonical_comparator_manifest.R` owns the exact filters, endpoints,
families, formulas, grouping, reference times, thresholds, sampler settings,
and deterministic SHA-256 analysis hashes. Both the maintainer builder and
`test-canonical-comparator-cache.R` source this manifest. A changed dataset,
filter, aggregation, factor structure, or endpoint therefore fails a test
before a stale comparator is presented as current.

The six fitted units are:

| ID | Data and endpoint | Formula contract | Threshold; reference |
|---|---|---|---|
| `zebrafish_oxygen` | Diploid; normoxia + hyperoxia; survival counts | `ctmax/z = ~ 0 + oxygen`; `low = ~ 0 + oxygen`; shared `up/k` | Relative; 60 min |
| `aphid_age6` | Heat branch; age 6; survival counts | `ctmax/z = ~ 0 + species`; `k = ~ temp_c`; shared `low/up` | Relative; 60 min |
| `aphid_all_age` | Heat branch; all ages; survival counts | `ctmax/z = ~ 1 + species * age`; `k = ~ temp_c`; shared `low/up` | Relative; 60 min |
| `snowgum_psii` | Retained PSII proportion | `ctmax = ~ 0 + recovery + (1 | plant)`; `z = ~ 0 + recovery`; shared shape | Relative; 60 min |
| `drosophila_mortality` | Temperature x duration x sex survival counts | `ctmax/z = ~ 0 + sex`; `low/up/k = ~ temp_c` | Absolute LT50 report; 240 min |
| `drosophila_awake` | Temperature x level x sex awake counts; duration zero removed | `ctmax/z = ~ sex`; `low/up/k = ~ temp_c` | Relative; 60 min |

## Totoro build and publication gate

Install freqTLS from the exact review commit and install bayesTLS from the
pinned checkout. Configure CmdStan, then run from the freqTLS repository root:

```sh
env OPENBLAS_NUM_THREADS=1 \
  BAYESTLS_GIT_SHA=76510412e06c594c96894a1baba1f0e1a34a5aea \
  FREQTLS_BAYES_CORES=4 \
  FREQTLS_CANONICAL_RAW_DIR="$HOME/freqtls-cache/76510412" \
  FREQTLS_PUBLISH_CACHE=1 \
  Rscript data-raw/build_canonical_comparator_cache.R
```

The builder refuses CI, requires `OPENBLAS_NUM_THREADS=1`, and caps parallelism
at 16 cores. The default is four. Raw `brms` fits and the first curated
candidate remain under `FREQTLS_CANONICAL_RAW_DIR`, outside the repository. The
only distributable output is the small summary file
`inst/extdata/canonical_bayesTLS_cache.rds`.

Every cached row records the source and analysis hashes, subset, endpoint,
family, formulas, grouping, `t_ref`, fit and reported thresholds, quantities,
seed, chains, iterations, warmup, controls, bayesTLS and freqTLS commits and
versions, CmdStan and R versions, build time, and diagnostics. If any diagnostic
does not pass, the candidate is still retained for investigation but the
official cache is blocked. Publication then requires the exact failing case IDs
in `FREQTLS_ACCEPT_DIAGNOSTIC_FAILURES` and a substantive explanation in
`FREQTLS_DIAGNOSTIC_NOTE`; both become cache metadata.

## Review rule

The cache must be inspected alongside live freqTLS results. Reviewers confirm
identical data and specifications first, then report the observed differences
in point estimates and intervals. They do not average discrepant estimates,
silently widen tolerances, or remove a difficult case. A discrepancy triggers
an audit of data hashes, formulas, thresholds, centring, units, convergence,
identifiability, and posterior diagnostics before any biological explanation.

