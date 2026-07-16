# Exact-artifact ledger — experimental 0.1.0

Status: **clean-checkout local candidate; not a frozen submission candidate**  
Built: 2026-07-16, local macOS arm64 / R 4.6.0  
Source state: clean detached checkout at commit `a9e59f3`; artifact identity is
valid only for that exact source state and is invalidated by any source-byte change.

| Field | Evidence |
|---|---|
| Command | `R CMD build --no-manual --sha256 .` |
| Artifact | `freqTLS_0.1.0.tar.gz` (local, untracked release artifact) |
| Commit | `a9e59f3` (`build: exclude git worktree pointer`) |
| SHA-256 | `53461c1bed3081e590f993665a63f733903cd791f08095bf35aaa3a759a7787b` |
| Size | 1,653,827 bytes |
| Entry count | 210 |
| Vignette payload | 40 `inst/doc/` entries; all 13 vignettes built |
| Forbidden-path scan | no `.git`, `output/`, `scripts/`, `docs/`, `tools/`, `.codex/`, `AGENTS.md`, `CLAUDE.md`, or `SPEC.md` entries |
| Excluded raw-data scan | no aphid temperature trace, Kristineberg, or Ørsted trace entries |
| Rights disposition | component ledger records all source/data/cache components; generated result-cache provenance remains a release gate |

## Why this is not the candidate

This artifact proves the source-package inventory, contains its vignette
outputs, and passed `R CMD check --as-cran --no-manual` with 0 errors, 0
warnings, and one ordinary new-submission NOTE. It is not submission-frozen:
the candidate is not yet merged, and rendered-site human review, URL
adjudication, co-author consent, and matching Windows/Ubuntu evidence remain
required. Any source-byte change invalidates the hash and requires a new row
before submission review.
