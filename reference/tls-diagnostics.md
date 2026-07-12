# Identifiability and data-adequacy diagnostics for thermal-load-sensitivity fits

freqTLS emits explicit identifiability warnings rather than letting weak
data quietly produce confident-looking estimates. This is the package's
clearest value-add over the Bayesian path. The diagnostic contract
splits into two groups:

## Details

- **Data-adequacy (1-8)** depend only on the data and design and are
  checked by `check_tls_data()`, which
  [`fit_tls()`](https://itchyshin.github.io/freqTLS/reference/fit_tls.md)
  runs before optimising. They are also surfaced after the fact by
  [`check_tls()`](https://itchyshin.github.io/freqTLS/reference/check_tls.md).

- **Profile-geometry (9-12)** depend on the profile likelihood and are
  emitted by the profiling code in `R/profile.R` / `R/confint.R`.

All warnings use
[`cli::cli_warn()`](https://cli.r-lib.org/reference/cli_abort.html) so
they can be caught with
[`withCallingHandlers()`](https://rdrr.io/r/base/conditions.html) /
[`tryCatch()`](https://rdrr.io/r/base/conditions.html) and silenced with
[`suppressWarnings()`](https://rdrr.io/r/base/warning.html).
