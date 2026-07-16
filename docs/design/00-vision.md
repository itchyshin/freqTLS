# freqTLS Vision

`freqTLS` is the fast, prior-free, profile-likelihood complement to
`bayesTLS`. It fits the single-stage four-parameter logistic (4PL)
thermal-load-sensitivity (thermal death-time) model by maximum likelihood via
Template Model Builder (TMB), parameterised **directly** in `CTmax` (the critical
thermal maximum at a reference exposure time) and `z` (the thermal sensitivity,
degrees Celsius per decade of exposure duration), so that both headline
quantities are direct, profile-able coordinates.

## Core idea

The 4PL thermal death-time curve relates survival to exposure temperature and
duration. The bayesTLS framework reads `z` and `CTmax` off the midpoint of that
curve after fitting. freqTLS instead makes `CTmax` and `z` the model
coordinates, via `mid = log10(tref) - (temp - CTmax) / z`. This is a smooth,
invertible reparameterisation of the bayesTLS constant-shape model, so it has the
same likelihood, the same fitted curve, and the same maximum-likelihood estimate.
What changes is that the headline scientific quantities are now coordinates,
which makes them directly profile-able, and profile likelihood is equivariant
under a monotone reparameterisation, so the `z` profile is `exp()` of the
`log_z` profile.

## Readers and users

The primary readers are:

- applied thermal-biology ecologists and evolutionary biologists who run thermal
  death-time assays and want defensible intervals for `CTmax` and `z`;
- statistical method developers interested in the likelihood-versus-Bayes
  contrast for this model class;
- R package contributors.

## Signature features

- Profile-likelihood confidence intervals for `CTmax` and `z`, displayed as
  Confidence Eyes rather than posterior densities. freqTLS produces likelihood
  confidence intervals; the prose and the figures never imply a posterior.
- An explicit identifiability story: 12 warnings (emitted, never silent) that
  tell the user when the data do not identify the target and point them to
  `bayesTLS` or a bootstrap. The Bayesian path lacks this guard, so it is
  freqTLS's clearest value-add.
- A fair, cached three-way benchmark against `bayesTLS` (Bayesian) and the
  classical two-stage estimator on shared, vendored datasets.

## Scope

The package supports:

- the single-stage 4PL thermal-load-sensitivity model with a direct
  `CTmax`/`log_z` midpoint and intercept-only shapes by default; the formula
  interface may give `low`, `up`, and `log_k` their own fixed designs;
- count response data (`binomial`, `beta_binomial` with overdispersion `phi`) and
  continuous proportions (`beta`);
- ungrouped fits, fixed-effect groups via `~ 0 + group`, per-sub-parameter fixed
  predictors and a formula DSL (`tls_bf()`), and single random intercepts on
  `CTmax` / `log_z` / `low` / `log_k`;
- Wald, profile-likelihood, and parametric-bootstrap confidence intervals, with the
  Bates–Watts profile-t small-sample calibration;
- derived heat-injury / `T_crit` quantities and the Confidence-Eye uncertainty plot.

The package does not currently support (non-goals):

- time-to-event or multi-trait responses;
- temperature effects on `low`, `up`, or `k` (the constant-shape invariant);
- a fit-time absolute-threshold option (the fit is on the relative threshold;
  absolute / p-survival quantities come from `extract_tdt()`) or non-default
  asymptote `bounds`;
- correlated, crossed, or random-slope random effects, or a random effect /
  profile coordinate for the upper asymptote `up`;
- CRAN submission until the release ledger, author consent, and external platform
  evidence are complete.

## Sibling boundary

- `bayesTLS` (Daniel W. A. Noble, Pieter A. Arnold, Patrice Pottier): the
  Bayesian path, the broad thermal-load-sensitivity workflow, heat-injury models,
  and posterior inference. freqTLS implements **their** framework by
  likelihood; they are co-authors.
- `drmTMB`: general univariate and bivariate distributional regression.
  freqTLS is purpose-built for one model class, not general regression.

## Core contracts

| Contract | Meaning | Where implemented | Validation |
| --- | --- | --- | --- |
| `fit_tls()` | tidy-eval fit of the 4PL model by ML | `R/fit_tls.R` | `test-fit-binomial`, `test-fit-beta-binomial` |
| `CTmax` | critical thermal maximum at `tref` | `src/profile_tls.cpp`, `R/extract.R` | `test-parameter-transforms` |
| `z` | thermal sensitivity (deg C per decade) | `src/profile_tls.cpp`, `R/extract.R` | `test-parameter-transforms`, `test-profile` |
| `confint(method = "profile")` | profile-likelihood confidence interval | `R/profile.R`, `R/confint.R` | `test-profile` (`ci_z == exp(ci_log_z)`) |
| Confidence Eye | default uncertainty visual (not a posterior) | `R/plotting.R` | Florence figure-audit gate |

## Evidence standard

An implemented claim needs a code path, test or simulation evidence,
documentation or an example, a check-log entry, and an after-task or after-phase
note for meaningful changes. A planned claim is labelled as planned in
user-facing prose, the roadmap, and the capability matrix.
