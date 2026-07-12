# Random effects: random intercepts on CTmax, log_z, and the shapes (v0.2–v0.3)

## Scope

freqTLS supports a single **random intercept** on `CTmax` (v0.2), `log_z`
(v0.3, "item 5"), and the shape coordinates `low` and `log_k` (v0.3), written
`<param> ~ <fixed> + (1 | group)` in the formula interface. The `CTmax` intercept
matches the `bayesTLS` random-effects-on-the-midpoint configuration (between-group
variation in thermal tolerance — colony, clutch, population); the `log_z` intercept
models between-group variation in thermal **sensitivity** (the steepness); the
`low` / `log_k` intercepts model between-group variation in the background-survival
asymptote and the curve steepness. Each spends one variance hyperparameter instead
of a fixed coefficient per group.

Any subset may be used together, on the same grouping factor or on different ones.
When two or more share a grouping factor they are fit as **independent** variances
and a warning is emitted (see "Independent variances").

Deliberately **out of scope**, each rejected with a clear error:

- a random effect on the upper asymptote `up` — the compiled objective has no
  random-intercept term for `up` (under disjoint bounds
  `up = up_min + up_w * plogis(beta_up)` has its own fixed coordinate, but there is
  no `b_up` / `sd_up`); put the RE on `low` / `log_k`;
- random slopes (`(temp | group)` and the like);
- more than one grouping factor on a single sub-parameter / crossed or nested
  random effects;
- a **correlated** (multivariate) random effect across coordinates — only
  independent intercepts are fit (use `bayesTLS` for a correlated random structure).

## Model

For observation `i` in group `g(i)`, the midpoint gains a group deviation on the
`CTmax` coordinate:

```
CTmax_i = X_CT[i,] %*% beta_CT + b_{g(i)},   b_g ~ N(0, sigma_CTmax^2)
mid_i   = log10(tref) - (temp_i - CTmax_i) / z_i
```

with the rest of the 4PL unchanged. The `b_g` are integrated out by the Laplace
approximation (TMB `random = "b_CT"`); `sigma_CTmax` is a fixed hyperparameter
estimated by marginal maximum likelihood, and `beta_CT`, `beta_logz`, and the
shape parameters are the usual fixed effects.

The **`log_z` random intercept** (item 5) adds a group deviation on the `log_z`
coordinate, on the **log scale**, before the `exp()` that produces `z`:

```
logz_i = X_logz[i,] %*% beta_logz + c_{g(i)},   c_g ~ N(0, sigma_logz^2)
z_i    = exp(logz_i)
```

This is the structural twin of the `CTmax` intercept: the deviation is additive on
the sub-parameter's own internal coordinate (identity for `CTmax`, `log` for `z`)
before it enters the 4PL. The `c_g` are integrated out by the Laplace
approximation (TMB `random = "b_logz"`).

**`sigma_logz` is a standard deviation on `log(z)`, not on `z`.** It is therefore
*not* in z-units and is not comparable in kind to `sigma_CTmax` (a SD on `CTmax`
in °C). The honest reading is multiplicative: a one-SD group sits at
`z × exp(±sigma_logz)`, so `exp(sigma_logz)` is the approximate fold-spread of `z`
across groups (e.g. `sigma_logz = 0.2` ⇒ roughly a ×1.22 / −18% spread), and for
small `sigma_logz` it approximates the between-group coefficient of variation of
`z`. `print()`/`summary()` therefore label `sigma_logz` as a log-scale SD.

When both intercepts are present the deviations are independent draws,
`b_g ~ N(0, sigma_CTmax^2)` and `c_g ~ N(0, sigma_logz^2)`, with no covariance
term (see "Independent variances").

The **shape random intercepts** (v0.3) add a group deviation on a shape
coordinate's own internal (link) scale before its inverse link:

```
low_i = inv_logit(X_low[i,] %*% beta_low + d_{g(i)}),   d_g ~ N(0, sigma_low^2)
k_i   = exp(X_logk[i,] %*% beta_logk + e_{g(i)}),        e_g ~ N(0, sigma_logk^2)
```

so `sigma_low` is a SD on the internal logit coordinate `beta_low` of `low` and
`sigma_logk` a SD on `log(k)`. Under disjoint bounds
`up = up_min + up_w * plogis(beta_up)` is independent of `low`, so a random
intercept on `low` shifts `low` per group while `up` stays at its population
value; there is no separate `up` random effect.

## Engine (`src/profile_tls.cpp`)

Each block adds three engine objects, all appended at the **end** of the
declarations so the existing free-parameter ordering is untouched. CTmax:
`DATA_IVECTOR(re_index)`, `PARAMETER_VECTOR(b_CT)`, `PARAMETER(log_sd_CT)`. log_z:
`DATA_IVECTOR(re_index_logz)`, `PARAMETER_VECTOR(b_logz)`, `PARAMETER(log_sd_logz)`.
The shape coordinates (v0.3): `DATA_IVECTOR(re_index_low)`,
`PARAMETER_VECTOR(b_low)`, `PARAMETER(log_sd_low)` and the `log_k` analogues
`re_index_logk` / `b_logk` / `log_sd_logk`.

