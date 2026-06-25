# Simulation sanity check — freqTLS (ML/TMB) vs bayesTLS (posterior)

**Date:** 2026-06-25 · **Branch:** `build/freqtls` · **Reader:** freqTLS maintainers.

## What was run

A frequentist twin of the bayesTLS two-stage-bias simulation
(`scripts/simulations/`): the DGP, the classical two-stage estimator, and the
scoring are copied verbatim from bayesTLS (engine-agnostic), so both packages run
the **same 29 scenarios**; the one change is `fit_joint_4pl()`, which fits by
maximum likelihood (freqTLS) instead of Stan. Two campaigns, both N_SIMS = 1000:

| Campaign | Where | Config | Output |
|---|---|---|---|
| Relative-threshold | local (18-core fork) | `NBOOT=0` (profile CI, `fallback=FALSE`) | `output/sim_freq/summary_sanity.rds` |
| + Absolute + T_crit | **DRAC fir**, 29-task SLURM array | `NBOOT=500` (parametric bootstrap) | `/project/def-snakagaw/snakagaw/freqTLS-sim/freqTLS/output/sim_freq/summary_scen*.rds` |

Compared against the bayesTLS results pulled from OSF (node `c6dxy`,
`../bayesTLS/output/sim_twostage/summary_*.rds`). The two summaries share columns,
so the merge is direct (`scripts/simulations/compare_to_bayes.R`).

## Findings

1. **DRAC reproduces local exactly.** Mean |coverage difference| for the relative
   `joint_4pl` (CTmax, 29 scenarios) = **0.0015** (Monte-Carlo noise) — the cluster
   pipeline is correct and reproducible.
2. **The twin recovers the truth ≈ as well as the posterior.** On interior designs
   (constant-shape model ≈ correct), freqTLS bias ≈ 0 and **coverage ≈ 0.94–0.96
   (nominal)** — often *closer* to 0.95 than bayesTLS, which over-covers (~0.98) —
   with **narrower intervals on these interior-design simulations** (where Bayes
   over-covers). The profile-t calibration delivers nominal coverage without a
   width penalty here. (On the real benchmark datasets — shrimp, zebrafish — the
   freqTLS and bayesTLS widths come out *comparable*; see
   `vignette("comparing-to-bayesTLS")`. "Narrower" is the controlled-simulation
   efficiency result, not a universal claim.)
3. **Threshold choice matters on misspecified shapes.** Mean coverage over all 29
   scenarios: relative `joint_4pl` freqTLS **0.850** vs bayes 0.941; absolute
   `joint_4pl_abs` freqTLS **0.921** vs bayes 0.948. The relative figure is pulled
   down by the deliberately shape-misspecified scenarios (scen6 u-drift, scen7 low
   upper asymptote), where the relative midpoint ≠ the OLS truth; the absolute path
   (which targets the truth) recovers coverage. Not a freqTLS bug — a known
   relative-threshold effect; bayes tolerates it with wider intervals.
4. **Sparse design (scen8_sparse): a real trade-off.** freqTLS is nearly *unbiased*
   (CTmax bias 0.006) but its bootstrap CI under-covers (**0.83**); bayes *covers*
   (0.92) but is badly *biased* (−0.24, the prior pulling). freqTLS's point estimate
   is better; its sparse-design interval is the weak spot. **Follow-up:** try BCa or
   a larger `nboot` for the absolute/T_crit bootstrap on sparse designs.
5. **Boundary asymptotes (scen1, u = 0.999) are degenerate for ML.** Only ~25 % of
   sims yield a positive-definite Hessian; the rest are honestly excluded (the
   `success = code==0 && pdHess` rule), not averaged in. This is the regime where
   Bayes's priors hold up and ML does not — documented, expected.

## Reusing the DRAC setup

The environment persists at `/project/def-snakagaw/snakagaw/freqTLS-sim/`
(`Rlib/` = the built R library incl. freqTLS; `freqTLS/` = synced source). To
re-run after a code change: rsync the source, then on a login node
`sbatch [--array=1-29] [--export=ALL,NBOOT=500] scripts/simulations/drac_sim.sh`.
The R env only needs rebuilding (`install_deps.sh`) if R/package versions change.
No ghost processes: installs exit on the login node; sims run under SLURM.
