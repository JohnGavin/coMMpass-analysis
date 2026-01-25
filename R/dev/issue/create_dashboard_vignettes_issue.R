#!/usr/bin/env Rscript
# Script: create_dashboard_vignettes_issue.R
# Purpose: Create GitHub issue for dashboard dependencies and vignette improvements
# Run with: R -f R/dev/issue/create_dashboard_vignettes_issue.R

library(gh)

issue_title <- "Fix dashboard dependencies and improve vignettes"

issue_body <- "## Summary
Critical issues found with the Shinylive dashboard deployment and vignettes need immediate attention.

## Console Errors from Live Dashboard
```
preload error:Error: package or namespace load failed for 'ggplot2' in loadNamespace(j <- i[[1L]], c(lib.loc, .libPaths()), versionCheck = vI[[j]]):
preload error: there is no package called 'munsell'
preload error:Error: package 'ggplot2' could not be loaded
```

## Issues to Fix

### 1. Shinylive Dashboard ggplot2 Dependencies ❌ CRITICAL
**Error:** Dashboard fails with `there is no package called 'munsell'`
- ggplot2 won't load without munsell, scales, farver, etc.
- These dependencies aren't explicitly declared in the dashboard
- **Fix:** Either:
  - Replace ggplot2 with plotly-only visualizations
  - OR explicitly add all ggplot2 dependencies to webr packages list

### 2. Vignette File Size Formatting
**Current:** `Total size: 5000877192` (unreadable)
**Needed:** `Total size: 5.0 GB (5,000,877,192 bytes)`
- Use `scales::label_bytes()` or custom formatting
- Apply to all file size displays in vignettes

### 3. Data Cleaning in Pipeline
**Current code in vignette:**
```r
clinical <- tar_read(clinical_data)
names(clinical) <- make.unique(names(clinical))  # Should be in pipeline!
```
- Move all data cleaning to targets pipeline
- Vignettes should only read clean data

### 4. Enhanced EDA in Vignettes
**Current:** Basic summary tables only
**Needed:**
- Distribution plots for key variables
- Missing data patterns
- Quality control visualizations
- Sample characteristics tables
- Hide code chunks by default (`echo=FALSE`)

### 5. pkgdown Reference Page
**Issue:** https://johngavin.github.io/coMMpass-analysis/reference/index.html is blank
- Missing function documentation or _pkgdown.yml configuration
- Functions may not be exported properly

## Testing Evidence
Dashboard tested at: https://johngavin.github.io/coMMpass-analysis/dashboard.html
- Service worker loads successfully
- WebR initializes
- Packages fail at ggplot2 dependency chain

## Acceptance Criteria
- [ ] Dashboard loads without console errors
- [ ] All plots render correctly
- [ ] File sizes display in human-readable format
- [ ] Data cleaning is in pipeline, not vignettes
- [ ] Vignettes include comprehensive EDA
- [ ] pkgdown reference page shows all functions
"

# Create the issue
result <- gh::gh(
  "POST /repos/JohnGavin/coMMpass-analysis/issues",
  title = issue_title,
  body = issue_body
)

cat("Issue created: #", result$number, "\n")
cat("URL: ", result$html_url, "\n")