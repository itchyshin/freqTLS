# After-task: freqTLS 0.1.0 CRAN-readiness implementation

## Task goal

Implement the approved release plan without disturbing the original dirty
checkout: publish the function-map repair separately, correct licensing and
provenance, reconcile the 0.1.0 contract, remove CRAN blockers, and verify an
exact source tarball. Submission remains conditional on external consent and
independent platform/release gates.

## What was implemented

The focused landing-page repair was merged and deployed first. The live SVG now
contains 69 text nodes, 27 rectangles, zero `<em>` elements, and no stray page
text.

The CRAN work lives on the clean `codex/cran-readiness` branch. Unused Suggests
were removed; normal Suggests checking and a four-job platform matrix were
restored; `output/`, `scripts/`, `.git`, and `cran-comments.md` received anchored
build exclusions; bootstrap parallelism now warns and caps requests above two
cores; broken roxygen links/blocks and stale benchmark skips were repaired; and
lightweight runnable examples were added to the exported topics that lacked
them.

Snow-gum was corrected from CC BY 4.0 to CC BY-NC 4.0. With no compatible
written permission recorded, its processed data, raw files, and vignette were
moved to `data-raw/licensing-pending/snowgum/`. Snow-gum was removed from
installed data, help, tests, site navigation, summaries, and the benchmark
cache. The unlicensed Kristineberg extract was moved to the corresponding
build-excluded area. The component ledger covers every installed data file.

Canonical and public documents now describe one 0.1.0 release candidate:
binomial, beta-binomial, and beta responses; column and formula interfaces;
fixed/grouped shape designs; limited independent random intercepts;
Wald/profile/bootstrap intervals; prediction; and deterministic heat-injury
scenarios. Claims are restricted to the matched relative-threshold,
constant-shape `bayesTLS` configuration. Universal-interval, unrestricted
package-switch, and already-released wording was removed.

## Mathematical contract

The 4PL likelihood, direct `CTmax`/`log_z` mapping, disjoint asymptote bounds,
and profile-likelihood algorithm were not changed. The only inferential runtime
change is operational: bootstrap requests above two cores warn and run with two,
while one- and two-core requests retain their existing deterministic behaviour.

## Files and artefacts

Changes span package metadata, CI workflows, R documentation/examples,
bootstrap tests, README/NEWS/roadmap/specification, current design/governance
documents, package data provenance, vignettes, pkgdown navigation, and generated
Rd/README outputs. The exact local candidate is `freqTLS_0.1.0.tar.gz` (1,864,624
bytes; 1.78 MiB,
211 entries; SHA-256
`7c2594a27ea9da6e61689a417d510827c0ba21ecb3fcb3f819ad656a81a7e8c5`). It
contains none of the permission-pending or governance material.

## Checks and tests of the tests

Exact commands and outcomes are recorded in `docs/dev-log/check-log.md`.
Highlights are a full source-tree test run with no failures, warnings, or skips,
a clean `check_man()`, clean
`devtools::check()`, clean pkgdown metadata and full site build, and strict
`R CMD check --as-cran` with only the expected new-submission NOTE. The new
parallelism test asks for eight cores and confirms the result matches an
explicit two-core run while emitting the cap warning. The benchmark test now
runs against the retained cache rather than carrying an unconditional skip.
The public-site build also asserts that internal governance pages and their
search/sitemap entries are absent and that the function map retains exactly 69
text nodes, 27 rectangles, and zero `<em>` nodes.

## Consistency and prose audit

The README, ROADMAP, NEWS, AGENTS, SPEC, known limitations, capability matrix,
benchmark protocol, DESCRIPTION, pkgdown navigation, data documentation, and
current decisions were reviewed together. Historical after-task and checkpoint
records were preserved; the dated licensing decision supersedes their erroneous
CC BY inference. Current installed/package-facing paths contain no snow-gum or
Kristineberg consumers.

## GitHub issue maintenance

The repository had no open issue overlapping this release work, so no issue was
opened or closed. The landing repair was handled in focused PR #1. The wider
release branch still needs its own review PR and CI run.

## What did not go smoothly

