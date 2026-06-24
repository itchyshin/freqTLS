# After Task: Phase 1 -- TMB engine, fit_tls, and simulate

## Date

2026-06-16

## Task

Implement and verify the load-bearing TMB engine and the maximum-likelihood
fitting surface for profileTLS: the 4PL thermal-load-sensitivity likelihood
(binomial + beta-binomial) with the direct `CTmax`/`log_z` midpoint
reparameterisation and nested-gap asymptotes (`src/profile_tls.cpp`,
`profile_tls_numeric.h`, `init.c`), the family registry, design matrices,
transforms, the fit engine (`MakeADFun` -> `nlminb` -> `optim(BFGS)` fallback ->
`sdreport`), the public tidy-eval `fit_tls()`, the locked-DGP `simulate_tls()`,
and `test-parameter-transforms`. Owner: Gauss + Noether (+ Emmy). SPEC.md S9,
S11.

This task also carried an explicit **audit obligation**: the Phase-0 scaffold
agent (Ada) wrote unverified engine drafts (`src/profile_tls.cpp`,
`profile_tls_numeric.h`, `init.c`, `R/families.R`, `R/model_matrix.R`,
`R/utils.R`, `R/profileTLS-package.R`) and described them as pre-existing.
Phase 1 had to review every one critically against SPEC S9, assume bugs until
proven otherwise, and fix or rewrite as needed -- not rubber-stamp them.

## Audit of Ada's Phase-0 drafts (honest findings)

The drafts were **never compiled or tested** before this phase. Critical review
against SPEC S9 and the cited drmTMB lines found them better than feared but not
flawless:

- **`src/profile_tls.cpp` -- correct, but unverified.** Reviewed line by line
  against SPEC S9: the data/parameter declarations, nested-gap `up`, the direct
  midpoint `mid = log10_tref - (temp - CT)/z`, `eta = k*(log_time - mid)`,
  `p = low + (up - low)*invlogit(-eta)`, the nested `CppAD::CondExp` clamp to
  `[1e-12, 1-1e-12]`, both NLLs, and the REPORT/ADREPORT block all match the
  spec. The Boolean.h pre-include guard matches `drmTMB::src/drmTMB.cpp:1-14`;
  the beta-binomial lgamma density matches `drmTMB::src/drmTMB.cpp:1319-1328`;
  the shape floor matches `drmTMB::src/drmTMB.cpp:1302-1314`. No code bug found.
  The real gap was process, not content: it had **never been put through a
  compiler**. Resolved by compiling it (clean, return value `0`, only harmless
  Eigen `-Wunused-but-set-variable` warnings) and then driving it end to end via
  `load_all` and `fit_tls`. **Verdict: kept unchanged; now verified.**
- **`src/profile_tls_numeric.h` -- one dead helper.** `profile_tls_inv_logit`
  is used; `profile_tls_log1p_exp` is **never called** by the `.cpp`. It is
  harmless and the header is spec-compliant (the spec only requires that stable
  `inv_logit`/`log1p_exp` helpers exist with a `.h` guard). Left in place rather
  than deleted, since it is a pre-existing helper the spec sanctions, not an
  orphan my own changes created.
- **`src/init.c` -- correct.** Matches `drmTMB::src/init.c` with the
  `R_init_profileTLS` registration and the Boolean.h guard. Verified by the DLL
  loading under `load_all`.
- **`R/families.R`, `R/model_matrix.R`, `R/utils.R` -- correct.** Family codes
  (binomial 0, beta_binomial 1), links, `~ 0 + group` design with level-named
  columns and an "all" ungrouped level, `%||%`, the link/back-transform helpers,
  and the name map all match the spec. No bug found; verified through `fit_tls`.
- **`R/profileTLS-package.R` -- one real bug (missing imports).** The package
  doc imported `stats`, `cli`, `TMB`, and `utils` but **omitted the `rlang`
  functions** (`enquo`, `eval_tidy`, `quo_is_null`) that the tidy-eval
  `fit_tls()` needs. This would have produced an `R CMD check` NOTE/ERROR and a
  runtime failure. **Fixed** by adding `@importFrom rlang enquo eval_tidy
  quo_is_null`.

Two further drift items, attributable to Phase-0 process rather than to the
engine logic, were corrected so the gate could run:

- The hand-written `NAMESPACE` was not roxygen-generated, so `devtools::document`
  refused to overwrite it. Deleted it and let roxygen regenerate from the tags.
