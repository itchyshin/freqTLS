---
name: model-implementation-review
description: Review statistical, machine-learning, simulation, or data-transformation implementations before merging.
---

# Model Implementation Review

Use this skill for changes to likelihoods, optimizers, training loops,
prediction paths, simulation engines, or nontrivial data transformations.

## Review Checklist

- Is the public contract documented before the internal mechanics?
- Are constrained parameters represented on stable internal scales?
- Are matrix dimensions, grouping levels, feature columns, and prediction-time
  shapes checked?
- Are constants, offsets, weights, missing values, and factor levels handled
  consistently?
- Are random seeds, stochastic schedules, and resampling splits reproducible?
- Do tests cover ordinary cases, boundary cases, and malformed inputs?
- Does the user-facing output report quantities on interpretable scales?
- Does the roadmap avoid describing planned behaviour as implemented?

For statistical models, also check:

- likelihood constants and link functions;
- gradients or optimizer diagnostics when available;
- simulation recovery;
- comparison to independent calculations when possible.

For machine-learning models, also check:

- leakage guards;
- calibration or uncertainty claims;
- train-time versus predict-time preprocessing parity;
- serialization and reload behaviour.
