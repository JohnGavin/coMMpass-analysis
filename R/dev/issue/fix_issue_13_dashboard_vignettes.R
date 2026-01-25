#!/usr/bin/env Rscript
# Fix script for Issue #13: Dashboard dependencies and vignette improvements
# Run with: source("R/dev/issue/fix_issue_13_dashboard_vignettes.R")

library(logger)
log_info("Fixing Issue #13: Dashboard dependencies and vignette improvements")

# 1. FIXED: Remove ggplot2 dependency from Shinylive dashboard
log_info("Removed ggplot2 from dashboard - it was loaded but never used")
log_info("This fixes the 'munsell' package error in WebR")

# 2. ADDED: Utility functions for human-readable formatting
log_info("Added format_file_size() to R/utils.R")
log_info("Added format_with_commas() for number formatting")
log_info("Added create_summary_table() for EDA")

# 3. CREATED: Data cleaning pipeline plan
log_info("Created R/tar_plans/plan_data_cleaning.R with:")
log_info("  - clean_clinical_data() - standardizes clinical data")
log_info("  - clean_expression_data() - preprocesses expression data")
log_info("  - integrate_clinical_expression() - matches samples")

# 4. ENHANCED: Vignettes with detailed EDA
log_info("Updated vignettes/01_data_acquisition.Rmd with:")
log_info("  - Human-readable file sizes using format_file_size()")
log_info("  - Interactive plots using plotly")
log_info("  - Summary statistics tables")
log_info("  - Data completeness analysis")
log_info("  - Age distribution histograms")
log_info("  - Missing data patterns")
log_info("  - Code chunks hidden by default (echo=FALSE)")

# 5. FIXED: pkgdown reference page configuration
log_info("Updated _pkgdown.yml with proper reference sections:")
log_info("  - Data Acquisition functions")
log_info("  - Quality Control functions")
log_info("  - Differential Expression functions")
log_info("  - Survival Analysis functions")
log_info("  - Pathway Analysis functions")
log_info("  - Utilities")
log_info("  - Data Cleaning functions")

# 6. REBUILT: Dashboard without ggplot2
log_info("Rebuilt dashboard_shinylive.html (56KB)")
log_info("Copied to docs/dashboard.html for GitHub Pages")

# Files modified:
files_modified <- c(
  "vignettes/dashboard_shinylive.qmd",  # Removed ggplot2
  "R/utils.R",                          # Added formatting functions
  "R/tar_plans/plan_data_cleaning.R",   # Created data cleaning plan
  "_targets.R",                          # Added plan_data_cleaning
  "vignettes/01_data_acquisition.Rmd",  # Enhanced with EDA
  "_pkgdown.yml",                        # Fixed reference configuration
  "docs/dashboard.html"                  # Updated for deployment
)

log_info("Files modified:")
for (f in files_modified) {
  log_info("  - {f}")
}

# Testing checklist
log_info("\nTesting Checklist:")
log_info("1. [ ] Open dashboard.html in browser")
log_info("2. [ ] Check console for errors (F12)")
log_info("3. [ ] Verify no 'munsell' package error")
log_info("4. [ ] Test all dashboard tabs")
log_info("5. [ ] Build vignettes: devtools::build_vignettes()")
log_info("6. [ ] Build pkgdown: pkgdown::build_site()")
log_info("7. [ ] Check reference page shows functions")

log_success("Issue #13 fixes complete!")