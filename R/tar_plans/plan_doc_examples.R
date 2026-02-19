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
        dd_load_data      = code_parsed_dd_load_data,
        dd_explore_dict   = code_parsed_dd_explore_dict,
        eda_simple_query  = code_parsed_eda_simple_query,
        eda_aggregation   = code_parsed_eda_aggregation
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
