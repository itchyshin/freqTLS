# Exact-artifact ledger — experimental 0.1.0

Status: **full-vignette local candidate; not a frozen submission candidate**  
Built: 2026-07-16, local macOS arm64 / R 4.6.0  
Source state: dirty remediation worktree; artifact identity is valid only for
this exact source state and is invalidated by any subsequent source-byte change.

| Field | Evidence |
|---|---|
| Command | `R CMD build --no-manual --sha256 .` |
| Artifact | `freqTLS_0.1.0.tar.gz` (local, untracked release artifact) |
| SHA-256 | `67518e0f585834791c919e86d1c2d20363a1d32edb4cb2a2404d0775d499ad55` |
| Size | 1,653,844 bytes |
| Entry count | 210 |
| Vignette payload | 40 `inst/doc/` entries; all 13 vignettes built |
| Forbidden-path scan | no `output/`, `scripts/`, `docs/`, `tools/`, `.codex/`, `AGENTS.md`, `CLAUDE.md`, or `SPEC.md` entries |
| Excluded raw-data scan | no aphid temperature trace, Kristineberg, or Ørsted trace entries |
| Rights disposition | component ledger records all source/data/cache components; generated result-cache provenance remains a release gate |

## Why this is not the candidate

This artifact proves the source-package inventory and contains its vignette
outputs. It is not submission-frozen: the worktree is not clean or post-merge,
the rendered pkgdown audit, URL adjudication, co-author consent, and matching
Windows/Ubuntu evidence remain required. Any source-byte change invalidates the
hash and requires a new row before submission review.
