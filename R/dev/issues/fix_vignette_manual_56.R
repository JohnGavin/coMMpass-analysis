# R/dev/issues/fix_vignette_manual_56.R
# Manually fix the broken sections

file <- "R/tar_plans/plan_vignette_outputs.R"
lines <- readLines(file)

# Replace broken sections with clean code
# Pattern to find: "assay_names <- ... " followed by broken if-else
# Replace with simple: "counts <- get_counts_assay(se)"

new_lines <- character()
i <- 1
while (i <= length(lines)) {
  if (grepl("assay_names <- SummarizedExperiment::assayNames\\(se\\)", lines[i])) {
    # Found start of broken section
    # Add the assay_names line
    new_lines <- c(new_lines, lines[i])
    i <- i + 1
    
    # Skip all lines until we find a line that's not part of the broken structure
    # (i.e., not indented continuation, not }, not commented)
    while (i <= length(lines)) {
      line <- lines[i]
      if (grepl("^\\s+(sample_stats|n_samples|caption|hist_data|p <-) <-", line)) {
        # Found the next real code - stop skipping
        # But first add the fixed counts line
        indent <- sub("^(\\s*).*", "\\1", line)
        new_lines <- c(new_lines, paste0(indent, "counts <- get_counts_assay(se)"), "")
        break
      }
      i <- i + 1
    }
  } else {
    new_lines <- c(new_lines, lines[i])
    i <- i + 1
  }
}

writeLines(new_lines, file)
cat("✓ Manually fixed broken sections\n")