- The package-doc `@importFrom stats ...` was wrapped across two lines, which
  **roxygen2 8.0.0 rejects** ("@importFrom must be only 1 line long"). Collapsed
  to a single line. Also changed two unresolvable cross-reference links: the
  `[TMB][TMB::TMB-package]` link in the package doc and the `[fit_tls_engine()]`
  links in `@noRd` internal-helper docs (no `.Rd` topic is generated for `@noRd`
  helpers, so those links can never resolve) -- both demoted to backticks.

## Implemented

- **Verified (unchanged):** `src/profile_tls.cpp`, `src/profile_tls_numeric.h`,
  `src/init.c`, `R/families.R`, `R/model_matrix.R`, `R/utils.R`.
- **Fixed:** `R/profileTLS-package.R` (added the rlang imports; single-line
  importFrom; removed unresolvable links). Regenerated `NAMESPACE` (now
  roxygen-managed) and `man/`.
- **Written:** `R/fit_engine.R` (`fit_tls_engine()` -- `MakeADFun` -> `nlminb`
  -> `optim(BFGS)` fallback -> `sdreport` in `tryCatch`, with a convergence list
  carrying `code`/`pdHess`/`optimizer`/`message`; mirrors
  `drmTMB::R/drmTMB.R:350-440`), `R/fit_tls.R` (the public tidy-eval
  `fit_tls()`, the default starts, the natural-scale `estimates` table, the
  internal vcov, and a minimal `logLik.profile_tls` S3 method so the engine
  output is immediately usable), `R/simulate.R` (`simulate_tls()` with the
  locked DGP and the documented `phi` convention), `tests/testthat.R`, and
  `tests/testthat/test-parameter-transforms.R`.

## Mathematical Contract

The implemented forward map (identical in the C++ engine and the simulator):

```
z_i  = exp(X_logz_i . beta_logz)
CT_i = X_CT_i . beta_CT
mid_i = log10(tref) - (T_i - CT_i) / z_i
eta_i = k * (log10(duration_i) - mid_i)
p_i  = low + (up - low) * invlogit(-eta_i),   clamped to [1e-12, 1 - 1e-12]
low  = invlogit(beta_low)
up   = low + (1 - low) * invlogit(beta_gap)    (nested gap, up > low guaranteed)
k    = exp(beta_logk),   z = exp(beta_logz),   phi = exp(log_phi)
```

Binomial NLL: `-dbinom(y, n, p, log=TRUE)`. Beta-binomial NLL: the `lgamma` form
with `a = p*phi`, `b = (1-p)*phi`, `phi` the sum of Beta shapes (larger `phi` =
less overdispersion; binomial limit as `phi -> Inf`). This matches SPEC S9 and
`docs/design/03-likelihoods.md`; no contradiction with the design docs was
found.

## Checks Performed (exact commands + counts)

1. Standalone compile (fail-fast on the load-bearing piece):
   `R -q -e 'TMB::compile("src/profile_tls.cpp")'` -> returned `[1] 0` (clean;
   only Eigen `-Wunused-but-set-variable` warnings). Artifacts removed
   afterwards.
2. `R -q -e 'devtools::document(".")'` -> regenerated `NAMESPACE` and `man/`
   with no errors (after the import/link fixes above).
3. `R -q -e 'devtools::load_all("."); cat("LOADED OK\n")'` -> compiled `src/`
   and printed `LOADED OK`.
4. `R -q -e 'devtools::test(".")'` -> `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 17 ]`
   for `test-parameter-transforms` (Duration ~1.0 s).
5. End-to-end recovery (SPEC verification gate), pasted real output:
   - binomial (truth CTmax=36, z=4): `logLik = -129.0538`, `conv = 0`,
     `pdHess = TRUE`, `CTmax = 35.93` (SE 0.11), `z = 3.998` (SE 0.19),
     `low = 0.0199`, `up = 0.977`, `k = 4.89`; all fitted `p in (0,1)`
     (range 0.0199-0.9772).
   - beta-binomial (truth CTmax=36, z=4, phi=50): `logLik = -137.71`,
     `conv = 0`, `pdHess = TRUE`, `CTmax = 35.90` (SE 0.12), `z = 4.057`
     (SE 0.21), `phi = 40.8` (SE 22.3; the truth 50 is within one SE -- `phi` is
     weakly identified at a single seed, as expected); all `p in (0,1)`.
6. Map and grouped smoke tests:
   - binomial `df = 5` with `log_phi` absent from the optimised par vector
     (`map = list(log_phi = factor(NA))` works).
   - grouped binomial (truth CTmax=c(34,38), z=c(3,5)): `conv = 0`,
     `pdHess = TRUE`, `df = 7`, recovered CTmax:A=34.01, CTmax:B=37.87,
     z:A=2.88, z:B=5.02.
   - default family resolves to `beta_binomial`.

