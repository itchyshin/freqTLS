# freqTLS implementation specification

> **For agentic workers:** This is the canonical SPEC + plan (doubles as repo `SPEC.md`). Every implementing agent reads this first. Use superpowers:subagent-driven-development / executing-plans; steps use checkbox (`- [ ]`) syntax. Definition of Done is in §2.

**Current goal (0.2.0.9000):** Maintain a focused, experimental
maximum-likelihood / profile-likelihood R package whose empirical teaching
cases follow the pinned `bayesTLS` supplement (rendered 2026-07-14; commit
`76510412e06c594c96894a1baba1f0e1a34a5aea`) as closely as the frequentist
engine permits. Organisms, datasets, filters, endpoints, formulas, thresholds,
reference times, and estimands match; inference and uncertainty language remain
explicitly frequentist.

Brown shrimp and life-stage zebrafish are benchmark-only legacy fixtures, not
active examples. Canonical cases are oxygen-gradient zebrafish, cereal aphids,
Snow-gum PSII, and both supported *Drosophila suzukii* endpoints. Censored-time
and hurdle-productivity analyses remain bayesTLS-only.

**Architecture:** small purpose-built TMB C++ 4PL likelihood (binomial,
beta-binomial, and beta; direct `CTmax`/`log_z` midpoint reparameterisation) +
column and formula R interfaces + profile-likelihood machinery adapted from
drmTMB's `confint`/`tmbprofile` patterns + a pinned canonical bayesTLS
comparator cache + live freqTLS refits + Confidence-Eye visuals
+ pkgdown site, all under an agent-kit-bootstrapped team with `docs/dev-log/`
memory.

**Tech Stack:** R (>= 4.2), TMB (LinkingTo RcppEigen, TMB), rlang
(tidy-eval), stats/utils, ggplot2 + tibble, cli; testthat ed.3; roxygen2;
pkgdown; GitHub Actions on Ubuntu R release/devel, Windows R release, and macOS
R release (`pull_request` + `workflow_dispatch`).

---

## Context — why this package

The bayesTLS paper (Noble, Arnold & Pottier, in prep) presents a single-stage
Bayesian 4PL for thermal death time / thermal load sensitivity (TDT/TLS) and
notes the same model class *could* be fit by likelihood (they suggest
bootstrap/Delta, not profile likelihood). `bayesTLS` is a complete Bayesian
`brms`/Stan package. `freqTLS` is the **likelihood/profile-likelihood
complement**: the matched configuration uses the same likelihood and fitted
curve, fit by ML via TMB, with `CTmax` and `z` as direct parameters so supported
targets can be profiled. The current experimental 0.2.0.9000 surface also provides
Wald/bootstrap routes, diagnostics, formula and column interfaces, limited
random intercepts, prediction, and the tested beta family. **drmTMB** (local,
GPL-3) supplied engineering and governance patterns; package-specific
adaptations are recorded in `inst/COPYRIGHTS`.

---

# PART I — TEAM, MEMORY & GOVERNANCE

## 1. Team — named perspectives (mirrored from drmTMB)

Bootstrap the same standing-review team drmTMB uses. Each name = a launchable agent in `.claude/agents/<file>.md` (+ a `.codex/agents/<name>.toml` mirror). "Perspective, not a daemon": invoked by name when its expertise is needed; **Ada** decides next steps and owns one-story coherence.

| Name | Perspective | freqTLS specialty | Model | drmTMB source file |
|---|---|---|---|---|
| **Ada** | Orchestrator / integrator | next-step decisions; code/eqs/docs/tests/roadmap tell one story | opus | `integration-reviewer.md` |
| **Gauss** | TMB likelihood & numerics | 4PL NLL correctness, transforms, AD stability, sdreport | opus | `tmb-engineer.md` |
| **Noether** | Math consistency | equations ↔ R syntax ↔ C++ coherence (direct CTmax/z) | opus | `math-consistency-reviewer.md` |
| **Fisher** | Statistical inference | profile likelihood, equivariance, identifiability, comparators | opus | `inference-reviewer.md` |
| **Emmy** | R-package architecture | S3 `profile_tls` object, methods, extractors, module coherence | opus | `architecture-reviewer.md` |
| **Boole** | R API & formula | `fit_tls()` tidy-eval surface, argument naming, stability | opus | `formula-reviewer.md` |
| **Curie** | Simulation & testing | `simulate_tls`, recovery tests, edge/malformed inputs, speed | sonnet | `simulation-tester.md` |
| **Florence** | Scientific figure editor | **Confidence-Eye gate** (§13), publication plots, honest uncertainty | sonnet | `figure-reviewer.md` |
| **Darwin** | Ecology/evolution audience | real thermal-biology questions, plausible examples, interpretation | sonnet | `audience-reviewer.md` |
| **Pat** | Applied PhD-student user-tester | tutorial clarity, error recovery, no hidden jargon | sonnet | `user-tester.md` |
| **Jason** | Landscape / source-map scout | bayesTLS/drmTMB comparators, papers, architecture lessons | opus | `landscape-scout.md` |
| **Grace** | CI / pkgdown / CRAN / reproducibility | platform checks, dep risk, compiled-code safety, site | opus | `reproducibility-engineer.md` |
| **Rose** | Systems auditor | stale wording, repeated mistakes, blind spots, **after-task audit** | opus | `systems-auditor.md` |

