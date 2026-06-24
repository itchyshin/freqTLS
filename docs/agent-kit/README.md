# Portable Agent Operating Kit

This kit packages the collaboration habits that freqTLS inherited from
`drmTMB` and adapted for a focused, single-model R package. It is deliberately
project-neutral in the templates: a statistical modelling package, a
machine-learning package, an agent-based simulation package, or a data-wrangling
package can all start from the same skeleton.

The core idea is simple. Put the durable operating rules in the repository, not
in one agent's private context. Then ask each agent to read the same rules, use
the same named review perspectives, leave the same check-log evidence, and close
each meaningful task with an after-task note.

In freqTLS the live, adapted instances of this kit are `AGENTS.md`,
`CLAUDE.md`, `.claude/agents/`, `.codex/agents/`, `.agents/skills/`, and the
`docs/dev-log/` and `docs/design/` trees. This directory keeps the neutral
templates and the explanatory references so the kit can be re-used elsewhere.

## What To Copy

Copy the contents of `docs/agent-kit/templates/` into the target repository.
Then adapt the placeholders in these files:

- `AGENTS.md`: project scope, design rules, standard commands, definition of
  done, standing review roles, and collaboration rules.
- `CLAUDE.md`: short Claude Code entry point that points back to `AGENTS.md`.
- `docs/design/00-vision.md`: the project vision and scope boundary.
- `docs/design/10-after-task-protocol.md`: the after-task and after-phase report
  contract.
- `docs/dev-log/check-log.md`: append-only validation and handoff log.
- `docs/dev-log/decisions.md`: durable architectural decision log.
- `.agents/skills/*/SKILL.md`: local skills for prose review, after-task audit,
  simulation planning, model implementation review, and release readiness.

The kit also includes explanatory documents that should usually stay in the
source project as references:

- `bootstrap-checklist.md`: first-hour setup sequence for a new repository.
- `team-roles.md`: how Ada, Boole, Gauss, Noether, Darwin, Fisher, Pat, Jason,
  Curie, Emmy, Grace, and Rose should be used without turning them into theatre.
- `project-memory-policy.md`: how to keep project memory durable and honest.

## Minimum Viable Setup

For a small project, copy only:

1. `AGENTS.md`
2. `docs/design/00-vision.md`
3. `docs/design/10-after-task-protocol.md`
4. `docs/dev-log/check-log.md`
5. `.agents/skills/after-task-audit/SKILL.md`
6. `.agents/skills/prose-style-review/SKILL.md`

For a modelling, machine-learning, or simulation project, also copy the
simulation, model-review, and release-readiness skills.

## Adaptation Rule

Do not copy freqTLS or drmTMB statistical claims into another project. Copy
the operating pattern, then rewrite the scope, parameter names, validation
rules, and examples for the target package.

Good portable claims:

- every implemented feature needs tests, docs, examples, and a check-log note;
- code, equations, examples, and roadmap language must agree;
- hidden memory is useful for routing, but repository files are authoritative;
- one named integrator should own each task;
- a task is not done until uncertainty and next actions are explicit.

Bad copied claims:

- `CTmax` and `z` are the canonical parameter names (that is freqTLS-specific);
- TMB likelihoods are always involved;
- thermal-biology examples are always the right examples;
- `pkgdown` is the only possible website layer.

## Suggested First Prompt

After copying the kit into another repository, start a new agent conversation
with:

```text
Please read AGENTS.md, docs/design/00-vision.md,
docs/design/10-after-task-protocol.md, docs/dev-log/check-log.md, and the local
.agents skills. Rehydrate from git status before editing. Use Ada, Boole,
Gauss, Noether, Darwin, Fisher, Pat, Jason, Curie, Emmy, Grace, and Rose as
named review perspectives, but keep the work evidence-bound and project-specific.
```
