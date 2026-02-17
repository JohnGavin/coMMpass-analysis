# fix_023_eda_vignette.R
# Issue: https://github.com/JohnGavin/coMMpass-analysis/issues/23
# Branch: feat/issue-23-eda-vignette
#
# Summary:
#   Add an exploratory data analysis vignette that shows users how to
#   explore downloaded CoMMpass data using the DuckDB/parquet infrastructure.
#
# Files created:
#   - R/tar_plans/plan_eda.R (5 targets: clinical, biospecimen, rnaseq,
#     duckdb demo, integration summary)
#   - vignettes/exploratory-analysis.Rmd (8-section EDA vignette)
#   - R/dev/issues/fix_023_eda_vignette.R (this file)
#
# Files modified:
#   - _targets.R (added plan_eda to pipeline)
#   - _pkgdown.yml (fixed stale vignette names, added exploratory-analysis)
#
# Verification:
#   devtools::document()       # passed
#   targets::tar_validate()    # passed
#   devtools::test()           # see PR
#   devtools::check()          # see PR
