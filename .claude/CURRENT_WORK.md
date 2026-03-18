# Current Work — coMMpass-analysis

## Last Session: 2026-03-18

### Branch: main

### Completed This Session

1. **Code provenance refactor** — deleted 78 stale code_vig_*.rds snapshots, kept 20 real pipeline targets. Code display now comes from pipeline targets (auto-invalidating) or tar_manifest() locally.

2. **echo:false on all show_target chunks** — 106 chunks across 12 vignettes. Quarto no longer shows `show_target(...)` in code folds; users see the generating R code via `<details>Generating code</details>`.

3. **CI deployment fixed** — root cause was DT widgets in RDS with Nix store paths. RDS files now contain plain data.frames. Last 3 CI runs all succeeded.

4. **Lessons-learned issue #95** created documenting 5 architectural lessons.

### Pipeline State

- **R CMD check**: 0 errors, 0 warnings, 0 notes
- **Tests**: 0 FAIL, 873 PASS, 14 SKIP
- **Targets**: 0 errored, 12 NULL (data limitations)
- **CI**: Last 3 deploys succeeded
- **pkgdown**: 14 articles, 54 figures, 112 ref pages

### Architecture (Code Provenance)

```
R/viz/*.R                         ← source of truth (edit here)
    ├→ code_vig_* target          ← deparse(body(fn)) → auto-invalidates
    │   └→ RDS in inst/extdata/   ← available in CI (20 targets)
    └→ vig_* target               ← evaluates function → plot/table
        └→ RDS in inst/extdata/   ← available in CI (data.frames, not DT)

Vignette: #| echo: false + show_target("vig_X")
  → <details>Generating code</details> + rendered output
```

### Open Issues
- #94 — vignette rendering (partially closed — DT, TOC, echo done; interactive DAG remains)
- #95 — lessons-learned documentation (open for review)
- #9 — data acquisition (blocked: MMRF Gateway)
- #79, #86 — API (low-priority)
