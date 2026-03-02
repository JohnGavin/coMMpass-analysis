#!/usr/bin/env Rscript
# Render dashboard with webr config (CRITICAL fix)

message("=== Rendering dashboard_shinylive.qmd ===")
quarto::quarto_render("vignettes/dashboard_shinylive.qmd")

message("\n=== Copying to docs/dashboard.html ===")
if (!dir.exists("docs")) dir.create("docs", recursive = TRUE)

rendered_file <- "vignettes/dashboard_shinylive.html"
dest_file <- "docs/dashboard.html"

if (file.exists(rendered_file)) {
  file.copy(rendered_file, dest_file, overwrite = TRUE)
  message("Copied ", rendered_file, " to ", dest_file)
  
  message("\n=== Verifying webr config in HTML ===")
  html_content <- readLines(dest_file)
  webr_lines <- grep("webr:", html_content, value = TRUE)
  
  if (length(webr_lines) > 0) {
    message("SUCCESS: Found webr config in HTML!")
    message("Sample webr line: ", substr(webr_lines[1], 1, 100))
  } else {
    warning("FAILED: webr config NOT found in HTML!")
  }
  
  # Check for packages section
  pkg_section <- grep('"packages"\\s*:', html_content, value = TRUE)
  if (length(pkg_section) > 0) {
    message("Found packages section in HTML")
  }
  
  # File size check
  file_size <- file.size(dest_file)
  message("\nHTML file size: ", format(file_size, big.mark = ","), " bytes")
  
} else {
  stop("Rendered file not found: ", rendered_file)
}

message("\n=== COMPLETE ===")