In the per-observation loop each coordinate's deviation is added on its own
internal scale, **only when the block is non-empty**: `CT_i` gains
`+ b_CT(re_index(i))`; `logz_i` gains `+ b_logz(re_index_logz(i))` before
`z_i = exp(logz_i)`; `low`'s logit gains `+ b_low(re_index_low(i))` before
`inv_logit` (and `up_i` is then recomputed from the shifted `low_i`, leaving the
`up_s` fast path only when there is no low RE); `log_k` gains
`+ b_logk(re_index_logk(i))` before `exp`. A `dnorm(b_*, 0, exp(log_sd_*))` prior
is added under the same guard, and `sigma_*` and the BLUPs are REPORT/ADREPORTed
only when their block is present.

### The byte-identical invariant (the gate)

The no-RE path must be **numerically identical** to the fixed-effects model, and
adding the `log_z` block must not perturb the no-RE or `CTmax`-only paths. This is
guaranteed structurally: when a block is absent its `b_*` vector is empty, so every
term is skipped (`b_*.size() == 0`), its `log_sd_*` is mapped out (`factor(NA)`),
and `random` names only the active block(s) (`NULL` when there are none). The new
declarations are appended at the end, so the free-parameter vector and its order,
the negative log-likelihood, the optimiser path, and every REPORT/ADREPORT are
unchanged for existing fits. The gate is the full test suite: all pre-existing
tests pass with their original expected values after the engine recompile
(verified: **498 pass / 0 fail / 0 warn / 0 skip**, `R CMD check` 0/0/0).

Every `MakeADFun` call site passes both blocks' data/parameters: `fit_tls()`,
`tls_contrast_refit()` (contrasts are fixed-group fits: `re_index*` zeros, empty
`b_CT`/`b_logz`, both `log_sd_*` mapped), and the profile / bootstrap refits (which
reuse the fit's retained `tmb_inputs`). The active-block bookkeeping (which `b_*`
maps to which sub-parameter / group / `sigma_*`) is centralised in
`tls_re_blocks()` (`R/utils.R`), the single source of truth for `ranef()`, the
`sigma_*` rows, the profile re-Laplace, and the bootstrap redraw.

## R surface

- **Formula parsing** (`R/formula.R`): `tls_extract_re(rhs, data, param)` (a
  param-agnostic generalisation of the former `tls_extract_ct_re()`) splits a
  `CTmax` *or* `log_z` right-hand side into its fixed part and a single
  `(1 | group)` term, validates the scope above, and returns an `re` spec
  `list(index, n, group_levels, group_var)`. It is called for both sub-parameters;
  non-RE formulas route through the same code with `re = NULL`, so they are
  unchanged. The bar is stripped before the shared-design comparison, so a `log_z`
  RE with the same fixed part as `CTmax` passes that check.
- **`fit_tls()`**: builds `re_index` / `b_CT` / `log_sd_CT` and
  `re_index_logz` / `b_logz` / `log_sd_logz`, and sets `random` to the active
  block names (`"b_CT"`, `"b_logz"`, both, or `NULL`). The fit stores `fit$re`
  (CTmax spec) and `fit$re_logz` (log_z spec); `tls_re_blocks()` derives the
  descriptor list consumed downstream. `sigma_CTmax` / `sigma_logz` are surfaced as
  rows in `fit$estimates` only for the corresponding RE fits.
- **`simulate_tls(re_sd, re_sd_z, n_re_groups, re_group_name)`**: draws
  group-level deviations on the requested coordinate(s) — `re_sd` on CTmax,
  `re_sd_z` on log(z), `re_sd_low` on logit(low), `re_sd_logk` on log(k) — and
  generates the grid per group with the shifted parameters (`up` tracking the
  shifted `low`). A coordinate that is not requested draws no RNG and stays exactly
  at its scalar value, so a call using a subset is bit-identical to the previous
  behaviour. Cannot be combined with a fixed `group`.
- **Prediction**: `predict(..., re.form = "population")` sets every random
  intercept to zero. `predict(..., re.form = "conditional")` adds each fitted
  BLUP on its internal coordinate and requires the corresponding grouping
  column in `newdata`; missing or unseen levels stop rather than silently using
  zero. Omitting `re.form` on a random-effects fit warns and returns the
  population prediction. The specialised surface, lethal-time, critical-
  temperature, and heat-injury helpers remain population-level for
  random-effects fits.

## Independent variances (honest limitation)