## Outcomes

The Phase 1 gate is met: the engine compiles and loads, `test-parameter-transforms`
is green, and both families fit with finite log-likelihoods, convergence code 0,
a positive-definite Hessian, recovered `CTmax ~ 36` and `z ~ 4`, and all fitted
probabilities strictly in `(0, 1)`. Grouped fits and the binomial `log_phi` map
also work. The `fit_tls()` signature and the `profile_tls` S3 field list (the
Phase 2 contract) are recorded in the check-log entry of the same date.

## Consistency Review

- The forward map in `R/simulate.R` is byte-for-byte the same algebra as
  `src/profile_tls.cpp` (descending in `log10(duration)` via `invlogit(-eta)`),
  so the simulator cannot drift from the engine.
- `docs/design/01-model-and-parameterisation.md` and
  `docs/design/03-likelihoods.md` agree with SPEC S9 and with the implemented
  code; no contradiction was found, so no design-doc edit was required this
  phase.
- `rg "posterior|credible"` over the new `R/` files: no hits -- the engine layer
  uses no posterior language (the compatibility-interval language gate is
  honoured even though intervals themselves arrive in Phase 3).
- The `phi` convention (R-PHI) is documented identically in `R/families.R`,
  `R/simulate.R`, and `docs/design/03-likelihoods.md`.

## Tests Of The Tests

`test-parameter-transforms` checks the algebra, not a tautology of the code: it
verifies link round-trips to `1e-8`, that the nested-gap transform yields
`0 < low < up < 1` over 500 random draws, that the forward map keeps `p` inside
`(low, up)` and `(0, 1)` across a temperature-by-duration grid, that
`mid = log10(tref)` exactly when `temp == CTmax`, that `d mid / d temp = -1/z`
both analytically and by central difference to `1e-6`, and that survival is
strictly decreasing in both duration and temperature. The recovery checks
(separate from the unit tests) confirm the *fitted* engine inverts the simulator,
which is the real end-to-end guarantee.

## What Did Not Go Smoothly

- The SPEC verification gate calls `logLik(f1)`, but the `logLik` S3 method is
  nominally a Phase-2 (`methods.R`) deliverable. Rather than fake the gate, a
  minimal `logLik.profile_tls` method was added to `R/fit_tls.R` so the stored
  log-likelihood is usable with `AIC`/`BIC` immediately. Phase 2 should fold this
  into the full method set (`print`/`summary`/`coef`/`vcov`/`nobs`) and may move
  it into `methods.R`.
- roxygen2 8.0.0 is stricter than older versions: multi-line `@importFrom` and
  unresolvable `@noRd` cross-links are now hard errors, not warnings. Fixed.
- The repository has only the initial commit; Phase 0's files (including Ada's
  engine drafts) are uncommitted in the working tree. Nothing was committed this
  phase (no commit was requested).

## Team Learning

- "Pre-existing" is not "verified." Ada's drafts were largely correct but had
  never touched a compiler and carried a real missing-import bug. The cheap
  fail-fast move -- compile the `.cpp` in isolation before writing any R -- paid
  off and should be the default whenever an unverified TMB draft is inherited.
- When inheriting a hand-written `NAMESPACE`, delete it before the first
  `document()` so roxygen owns it; otherwise the import fixes silently do not
  take effect.

## Known Limitations

- `up` still has no single internal coordinate (nested-gap), so its profile will
  need native re-rooting in Phase 3 (already flagged in
  `docs/design/04-profile-likelihood.md`).
- Only `logLik` is implemented among the S3 methods; `print`/`summary`/`coef`/
  `vcov`/`nobs`/`confint`/`profile`/`predict`/`plot` are Phase 2+.
- `phi` is weakly identified on small single-seed designs (expected; the SE is
  honest about it). No identifiability warnings are emitted yet -- those are the
  Phase 3 (`diagnostics.R`) twelve-warning deliverable.
- No real-data fits, no profile intervals, no plotting in this phase.

## Next Best Task

Phase 2 (Emmy + Boole + Curie): `R/methods.R`
(`print`/`summary`/`coef`/`vcov`/`nobs`/`AIC`, folding in the existing `logLik`),
`R/extract.R` (`tidy_parameters`/`get_ctmax`/`get_z`/`get_shape`), and
`test-fit-binomial` + `test-fit-beta-binomial` (the recovery-tolerance and
`AIC(bb) < AIC(binom)`-when-overdispersed tests). The `fit_tls()` signature and
the `profile_tls` field list in the same-date check-log entry are the contract.
