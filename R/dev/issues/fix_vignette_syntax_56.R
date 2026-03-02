# R/dev/issues/fix_vignette_syntax_56.R
# Fix broken syntax in plan_vignette_outputs.R

file <- "R/tar_plans/plan_vignette_outputs.R"
lines <- readLines(file)

# Find lines with broken if-else structure
# Pattern: "counts <- get_counts_assay(se)" followed by commented lines and orphaned "} else"
for (i in seq_along(lines)) {
  if (grepl("counts <- get_counts_assay\\(", lines[i])) {
    # Look ahead for orphaned } else
    for (j in (i+1):min(i+10, length(lines))) {
      if (grepl("^\\s*\\} else", lines[j])) {
        # Remove the broken structure - keep only the get_counts_assay line
        # and remove all commented/broken else lines until we find valid code
        valid_next <- j
        while (valid_next <= length(lines) && 
               (grepl("^\\s*#", lines[valid_next]) || grepl("^\\s*\\}", lines[valid_next]))) {
          valid_next <- valid_next + 1
        }
        # Remove broken lines
        lines <- lines[-c((i+1):(valid_next-1))]
        break
      }
    }
  }
}

writeLines(lines, file)
cat("✓ Fixed broken if-else syntax\n")
