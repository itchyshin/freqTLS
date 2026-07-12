# After Task: CRAN Resubmission Ready

## 1. Goal

Close every technical and governance gate for the exact corrected freqTLS 0.1.0
tarball before resubmitting it to CRAN.

## 2. Implemented

The DESCRIPTION spelling flags were removed with equivalent prose. The slow
cross-case vignette now reads versioned, provenance-checked precomputed results,
while individual articles and all 827 tests retain live fitting and inference.
Grouped contrast direction, interval-method labels, cache reproducibility,
licensing records, public scope, and the generated pkgdown site were corrected.
PR #4 was squash-merged to `main` as `adb5e0dc5ace287ff7304a43ba839dffdc5fb88a`.

## 3a. Decisions and Rejected Alternatives

The final artifact is frozen at SHA-256
`e3b38efb954e3292d814c897c2af8620b967ff2ffa72a753bf18c3ab886f62be`.
We used the precomputed-results option Uwe Ligges explicitly permitted rather
than weakening tests, using misleadingly few bootstrap iterations, or hiding
the case-study synthesis. Any installed-byte change invalidates this freeze and
requires all exact-artifact gates to be repeated.

## 4. Files Touched

- `cran-comments.md`
- `docs/dev-log/after-task/2026-07-12-cran-resubmission-ready.md`
- `docs/dev-log/after-task/2026-07-12-cran-incoming-pretest-remediation.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/decisions.md`
- `docs/dev-log/release-gates/2026-07-11-cran-0.1.0.md`

All files in this final evidence batch are excluded from the source package, so
the verified tarball is unchanged.

## 5. Checks Run

- Local strict `R CMD check --as-cran` -> zero errors, zero warnings, one
  expected `New submission` NOTE; 827 tests passed.
- GitHub Actions run `29196192961` -> Ubuntu release/devel, Windows release, and
  macOS release passed at source HEAD `7097a1333fc15b31c65b2863ab74039faca23724`.
- R-hub run `29196204879` -> Ubuntu/clang passed at the same source HEAD.
- `curl -fsSL https://win-builder.r-project.org/z8E3gcN9PWek/00check.log` ->
  package/version verified; 87-second installation, 431-second check, 89-second
  tests, 165-second vignette rebuild, and only the `New submission` NOTE.
- Tarball inventory -> 212 entries; no governance, scripts, excluded/licensing-
  pending data, compiled artifacts, or unlicensed assets.
- Fresh audits -> Pat READY, Rose READY, Grace no local blocker with all stated
  external conditions now satisfied.
- `gh pr view 4` -> merged to `main` at
  `adb5e0dc5ace287ff7304a43ba839dffdc5fb88a`.

## 6. Tests of the Tests

The original incoming pre-test measured 625 seconds overall and 375 seconds for
vignettes, so it demonstrated that the gate detects an unaffordable reader
workflow. The final independent Windows check measured 431 and 165 seconds,
respectively. Directed contrast tests would fail under the old reversed A-B
semantics, and the installed-cache test would fail if provenance, seeds,
checksums, row counts, or actual interval methods drifted.

## 7a. Issue Ledger

- `CRAN-SPELL`: closed; no final spell flags.
- `CRAN-TIME`: closed; final win-builder total is below ten minutes.
- `CONTRAST-DIRECTION`: closed in implementation, documentation, tests, and
  cache values.
- `DATA-RIGHTS`: closed by documented permission or package exclusion.
- `AUTHOR-CONSENT`: closed by the maintainer's dated attestation.
- No overlapping open GitHub issue requires a separate comment.

## 8. Consistency Audit

The exact hash, source head, local check, GitHub matrix, R-hub result,
win-builder result, release gate, CRAN comments, licensing ledger, COPYRIGHTS,
and Grace/Rose/Pat verdicts describe one candidate. README, NEWS, roadmap,
capability matrix, and public site do not claim CRAN publication.

## 9. What Did Not Go Smoothly

The first CRAN incoming check exposed both an expensive synthesis article and
two DESCRIPTION spell flags. Subsequent adversarial review found a reversed
contrast convention, incomplete cache provenance, and stale six-versus-12
profile wording. Each was corrected and independently rechecked rather than
explained away.

## 10. Known Residuals

CRAN resubmission, confirmation, review, acceptance, mirror propagation, and
public package/check pages remain external gates. Until those pages exist,
freqTLS 0.1.0 remains a release candidate rather than an on-CRAN release.

## 11. Team Learning

Memory receipt: the repository contract, ultra-plan, release-readiness,
after-task-audit, and prose review required exact-artifact evidence and a fresh
installed-user/adversarial gate. The Rose principle converted timing cleanup
into corrections to scientific semantics and public claims.

Golden Set: the reusable guard is that a performance cache must preserve actual
method labels, fixed seeds, exact inputs, generation source, and an executable
test that would detect silent drift.

## 12. Cross-Product Coverage

Covers local and external checks, Windows timing, installed workflows, function
map integrity, contrast semantics, cache provenance, licensing, author consent,
public documentation, pkgdown, exact tarball inventory, and merge to `main`.

This does NOT cover CRAN reviewer acceptance, mirror propagation, or public
package/check-page availability.
