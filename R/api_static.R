# R/api_static.R
# Static JSON API generation for Phase 1 (GitHub Pages).
# Generates pre-computed JSON files served via
# https://JohnGavin.github.io/coMMpass-analysis/api/v1/

#' Generate API index metadata
#'
#' Creates the index.json content listing all available endpoints,
#' their descriptions, and URLs for the static JSON API.
#'
#' @param base_url Base URL for the static API. Defaults to the GitHub
#'   Pages URL.
#' @return A list suitable for JSON serialization containing endpoint
#'   catalogue, version, and generated timestamp.
#' @family api
#' @export
#' @examples
#' \dontrun{
#' idx <- generate_api_index()
#' cat(jsonlite::toJSON(idx, pretty = TRUE, auto_unbox = TRUE))
#' }
generate_api_index <- function(
    base_url = "https://JohnGavin.github.io/coMMpass-analysis/api/v1") {
  if (!is.character(base_url) || length(base_url) != 1) {
    cli::cli_abort("{.arg base_url} must be a single character string")
  }

  endpoints <- data.frame(
    name = c("clinical", "de-results", "survival", "pathways",
             "cytogenetics", "data-dictionary"),
    url = paste0(base_url, "/", c(
      "clinical.json", "de-results.json", "survival.json",
      "pathways.json", "cytogenetics.json", "data-dictionary.json"
    )),
    description = c(
      "Clinical data for CoMMpass patients",
      "Differential expression results (DESeq2)",
      "Prepared survival data with covariates",
      "GSEA pathway analysis results",
      "Cytogenetic marker status and risk classification",
      "Variable metadata and data dictionary"
    ),
    stringsAsFactors = FALSE
  )

  list(
    api = "CoMMpass Static API",
    version = as.character(utils::packageVersion("coMMpass")),
    generated = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    base_url = base_url,
    endpoints = endpoints,
    source = "https://github.com/JohnGavin/coMMpass",
    note = paste(
      "Static pre-computed data. Updated on each pipeline run.",
      "For raw data, visit the GDC portal:",
      "https://portal.gdc.cancer.gov/projects/MMRF-COMMPASS"
    )
  )
}

#' Generate a single API endpoint JSON string
#'
#' Wraps a data frame in standard API envelope with metadata and
#' serializes to JSON. Used by [plan_api] targets to produce static
#' JSON files.
#'
#' @param data A data frame to serialize, or NULL if data is unavailable
#' @param dataset_name Short name for this dataset (e.g. "clinical")
#' @param description Human-readable description
#' @return A JSON string (character scalar) with `metadata` and `data`
#'   fields
#' @family api
#' @export
#' @examples
#' \dontrun{
#' df <- data.frame(a = 1:3, b = letters[1:3])
#' json <- generate_api_endpoint(df, "example", "Example data")
#' cat(json)
#' }
generate_api_endpoint <- function(data, dataset_name, description) {
  if (!is.character(dataset_name) || length(dataset_name) != 1) {
    cli::cli_abort("{.arg dataset_name} must be a single character string")
  }

  if (!is.character(description) || length(description) != 1) {
    cli::cli_abort("{.arg description} must be a single character string")
  }

  if (is.null(data) || (is.data.frame(data) && nrow(data) == 0)) {
    envelope <- list(
      metadata = list(
        dataset = dataset_name,
        description = description,
        n_rows = 0L,
        n_cols = 0L,
        generated = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
        note = "Data not available in current pipeline run"
      ),
      data = NULL
    )
  } else {
    envelope <- list(
      metadata = list(
        dataset = dataset_name,
        description = description,
        n_rows = nrow(data),
        n_cols = ncol(data),
        columns = names(data),
        generated = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
      ),
      data = data
    )
  }

  jsonlite::toJSON(
    envelope,
    pretty = TRUE,
    auto_unbox = TRUE,
    POSIXt = "ISO8601",
    Date = "ISO8601",
    na = "null"
  )
}
