# Current Work — coMMpass-analysis

## Last Session: 2026-03-15

### Branch: main

### Completed This Session

1. **Regenerated default.nix** — date 2026-02-02, qpdf added
2. **Reduced ggplot sizes** — 7 targets, 96 MB → 1.1 MB via ggplotGrob()
3. **GDC treatment extraction** — 7,184 records, 994 patients
4. **Cox model fix** — drop all-NA covariates, ISS + age (C=0.673)
5. **msigdbr fix** — fallback path for local parquets
6. **Causal DAGs (#85)** — dagitty/ggdag, adjustment sets, model checks, vignette
7. **pkgdown validated** — 14 articles, 112 ref pages, 54 figures, 0 errors

### Pipeline State

- **R CMD check**: 0 errors, 0 warnings, 0 notes
- **Tests**: 0 FAIL, 869 PASS, 14 SKIP
- **Targets**: 0 errored, 12 NULL (data limitations)
- **RDS**: 143 files, 3.4 MB total
- **pkgdown**: 14 articles built, 54 figure PNGs

### NULL Targets (12 — all PFS/response/FISH data)
- 7 PFS: shiny_pfs_data + 6 cascade (need pfs_time/pfs_status)
- 3 FISH: vig_km_markers, vig_km_risk, shiny_risk_os_by_risk (need cytogenetic markers)
- 2 response: shiny_km_os_by_response, shiny_risk_os_by_response (need treatment response)
- All require MMRF Researcher Gateway registration (pending)

### Issues Closed This Session
- #93 (package.nix from default.R) — done
- #85 (causal DAGs) — done

### Issues Labelled Low-Priority
- #79 (API documentation) — scope notes added
- #86 (plumber2 API) — 5 phases documented

### Open Issues (by priority)
1. #9 — Full data acquisition pipeline (blocked: MMRF Gateway access)
2. #88, #89, #91 — NULL targets (blocked by #9)
3. #79, #86 — API (low-priority, scope documented)
4. #84 — Bayesian survival (low-priority)
5. #70, #69, #66, #65, #8 — Analysis extensions (low-priority)
