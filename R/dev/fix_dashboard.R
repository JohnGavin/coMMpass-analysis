#!/usr/bin/env Rscript
# Fix dashboard and documentation issues

# Step 1: Update documentation
message("=== Step 1: Updating package documentation ===")
devtools::document()

# Step 2: Render dashboard with webr config
message("\n=== Step 2: Rendering dashboard_shinylive.qmd ===")
quarto::quarto_render("vignettes/dashboard_shinylive.qmd")

# Step 3: Copy to docs directory
message("\n=== Step 3: Copying to docs/dashboard.html ===")
if (!dir.exists("docs")) dir.create("docs", recursive = TRUE)

rendered_file <- "vignettes/dashboard_shinylive.html"
dest_file <- "docs/dashboard.html"

if (file.exists(rendered_file)) {
  file.copy(rendered_file, dest_file, overwrite = TRUE)
  message("Copied ", rendered_file, " to ", dest_file)
  
  # Step 4: Verify webr config is in HTML
  message("\n=== Step 4: Verifying webr config in HTML ===")
  html_content <- readLines(dest_file)
  webr_lines <- grep("webr:", html_content, value = TRUE)
  
  if (length(webr_lines) > 0) {
    message("SUCCESS: Found webr config in HTML!")
    message("First webr line: ", webr_lines[1])
  } else {
    warning("FAILED: webr config NOT found in HTML!")
  }
  
  # Check for package names
  pkg_lines <- grep("(shiny|bslib|plotly|DT|dplyr|tidyr|survival|ggplot2|munsell)", html_content)
  message("Found ", length(pkg_lines), " lines mentioning key packages")
  
} else {
  stop("Rendered file not found: ", rendered_file)
}

message("\n=== COMPLETE ===")
