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

Install the build dependencies, configure CmdStan, and keep clean checkouts of
freqTLS and the pinned bayesTLS source. Run from the freqTLS repository root.

The builder refuses CI, requires `OPENBLAS_NUM_THREADS=1`, and caps parallelism
at 16 cores. The default is four. `BAYESTLS_SOURCE_DIR` is mandatory: the
builder verifies that checkout's clean Git state and exact commit, then loads
bayesTLS from that source tree rather than trusting an environment label or an
unrelated installed namespace. It likewise loads freqTLS from the clean current
checkout, so both recorded commits identify the executed code.

Raw `brms` fits and the first curated candidate remain under
`FREQTLS_CANONICAL_RAW_DIR`, outside the repository. The candidate build never
writes into `inst/extdata`. First build it:

```sh
env OPENBLAS_NUM_THREADS=1 \
  BAYESTLS_SOURCE_DIR="$HOME/bayesTLS-pinned" \
  FREQTLS_BAYES_CORES=4 \
  FREQTLS_CANONICAL_RAW_DIR="$HOME/freqtls-cache/76510412" \
  Rscript data-raw/build_canonical_comparator_cache.R
```

After reviewing the summaries, hashes, formulas, thresholds, differences, and
diagnostics, publish that exact candidate in a separate invocation:

```sh
env FREQTLS_CANONICAL_CANDIDATE="$HOME/freqtls-cache/76510412/canonical_bayesTLS_cache-candidate.rds" \
  FREQTLS_REVIEWED_CANDIDATE_SHA256=<reviewed-sha256> \
  Rscript data-raw/publish_canonical_comparator_cache.R
```

The publisher verifies the independently supplied candidate SHA-256, both
source commits, every case hash, complete case coverage, and all sampler
diagnostics before copying the exact bytes to
`inst/extdata/canonical_bayesTLS_cache.rds`.

The published 2026-07-16 cache has SHA-256
`3b04bb161250abb1628e3018ff25648984b7c6a4131272e6e9c0557b15c3b2f0`. It was
built with bayesTLS 1.0.0 at the pinned commit, freqTLS 0.2.0.9000 at
`b32c86001a7e88dd419f1a5a92e81c54b3b2b67c`, CmdStan 2.39.0, R 4.5.3, four
bounded cores, and `OPENBLAS_NUM_THREADS=1`. All six cases passed the recorded
diagnostic gates: maximum R-hat was 1.0019, there were zero divergences and zero
tree-depth hits, and every ESS and BFMI check passed.

Every fitted case records the source and analysis hashes, subset, endpoint,
family, formulas, grouping, `t_ref`, fit and reported thresholds, quantities,
seed, chains, iterations, warmup, controls, bayesTLS and freqTLS commits and
versions, CmdStan and R versions, build time, and diagnostics. If any diagnostic
does not pass, the candidate is retained for investigation but publication
fails closed; the model must be investigated and rebuilt.

## Review rule

The cache must be inspected alongside live freqTLS results. Reviewers confirm
identical data and specifications first, then report the observed differences
in point estimates and intervals. They do not average discrepant estimates,
silently widen tolerances, or remove a difficult case. A discrepancy triggers
an audit of data hashes, formulas, thresholds, centring, units, convergence,
identifiability, and posterior diagnostics before any biological explanation.
The rendered comparison article performs the current freqTLS refits, reports
the actual point differences, and keeps confidence and credible intervals
labelled separately.
