---
name: prose-style-review
description: Review and improve freqTLS prose in README files, vignettes, pkgdown articles, after-task reports, release notes, design docs, and manuscript-style text for clarity, concrete claims, stable terminology, citations, and reader fit.
---

# Prose Style Review

Use this skill for substantial prose, especially public documentation and
after-task reports.

## Reader First

Before editing, name the reader:

- applied thermal-biology ecology or evolution user;
- adjacent-field graduate student;
- statistical method developer;
- R package contributor;
- reviewer of a paper, grant, or release.

Write for that reader's current knowledge. Explain a term when the reader would
otherwise have to infer it from context.

## Review Checklist

1. Lead with purpose before mechanics.
2. For model docs, pair the symbolic equation (the 4PL and the direct
   `CTmax`/`z` map), the R syntax (`fit_tls(...)`), and the interpretation.
3. Replace vague nouns with concrete functions, parameters, files, equations,
   checks, or numerical results.
4. Use active voice when the actor matters.
5. Delete filler phrases such as "it is important to note that", "in order to",
   "various factors", and "significant improvements".
6. Do not over-bullet. Use bullets for genuine lists; use prose for one or two
   connected ideas.
7. Keep terms stable: `CTmax`, `z`, `log_z`, `low`, `up`, `k`, `phi`, `mid`,
   `tref`, and `relative` / `absolute` threshold. Define `CTmax` (critical
   thermal maximum at `tref`) and `z` (thermal sensitivity, degrees per decade)
   at first use.
8. Use "confidence" or "compatibility" interval language. **Never** call a
   freqTLS interval a "posterior" or "credible" interval; that is the
   `bayesTLS` path. The default uncertainty visual is the Confidence Eye.
9. Credit the `bayesTLS` framework (Noble, Arnold & Pottier) as the origin of
   the modelling idea wherever the model is introduced.
10. Support factual, statistical, or literature claims with citations, local
    evidence, check outputs, or a clear "design assumption" label.
11. For tutorials and error-message docs, tell the reader what to do next when a
    design is weakly identified (the profile may not close; consider bayesTLS or
    bootstrap).
12. End paragraphs with the point the reader should carry forward; avoid
    repeated sentence openings and summary closers.

## Role Guidance

- Pat checks whether an applied user can follow the prose, run the example, and
  interpret the output.
- Darwin checks whether examples answer real thermal-biology questions.
- Rose checks stale wording, unsupported claims, duplicated summaries, and
  contradictions with code, docs, tests, roadmap, or after-task notes, including
  any stray "posterior"/"credible" language.

## Output

For a review-only task, return blocking confusion, important friction, small
polish, and suggested wording for the highest-impact fixes. For an edit task,
make the smallest prose edits that fix the problem, then record what changed in
the check log or after-task report when the task is meaningful.
