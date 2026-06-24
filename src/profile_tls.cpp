// freqTLS TMB likelihood: single-stage 4PL thermal-load-sensitivity model
// with a direct CTmax / log_z midpoint reparameterisation and disjoint-bounds
// asymptotes (matching bayesTLS::compute_4pl_bounds). Families: binomial (0),
// beta-binomial (1), beta (2).
//
// Engineering patterns adapted from drmTMB (GPL-3,
// https://github.com/itchyshin/drmTMB):
//   - the Boolean.h pre-include guard below mirrors drmTMB::src/drmTMB.cpp:1-14;
//   - the beta-binomial lgamma density follows drmTMB::src/drmTMB.cpp:1319-1328;
//   - the CondExp probability clamp and shape floor follow
//     drmTMB::src/drmTMB.cpp:1302-1314.
// freqTLS is GPL-3; see LICENSE.

// R 4.5's Apple clang headers currently use a diagnostic pragma for
// -Wfixed-enum-extension that this local clang does not recognize. Including
// Boolean.h through the legacy branch before TMB avoids a package-check
// installation warning without shipping non-portable compiler flags.
#include <Rconfig.h>
#ifdef HAVE_ENUM_BASE_TYPE
#define FREQTLS_RESTORE_HAVE_ENUM_BASE_TYPE 1
#undef HAVE_ENUM_BASE_TYPE
#endif
#include <R_ext/Boolean.h>
#ifdef FREQTLS_RESTORE_HAVE_ENUM_BASE_TYPE
#define HAVE_ENUM_BASE_TYPE 1
#endif
#include <TMB.hpp>
#include "profile_tls_numeric.h"

