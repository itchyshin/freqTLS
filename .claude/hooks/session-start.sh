#!/bin/bash
# SessionStart hook for freqTLS.
#
# Installs the R toolchain and the package's R dependencies so that
# devtools::test(), devtools::document(), and R CMD check work inside
# Claude Code on the web sessions (the ephemeral container ships without R).
# freqTLS compiles a TMB C++ likelihood, so the toolchain must include a C++
# compiler, RcppEigen, and TMB; no Stan / cmdstanr is needed (the bayesTLS
# benchmark reads a cached summary).
#
# Synchronous on purpose: the session waits until dependencies are ready, so
# the agent never tries to run tests before they exist. Switch to async mode
# (echo '{"async": true, "asyncTimeout": 600000}' as the first stdout line) if
# you prefer faster startup and can tolerate a brief not-ready window.
#
# Network policy: dependency installation needs the environment to allow the
# CRAN / Posit Public Package Manager hosts (packagemanager.posit.co and
# cloud.r-project.org). If they are blocked, R still installs and the session
# still starts; the hook prints how to finish dependency setup. Mirrors the
# GitHub Actions R-CMD-check setup (.github/workflows/R-CMD-check.yaml):
# R release + pandoc + the DESCRIPTION dependency tree.

set -euo pipefail

# Only run in the remote (web) environment; local machines already have R.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

export DEBIAN_FRONTEND=noninteractive
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# 1. System toolchain: R + compilers (for TMB), pandoc, and the -dev libraries
#    that ggplot2/systemfonts and the Suggests tree link against.
if ! command -v Rscript >/dev/null 2>&1; then
  # Tolerate failures from unrelated third-party PPAs (e.g. deadsnakes) that may
  # be present in the base image; the core Ubuntu repos carry r-base-dev.
  sudo apt-get update -y || echo "apt-get update reported errors (likely third-party PPAs); continuing"
  sudo apt-get install -y --no-install-recommends \
    r-base-dev pandoc \
    libcurl4-openssl-dev libssl-dev libxml2-dev \
    libfontconfig1-dev libfreetype6-dev libharfbuzz-dev libfribidi-dev \
    libpng-dev libtiff5-dev libjpeg-dev
fi

# 2. Prefer Posit Public Package Manager binaries for the detected Ubuntu
#    release (Matrix/TMB/RcppEigen and the Suggests tree install prebuilt), with
#    cloud CRAN as a source fallback. The HTTPUserAgent makes P3M serve Linux
#    binaries. Persist for every Rscript call this session.
cat > "$HOME/.Rprofile" <<'RP'
local({
  os_release <- tryCatch(readLines("/etc/os-release"), error = function(e) character())
  codename <- sub("^VERSION_CODENAME=", "", grep("^VERSION_CODENAME=", os_release, value = TRUE))
  if (length(codename) != 1L || codename == "") codename <- "noble"
  options(
    repos = c(
      P3M  = sprintf("https://packagemanager.posit.co/cran/__linux__/%s/latest", codename),
      CRAN = "https://cloud.r-project.org"
    ),
    HTTPUserAgent = sprintf(
      "R/%s R (%s)", getRversion(),
      paste(getRversion(), R.version$platform, R.version$arch, R.version$os)
    ),
    Ncpus = max(1L, parallel::detectCores())
  )
})
RP

# 3. Install the package dependency tree (Imports + Suggests) plus check/dev
#    tooling. Best-effort and idempotent: if the package repos are unreachable
#    (network policy), log how to finish and let the session start anyway.
set +e
Rscript -e '
  proj <- Sys.getenv("CLAUDE_PROJECT_DIR", ".")
  if (!requireNamespace("remotes", quietly = TRUE)) install.packages("remotes")
  remotes::install_deps(proj, dependencies = TRUE, upgrade = "never")
  for (p in c("rcmdcheck", "devtools", "roxygen2"))
    if (!requireNamespace(p, quietly = TRUE)) install.packages(p)
'
deps_status=$?
set -e

if [ "$deps_status" -ne 0 ]; then
  echo "freqTLS session-start hook: R ${R_VERSION:-} installed, but dependency download failed."
  echo "This usually means the environment network policy blocks the R package repos."
  echo "Allow packagemanager.posit.co and cloud.r-project.org for this environment,"
  echo "then rerun this hook or run Rscript -e 'remotes::install_deps(dependencies = TRUE)'."
  exit 0
fi

echo "freqTLS session-start hook complete: R toolchain, TMB, and dependencies ready."
