# pkgdown page ledger — experimental 0.1.0

Date: 2026-07-16  
Status: rebuilt locally on 2026-07-16; not a deployment claim.

## Source manifest

- Home, authors, changelog, and roadmap are public top-level pages.
- `_pkgdown.yml` declares 13 named articles, organized as Get started, Model
  details, Comparison, Applications, and Case studies.
- The reference index is organized by fit/extract, classical comparator, engine,
  simulation, utilities, data, and package.
- `AGENTS`, `CLAUDE`, and `SPEC` are internal governance inputs. Their `.html`
  and `.md` copies, plus their search-index and sitemap records, must be absent.

## Findings incorporated before final rebuild

| Surface | Finding | Repair / final assertion |
|---|---|---|
| Data group | blanket “credit bayesTLS, CC BY 4.0” was false | component-level licence pointer in `_pkgdown.yml` |
| Snow-gum pages | source and citation wording needed CC BY-NC 4.0 | source repaired; verify rendered data help and leaf-PSII article |
| Function map | planned/internal trace and repair labels blurred API boundary | source SVG and get-started prose repaired; validate SVG closes and contains no `<em>` |
| Internal pages | visible pages were removed but raw `.md`, `search.json`, and `sitemap.xml` leaked | build guard now removes/checks all four surfaces |
| Accessibility | no empty article/reference image alt was found in the prior scan | repeat on exact build; reference-image alt injection remains guarded |

## Exact-build result

- `Rscript tools/build-site.R .` completed. The site has 101 HTML pages: 14
  articles and 81 reference pages.
- The internal-page guard removed all six generated `AGENTS`, `CLAUDE`, and
  `SPEC` HTML/Markdown artifacts and found no remaining search or sitemap URL.
- The local-link scan found zero unresolved local links; the empty-image scan
  found zero empty image sources. Six reference pages received generated figure
  alt text.
- The rendered get-started function-map guard passed: the SVG closes, preserves
  its wildcard accessors, and has no `<em>` element inside the SVG fragment.
- The broad terminology scan found only deliberate comparisons to `bayesTLS`
  posterior/credible intervals and explicit statements that freqTLS intervals
  are not credible intervals. The generic roadmap phrase “not yet implemented”
  was removed.

The remaining reader check is a human visual inspection of the home page,
get-started, model/profile/random-effects/comparison/heat-injury articles,
case-study templates, and reference figure pages from the frozen post-merge
artifact.
