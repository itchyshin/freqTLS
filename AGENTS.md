# freqTLS Agent Instructions

`freqTLS` is an R package for maximum-likelihood and profile-likelihood
inference on single-stage four-parameter logistic (4PL) thermal-load-sensitivity
(thermal death-time) models, fitted via Template Model Builder (TMB).

These instructions are for Codex, Claude Code, and any other coding agent
working in this repository. Repository files are authoritative. Hidden memory
may help route work, but it must not be the only record of a design decision,
validation result, or release boundary. Read this file first; it is the source
of truth for project rules. The canonical SPEC is `SPEC.md`; read it before any
implementation slice.

## Core Scope

- Fit one model class: the single-stage 4PL thermal-load-sensitivity model,
  `p = low + (up - low) / (1 + exp(k * (log10(duration) - mid)))`, with the
  midpoint reparameterised **directly** in `CTmax` and `z` (thermal
  sensitivity) so that both headline quantities are direct, profile-able
  coordinates.
- Support count responses (`binomial`, `beta_binomial`) and continuous
  proportions in `(0, 1)` (`beta`), with precision/overdispersion parameter
  `phi` for the latter two families.
- Return Wald, profile-likelihood, and parametric-bootstrap confidence
  intervals. Profile intervals are available for supported direct fixed-effect
  targets; `up`, variance components, and general shape slopes use the
  documented Wald/bootstrap routes. Display intervals as Confidence Eyes,
  never posterior densities.
- Use the constant-shape, midpoint-only configuration by default so the
  `bayesTLS` benchmark remains matched. Optional independent fixed-effect
  designs may model `low`, `up`, and `log_k` outside that benchmark.
- Support column and `tls_bf()` formula interfaces, fixed effects on direct
  coordinates, and one independent random intercept per supported coordinate
  (`CTmax`, `log_z`, `low`, `log_k`).
- Benchmark freqTLS against `bayesTLS` (Bayesian) and the classical two-stage
  estimator on shared, vendored datasets, using a version-stamped cache.

`freqTLS` implements the thermal-load-sensitivity modelling framework
introduced by Daniel W. A. Noble, Pieter A. Arnold, and Patrice Pottier in the
`bayesTLS` package. The model and the mapping from the 4PL midpoint slope to `z`
and `CTmax` are theirs; freqTLS contributes the TMB likelihood, the direct
`CTmax`/`log_z` reparameterisation, and the profile-likelihood machinery.

### Experimental 0.1.0 release boundary

Version `0.1.0` ships the Beta family, formula interface, limited
independent random intercepts, shape formulas, deterministic heat-injury
prediction, bootstrap intervals, and Confidence Eyes. All remain experimental.

These capabilities are not implemented and must not be described as available:

- Censored time-to-event, hurdle Gamma/lognormal productivity, and multi-trait
  or multivariate responses.
- Fitting heat-injury or repair-rate sub-models. Deterministic heat-injury
  prediction from a fitted 4PL and user-supplied repair scenarios are supported.
- Absolute-threshold default (the default is the **relative** threshold).
- Correlated, random-slope, crossed, nested, or multiple random effects per
  coordinate; any random effect on `up`.
- Universal profile support for `up`, variance components, or general
  continuous shape slopes.
- Submission remains subject to the exact-candidate checks and rights ledger.

General distributional regression belongs to `drmTMB`. The full Bayesian
workflow, heat-injury models, and posterior inference belong to `bayesTLS`.

### Teaching-template contract

The empirical teaching baseline is the `bayesTLS` supplement rendered
2026-07-14 from commit `76510412e06c594c96894a1baba1f0e1a34a5aea`.
Canonical active cases are oxygen-gradient zebrafish, cereal aphids, Snow-gum
PSII, and the mortality and awake/coma endpoints from the two *Drosophila
suzukii* examples. Brown shrimp and life-stage zebrafish remain unpublished
benchmark-only compatibility data: do not use them in active tutorials,
navigation, README examples, current comparison tables, or generated discovery
surfaces.

### Canonical terms

Keep these stable across code, docs, tests, equations, and issues:
`CTmax`, `z`, `log_z`, `low`, `up`, `k`, `phi`, `mid`, `tref`, `family_code`
(0 = binomial, 1 = beta-binomial, 2 = beta), `relative` vs `absolute` threshold. Use
"confidence" interval language; never "posterior" or
"credible".

## Design Rules

1. Do not add a response family without simulation parameter-recovery tests.
2. Do not add user-facing functions without roxygen2 documentation and at least
   one runnable example.
3. Do not change the model parameterisation (the `CTmax`/`z`/`mid` mapping or
   the disjoint-bounds asymptotes) without updating
   `docs/design/01-model-and-parameterisation.md`.
4. Do not change likelihood parameterisation (the binomial or beta-binomial NLL,
   the `phi` convention, the probability clamp) without updating
   `docs/design/03-likelihoods.md`.
5. Do not change the profile-likelihood algorithm, targets, transforms, or the
   identifiability warnings without updating
   `docs/design/04-profile-likelihood.md`.
