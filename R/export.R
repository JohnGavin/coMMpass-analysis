# R/export.R
# Data export utilities for interoperability

#' Export SummarizedExperiment to H5AD (AnnData) format
#'
#' Converts a [SummarizedExperiment::SummarizedExperiment] to AnnData format
#' and writes an H5AD file for Python/scanpy interoperability.
#'
#' @param se A [SummarizedExperiment::SummarizedExperiment] object
#' @param output_path Path for the output .h5ad file
#' @param assay_name Which assay to export (default "unstranded", falls back
#'   to "counts" then first available)
#' @return The output path (invisibly)
#' @family utilities
#' @export
#' @examples
#' \dontrun{
#' d <- example_data()
#' export_h5ad(d$rnaseq_se, "commpass.h5ad")
#' }
export_h5ad <- function(se, output_path, assay_name = NULL) {
  # Validate input before checking optional dependency
  if (is.null(se) || !inherits(se, "SummarizedExperiment")) {
    cli::cli_abort(c(
      "x" = "{.arg se} must be a SummarizedExperiment object",
      "i" = "Use {.fn example_data} to get an example SE"
    ))
  }

  if (!requireNamespace("anndataR", quietly = TRUE)) {
    cli::cli_abort(c(
      "x" = "Package {.pkg anndataR} is required for H5AD export",
      "i" = "Add {.pkg anndataR} to your Nix environment or install from Bioconductor"
    ))
  }

  # Select assay
  available <- SummarizedExperiment::assayNames(se)
  if (is.null(assay_name)) {
    priority <- c("unstranded", "counts")
    assay_name <- intersect(priority, available)[1]
    if (is.na(assay_name)) assay_name <- available[1]
  }
  if (!assay_name %in% available) {
    cli::cli_abort(c(
      "x" = "Assay {.val {assay_name}} not found",
      "i" = "Available assays: {paste(available, collapse = ', ')}"
    ))
  }

  logger::log_info("Exporting assay '{assay_name}' to {output_path}")

  # Convert SE to SingleCellExperiment (required by anndataR::as_AnnData)
  sce <- as(se, "SingleCellExperiment")
  adata <- anndataR::as_AnnData(sce, x = assay_name)
  anndataR::write_h5ad(adata, output_path)

  logger::log_info(
    "Exported {nrow(se)} genes x {ncol(se)} samples to {output_path} ",
    "({round(file.size(output_path) / 1024, 1)} KB)"
  )

  invisible(output_path)
}
