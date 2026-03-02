# R/dev/issues/fix_eda_duckdb_type_cast_56.R
# Fix type casting error in eda_duckdb_demo target
# Issue: age_at_diagnosis is VARCHAR with literal "NA" strings
# Solution: Filter out "NA" strings before casting to numeric

plan_path <- "R/tar_plans/plan_eda.R"
lines <- readLines(plan_path)

# Find the aggregation section (lines 150-159)
# Need to:
# 1. Filter !is.na(gender) AND age_at_diagnosis != "NA"
# 2. Cast age_at_diagnosis to numeric

# Find line with filter(!is.na(gender))
filter_idx <- grep('dplyr::filter\\(!is.na\\(gender\\)\\)', lines)
if (length(filter_idx) == 0) {
  stop("Cannot find filter line")
}

# Replace the filter line to also exclude "NA" strings in age_at_diagnosis
old_filter <- lines[filter_idx]
new_filter <- gsub(
  'dplyr::filter\\(!is.na\\(gender\\)\\)',
  'dplyr::filter(!is.na(gender), age_at_diagnosis != "NA")',
  old_filter
)
lines[filter_idx] <- new_filter

# Verify the cast line is present
cast_idx <- grep('as.numeric\\(age_at_diagnosis\\) / 365.25', lines)
if (length(cast_idx) == 0) {
  stop("Cast line not found - was previous fix applied?")
}

writeLines(lines, plan_path)
cat("✓ Fixed filter to exclude 'NA' strings in age_at_diagnosis\n")
cat("✓ Line", filter_idx, "updated\n")
