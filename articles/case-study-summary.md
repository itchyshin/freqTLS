# Canonical empirical examples: what can and cannot be compared

The active freqTLS case-study sequence mirrors the pinned [`bayesTLS`
supplement](https://daniel1noble.github.io/bayesTLS/). The table keeps
endpoint, response family, threshold, and reference time visible because
`CTmax` values defined for different endpoints, thresholds, or durations
are not automatically comparable.

``` r

cases <- data.frame(
  Case = c(
    "Zebrafish oxygen", "Cereal aphids", "Snow-gum PSII",
    "D. suzukii mortality", "D. suzukii awake/coma"
  ),
  Dataset = c("zebrafish_o2", "aphid_tdt", "snowgum_psii",
              "dsuzukii", "dsuzukii"),
  Endpoint = c("survival", "survival", "retained PSII",
               "mortality/survival", "awake/coma"),
  Family = c("beta-binomial", "beta-binomial", "Beta",
             "beta-binomial", "beta-binomial"),
  Threshold = c("relative midpoint", "relative midpoint", "relative midpoint",
                "relative CTmax/z; absolute LT50 point check", "relative midpoint"),
  `t_ref (min)` = c(60, 60, 60, 240, 60),
  Report = rep("CTmax and z (not Tcrit)", 5),
  check.names = FALSE
)
knitr::kable(cases)
```

| Case | Dataset | Endpoint | Family | Threshold | t_ref (min) | Report |
|:---|:---|:---|:---|:---|---:|:---|
| Zebrafish oxygen | zebrafish_o2 | survival | beta-binomial | relative midpoint | 60 | CTmax and z (not Tcrit) |
| Cereal aphids | aphid_tdt | survival | beta-binomial | relative midpoint | 60 | CTmax and z (not Tcrit) |
| Snow-gum PSII | snowgum_psii | retained PSII | Beta | relative midpoint | 60 | CTmax and z (not Tcrit) |
| D. suzukii mortality | dsuzukii | mortality/survival | beta-binomial | relative CTmax/z; absolute LT50 point check | 240 | CTmax and z (not Tcrit) |
| D. suzukii awake/coma | dsuzukii | awake/coma | beta-binomial | relative midpoint | 60 | CTmax and z (not Tcrit) |

## Scientific questions

- Oxygen-gradient zebrafish compare diploid normoxia and hyperoxia;
  hypoxia is excluded because `z` is weakly identified.
- Cereal aphids compare species at age 6, then extend to all heat-branch
  ages.
- Snow-gum PSII compares Dark and Light recovery with a plant random
  intercept on `CTmax`.
- *D. suzukii* mortality reports the direct model’s relative `CTmax` and
  `z`, then cross-checks the four-hour absolute LT50 as an ML point. Its
  exact-model bootstrap interval is not reported because too few refits
  converged.
- *D. suzukii* awake/coma uses the first cell duration and excludes
  duration zero because `log10(duration)` cannot represent it; those
  controls are not evidence against `up`. Censored time-to-coma and
  hurdle productivity remain bayesTLS-only.

## Reading estimates across cases

`z` is expressed in degrees per order-of-magnitude change in tolerated
duration, but endpoint and model differences still matter. `CTmax` is
explicitly tied to `t_ref` and the threshold. In particular, the
four-hour mortality value must not be ranked against one-hour
relative-midpoint values as if all rows measured one common trait.
Cross-case displays must retain the columns above.

freqTLS adds Confidence Eyes, profile/Wald/bootstrap confidence
intervals, likelihood contrasts, and explicit identifiability
diagnostics. Those are frequentist extensions to the shared scientific
examples, not substitute case studies.
