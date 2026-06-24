# freqTLS 0.1.0 (development)

* freqTLS is the frequentist counterpart to the Bayesian **bayesTLS** package: it
  fits the four-parameter logistic thermal-load-sensitivity (thermal death-time)
  model by maximum likelihood via TMB, parameterised directly in CTmax and
  thermal sensitivity (z), and reports uncertainty through a trio of frequentist
  intervals — Wald (delta), profile-likelihood, and bootstrap.
* Forked from the **profileTLS** package (commit `6f963a9`, v0.3.3), which it
  supersedes. Ongoing 0.1.0 development adds a bayesTLS-mirrored direct formula
  API (`ctmax`/`z`/`up`/`low`/`k` formulas, `threshold`, `bounds`), fit-time
  relative/absolute threshold selection, Bates–Watts profile-t interval
  calibration, and new case-study datasets (Li et al. 2023; Saruhashi et al.
  2026) — recorded here as they land.
