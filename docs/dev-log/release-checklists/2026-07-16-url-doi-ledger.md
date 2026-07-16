# URL and DOI ledger — experimental 0.1.0

Date: 2026-07-16  
Method: `curl -L --max-time 20` against the distinct public URLs extracted from
DESCRIPTION, copyright/citation files, README, R sources, vignettes, and design
notes. A transport status is evidence about reachability, not evidence that a
scholarly record is invalid.

## Result

- All package, GitHub, pkgdown, GPL, lifecycle, TMB, bayesTLS, drmTMB, Zenodo,
  and directly reachable DOI URLs returned HTTP 200.
- The historical `JenniNiku/gllvmTMB` provenance URL returned 404. It was
  corrected to the repository's actual origin,
  `https://github.com/itchyshin/gllvmTMB`.
- Seven publisher DOI URLs returned HTTP 403 and one returned HTTP 504 from the
  automated client. These are publisher/CDN access outcomes, not dead-link
  evidence; the DOI strings remain bibliographic identifiers in the cited
  sources. They require a maintainer browser check before upload if CRAN's URL
  checker reports them again.

| Class | Count | Outcome |
|---|---:|---|
| HTTP 200 | 17 | reachable |
| HTTP 403 | 7 | publisher access-control response; retain DOI |
| HTTP 504 | 1 | publisher/CDN timeout; retain DOI pending browser check |
| HTTP 404 | 1 | corrected source URL |

## Remaining release action

Record browser adjudication of the 403/504 DOI destinations with the submission
evidence. Do not remove valid bibliographic DOI identifiers merely because an
automated client receives a publisher access-control response.
