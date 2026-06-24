---
name: simulation-test-plan
description: Design compact simulation, replay, or calibration tests for statistical models, machine-learning workflows, agent-based models, and stochastic data pipelines.
---

# Simulation Test Plan

Use this skill when evidence depends on simulation, stochastic training,
synthetic data, or deterministic replay.

## Procedure

1. State the estimand, target metric, or invariant.
2. Simulate or construct data from known settings.
3. Fit, train, run, or transform with the intended public workflow.
4. Check estimates, predictions, metrics, or invariants on the scale users
   interpret.
5. Add at least one scientifically or operationally likely edge case.
6. Keep routine tests deterministic and small.

## Project-Type Examples

Statistical modelling:

- recover known parameters under ordinary sample sizes;
- check boundary cases and weak-identification regions;
- compare to an independent calculation or trusted package when possible.

Machine learning:

- check train/predict shape contracts;
- test leakage guards;
- use fixed seeds and small fixtures for routine tests;
- keep long benchmarks outside routine checks.

Agent-based modelling:

- test deterministic replay under fixed seeds;
- check conservation rules and schedule order;
- test malformed scenario files.

Data wrangling:

- test type stability, row-order stability, grouping rules, and missing-data
  behaviour;
- include small messy fixtures.
