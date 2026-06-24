# Bootstrap Checklist For A New Project

Use this checklist when installing the agent operating kit in another R,
statistical, machine-learning, agent-based modelling, or data-wrangling
repository. freqTLS itself was bootstrapped from this kit (the drmTMB
original), so this file is both a record and a template.

## First Hour

1. Copy `docs/agent-kit/templates/` into the target repository.
2. Replace every `<PROJECT>` placeholder.
3. Rewrite `AGENTS.md` so the first section states the target project's true
   scope and non-goals.
4. Replace the standard commands with the target project's real validation
   commands.
5. Fill `docs/design/00-vision.md` with the project's audience, core workflow,
   supported data types, and current implementation status.
6. Keep `docs/design/10-after-task-protocol.md` unless the project already has a
   stronger equivalent.
7. Keep `docs/dev-log/check-log.md` append-only.
8. Add a first check-log entry that records the installation date, current
   branch, and commands that have not yet been run.
9. Ask one agent to act as Ada for the first task and one agent to act as Rose
   for the first closing audit.
10. Commit the setup before starting large feature work.

## What To Customize By Project Type

For statistical modelling packages:

- define canonical parameter names and link scales (freqTLS: `CTmax`, `z`,
  `log_z`, `low`, `up`, `k`, `phi`);
- require equations, syntax, and implementation to match;
- require simulation recovery tests for new likelihoods or estimators;
- record comparison targets such as `bayesTLS`, `glmmTMB`, or a classical
  estimator when relevant.

For machine-learning packages:

- define the train, validate, test, predict, and serialize contracts;
- require leakage checks and prediction-time shape checks;
- separate fast unit tests from long benchmark or calibration studies;
- record seeds, hardware assumptions, and dataset versions.

For agent-based modelling packages:

- define agent state, environment state, schedule order, and stochastic events;
- require deterministic replay tests under fixed seeds;
- test conservation rules, boundary cases, and malformed scenario files;
- record which conclusions are model behaviour, not empirical facts.

For data-wrangling packages:

- define input schemas, output schemas, grouping rules, and missing-data rules;
- test type stability and row-order stability;
- include representative messy fixtures;
- record whether errors are strict, warning-based, or repair-based.

## First Three Tasks

The first three tasks should be deliberately small:

1. A documentation-only task that proves the check-log and after-task process.
2. A narrow code task with one test and one user-facing example.
3. A review task where Rose searches for stale claims across README, docs,
   vignettes, issues, and roadmap files.

After those tasks, the project owner should revise `AGENTS.md` to remove rules
that felt ceremonial and strengthen rules that prevented real mistakes.
