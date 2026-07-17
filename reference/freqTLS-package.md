# freqTLS: Frequentist Inference for Thermal Load Sensitivity Models

`freqTLS` is a maximum-likelihood / profile-likelihood complement to the
Bayesian `bayesTLS` package. It fits single-stage four-parameter
logistic (4PL) thermal-load-sensitivity (thermal death-time) models via
Template Model Builder (`TMB`), parameterised directly in `CTmax` and
`z` (thermal sensitivity), so that both headline quantities can be
profiled. It returns prior-free Wald, profile-likelihood, or
parametric-bootstrap confidence intervals for binomial and beta-binomial
survival counts and the experimental Beta continuous-proportion family.
Formula shape effects, limited random intercepts, and deterministic
heat-injury prediction are also experimental; censored-time,
hurdle-productivity, posterior, and fitted repair models remain outside
freqTLS.

## Experimental software

**Use freqTLS at your own risk.** Results and APIs may be incorrect or
change. Users are responsible for checking their data, design, model
specification, convergence, identifiability, diagnostics, and
interpretation. Important analyses should be independently refitted and
cross-checked with the Bayesian sister package
[bayesTLS](https://daniel1noble.github.io/bayesTLS/) ([source
repository](https://github.com/daniel1noble/bayesTLS)). Agreement is a
cross-check, not proof of correctness; shared data or model errors can
make both packages agree.

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

- <https://itchyshin.github.io/freqTLS/>

- Report bugs at <https://github.com/itchyshin/freqTLS/issues>

## Author

**Maintainer**: Shinichi Nakagawa <itchyshin@gmail.com>
([ORCID](https://orcid.org/0000-0002-7765-5182)) \[copyright holder\]

Authors:

- Shinichi Nakagawa <itchyshin@gmail.com>
  ([ORCID](https://orcid.org/0000-0002-7765-5182)) \[copyright holder\]

- Pieter A. Arnold ([ORCID](https://orcid.org/0000-0002-6158-7752))
  (co-author of the bayesTLS framework)

- Patrice Pottier ([ORCID](https://orcid.org/0000-0003-2106-6597))
  (co-author of the bayesTLS framework)

- Daniel W. A. Noble ([ORCID](https://orcid.org/0000-0001-9460-8743))
  (senior author of the bayesTLS thermal-load-sensitivity framework)
