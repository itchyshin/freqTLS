# Profile Likelihood

This document records the profile-likelihood algorithm, the per-target
transforms, and the 12 identifiability warnings. Any change to the algorithm,
targets, transforms, or warnings must update this file in the same commit
(AGENTS.md design rule 5). The implementation lives in `R/profile.R`,
`R/confint.R`, and `R/diagnostics.R`. The review checklist is the
`profile-ci-review` skill (Fisher).

## Algorithm (as implemented, Phase 3)

For a scalar target `psi`:

1. Fit the MLE, obtaining `(theta_hat, logLik_hat)`.
2. Fix the unconstrained internal coordinate that maps to `psi`; re-optimise the
   remaining coordinates to get the profile log-likelihood `logLik_p(psi)`.
3. Form the deviance `D(psi) = 2 * (logLik_hat - logLik_p(psi))`.
4. The confidence interval is `{psi : D(psi) <= qt(1 - alpha/2, df)^2}`, found by
   `uniroot` on each side of the MLE.
5. Transform the endpoints to the natural scale.

At the MLE, `|D| ~ 0` (checked to about `1e-4` in tests; the verification run
gives exactly `0`). The cutoff is the **squared Student-t quantile**
`qt(1 - alpha/2, df)^2` on `df = n - p` residual degrees of freedom (the
Bates–Watts profile-t calibration), not `qchisq(level, 1)`; the two coincide as
`df -> Inf`. The interval is asymmetric in general, and freqTLS preserves the
asymmetry rather than symmetrising it.

### Implementation choices (these differ from the draft above)

* **Map-refit, not `TMB::tmbprofile`.** Step 2 fixes the target coordinate with
  TMB's `map` mechanism (`factor(NA)` on that one slot of the corresponding
  `PARAMETER_VECTOR`) and re-optimises the rest with `nlminb` (BFGS fallback),
  warm-started at the fitted MLE. This is the single profile-NLL evaluator
  `D(theta)` reused for both the deviance curve (a grid) and the interval
  endpoints. It gives full control over the inner optimisation and a uniform path
  for the `up` and contrast special cases. The map-refit rebuilds the objective
  from the *clean* TMB inputs retained on the fit (`fit$tmb_inputs`), not from the
  mutated `obj$env` (whose mapped-out `log_phi` slot is length-0 and cannot be
  rebuilt directly).
* **Bracket-then-`uniroot` endpoints** (adapted from
  `drmTMB::R/profile.R:2314-2373`): step outward from the MLE along each
  direction (seeded from the curve grid when it already brackets, else
  geometrically with a curvature-scaled step) until `D` rises above the cutoff,
  then solve `D(theta) = cutoff` with `uniroot`. No bracket within the search
  means a non-closing side (warning 9) and the endpoint is returned `NA`.
* **`up` uses the delta-method Wald fallback.** Under disjoint bounds `up` already
  has its own coordinate `beta_up`, but the profile path is not yet wired for it
  (the work is symmetric with `low`); freqTLS takes the documented Wald/delta
  fallback meanwhile. `profile(fit, "up")` and
  `confint(fit, "up", method = "profile")` emit an informational message, return
  `interval_type = "wald"`, and carry `conf.status = "wald_fallback"`. The `up`
  row of `tidy_parameters(method = "profile")` is honestly labelled `"wald"`.
* **Contrasts are profiled by refitting on a treatment-coded design.** A
  `dCTmax:<a>-<b>` / `dlog_z:<a>-<b>` target rebuilds the objective with
  `model.matrix(~ relevel(group, a))`, so the alternate group's coefficient is
  exactly the contrast and can be profiled by the standard coordinate path. The
  recoded objective has the same likelihood and MLE as the `~ 0 + group` fit
  (verified: the recoded `dCTmax` estimate equals `CTmax_b - CTmax_a` from the
  original fit to ~1e-4), so this is the equivariant move that makes the contrast
  directly profile-able.

## Targets and transforms

| Target | Profile on | Endpoint transform |
| --- | --- | --- |
| `z`, `z:grp` | `eta_logz[g]` | `exp` |
| `CTmax`, `CTmax:grp` | `beta_CT[g]` | identity |
| `low` | `beta_low` | `plogis` |
| `k` | `beta_logk` | `exp` |
| `phi` | `log_phi` | `exp` |
| `up` | re-root on the native `(up, low-fraction)` pair | identity (else Wald/delta) |
| contrasts `dCTmax`, `dlog_z` | reference + contrast recoding | identity (ratio `z = exp(dlog_z)`) |

