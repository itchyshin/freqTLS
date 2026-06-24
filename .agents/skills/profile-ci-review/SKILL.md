---
name: profile-ci-review
description: Review freqTLS profile-likelihood confidence intervals for correctness, equivariance, chi-square calibration, and honest open/boundary/multimodal handling.
---

# Profile-Likelihood CI Review

Use this skill for any change to `R/profile.R`, `R/confint.R`, or
`R/diagnostics.R`, and before any claim about a freqTLS interval. Fisher
leads; Noether checks the transform algebra; Curie checks the tests.

## The Algorithm Contract

For a scalar target psi: fit the MLE `(theta_hat, logLik_hat)`; fix psi's
unconstrained coordinate; re-optimise the other coordinates; form the deviance
`D = 2 * (logLik_hat - logLik_p)`; the interval is `{psi : D <= qchisq(level, 1)}`,
found by `uniroot` on each side; transform endpoints to the natural scale.

| Target | Profile on | Transform |
| --- | --- | --- |
| `z`, `z:grp` | `eta_logz[g]` | `exp` |
| `CTmax`, `CTmax:grp` | `beta_CT[g]` | identity |
| `low` | `beta_low` | `plogis` |
| `k` | `beta_logk` | `exp` |
| `phi` | `log_phi` | `exp` |
| `up` | re-root on the native `(up, low-fraction)` | identity (else Wald/delta) |
| contrasts `dCTmax`, `dlog_z` | reference + contrast recoding | identity (ratio `z = exp(dlog_z)`) |

## Review Checklist

1. Is `|D(MLE)|` near zero (about 1e-4) at the fitted optimum?
2. Is profile equivariance enforced? The z-profile must equal `exp()` of the
   log_z-profile, so a test asserts `ci_z == exp(ci_log_z)` to about 1e-6. This
   is the headline equivariance check.
3. Is the chi-square cutoff `qchisq(level, 1)` (one degree of freedom per scalar
   target), and is the confidence level wired through correctly?
4. Is asymmetry allowed and preserved (do not symmetrise the interval)?
5. Open / non-closing profile: does the side that does not cross the cutoff
   return `NA` with a warning ("profile did not close; weakly identified --
   consider bayesTLS or bootstrap") and a `conf.status` marker, rather than
   crashing or fabricating an endpoint (R-PROFILE)?
6. Boundary MLE: when the MLE is on a boundary, is the chi-square calibration
   flagged as unreliable (warning), not silently trusted?
7. Multimodal / non-monotone profile: is a non-monotone deviance trace detected
   and reported, not collapsed to a single interval?
8. Inner non-convergence: does an inner re-optimisation failure propagate as
   `NA` with a warning, not a misleading finite endpoint?

## Tests Of The Tests

- A clean interior fit yields a finite closed interval with `ci_z ==
  exp(ci_log_z)`.
- A deliberately sparse design triggers `expect_warning("did not close")` and an
  `NA` endpoint with no crash.
- The deviance at the MLE is essentially zero.

Record the exact `uniroot` tolerances and the chi-square level in the after-task
report; do not relax a tolerance without inspecting the failure first.