6. Keep the benchmark configuration constant-shape and midpoint-only. Shape
   predictors outside that benchmark must remain explicit and documented in
   `docs/dev-log/decisions.md`.
7. Every meaningful change should update `docs/dev-log/check-log.md` with exact
   command text and an interpretation, not a summary.
8. Every completed task or phase should create an after-task or after-phase
   report following `docs/design/10-after-task-protocol.md`.
9. If code is ported or closely adapted from `drmTMB`, `gllvmTMB`, or another
   package, document the source file, license, and adaptation in
   `inst/COPYRIGHTS` before treating the change as complete. Record each data
   component's source-specific licence in the data ledger and attribution files.
   Snow-gum source material is CC BY-NC 4.0 and ships as a separately licensed
   component with attribution, source URL, transformation record, and Pieter A.
   Arnold's recorded holder authorization. Do not imply that its licence applies
   to the package code or other datasets.
10. Keep public capability synchronized in one commit: when a capability is
    added or removed, update `README.Rmd`, `ROADMAP.md`, `NEWS.md`,
    `docs/dev-log/known-limitations.md`, `docs/design/46-capability-matrix.md`,
    and the relevant design doc together. Check PR overlap before editing shared
    files (`check-log.md`, `known-limitations.md`).
11. Keep pull requests small and focused. No agent should revert another agent's
    or human's work without explicit instruction.

## Standard Commands

```r
devtools::document()
devtools::test()
devtools::check()
pkgdown::check_pkgdown()
```

Project-specific commands:

```sh
Rscript tools/checkpoint.R --goal "current task" --next "next command or edit"
sh tools/start-mission-control.sh --background   # local dashboard on port 8767
Rscript data-raw/build_benchmark_cache.R          # maintainer-only: bayesTLS cache
```

## Recovery Checkpoints

For long runs, stream failures, or handoffs, create a compact recovery
checkpoint before continuing:

```sh
Rscript tools/checkpoint.R --goal "current task" --next "next command or edit"
```

The script writes a Markdown snapshot under
`docs/dev-log/recovery-checkpoints/` with git status, changed files, diff stat,
the newest check-log evidence, newest after-task reports, and exact commands for
the next agent to rerun. A checkpoint is only a handoff aid: repository state is
authoritative, so always rerun the following before editing:

```sh
git status --short --branch
git diff --stat
git diff
```

## Definition of Done

A feature is done only when implementation, tests, documentation, examples,
check logs, after-task notes, and review are all present. If one of those is not
appropriate, the after-task report must say why.

The adversarial Definition-of-Done gate before "core done" is **Rose + Pat +
Fisher**: Rose audits stale wording, consistency, and the R-SHRIMP data fix; Pat
confirms a new user can fit a model, interpret the output, and read the
identifiability warnings; Fisher confirms profile equivariance
(`ci_z == exp(ci_log_z)`), identifiability handling, and a fair benchmark.

## Writing Style

For user-facing prose, developer notes, after-task reports, and release text,
write for a named reader and keep the prose concrete. The main readers are
thermal-biology ecologists and evolutionary biologists, plus statistical method
developers and R package contributors.

- Name the purpose before mechanics.
- Pair symbolic equations, R syntax, and interpretation when explaining the
  model.
- Use concrete terms, files, equations, functions, or numerical results rather
  than vague phrases such as "various factors" or "significant improvements".
- Use active voice when the agent matters.
- Do not turn prose into bullets unless the content is a genuine list.
- Keep terms stable: `CTmax`, `z`, `log_z`, `low`, `up`, `k`, `phi`, `mid`,
  `tref`, `relative` / `absolute` threshold should not drift across documents.
- Use "confidence" interval language. Never describe a
  freqTLS interval as a "posterior" or "credible" interval; that is the
  `bayesTLS` path, and conflating the two misleads the reader.
- Support factual, statistical, or literature claims with a citation, local
  evidence, or a clear note that the statement is a design assumption.
- Define `CTmax` (the critical thermal maximum at the reference time `tref`),
  `z` (the thermal sensitivity, degrees per decade of duration), and the
  relative-vs-absolute threshold at first use.
- For tutorials and error-message docs, tell the reader what to try next when a
  model or design is weakly identified (the warnings in
  `docs/design/04-profile-likelihood.md` point users to `bayesTLS` or bootstrap
  when the profile does not close).

Use the project-local `prose-style-review` skill for substantial README,
vignette, pkgdown, after-task, release, or paper-oriented text.

## Multi-Agent Collaboration

Codex and Claude Code may both contribute to this repository. All agent work
must follow the same project rules:

- preserve the experimental 0.1.0 single-stage 4PL scope, including the tested
  count and Beta families, while respecting every unsupported boundary above;
- avoid unreviewed likelihood or parameterisation changes;
- update design docs when the model, likelihood, profile algorithm, or benchmark
  protocol changes;
- add tests with implementation;
- do not revert changes made by another agent or human unless explicitly asked;
- prefer small, reviewable commits or pull requests.

When an agent hands work to another agent, leave enough context in
`docs/dev-log/check-log.md` or the relevant issue/PR for the next agent to
continue without rediscovering the whole problem.

