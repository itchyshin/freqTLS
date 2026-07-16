test_that("the experimental warning is present on every independent surface", {
  pkgdown_path <- test_path("..", "..", "_pkgdown.yml")
  skip_if_not(file.exists(pkgdown_path), "source tree not available")
  pkgdown <- paste(readLines(pkgdown_path, warn = FALSE), collapse = "\n")
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
  pkgdown_path <- test_path("..", "..", "_pkgdown.yml")
  css_path <- test_path("..", "..", "pkgdown", "extra.css")
  skip_if_not(file.exists(pkgdown_path), "source tree not available")
  skip_if_not(file.exists(css_path), "source-tree pkgdown CSS not available")
  pkgdown <- paste(readLines(pkgdown_path, warn = FALSE), collapse = "\n")
  css <- paste(readLines(css_path, warn = FALSE), collapse = "\n")

  expect_length(gregexpr('id="freqtls-experimental-warning"', pkgdown,
                         fixed = TRUE)[[1]], 1L)
  expect_match(pkgdown, 'role="alert"', fixed = TRUE)
  expect_match(pkgdown, 'aria-labelledby="freqtls-experimental-warning-title"',
               fixed = TRUE)
  expect_match(css, ".freqtls-experimental-warning", fixed = TRUE)
  expect_match(css, "margin-top: 56px", fixed = TRUE)
})

test_that("the experimental pkgdown site publishes at its advertised root", {
  pkgdown_path <- test_path("..", "..", "_pkgdown.yml")
  workflow_path <- test_path("..", "..", ".github", "workflows",
                             "pkgdown.yaml")
  builder_path <- test_path("..", "..", "tools", "build-site.R")
  skip_if_not(
    file.exists(pkgdown_path) && file.exists(workflow_path) &&
      file.exists(builder_path),
    "source-tree pkgdown configuration is not available"
  )

  pkgdown <- paste(readLines(pkgdown_path, warn = FALSE), collapse = "\n")
  workflow <- paste(readLines(workflow_path, warn = FALSE), collapse = "\n")
  builder <- paste(readLines(builder_path, warn = FALSE), collapse = "\n")

  expect_match(pkgdown, "url: https://itchyshin.github.io/freqTLS/", fixed = TRUE)
  expect_match(pkgdown, "development:\n  mode: release", fixed = TRUE)
  expect_match(workflow, "folder: pkgdown-site", fixed = TRUE)
  expect_false(grepl("folder: pkgdown-site/dev", workflow, fixed = TRUE))
  expect_match(builder, 'stale_dev_path <- file.path(dst, "dev")', fixed = TRUE)
  expect_match(builder, "unlink(stale_dev_path, recursive = TRUE, force = TRUE)",
               fixed = TRUE)
})
