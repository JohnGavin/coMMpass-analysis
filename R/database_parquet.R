# R/database_parquet.R
# DuckDB-backed parquet querying for CoMMpass data

#' Query CoMMpass Parquet Files
#'
#' Opens an in-memory DuckDB connection, creates a VIEW on the specified
#' parquet file, optionally applies filters, and returns a data frame.
#'
#' @param data_type One of "clinical", "biospecimen", "rnaseq_counts",
#'   "rnaseq_sample_metadata", "rnaseq_gene_metadata"
#' @param data_dir Base directory containing parquet files
#' @param filters Optional named list of filters. Names are column names,
#'   values are vectors of allowed values (used in WHERE ... IN (...))
#' @param collect If TRUE (default), collect results into a data frame.
#'   If FALSE, return a lazy tbl for further dplyr operations.
#' @return A data frame (if collect=TRUE) or lazy dbplyr tbl
#' @family storage
#' @export
#' @examples
#' \dontrun{
#' # Read all clinical data
#' clinical <- query_commpass_parquet("clinical")
#'
#' # Filter to specific patients
#' subset <- query_commpass_parquet(
#'   "clinical",
#'   filters = list(gender = "female", vital_status = "Alive")
#' )
#'
#' # Get lazy tbl for chaining
#' tbl <- query_commpass_parquet("clinical", collect = FALSE)
#' result <- tbl |> dplyr::filter(gender == "female") |> dplyr::collect()
#' }
query_commpass_parquet <- function(
  data_type = c("clinical", "biospecimen", "rnaseq_counts",
                "rnaseq_sample_metadata", "rnaseq_gene_metadata"),
  data_dir = "data/raw",
  filters = NULL,
  collect = TRUE
) {
  data_type <- match.arg(data_type)

  parquet_file <- resolve_parquet_path(data_type, data_dir)

  if (!file.exists(parquet_file)) {
    cli::cli_abort(c(
      "x" = "Parquet file not found: {.file {parquet_file}}",
      "i" = "Run {.fn download_clinical_data} or {.fn download_gdc_rnaseq} first."
    ))
  }

  con <- DBI::dbConnect(duckdb::duckdb(), dbdir = ":memory:")
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)

  # Register parquet file as a view
  DBI::dbExecute(con, glue::glue(
    "CREATE VIEW data_view AS SELECT * FROM read_parquet('{parquet_file}')"
  ))

  tbl <- dplyr::tbl(con, "data_view")

  # Apply filters if provided
  if (!is.null(filters) && length(filters) > 0) {
    for (col_name in names(filters)) {
      filter_vals <- filters[[col_name]]
      tbl <- dplyr::filter(tbl, .data[[col_name]] %in% filter_vals)
    }
  }

  if (collect) {
    return(dplyr::collect(tbl))
  }

  # For non-collected return, we need to keep the connection alive
  # Return collected since lazy tbl would lose connection on exit
  cli::cli_alert_warning(
    "Returning collected data (DuckDB connection is ephemeral). Use {.fn get_commpass_tbl} for persistent lazy queries."
  )
  dplyr::collect(tbl)
}

#' Get Lazy DuckDB Table for CoMMpass Data
#'
#' Returns a lazy `dplyr::tbl()` backed by DuckDB, reading from parquet files.
#' The connection is managed by the caller and must be disconnected when done.
#'
#' @param data_type One of "clinical", "biospecimen", "rnaseq_counts",
#'   "rnaseq_sample_metadata", "rnaseq_gene_metadata"
#' @param data_dir Base directory containing parquet files
#' @param con An existing DuckDB connection. If NULL, a new in-memory connection
#'   is created and returned as an attribute of the result.
#' @return A lazy dbplyr tbl. If con was NULL, the DuckDB connection is stored
#'   as attr(result, "connection") - caller must disconnect it.
#' @family storage
#' @export
#' @examples
#' \dontrun{
#' # Create connection and query
#' con <- DBI::dbConnect(duckdb::duckdb())
#' clinical_tbl <- get_commpass_tbl("clinical", con = con)
#'
#' # Chain dplyr operations (lazy - not executed until collect)
#' result <- clinical_tbl |>
#'   dplyr::filter(gender == "female") |>
#'   dplyr::select(submitter_id, age_at_diagnosis, vital_status) |>
#'   dplyr::collect()
#'
#' # Clean up
#' DBI::dbDisconnect(con, shutdown = TRUE)
#' }
get_commpass_tbl <- function(
  data_type = c("clinical", "biospecimen", "rnaseq_counts",
                "rnaseq_sample_metadata", "rnaseq_gene_metadata"),
  data_dir = "data/raw",
  con = NULL
) {
  data_type <- match.arg(data_type)

  parquet_file <- resolve_parquet_path(data_type, data_dir)

  if (!file.exists(parquet_file)) {
    cli::cli_abort(c(
      "x" = "Parquet file not found: {.file {parquet_file}}",
      "i" = "Run {.fn download_clinical_data} or {.fn download_gdc_rnaseq} first."
    ))
  }

  own_con <- is.null(con)
  if (own_con) {
    con <- DBI::dbConnect(duckdb::duckdb(), dbdir = ":memory:")
  }

  view_name <- paste0(data_type, "_view")
  DBI::dbExecute(con, glue::glue(
    "CREATE OR REPLACE VIEW {view_name} AS SELECT * FROM read_parquet('{parquet_file}')"
  ))

  result <- dplyr::tbl(con, view_name)

  if (own_con) {
    attr(result, "connection") <- con
    cli::cli_alert_info(
      "Connection stored as attr(result, 'connection'). Remember to disconnect."
    )
  }

  result
}

#' Resolve Parquet File Path
#'
#' Maps data_type to the actual parquet file path within the data directory.
#'
#' @param data_type Data type identifier
#' @param data_dir Base data directory
#' @return Character path to parquet file
#' @keywords internal
resolve_parquet_path <- function(data_type, data_dir) {
  paths <- list(
    clinical = file.path(data_dir, "clinical", "clinical_data.parquet"),
    biospecimen = file.path(data_dir, "clinical", "biospecimen_data.parquet"),
    rnaseq_counts = file.path(data_dir, "gdc", "rnaseq_counts.parquet"),
    rnaseq_sample_metadata = file.path(data_dir, "gdc", "rnaseq_sample_metadata.parquet"),
    rnaseq_gene_metadata = file.path(data_dir, "gdc", "rnaseq_gene_metadata.parquet")
  )
  paths[[data_type]]
}