The launchable team agents live in two mirrored directories: `.codex/agents/`
for Codex and `.claude/agents/` for Claude Code. The two sets are one-to-one and
share verbatim instruction bodies. When an agent is added or its instructions
change, update both directories in the same change so the runtimes do not drift.

### Name to agent map

| Name | Perspective | Claude / Codex file |
| --- | --- | --- |
| Ada | Orchestrator and integrator | `integration-reviewer` |
| Gauss | TMB likelihood and numerics | `tmb-engineer` |
| Noether | Mathematical consistency | `math-consistency-reviewer` |
| Fisher | Statistical inference | `inference-reviewer` |
| Emmy | R-package architecture | `architecture-reviewer` |
| Boole | R API and formula | `formula-reviewer` |
| Curie | Simulation and testing | `simulation-tester` |
| Florence | Scientific figure editor | `figure-reviewer` |
| Darwin | Ecology / evolution audience | `audience-reviewer` |
| Pat | Applied PhD-student user-tester | `user-tester` |
| Jason | Landscape / source-map scout | `landscape-scout` |
| Grace | CI / pkgdown / CRAN / reproducibility | `reproducibility-engineer` |
| Rose | Systems auditor | `systems-auditor` |

Plus job-function agents: `reviewer`, `documentation-writer`, `pkgdown-editor`,
`literature-curator`.

### Phase ownership

P0 Ada + Grace + Rose; P1 Gauss + Noether (+ Emmy); P2 Emmy + Boole + Curie;
P3 Fisher + Gauss + Pat; P4 Florence + Darwin (parallel with) P5 Curie + Jason +
Rose; P6 documentation-writer + pkgdown-editor + Pat + Darwin +
literature-curator + Grace.

## Standing Review Roles

These names are shorthand for recurring review perspectives. They do not run
continuously; the orchestrator should launch them only for bounded tasks. Use
these canonical names when reporting team perspectives; do not rename them in
status updates or project notes.

| Name | Role | Primary questions |
| --- | --- | --- |
| Ada | Orchestrator and integrator | What should happen next, and are code, math, docs, tests, pkgdown, and git consistent? |
| Boole | R API and formula reviewer | Is the `fit_tls()` surface memorable, parseable, and internally consistent? |
| Gauss | TMB likelihood and numerical reviewer | Is the 4PL likelihood correct and numerically stable? |
| Noether | Mathematical consistency reviewer | Do the symbolic equations, R syntax, and TMB implementation describe the same direct-`CTmax`/`z` model? |
| Darwin | Ecology / evolution audience reviewer | Does the example answer a real thermal-biology question for the target audience? |
| Florence | Scientific figure editor and visualization reviewer | Are plots publication-quality, interpretable, and honest about uncertainty, with the Confidence Eye as the default? |
| Fisher | Statistical inference reviewer | Do simulations, comparator checks, likelihood profiles, equivariance, and identifiability diagnostics support the claim? |
| Pat | Applied PhD student user tester | Can a new applied user follow the tutorial, interpret output, recover from warnings, and avoid hidden jargon? |
| Jason | Landscape and source-map scout | What do `bayesTLS`, `drmTMB`, and the thermal-biology literature already do, and what should freqTLS learn or avoid? |
| Curie | Simulation and testing specialist | Do recovery tests cover ordinary, edge, and malformed-input cases without becoming too slow? |
| Emmy | R package architecture reviewer | Are the `profile_tls` S3 object, methods, extractors, and internal APIs coherent? |
| Grace | CI, pkgdown, CRAN, and reproducibility engineer | Will this pass on all platforms, deploy cleanly, and avoid compiled-code or dependency risk? |
| Rose | Systems auditor | What discrepancies, repeated mistakes, stale wording, unsupported claims, and missing feedback loops are accumulating? |

Figure quality is shared work. Florence leads the final scientific-figure
standard, but Pat, Fisher, Rose, Darwin, Grace, Boole, and Noether should help
before a figure reaches her: they should notice missing uncertainty, wrong data
grain, a figure that implies a posterior, weak reader guidance, stale claims,
failed render evidence, and figures that are technically present but visually
unhelpful. Use the project-local `figure-visual-audit` skill when plots, figure
galleries, simulation graphics, or rendered pkgdown pages are under review.

## Team Improvement Loop

When a task exposes a better way for the team to work, record it in
`docs/dev-log/team-improvements.md`. Low-risk documentation, process, and local
skill improvements can be implemented immediately. Product, architecture, or
validation-policy changes need a normal task, evidence, and review.

## pkgdown Policy

The pkgdown site is a first-class project artifact. User-facing features should
include reference documentation and, when substantial, an article or tutorial.
Keep `_pkgdown.yml` synchronized with exported functions and vignettes. The
built site is written to `pkgdown-site/` (kept out of the package build) so it
does not collide with the durable `docs/` governance tree.

<!-- shinichi-hub -->
> Read first — personal operating contract and second brain:
> `/Users/z3437171/Dropbox/Github Local/Shinichi/AGENTS.md` (repository rules
> override the hub where they differ).
