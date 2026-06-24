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

internal_pages <- c("AGENTS.html", "CLAUDE.html", "SPEC.html")
to_remove <- file.path(dst, internal_pages)
existing <- to_remove[file.exists(to_remove)]

if (length(existing)) {
  file.remove(existing)
  message("Removed internal pages from the public site: ",
          paste(basename(existing), collapse = ", "))
} else {
  message("No internal pages found in ", dst, " (nothing to remove).")
}

# Fail loudly if any internal page survived, so the privacy invariant is checked
# on every build rather than trusted.
still_there <- internal_pages[file.exists(file.path(dst, internal_pages))]
if (length(still_there)) {
  stop("Internal pages still present after cleanup: ",
       paste(still_there, collapse = ", "))
}
