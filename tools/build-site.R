#!/usr/bin/env Rscript

# Build the public pkgdown site, then strip internal documents that pkgdown
# renders by default but must NOT appear on the public site.
#
# Why a post-build step? pkgdown (>= 2.1.3) discovers home-page Markdown by
# globbing every `*.md` at the package root (see pkgdown:::package_mds). It
# ignores .Rbuildignore and exposes no config key to exclude arbitrary files,
# so root files like AGENTS.md, CLAUDE.md and SPEC.md are rendered to
# AGENTS.html, CLAUDE.html and SPEC.html. Those files must stay at the repo
# root for the AI tooling and the SPEC critique, so we remove only their
# *rendered copies* after the build. ROADMAP.html and the changelog are
# user-facing and are kept.
#
# This script is the single source of truth for "build the public site" and is
# used both locally and in the pkgdown GitHub Actions workflow.

args <- commandArgs(trailingOnly = TRUE)
pkg_path <- if (length(args) >= 1) args[[1]] else "."

# Examples on the reference pages need the package on the search path. Install
# it (into a temporary library by default) unless it is already available, so
# the script works both on a fresh local checkout and in CI where the package
# is already installed via `local::.`.
install_pkg <- !requireNamespace("freqTLS", quietly = TRUE)
pkgdown::build_site(pkg_path, preview = FALSE, devel = FALSE,
                    new_process = FALSE, install = install_pkg)

# Resolve the build destination from the pkgdown config (defaults to docs/).
dst <- pkgdown::as_pkgdown(pkg_path)$dst_path

internal_stems <- c("AGENTS", "CLAUDE", "SPEC")
internal_pages <- as.vector(outer(internal_stems, c(".html", ".md"), paste0))
to_remove <- file.path(dst, internal_pages)
existing <- to_remove[file.exists(to_remove)]

if (length(existing)) {
  file.remove(existing)
  message("Removed internal pages from the public site: ",
          paste(basename(existing), collapse = ", "))
} else {
  message("No internal pages found in ", dst, " (nothing to remove).")
}

# The files are also indexed before their HTML copies are removed. Remove their
# search records and sitemap URLs so an internal page cannot remain discoverable
# through the public site's search box or crawler metadata.
search_path <- file.path(dst, "search.json")
if (file.exists(search_path)) {
  search_index <- jsonlite::fromJSON(search_path, simplifyVector = FALSE)
  keep <- !vapply(search_index, function(entry) {
    path <- entry$path
    # Some pkgdown records (for example generated section headings) have no
    # path field.  `vapply()` needs one logical result for those records too.
    if (is.null(path) || length(path) != 1L || is.na(path)) path <- ""
    any(vapply(internal_stems, function(stem) {
      grepl(paste0("/", stem, ".html$"), path)
    }, logical(1)))
  }, logical(1))
  jsonlite::write_json(search_index[keep], search_path, auto_unbox = TRUE,
                       pretty = FALSE)
}

sitemap_path <- file.path(dst, "sitemap.xml")
if (file.exists(sitemap_path)) {
  sitemap <- readLines(sitemap_path, warn = FALSE, encoding = "UTF-8")
  keep <- !vapply(sitemap, function(line) {
    any(vapply(internal_stems, function(stem) {
      grepl(paste0("/", stem, ".html"), line, fixed = TRUE)
    }, logical(1)))
  }, logical(1))
  writeLines(sitemap[keep], sitemap_path, useBytes = TRUE)
}

# ---- accessibility: alt text for the reference example figures ------------
# pkgdown runs @examples through downlit::evaluate_and_highlight(), whose
# replay_html.recordedplot() hard-codes alt='' on the generated <img> tags and
# exposes no hook (no `#| fig.alt:` parsing) to set it. Until that lands
# upstream, fill the empty alt of the example figures here, keyed by image
# basename. Alt text is ASCII and quote-free so the in-place substitution is
# safe; only an empty alt="" is filled, never an existing one.
example_alt <- c(
  "plot_confidence_eye-1.png" =
    "Confidence Eye for CTmax and z from a simulated binomial fit: the CTmax panel shows a narrow lens around 36 degrees Celsius with a hollow point estimate; the z panel shows a wide shallow lens around 4.",
  "plot_survival_curves-1.png" =
    "Fitted 4PL survival curves from a simulated binomial fit: survival probability declining with log exposure duration, one coloured line per assay temperature from 30 to 42 degrees Celsius (hotter temperatures decline sooner), with observed proportions overlaid as points.",
  "plot_tdt_curve-1.png" =
    "Thermal death-time curve from a simulated binomial fit: log10 of the duration to 50 percent survival falling linearly with temperature from 30 to 42 degrees Celsius.",
  "plot_survival_surface-1.png" =
    "Fitted survival surface from a simulated binomial fit: a filled heatmap over temperature by log-duration with contour lines, high survival at low temperatures and short durations grading to low survival at high temperatures and long durations.",
  "plot.profile_tls_profile-1.png" =
    "Profile-likelihood deviance curve for CTmax from a simulated binomial fit: a U-shaped curve with a horizontal dotted profile-t cutoff line, dashed vertical lines at the interval endpoints, and a solid vertical line at the maximum-likelihood estimate.",
  "plot_heat_injury-1.png" =
    "Heat-injury survival band from a simulated binomial fit under a fluctuating temperature trace: a declining point-estimate survival curve over time wrapped in a pale pointwise confidence band."
)

