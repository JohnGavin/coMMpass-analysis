# R/dev/issues/fix_rnaseq_list_columns_56.R
# Fix arrow parquet write error for list columns in colData
# Issue: treatments, primary_site, disease_type are list columns
# Solution: Convert list columns to character before write_parquet()

file_path <- "R/01_data_acquisition.R"
lines <- readLines(file_path)

# Find line 157: "sample_meta <- as.data.frame(SummarizedExperiment::colData(se))"
meta_idx <- grep("sample_meta <- as.data.frame\\(SummarizedExperiment::colData\\(se\\)\\)",
                 lines)
if (length(meta_idx) == 0) {
  stop("Cannot find sample_meta line")
}

# Insert code to flatten list columns after line 157
new_lines <- c(
  "  ",
  "  # Flatten list columns (arrow cannot write list columns to parquet)",
  "  list_cols <- sapply(sample_meta, function(x) is.list(x) && !is.data.frame(x))",
  "  if (any(list_cols)) {",
  "    for (col_name in names(sample_meta)[list_cols]) {",
  "      sample_meta[[col_name]] <- sapply(",
  "        sample_meta[[col_name]],",
  "        function(x) if (length(x) == 0) NA_character_ else paste(x, collapse = \"; \")",
  "      )",
  "    }",
  "  }"
)

# Insert after line 157
lines <- c(
  lines[1:meta_idx],
  new_lines,
  lines[(meta_idx + 1):length(lines)]
)

writeLines(lines, file_path)
cat("✓ Added list column flattening after line", meta_idx, "\n")