Because the profile is taken on the unconstrained coordinate and the endpoint is
then transformed by a monotone function, the interval is equivariant: the `z`
interval is `exp()` of the `log_z` interval. A test asserts `ci_z ==
exp(ci_log_z)` to about `1e-6`; this is the headline equivariance check.

`up` is the exception: under disjoint bounds it has its own coordinate `beta_up`,
but freqTLS does not yet profile it. The implemented Phase 3 takes the documented
Wald/delta fallback for `up` (see "Implementation choices" above); wiring a
`beta_up` profile is straightforward (it is symmetric with `low`) but not yet
done. The interval is therefore reported with `interval_type = "wald"` and a
message.

## The 12 identifiability warnings (the bayesTLS gap-filler)

These are emitted, never silent. They are freqTLS's clearest value-add over
the Bayesian path, which silently lets the priors identify weakly informed
parameters.

1. Fewer than 3 temperatures.
2. Fewer than 3 durations (overall, and per temperature).
3. No mortality anywhere.
4. All mortality anywhere.
5. The mortality threshold is never crossed.
6. An asymptote is never approached.
7. `CTmax` is extrapolated beyond the duration span.
8. `phi` is at the binomial limit (beta-binomial collapsing to binomial).
9. The profile does not close (an open CI): warn "weakly identified -- consider
   bayesTLS or bootstrap" and set a `conf.status` marker (R-PROFILE).
   `confint(fallback = TRUE)` (the default) replaces the open profile interval
   with a parametric-bootstrap interval; `fallback = FALSE` returns `NA` on the
   open side.
10. The MLE is on a boundary: warn that the interval calibration is unreliable.
11. The profile is non-monotone or multimodal.
12. Inner re-optimisation does not converge: propagate `NA` rather than a
    misleading finite endpoint.

## Ship stance

The profile gives fast, prior-free, asymmetry-respecting confidence intervals
when the MLE is interior and the data identify `psi`. For boundary asymptotes,
very sparse designs, overdispersion concentrated at zero, or weakly identified
random-effects fits, the profile may not close. freqTLS warns in that regime
and, by default, attempts the parametric-bootstrap fallback below. That fallback
can also be unstable and then returns `NA`; neither freqTLS nor bayesTLS is
described as guaranteeing a finite interval. Fixed-effect targets may be
profiled under the Laplace-integrated random-effects likelihood; variance
components use Wald intervals unless bootstrap is requested. freqTLS never
claims the profile is universally superior.

## Parametric bootstrap fallback

When a profile does not close, or the fitted Hessian is not positive definite
(`pdHess = FALSE`), `confint(method = "profile", fallback = TRUE)` (the default)
computes a prior-free **parametric bootstrap** percentile interval instead of
returning `NA`. The same machinery is available directly as
`confint(method = "bootstrap")`.

The procedure regenerates survival counts at the *observed* design from the
fitted 4PL (`p_fitted` from the compiled model, drawn binomial or beta-binomial
per the fit's family and `phi`), refits the model `nboot` times through the same
retained TMB inputs the profile uses (warm-started at the MLE), and takes the
percentile interval of the replicate estimates. Percentiles are taken on each
parameter's construction scale (`z`/`k`/`phi` on log, `low` on logit,
`CTmax`/`up` on identity) and back-transformed, so the bootstrap is exactly
equivariant in the same sense the profile is: the `z` interval equals `exp()` of
the `log_z` interval. It is a prior-free likelihood-path alternative to the
prior-informed bayesTLS posterior interval. No Stan and no model recompilation
are involved; only the response vector changes between replicates. A target
with too few converged replicates returns `NA` with `conf.status =
"bootstrap_unstable"` rather than a fabricated bound.

The refits are independent, so `cores > 1` runs them in parallel via process
forking (`parallel::mclapply`; sequential fallback on Windows). The response
vectors are pre-drawn sequentially under `boot_seed` and the refits consume no
RNG, so the interval is identical for a given seed regardless of `cores`.

## Display

Profile intervals are displayed as Confidence Eyes (see
`docs/design/07-collaboration-and-site.md` and the `figure-visual-audit` skill).
A non-closing profile renders a hollow point with no lens, never a fabricated
interval shape. A bootstrap fallback interval renders as its own
distinctly coloured lens ("bootstrap interval"), so it is never mistaken for a
profile interval. The interval source (profile, Wald, or bootstrap) and the
transformation scale are exposed in the caption. freqTLS prose and figures use
"confidence" language and never "posterior" / "credible".
