# R/dev/issues/fix_vignette_assay_refs_56.R
# Simple replacement of all "counts" assay references

file <- "R/tar_plans/plan_vignette_outputs.R"
lines <- readLines(file)

# Replace all variations
lines <- gsub(
  'SummarizedExperiment::assay\\(se, "counts"\\)',
  'get_counts_assay(se)',
  lines
)
lines <- gsub(
  'SummarizedExperiment::assay\\(filtered_data, "counts"\\)',
  'get_counts_assay(filtered_data)',
  lines
)
lines <- gsub(
  'if \\("counts" %in% assay_names\\) \\{',
  'if (TRUE) {  # Always use get_counts_assay',
  lines
)

writeLines(lines, file)
cat("✓ Fixed plan_vignette_outputs.R\n")
