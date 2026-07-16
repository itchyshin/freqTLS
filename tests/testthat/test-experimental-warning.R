test_that("the experimental warning is present on every independent surface", {
  pkgdown <- paste(readLines(test_path("..", "..", "_pkgdown.yml"), warn = FALSE),
                   collapse = "\n")
  readme <- paste(readLines(test_path("..", "..", "README.Rmd"), warn = FALSE),
                  collapse = "\n")
  package_doc <- paste(readLines(test_path("..", "..", "R", "freqTLS-package.R"),
                                 warn = FALSE), collapse = "\n")
  fit4_doc <- paste(readLines(test_path("..", "..", "R", "fit_4pl.R"), warn = FALSE),
                    collapse = "\n")
  fittls_doc <- paste(readLines(test_path("..", "..", "R", "fit_tls.R"), warn = FALSE),
                      collapse = "\n")

  required <- c(
    "own risk",
    "data, design",
    "convergence, identifiability, diagnostics",
    "Agreement is a cross-check, not proof of correctness",
    "shared data or model errors can make both packages agree",
    "https://daniel1noble.github.io/bayesTLS/",
    "https://github.com/daniel1noble/bayesTLS"
  )

  clean_surface <- function(x) {
    x <- gsub("#'", "", x, fixed = TRUE)
    x <- gsub("[>#*`]", "", x)
    tolower(gsub("[[:space:]]+", " ", x))
  }
  required <- tolower(required)

  for (surface in list(pkgdown, readme, package_doc, fit4_doc, fittls_doc)) {
    surface <- clean_surface(surface)
    expect_true(all(vapply(required, grepl, logical(1), x = surface,
                           fixed = TRUE)))
  }
})

test_that("the pkgdown warning uses one accessible site-wide template include", {
  pkgdown <- paste(readLines(test_path("..", "..", "_pkgdown.yml"), warn = FALSE),
                   collapse = "\n")

  expect_length(gregexpr('id="freqtls-experimental-warning"', pkgdown,
                         fixed = TRUE)[[1]], 1L)
  expect_match(pkgdown, 'role="alert"', fixed = TRUE)
  expect_match(pkgdown, 'aria-labelledby="freqtls-experimental-warning-title"',
               fixed = TRUE)
})
