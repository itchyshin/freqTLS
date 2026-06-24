// freqTLS TMB likelihood: single-stage 4PL thermal-load-sensitivity model
// with a direct CTmax / log_z midpoint reparameterisation and nested-gap
// asymptotes. Families: binomial (0), beta-binomial (1), beta (2).
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
  DATA_MATRIX(X_gap);      // design matrix for the nested gap up|low (logit)
  DATA_MATRIX(X_logk);     // design matrix for log(k)
  DATA_INTEGER(family_code); // 0 binomial, 1 beta_binomial, 2 beta
  DATA_SCALAR(log10_tref); // log10 of the reference time
  DATA_IVECTOR(re_index);  // 0-based random-intercept group per obs (CTmax RE)
  DATA_IVECTOR(re_index_logz); // 0-based random-intercept group per obs (log_z RE)
  DATA_IVECTOR(re_index_low);  // 0-based random-intercept group per obs (low RE)
  DATA_IVECTOR(re_index_logk); // 0-based random-intercept group per obs (log_k RE)

  // ---- parameters ----------------------------------------------------------
  PARAMETER_VECTOR(beta_low);   // lower-asymptote coefficients (logit, per column)
  PARAMETER_VECTOR(beta_gap);   // nested-gap coefficients (logit, per column)
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
  bool gap_shared  = (beta_gap.size()  == 1);
  bool logk_shared = (beta_logk.size() == 1);
  Type low_s = profile_tls_inv_logit(beta_low(0));
  Type up_s  = low_s + (Type(1.0) - low_s) * profile_tls_inv_logit(beta_gap(0));
  Type k_s   = exp(beta_logk(0));
  vector<Type> low_lin, gap_lin, logk_lin;
  if (!low_shared)  low_lin  = X_low  * beta_low;
  if (!gap_shared)  gap_lin  = X_gap  * beta_gap;
  if (!logk_shared) logk_lin = X_logk * beta_logk;

  // Per-design-column natural-scale shape values for the report. Each is sized to
  // its OWN coefficient vector, since the shape designs may have independent
  // widths. `up` is the nested gap on `low`, so a per-column `up` is only defined
  // when `low` and `gap` share a design (the grouped / uniform-width case); when
  // the widths differ, `up` reports the shared scalar only (the continuous case
  // uses the coefficient SEs, not a per-column `up`). For uniform widths this is
  // identical to the previous block, so existing fits are byte-identical.
  vector<Type> low(beta_low.size());
  for (int j = 0; j < beta_low.size(); ++j) {
    low(j) = profile_tls_inv_logit(beta_low(j));
  }
  vector<Type> k(beta_logk.size());
  for (int j = 0; j < beta_logk.size(); ++j) {
    k(j) = exp(beta_logk(j));
  }
  bool up_per_column = (beta_low.size() == beta_gap.size());
  vector<Type> up(up_per_column ? beta_low.size() : 1);
  if (up_per_column) {
    for (int j = 0; j < beta_low.size(); ++j) {
      up(j) = low(j) + (Type(1.0) - low(j)) * profile_tls_inv_logit(beta_gap(j));
    }
  } else {
    up(0) = up_s;
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
    // Per-observation shape values: the scalar shared path (bit-identical) or
    // the per-observation grouped design.
    // Per-shape values, preserving the EXACT original expressions and ordering
    // (low_i, then up_i, then k_i) for the two pre-existing cases so the fit is
    // bit-identical: the fully-shared scalar path (up_s) and the all-vary grouped
    // path (`low_i + (1 - low_i) * inv_logit(gap_lin(i))`). The middle branch is
    // the new mixed case (low shared, gap varying, or vice versa).
    // low, with an optional random intercept on its logit coordinate. When b_low
    // is empty the original expressions are used verbatim (bit-identical); with a
    // RE the deviation is added on the logit scale before inv_logit, and up_i is
    // recomputed from the shifted low_i (it can no longer use the up_s fast path).
    Type low_i;
    if (b_low.size() > 0) {
      Type low_eta = (low_shared ? beta_low(0) : low_lin(i)) + b_low(re_index_low(i));
      low_i = profile_tls_inv_logit(low_eta);
    } else {
      low_i = low_shared ? low_s : profile_tls_inv_logit(low_lin(i));
    }
    Type up_i;
    if (low_shared && gap_shared && b_low.size() == 0) {
      up_i = up_s;
    } else if (gap_shared) {
      up_i = low_i + (Type(1.0) - low_i) * profile_tls_inv_logit(beta_gap(0));
    } else {
      up_i = low_i + (Type(1.0) - low_i) * profile_tls_inv_logit(gap_lin(i));
    }
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
