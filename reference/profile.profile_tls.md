# Profile-likelihood curves for a fitted thermal-load-sensitivity model

[`profile()`](https://rdrr.io/r/stats/profile.html) computes the
profile-likelihood deviance curve for one scalar target of a
[`fit_tls()`](https://itchyshin.github.io/freqTLS/reference/fit_tls.md)
model. For the target it fixes the corresponding internal
(unconstrained) coordinate on a grid, re-optimises the remaining
coordinates at each grid point, and returns the deviance
`D = 2 * (logLik_hat - logLik_profile)` together with the profile-t
cutoff and the profile-likelihood confidence interval. Because the
profile is taken on the unconstrained coordinate and the endpoints are
then transformed by a monotone function, the interval is exactly
equivariant: the `z` interval equals
[`exp()`](https://rdrr.io/r/base/Log.html) of the internal `log_z`
interval (the headline equivariance check).

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
[`vignette("profile-likelihood")`](https://itchyshin.github.io/freqTLS/articles/profile-likelihood.md).

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

Under the disjoint-bounds parameterisation
`up = up_min + up_w * plogis(beta_up)` has its own coordinate `beta_up`,
but freqTLS does not yet profile it (the profile path is wired for `low`
but not `up` — symmetric work, simply not implemented). freqTLS falls
back to the delta-method Wald interval for `up` and says so. Group
contrasts (`dCTmax`, `dlog_z`) are profiled directly by recoding the
design so the contrast is itself a coordinate.

## Examples

``` r
d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
               family = "binomial", tref = 60)
pc <- profile(fit, "CTmax")
pc$conf.low
#> [1] 28.23147
pc$conf.high
#> [1] 29.4012
```