template<class Type>
Type objective_function<Type>::operator()()
{
  // ---- data ----------------------------------------------------------------
  DATA_VECTOR(y);          // successes (survived), Type so beta-binomial works
  DATA_VECTOR(n);          // trials (total)
  DATA_VECTOR(log_time);   // log10(duration)
  DATA_VECTOR(temp);       // assay temperature (deg C)
  DATA_MATRIX(X_CT);       // design matrix for CTmax
  DATA_MATRIX(X_logz);     // design matrix for log(z)
  DATA_MATRIX(X_low);      // design matrix for low (logit)
  DATA_MATRIX(X_up);       // design matrix for up (disjoint-bounds logit)
  DATA_MATRIX(X_logk);     // design matrix for log(k)
  DATA_INTEGER(family_code); // 0 binomial, 1 beta_binomial, 2 beta
  DATA_SCALAR(log10_tref); // log10 of the reference time
  DATA_SCALAR(low_min);    // disjoint asymptote bounds (bayesTLS compute_4pl_bounds):
  DATA_SCALAR(low_w);      //   low in [low_min, low_min + low_w]
  DATA_SCALAR(up_min);     //   up  in [up_min,  up_min  + up_w]
  DATA_SCALAR(up_w);
  DATA_IVECTOR(re_index);  // 0-based random-intercept group per obs (CTmax RE)
  DATA_IVECTOR(re_index_logz); // 0-based random-intercept group per obs (log_z RE)
  DATA_IVECTOR(re_index_low);  // 0-based random-intercept group per obs (low RE)
  DATA_IVECTOR(re_index_logk); // 0-based random-intercept group per obs (log_k RE)

  // ---- parameters ----------------------------------------------------------
  PARAMETER_VECTOR(beta_low);   // lower-asymptote coefficients (logit, per column)
  PARAMETER_VECTOR(beta_up);    // upper-asymptote coefficients (disjoint-bounds logit, per column)
  PARAMETER_VECTOR(beta_logk);  // log-steepness coefficients (per column)
  PARAMETER_VECTOR(beta_CT);    // CTmax coefficients (per design column)
  PARAMETER_VECTOR(beta_logz);  // log(z) coefficients (per design column)
  PARAMETER(log_phi);           // log overdispersion (beta-binomial only)
  PARAMETER_VECTOR(b_CT);       // CTmax random intercepts (empty vector => no RE)
  PARAMETER(log_sd_CT);         // log SD of the CTmax random intercept
  PARAMETER_VECTOR(b_logz);     // log(z) random intercepts (empty vector => no RE)
  PARAMETER(log_sd_logz);       // log SD of the log(z) random intercept
  PARAMETER_VECTOR(b_low);      // lower-asymptote random intercepts (empty => no RE)
  PARAMETER(log_sd_low);        // log SD of the low random intercept
  PARAMETER_VECTOR(b_logk);     // log-steepness random intercepts (empty => no RE)
  PARAMETER(log_sd_logk);       // log SD of the log_k random intercept

  Type eps = Type(1e-12);
  Type phi = exp(log_phi);

  vector<Type> CT   = X_CT * beta_CT;
  vector<Type> logz = X_logz * beta_logz;

  // Shape parameters. A single shape coefficient (intercept-only / shared shape)
  // takes the SCALAR path, bit-identical to the pre-covariate shared-shape model
  // (the matrix product X_low * beta_low would re-order the gradient sum and so
  // is not used here); multiple coefficients (grouped shapes) use the
  // per-observation design matrices, the same mechanism as CTmax / log_z.
  // Each shape sub-parameter (low, the nested gap, log_k) has its OWN design and
  // may be shared (a single intercept coefficient -> the bit-identical scalar
  // path) or vary per observation, INDEPENDENTLY of the others. A single-column
  // shape skips its matrix product so the shared-shape NLL is bit-identical; with
  // all three shared (or all the same width) this is identical to the previous
  // single `shared_shape` block.
  bool low_shared  = (beta_low.size()  == 1);
  bool up_shared   = (beta_up.size()   == 1);
  bool logk_shared = (beta_logk.size() == 1);
  // Disjoint-bounds asymptotes (bayesTLS::compute_4pl_bounds): low and up each map
  // an unconstrained coefficient onto a half-open interval splitting [lower, upper]
  // at its midpoint, so low < up by construction and `up` is a DIRECT coordinate
  // (no nested gap on low). Each shape sub-parameter has its OWN design and may be
  // shared (a single intercept coefficient -> the scalar path) or vary per
  // observation, INDEPENDENTLY of the others.
  Type low_s = low_min + profile_tls_inv_logit(beta_low(0)) * low_w;
  Type up_s  = up_min  + profile_tls_inv_logit(beta_up(0))  * up_w;
  Type k_s   = exp(beta_logk(0));
  vector<Type> low_lin, up_lin, logk_lin;
  if (!low_shared)  low_lin  = X_low  * beta_low;
  if (!up_shared)   up_lin   = X_up   * beta_up;
  if (!logk_shared) logk_lin = X_logk * beta_logk;

  // Per-design-column natural-scale shape values for the report, each sized to its
  // OWN coefficient vector. low and up are now INDEPENDENT (disjoint bounds), so
  // `up` is sized to beta_up directly.
  vector<Type> low(beta_low.size());
  for (int j = 0; j < beta_low.size(); ++j) {
    low(j) = low_min + profile_tls_inv_logit(beta_low(j)) * low_w;
  }
  vector<Type> up(beta_up.size());
  for (int j = 0; j < beta_up.size(); ++j) {
    up(j) = up_min + profile_tls_inv_logit(beta_up(j)) * up_w;
  }
  vector<Type> k(beta_logk.size());
  for (int j = 0; j < beta_logk.size(); ++j) {
    k(j) = exp(beta_logk(j));
  }

  Type nll = Type(0.0);
  vector<Type> p_fitted(y.size());

  for (int i = 0; i < y.size(); ++i) {
    // log(z) with an optional random intercept, added on the LOG scale BEFORE
    // exp(): when b_logz is empty (no RE) logz_i equals logz(i) exactly, so
    // z_i = exp(logz(i)) is byte-identical to the no-RE model.
    Type logz_i = logz(i);
    if (b_logz.size() > 0) logz_i += b_logz(re_index_logz(i));
    Type z_i = exp(logz_i);
    // CTmax with an optional random intercept. When b_CT is empty (no RE) CT_i
    // equals CT(i) exactly, so the no-RE likelihood is byte-identical.
    Type CT_i = CT(i);
    if (b_CT.size() > 0) CT_i += b_CT(re_index(i));
    // Per-observation shape values (disjoint bounds). low and up each map their
    // own coordinate onto [min, min + w]; low may carry a random intercept on its
    // pre-bounds logit coordinate (added before inv_logit). up has no RE and is a
    // direct coordinate independent of low.
    Type low_i;
    if (b_low.size() > 0) {
      Type low_eta = (low_shared ? beta_low(0) : low_lin(i)) + b_low(re_index_low(i));
      low_i = low_min + profile_tls_inv_logit(low_eta) * low_w;
    } else {
      low_i = low_shared ? low_s : (low_min + profile_tls_inv_logit(low_lin(i)) * low_w);
    }
    Type up_i = up_shared ? up_s : (up_min + profile_tls_inv_logit(up_lin(i)) * up_w);
    // log_k, with an optional random intercept on the log scale (bit-identical
    // when b_logk is empty).
    Type k_i;
    if (b_logk.size() > 0) {
      Type logk_eta = (logk_shared ? beta_logk(0) : logk_lin(i)) + b_logk(re_index_logk(i));
      k_i = exp(logk_eta);
    } else {
      k_i = logk_shared ? k_s : exp(logk_lin(i));
    }
    Type mid = log10_tref - (temp(i) - CT_i) / z_i;    // direct CTmax/z param
    Type eta = k_i * (log_time(i) - mid);
    // stable descending 4PL: p high at short durations, low at long durations
    Type p   = low_i + (up_i - low_i) * profile_tls_inv_logit(-eta);
    // clamp p to [eps, 1 - eps] without branching on a Type (drmTMB pattern)
    p = CppAD::CondExpLt(
      p, eps, eps,
      CppAD::CondExpGt(p, Type(1.0) - eps, Type(1.0) - eps, p)
    );
    p_fitted(i) = p;

    if (family_code == 0) {
      nll -= dbinom(y(i), n(i), p, true);
    } else if (family_code == 1) {
      // beta-binomial via lgamma form (drmTMB::src/drmTMB.cpp:1319-1328)
      Type a = p * phi;
      Type b = (Type(1.0) - p) * phi;
      // shape floor to keep lgamma well behaved (drmTMB:1302-1314)
      Type shape_floor = Type(1e-8);
      a = CppAD::CondExpLt(a, shape_floor, shape_floor, a);
      b = CppAD::CondExpLt(b, shape_floor, shape_floor, b);
      Type yf = n(i) - y(i);
      Type log_density =
        lgamma(n(i) + Type(1.0)) -
        lgamma(y(i) + Type(1.0)) -
        lgamma(yf + Type(1.0)) +
        lgamma(phi) -
        lgamma(n(i) + phi) +
        lgamma(y(i) + a) -
        lgamma(a) +
        lgamma(yf + b) -
        lgamma(b);
      nll -= log_density;
    } else {
      // beta: continuous proportion y in (0, 1). Same p*phi / (1-p)*phi shape
      // convention as the beta-binomial, with the shapes floored so dbeta stays
      // well behaved (drmTMB:1302-1314). n(i) is an unused dummy here.
      Type a = p * phi;
      Type b = (Type(1.0) - p) * phi;
      Type shape_floor = Type(1e-8);
      a = CppAD::CondExpLt(a, shape_floor, shape_floor, a);
      b = CppAD::CondExpLt(b, shape_floor, shape_floor, b);
      nll -= dbeta(y(i), a, b, true);
    }
  }

  // Random-intercept prior on CTmax. Skipped when there is no RE, so the no-RE
  // negative log-likelihood is byte-identical to the fixed-effects model.
  if (b_CT.size() > 0) {
    Type sd_CT = exp(log_sd_CT);
    nll -= dnorm(b_CT, Type(0.0), sd_CT, true).sum();
  }
  // Random-intercept prior on log(z). Skipped when there is no RE, so the no-RE
  // negative log-likelihood is byte-identical to the fixed-effects model.
  if (b_logz.size() > 0) {
    Type sd_logz = exp(log_sd_logz);
    nll -= dnorm(b_logz, Type(0.0), sd_logz, true).sum();
  }
  // Random-intercept priors on low / log_k. Skipped when absent (byte-identical).
  if (b_low.size() > 0) {
    Type sd_low = exp(log_sd_low);
    nll -= dnorm(b_low, Type(0.0), sd_low, true).sum();
  }
  if (b_logk.size() > 0) {
    Type sd_logk = exp(log_sd_logk);
    nll -= dnorm(b_logk, Type(0.0), sd_logk, true).sum();
  }

  vector<Type> z_group = exp(beta_logz);

  REPORT(low);
  REPORT(up);
  REPORT(k);
  REPORT(phi);
  REPORT(beta_CT);
  REPORT(z_group);
  REPORT(p_fitted);
  if (b_CT.size() > 0) {
    Type sigma_CT = exp(log_sd_CT);
    REPORT(sigma_CT);
    REPORT(b_CT);
  }
  if (b_logz.size() > 0) {
    Type sigma_logz = exp(log_sd_logz);
    REPORT(sigma_logz);
    REPORT(b_logz);
  }
  if (b_low.size() > 0) {
    Type sigma_low = exp(log_sd_low);
    REPORT(sigma_low);
    REPORT(b_low);
  }
  if (b_logk.size() > 0) {
    Type sigma_logk = exp(log_sd_logk);
    REPORT(sigma_logk);
    REPORT(b_logk);
  }

  ADREPORT(low);
  ADREPORT(up);
  ADREPORT(k);
  ADREPORT(beta_CT);
  ADREPORT(beta_logz);
  ADREPORT(z_group);
  if (family_code >= 1) ADREPORT(phi);
  if (b_CT.size() > 0) {
    Type sigma_CT = exp(log_sd_CT);
    ADREPORT(sigma_CT);
  }
  if (b_logz.size() > 0) {
    Type sigma_logz = exp(log_sd_logz);
    ADREPORT(sigma_logz);
  }
  if (b_low.size() > 0) {
    Type sigma_low = exp(log_sd_low);
    ADREPORT(sigma_low);
  }
  if (b_logk.size() > 0) {
    Type sigma_logk = exp(log_sd_logk);
    ADREPORT(sigma_logk);
  }

  return nll;
}
