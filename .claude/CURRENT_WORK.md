# Current Work — coMMpass-analysis

## Last Session: 2026-09-13

### Branch: feat/cc-20260913-102105 (worktree, no code changes)

### Completed This Session

Research-only session, no code/commit activity (working tree clean, nothing pushed):

1. Investigated two UK genomics resources as candidate leads to help with the
   "blocked: MMRF Gateway" limitation below (#88, #89, #9 — user lacks an
   academic email for controlled-access MMRF/dbGaP data):
   - **PanelApp (Genomics England)** — public Swagger REST API (panels, genes/
     entities, CNVs, STRs, activity log). Not yet queried; identifier naming
     is inconsistent across endpoints (`{id}` vs `{panel_pk}`, same value).
   - **NHS National Genomic Test Directory — HaemOnc eligibility criteria
     v1.1** (`~/Downloads/haematological-oncology-eligibility-criteria-version-1.1.pdf`).
     Verified (via `pdftotext`, not just raw zlib grep — see tooling note)
     the full "Myeloma TP126" test package: FISH panel for IGH::FGFR3 (t4;14),
     IGH::CCND3, IGH::CCND1 (t11;14), IGH::MAF (t14;16), IGH::MAFB (t14;20),
     IGH break-apart, hyperdiploidy, CDKN2C/CKS1B (1p/1q), TP53 (del17p), MYC
     rearrangement — plus NGS small-variant/CNV panels, an SNP array, and WGS
     eligibility (M235). This maps closely onto CoMMpass's own clinical
     cytogenetics/seqFISH variables — useful as an independent reference for
     panel completeness, not an extra patient-data source.
2. Full detail + verification status saved to project memory:
   `~/.claude/projects/-Users-johngavin-docs-gh-proj-data-coMMpass/memory/project_genomic-data-source-leads.md`.
3. Installed `poppler` (`pdftotext`/`pdftoppm`) via Homebrew — was previously
   missing, blocking real PDF text extraction; a raw `zlib`-decompress +
   byte-grep approach on a font-subsetted PDF gives false negatives.

### Previous Session: 2026-03-19

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
