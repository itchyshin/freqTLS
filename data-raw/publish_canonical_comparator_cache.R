# Publish an independently reviewed canonical bayesTLS cache candidate.
#
# This script does not fit models. It copies one exact external candidate into
# inst/extdata only when its supplied SHA-256 matches, every sampler diagnostic
# passed, and its freqTLS/bayesTLS source commits match this clean checkout and
# the pinned supplement.
#
#   env FREQTLS_CANONICAL_CANDIDATE="$HOME/freqtls-cache/76510412/canonical_bayesTLS_cache-candidate.rds" \
#     FREQTLS_REVIEWED_CANDIDATE_SHA256=<reviewed-sha256> \
#     Rscript data-raw/publish_canonical_comparator_cache.R

if (
  identical(Sys.getenv("CI"), "true") ||
    identical(Sys.getenv("GITHUB_ACTIONS"), "true")
) {
  stop("Canonical cache publication is forbidden in CI.", call. = FALSE)
}
if (!requireNamespace("digest", quietly = TRUE)) {
  stop("Publishing requires the maintainer package 'digest'.", call. = FALSE)
}

source(file.path("data-raw", "canonical_comparator_manifest.R"))

candidate <- path.expand(Sys.getenv("FREQTLS_CANONICAL_CANDIDATE"))
reviewed_sha <- tolower(Sys.getenv("FREQTLS_REVIEWED_CANDIDATE_SHA256"))
if (!file.exists(candidate)) {
  stop(
    "FREQTLS_CANONICAL_CANDIDATE must name the reviewed external RDS.",
    call. = FALSE
  )
}
if (!grepl("^[0-9a-f]{64}$", reviewed_sha)) {
  stop(
    "FREQTLS_REVIEWED_CANDIDATE_SHA256 must be a SHA-256 digest.",
    call. = FALSE
  )
}
observed_sha <- digest::digest(file = candidate, algo = "sha256")
if (!identical(observed_sha, reviewed_sha)) {
  stop(
    "Candidate SHA-256 does not match the independently reviewed digest.",
    call. = FALSE
  )
}

git_sha <- system2("git", c("rev-parse", "HEAD"), stdout = TRUE, stderr = FALSE)
changes <- system2(
  "git",
  c("status", "--porcelain", "--untracked-files=all"),
  stdout = TRUE,
  stderr = FALSE
)
if (
  length(git_sha) != 1L ||
    !grepl("^[0-9a-f]{40}$", git_sha) ||
    (length(changes) && any(nzchar(changes)))
) {
  stop(
    "Publish from the exact clean freqTLS candidate-build commit.",
    call. = FALSE
  )
}

cache <- readRDS(candidate)
if (
  !is.list(cache) ||
    !setequal(names(cache), c("meta", "summaries", "diagnostics"))
) {
  stop("Candidate does not have the canonical cache schema.", call. = FALSE)
}
if (
  !identical(cache$meta$bayesTLS_git_sha, CANONICAL_BAYESTLS_SHA) ||
    !identical(cache$meta$freqTLS_git_sha, git_sha)
) {
  stop(
    "Candidate source commits do not match the pinned clean checkouts.",
    call. = FALSE
  )
}
if (
  !isTRUE(cache$meta$diagnostic_all_pass) ||
    length(cache$meta$diagnostic_failures) ||
    !all(cache$diagnostics$all_pass)
) {
  stop(
    "Candidate has failed sampler diagnostics; investigate and rebuild.",
    call. = FALSE
  )
}

expected_cases <- names(canonical_comparator_specs())
if (
  !setequal(names(cache$meta$cases), expected_cases) ||
    !setequal(unique(cache$summaries$case_id), expected_cases) ||
    !setequal(unique(cache$diagnostics$case_id), expected_cases)
) {
  stop(
    "Candidate case coverage does not match the canonical manifest.",
    call. = FALSE
  )
}
for (case_id in expected_cases) {
  if (
    !identical(
      cache$meta$cases[[case_id]]$analysis_hash_sha256,
      unname(CANONICAL_ANALYSIS_HASHES[[case_id]])
    )
  ) {
    stop("Candidate analysis hash mismatch for ", case_id, ".", call. = FALSE)
  }
}

out <- file.path("inst", "extdata", "canonical_bayesTLS_cache.rds")
ok <- file.copy(candidate, out, overwrite = TRUE, copy.mode = TRUE)
if (
  !isTRUE(ok) ||
    !identical(digest::digest(file = out, algo = "sha256"), reviewed_sha)
) {
  stop(
    "Published cache copy failed its post-copy SHA-256 check.",
    call. = FALSE
  )
}
message("Published reviewed canonical cache: ", out)
message("SHA-256: ", reviewed_sha)
