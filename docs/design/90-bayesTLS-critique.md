# Balanced Critical Assessment of bayesTLS

This is the durable record of the balanced critique of `bayesTLS` that drives the
freqTLS design. It reproduces SPEC section 5. The directive was: "Dan's team
checked a lot -- critical but balanced, don't just accept everything." Citations
are `bayesTLS` `file:line` at HEAD (2026-06-16).

## Strengths

- Asymptote ordering is provably enforced (`utils.R:119-141`).
- The shared-draw z / CTmax / T_crit construction preserves the joint
  correlation (`extract_tdt.R:593-612`).
- `z` is read directly from the `mid` slope `-1 / b_mid_temp_c`
  (`extract_tdt.R:89-90`).
- Honest relative-vs-absolute handling with `NA` propagation
  (`extract_tdt.R:75-77`).
- `T_crit` is guarded behind `lethal = TRUE`.
- Real sampler diagnostics are reported (`diagnostics.R:38-110`).
- The two-stage path has a `< 3`-unique gating check (`two_stage.R`).

## Concerns (classified, cited)

### REAL -- verified data bug: shrimp shipped counts corrupted

The CSV `Mortality_after_trial` is a **proportion** (`0.0909 = 1/11`,
`0.5 = 5/10`); `make_datasets.R:25` mislabels it a "death count" and `:34`
applies `as.integer(...)`, flooring proportions below 1 to 0. The shipped
`shrimp_lethal` deaths collapse to nearly all-zero. **Action:** rebuild from the
CSV with `deaths = round(prop * N)`; document; file a friendly upstream report;
verify the `.rda` before finalising. (Risk R-SHRIMP.)

### REAL -- no identifiability / data-adequacy guard on the Bayesian path

There is no guard in `fit_4pl.R`, `standardize_data.R`, or `priors.R`; guards
live only in the classical `two_stage.R`. With weak data the priors silently
identify the parameters. This is **freqTLS's clearest value-add**: the 12
explicit warnings (`docs/design/04-profile-likelihood.md`).

### REAL on sparse data -- default priors are weakly but genuinely informative

The `mid` slope prior is `normal(0, 0.6)`; the asymptote and `phi` priors are at
`priors.R:55-82`. There is no sensitivity tooling. freqTLS's prior-free CIs
are an implicit sensitivity check; expect divergence on sparse data (this is not
a "bug").

### RESOLVED -- disjoint asymptote bounds force low < midpoint < up

`utils.R:128-131` forces `low < 0.5 < up` (the midpoint split). freqTLS originally
treated this as a feasibility wall and used a nested-gap reparameterisation; P1
reversed that and **adopted** the same disjoint bounds (`compute_4pl_bounds()`), so
the asymptote contract is now shared with bayesTLS
(`docs/design/01-model-and-parameterisation.md`).

### MINOR

- The all-four `temp_effects` headline relative-z ignores shape temperature
  effects (correct but under-signposted; irrelevant to v0.1 constant shape).
- The finite-difference local-z step `h = 1e-3` is undocumented but fine.
- `CTmax` extrapolation is unflagged.
- The `T_crit` rate range `c(0.1, 1)` is taxon-general but prose-flagged.

## Net assessment

bayesTLS is competently built. Only three things change the freqTLS design:
the shrimp data fix, the identifiability gap (our differentiator), and the
asymptote reparameterisation choice. None threaten benchmark validity given the
matched constant-shape / relative configuration.
