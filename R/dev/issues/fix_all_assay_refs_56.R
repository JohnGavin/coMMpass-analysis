# R/dev/issues/fix_all_assay_refs_56.R
# Fix ALL hardcoded "counts" assay references across the codebase
# Move get_counts_assay() to utils.R and use it everywhere

# 1. Move get_counts_assay from R/02_quality_control.R to R/utils.R
qc_lines <- readLines("R/02_quality_control.R")

# Find and extract the helper function
helper_start <- grep("^get_counts_assay <- function", qc_lines)
helper_end <- grep("^}$", qc_lines)
helper_end <- helper_end[helper_end > helper_start][1]

# Also get roxygen comments
helper_roxygen_start <- helper_start - 6  # 6 lines of roxygen before function
helper_code <- qc_lines[helper_roxygen_start:helper_end]

# Remove from qc file
qc_lines <- qc_lines[-c(helper_roxygen_start:helper_end)]
writeLines(qc_lines, "R/02_quality_control.R")
cat("✓ Removed get_counts_assay from R/02_quality_control.R\n")

# Add to utils.R at the beginning (after initial comments)
utils_lines <- readLines("R/utils.R")
first_func_idx <- grep("^#'|^[a-z_]+ <- function", utils_lines)[1]

utils_lines <- c(
  utils_lines[1:(first_func_idx - 1)],
  helper_code,
  "",
  utils_lines[first_func_idx:length(utils_lines)]
)
writeLines(utils_lines, "R/utils.R")
cat("✓ Added get_counts_assay to R/utils.R\n")

# 2. Replace ALL hardcoded assay(*, "counts") calls in all R files
files_to_fix <- c(
  "R/01_data_acquisition.R",
  "R/03_differential_expression.R",
  "R/06_de_visualization.R",
  "R/utils.R"
)

for (file in files_to_fix) {
  lines <- readLines(file)
  
  # Replace patterns
  lines <- gsub(
    'SummarizedExperiment::assay\\(se_data, "counts"\\)',
    'get_counts_assay(se_data)',
    lines
  )
  lines <- gsub(
    'SummarizedExperiment::assay\\(se, "counts"\\)',
    'get_counts_assay(se)',
    lines
  )
  lines <- gsub(
    'assay\\(se_data, "counts"\\)',
    'get_counts_assay(se_data)',
    lines
  )
  lines <- gsub(
    'assay\\(se, "counts"\\)',
    'get_counts_assay(se)',
    lines
  )
  
  writeLines(lines, file)
  cat("✓ Fixed", file, "\n")
}

cat("\n✓ All 'counts' assay references now use get_counts_assay()\n")
