# Doc-consistency tripwires (Rose audit, 2026-06-25). Two whole-fix invariants
# the remediation initially got wrong by updating N-1 of N surfaces:
#   (1) the package title must agree across DESCRIPTION and the package doc
#       (.R + .Rd), and must not revert to "Profile-Likelihood Inference";
#   (2) under the disjoint-bounds asymptotes `up` HAS its own coordinate `beta_up`,
#       so no live doc may state its "nested gap has no single coordinate" as the
#       current reason it is Wald-only.
# inst/CITATION is intentionally excluded from (1): by design freqTLS cites the
# paper it implements, not a separate R-package self-citation, so the package
# title does not appear there (2026-07-19 citation policy change).
# Dev-only where the source tree is needed (skipped against an installed package).

repo_root <- function() normalizePath(test_path("..", ".."), mustWork = FALSE)

test_that("the package title agrees across DESCRIPTION and package doc", {
  files <- file.path(repo_root(),
                     c("DESCRIPTION", "R/freqTLS-package.R",
                       "man/freqTLS-package.Rd"))
  skip_if_not(all(file.exists(files)), "source tree not available")
  the_title <- "Frequentist Inference for Thermal Load Sensitivity Models"
  for (f in files) {
    txt <- paste(readLines(f, warn = FALSE), collapse = "\n")
    expect_true(grepl(the_title, txt, fixed = TRUE),
                info = paste(basename(f), "is missing the agreed package title"))
    expect_false(grepl("Profile-Likelihood Inference", txt, fixed = TRUE),
                 info = paste(basename(f),
                              "reverted to the 'Profile-Likelihood Inference' title"))
  }
})

test_that("no live doc claims up's 'nested gap has no single coordinate'", {
  targets <- file.path(repo_root(),
                       c("README.md", "README.Rmd", "ROADMAP.md", "SPEC.md",
                         "vignettes", "R", "man", "docs/design",
                         "docs/dev-log/known-limitations.md"))
  targets <- targets[file.exists(targets)]
  skip_if_not(length(targets) > 0, "source tree not available")
  files <- unlist(lapply(targets, function(p)
    if (dir.exists(p))
      list.files(p, pattern = "[.](R|Rd|md|Rmd)$", full.names = TRUE,
                 recursive = TRUE)
    else p))
  pat <- "nested gap has no single|no single (internal )?coordinate under the nested"
  bad <- character(0)
  for (f in files) {
    ln <- readLines(f, warn = FALSE)
    hit <- grep(pat, ln, perl = TRUE)
    if (length(hit)) bad <- c(bad, sprintf("%s:%s", f, paste(hit, collapse = ",")))
  }
  expect_identical(bad, character(0),
                   info = paste("present-tense nested-gap claims:",
                                paste(bad, collapse = "; ")))
})

test_that("row counts stated in known-limitations.md match the shipped data", {
  doc <- file.path(repo_root(), "docs", "dev-log", "known-limitations.md")
  skip_if_not(file.exists(doc), "source tree not available")
  txt <- paste(readLines(doc, warn = FALSE), collapse = "\n")
  ns <- asNamespace("freqTLS")
  data_names <- c("aphid_tdt", "dsuzukii", "shrimp_lethal", "shrimp_sublethal",
                  "zebrafish_lethal", "zebrafish_o2")
  rx <- "`([a-z_]+)` \\(([0-9,]+) rows"
  hits <- regmatches(txt, gregexpr(rx, txt, perl = TRUE))[[1]]
  bad <- character(0)
  for (h in hits) {
    p <- regmatches(h, regexec(rx, h, perl = TRUE))[[1]]
    nm <- p[2]; stated <- as.integer(gsub(",", "", p[3]))
    if (!nm %in% data_names) next
    actual <- nrow(get(nm, envir = ns))
    if (!identical(stated, actual))
      bad <- c(bad, sprintf("%s: doc says %d, data has %d", nm, stated, actual))
  }
  expect_identical(bad, character(0),
                   info = paste("row-count drift in known-limitations.md:",
                                paste(bad, collapse = "; ")))
})

test_that("every documented callable has return-value documentation", {
  man_dir <- file.path(repo_root(), "man")
  skip_if_not(dir.exists(man_dir), "source tree not available")
  rd_files <- list.files(man_dir, pattern = "[.]Rd$", full.names = TRUE)
  missing_value <- vapply(rd_files, function(f) {
    txt <- readLines(f, warn = FALSE)
    is_dataset <- any(grepl("^\\\\keyword\\{datasets\\}", txt))
    !is_dataset && any(grepl("^\\\\usage\\{", txt)) &&
      !any(grepl("^\\\\value\\{", txt))
  }, logical(1))
  expect_identical(
    basename(rd_files[missing_value]), character(0),
    info = "Rd topics with a callable usage block must document their return value"
  )
})

test_that("the function-map SVG is declared as an installed vignette extra", {
  vignette_dir <- file.path(repo_root(), "vignettes")
  source_svg <- file.path(vignette_dir, "freqTLS_function_map.svg")
  extras <- file.path(vignette_dir, ".install_extras")
  skip_if_not(all(file.exists(c(source_svg, extras))),
              "source vignette tree not available")
  installed_names <- trimws(readLines(extras, warn = FALSE))
  expect_true("freqTLS_function_map.svg" %in% installed_names)
})

test_that("release docs distinguish five articles from six shipped datasets", {
  files <- file.path(repo_root(),
                     c("ROADMAP.md", "docs/dev-log/known-limitations.md"))
  skip_if_not(all(file.exists(files)), "source tree not available")
  txt <- paste(unlist(lapply(files, readLines, warn = FALSE)), collapse = "\n")
  expect_false(grepl("six case studies", txt, fixed = TRUE))
  expect_true(grepl("five case-study articles", txt, fixed = TRUE))
})

test_that("licensing-pending environmental traces are not installed", {
  root <- repo_root()
  installed <- file.path(
    root, "inst", "extdata",
    c("data_temp_trace_aphid_summer2016.csv",
      "orsted_2024/orsted2024_nichemapr_rennes_2018_hourly.csv.gz")
  )
  skip_if_not(dir.exists(file.path(root, "inst", "extdata")),
              "source tree not available")
  expect_false(any(file.exists(installed)))
})
