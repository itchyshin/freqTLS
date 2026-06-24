# <PROJECT> Agent Instructions

`<PROJECT>` is an R package for <one-sentence purpose>.

These instructions are for Codex, Claude Code, and any other coding agent
working in this repository. Repository files are authoritative. Hidden memory
may help route work, but it must not be the only record of a design decision,
validation result, or release boundary.

## Core Scope

- Supported problem class: <statistical modelling / machine learning /
  agent-based modelling / data wrangling / other>.
- Primary users: <applied users, method developers, package contributors>.
- Primary workflows: <fit, predict, simulate, wrangle, visualize, deploy>.
- Current non-goals: <list what belongs in another package or later phase>.
- Canonical terms: <parameter names, data objects, model names, schema names>.

## Design Rules

1. Do not add user-facing functions without documentation and examples.
2. Do not change public syntax, data schemas, or model parameterization without
   updating the relevant design document.
3. Do not add statistical estimators, likelihoods, simulations, training
   routines, or data transformations without targeted tests.
4. Keep pull requests small and focused.
5. Every meaningful change should update `docs/dev-log/check-log.md`.
6. Every completed task or phase should create an after-task or after-phase
   report following `docs/design/10-after-task-protocol.md`.
7. If code or examples are ported from another package, paper, repository, or
   agent branch, document provenance before treating the change as complete.
8. No agent should revert another agent's or human's work without explicit
   instruction.

## Standard Commands

Replace this block with commands that are real for the project.

```r
devtools::document()
devtools::test()
devtools::check()
pkgdown::check_pkgdown()
```

Optional project-specific commands:

```sh
Rscript tools/run-long-simulations.R
Rscript tools/check-data-fixtures.R
quarto render
```

## Recovery Checkpoints

For long runs, stream failures, or handoffs, create a compact recovery
checkpoint before continuing. If the project has no helper script yet, write a
short Markdown note under `docs/dev-log/recovery-checkpoints/` with:

- current branch and `git status --short`;
- changed files and diff stat;
- commands already run;
- commands that should be rerun;
- next safest action.

After a crash, repository state is authoritative. Always rerun:

```sh
git status --short --branch
git diff --stat
git diff
```

## Definition Of Done

A feature is done only when implementation, tests, documentation, examples,
check logs, after-task notes, and review are all present. If one of those is
not appropriate, the after-task report must say why.

## Writing Style

Write for a named reader. For technical prose, name the purpose before the
mechanics. Use concrete functions, files, equations, schemas, checks, or
numerical results instead of vague claims.

For model or algorithm documentation, pair:

- symbolic notation or algorithm statement;
- R syntax or user-facing code;
- interpretation in the project's domain.

Support factual, statistical, computational, or literature claims with a
citation, local evidence, check output, or an explicit design-assumption label.
Tell users what to try next when a feature, model, or syntax is unsupported.

Use the project-local `prose-style-review` skill for substantial README,
vignette, pkgdown, after-task, release, paper, or tutorial text.

## Multi-Agent Collaboration

One agent should act as integrator for each task. Use read-only sidecar
perspectives for design review, mathematical review, documentation review, and
validation planning. Use write-capable workers only when their file ownership
is narrow and does not overlap with other active work.

When handing work to another agent, leave enough context in
`docs/dev-log/check-log.md`, an after-task report, an issue, or a pull request
for the next agent to continue without rediscovering the whole problem.

Claude Code should read this file first. It should not introduce a parallel
agent configuration system unless the project owner asks for one.

## Standing Review Roles

These names are shorthand for recurring review perspectives. They do not run
continuously. Use the canonical names when reporting team perspectives.

| Name | Role | Primary questions |
| --- | --- | --- |
| Ada | Orchestrator and integrator | What should happen next, and are code, math, docs, tests, site, and git consistent? |
| Boole | API and interface reviewer | Is the syntax, schema, or public API memorable, parseable, and internally consistent? |
| Gauss | Numerical and implementation reviewer | Is the model, optimizer, simulation, or numerical routine correct and stable? |
| Noether | Mathematical consistency reviewer | Do notation, equations, algorithms, and implementation match exactly? |
| Darwin | Domain audience reviewer | Does the example answer a real question for the target audience? |
| Fisher | Inference and evaluation reviewer | Do simulations, metrics, uncertainty, comparator checks, and diagnostics support the claim? |
| Pat | Applied user tester | Can a new applied user follow the tutorial, interpret output, recover from errors, and avoid hidden jargon? |
| Jason | Landscape and source-map scout | What do related packages, papers, and repositories already do, and what should this project learn or avoid? |
| Curie | Testing specialist | Do tests cover ordinary, edge, and malformed-input cases without becoming too slow? |
| Emmy | R package architecture reviewer | Are S3/S4/R6 methods, object structures, internal APIs, and module boundaries coherent? |
| Grace | CI, site, release, and reproducibility engineer | Will this pass on all platforms, deploy cleanly, and avoid dependency or reproducibility risk? |
| Rose | Systems auditor | What discrepancies, repeated mistakes, stale wording, unsupported claims, and missing feedback loops are accumulating? |

## Team Improvement Loop

When a task exposes a better way for the team to work, record it in
`docs/dev-log/team-improvements.md` or the closest equivalent. Low-risk
documentation and skill improvements can be implemented immediately. Product,
architecture, or validation-policy changes need a normal task, evidence, and
review.

## Website And Documentation Policy

If this project has a pkgdown, Quarto, or other documentation site, treat it as
a first-class artifact. User-facing features should include reference
documentation and, when substantial, an article, vignette, or tutorial. Keep
navigation synchronized with exported functions and supported workflows.

## External Orchestration

External orchestration tools are optional. They must not become package
dependencies or hidden requirements unless the project owner explicitly decides
that they belong in the project.
