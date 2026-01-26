#!/usr/bin/env Rscript

cat("\n=== Nix Environment Verification Report ===\n\n")

# Test 1: Check R version and Nix environment
cat("1. ENVIRONMENT INFO\n")
cat("   R Version:", R.version$version.string, "\n")
cat("   Nix Shell:", Sys.getenv("IN_NIX_SHELL"), "\n\n")

# Test 2: Check if required packages are installed
cat("2. PACKAGE INSTALLATION CHECK\n")
required_packages <- c("shiny", "plotly", "bslib", "DT", "shinylive", "dplyr", "tidyr", "ggplot2")

install_check <- sapply(required_packages, function(pkg) {
  pkg %in% rownames(installed.packages())
})

for (pkg in names(install_check)) {
  status <- if(install_check[pkg]) "INSTALLED" else "MISSING"
  cat(sprintf("   %-15s: %s\n", pkg, status))
}

# Test 3: Try loading key packages
cat("\n3. PACKAGE LOADING TEST\n")
load_results <- sapply(required_packages, function(pkg) {
  tryCatch({
    library(pkg, character.only = TRUE, quietly = TRUE)
    "LOADED"
  }, error = function(e) {
    paste("ERROR:", substr(e$message, 1, 40))
  })
})

for (pkg in names(load_results)) {
  cat(sprintf("   %-15s: %s\n", pkg, load_results[pkg]))
}

# Test 4: Check Shiny app
cat("\n4. SHINY APP SYNTAX CHECK\n")
app_check <- tryCatch({
  source("shiny/app.R", local = TRUE)
  "VALID"
}, error = function(e) {
  paste("ERROR:", substr(e$message, 1, 50))
})
cat(sprintf("   shiny/app.R: %s\n", app_check))

# Test 5: Check Shiny modules
cat("\n5. SHINY MODULES CHECK\n")
module_files <- list.files("shiny/modules", pattern = "\\.R$", full.names = TRUE)
for (mod in module_files) {
  mod_check <- tryCatch({
    source(mod, local = TRUE)
    "OK"
  }, error = function(e) {
    paste("ERROR:", substr(e$message, 1, 40))
  })
  cat(sprintf("   %s: %s\n", basename(mod), mod_check))
}

cat("\n=== SUMMARY ===\n")
all_loaded <- all(load_results == "LOADED")
shiny_valid <- app_check == "VALID"
modules_ok <- all(grepl("^OK$", sapply(module_files, function(m) {
  tryCatch({source(m, local = TRUE); "OK"}, error = function(e) "ERROR")
})))

cat(sprintf("All packages loaded: %s\n", ifelse(all_loaded, "YES", "NO")))
cat(sprintf("Shiny app valid: %s\n", ifelse(shiny_valid, "YES", "NO")))
cat(sprintf("All modules load: %s\n", ifelse(modules_ok, "YES", "NO")))

if (all_loaded && shiny_valid && modules_ok) {
  cat("\nResult: SUCCESS - Environment fully configured and tested\n")
} else {
  cat("\nResult: PARTIAL - Some issues detected\n")
}

cat("\n")
