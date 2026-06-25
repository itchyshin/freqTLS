# Family Registry

freqTLS models **count** survival data (binomial, beta-binomial) and, since
v0.2, **continuous proportion** responses in `(0, 1)` (the beta family). The
count response is the number of survivors `y` out of `n` trials; the beta
response is a single proportion `y` with no trials. All families share the same
4PL mean curve as a function of exposure temperature and duration. Adding a
family requires the `add-simulation-test` discipline plus updates to this file
and `docs/design/03-likelihoods.md` (AGENTS.md design rule 1).

## Supported families

| Family | Constructor | `family_code` | Response | Extra parameter | Link of extra |
| --- | --- | --- | --- | --- | --- |
| Binomial | `binomial_tls()` | 0 | counts `y` of `n` | none | -- |
| Beta-binomial | `beta_binomial_tls()` | 1 | counts `y` of `n` | `phi` (dispersion) | log |
| Beta | `beta_tls()` | 2 | proportion `y` in (0, 1) | `phi` (dispersion) | log |

All families share the survival mean model (the 4PL curve with the direct
`CTmax`/`z` midpoint and disjoint-bounds asymptotes). The beta-binomial and beta
families add a single dispersion parameter `phi`; the beta family models a
continuous proportion directly with `y ~ Beta(p * phi, (1 - p) * phi)` and needs
no `n` (a dummy `n` is supplied internally and ignored by the likelihood).

`resolve_tls_family()` maps the string shortcuts `"binomial"`,
`"beta_binomial"`, and `"beta"` to the constructors; the default in `fit_tls()`
is `"beta_binomial"` (the more conservative choice for replicated count data,
which reduces to the binomial as `phi` grows).

## The phi convention (R-PHI)

`phi` is the **sum of the Beta shape parameters**. For fitted survival
probability `p`, counts are beta-binomial with shapes `a = p * phi` and
`b = (1 - p) * phi`. Larger `phi` means **less** overdispersion; the binomial is
recovered as `phi` grows. This single convention is used by `simulate_tls()`, the
TMB likelihood, and all documentation. It differs from the precision or size
parameterisations used by some other packages, so it is stated explicitly
wherever `phi` appears. The beta family reuses the identical shapes for its
continuous proportion, so `phi` carries the same meaning across both dispersed
families.

## Temperature / group effect on the shapes

By default the temperature effect runs through the midpoint only; `low`, `up`,
and `k` are shared. This is the bayesTLS constant-shape configuration, keeps the
model identifiable on typical thermal death-time data, and is the benchmark
setting. Since v0.2, each of `low`, `up`, and `log_k` may carry its **own** design
independently — a grouping factor (`low ~ group`), a general continuous covariate
(`log_k ~ body_size`), or an intercept — no longer required to share one factor or
match the `CTmax` / `log_z` grouping; `predict()` rebuilds each shape design from
`newdata`, and the intercept-only default is byte-identical. Since v0.3, `low` and
`log_k` may additionally carry a random intercept (`low ~ <fixed> + (1 | group)`).
See the 2026-06-17 entries in `docs/dev-log/decisions.md` and
`docs/design/46-capability-matrix.md`.

## Planned / non-goal families

- Time-to-event responses: non-goal for v0.1.
- Multi-trait responses: non-goal for v0.1.

When a `predict(type = "response")`, `fitted()`, or variance rule is added for a
new family, document the family-link contract here and in
`docs/design/03-likelihoods.md`.
