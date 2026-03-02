# R/dev/issues/fix_vignette_careful_56.R
# Careful replacement: only replace the exact if-else blocks, preserve everything else

file <- "R/tar_plans/plan_vignette_outputs.R"

# Read from git HEAD to get clean version
system("git show HEAD:R/tar_plans/plan_vignette_outputs.R > /tmp/plan_vignette_clean.R")
lines <- readLines("/tmp/plan_vignette_clean.R")

# Replace ONLY the specific if-else patterns
# Pattern: if ("counts" %in% assay_names) { ... } else if ... { ... } else { return(NULL) }
# Replacement: counts <- get_counts_assay(se)

i <- 1
while (i <= length(lines)) {
  if (grepl('if \\("counts" %in% assay_names\\)', lines[i])) {
    # Found start of pattern - find the matching closing brace
    indent <- sub("^(\\s*).*", "\\1", lines[i])
    brace_count <- 1
    j <- i + 1
    
    while (j <= length(lines) && brace_count > 0) {
      if (grepl("\\{", lines[j])) brace_count <- brace_count + 1
      if (grepl("\\}", lines[j])) brace_count <- brace_count - 1
      j <- j + 1
    }
    
    # Replace entire block with single line
    lines <- c(
      lines[1:(i-1)],
      paste0(indent, "counts <- get_counts_assay(se)"),
      lines[j:length(lines)]
    )
  }
  
  # Also replace direct assay(..., "counts") calls
  lines[i] <- gsub(
    'SummarizedExperiment::assay\\((se|filtered_data), "counts"\\)',
    'get_counts_assay(\\1)',
    lines[i]
  )
  
  i <- i + 1
}

writeLines(lines, file)
cat("✓ Carefully replaced counts references\n")