The first integrated check caught escaped `\\donttest{}` markup in new examples
and two missing build exclusions. That failed check was retained in the log;
the fixes were documented, regenerated, and the full check was rerun cleanly.
Automated DOI requests returned 403 from publisher endpoints, so all seven DOI
registrations were independently confirmed through Crossref.

The first Sol adversarial pass correctly rejected the candidate because the
tarball and generated site predated final wording/cache corrections. It also
found remaining universal-interval, package-switch, dataset-count, and snow-gum
cache claims. Those findings were corrected and all generated artefacts were
rebuilt. During that rebuild, the new search-index cleanup exposed a pkgdown
record without a scalar `path`; the filter now handles that case, and the full
site build was rerun successfully.

The second Sol pass rejected the replacement candidate for an unpinned
benchmark cache, remaining relative-versus-absolute threshold ambiguity,
installed-user help that pointed to excluded governance files, and an unsafe
privileged pkgdown trigger. The cache was rebuilt against verified `bayesTLS`
commit `578740f20f3a2e6e81b3b700b1d0f0e5a06ecf8a`; model-based and classical
comparators are now distinguished explicitly; installed help points only to
installed vignettes/functions; and pkgdown deployment is gated on a successful
`main` check. The final cache metadata and vignette captions also state that the
classical two-stage route estimates absolute LT50. A new exact tarball was then
built and passed strict checking.

The third Sol pass rejected that candidate because the privileged pkgdown
workflow did not prove a trusted push; the installed profile tutorial described
strict-open behavior while executing the default bootstrap fallback; and current
scope, citations, cache schema, bounds, random-effects guidance, and recovery
instructions still had contradictions. Grace, Rose, and Pat remediated disjoint
slices, followed by a neighbor sweep and full regeneration. The replacement
artifact above passed both `devtools::check()` with no findings and strict
`R CMD check --as-cran` with only the incoming new-submission NOTE.

The fourth Sol pass approved the local technical mechanics but rejected the
public contract because formula prose implied independent fixed predictors for
`CTmax` and `log_z`, while the parser requires the same model-matrix columns,
and because README prose implied a lens for strict open profiles. Formula,
README, installed help, specification, capability, and limitation prose now
state the shared-column constraint, and strict open profiles are consistently
described as a hollow point with no lens. The exact replacement artifact above
then passed strict checking.

The fifth Sol pass retested the exact artifact and found deeper user-facing
defects: continuous headline fixed designs were accepted but not rebuilt for
prediction; random-effect predictions silently omitted BLUPs; canonical
no-lens, benchmark, and beta-family wording still drifted; installed shrimp and
life-stage zebrafish help lacked the promised source-specific attribution; two
examples remained hidden; and manual pkgdown deployment bypassed the successful-
check gate. Prediction now rebuilds continuous designs and exposes explicit
population/conditional random-effect behavior with tests. Documentation,
dataset help, examples, bootstrap warning handling, and workflow trust boundaries
were corrected and regenerated. The replacement artifact above passes
`devtools::check()` with no findings and strict checking with only the incoming
new-submission NOTE.

## Ultra-plan, compute, and team learning

The initial fan-out did not explicitly assign Luna/Terra/Sol because the
collaboration interface exposed no per-agent model control. The release gate now
records the intended routing: Luna for bounded inventories, Terra for coding and
Pat's installed-user pass, and Sol for Ada/Rose/Grace verification. No new
simulation campaign is justified for this packaging release. If statistical
evidence fails later, Totoro is the rehearsal host and DRAC the claim-bearing
rerun, with estimand, grid, seeds, stopping rule, resources, and provenance
specified before launch.

## Known limitations and next actions

Local readiness is established, not submission readiness. Push the release
branch, open the CRAN-readiness PR, pass Ubuntu release/devel, Windows release,
and macOS release, then check the exact tarball on win-builder R-devel and R-hub
Linux/clang. Rerun the independent Grace/Rose/Pat completion adversary on the
landed, platform-checked candidate. Finally,
record written consent from Pieter A. Arnold, Patrice Pottier, and Daniel W. A.
Noble before retaining their `aut` roles and uploading. Do not claim the package
is on CRAN until its public CRAN package and check pages exist.
