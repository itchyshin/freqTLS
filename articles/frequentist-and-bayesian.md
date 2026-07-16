# Frequentist and Bayesian thermal-load sensitivity: strengths, weaknesses, and the blurry line

``` r

library(freqTLS)
```

This vignette is for a thermal biologist deciding **how** to fit a
thermal-load- sensitivity (TLS) model, not just **which package**.
`freqTLS` (maximum likelihood, profile-likelihood intervals) and
[`bayesTLS`](https://github.com/daniel1noble/bayesTLS) (Bayesian,
posterior intervals) fit the *same* four-parameter logistic
thermal-death-time model. They are complementary lenses on one model,
and the choice between them is really a choice between two ways of
handling the same hard realities: weak data, weak identifiability, and
non-convergence. The aim here is an honest account of the trade-offs —
including the uncomfortable fact, developed at the end, that the
“prior-free” frequentist path quietly uses prior-like machinery of its
own.

It builds **without Stan**: the `freqTLS` fits run live, while the
Bayesian comparison and the coverage evidence are read from cached
simulations rather than recomputed.

## One model, two inferential philosophies

Both packages fit survival as a 4PL curve in `log10(duration)` whose
midpoint moves with temperature through `CTmax` (the critical thermal
maximum) and `z` (thermal sensitivity). They differ only in **how they
turn data into a statement about the parameters**:

- **`freqTLS` (likelihood).** It maximises the likelihood and inverts
  the likelihood-ratio test to get a **confidence interval** — the set
  of parameter values the data do not reject at a given level. No prior;
  the interval reflects the data and the model alone.
- **`bayesTLS` (Bayesian).** It combines the likelihood with a **prior**
  to get a **posterior**, and reports a **credible interval** — a
  probability statement about the parameter, conditional on the prior.

