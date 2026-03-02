# R/dev/issues/fix_assay_name_56.R
# Fix hardcoded "counts" assay name - GDC uses "unstranded"
# Solution: Add helper function to get the correct counts assay

# 1. Add helper function to R/02_quality_control.R
qc_file <- "R/02_quality_control.R"
lines <- readLines(qc_file)

# Find first function definition (after roxygen comments)
first_func_idx <- grep("^calculate_qc_metrics <- function", lines)[1]

# Insert helper function before first function
helper_code <- c(
  "#' Get counts assay from SummarizedExperiment",
  "#' ",
  "#' GDC STAR-Counts uses 'unstranded', but fallback to 'counts' if present",
  "#' @param se SummarizedExperiment object",
  "#' @return Counts matrix",
  "#' @keywords internal",
  "get_counts_assay <- function(se) {",
  "  assay_names <- SummarizedExperiment::assayNames(se)",
  "  if ('unstranded' %in% assay_names) {",
  "    return(SummarizedExperiment::assay(se, 'unstranded'))",
  "  } else if ('counts' %in% assay_names) {",
  "    return(SummarizedExperiment::assay(se, 'counts'))",
  "  } else if (length(assay_names) > 0) {",
  "    logger::log_warn('Using first assay: {assay_names[1]}')",
  "    return(SummarizedExperiment::assay(se, 1))",
  "  } else {",
  "    cli::cli_abort('No assays found in SummarizedExperiment')",
  "  }",
  "}",
  ""
)

lines <- c(
  lines[1:(first_func_idx - 1)],
  helper_code,
  lines[first_func_idx:length(lines)]
)

writeLines(lines, qc_file)
cat("✓ Added get_counts_assay() helper function\n")

# 2. Replace all hardcoded assay(*, "counts") calls with get_counts_assay()
lines <- readLines(qc_file)

# Replace patterns
lines <- gsub(
  'SummarizedExperiment::assay\\(se_data, "counts"\\)',
  'get_counts_assay(se_data)',
  lines
)
lines <- gsub(
  'assay\\(se_data, "counts"\\)',
  'get_counts_assay(se_data)',
  lines
)

writeLines(lines, qc_file)
cat("✓ Replaced hardcoded 'counts' assay references\n")
