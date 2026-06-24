# After Task: Phase 0 -- Bootstrap team, memory, docs, and package scaffold

## Goal

Stand up the profileTLS team, dev-log memory, design docs, and package metadata
by adapting the drmTMB agent-kit to the profileTLS scope: a single-stage 4PL
thermal-load-sensitivity model fitted by maximum likelihood via TMB,
parameterised directly in `CTmax` and `z`, returning profile-likelihood
compatibility intervals (shown as Confidence Eyes, never posteriors), and
benchmarked against `bayesTLS`. No engine or R/ engine code is written in this
phase (that is Phase 1).

## Implemented

- Governance: `SPEC.md` (copied verbatim from the plan), `AGENTS.md`, `CLAUDE.md`,
  the 13 named and 4 job-function agents under `.claude/agents/` with 1-to-1
  `.codex/agents/` `.toml` mirrors, nine local skills under `.agents/skills/`,
  the SessionStart hook and `.claude/settings.json`, and the `docs/agent-kit/`
  reference plus the project-neutral templates.
- Memory: the `docs/dev-log/` tree (`check-log.md`, `decisions.md`,
  `known-limitations.md`, `team-improvements.md`, the eight empty subdirectories
  with `.gitkeep`, and the dashboard on port 8767), plus
  `tools/start-mission-control.sh` and `tools/checkpoint.R`.
- Docs: the design docs `00, 01, 02, 03, 04, 05, 06, 07, 10, 46, 90`;
  `ROADMAP.md`; the existing `NEWS.md` confirmed; `README.Rmd` extended with the
  start-here links, the preview status, the model equation, and the data credits.
- Metadata: the `DESCRIPTION` confirmed (four authors), a minimal hand-written
  `NAMESPACE`, `_pkgdown.yml` (destination set to `pkgdown-site`), the CI
  workflows confirmed/adjusted, `.Rbuildignore` extended, `.gitignore` corrected
  (pkgdown ignores `pkgdown-site/`, not `docs/`), `inst/COPYRIGHTS`, and
  `inst/CITATION`.

## Mathematical Contract

No likelihood or parameterisation code was written this phase, but the contract
the next phase must honour is recorded in `docs/design/01-model-and-parameterisation.md`
and `docs/design/03-likelihoods.md`: the descending 4PL
`p = low + (up - low) / (1 + exp(k * (log10(d) - mid)))` with the direct midpoint
`mid = log10(tref) - (T - CTmax) / z`, nested-gap asymptotes
`up = low + (1 - low) * plogis(beta_gap)`, the exact equivalence to the bayesTLS
constant-shape model (`z = -1/beta1`, `CTmax = Tbar + (log10(tref) - beta0)/beta1`),
and profile equivariance so the `z` interval is `exp()` of the `log_z` interval.

## Files Changed

Created: `AGENTS.md`, `CLAUDE.md`, `NAMESPACE`, `ROADMAP.md`,
`.claude/agents/*.md` (17), `.codex/agents/*.toml` (17), `.agents/skills/*/SKILL.md`
(9), `.claude/hooks/session-start.sh`, `.claude/settings.json`,
`docs/agent-kit/**` (16 files), `docs/design/{00,01,02,03,04,05,06,07,10,46,90}*.md`
(11), `docs/dev-log/{check-log,decisions,known-limitations,team-improvements}.md`,
`docs/dev-log/dashboard/{index.html,status.json,sweep.json,version.txt,README.md}`,
`docs/dev-log/*/.gitkeep` (8), `tools/{start-mission-control.sh,checkpoint.R}`,
`inst/COPYRIGHTS`, `inst/CITATION`, `SPEC.md`.
Edited: `README.Rmd`, `_pkgdown.yml`, `.Rbuildignore`, `.gitignore`,
`.github/workflows/pkgdown.yaml`.
Pre-existing (left as Phase-1 drafts, not modified): `DESCRIPTION`, `NEWS.md`,
`R/{families,model_matrix,profileTLS-package,utils}.R`,
`src/{init.c,profile_tls.cpp,profile_tls_numeric.h}`, the CI `R-CMD-check.yaml`.

## Checks Run

- `R -q -e 'desc::desc(file="DESCRIPTION")'` plus `get_authors()`: parses;
  Package `profileTLS`, License `GPL (>= 3)`, four authors (Nakagawa `[aut, cre]`;
  Noble, Arnold, Pottier `[aut]`).
- `R -q -e 'tools::toTitleCase("ok")'`: returns `Ok`.
- `R -q -e 'usethis::proj_get()'`: sets the active project to the repo root
  (valid R-package skeleton recognised).
- `R -q -e 'jsonlite::fromJSON("docs/dev-log/dashboard/status.json")'` and the
  same for `sweep.json` and `.claude/settings.json`: all valid JSON.
- `R -q -e 'utils::readCitationFile("inst/CITATION", meta=list(Package="profileTLS"))'`:
  2 entries (profileTLS + bayesTLS).
- `R -q -e 'parse("NAMESPACE")'`: 22 directives parse.
- `sh -n .claude/hooks/session-start.sh`, `sh -n tools/start-mission-control.sh`:
  pass.
- `Rscript tools/checkpoint.R --stdout`: writes a recovery checkpoint from git
  state.
- Dashboard served: `sh tools/start-mission-control.sh --background` then
  `curl http://127.0.0.1:8767/status.json` returned HTTP 200; the served bytes
  parse as JSON (7 phases, 13 agents, 7 matrix rows, Phase 0 `verified`); the
  index title is "profileTLS mission control".

## Tests Of The Tests