On strong data these agree closely — on the brown-shrimp benchmark the
two packages’ `CTmax` estimates differ by only about 0.07 °C (cached in
`benchmark_vs_bayes.rds`; the full three-way comparison, which adds the
classical two-stage method, is in
[`vignette("comparing-to-bayesTLS")`](https://itchyshin.github.io/freqTLS/articles/comparing-to-bayesTLS.md)).
They diverge exactly where the data are weak and the prior starts to do
the work — which is precisely where you most need to know what is data
and what is assumption.

## Priors: regularisation versus sensitivity

A prior is a double-edged tool.

- **As a strength**, a prior *regularises*: it pulls estimates toward
  plausible values, stabilises fits on thin data, and propagates genuine
  prior knowledge. A weakly identified parameter that the likelihood
  alone cannot pin down can still yield a finite, sensible posterior.
- **As a weakness**, that same pull is *sensitivity*: the answer can
  depend on the prior, and a reader must trust (and the analyst must
  defend) that choice. A confident-looking posterior may be reporting
  the prior as much as the data.

`freqTLS` takes the opposite trade. Being prior-free, it needs nothing
to defend and reports only what the data carry — but it offers **no free
regularisation**: when the data are thin, the likelihood is flat and the
interval is wide or fails to close. That is not a defect to paper over;
it is information (see the next section). When you genuinely have prior
knowledge and want to use it, that is a positive reason to reach for
`bayesTLS`.

## Identifiability: revealing versus masking

This is the sharpest practical difference.

When a parameter is **weakly identified** — the data barely constrain it
— the likelihood is nearly flat along that direction. The two paths
respond in opposite ways:

- **`freqTLS` reveals it.** The profile does not close,
  [`confint()`](https://rdrr.io/r/stats/confint.html) returns `NA` on
  the open side (never a fabricated bound) or falls back to a prior-free
  bootstrap, and the package emits an explicit identifiability warning.
  The Confidence Eye draws a hollow point with an open lens, so weak
  data *look* weak. freqTLS surfaces twelve such data-adequacy and
  profile-geometry warnings rather than letting thin data produce
  confident-looking numbers.
- **A prior can mask it.** Add a prior and the posterior closes: the
  credible interval looks finite and tidy. But for a non-identified
  direction that interval is largely the prior, re-expressed. The
  weakness is real; it has just been hidden behind an assumption.

``` r

# Sparse design: few temperatures, so the CTmax/z slope is weakly identified.
sparse <- simulate_tls(
  temps = c(35, 36), times = c(1, 4), reps = 2, n = 20,
  CTmax = 36, z = 4, family = "binomial", seed = 11
)
fit_sparse <- suppressWarnings(fit_tls(
  sparse, y = survived, n = total, time = duration, temp = temp,
  family = "binomial", tref = 1
))
# freqTLS says so: a profile that does not close returns NA on the open side
# (here with the prior-free bootstrap fallback turned off to show the raw signal).
suppressWarnings(confint(fit_sparse, "z", method = "profile", fallback = FALSE))
#> # A tibble: 1 × 8
#>   parameter conf.low conf.high estimate level method  scale conf.status
#>   <chr>        <dbl>     <dbl>    <dbl> <dbl> <chr>   <chr> <chr>      
#> 1 z               NA        NA     2.95  0.95 profile log   open_both
```

Neither behaviour is “right” in the abstract. The point is that they
answer different questions: *what do the data alone support?* versus
*what should I believe, given the data and my prior?* `freqTLS` makes
weak identifiability visible; the Bayesian path lets you act through it,
at the cost of leaning on the prior. Reporting both — or at least being
explicit about which you used — is the honest stance (Amrhein, Greenland
& McShane, 2019).

## Non-convergence and diagnostics

Both paths can fail, in different ways and with different tells:

|  | `freqTLS` (ML) | `bayesTLS` (MCMC) |
|----|----|----|
| Failure modes | optimiser non-convergence (`code != 0`); non-positive-definite Hessian (`pdHess = FALSE`); a profile that does not close | divergent transitions; low effective sample size; `R-hat > 1.01`; poor mixing |
| Diagnostics | convergence code, `pdHess`, profile geometry, the identifiability warnings | divergences, ESS, `R-hat`, trace plots |
| Typical fixes | better starts, the built-in BFGS retry, the **bootstrap fallback** so an interval is always returned, or simplifying the model | reparameterising, more iterations/adapt-delta, or **stronger priors** |

Two things are worth noting. First, the Bayesian fix of last resort —
strengthening the prior — is the very lever that trades identifiability
for prior dependence (above). Second, `freqTLS` is built to **always
return an interval**: when a profile does not close or the Hessian is
not positive definite,
[`confint()`](https://rdrr.io/r/stats/confint.html) falls back to a
prior-free parametric bootstrap, matching the “you always get an answer”
convenience of a Bayesian fit without a prior. It runs in milliseconds
with no Stan toolchain, where an MCMC fit takes minutes and a working
sampler.

## Confidence versus credible intervals

The interval labels are not interchangeable. A `freqTLS` interval is a
**confidence** interval: parameter values not rejected by the data at
the stated level, with a coverage interpretation and no prior. A
`bayesTLS` interval is a **credible** interval: a posterior-probability
statement that depends on the prior. `freqTLS` therefore never calls its
intervals “posterior” or “credible”, and its default visual (the
Confidence Eye) deliberately avoids posterior-density iconography. Some
statisticians argue these intervals should be renamed *compatibility*
intervals — to discourage misreading the coverage as a probability about
the parameter — and that “significance” language should be retired (Rafi
& Greenland 2020; Amrhein, Greenland & McShane 2019); freqTLS keeps the
familiar term “confidence interval” but shares that caution.

## Does the interval actually cover? Small-sample calibration

A confidence interval is only worth the name if it contains the truth at
the advertised rate. That is a *checkable* claim — and, unlike the
Bayesian path whose calibration is entangled with the prior, the
frequentist path lets us check it cleanly: simulate data from a known
`CTmax` and `z`, refit, and count how often the nominal 95% interval
covers the generating value.

The asymptotic theory behind a likelihood interval is exact only as the
sample grows. In small samples the curvature-based standard error is a
little too small and the normal / chi-squared reference a little too
generous, so the naive interval comes out **too narrow and
under-covers**. `freqTLS` corrects this with the **Bates–Watts
profile-t** calibration: it refers the signed-root likelihood statistic
to a *t* distribution with the residual degrees of freedom of the fit
(`df = n_obs − n_parameters`) rather than to a standard normal. This
widens the Wald and profile intervals precisely when the sample is
small, and not at all when it is large (Bates & Watts, 1988).

The pay-off, measured over ~500 simulated datasets per cell (cached in
`calibration_results.rds`):

| Sample size | Residual df | Coverage (Wald, z-ref) | Coverage (Wald, t-ref) | Extra width |
|:---|---:|:---|:---|:---|
| small | 10 | 0.927 | 0.964 | +14% |
| medium | 35 | 0.946 | 0.964 | +4% |
| large | 100 | 0.970 | 0.970 | +1% |

95% confidence-interval coverage for CTmax (nominal 0.95), over ~500
simulated datasets per cell. Monte-Carlo SE ≈ 0.01. {.table}

At `df ≈ 10` the asymptotic 95% interval covers only about 93% of the
time; the t-calibration restores it to ~96%, at the cost of ~14% extra
width. By `df ≈ 100` the two references coincide (`t ≈ z`) and the
correction costs essentially nothing. The widening is therefore
self-cancelling: it pays for the small-sample optimism of the
asymptotics, then steps out of the way as data accumulate.

The coverages above are for the **Wald** interval, where the
*z*-versus-*t* reference is a clean one-line change. The default
**profile** interval inherits the *same* small-sample correction — its
cutoff is the squared *t* quantile `qt(df)^2` rather than
`qchisq(level, 1)` — so it tracks the Wald *t*-reference column, not the
asymptotic-*z* one.

This bears on the Bayesian comparison in two ways. First, it is the
honest basis for the “confidence” label of the previous section — here
the coverage is *measured*, not assumed. Second, it is itself a mild
small-sample adjustment, a frequentist cousin of the regularisation
discussed next: a correction that leans on the *t* distribution much as
a weakly informative prior leans on its scale. The difference is that
this one is explicit, validated by simulation, and disappears as the
sample grows.

## The blurry line: clamping, shrinkage, and penalties as implicit priors

It is tempting to frame this as “prior versus no prior”. That is too
clean. **Frequentist fits routinely embed prior-like regularisation**,
and `freqTLS` is no exception. Three forms appear in this very package.

**Clamping.** To keep the likelihood well behaved, `freqTLS` clamps the
fitted probability off the boundary (to `[1e-12, 1 - 1e-12]`), clamps a
`beta`- family response off `{0, 1}`, and floors the Beta shape
parameters. Each is a hard interior bound — behaviourally a degenerate
prior that assigns no mass to the edge. This is the same disease that
**separation** cures with a penalty or a weak prior: with perfectly
separated binary data the unpenalised maximum- likelihood estimate runs
to infinity, and a mild penalty (equivalently, a weakly informative
prior) brings it back to a finite value (Firth, 1993; Gelman, Jakulin,
Pittau & Su, 2008). The advantage is numerical stability and finite
estimates; the cost is a small, usually hidden, boundary bias and an
arbitrary clamp constant.

**Shrinkage / partial pooling.** `freqTLS`’s random intercepts on
`CTmax`, `log_z`, `low`, and `log_k`
(e.g. `CTmax ~ <fixed> + (1 | group)`) assume the group deviations are
Gaussian, `b_g ~ N(0, sigma)`. That Gaussian *is* a prior on the
deviations, and the predicted group effects (the BLUPs returned by
[`ranef()`](https://itchyshin.github.io/freqTLS/reference/ranef.md)) are
**shrunk toward zero** exactly as a posterior mean would be — the
empirical-Bayes view of mixed models (James & Stein, 1961; Efron &
Morris, 1975; Robinson, 1991). Shrinkage borrows strength across groups
and lowers variance; the costs are that the shrinkage scale is itself a
modelling assumption, and the maximum-likelihood variance is biased low
with few groups, a boundary problem usually addressed with — again — a
penalty or prior on the variance component (Chung, Rabe-Hesketh, Dorie,
Gelman & Liu, 2013).

``` r

# Data-poor colonies (few assays each) so partial pooling has work to do.
d_re <- simulate_tls(
  family = "binomial", temps = c(34, 36, 38), times = c(1, 4), reps = 1, n = 8,
  CTmax = 36, z = 4, re_sd = 1.5, n_re_groups = 12, seed = 42
)
# Partial pooling: a random intercept shrinks the colony effects toward 0.
fit_re <- suppressWarnings(fit_tls(
  tls_bf(survived | trials(total) ~ time(duration) + temp(temp),
         CTmax ~ 1 + (1 | colony)),
  data = d_re, family = "binomial", tref = 1
))
blup <- ranef(fit_re)$estimate
# No pooling: a fixed CTmax per colony (the unshrunk per-group estimates).
fit_fix <- suppressWarnings(fit_tls(
  d_re, y = survived, n = total, time = duration, temp = temp,
  group = colony, family = "binomial", tref = 1
))
ct_fix <- fit_fix$estimates$estimate[startsWith(fit_fix$estimates$parameter, "CTmax:")]
# The Gaussian prior on b_g (scale sigma_CTmax) pulls the spread in.
c(no_pooling_sd = round(sd(ct_fix - mean(ct_fix)), 2),
  partial_pooling_sd = round(sd(blup), 2),
  sigma_CTmax = round(fit_re$estimates$estimate[fit_re$estimates$parameter == "sigma_CTmax"], 2))
#>      no_pooling_sd partial_pooling_sd        sigma_CTmax 
#>               2.32               1.48               1.48
```

Here the spread of the colony effects is pulled in from the no-pooling
fit (a separate `CTmax` per colony) to the shrunk random-effect BLUPs —
the Gaussian prior `b_g ~ N(0, sigma)` doing exactly what a prior does.
The pull is strongest for data-poor colonies; with many assays per
colony there is little to shrink.

**Penalised likelihood in general.** More broadly, adding a penalty to
the log- likelihood is **maximum a posteriori (MAP) estimation under a
prior**: ridge is a Gaussian prior (Hoerl & Kennard, 1970), the lasso is
a Laplace prior (Tibshirani, 1996; Park & Casella, 2008), and Firth’s
bias-reduction penalty is the Jeffreys prior (Firth, 1993). The
continuum from maximum likelihood through profile likelihood to
penalised likelihood is laid out by Cole, Chu & Greenland (2014), and
the penalty-as-prior equivalence — penalised likelihood equals maximum a
posteriori (MAP) estimation under a prior — is standard (Bishop, 2006;
Hastie, Tibshirani & Friedman, 2009).

So the real distinction is not *prior versus no prior*. It is **how the
regularisation is expressed and propagated**:

- a Bayesian prior is *explicit* and its uncertainty flows into the
  posterior;
- a clamp is *implicit and fixed* (a tuning constant, not propagated);
- a random effect or penalty is *semi-explicit* (a structural assumption
  with a scale that is estimated or chosen).

`freqTLS` keeps its regularisation light and transparent — a documented
clamp, an optional and clearly labelled random effect — and reports
confidence intervals rather than a posterior. But it is honest to say it
is *lightly regularised*, not *assumption-free*.

## Practical guidance: when to reach for which

- **Reach for `freqTLS`** when you want fast, prior-free,
  asymmetry-respecting intervals; when you want weak identifiability
  surfaced rather than smoothed over; or when a Stan toolchain is
  impractical. It is the natural default for a quick, defensible,
  reproducible fit.
- **Reach for `bayesTLS`** when you have genuine prior information to
  use; when you want full posterior uncertainty (including for derived
  quantities) and probability statements; or when regularisation through
  a principled prior is exactly what thin data call for.
- **Use both** when it matters. Agreement on strong data is reassuring;
  disagreement on weak data is diagnostic — it localises where the prior
  is doing the work. That pluralism, not a winner, is the point.

## References

- Amrhein, V., Greenland, S., & McShane, B. (2019). Scientists rise up
  against statistical significance \[Comment\]. *Nature*, 567, 305–307.
  <https://doi.org/10.1038/d41586-019-00857-9>
- Bates, D. M., & Watts, D. G. (1988). *Nonlinear Regression Analysis
  and Its Applications*. Wiley. <https://doi.org/10.1002/9780470316757>
- Bishop, C. M. (2006). *Pattern Recognition and Machine Learning*
  (§3.1.4, §3.3). Springer.
- Chung, Y., Rabe-Hesketh, S., Dorie, V., Gelman, A., & Liu, J. (2013).
  A nondegenerate penalized likelihood estimator for variance parameters
  in multilevel models. *Psychometrika*, 78(4), 685–709.
  <https://doi.org/10.1007/s11336-013-9328-2>
- Cole, S. R., Chu, H., & Greenland, S. (2014). Maximum likelihood,
  profile likelihood, and penalized likelihood: a primer. *American
  Journal of Epidemiology*, 179(2), 252–260.
  <https://doi.org/10.1093/aje/kwt245>
- Efron, B., & Morris, C. (1975). Data analysis using Stein’s estimator
  and its generalizations. *Journal of the American Statistical
  Association*, 70(350), 311–319.
  <https://doi.org/10.1080/01621459.1975.10479864>
- Firth, D. (1993). Bias reduction of maximum likelihood estimates.
  *Biometrika*, 80(1), 27–38. <https://doi.org/10.1093/biomet/80.1.27>
- Gelman, A., & Hill, J. (2007). *Data Analysis Using Regression and
  Multilevel/Hierarchical Models*. Cambridge University Press.
- Gelman, A., Jakulin, A., Pittau, M. G., & Su, Y.-S. (2008). A weakly
  informative default prior distribution for logistic and other
  regression models. *The Annals of Applied Statistics*, 2(4),
  1360–1383. <https://doi.org/10.1214/08-AOAS191>
- Hastie, T., Tibshirani, R., & Friedman, J. (2009). *The Elements of
  Statistical Learning* (2nd ed.). Springer.
  <https://doi.org/10.1007/978-0-387-84858-7>
- Hoerl, A. E., & Kennard, R. W. (1970). Ridge regression: biased
  estimation for nonorthogonal problems. *Technometrics*, 12(1), 55–67.
  <https://doi.org/10.1080/00401706.1970.10488634>
- James, W., & Stein, C. (1961). Estimation with quadratic loss. In
  *Proceedings of the Fourth Berkeley Symposium on Mathematical
  Statistics and Probability* (Vol. 1, pp. 361–379). University of
  California Press.
- Park, T., & Casella, G. (2008). The Bayesian lasso. *Journal of the
  American Statistical Association*, 103(482), 681–686.
  <https://doi.org/10.1198/016214508000000337>
- Rafi, Z., & Greenland, S. (2020). Semantic and cognitive tools to aid
  statistical science: replace confidence and significance by
  compatibility and surprise. *BMC Medical Research Methodology*,
  20, 244. <https://doi.org/10.1186/s12874-020-01105-9>
- Robinson, G. K. (1991). That BLUP is a good thing: the estimation of
  random effects. *Statistical Science*, 6(1), 15–32.
  <https://doi.org/10.1214/ss/1177011926>
- Tibshirani, R. (1996). Regression shrinkage and selection via the
  lasso. *Journal of the Royal Statistical Society: Series B*, 58(1),
  267–288. <https://doi.org/10.1111/j.2517-6161.1996.tb02080.x>
