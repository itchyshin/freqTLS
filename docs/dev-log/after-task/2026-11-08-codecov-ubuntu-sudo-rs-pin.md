# After Task: Ubuntu sudo-rs r-lib/actions pin repair (PR 65)

## Goal

Bounded CI-only compatibility repair on the same freqTLS Codecov PR after
the coordinator assigned the slot. The first-pass `test-coverage` and
Ubuntu R-CMD-check jobs died in `setup-r-dependencies` before covr. Move
the r-lib action pin to the released SHA that fixes Ubuntu 26.04
`sudo-rs`, without changing tests, the OS/R matrix, or Codecov auth.

## Implemented

Pinned `r-lib/actions` `{setup-pandoc,setup-r,setup-r-dependencies,check-r-package}`
from `d3c5be51` (`v2.12.1`) to immutable commit
`f9a764fea8d5c63df6ef9a5c7795bf7deb5d7e05` (released tag `v2.14.0`) in
`test-coverage.yaml`, `R-CMD-check.yaml`, and `pkgdown.yaml`. pkgdown uses
the same ubuntu-latest pin and would hit the same sudo-rs failure after
an authorized main merge.

Codecov OIDC, `after_n_builds: 1`, ubuntu-only coverage upload, and the
four-platform check matrix are unchanged.

## Mathematical Contract

Untouched.

## Files Changed

- `.github/workflows/test-coverage.yaml`
- `.github/workflows/R-CMD-check.yaml`
- `.github/workflows/pkgdown.yaml`
- `docs/dev-log/dashboard/test-coverage.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-11-08-codecov-ubuntu-sudo-rs-pin.md`

No `R/`, `src/`, `tests/`, fixtures, NEWS, DESCRIPTION, capability, or
README edits.

## Checks Run

Exact commands are in `docs/dev-log/check-log.md`. YAML parse and pin
assertions only. `Rscript` / `R` **ABSENT**. Local covr **NOT_VERIFIED**.
Hosted CI after the push is **NOT_VERIFIED** at write time.

## Tests Of The Tests

Did not add, skip, or weaken tests. Matrix, timeouts, and existing
`skip_on_cran` / `skip_if_not` guards stay.

## Consistency Audit

Public model claims unchanged. Docs state that the pin is compatibility
evidence, not a coverage percentage. Codecov upload on the previous run
was skipped, so this is not a grant/token moment.

## GitHub Issue Maintenance

No open freqTLS issues. Tracker unchanged. Upstream evidence is
r-lib/actions#1094 / #1096.

## What Did Not Go Smoothly

Current `ubuntu-latest` is Ubuntu Resolute / 26.04 with sudo-rs, which
the June `v2.12.1` pin does not handle. Windows and macOS already passed
on that pin.

## Team Learning

Pin r-lib actions to a released full-length SHA that includes runner
fixes, rather than pinning an older Ubuntu image as the first response.

## Known Limitations

CI coverage finish, upload transaction, processed commit report, and main
baseline remain **NOT_VERIFIED** until hosted jobs and Codecov produce
them. This lane does not merge. After this pass, all future wakes are
evidence-only; no further coding without explicit coordinator assignment.

## Next Actions

Push, let fresh CI start, hand off. Coordinator reviews logs before any
further edit.