This is a scaffold-only phase, so there are no package unit tests yet. The
verification was structural: parse the metadata, validate the JSON the dashboard
serves (not just the file on disk), confirm the CITATION and NAMESPACE parse, and
confirm the agent mirrors are 1-to-1 by filename and structure. The `desc`
author check reads the parsed `Authors@R` roles rather than grepping the text, so
it would catch a malformed role vector.

## Consistency Audit

- `rg "rho12|meta_V|biv_gaussian|gamlss|sdmTMB"` over the adapted governance,
  agents, skills, design, and top-level docs: the only hit is the line in
  `check-log.md` that cites the audit pattern itself; no drmTMB-specific scope
  leaked into profileTLS files.
- `rg "posterior|credible"` over R, docs, governance, and skills: every hit is a
  deliberate boundary statement (heat-injury/posterior inference belongs to
  bayesTLS; "Confidence Eyes rather than posterior densities"; the R-POSTERIOR
  risk; "implying a posterior" in the figure contract). No profileTLS interval is
  described as a posterior or credible interval.
- The capability story is consistent across `ROADMAP.md`,
  `docs/dev-log/known-limitations.md`, `docs/design/46-capability-matrix.md`, and
  the dashboard `status.json`: all eight family x design x CI cells are planned
  for v0.1; bootstrap, Beta, time-to-event, random effects, and heat-injury are
  non-goals.

## GitHub Issue Maintenance

No GitHub issues were opened or closed: the repository is a fresh scaffold and
the issue tracker is empty. The dashboard and `ROADMAP.md` are the current work
ledger until issues are populated. This is recorded deliberately, not by
omission.

## What Did Not Go Smoothly

- The repository already contained a partial scaffold beyond the brief's stated
  "empty skeleton": `DESCRIPTION`, `NEWS.md`, `README.Rmd`, `_pkgdown.yml`, both
  CI workflows, four `R/` files, and three `src/` files. These were inspected and
  found to match the SPEC, so they were kept (and `README.Rmd`/`_pkgdown.yml`
  were extended rather than rewritten). The pre-existing `src/` and `R/` files
  are Phase-1 drafts; this Phase-0 task did not modify their logic.
- A real conflict surfaced: the existing `.Rbuildignore` and `.gitignore` ignored
  `docs/` (the conventional pkgdown output), but the SPEC places the governance
  tree (`docs/design`, `docs/dev-log`, `docs/agent-kit`) under `docs/`. Resolved
  by setting the pkgdown `destination: pkgdown-site`, ignoring `pkgdown-site/` in
  `.gitignore`, keeping `^docs$` in `.Rbuildignore` (so the governance tree is
  not shipped in the package tarball but is tracked in git), and pointing the
  pkgdown CI upload at `pkgdown-site`. This is the main deviation from a literal
  reading of the inherited ignore files; it is noted in the decisions log context
  and the `_pkgdown.yml` comment.
- `MEMORY.seed.md` from the drmTMB template set was intentionally omitted:
  profileTLS keeps its memory in `docs/dev-log/`, and there is no external memory
  system to seed for this repo.

## Team Learning

- Generating the `.codex/agents/*.toml` mirrors programmatically from the
  `.claude/agents/*.md` files (parsing the frontmatter, mapping opus -> high and
  sonnet -> medium) guarantees the two runtimes cannot drift in their instruction
  bodies. Regenerate rather than hand-edit both. Recorded in
  `docs/dev-log/team-improvements.md`.
- Two profileTLS-specific review skills were added beyond the drmTMB set:
  `profile-ci-review` (equivariance, chi-square calibration, open/boundary/
  multimodal handling) and `benchmark-vs-bayesTLS-audit` (fair config, cache
  provenance, R-SHRIMP). New model classes should get their own targeted skills.

## Known Limitations

As of this phase the repository is a scaffold: there is no engine, no `fit_tls()`
implementation, no profile machinery, no plotting, and no benchmark. Every
capability in `docs/design/46-capability-matrix.md` is `planned`. The pre-existing
`src/profile_tls.cpp` and `R/` helpers have not been compiled or tested in this
phase. `devtools::check()` and `devtools::test()` were not run (there is nothing
to test yet, and a full check would need the engine to compile); they are the
Phase-1 gate.

## Next Actions

Phase 1 (Gauss + Noether, with Emmy). The scaffold hands the engine these
contracts:

- **NAMESPACE / imports contract.** `R/profileTLS-package.R` carries the roxygen
  `@useDynLib profileTLS, .registration = TRUE` plus the `@importFrom` tags;
  `devtools::document()` will regenerate `NAMESPACE` from those tags and the
  `@export` tags on new functions. The current hand-written `NAMESPACE` declares
  the DLL, the existing `cli`/`stats`/`TMB`/`utils` imports, and the two family
  constructors; extend the imports as new R files are added (e.g. `rlang` for the
  tidy-eval `fit_tls()`, `Matrix`, `tibble`, `ggplot2` in Phase 4).
- **Where src/ and R/ go.** TMB C++ lives in `src/` (the draft
  `profile_tls.cpp`, `profile_tls_numeric.h`, `init.c` are already present and
  match `docs/design/03-likelihoods.md`); the R engine lives in `R/`
  (`families.R`, `model_matrix.R`, and `utils.R` exist; add `fit_engine.R`,
  `fit_tls.R`, and `simulate.R`). Compile with `pkgbuild`/`devtools::load_all()`,
  fit binomial and beta-binomial simulations, and add
  `tests/testthat/test-parameter-transforms.R`.
- The Phase-1 gate (from `ROADMAP.md`): the package compiles; both families fit
  with finite logLik and convergence code 0; `CTmax` and `z` recovered near
  truth; the transforms test is green. Close Phase 1 with a check-log entry and
  an after-phase report, and flip the dashboard Phase 1 status from `queued` to
  `active`/`verified`.
