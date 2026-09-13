# Current Work — coMMpass-analysis

## Last Session: 2026-09-13 (branch feat/cc-20260913-184749)

### Completed This Session

- Filed [#104](https://github.com/JohnGavin/coMMpass-analysis/issues/104) — research task: virtuallab.themmrf.org (MMRF Virtual Lab) as a data source, and API access requirements. No code changes.
- Key finding: Virtual Lab is a **Gen3** data commons deployment (Center for Translational Data Science, UChicago) — access model is inferred to be account + granted data access → API key (`credentials.json`) → short-lived bearer token → GraphQL (`sheepdog`/`peregrine`) + file download (`indexd`). Not confirmed for the MMRF instance itself; the public pages expose no eligibility/DUA/cost info.
- This directly relates to the **"blocked: MMRF Gateway"** items below (#88, #89, #9) — worth checking during #104's research whether Virtual Lab access unblocks any of them, or whether the "no academic email" constraint (from `project_genomic-data-source-leads.md` memory) blocks this too.

### Previous Session: 2026-03-19

### Branch: main

### Completed This Session

1. **#94 closed** — all 7 items: DT rendering, code provenance, TOC, echo:false, grobs, validation targets
2. **#70 closed** — missingness analysis: compute_missingness_profile(), test_missingness_vs_outcome(), 5 targets. Key finding: cause_of_death MNAR (HR ≈ 0, p < 2e-26)
3. **#84 partial** — brms infrastructure added (R/14_bayesian_survival.R, plan_bayesian.R, 5 targets). Model compiles and runs but has numerical instability — needs covariate scaling + priors
4. **6 more ggplot targets → grobs** (PCA, KM, commit_velocity)
5. **Dependencies added**: brms, bayesplot, posterior, splines2, naniar

### Pipeline State

- **R CMD check**: 0 errors, 0 warnings, 0 notes
- **Tests**: 0 FAIL, 885 PASS, 14 SKIP
- **Targets**: 0 errored, 12 NULL (data limitations)
- **CI**: latest in progress

### Open Issues

1. **#84** — brms tuning (scale covariates, add priors, increase iterations)
2. **#88, #89** — NULL targets (blocked: MMRF Gateway)
3. **#9** — Full data pipeline (blocked: MMRF Gateway)
4. **#69** — Clinical-informed normalisation
5. **#66, #65** — Adverse events, longitudinal biomarkers (blocked by #9)
6. **#79, #86** — API (low-priority)
7. **#8** — Single-cell (low-priority)
