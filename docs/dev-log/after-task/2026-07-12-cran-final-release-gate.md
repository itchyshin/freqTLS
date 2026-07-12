# After Task: CRAN Final Release Gate

## 1. Goal

Close the external platform, author-consent, and independent completion gates
for the exact freqTLS 0.1.0 CRAN candidate.

## 2. Implemented

Recorded the successful replacement GitHub, R-hub, and win-builder results;
recorded the maintainer's dated attestation that all three co-authors confirmed
their `aut` roles; updated `cran-comments.md`; and ran fresh Grace, Rose, and Pat
release audits. No package code, installed documentation, data, or tarball bytes
changed.

## 3a. Decisions and Rejected Alternatives

The release retains Pieter A. Arnold, Patrice Pottier, and Daniel W. A. Noble as
authors because the maintainer confirmed their agreement. The repository stores
the maintainer's attestation rather than private correspondence. We did not
remove `cli` after the first win-builder infrastructure failure because the
replacement run installed it and checked the package successfully. We did not
change `TLS` or the valid British spelling `reparameterised` merely to silence
spell-check flags; `cran-comments.md` explains them.

## 4. Files Touched

- `cran-comments.md`
- `docs/dev-log/after-task/2026-07-12-cran-final-release-gate.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/decisions.md`
- `docs/dev-log/release-gates/2026-07-11-cran-0.1.0.md`

## 5. Checks Run

- `git rev-parse HEAD` -> release artifact commit
  `3fe45a942f80e58c3233cb8ff8ffd354ce96842a`.
- `shasum -a 256 freqTLS_0.1.0.tar.gz` ->
  `1a8d1248a9517e2ba6df2cc595e181d3cc9846f52b868fdec61caac55326b331`.
- `gh run view 29177778758 --json status,conclusion,headSha,jobs` -> success;
  Ubuntu release/devel, Windows release, and macOS release passed at `3fe45a9`.
- `gh run view 29177783632 --json status,conclusion,headSha,jobs` -> success;
  R-hub Ubuntu/clang passed at `3fe45a9`.
- `curl -fsSL https://win-builder.r-project.org/4xKTjl6D6WT4/00check.log` ->
  `Status: 1 NOTE`; installation, compiled code, examples, tests, vignettes,
  and PDF/HTML manuals passed. The NOTE contains `New submission` and spell
  checks for `TLS` and `reparameterised`.
- `gh issue list --state open --limit 100 --json number,title,url` -> no open
  issues.
- `git diff --check` -> clean.
- Grace -> READY; Pat -> READY; Rose -> substantively READY with one process
  condition: commit and push this evidence batch and confirm a clean tree.

## 6. Tests of the Tests

The first win-builder attempt demonstrated that the gate distinguishes a server
dependency failure from a package check: it stopped before installation and was
not promoted as evidence. The replacement run exercised installation, compiled
code, examples, tests, and vignette rebuilding. Pat independently installed the
exact tarball in a temporary library, ran the README workflow and exported
examples from a neutral directory, rendered the installed vignette, and counted
69 SVG text nodes, 27 rectangles, and zero `<em>` elements.

## 7a. Issue Ledger

- `WIN-INFRA`: closed by the successful replacement win-builder run.
- `AUTHOR-CONSENT`: closed by the maintainer's 2026-07-12 attestation.
- `LANDED-EVIDENCE`: closed by the commit containing this report and the four
  gate records; Rose must confirm the clean pushed state before upload.
- GitHub has no open issues, so no issue comment or duplicate issue was needed.

## 8. Consistency Audit

Grace checked exact-artifact checksums, inventory, CRAN mechanics, local and
external platform evidence, and `cran-comments.md`. Rose checked all 20 shipped
data/extdata ledger entries, CC BY-NC wording, excluded snow-gum, Kristineberg,
and environmental traces, author roles, consent, and false release claims. Pat
checked clean installation, first fit, intervals, prediction, diagnostics,
examples, all 12 installed vignettes, neutral-directory rendering, and the
function map. Historical reports were not rewritten; current decisions and
release gates explicitly supersede their pending state.

## 9. What Did Not Go Smoothly

The first win-builder server lacked `cli` and `curl`, so no package check ran.
The replacement completed normally. The closeout generator initially resolved
the requested relative report path against the Shinichi hub rather than this
worktree; that empty scaffold was removed immediately and this report was added
to the package repository explicitly.

## 10. Known Residuals

CRAN has not yet accepted or published freqTLS. The submission confirmation
email, CRAN review, and public package/check pages remain external gates. NEWS
honestly labels 0.1.0 a release candidate until publication.

## 11. Team Learning

Memory receipt: `route.py` returned no package-specific LOAD-FIRST manifest, so
the repository `AGENTS.md`, `SPEC.md`, ultra-plan, release-readiness,
after-task-audit, and prose-style-review instructions governed the closeout.
They required exact-artifact evidence, three fresh adversarial views, explicit
negative space, and a superseding record rather than rewriting history.

Golden Set: not in scope; this task changed release evidence only and introduced
no known cross-repository mistake class or implementation behavior.

## 12. Cross-Product Coverage

Covers: the exact local source tarball; macOS local checks; GitHub Ubuntu
release/devel, Windows release, and macOS release; R-hub Ubuntu/clang;
win-builder R-devel; shipped-data licensing inventory; author confirmation;
CRAN comments; installed-user workflows; and landing-page SVG installation.

This does NOT cover CRAN reviewer acceptance, CRAN mirror propagation, public
package/check-page availability, or downstream user reports after release.