Plus job-function agents to copy: `reviewer`, `documentation-writer`, `pkgdown-editor`, `literature-curator`.

**Phase ownership** (see §16): P0 Ada+Grace+Rose · P1 Gauss+Noether(+Emmy) · P2 Emmy+Boole+Curie · P3 Fisher+Gauss+Pat · P4 Florence+Darwin · P5 Curie+Jason+Rose · P6 documentation-writer+pkgdown-editor+Pat+Darwin+literature-curator+Grace. **Adversarial DoD gate before "core done": Rose + Pat + Fisher.**

## 2. Agent-kit bootstrap & governance

drmTMB ships a reusable kit at `docs/agent-kit/` (`README.md`, `team-roles.md`, `bootstrap-checklist.md`, `project-memory-policy.md`, `templates/{AGENTS.md,CLAUDE.md,.agents/skills/*}`). **Phase 0 copies this kit and adapts it for freqTLS** rather than reinventing.

Stand up:
- **`.claude/agents/`** (13 named + 4 job-function `.md`) and **`.codex/agents/`** (`.toml` mirrors, 1-to-1) — adapt each agent body's context to freqTLS scope (4PL, direct CTmax/z, profile CIs, benchmark-vs-bayesTLS).
- **`AGENTS.md`** — sections mirroring drmTMB: Core Scope (single-stage 4PL TLS; binomial and beta-binomial counts plus beta continuous proportions; direct CTmax/z; experimental-v0.2 boundaries); Design Rules (every family needs simulation tests; every exported fn needs roxygen; parameterisation changes update `docs/design/01-…`; likelihood changes update `docs/design/03-…`; every change updates `check-log.md`; completed tasks write after-task reports; ported drmTMB code documents provenance in `inst/COPYRIGHTS`); Standard Commands; Recovery Checkpoints; **Definition of Done**; Writing Style; Multi-Agent Collaboration (name→agent map); Standing Review Roles; Team-Improvement loop; pkgdown policy.
- **`CLAUDE.md`** — points to `AGENTS.md` as source of truth; sets freqTLS-specific invariants (stable names `CTmax`,`z`,`log_z`,`low`,`up`,`k`,`phi`; relative threshold default; "confidence" language, never "posterior"; sibling boundary vs bayesTLS & drmTMB).
- **`.agents/skills/`** — adapt drmTMB skills: `tmb-likelihood-review` (Gauss), `figure-visual-audit` (Florence; Confidence Eye), `add-simulation-test`/`simulation-test-plan` (Curie), `after-task-audit` (Rose; with freqTLS `rg` patterns: `CTmax|log_z|tref|relative|absolute|beta_binomial`), `prose-style-review`, `release-readiness-review`. **New:** `profile-ci-review` (Fisher — equivariance `ci_z==exp(ci_log_z)`, χ² cutoff, open/boundary/multimodal handling) and `benchmark-vs-bayesTLS-audit` (Jason/Rose — fair config, cache provenance, R-SHRIMP).
- **`.claude/hooks/session-start.sh`** — adapt drmTMB's idempotent R/TMB toolchain setup; `.claude/settings.json` (SessionStart hook).

**Definition of Done (verbatim from drmTMB):** *"A feature is done only when implementation, tests, documentation, examples, check logs, after-task notes, and review are all present."*

## 3. Memory management & dev-log discipline

Mirror `docs/dev-log/` exactly (the durable, repo-authoritative memory — "trust repo state, not chat"):

```
docs/dev-log/
  check-log.md            # master log; per dated entry: Goal / Changes / Checks run / Interpretation (+GitHub issue maintenance)
  after-task/             # YYYY-MM-DD-<task>.md — 10-section closure report (see template below)
  after-phase/            # phase closure incl. the symbolic mathematical contract + consistency audit
  recovery-checkpoints/   # git state + recent check-log/after-task + exact recovery commands (interrupt handoff)
  decisions.md            # dated design decisions + rationale (append-only)
  known-limitations.md    # AUTHORITATIVE fitted / planned / unsupported boundary, indexed by model class
  dashboard/              # mission-control: index.html + status.json + sweep.json + version.txt + README (served on a free port, e.g. 8767)
  benchmarks/ figure-audits/ simulation-artifacts/ audits/ agent-notes/ release-checklists/ comparator-results/
```

- **after-task template** (`docs/design/10-after-task-protocol.md` governs): `# After Task: <title>` · Date · Task · Created/Changed · Checks Performed (exact commands + counts) · Outcomes · Consistency Review · Tests Of The Tests · What Did Not Go Smoothly · Team Learning · Known Limitations · Next Best Task.
- **recovery-checkpoint template**: goal, suggested next step, git status/diff-stat/HEAD, newest check-log entries, newest after-task refs, exact recovery commands, "do not treat as approval for broad changes."
- **check-log entries** use exact command text (not summaries) and interpret into next steps.
- **dashboard** = static HTML polling `status.json` (per-slice status enum: queued/active/blocked/verified/banked/deferred) + a `tools/start-mission-control.sh`. Pick a free port (drmTMB 8765, hsquared 8766 → use **8767**).
- A `tools/checkpoint.R` helper (adapt drmTMB `codex-checkpoint.R`) writes recovery checkpoints for long runs.

## 4. Project docs (vision / roadmap / status) + sync protocol

