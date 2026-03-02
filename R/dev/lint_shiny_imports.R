# lint_shiny_imports.R
# Scan shiny/**/*.R for bare (unqualified) calls to coMMpass exported functions.
# Usage: Rscript R/dev/lint_shiny_imports.R
#
# Returns exit code 1 if violations are found, 0 otherwise.

# ── coMMpass exported functions ──────────────────────────────────────────────
commpass_exports <- c(

  # Data acquisition
  "download_gdc_rnaseq", "download_clinical_data", "acquire_commpass_data",
  # Cytogenetics

  "extract_cytogenetic_data",
  # QC
  "calculate_qc_metrics",

  # Differential expression
  "run_deseq2",
  # Survival
  "prepare_survival_data", "run_kaplan_meier", "run_cox_regression",
  # Pathway analysis
  "run_gsea", "run_ora", "run_pathway_analysis",
  # Visualization / analysis helpers

  "run_vst", "compute_pca", "plot_volcano", "plot_ma", "plot_pca",
  "plot_heatmap_de", "summarize_de_methods",
  # Annotation / enrichment plots
  "annotate_genes", "annotate_de_results",
  "plot_enrichment_dotplot", "plot_enrichment_barplot",
  "plot_gsea_running_score",
  # Cytogenetic plots
  "plot_cytogenetic_oncoprint", "calculate_cooccurrence",
  "plot_cooccurrence_heatmap", "summarize_cytogenetics",
  # Survival plots
  "plot_km", "plot_forest", "run_km_by_markers",
  # S3 / parquet queries
  "query_commpass_rna", "get_commpass_clinical",
  "list_s3_commpass", "download_s3_subset",
  # Cleaning / integration
  "clean_clinical_data", "clean_expression_data",
  "integrate_clinical_expression",
  # Data dictionary
  "get_commpass_data_dictionary", "get_variable_docs",
  # Parquet / tbl
  "query_commpass_parquet", "get_commpass_tbl",
  # Utilities
  "format_file_size", "format_with_commas", "create_summary_table"
)

# ── Find Shiny R files ──────────────────────────────────────────────────────
shiny_dir <- file.path("inst", "shiny")
if (!dir.exists(shiny_dir)) {
  message("No inst/shiny/directory found. Nothing to lint.")
  quit(status = 0)
}

shiny_files <- list.files(
  shiny_dir,
  pattern = "\\.R$",
  recursive = TRUE,
  full.names = TRUE
)

if (length(shiny_files) == 0) {
  message("No .R files found under shiny/. Nothing to lint.")
  quit(status = 0)
}

# ── Scan each file ──────────────────────────────────────────────────────────
# A bare call is a function name followed by '(' that is NOT preceded by
# 'coMMpass::'. We also exclude matches inside comments and strings (basic
# heuristic: skip lines starting with #).

violations <- data.frame(

  file = character(),
  line = integer(),
  function_name = character(),
  text = character(),
  stringsAsFactors = FALSE
)

for (f in shiny_files) {
  lines <- readLines(f, warn = FALSE)
  for (i in seq_along(lines)) {
    line <- lines[i]

    # Skip comment lines
    if (grepl("^\\s*#", line)) next

    for (fn in commpass_exports) {
      # Match bare function call: fn( without coMMpass:: prefix
      # Negative lookbehind for 'coMMpass::' and also for word characters
      # (to avoid matching e.g. 'my_plot_volcano')
      pattern <- paste0("(?<!coMMpass::)(?<!\\w)", fn, "\\s*\\(")
      if (grepl(pattern, line, perl = TRUE)) {
        violations <- rbind(violations, data.frame(
          file = f,
          line = i,
          function_name = fn,
          text = trimws(line),
          stringsAsFactors = FALSE
        ))
      }
    }
  }
}

# ── Report ───────────────────────────────────────────────────────────────────
if (nrow(violations) == 0) {
  message("OK: No bare coMMpass function calls found in inst/shiny/files.")
  quit(status = 0)
} else {
  message(
    "FAIL: Found ", nrow(violations),
    " bare coMMpass function call(s) in inst/shiny/files.\n",
    "All coMMpass functions must be called as coMMpass::function_name().\n"
  )
  for (j in seq_len(nrow(violations))) {
    v <- violations[j, ]
    message(sprintf(
      "  %s:%d  %s()  ->  %s",
      v$file, v$line, v$function_name, v$text
    ))
  }
  quit(status = 1)
}
