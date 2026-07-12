# Team Improvements

Record process and collaboration improvements here when a task exposes a better
way for the team to work. Low-risk documentation, process, and local-skill
improvements can be implemented immediately; product, architecture, or
validation-policy changes need a normal task, evidence, and review.

## 2026-06-16 -- Phase 0 bootstrap

- Generated the `.codex/agents/*.toml` mirrors programmatically from the
  `.claude/agents/*.md` files so the two runtimes cannot drift in their
  instruction bodies. When an agent changes, regenerate the mirror rather than
  hand-editing both, and keep the opus -> high / sonnet -> medium reasoning-effort
  mapping.
- Added two freqTLS-specific skills the drmTMB kit lacked: `profile-ci-review`
  (profile equivariance, chi-square calibration, open/boundary/multimodal
  handling) and `benchmark-vs-bayesTLS-audit` (fair config, cache provenance,
  R-SHRIMP). New model classes should get their own targeted review skills rather
  than overloading the generic ones.

## 2026-07-11 -- Ultra-plan routing and compute specification

- Every future ultra-plan must name the model tier and reasoning effort for each
  slice, the named agent/role, dependencies, expected wall time, and the
  independent verifier. Use Luna for bounded scouting/mechanical work, Terra as
  the default implementation tier, and Sol for high-cost release/statistical
  verification unless live evidence supports a different economical route.
- Every simulation-bearing plan must specify the estimand, data-generating
  process, parameter grid, repetitions, seeds, stopping rule, acceptance
  thresholds, software environment, worker/thread limits, host, scheduler/job
  shape, wall time, memory, and output provenance before launch. State
  explicitly when no simulation is justified. Use Totoro for rehearsals and
  DRAC for claim-bearing scale when appropriate; never mix host denominators
  without a declared design.

## 2026-07-11 -- Benchmark audits must distinguish relative midpoint from absolute LT50

The project-local `benchmark-vs-bayesTLS-audit` skill incorrectly required all
three estimators to use the relative threshold, even though the classical
two-stage estimator returns absolute LT50 by construction. That stale rule
propagated into multiple vignettes. The audit now requires the two model fits to
share the relative, constant-shape configuration and requires the classical
column to be labelled as an approximate absolute-LT50 comparator, used only when
lethal asymptotes near zero and one make the thresholds close. The cache gate now
also requires a verified source commit and URL rather than accepting an unknown
SHA.
