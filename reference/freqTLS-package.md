# freqTLS: Profile-Likelihood Inference for Thermal Load Sensitivity Models

`freqTLS` is a maximum-likelihood / profile-likelihood complement to the
Bayesian `bayesTLS` package. It fits single-stage four-parameter
logistic (4PL) thermal-load-sensitivity (thermal death-time) models via
Template Model Builder (`TMB`), parameterised directly in `CTmax` and
`z` (thermal sensitivity), so that both headline quantities can be
profiled. It returns prior-free, asymmetry-respecting profile-likelihood
confidence intervals for binomial and beta-binomial survival-count data.

## Credit and origins

The thermal-load-sensitivity modelling framework and the direct mapping
from the 4PL midpoint slope to `z` and `CTmax` are due to Noble, Arnold
and Pottier (the `bayesTLS` package). `freqTLS` contributes the TMB
maximum-likelihood likelihood, the direct `CTmax`/`log_z`
reparameterisation, and the profile-likelihood machinery. Engineering
patterns are adapted from `drmTMB` (GPL-3) with attribution in the
relevant source files.

## See also

Useful links:

- <https://github.com/itchyshin/freqTLS>

- <https://itchyshin.github.io/freqTLS>

- Report bugs at <https://github.com/itchyshin/freqTLS/issues>

## Author

**Maintainer**: Shinichi Nakagawa <itchyshin@gmail.com>

Authors:

- Shinichi Nakagawa <itchyshin@gmail.com>

- Daniel W. A. Noble (author of the bayesTLS thermal-load-sensitivity
  framework)

- Pieter A. Arnold (co-author of the bayesTLS framework)

- Patrice Pottier (co-author of the bayesTLS framework)
