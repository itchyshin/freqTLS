# Exact-candidate ledger — 0.1.0 merged technical candidate

Status: technical candidate frozen; **not ready to upload** because Dan must
finalise the `Authors@R` order and the authors must approve that final metadata.

| Field | Evidence |
| --- | --- |
| Merged source | GitHub merge commit `562cb027ced270e6ef32aaee265094f2d760b580` |
| Release boundary | Experimental `0.1.0`; not submitted to CRAN |
| Source tree | clean detached checkout at the merge commit; its package tree is identical to PR head `99da90b` used by the platform run |
| Tarball path / SHA-256 / size / entries | `/tmp/freqtls-postmerge-562cb02/freqTLS_0.1.0.tar.gz`; `0b97a520a7dff05d859fa36a30fa7ea7cd304159e9dcf91d9679567ed1f0a5aa`; 1,191,636 bytes; 226 entries |
| Tarball exclusion scan | 0 forbidden paths for `output`, `scripts`, `docs`, `tools`, `data-raw`, `.codex`, `.git`, `.github`, and internal contract files |
| Strict check | `R CMD check --as-cran --no-manual`: 0 errors, 0 warnings, 1 ordinary `New submission` NOTE |
| Public site | 103 HTML / 15 article / 82 reference pages; internal-page and stale-claim scans clean |
| Platform evidence | GitHub Actions run `29543780687`: Ubuntu release/devel, Windows release, and macOS release all passed on merged package source |
| Author metadata | Package use authorised by all coauthors; final author order remains for Dan to resolve before upload |

No claim here states that the package has been submitted to, accepted by, or
made available through CRAN.
