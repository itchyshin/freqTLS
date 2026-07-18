# After Task: Citation sync to the bayesTLS framework paper

## 1. Goal

Bring the freqTLS citation into line with the finalised bayesTLS framework
citation, add a load-time citation reminder, and make the freqTLS headline
citation the paper rather than a separate R-package self-citation.

## 2. Implemented

`inst/CITATION` now leads with the paper freqTLS implements — *A flexible
modelling framework for estimating thermal tolerance and sensitivity* (Noble,
Arnold, Nakagawa & Pottier, 2026, bioRxiv, doi:10.64898/2026.07.16.738378) —
as a `bibtype = "Article"` preprint entry carrying a `textVersion` that matches
the canonical `bayesTLS` citation. Title, author order, year, and DOI were
confirmed against the bioRxiv/Crossref metadata for the DOI. The former
freqTLS R-package `Manual` self-citation was removed; the data-provenance note
that used to live inside the old bayesTLS entry now sits in a `citFooter`.

Shinichi Nakagawa is credited as a co-author of the bayesTLS framework across
`DESCRIPTION` (comment field + `Description` prose), `R/freqTLS-package.R`,
`R/data.R`, the regenerated `man/*.Rd`, `README.Rmd`/`README.md`, `SPEC.md`, and
the `.claude`/`.codex` documentation-agent instructions. The freqTLS *package*
authorship in `DESCRIPTION` `Authors@R` was reordered to place Patrice Pottier
second (Nakagawa, Pottier, Arnold, Noble); this governs package metadata only
and is independent of the paper citation, which stays in the framework's
canonical Noble-led order (author order confirmed with the owner).

A new `R/zzz.R` `.onAttach` prints a startup message pointing to the paper and
`citation("freqTLS")`, mirroring the `bayesTLS` startup banner minus its
Stan/brms lines.

## 3. Mathematical Contract

No likelihood, 4PL parameterisation, profile algorithm, family, diagnostic, or
benchmark protocol changed. This task is documentation, metadata, and a load
hook only.

## 3a. Decisions and Rejected Alternatives

The doc-consistency tripwire in `tests/testthat/test-doc-consistency.R` asserted
the package title appears in `inst/CITATION`. Because the CITATION now cites the
paper, not the package, that title is intentionally absent; the tripwire was
narrowed to `DESCRIPTION` + package doc, with an inline note recording the
policy change rather than gaming the check by re-inserting the title.

Local roxygen2 was upgraded 7.3.2 → 8.0.0 (from source) to match the project's
`Config/roxygen2/version`. An earlier regeneration under 7.3.2 had silently
rewritten unrelated `\link[...]` targets (`cli_warn`→`cli_abort`,
`BIC`→`AIC`); those were discarded and the docs regenerated cleanly under 8.0.0.

## 4. Files Touched

`DESCRIPTION`, `inst/CITATION`, `R/zzz.R` (new), `R/data.R`,
`R/freqTLS-package.R`, `man/freqTLS-package.Rd`, `man/shrimp_lethal.Rd`,
`man/shrimp_sublethal.Rd`, `man/zebrafish_lethal.Rd`, `README.Rmd`, `README.md`,
`SPEC.md`, `NEWS.md`, `tests/testthat/test-doc-consistency.R`,
`.claude/agents/documentation-writer.md`, `.claude/agents/literature-curator.md`,
`.codex/agents/documentation-writer.toml`, `.codex/agents/literature-curator.toml`,
`.agents/skills/prose-style-review/SKILL.md`.

## 5. Verification

`devtools::test()` — 1044 pass, 0 fail, 0 warn, 0 skip (TMB 1.9.20; glmmTMB
reinstalled from source to match). `tools::checkRd()` clean on all edited Rd
files; `inst/CITATION` parses via `readCitationFile()`; `DESCRIPTION`
`Authors@R` parses to four persons; `.onAttach` renders the intended banner.
