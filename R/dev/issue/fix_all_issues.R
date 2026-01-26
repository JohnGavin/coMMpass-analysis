#!/usr/bin/env Rscript
# Fix script for all outstanding issues
# Run with: source("R/dev/issue/fix_all_issues.R")

library(logger)
library(devtools)

log_info("Fixing all outstanding issues...")

# 1. Add @export tags to main functions
log_info("Adding @export tags to analysis functions...")

# List of files and functions to export
files_to_update <- list(
  "R/02_quality_control.R" = c("calculate_qc_metrics", "identify_outliers",
                                "filter_low_expression", "normalize_counts"),
  "R/03_differential_expression.R" = c("run_deseq2_analysis", "run_edger_analysis",
                                        "run_limma_analysis", "combine_de_results"),
  "R/04_survival_analysis.R" = c("prepare_survival_data", "fit_survival_model",
                                  "plot_survival_curves", "cox_regression_analysis"),
  "R/05_pathway_analysis.R" = c("run_enrichment_analysis", "run_gsea",
                                 "plot_enrichment_results", "create_pathway_network"),
  "R/tar_plans/plan_data_cleaning.R" = c("clean_clinical_data", "clean_expression_data",
                                          "integrate_clinical_expression")
)

# Add @export tags
for (file in names(files_to_update)) {
  functions <- files_to_update[[file]]
  log_info("Processing {file}")

  if (file.exists(file)) {
    content <- readLines(file)

    for (func in functions) {
      # Find function definition
      pattern <- paste0("^", func, " <- function")
      func_line <- grep(pattern, content)

      if (length(func_line) > 0) {
        # Check if @export already exists
        if (func_line[1] > 1) {
          prev_line <- content[func_line[1] - 1]
          if (!grepl("@export", prev_line)) {
            # Add @export and @description
            content <- append(content,
                            c(paste0("#' @description ", func),
                              "#' @export"),
                            after = func_line[1] - 1)
            log_info("  Added @export for {func}")
          }
        }
      }
    }

    # Write back
    writeLines(content, file)
  }
}

# 2. Fix _pkgdown.yml to match actual exports
log_info("Updating _pkgdown.yml reference section...")

pkgdown_content <- '
url: https://JohnGavin.github.io/coMMpass-analysis/
template:
  bootstrap: 5

reference:
- title: "Data Access"
  desc: "Functions for retrieving CoMMpass data"
  contents:
  - download_commpass_rna
  - query_gdc_clinical
  - list_s3_files
  - download_s3_files

- title: "Quality Control"
  desc: "Functions for data quality assessment"
  contents:
  - calculate_qc_metrics
  - identify_outliers
  - filter_low_expression
  - normalize_counts

- title: "Differential Expression"
  desc: "Functions for differential expression analysis"
  contents:
  - run_deseq2_analysis
  - run_edger_analysis
  - run_limma_analysis
  - combine_de_results

- title: "Survival Analysis"
  desc: "Functions for survival modeling"
  contents:
  - prepare_survival_data
  - fit_survival_model
  - plot_survival_curves
  - cox_regression_analysis

- title: "Pathway Analysis"
  desc: "Functions for functional enrichment"
  contents:
  - run_enrichment_analysis
  - run_gsea
  - plot_enrichment_results
  - create_pathway_network

- title: "Utilities"
  desc: "Helper functions and utilities"
  contents:
  - format_file_size
  - format_with_commas
  - create_summary_table
  - clean_clinical_data
  - clean_expression_data
  - integrate_clinical_expression

articles:
- title: "Vignettes"
  contents:
  - 01_data_acquisition

navbar:
  structure:
    left: [intro, reference, articles]
    right: [github]
'

writeLines(pkgdown_content, "_pkgdown.yml")

# 3. Update vignette to hide code by default
log_info("Updating vignette with code folding...")

vignette_file <- "vignettes/01_data_acquisition.Rmd"
if (file.exists(vignette_file)) {
  content <- readLines(vignette_file)

  # Update knitr options
  opts_line <- grep("knitr::opts_chunk", content)[1]
  if (!is.na(opts_line)) {
    content[opts_line] <- 'knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  echo = FALSE,  # Hide code by default
  message = FALSE,
  warning = FALSE,
  fig.width = 8,
  fig.height = 5,
  fig.cap = TRUE  # Enable figure captions
)'
  }

  writeLines(content, vignette_file)
}

# 4. Run document to generate man pages
log_info("Generating documentation...")
tryCatch({
  devtools::document()
}, error = function(e) {
  log_warn("Document generation had issues: {e$message}")
})

log_success("All fixes applied! Next steps:")
log_info("1. Rebuild dashboard with: quarto render vignettes/dashboard_shinylive.qmd")
log_info("2. Build vignettes with: devtools::build_vignettes()")
log_info("3. Build pkgdown site with: pkgdown::build_site()")
log_info("4. Commit and push all changes")