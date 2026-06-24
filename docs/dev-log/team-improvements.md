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
