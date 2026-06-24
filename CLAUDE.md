# Claude Code Instructions for freqTLS

This repository is shared by humans, Codex, and Claude Code. Read `AGENTS.md`
first; it is the source of truth for project rules. The canonical SPEC is
`SPEC.md`; read it before any implementation slice.

## Project Identity

`freqTLS` is the maximum-likelihood / profile-likelihood complement to the
Bayesian `bayesTLS` package. It fits the single-stage 4PL
thermal-load-sensitivity (thermal death-time) model by ML via TMB, parameterised
directly in `CTmax` and `z`, and returns prior-free, asymmetry-respecting
profile-likelihood confidence intervals for binomial and beta-binomial
survival counts.

Sibling boundaries:

- `bayesTLS` (Daniel W. A. Noble, Pieter A. Arnold, Patrice Pottier): the
  Bayesian path, the broad TLS workflow, heat-injury models, and posterior
  inference. freqTLS implements **their** modelling framework by likelihood.
- `drmTMB`: general univariate and bivariate distributional regression.
  freqTLS is purpose-built for one model class, not general regression.

## Invariants To Preserve

- Stable parameter names: `CTmax`, `z`, `log_z`, `low`, `up`, `k`, `phi`. Do not
  let these drift across code, docs, tests, and equations.
- The default mortality threshold is **relative**, not absolute. The benchmark
  locks all three estimators (classical two-stage, `bayesTLS`, freqTLS) to
  the relative threshold for a fair comparison.
- Use "confidence" interval language. Never describe a
  freqTLS interval as a "posterior" or "credible" interval. freqTLS
  intervals are likelihood confidence intervals.
- The default uncertainty visual is the **Confidence Eye**, not a posterior
  density. The visual contract in `docs/design/13` (and the SPEC) forbids
  implying a posterior; Florence owns the figure gate. A non-closing profile
  renders a hollow point and an open/annotated lens, never a fabricated closed
  eye.
- The temperature effect runs through the midpoint only (shared `low`, `up`,
  `k`), matching the `bayesTLS` constant-shape configuration.

## Before Finishing Work

- Run the narrow tests you touched, then the broader package checks when
  practical.
- Update design docs if the model parameterisation, likelihood, profile
  algorithm, families, diagnostics, or benchmark protocol changes.
- Add or update an after-task report in `docs/dev-log/after-task/`.
- Keep public capability in sync in one commit: `README.Rmd`, `ROADMAP.md`,
  `NEWS.md`, `docs/dev-log/known-limitations.md`,
  `docs/design/46-capability-matrix.md`, and the relevant design doc.
- For substantial prose, apply the project-local `prose-style-review` standard:
  name the reader, lead with purpose, use concrete claims, keep terms stable,
  cite factual or literature claims, and explain what users should try next when
  a design is weakly identified.
- Do not revert Codex or human changes unless explicitly asked.

Before editing after a handoff or crash, run:

```sh
git status --short --branch
git diff --stat
git diff
```

Then read the newest check-log and after-task reports.

## Launchable Team Agents

`.claude/agents/` mirrors `.codex/agents/` one-to-one, so Claude Code can launch
the same team Codex uses. The named perspectives map to files as: Ada =
`integration-reviewer`, Gauss = `tmb-engineer`, Noether =
`math-consistency-reviewer`, Fisher = `inference-reviewer`, Emmy =
`architecture-reviewer`, Boole = `formula-reviewer`, Curie =
`simulation-tester`, Florence = `figure-reviewer`, Darwin = `audience-reviewer`,
Pat = `user-tester`, Jason = `landscape-scout`, Grace =
`reproducibility-engineer`, and Rose = `systems-auditor`. The job-function agents
are `reviewer`, `documentation-writer`, `pkgdown-editor`, and
`literature-curator`. The instruction bodies are copied verbatim between the
Claude `.md` files and the Codex `.toml` files. When you add an agent or change
its instructions, update both directories so the two runtimes stay in sync.

## Reusing drmTMB / gllvmTMB Code

freqTLS adapts engineering patterns from `drmTMB` (GPL-3) for the TMB
likelihood, the optimizer plumbing, and the profile machinery, and from
`gllvmTMB` (GPL-3) for the Confidence-Eye geometry. Copying or closely adapting
code requires provenance notes in `inst/COPYRIGHTS` and tests around the ported
behaviour. Do not introduce a parallel agent configuration system unless the
project owner asks for one.
