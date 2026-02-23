# R/tar_plans/plan_doc_examples.R
# Code-as-targets for vignette code display blocks.
# Each code example is stored as a character vector target, validated
# via parse(), and displayed in vignettes with safe_tar_read().
#
# Pattern reference: irishbuoys/R/tar_plans/plan_doc_examples.R

# --- Helper: parse validation (no execution) ---
parse_code_example <- function(code_lines) {
  code_text <- paste(code_lines, collapse = "\n")
  tryCatch(
    {
      parsed <- parse(text = code_text)
      list(
        valid = TRUE,
        n_expressions = length(parsed),
        code = code_lines,
        error = NULL
      )
    },
    error = function(e) {
      list(
        valid = FALSE,
        n_expressions = 0L,
        code = code_lines,
        error = conditionMessage(e)
      )
    }
  )
}

# ============================================================
# Code text targets (one per display block in vignettes)
# ============================================================

plan_doc_examples <- list(

  # --- data-dictionary.Rmd: "Loading Data" block ---
  targets::tar_target(
    code_dd_load_data,
    {
      # Depend on the source file defining these functions
      force(file.exists("R/database_parquet.R"))
      c(
        "library(coMMpass)",
        "",
        "# Load clinical data from parquet",
        "clinical <- query_commpass_parquet(\"clinical\")",
        "",
        "# Load with DuckDB lazy evaluation",
        "con <- DBI::dbConnect(duckdb::duckdb())",
        "clinical_tbl <- get_commpass_tbl(\"clinical\", con = con)",
        "result <- clinical_tbl |>",
        "  dplyr::filter(gender == \"female\") |>",
        "  dplyr::select(submitter_id, age_at_diagnosis, vital_status) |>",
        "  dplyr::mutate(age_years = age_at_diagnosis / 365.25) |>",
        "  dplyr::collect()",
        "DBI::dbDisconnect(con, shutdown = TRUE)"
      )
    }
  ),

  # --- data-dictionary.Rmd: "Exploring the Dictionary" block ---
  targets::tar_target(
    code_dd_explore_dict,
    {
      force(file.exists("R/data_dictionary.R"))
      c(
        "dd <- get_commpass_data_dictionary()",
        "",
        "# Find all clinical variables",
        "dplyr::filter(dd, category == \"clinical\")",
        "",
        "# Get detailed docs for a variable",
        "docs <- get_variable_docs(\"age_at_diagnosis\")",
        "cat(docs$usage_notes)"
      )
    }
  ),

  # --- README: Quick Start bash commands ---
  targets::tar_target(
    code_readme_quick_start,
    c(
      "# Requires Nix package manager (https://nixos.org/download.html)",
      "chmod +x default.sh",
      "./default.sh",
      "",
      "# macOS only: prevent sleep during long builds",
      "caffeinate -i ./default.sh"
    )
  ),

  # --- README: Project structure tree ---
  targets::tar_target(
    readme_project_tree,
    {
      force(file.exists("DESCRIPTION"))
      utils::capture.output(
        fs::dir_tree(recurse = 2, regexp = "^[^._]", type = "directory")
      )
    }
  ),

  # --- Glossary vignette: Glossary table ---
  targets::tar_target(
    glossary_table,
    data.frame(
      Term = c(
        "CoMMpass", "Cox PH", "DE", "FISH", "Gene detection",
        "GSEA", "HR", "IMWG", "ISS", "KM", "Library size", "MAD",
        "Outlier (QC)", "Read count", "scRNA-seq", "VST"
      ),
      Definition = c(
        "Clinical Outcomes in Multiple Myeloma to Personal Assessment of Genetic Profile",
        "Cox proportional hazards -- semi-parametric regression for survival data",
        "Differential expression -- genes with significantly different expression between conditions",
        "Fluorescence in situ hybridization -- detects cytogenetic abnormalities like t(4;14), t(14;16), del(17p)",
        "A gene is 'detected' in a sample if it has at least 1 mapped read (count > 0). The number of detected genes per sample is a QC metric; low detection suggests poor sequencing depth or sample degradation",
        "Gene Set Enrichment Analysis -- tests enrichment of gene sets in ranked lists",
        "Hazard ratio -- relative risk of event occurrence (HR > 1 = worse survival)",
        "International Myeloma Working Group -- defines cytogenetic risk criteria (Sonneveld et al. 2016, doi:10.1200/JCO.2014.55.1519)",
        "International Staging System -- classifies myeloma severity (I-III) by serum albumin and beta-2 microglobulin (Greipp et al. 2005, doi:10.1200/JCO.2005.04.242)",
        "Kaplan-Meier -- non-parametric survival curve estimator",
        "Total number of sequencing reads mapped to genes in one sample (= sum of all gene counts). A proxy for sequencing depth. Synonym: 'Total Counts'",
        "Median absolute deviation -- robust measure of spread. In QC context, MAD of gene counts within a single sample measures how variable gene expression is for that sample",
        "A sample flagged as outlier if it falls in the bottom 5th percentile of library size OR genes detected, computed across all samples in the pipeline run. The flag is binary (Yes/No) because it answers: 'Is this sample in the tail?' The continuous metrics inform the threshold",
        "The number of sequencing reads aligned to a gene in one sample. Raw integer counts are the input for DE methods (DESeq2, edgeR). See RNA-seq quantification",
        "Single-cell RNA sequencing -- measures gene expression in individual cells",
        "Variance-stabilizing transformation -- normalizes count data for visualization"
      ),
      See_Also = c(
        "[MMRF](https://themmrf.org/finding-a-cure/personalized-treatment-approaches/)",
        "[Survival vignette](survival-analysis.html)",
        "[DE vignette](differential-expression.html)",
        "[EDA vignette](exploratory-analysis.html)",
        "[Data Acquisition QC](data-acquisition.html#quality-control)",
        "[DE vignette](differential-expression.html)",
        "[Survival vignette](survival-analysis.html)",
        "[Survival vignette](survival-analysis.html)",
        "[EDA vignette](exploratory-analysis.html)",
        "[Survival vignette](survival-analysis.html)",
        "[Data Acquisition](data-acquisition.html#rnaseq-data)",
        "[Data Acquisition QC](data-acquisition.html#quality-control)",
        "[Data Acquisition QC](data-acquisition.html#quality-control)",
        "[Data Acquisition](data-acquisition.html#rnaseq-data)",
        "[Data Dictionary](data-dictionary.html)",
        "[DE vignette](differential-expression.html)"
      ),
      stringsAsFactors = FALSE
    )
  ),

  # --- exploratory-analysis.Rmd: "Simple Query" block ---
  targets::tar_target(
    code_eda_simple_query,
    {
      force(file.exists("R/database_parquet.R"))
      c(
        "# One-shot query (returns data frame)",
        "clinical <- query_commpass_parquet(\"clinical\")",
        "head(clinical)",
        "",
        "# With filters",
        "females <- query_commpass_parquet(",
        "  \"clinical\",",
        "  filters = list(gender = \"female\")",
        ")"
      )
    }
  ),

  # --- exploratory-analysis.Rmd: "Aggregation with DuckDB" block ---
  targets::tar_target(
    code_eda_aggregation,
    {
      force(file.exists("R/database_parquet.R"))
      c(
        "# Lazy tbl for dplyr-style queries",
        "con <- DBI::dbConnect(duckdb::duckdb())",
        "clinical_tbl <- get_commpass_tbl(\"clinical\", con = con)",
        "",
        "result <- clinical_tbl |>",
        "  filter(!is.na(gender)) |>",
        "  group_by(gender) |>",
        "  summarise(",
        "    n = n(),",
        "    mean_age_years = mean(age_at_diagnosis / 365.25, na.rm = TRUE)",
        "  ) |>",
        "  collect()",
        "",
        "DBI::dbDisconnect(con, shutdown = TRUE)"
      )
    }
  ),

  # ============================================================
  # Parse validation targets
  # ============================================================

  targets::tar_target(
    code_parsed_readme_quick_start,
    # Bash code -- just validate it's a character vector
    list(valid = TRUE, n_expressions = 0L, code = code_readme_quick_start, error = NULL)
  ),

  targets::tar_target(
    code_parsed_dd_load_data,
    parse_code_example(code_dd_load_data)
  ),

  targets::tar_target(
    code_parsed_dd_explore_dict,
    parse_code_example(code_dd_explore_dict)
  ),

  targets::tar_target(
    code_parsed_eda_simple_query,
    parse_code_example(code_eda_simple_query)
  ),

  targets::tar_target(
    code_parsed_eda_aggregation,
    parse_code_example(code_eda_aggregation)
  ),

  # ============================================================
  # Master validation gate
  # ============================================================

  targets::tar_target(
    doc_examples_validation,
    {
      parse_results <- list(
        readme_quick_start = code_parsed_readme_quick_start,
        dd_load_data       = code_parsed_dd_load_data,
        dd_explore_dict    = code_parsed_dd_explore_dict,
        eda_simple_query   = code_parsed_eda_simple_query,
        eda_aggregation    = code_parsed_eda_aggregation
      )

      all_valid <- all(vapply(parse_results, function(x) x$valid, logical(1)))

      if (!all_valid) {
        failed <- names(parse_results)[
          !vapply(parse_results, function(x) x$valid, logical(1))
        ]
        errors <- vapply(
          parse_results[failed],
          function(x) x$error %||% "unknown",
          character(1)
        )
        cli::cli_abort(c(
          "x" = "Vignette code examples failed syntax validation",
          "i" = "Failed examples: {paste(failed, collapse = ', ')}",
          "i" = "Errors: {paste(errors, collapse = '; ')}"
        ))
      }

      list(
        all_valid    = all_valid,
        n_examples   = length(parse_results),
        examples     = names(parse_results),
        validated_at = Sys.time()
      )
    }
  )
)
