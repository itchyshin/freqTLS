# Doc-consistency tripwires (Rose audit, 2026-06-25). Two whole-fix invariants
# the remediation initially got wrong by updating N-1 of N surfaces:
#   (1) the package title must agree across DESCRIPTION, the package doc (.R + .Rd),
#       and inst/CITATION, and must not revert to "Profile-Likelihood Inference";
#   (2) under the disjoint-bounds asymptotes `up` HAS its own coordinate `beta_up`,
#       so no live doc may state its "nested gap has no single coordinate" as the
#       current reason it is Wald-only.
# Dev-only where the source tree is needed (skipped against an installed package).

repo_root <- function() normalizePath(test_path("..", ".."), mustWork = FALSE)

test_that("the package title agrees across DESCRIPTION, package doc, and CITATION", {
  files <- file.path(repo_root(),
                     c("DESCRIPTION", "R/freqTLS-package.R",
                       "man/freqTLS-package.Rd", "inst/CITATION"))
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
