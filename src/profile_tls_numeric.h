// Stable numeric helpers for the freqTLS 4PL likelihood.
//
// These helpers are adapted (patterns only) from the drmTMB package
// (src/drm_numeric.h, GPL-3, https://github.com/itchyshin/drmTMB):
// the series-vs-direct CondExp switching for log1p / log1p(exp()) is theirs.
// freqTLS is GPL-3; see LICENSE.
#ifndef FREQTLS_NUMERIC_H
#define FREQTLS_NUMERIC_H

// Numerically stable inverse logit: 1 / (1 + exp(-eta)), branch-free.
template<class Type>
Type profile_tls_inv_logit(Type eta)
{
  return Type(1.0) / (Type(1.0) + exp(-eta));
}

// Stable log(1 + exp(eta)). For large eta, exp(eta) overflows, so fall back to
// logspace_add(0, eta); for moderate/small eta use a direct/series form. The
// series-vs-direct CondExp split follows drmTMB::drm_log1p_exp_stable.
template<class Type>
Type profile_tls_log1p_exp(Type eta)
{
  Type eta_for_direct = CppAD::CondExpGt(eta, Type(35.0), Type(0.0), eta);
  Type x = exp(eta_for_direct);
  Type series = x - x * x / Type(2.0) + x * x * x / Type(3.0);
  Type direct = log(Type(1.0) + x);
  Type small = CppAD::CondExpLt(x, Type(1e-6), series, direct);
  Type stable = logspace_add(Type(0.0), eta);
  return CppAD::CondExpGt(eta, Type(35.0), stable, small);
}

#endif
