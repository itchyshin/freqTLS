---
name: prose-style-review
description: Review and improve project prose in README files, vignettes, pkgdown or Quarto pages, after-task reports, release notes, design docs, and manuscript-style text.
---

# Prose Style Review

Use this skill for substantial prose, especially public documentation and
after-task reports.

## Reader First

Before editing, name the reader:

- applied user;
- adjacent-field graduate student;
- method or algorithm developer;
- R package contributor;
- reviewer of a paper, grant, release, or model output.

Write for that reader's current knowledge. Explain terms the reader would
otherwise have to infer from context.

## Review Checklist

1. Lead with purpose before mechanics.
2. For model or algorithm docs, pair symbolic notation, R syntax, and
   interpretation.
3. Replace vague nouns with concrete functions, parameters, files, equations,
   checks, schemas, metrics, or numerical results.
4. Use active voice when the actor matters.
5. Delete filler phrases such as "it is important to note that", "in order to",
   "various factors", and "significant improvements".
6. Keep project terms stable.
7. Support factual, statistical, computational, or literature claims with
   citations, local evidence, check outputs, or a clear design-assumption label.
8. Tell users what to do next when a feature, model, syntax, or data shape is
   unsupported.
9. End paragraphs with the point the reader should carry forward.
10. Avoid repeated sentence openings and repeated summary closers.

## Role Guidance

- Pat checks whether an applied user can follow the prose, run the example, and
  interpret the output.
- Darwin checks whether examples answer real domain questions.
- Rose checks stale wording, unsupported claims, duplicated summaries, and
  contradictions with code, docs, tests, roadmap, or after-task notes.

## Output

For a review-only task, return:

- blocking confusion;
- important friction;
- small polish;
- suggested wording for the highest-impact fixes.

For an edit task, make the smallest prose edits that fix the problem, then
record what changed in the check log or after-task report when the task is
meaningful.
