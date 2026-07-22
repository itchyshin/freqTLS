# Testing Strategy

freqTLS uses testthat edition 3. Tests are fast and CRAN-safe, with the
data-generating truth carried as an attribute on simulated data. Long studies
live in `data-raw/` or optional scripts, not in routine checks. The
`add-simulation-test` and `simulation-test-plan` skills (Curie) govern the test
design; `profile-ci-review` (Fisher) governs the profile tests.

## simulate_tls

```
simulate_tls(temps, times, reps, n, low, up, k, CTmax, z, phi = NULL,
             family, group = NULL, tref = 60, seed)
```

It builds a factorial temperature x duration grid and draws counts from the
locked data-generating process: `rbinom` for the binomial family, and for the
beta-binomial, `rbeta(a = p * phi, b = (1 - p) * phi)` then `rbinom`. Grouped
data uses per-group `CTmax`/`z` with shared shape. The return is a base
`data.frame` with the true parameters attached as `attr(, "truth")`. The `phi`
convention (R-PHI) is documented: `phi` is the sum of the Beta shapes.

## Optimiser and start contract (v0.2)

Formula starts distinguish two parameterisations. For an intercept-containing
design, the biological baseline initialises only `(Intercept)` and slopes or
contrasts start at zero. For a no-intercept cell-means design, every cell
coefficient receives the biological baseline. This prevents an interacted
formula such as `~ 1 + species * age` from adding the baseline once per term.

`nlminb()` remains the primary optimiser, with BFGS as its error/non-convergence
fallback. When the nominal solution has `max(abs(gradient)) >= 1e-3`, the engine
may attempt deterministic preconditioned truncated-Newton refinement through
`nloptr`. It accepts the refinement only when the objective is no worse and the
maximum raw gradient is smaller. Tests judge the accepted point by that shared
objective/gradient contract, not by an NLopt status code alone.

## Test inventory (v0.1 plus v0.2 parity guards)

| Test | Asserts (tolerances) |
| --- | --- |
| `test-parameter-transforms` | `p` in (0,1); link round-trips to 1e-8; `low < up`; `mid = log10(tref)` when `temp = CTmax`; `dmid/dT = -1/z` |
| `test-fit-binomial` | recover `CTmax` to ~0.4 deg C, `z` to ~0.6, `low`/`up` to ~0.05, `k` to ~30% relative; converged |
| `test-fit-beta-binomial` | recover (wider); `logLik(bb) > logLik(binom)` and `AIC(bb) < AIC(binom)` on overdispersed data; near-binomial on clean data |
| `test-profile` | `|D(MLE)| < 1e-4`; finite closed CI; **`ci_z == exp(ci_log_z)` to 1e-6**; asymmetry allowed; sparse design gives `expect_warning("did not close")` + `NA`, no crash |
| `test-predict` | survival decreases with duration and with temperature; `newdata` works; predictions in (0,1) |
| `test-group` | recover `dCTmax` ~0.6, `dz` ~0.8; `CTmax:grp` and `z:grp` finite profiles |
| `test-benchmark-sanity` | cached bayesTLS vs live freqTLS within a loose tolerance (`CTmax` ~1 deg C, `z` ~25%); no Stan |
| `test-formula` | intercept starts leave slopes at zero; no-intercept designs initialise every cell mean |
| `test-canonical-case-specifications` | exact canonical hashes, filters, endpoints, formulas, `t_ref`, thresholds, no forbidden `Tcrit`, converged all-age aphid cells, and both Drosophila direct models |
| `test-shared-api-compatibility` | inference-independent utility equality and explicitly non-identical uncertainty-object contracts |

## CRAN-safe discipline

Use small datasets and fixed seeds. Use moderate tolerances calibrated against
the data-generating truth, not arbitrary round numbers. The benchmark sanity test
reads the cached summaries (no Stan in the test run); the live three-way refit is
a maintainer script.

## Tests of the tests

For each new test, confirm at least one of: the test failed before the fix; the
test compares the likelihood or profile to an independent calculation; the test
checks a boundary, malformed input, sparse design, or non-closing profile; or the
test combines a new feature with a supported neighbour (e.g. grouped
beta-binomial). Inspect failure messages before relaxing any expectation.
