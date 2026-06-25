# Profile-likelihood curves for a fitted thermal-load-sensitivity model

[`profile()`](https://rdrr.io/r/stats/profile.html) computes the
profile-likelihood deviance curve for one scalar target of a
[`fit_tls()`](https://itchyshin.github.io/freqTLS/reference/fit_tls.md)
model. For the target it fixes the corresponding internal
(unconstrained) coordinate on a grid, re-optimises the remaining
coordinates at each grid point, and returns the deviance
`D = 2 * (logLik_hat - logLik_profile)` together with the chi-square
cutoff and the profile-likelihood confidence interval. Because the
profile is taken on the unconstrained coordinate and the endpoints are
then transformed by a monotone function, the interval is exactly
equivariant: the `z` interval equals
[`exp()`](https://rdrr.io/r/base/Log.html) of the internal `log_z`
interval (the headline equivariance check, SPEC.md S10).

## Usage

``` r
# S3 method for class 'profile_tls'
profile(fitted, parm, level = 0.95, npoints = 30L, trace = FALSE, ...)

# S3 method for class 'profile_tls_profile'
print(x, digits = 4, ...)
```

## Arguments

- fitted:

  A `profile_tls` fit from
  [`fit_tls()`](https://itchyshin.github.io/freqTLS/reference/fit_tls.md).

- parm:

  A single target name (see Targets).

- level:

  Confidence level for the interval and the cutoff line (default
  `0.95`).

- npoints:

  Number of grid points for the deviance curve (default `30`).

- trace:

  Logical; print inner-optimisation progress.

- ...:

  Reserved; must be empty.

- x:

  A `"profile_tls_profile"` object.

- digits:

  Number of significant digits for the printed summary (default `4`).

## Value

An object of class `"profile_tls_profile"`: a list with `parm`,
`profile_value` (grid on the natural scale), `deviance`, `estimate`,
`conf.low`, `conf.high`, `conf.status`, `cutoff`, `level`, `scale`, and
`transformation`.

## Details

The algorithm is a map-refit profile: the target coordinate is fixed
with TMB's `map` mechanism and the rest re-optimised, mirroring the
bracket-then- [`stats::uniroot()`](https://rdrr.io/r/stats/uniroot.html)
endpoint solver in `drmTMB::R/profile.R:2314-2373`. See
`docs/design/04-profile-likelihood.md`.

## Functions

- `print(profile_tls_profile)`: Print a compact summary of the profile.

## Targets

|  |  |  |
|----|----|----|
| **Target** | **Profiled coordinate** | **Endpoint transform** |
| `CTmax`, `CTmax:<grp>` | `beta_CT[g]` | identity |
| `z`, `z:<grp>` | `beta_logz[g]` | `exp` |
| `log_z`, `log_z:<grp>` | `beta_logz[g]` | identity |
| `low` | `beta_low` | `plogis` |
| `k` | `beta_logk` | `exp` |
| `phi` | `log_phi` | `exp` |
| `up` | (Wald/delta fallback) | – |
| `dCTmax:<a>-<b>`, `dlog_z:<a>-<b>` | contrast recoding | identity |

`up` has no single internal coordinate under the nested-gap asymptote
reparameterisation (`up = low + (1 - low) * plogis(beta_up)`); profiling
it would require rebuilding the compiled objective on a re-rooted
`(up, low)` pair. freqTLS instead falls back to the delta-method Wald
interval for `up` and says so (SPEC.md S10). Group contrasts (`dCTmax`,
`dlog_z`) are profiled directly by recoding the design so the contrast
is itself a coordinate.

## Examples

``` r
d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
               family = "binomial", tref = 1)
pc <- profile(fit, "CTmax")
pc$conf.low
#> [1] 35.7173
pc$conf.high
#> [1] 36.13577
```