inject_example_alt <- function(dst, alt_map) {
  ref_dir <- file.path(dst, "reference")
  if (!dir.exists(ref_dir)) return(0L)
  files <- list.files(ref_dir, pattern = "[.]html$", full.names = TRUE)
  changed <- 0L
  for (f in files) {
    txt <- paste(readLines(f, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
    orig <- txt
    for (img in names(alt_map)) {
      esc <- gsub(".", "[.]", img, fixed = TRUE)   # escape dots in the basename
      alt <- alt_map[[img]]
      # Fill an empty alt whether it sits after src (the usual order) or before.
      txt <- gsub(sprintf('(<img\\b[^>]*\\bsrc="%s"[^>]*\\balt=)""', esc),
                  sprintf('\\1"%s"', alt), txt, perl = TRUE)
      txt <- gsub(sprintf('(<img\\b[^>]*\\balt=)""([^>]*\\bsrc="%s")', esc),
                  sprintf('\\1"%s"\\2', alt), txt, perl = TRUE)
    }
    if (!identical(txt, orig)) {
      con <- file(f, open = "w", encoding = "UTF-8")
      writeLines(txt, con)
      close(con)
      changed <- changed + 1L
    }
  }
  changed
}

n_alt <- tryCatch(
  inject_example_alt(dst, example_alt),
  error = function(e) {
    warning("Example alt-text injection failed: ", conditionMessage(e))
    0L
  }
)
message("Filled alt text on example figures in ", n_alt, " reference page(s).")

# Fail loudly if any internal page survived, so the privacy invariant is checked
# on every build rather than trusted.
still_there <- internal_pages[file.exists(file.path(dst, internal_pages))]
index_files <- file.path(dst, c("search.json", "sitemap.xml"))
leaked_index <- c(search.json = FALSE, sitemap.xml = FALSE)
if (file.exists(search_path)) {
  search_index <- jsonlite::fromJSON(search_path, simplifyVector = FALSE)
  search_paths <- vapply(search_index, function(entry) {
    path <- entry$path
    if (is.null(path) || length(path) != 1L || is.na(path)) "" else path
  }, character(1))
  leaked_index[["search.json"]] <- any(vapply(internal_stems, function(stem) {
    any(grepl(paste0("/", stem, ".html$"), search_paths))
  }, logical(1)))
}
if (file.exists(sitemap_path)) {
  sitemap <- paste(readLines(sitemap_path, warn = FALSE, encoding = "UTF-8"),
                   collapse = "\n")
  leaked_index[["sitemap.xml"]] <- any(vapply(internal_stems, function(stem) {
    any(grepl(paste0("/", stem, ".html"), sitemap, fixed = TRUE))
  }, logical(1)))
}
if (length(still_there) || any(leaked_index)) {
  details <- c(still_there, basename(index_files)[leaked_index])
  stop("Internal artifacts survived the public-site cleanup: ",
       paste(details, collapse = ", "))
}

# Fail if Pandoc has interpreted wildcard function names inside the inline SVG
# as Markdown emphasis. An HTML <em> element is a foreign-content integration
# point: it terminates the SVG context and makes the rest of the map flow as
# ordinary page text. This guard checks the rendered artifact, where the defect
# occurs, rather than trusting the valid source SVG.
article <- file.path(dst, "articles", "freqTLS.html")
if (!file.exists(article)) {
  stop("Rendered get-started article is missing: ", article)
}

article_html <- paste(
  readLines(article, warn = FALSE, encoding = "UTF-8"),
  collapse = "\n"
)
map_start <- regexpr(
  '<svg xmlns="http://www.w3.org/2000/svg" viewbox="0 0 1500 880"',
  article_html,
  fixed = TRUE
)
if (map_start[[1]] < 0L) {
  stop("The freqTLS function map SVG was not preserved in the rendered article.")
}

map_tail <- substring(article_html, map_start[[1]])
map_end <- regexpr("</svg>", map_tail, fixed = TRUE)
if (map_end[[1]] < 0L) {
  stop("The freqTLS function map has no closing </svg> tag.")
}
map_html <- substring(map_tail, 1L, map_end[[1]] + nchar("</svg>") - 1L)
map_text_nodes <- lengths(regmatches(map_html, gregexpr("<text", map_html,
                                                        fixed = TRUE)))

if (grepl("<em", map_html, fixed = TRUE) ||
    !grepl("get_*_summary()", map_html, fixed = TRUE) ||
    !grepl("get_*_draws()", map_html, fixed = TRUE) ||
    map_text_nodes < 60L) {
  stop("The rendered function map was corrupted by Markdown/HTML parsing.")
}
