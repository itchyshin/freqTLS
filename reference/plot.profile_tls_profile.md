# Plot a profile-likelihood deviance curve

[`plot()`](https://rdrr.io/r/graphics/plot.default.html) for a
`"profile_tls_profile"` object draws the likelihood-ratio deviance curve
against the natural-scale parameter. A dotted horizontal line marks the
profile-t cutoff `qt(1 - alpha/2, df)^2`; a solid vertical line marks
the point estimate; dashed vertical lines mark the interval endpoints
when they are finite. The wording is deliberately "confidence" – this is
a likelihood curve, never a posterior. A non-closing side is annotated
rather than drawn as a closed bound.

## Usage

``` r
# S3 method for class 'profile_tls_profile'
plot(x, ...)
```

## Arguments

- x:

  A `"profile_tls_profile"` object from
  [`profile.profile_tls()`](https://itchyshin.github.io/freqTLS/reference/profile.profile_tls.md).

- ...:

  Reserved; must be empty.

## Value

A `ggplot` object (invisibly when printed for its side effect).

## Details

This plot diagnoses one parameter's likelihood profile. Use
[`plot_confidence_eye()`](https://itchyshin.github.io/freqTLS/reference/plot_confidence_eye.md)
to summarize the resulting confidence interval across one or more
headline parameters.

## Examples

``` r
d <- simulate_tls(family = "binomial", CTmax = 36, z = 4, seed = 1)
fit <- fit_tls(d, y = survived, n = total, time = duration, temp = temp,
               family = "binomial", tref = 1)
plot(profile(fit, "CTmax"))
```
