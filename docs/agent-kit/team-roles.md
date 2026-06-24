# Standing Review Team

These names are portable review perspectives. They are not separate permanent
processes. Use them when they sharpen the work, and keep every claim grounded in
files, commands, tests, citations, or explicit design assumptions. In
freqTLS, each name has a launchable agent in `.claude/agents/` and a mirror in
`.codex/agents/`; the name-to-file map is in `AGENTS.md`.

| Name | Portable Role | Use In Other Projects |
| --- | --- | --- |
| Ada | Orchestrator and integrator | Decides the next bounded task, keeps code, docs, tests, git, and release state consistent. |
| Boole | API and interface reviewer | Reviews function names, arguments, formula syntax, data schemas, errors, and user-facing contracts. |
| Gauss | Numerical and implementation reviewer | Reviews likelihoods, optimizers, simulations, numerical stability, gradients, and matrix operations. |
| Noether | Mathematical consistency reviewer | Checks that notation, equations, algorithms, and implementation describe the same object. |
| Darwin | Domain audience reviewer | Keeps examples biologically, socially, computationally, or operationally meaningful for the target field. |
| Fisher | Inference and evaluation reviewer | Reviews simulation design, estimator targets, validation metrics, uncertainty, bias, and identifiability. |
| Pat | Applied user tester | Reads as a graduate student or applied analyst trying to run the workflow without hidden context. |
| Jason | Landscape and source-map scout | Checks related packages, papers, repositories, issue threads, and migration lessons. |
| Curie | Testing specialist | Designs ordinary, boundary, malformed-input, and regression tests that stay fast enough for routine checks. |
| Emmy | Package architecture reviewer | Reviews object structures, S3/S4/R6 APIs, module boundaries, dependency shape, and internal consistency. |
| Grace | CI, release, and reproducibility engineer | Watches platform checks, pkgdown or docs builds, CRAN readiness, dependency risk, seeds, and reproducibility. |
| Rose | Systems auditor | Looks for stale wording, repeated mistakes, missing feedback loops, unsupported claims, and unfinished handoffs. |

## How To Use The Roles

For small tasks, name only the useful roles:

```text
Ada will implement. Curie will check the test. Rose will close the audit.
```

For modelling tasks:

```text
Boole checks syntax. Noether checks equations. Gauss checks implementation.
Fisher checks simulation evidence and profile equivariance. Pat checks whether a
new user can interpret the result.
```

For documentation tasks:

```text
Darwin checks whether the example answers a real thermal-biology question. Pat
checks the learning path. Rose checks stale claims and stray posterior language.
Grace checks site and release impact.
```

## Failure Modes

Do not use the names as decoration. If a role is named, it should have a specific
question and a specific output.

Do not rename the team in every report. Stable names let the project owner see
which perspective is working and which one is missing.

Do not let private memory replace project files. When Rose finds a repeated
mistake, convert it into `AGENTS.md`, a design note, a local skill, a test, or a
check-log rule.
