# R/10_api.R
# Plumber API helper functions for programmatic data access.
# Endpoints are defined in inst/plumber/plumber.R.
# This file contains the R functions that endpoints call.

#' List available API datasets
#'
#' Returns metadata about all datasets available through the API,
#' including data type, row/column counts, and download formats.
#'
#' @return A data frame with columns: dataset, description, format,
#'   n_rows, n_cols, last_updated
#' @family api
#' @export
#' @examples
#' \dontrun{
#' api_list_datasets()
#' }
api_list_datasets <- function() {
  datasets <- data.frame(
    dataset = c(
      "clinical", "biospecimen", "cytogenetics",
      "de_results", "survival_data", "pathway_results"
    ),
    description = c(
      "Clinical data for CoMMpass patients",
      "Biospecimen metadata",
      "Cytogenetic marker status and risk classification",
      "Differential expression results (DESeq2)",
      "Prepared survival data with covariates",
      "GSEA and ORA pathway analysis results"
    ),
    format = rep("json", 6),
    endpoint = c(
      "/data/clinical", "/data/biospecimen", "/data/cytogenetics",
      "/data/de_results", "/data/survival", "/data/pathways"
    ),
    stringsAsFactors = FALSE
  )
  datasets
}

#' Get clinical data for API response
#'
#' Reads clinical data from the targets store and formats it for
#' API delivery. Optionally filters by patient IDs or variables.
#'
#' @param patient_ids Optional character vector of patient IDs to filter
#' @param variables Optional character vector of column names to select
#' @param store Path to targets store (default: "_targets")
#' @return A data frame of clinical data, or NULL if unavailable
#' @family api
#' @export
api_get_clinical <- function(patient_ids = NULL, variables = NULL,
                              store = "_targets") {
  if (!is.null(patient_ids) && !is.character(patient_ids)) {
    cli::cli_abort(c(
      "x" = "{.arg patient_ids} must be a character vector, not {.obj_type_friendly {patient_ids}}"
    ))
  }

  if (!is.null(variables) && !is.character(variables)) {
    cli::cli_abort(c(
      "x" = "{.arg variables} must be a character vector, not {.obj_type_friendly {variables}}"
    ))
  }

  if (!is.character(store) || length(store) != 1) {
    cli::cli_abort(c(
      "x" = "{.arg store} must be a single character string"
    ))
  }

  clin <- tryCatch(
    targets::tar_read("cleaned_clinical", store = store),
    error = function(e) NULL
  )
  if (is.null(clin)) return(NULL)

  if (!is.null(patient_ids)) {
    id_col <- intersect(c("submitter_id", "patient_id"), names(clin))
    if (length(id_col) > 0) {
      clin <- clin[clin[[id_col[1]]] %in% patient_ids, ]
    }
  }

  if (!is.null(variables)) {
    variables <- intersect(variables, names(clin))
    if (length(variables) > 0) clin <- clin[, variables, drop = FALSE]
  }

  clin
}

#' Get DE results for API response
#'
#' Reads differential expression results from the targets store.
#' Returns the DESeq2 results table with gene symbols.
#'
#' @param padj_threshold Filter to genes with padj below this threshold
#'   (default: 1, i.e., no filter)
#' @param lfc_threshold Filter to genes with absolute log2FC above this
#'   threshold (default: 0, i.e., no filter)
#' @param store Path to targets store
#' @return A data frame of DE results, or NULL if unavailable
#' @family api
#' @export
api_get_de_results <- function(padj_threshold = 1, lfc_threshold = 0,
                                store = "_targets") {
  if (!is.numeric(padj_threshold) || length(padj_threshold) != 1 ||
      is.na(padj_threshold)) {
    cli::cli_abort(c(
      "x" = "{.arg padj_threshold} must be a single numeric value, not {.obj_type_friendly {padj_threshold}}"
    ))
  }

  if (padj_threshold < 0 || padj_threshold > 1) {
    cli::cli_abort(c(
      "x" = "{.arg padj_threshold} must be between 0 and 1, not {padj_threshold}"
    ))
  }

  if (!is.numeric(lfc_threshold) || length(lfc_threshold) != 1 ||
      is.na(lfc_threshold)) {
    cli::cli_abort(c(
      "x" = "{.arg lfc_threshold} must be a single numeric value, not {.obj_type_friendly {lfc_threshold}}"
    ))
  }

  if (lfc_threshold < 0 || is.infinite(lfc_threshold)) {
    cli::cli_abort(c(
      "x" = "{.arg lfc_threshold} must be a non-negative finite number, not {lfc_threshold}"
    ))
  }

  if (!is.character(store) || length(store) != 1) {
    cli::cli_abort("{.arg store} must be a single character string")
  }

  de <- tryCatch(
    targets::tar_read("de_results_annotated", store = store),
    error = function(e) NULL
  )
  if (is.null(de)) return(NULL)

  padj_col <- intersect(c("padj", "FDR", "adj.P.Val"), names(de))
  lfc_col <- intersect(c("log2FoldChange", "logFC"), names(de))

  if (length(padj_col) > 0 && padj_threshold < 1) {
    keep <- !is.na(de[[padj_col[1]]]) & de[[padj_col[1]]] < padj_threshold
    de <- de[keep, ]
  }

  if (length(lfc_col) > 0 && lfc_threshold > 0) {
    keep <- abs(de[[lfc_col[1]]]) > lfc_threshold
    de <- de[keep, ]
  }

  de
}