Random intercepts on the **same** grouping factor for **two or more** of `CTmax`,
`log_z`, `low`, `log_k` are fit as **independent** variances (all pairwise
correlations forced to zero). In thermal data the group-level deviations (e.g.
tolerance `CTmax` and sensitivity `z`) are usually correlated, and that omitted
covariance is then absorbed into the marginal SDs and the fixed-effect intervals,
biasing them in an unknown direction. The parser **warns** once per shared grouping
factor. A correlated (multivariate) random effect across coordinates is out of
scope; for a correlated random structure, use `bayesTLS`. A `log_z` RE and a beta-binomial `phi` can also trade off (both
absorb extra spread in the transition); if `sigma_logz` collapses toward zero or
`phi` runs to its binomial limit, prefer one source of dispersion or `bayesTLS`.

## Estimation note (honest)

`sigma_CTmax` and `sigma_logz` are **maximum-likelihood** variance-component
estimates, so they are biased **low** with few groups (REML would reduce this bias;
the Laplace ML path does not). For `sigma_CTmax`, simulation with 30 groups and
`re_sd = 1.5` gives a mean estimate ~1.28. `sigma_logz` is a SD on `log(z)`
(≈ the between-group coefficient of variation of `z`), so it is multiplicative, not
additive — read `exp(sigma_logz)` as the fold-spread. The fixed effects `CTmax`/`z`
recover essentially unbiased in both cases. Treat the variance components
cautiously with few groups; the parser warns below three levels.

## Phase 2

Landed:

- `ranef()` returns the `CTmax` BLUPs (conditional modes) with conditional SEs,
  from the sdreport random block.
- `sigma_CTmax` gets a log-scale Wald interval, `exp(log_sd_CT +/- z * se)`, so
  it stays positive.
- **Profile-likelihood `confint` under the RE.** `confint(method = "profile")`
  and `profile()` now profile the fixed-effect coordinates of an RE fit by
  re-running the Laplace approximation at each grid point (`random = "b_CT"`).
  Routing is selective: `sigma_CTmax` stays on its log-scale Wald interval (it has
  no profile coordinate yet), the non-closing fallback uses Wald (kept fast; the
  RE-aware bootstrap below is the prior-free alternative), and group contrasts
  under an RE error clearly.
  The Confidence Eye stays on Wald for an RE fit for speed. Each profile point is
  a nested Laplace fit, so it is slower than a fixed-effects profile and its
  recovery test is `skip_on_cran`.

- **RE-aware parametric bootstrap.** `confint(method = "bootstrap")` on an RE fit
  redraws the group deviations `b_g ~ N(0, sigma_hat)` through the compiled model
  and refits with the random block, giving a prior-free interval for
  `sigma_CTmax` (and the fixed effects). It is slow (a Laplace refit per
  replicate), so use a small `nboot`; the recovery test is `skip_on_cran`.

## Item 5 (v0.3): the log_z intercept

The `log_z` random intercept reuses every Phase-2 mechanism through
`tls_re_blocks()`: `ranef()` returns the `log_z` BLUPs (term `"log_z"`),
`sigma_logz` gets the same log-scale Wald interval, fixed-effect profiles re-run
the Laplace with all active blocks in `random`, and the RE-aware bootstrap redraws
every block's deviations. `sigma_logz` stays on Wald under `method = "profile"`
(no profile coordinate), as `sigma_CTmax` does.

## Tests

- `tests/testthat/test-random-effects.R` (CTmax): convergence + fixed-effect
  recovery; averaged `sigma_CTmax` recovery (ML, mildly low); the no-RE formula fit
  equals the column-interface fit; scope errors (intercept only, single grouping,
  `up` RE rejected while `low`/`log_k` are accepted); `simulate_tls` RE-mode
  validation.
- `tests/testthat/test-random-effects-logz.R` (log_z, item 5): convergence +
  fixed-effect recovery; averaged `sigma_logz` recovery; the no-RE fit is
  unchanged; `ranef()` `log_z` BLUPs and the `sigma_logz` Wald interval;
  `sigma_logz` stays Wald under `method = "profile"`; profile-under-RE and the
  RE-aware bootstrap (`skip_on_cran`); scope errors; the same-grouping-on-both
  warning; CTmax + log_z on different groupings; `simulate_tls(re_sd_z=)`
  validation.
- `tests/testthat/test-shape-random-effects.R` (low / log_k, v0.3): convergence +
  `sigma_low` / `sigma_logk` surfaced; the no-RE fit is unchanged; `ranef()` shape
  BLUPs; `up` RE and shape random slopes rejected; the generalised same-grouping
  warning (a shape RE and a CTmax RE on one factor); `simulate_tls(re_sd_low=,
  re_sd_logk=)` validation. The shape REs reuse the same `tls_re_blocks()` path as
  CTmax / log_z, so ranef / sigma rows / profile / bootstrap need no per-shape
  special-casing.
