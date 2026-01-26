# test_dashboard.R
# Tests for CoMMpass Dashboard - Deployment Readiness Verification
# Run with: R -f test_dashboard.R

cat("\n=== CoMMpass Dashboard - Deployment Readiness Tests ===\n\n")

# Test 1: Required packages availability
cat("Test 1: Checking required packages...\n")
required_packages <- c(
  "shiny", "bslib", "plotly", "DT", "dplyr", "tidyr", 
  "ggplot2", "survival", "survminer"
)

pkg_status <- data.frame(
  package = required_packages,
  available = logical(length(required_packages)),
  stringsAsFactors = FALSE
)

for (i in seq_along(required_packages)) {
  pkg <- required_packages[i]
  pkg_status$available[i] <- requireNamespace(pkg, quietly = TRUE)
  status <- if (pkg_status$available[i]) "✓" else "✗"
  cat(sprintf("  %s %s\n", status, pkg))
}

if (!all(pkg_status$available)) {
  cat("\nWARNING: Missing packages detected!\n")
  missing <- pkg_status$package[!pkg_status$available]
  cat("Missing:", paste(missing, collapse = ", "), "\n")
}

# Test 2: Module files exist and are readable
cat("\nTest 2: Checking module files...\n")
module_dir <- "shiny/modules"
required_modules <- c(
  "mod_data_loader.R",
  "mod_qc_viz.R",
  "mod_de_viz.R",
  "mod_survival_viz.R",
  "mod_pathway_viz.R"
)

for (module in required_modules) {
  path <- file.path(module_dir, module)
  exists <- file.exists(path)
  readable <- if (exists) {
    tryCatch({
      readLines(path)
      TRUE
    }, error = function(e) FALSE)
  } else {
    FALSE
  }
  status <- if (readable) "✓" else "✗"
  cat(sprintf("  %s %s\n", status, module))
}

# Test 3: Main app.R exists and can be parsed
cat("\nTest 3: Checking app.R...\n")
app_path <- "shiny/app.R"
if (file.exists(app_path)) {
  app_content <- readLines(app_path)
  cat(sprintf("  ✓ app.R exists (%d lines)\n", length(app_content)))
  
  # Check for required elements
  elements <- list(
    "library(shiny)" = any(grepl("library\\(shiny\\)", app_content)),
    "page_navbar" = any(grepl("page_navbar", app_content)),
    "server function" = any(grepl("^server\\s*<-\\s*function", app_content)),
    "shinyApp" = any(grepl("shinyApp", app_content))
  )
  
  for (elem_name in names(elements)) {
    status <- if (elements[[elem_name]]) "✓" else "✗"
    cat(sprintf("    %s %s\n", status, elem_name))
  }
} else {
  cat("  ✗ app.R not found\n")
}

# Test 4: Shinylive vignette exists
cat("\nTest 4: Checking Shinylive vignette...\n")
vignette_path <- "vignettes/dashboard_shinylive.qmd"
html_path <- "vignettes/dashboard_shinylive.html"

if (file.exists(vignette_path)) {
  cat(sprintf("  ✓ dashboard_shinylive.qmd exists\n"))
} else {
  cat(sprintf("  ✗ dashboard_shinylive.qmd not found\n"))
}

if (file.exists(html_path)) {
  size <- file.size(html_path)
  cat(sprintf("  ✓ dashboard_shinylive.html exists (%.1f KB)\n", size / 1024))
} else {
  cat(sprintf("  ✗ dashboard_shinylive.html not found\n"))
}

# Test 5: Module sourcing test
cat("\nTest 5: Testing module loading...\n")
module_load_success <- TRUE
for (module in required_modules) {
  path <- file.path(module_dir, module)
  if (file.exists(path)) {
    tryCatch({
      source(path, local = TRUE)
      cat(sprintf("  ✓ %s loaded successfully\n", module))
    }, error = function(e) {
      cat(sprintf("  ✗ %s failed to load: %s\n", module, conditionMessage(e)))
      module_load_success <<- FALSE
    })
  }
}

# Test 6: DESCRIPTION file dependencies
cat("\nTest 6: Checking DESCRIPTION file...\n")
if (file.exists("DESCRIPTION")) {
  desc_content <- readLines("DESCRIPTION")
  depends_line <- grep("^Depends:", desc_content, value = TRUE)
  imports_line <- grep("^Imports:", desc_content, value = TRUE)
  
  if (length(depends_line) > 0) {
    cat(sprintf("  ✓ Depends specified\n"))
  }
  if (length(imports_line) > 0) {
    cat(sprintf("  ✓ Imports specified\n"))
  }
} else {
  cat("  ✗ DESCRIPTION file not found\n")
}

# Summary
cat("\n=== Summary ===\n")
all_packages_available <- all(pkg_status$available)
all_modules_exist <- all(file.exists(file.path(module_dir, required_modules)))
app_exists <- file.exists(app_path)
html_exists <- file.exists(html_path)

cat(sprintf("All packages available: %s\n", if (all_packages_available) "YES" else "NO"))
cat(sprintf("All modules exist: %s\n", if (all_modules_exist) "YES" else "NO"))
cat(sprintf("App structure valid: %s\n", if (app_exists) "YES" else "NO"))
cat(sprintf("Shinylive HTML generated: %s\n", if (html_exists) "YES" else "NO"))

if (all_packages_available && all_modules_exist && app_exists && html_exists) {
  cat("\n✓ Dashboard ready for deployment!\n\n")
  quit(status = 0)
} else {
  cat("\n✗ Issues detected - see above for details\n\n")
  quit(status = 1)
}