#' Get survival data for API response
#'
#' Reads prepared survival data from the targets store.
#'
#' @param store Path to targets store
#' @return A data frame of survival data, or NULL if unavailable
#' @family api
#' @export
api_get_survival <- function(store = "_targets") {
  if (!is.character(store) || length(store) != 1) {
    cli::cli_abort("{.arg store} must be a single character string")
  }

  tryCatch(
    targets::tar_read("survival_data", store = store),
    error = function(e) NULL
  )
}

#' Get pathway analysis results for API response
#'
#' Reads GSEA results from the targets store.
#'
#' @param significant_only If TRUE, return only pathways with padj < 0.05
#' @param store Path to targets store
#' @return A data frame of pathway results, or NULL if unavailable
#' @family api
#' @export
api_get_pathways <- function(significant_only = FALSE, store = "_targets") {
  if (!is.logical(significant_only) || length(significant_only) != 1 ||
      is.na(significant_only)) {
    cli::cli_abort(c(
      "x" = "{.arg significant_only} must be TRUE or FALSE, not {.obj_type_friendly {significant_only}}"
    ))
  }

  if (!is.character(store) || length(store) != 1) {
    cli::cli_abort("{.arg store} must be a single character string")
  }

  gsea <- tryCatch(
    targets::tar_read("gsea_results", store = store),
    error = function(e) NULL
  )
  if (is.null(gsea) || is.null(gsea$results)) return(NULL)

  results <- gsea$results
  if (significant_only) {
    results <- results[results$padj < 0.05, ]
  }

  # Remove leadingEdge list column for JSON serialization
  results$leadingEdge <- NULL
  results
}

#' Launch the plumber API
#'
#' Starts the plumber API server for programmatic data access.
#' The API reads pre-computed results from the targets store.
#'
#' @param port Port number (default: 8080)
#' @param host Host address (default: "127.0.0.1")
#' @param store Path to targets store (default: "_targets")
#' @return Invisible NULL (starts server)
#' @family api
#' @export
#' @examples
#' \dontrun{
#' # Start the API server
#' api_serve(port = 8080)
#'
#' # Then query from R or curl:
#' # curl http://localhost:8080/datasets
#' # curl http://localhost:8080/data/clinical?variables=submitter_id,gender
#' }
api_serve <- function(port = 8080L, host = "127.0.0.1",
                       store = "_targets") {
  if (!is.numeric(port) || length(port) != 1 || is.na(port) ||
      port < 1 || port > 65535) {
    cli::cli_abort(c(
      "x" = "{.arg port} must be a single integer between 1 and 65535"
    ))
  }

  if (!is.character(host) || length(host) != 1) {
    cli::cli_abort("{.arg host} must be a single character string")
  }

  if (!is.character(store) || length(store) != 1) {
    cli::cli_abort("{.arg store} must be a single character string")
  }

  if (!requireNamespace("plumber", quietly = TRUE)) {
    cli::cli_abort(c(
      "x" = "Package {.pkg plumber} required but not installed",
      "i" = "Install with: install.packages('plumber')"
    ))
  }

  plumber_file <- system.file("plumber", "plumber.R",
                               package = "coMMpass")
  if (!nzchar(plumber_file)) {
    cli::cli_abort("Plumber definition file not found in package")
  }

  pr <- plumber::plumb(plumber_file)

  # Store the targets store path in plumber's environment
  pr$setApiSpec(function(spec) {
    spec$info$title <- "CoMMpass Analysis API"
    spec$info$description <- paste(
      "Programmatic access to MMRF CoMMpass analysis results.",
      "Data is pre-computed via a targets pipeline."
    )
    spec$info$version <- as.character(
      utils::packageVersion("coMMpass")
    )
    spec
  })

  cli::cli_alert_success("Starting CoMMpass API on {host}:{port}")
  cli::cli_alert_info("Swagger docs: http://{host}:{port}/__docs__/")
  pr$run(port = port, host = host)
}
