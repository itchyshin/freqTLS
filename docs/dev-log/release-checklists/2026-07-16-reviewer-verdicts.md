# Release-verdict register — experimental 0.1.0

Candidate under review: `freqTLS_0.1.0.tar.gz`  
SHA-256: `53461c1bed3081e590f993665a63f733903cd791f08095bf35aaa3a759a7787b`  
Current rung: clean-checkout macOS technical candidate only; **NOT READY for upload**.

| Verifier | Required same-hash evidence | Current verdict |
|---|---|---|
| Grace | macOS, Ubuntu, and Windows checks; dependency and timing review | **NOT READY** — macOS check is clean; matching Ubuntu/Windows evidence is absent |
| Rose | source/tarball claims, component-rights ledger, rendered-surface audit, stale wording | **NOT READY** — local ledgers and scans are present, but clean post-merge candidate and final human review are absent |
| Pat | clean install, first fit, help/reference reading, articles, weak-identification recovery | **NOT READY** — automated examples/vignettes pass; independent new-user walkthrough is absent |

## Upload blockers

1. Final `Authors@R` order and each author's approval of that final order.
   Shinichi confirmed on 2026-07-16 that all co-authors authorise package use;
   Dan will resolve the order before submission.
2. A clean post-merge checkout that rebuilds this candidate identity (or records
   its replacement identity).
3. Matching Windows and Ubuntu evidence on that post-merge artifact.
4. Browser adjudication for the publisher DOI 403/504 responses in the URL/DOI
   ledger.
5. Grace, Rose, and Pat each inspect the same hash and replace their NOT READY
   verdict only with evidence attached to that artifact.

No upload, CRAN incoming, acceptance, archive, or live-CRAN claim is authorized
by this register.