- **`docs/design/00-vision.md`** — freqTLS identity: *the fast, prior-free, profile-likelihood complement to bayesTLS*. Core idea: direct CTmax/z parameterisation → directly profile-able headline quantities + honest identifiability diagnostics. Signature features: profile-likelihood confidence intervals (Confidence Eyes) for CTmax & z, and the 12-warning identifiability story. Audience: thermal-biology ecologists. Sibling boundary: bayesTLS (Bayesian, broad workflow, heat-injury) and drmTMB (general distributional regression).
- **`ROADMAP.md`** — phases 0–N with status (initial/implemented/planned), version status line, release boundary, links to the capability matrix. Experimental `0.2.0.9000` retains binomial and beta-binomial counts, beta continuous proportions, shared shape by default, grouped CTmax/z, profile/Wald/bootstrap CIs, and the canonical benchmark.
- **`README.Rmd`** — "Start here" links · **Credit / origins** (TLS framework is bayesTLS's; Noble/Arnold/Pottier are co-authors) · preview status (intentionally bounded) · install · quick example · model equation · experimental lifecycle badge · data credits.
- **`NEWS.md`** — version history.
- **Design docs** (`docs/design/`, numbered like drmTMB): `00-vision`, `01-model-and-parameterisation` (4PL + direct CTmax/z + equivalence to bayesTLS), `02-family-registry` (binomial, beta-binomial, and the tested Beta family), `03-likelihoods` (symbolic + C++ notes), `04-profile-likelihood` (algorithm/targets/transforms/diagnostics), `05-testing-strategy`, `06-benchmark-protocol` (canonical parity, cache, diagnostics, legacy boundary), `07-collaboration-and-site`, `10-after-task-protocol`, `46-capability-matrix` (fitted-vs-planned = the missing-cell audit), `90-bayesTLS-critique` (the §5 balanced critique, cited, as a durable record).
- **Consistency rule (one work ledger):** whenever capability is added/removed, update in the SAME commit — `README` + `ROADMAP` + `NEWS` + `docs/dev-log/known-limitations.md` + the relevant design doc; write an after-task report whose Consistency Review runs `rg` stale-wording scans; check PR overlap before editing shared files (`check-log.md`, `known-limitations.md`). GitHub Issues ↔ after-task ↔ ROADMAP kept in sync.

---

# PART II — SCIENTIFIC & TECHNICAL DESIGN

## 5. Balanced critical assessment of bayesTLS (drives design)

Directive: *"Dan's team checked a lot — critical but balanced, don't just accept everything."* Citations are bayesTLS `file:line` @HEAD (2026-06-16). Full record → `docs/design/90-bayesTLS-critique.md`.

**Strengths:** asymptote ordering provably enforced (`utils.R:119-141`); shared-draw z/CTmax/T_crit preserves joint correlation (`extract_tdt.R:593-612`); z read directly from `mid` slope `-1/b_mid_temp_c` (`extract_tdt.R:89-90`); honest relative-vs-absolute handling + `NA` propagation (`extract_tdt.R:75-77`); T_crit guarded behind `lethal=TRUE`; real sampler diagnostics (`diagnostics.R:38-110`); two-stage path has `<3`-unique gating (`two_stage.R`).

**Concerns (classified, cited):**
- **[REAL — verified data bug] Shrimp shipped counts corrupted.** CSV `Mortality_after_trial` is a **proportion** (`0.0909=1/11`, `0.5=5/10`); `make_datasets.R:25` mislabels it "death count" and `:34` does `as.integer(...)`, flooring proportions `<1` to `0`. Shipped `shrimp_lethal` deaths collapse to ~all-zero. **Action:** rebuild from CSV `deaths=round(prop*N)`; document; friendly upstream report; verify `.rda` before finalising.
- **[REAL] No identifiability/data-adequacy guard on the Bayesian path** (none in `fit_4pl.R`/`standardize_data.R`/`priors.R`; guards live only in the classical `two_stage.R`). With weak data the priors silently identify. **freqTLS's clearest value-add** → 12 explicit warnings (§10).
- **[REAL on sparse data] Default priors weakly-but-genuinely informative** (`mid` slope `normal(0,0.6)`; asymptote/phi priors `priors.R:55-82`), no sensitivity tooling. freqTLS's prior-free CIs are an implicit sensitivity check — expect divergence on sparse data (not a "bug").
- **[RESOLVED — adopted] Disjoint asymptote bounds force `low<midpoint<up`** (`utils.R:128-131`) — freqTLS originally diverged (nested gap) but P1 **adopted** these disjoint bounds (§7), so the asymptote contract is shared with bayesTLS.
- **[MINOR]** all-four `temp_effects` headline relative-z ignores shape temp-effects (correct but under-signposted; irrelevant to v0.1 constant-shape); finite-diff local-z `h=1e-3` undocumented but fine; CTmax extrapolation unflagged; T_crit rate range `c(0.1,1)` taxon-general but prose-flagged.

**Net:** competently built; only the shrimp fix and the identifiability gap (our differentiator) change our design — freqTLS otherwise mirrors bayesTLS, including adopting its disjoint-bounds asymptotes. None threaten the matched freqTLS-versus-bayesTLS comparison in the constant-shape, relative-threshold configuration; the classical two-stage result remains a separately labelled absolute-LT50 approximation.

## 6. Locked model + equivalence (verified from bayesTLS source)

4PL, `logd = log10(duration)`: `p = low + (up-low)/(1 + exp(k*(logd - mid)))`, `k = exp(logk)`.
bayesTLS constant-shape (`temp_effects="mid"`): `mid(T)=b_mid_Intercept + b_mid_temp_c*(T-Tbar)`; `z=-1/b_mid_temp_c`; `CTmax(tref)=Tbar+(log10(tref)-b_mid_Intercept)/b_mid_temp_c` (`fit_4pl.R:88-94`, `extract_tdt.R:89-90,144-146`).

**freqTLS direct reparam:** `z_i=exp(eta_logz_i)`, `CT_i=X_CT_i·beta_CT`, `mid_i=log10(tref)-(T_i-CT_i)/z_i`.
**Equivalence:** expand → `β1=-1/z`, `β0=log10(tref)+(CT-Tbar)/z` ⇒ `z=-1/β1`, `CT=Tbar+(log10(tref)-β0)/β1` (exactly bayesTLS). Same `(low,up,k)`; smooth invertible reparam (Jacobian nonsingular while z finite) ⇒ **same likelihood/curve/MLE**, but CTmax,z are coordinates → directly profile-able. Profile likelihood is equivariant under monotone reparam ⇒ z-profile = `exp()` of log_z-profile.

## 7. Key design decisions

| Decision | Choice | Rationale |
|---|---|---|
| **License** | **GPL-3** for code; component-specific data terms | Redistributed data retain source licences. Snow-gum is CC BY-NC 4.0 in the current development branch. A maintainer attestation permits non-commercial GitHub/pkgdown teaching use, but unrestricted/commercial downstream redistribution and CRAN remain blocked until a rights-holder grant is archived. |
| **Authorship** | Shinichi Nakagawa (`aut`,`cre`) **+ Daniel W. A. Noble, Pieter A. Arnold, Patrice Pottier (`aut`)** | TLS framework is bayesTLS's, not ours alone. Confirm with them before release (a person should agree to being listed). |
| **Midpoint param** | Direct `CTmax` + `log_z` | makes headline quantities profile-able (§6). |
| **Asymptote reparam** | **Disjoint bounds** (bayesTLS `compute_4pl_bounds`) `low=low_min+low_w·plogis(beta_low)`, `up=up_min+up_w·plogis(beta_up)` | split `[lower,upper]` at the midpoint so `low<up` unconstrained; shares the bayesTLS contract; `up` is a direct coordinate. (P1 reversed the earlier nested gap.) Cost: `up` profile not yet wired → Wald/delta (§10). |
| **Families in experimental v0.2** | binomial, beta-binomial(`phi`), beta(`phi`) | counts plus continuous proportions in `(0, 1)`. |
| **Temp effect** | midpoint-only by default; optional independent fixed designs on `low/up/log_k` | the default matches bayesTLS constant-shape for a fair benchmark. |
| **Predictors / groups** | column + `tls_bf()` formula interfaces; fixed effects on direct coordinates; one independent random intercept on `CTmax`, `log_z`, `low`, or `log_k` | grouped headline parameters remain direct/profile-able; unsupported targets route honestly to Wald/bootstrap. |
| **`y`,`n` in TMB** | `DATA_VECTOR` (Type) not IVECTOR | beta-binomial needs `lgamma(y+a)`, `a` a `Type`. |
| **Uncertainty visuals** | **Confidence Eye, NOT posterior densities** (§13) | freqTLS yields *confidence* intervals; posterior visuals would mislead. Distinct identity vs bayesTLS; teaching contrast in the comparison vignette. Florence-owned gate. |
| **Time unit** | data's native unit (hours); `tref` in same unit (CTmax@1h); pin matching `t_ref`/`time_multiplier` when calling bayesTLS | avoids unit mismatch (R-UNITS). |

**Non-goals for experimental v0.2:** time-to-event and multi-trait responses; fitted
heat-injury/repair dynamics; an absolute-threshold default; correlated,
random-slope, crossed, nested, or `up` random effects; universal profiles for
`up`, variance components, or continuous shape slopes; Bayesian/posterior
inference.

## 8. Package structure & file-by-file map (reuse → drmTMB GPL-3 paths)

```
freqTLS/
  DESCRIPTION NAMESPACE README.Rmd NEWS.md LICENSE ROADMAP.md _pkgdown.yml SPEC.md AGENTS.md CLAUDE.md inst/COPYRIGHTS
  R/ src/ inst/{extdata,CITATION} data/ data-raw/ tests/testthat/ vignettes/ man/ tools/
  .claude/{agents,hooks,settings.json} .codex/agents .agents/skills
  docs/{design,dev-log,agent-kit}  .github/workflows/{R-CMD-check.yaml,pkgdown.yaml}
```

| File | Responsibility | Pattern from (drmTMB) |
|---|---|---|
| `src/profile_tls.cpp` | 4PL NLL, direct CTmax/log_z mid, disjoint-bounds asymptotes, REPORT/ADREPORT | `src/drmTMB.cpp:1-14,1319-1328,1302-1314` |
| `src/profile_tls_numeric.h` | stable `inv_logit`/`log1p_exp` (`.h`, `#ifndef`) | `src/drm_numeric.h:13-44` |
| `src/init.c` | DLL registration | `src/init.c:1-17` |
| `R/freqTLS-package.R` | `@useDynLib freqTLS,.registration=TRUE`, importFrom | `R/drmTMB-package.R` |
| `R/families.R` | `binomial_tls()`,`beta_binomial_tls()`→family_code | `R/family.R:263-274` |
| `R/model_matrix.R` | `X_CT`,`X_logz` via `model.matrix(~0+group)` | `stats::model.matrix` |
| `R/fit_engine.R` | MakeADFun→nlminb→optim fallback→sdreport; conv+pdHess | `R/drmTMB.R:350-440` |
| `R/fit_tls.R` | public `fit_tls()` tidy-eval; starts; S3 object | `R/drmTMB.R:340-399` |
| `R/methods.R` | print/summary/coef/vcov/logLik/AIC/nobs | `R/methods.R:2-40,1826-1864,2025-2037` |
| `R/profile.R` | `profile.profile_tls`; tmbprofile/endpoint; profile-t cutoff; transforms; open/boundary/multimodal | `R/profile.R:390-525,2300-2373,2996-3009` |
| `R/confint.R` | `confint.profile_tls(method=c("profile","wald"))` | `R/profile.R:116-275,1468-1535` |
| `R/diagnostics.R` | the 12 identifiability warnings (§10) | new |
| `R/predict.R` | `predict.profile_tls(survival/link/midpoint)`, surface, `derive_lt` | drmTMB `R/predict-parameters.R` |
| `R/simulate.R` | `simulate_tls()`/`simulate.profile_tls` | `stats::simulate` |
| `R/plotting.R` | survival curves, tdt curve, surface, **Confidence-Eye** profile/interval plots (§13) | **gllvmTMB `R/plot-loadings-confidence-eye.R` + `R/loading-uncertainty-helpers.R` (`.eye_polygon_df`)**; drmTMB `R/plot-corpairs.R`, `R/profile.R:495-525` |
| `R/extract.R` | `tidy_parameters`,`get_ctmax`,`get_z`,`get_shape` | broom-style, new |
| `R/utils.R` | name-mapping, transforms, clamps, `%||%` | `R/profile.R:775-785` |
| `R/data.R` | docs and source-specific attribution for all seven shipped development datasets, including the R-SHRIMP and Snow-gum rights boundaries | drmTMB data docs |
| installed raw CSVs + `standardize_data(mortality = ...)` | reconstruct shrimp counts from the vendored proportion at fit time (R-SHRIMP) | — |
| `data-raw/build_benchmark_cache.R` | maintainer-run: fit bayesTLS + two-stage → version-stamped cache | — |

**DESCRIPTION — `Authors@R`** (synchronized current-development contract):
```r
Authors@R: c(
  person("Shinichi", "Nakagawa", email = "itchyshin@gmail.com",
         role = c("aut", "cre", "cph"),
         comment = c(ORCID = "0000-0002-7765-5182")),
  person("Pieter A.", "Arnold", role = "aut",
         comment = c(ORCID = "0000-0002-6158-7752",
                     "co-author of the bayesTLS framework")),
  person("Patrice", "Pottier", role = "aut",
         comment = c(ORCID = "0000-0003-2106-6597",
                     "co-author of the bayesTLS framework")),
  person("Daniel W. A.", "Noble", role = "aut",
         comment = c(ORCID = "0000-0001-9460-8743",
                     "senior author of the bayesTLS thermal-load-sensitivity framework")))
```
`Description:` states plainly that freqTLS implements the TLS framework **introduced by Noble, Arnold & Pottier (bayesTLS)**; freqTLS contributes the TMB ML likelihood, direct CTmax/z reparameterisation, and profile-likelihood CIs. Current fields: `Imports: cli, ggplot2, MASS, parallel, rlang, stats, tibble, TMB, utils`; `LinkingTo: RcppEigen, TMB`; `Suggests: glmmTMB, knitr, rmarkdown, testthat (>= 3.0.0)`; `Config/testthat/edition: 3`; `LazyData: true`. No Makevars are needed.

## 9. TMB engine core (load-bearing)

```cpp
DATA_VECTOR(y); DATA_VECTOR(n); DATA_VECTOR(log_time); DATA_VECTOR(temp);
DATA_MATRIX(X_CT); DATA_MATRIX(X_logz); DATA_INTEGER(family_code); DATA_SCALAR(log10_tref);
DATA_SCALAR(low_min); DATA_SCALAR(low_w); DATA_SCALAR(up_min); DATA_SCALAR(up_w);   // disjoint bounds
PARAMETER(beta_low); PARAMETER(beta_up); PARAMETER(beta_logk);
PARAMETER_VECTOR(beta_CT); PARAMETER_VECTOR(beta_logz); PARAMETER(log_phi);
Type eps=1e-12, low=low_min+low_w*invlogit(beta_low), up=up_min+up_w*invlogit(beta_up),
     k=exp(beta_logk), phi=exp(log_phi);
vector<Type> CT=X_CT*beta_CT, logz=X_logz*beta_logz; Type nll=0;
for(int i=0;i<y.size();++i){
  Type z_i=exp(logz(i)), mid=log10_tref-(temp(i)-CT(i))/z_i, eta=k*(log_time(i)-mid);
  Type p=low+(up-low)*invlogit(-eta);
  p=CppAD::CondExpLt(p,eps,eps,CppAD::CondExpGt(p,Type(1)-eps,Type(1)-eps,p));
  if(family_code==0) nll-=dbinom(y(i),n(i),p,true);
  else { Type a=p*phi,b=(Type(1)-p)*phi,yf=n(i)-y(i);
    nll-=lgamma(n(i)+1)-lgamma(y(i)+1)-lgamma(yf+1)+lgamma(phi)-lgamma(n(i)+phi)
        +lgamma(y(i)+a)-lgamma(a)+lgamma(yf+b)-lgamma(b); } }
vector<Type> z_group=exp(beta_logz);
REPORT(low);REPORT(up);REPORT(k);REPORT(phi);REPORT(beta_CT);REPORT(z_group);
ADREPORT(low);ADREPORT(up);ADREPORT(k);ADREPORT(beta_CT);ADREPORT(beta_logz);ADREPORT(z_group);
if(family_code==1) ADREPORT(phi); return nll;
```
Stability: `invlogit(-eta)`; nested `CondExp` clamp; optional shape floor on `a,b`; log-scale `k,phi,z`. Include drmTMB's Boolean.h pre-include guard; `.h` headers.

`fit_tls(data, y, n, time, temp, group=NULL, family=c("beta_binomial","binomial"), tref=1, start=NULL, control=list(), trace=FALSE)` — tidy-eval columns; starts `beta_low=qlogis((0.05−low_min)/low_w)`, `beta_up=qlogis((0.95−up_min)/up_w)`, `beta_logk=log(5)`, `beta_CT=median(temp)/group`, `beta_logz=log(3)`, `log_phi=log(100)`; map fixes `log_phi=factor(NA)` for binomial; S3 `class=c("profile_tls","tls_fit")` with call/family/tref/group_levels/data_summary/par/estimates/vcov/logLik/df/AIC/convergence{code,pdHess,message}/name_map/obj/opt/sdreport.

## 10. Profile-likelihood strategy + diagnostics

Per scalar target ψ: fit MLE `θ̂,ℓ̂`; fix ψ's unconstrained coordinate, re-optimise others; `D=2(ℓ̂-ℓ_p)`; CI = `{ψ: D ≤ qt(1−α/2, df)²}` (Bates–Watts profile-t, df = n−p; → χ²₁ as df→∞) via `uniroot` each side; transform endpoints to natural scale.

| Target | Profile on | Transform |
|---|---|---|
| `z`,`z:grp` | `eta_logz[g]` | `exp` |
| `CTmax`,`CTmax:grp` | `beta_CT[g]` | identity |
| `low` | `beta_low` | `plogis` |
| `k` | `beta_logk` | `exp` |
| `phi` | `log_phi` | `exp` |
| `up` | re-root `(up,low-frac)` native | identity (else Wald/delta) |
| contrasts `ΔCTmax`,`Δlog_z` | reference+contrast recoding | identity (ratio z=`exp(Δlog_z)`) |

**12 warnings (the bayesTLS gap-filler; emit, never silent):** 1 <3 temps; 2 <3 durations (overall+per-temp); 3 no mortality; 4 all mortality; 5 threshold never crossed; 6 asymptote not approached; 7 CTmax extrapolated; 8 phi→binomial limit; 9 profile not closing (open CI + "weakly identified — consider bayesTLS/bootstrap"); 10 MLE on boundary ("interval calibration unreliable"); 11 non-monotone/multimodal profile; 12 inner non-convergence (NA).

**Ship stance:** *profile gives fast, prior-free, asymmetry-respecting CIs when
the MLE is interior and the data identify ψ; for boundary asymptotes, very sparse
designs, overdispersion at zero, or weakly identified random-effects fits,
prefer bayesTLS or bootstrap — and freqTLS warns you when you're in that
regime.* Never claim profile universally superior.

## 11. Simulation & tests (testthat ed.3; fast; truth as attribute)

`simulate_tls(temps,times,reps,n,low,up,k,CTmax,z,phi=NULL,family,group=NULL,tref=1,seed)` — factorial grid; locked DGP; `rbinom` / beta-binomial via `rbeta(a=p*phi,b=(1-p)*phi)`→`rbinom`; grouped per-group CTmax/z with shared shape; base data.frame + `attr(,"truth")`. Document the `phi` convention (R-PHI).

| Test | Asserts (tolerances) |
|---|---|
| `test-parameter-transforms` | `p∈(0,1)`; link round-trips 1e-8; `low<up`; `mid=log10(tref)` at `temp=CTmax`; `dmid/dT=-1/z` |
| `test-fit-binomial` | CTmax 0.4°C, z 0.6, low/up 0.05, k 30% rel; converged |
| `test-fit-beta-binomial` | recover (wider); `logLik(bb)>logLik(binom)` & `AIC(bb)<AIC(binom)` overdispersed; near-binomial on clean |
| `test-profile` | `|D(MLE)|<1e-4`; finite closed CI; **`ci_z==exp(ci_log_z)` 1e-6**; asymmetry allowed; sparse ⇒ `expect_warning("did not close")`+NA, no crash |
| `test-predict` | survival ↓ duration & ↓ temp; `newdata` works; ∈(0,1) |
| `test-group` | ΔCTmax 0.6, Δz 0.8; `CTmax:grp`,`z:grp` finite profiles |
| `test-benchmark-sanity` | cache vs live freqTLS within loose tol (CTmax~1°C, z~25%); no Stan |

## 12. bayesTLS canonical comparator harness

The active comparison covers oxygen-gradient zebrafish, cereal aphids at age
six and across ages, Snow-gum PSII, and the mortality and awake/coma
*Drosophila suzukii* endpoints. The manifest locks exact bytes, filters,
responses, families, formulas, grouping, `t_ref`, thresholds, and estimands.

- **Comparator construction:** the maintainer-only builder loads clean freqTLS
  and bayesTLS source trees, requires pinned bayesTLS commit `76510412`, runs on
  Totoro with bounded parallelism and `OPENBLAS_NUM_THREADS=1`, and keeps raw
  posterior fits outside the repository.
- **Publication gate:** an independent invocation publishes only the reviewed
  candidate SHA-256 when all R-hat, ESS, divergence, tree-depth, and BFMI gates
  pass. The installed cache contains curated summaries and provenance, never raw
  posterior draws.
- **Interpretation:** `vignettes/comparing-to-bayesTLS.Rmd` refits freqTLS live,
  reports actual ML-minus-posterior-median differences, and labels confidence
  and credible intervals separately. Snow-gum is the locked shared-shape
  analogue. Drosophila mortality compares only the absolute 240-minute LT50
  point; relative direct `z` is not subtracted from absolute Bayesian `z`.
- **Legacy boundary:** shrimp and life-stage zebrafish remain installed only as
  unpublished compatibility fixtures. Their historical caches and R-SHRIMP
  repair tests remain internal and cannot appear in current teaching,
  navigation, search, or comparison tables.

## 13. Visual identity — the Confidence Eye (Florence-owned) + docs/pkgdown/CI

**Confidence Eye is freqTLS's default uncertainty display, replacing posterior-density visuals** (the contract forbids implying a posterior; freqTLS intervals are likelihood confidence intervals):
- Elements: pale low-alpha confidence region + darker interval outline + emphasized centre mark + **hollow point-estimate circle** (white interior, dark stroke).
- Prohibited by default (explicit variants only): filled points, horizontal CI bars, centre lines through the eye, row guide-lines through the eye.
- **Language: "confidence", never "posterior"/"credible."** Captions expose interval source (profile/Wald) + transformation scale. Render-proof: fresh PNG filename, inspect the exact rendered image.
- Used for: CTmax & z interval displays, group comparisons, `plot.profile_tls_profile`, and the homepage profile plot. `style=c("eye","line")` switch (default `"eye"`); carry a `conf.status` marker.
- **Reuse source (gllvmTMB, GPL-3 → attribute in `inst/COPYRIGHTS`):** adapt `plot_loadings_confidence_eye()` and the lens-geometry helper `.eye_polygon_df(width_max=0.70)` from `gllvmTMB/R/loading-uncertainty-helpers.R`. Realization: pale lens `geom_polygon(alpha≈0.35, colour=NA)` + hollow estimate `geom_point(shape=21, fill="white", stroke=0.9)` + optional negligible-band `geom_rect` + `geom_hline(0)`; reliability palette (pinned `grey50` / CI-overlaps-null `#d6604d` / CI-excludes-null `#1b7837` / estimated `#377eb8`).
- **Honest fallback (ties R-PROFILE):** gllvmTMB's eye refuses to draw a lens when no finite `(lower,upper)` exists ("CIs unavailable — hollow points only"). freqTLS reuses this: a **non-closing profile** renders a hollow point with no lens, never a fabricated interval shape.
- **Comparison vignette teaching device:** bayesTLS posterior *density* beside freqTLS Confidence *Eye* for the same CTmax/z — visualises Bayesian-vs-likelihood.
- **Florence** runs the `figure-visual-audit` gate before any figure is "done."

**Docs:** README (§4); vignettes `getting-started`, `model-math` (4PL + direct
CTmax/z + relative-vs-absolute + bridge identities), `profile-likelihood` (LR
profiles, asymmetry, profile vs Wald, non-closing), `comparing-to-bayesTLS`
(canonical paired cache plus live ML refits). **_pkgdown.yml** Bootstrap5/flatly, grouped navbar +
reference sections; homepage = tagline + equation + quick-start + one survival
plot + one Confidence-Eye profile plot + comparison table + experimental badge.
**CI:** `R-CMD-check.yaml` on main pushes, pull requests, and manual dispatch covers Ubuntu R
release/devel, Windows R release, and macOS R release with normal Suggests and
no Stan; `pkgdown.yaml` deploys after checks; benchmark articles build from the
cache.

## 14. Risk register + missing-cell audit

**Missing-cell audit (`docs/design/46-capability-matrix.md`):** experimental
`0.2.0.9000` includes binomial, beta-binomial, and beta families; ungrouped,
grouped, formula, supported shape-design, and limited random-intercept paths;
and Wald, target-supported profile, and parametric-bootstrap intervals. The
matrix records target-specific fallbacks and unsupported cells rather than
calling the whole product universally profile-able.

| ID | Risk | Mitigation |
|---|---|---|
| R-SHRIMP | shrimp counts truncated upstream | rebuild from CSV `round(prop*N)`; assert distribution; document; report upstream; verify `.rda` |
| R-STALE | cached bayesTLS numbers drift | version-stamp cache; print provenance; `test-benchmark-sanity` tripwire; one-command regen |
| R-IDENT | sparse-mortality non-identifiability | shared-shape design; 12 warnings (§10); beta-binomial only when AIC says so |
| R-RELABS | relative vs absolute threshold conflated | lock the two model fits to relative; label the classical two-stage absolute-LT50 approximation and its near-0/near-1 condition |
| R-UNITS | hours/tref mismatch | fix native unit; pin matching `t_ref`/`time_multiplier`; surface in `print` |
| R-EXTRAP | CTmax extrapolation | default `tref` inside duration span; warn+shade; show data ranges |
| R-PHI | phi convention conflated | one documented definition; direction tests |
| R-LICENSE | source-specific data licence or attribution missing | component ledger + `R/data.R`/CITATION/README attribution; exclude components without compatible redistribution authority; code GPL-3; provenance in `inst/COPYRIGHTS` |
| R-PROFILE | non-closing profile silent/crash | warn + NA open side + `conf.status`; tests enforce; honest eye plot |
| R-POSTERIOR | a figure implies a posterior | Confidence-Eye contract + Florence gate forbid posterior language/visuals |

---

# PART III — EXECUTION

## 15. Build sequence (phased, gated)

**Phase 0 — Bootstrap team + memory + docs + scaffold.** Copy & adapt drmTMB `docs/agent-kit/` → AGENTS.md, CLAUDE.md, `.claude/agents/` (+`.codex/agents/`), `.agents/skills/`, hooks; create `docs/dev-log/` tree + dashboard + `tools/checkpoint.R`; `docs/design/{00-vision,01,…,10,46,90}`; ROADMAP.md, NEWS.md, README.Rmd; DESCRIPTION (4 authors), NAMESPACE, `_pkgdown.yml`, CI, `.Rbuildignore`, `inst/COPYRIGHTS`. **Gate:** DESCRIPTION parses; `usethis`/`devtools` see a valid skeleton; vision+roadmap+AGENTS committed; first `check-log.md` + after-task entry written.

**Phase 1 — TMB core + engine** (Gauss+Noether). `src/*.cpp/.h`, `init.c`; `families.R`, `model_matrix.R`, `fit_engine.R`, `fit_tls.R`, `utils.R`, `simulate.R`; `test-parameter-transforms`. **Gate:** compiles; binomial + beta-binomial sims fit; finite logLik; convergence 0; CTmax≈truth, z≈truth; transforms test green.

**Phase 2 — API + methods + extract** (Emmy+Boole+Curie). `methods.R`, `extract.R`; `test-fit-binomial`, `test-fit-beta-binomial`. **Gate:** ungrouped+grouped fits readable; recovery green.

**Phase 3 — Profile + diagnostics** (Fisher+Gauss+Pat). `profile.R`, `confint.R`, `diagnostics.R`, eye-style `plot.profile_tls_profile`; `test-profile`, `test-group`. **Gate:** `D(MLE)≈0`; finite closed CIs; `ci_z==exp(ci_log_z)`; non-closing→warning; group targets work.

**Phase 4 — Predict + plotting** (Florence+Darwin) ∥ **Phase 5 — Benchmark**
(Curie+Jason+Rose). P4: `predict.R`, `plotting.R` (Confidence Eye),
`test-predict`. P5: canonical manifest, exact dataset/filter tests, the
Totoro-only bayesTLS builder, reviewed cache publisher, live ML comparison, and
legacy compatibility guards. **Gates:**
monotone surfaces + eye plots render + Florence audit; all canonical hashes,
formulas, thresholds, diagnostics, and legacy-exclusion tests green.

**Phase 6 — Docs + site** (documentation-writer+pkgdown-editor+Pat+Darwin+literature-curator+Grace). README, four vignettes, NEWS, `_pkgdown.yml` final. **Gate:** `devtools::document/test/check` + `pkgdown::build_site()` clean locally.

Each phase closes with an **after-task report + check-log entry + known-limitations/ROADMAP/README sync** (DoD §2).

## 16. Multi-agent fleet execution

Orchestrate per §1 ownership. **Sequential** P0→P1→P2→P3 (shared engine contract); **parallel** P4∥P5 after P3; P6 last. I (Ada/orchestrator) verify each phase's gate with real R output before proceeding (verification-before-completion). **Adversarial DoD review gate before "core done": Rose** (after-task-audit: stale wording, consistency, legacy exclusion) **+ Pat** (a new user can fit + interpret + read the warnings) **+ Fisher** (profile equivariance, identifiability, fair benchmark). Each agent reads SPEC.md + AGENTS.md, cites only lines actually read, writes an after-task report, and never claims success without pasted output.

## 17. Verification — acceptance ("core done" only when ALL pass)
```r
devtools::document(); devtools::test(); devtools::check(); pkgdown::build_site()
```
End-to-end:
```r
library(freqTLS)
dat <- simulate_tls(family="beta_binomial", CTmax=36, z=3, phi=50, seed=1)
fit <- fit_tls(dat, y=survived, n=total, time=duration, temp=temp, family="beta_binomial", tref=1)
summary(fit); confint(fit, parm="CTmax", method="profile"); confint(fit, parm="z", method="profile")
plot_survival_curves(fit); plot(profile(fit, "CTmax"))   # Confidence-Eye style
```
Plus: the canonical comparison article renders from the reviewed cache without
Stan, refits freqTLS live, reports actual differences without mixing estimands,
and contains no active shrimp/life-stage examples; `docs/dev-log/` has check-log
+ after-task/after-phase entries; Florence figure-audit passed; Rose+Pat+Fisher
DoD gate signed off.
