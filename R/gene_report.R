# R/gene_report.R
# Parameterized single-gene report rendering

#' Render a single-gene characterization report
#'
#' Renders the parameterized `gene-report.qmd` vignette for a specific gene,
#' producing a self-contained HTML report with expression distribution,
#' survival stratification, cytogenetic context, and gene-gene correlations.
#'
#' @param gene Gene name (e.g., "CD70", "TP53")
#' @param output_dir Directory for the rendered report (default "results/gene_reports/")
#' @param vst_matrix Optional pre-loaded VST matrix (genes x samples). If NULL,
#'   the function attempts to load from the targets store.
#' @param surv_data Optional pre-loaded survival data frame. If NULL,
#'   attempts to load from the targets store.
#' @param cyto_data Optional pre-loaded cytogenetic data frame
#' @return Path to the rendered HTML file (invisibly)
#' @family utilities
#' @export
#' @examples
#' \dontrun{
#' gene_report("CD70")
#' gene_report("TP53", output_dir = "results/")
#' }
gene_report <- function(gene,
                         output_dir = "results/gene_reports",
                         vst_matrix = NULL,
                         surv_data = NULL,
                         cyto_data = NULL) {
  if (!requireNamespace("quarto", quietly = TRUE)) {
    cli::cli_abort(c(
      "x" = "Package {.pkg quarto} is required to render gene reports",
      "i" = "Install quarto CLI: https://quarto.org/docs/get-started/"
    ))
  }

  # Find the vignette template
  template <- system.file("vignettes", "gene-report.qmd",
                           package = "coMMpass")
  if (!nzchar(template)) {
    # Try local dev path
    template <- file.path("vignettes", "gene-report.qmd")
  }
  if (!file.exists(template)) {
    cli::cli_abort(c(
      "x" = "Template {.file gene-report.qmd} not found",
      "i" = "Ensure the coMMpass package is installed or run from project root"
    ))
  }

  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  output_file <- file.path(output_dir,
                            paste0("gene_report_", gene, ".html"))

  logger::log_info("Rendering gene report for {gene}")

  quarto::quarto_render(
    input = template,
    output_file = basename(output_file),
    execute_params = list(gene = gene),
    execute_dir = getwd()
  )

  # Move to output_dir if rendered elsewhere
  rendered <- file.path(dirname(template),
                         paste0("gene_report_", gene, ".html"))
  if (file.exists(rendered) && !file.exists(output_file)) {
    file.copy(rendered, output_file, overwrite = TRUE)
    file.remove(rendered)
  }

  logger::log_info("Gene report saved to {output_file}")
  invisible(output_file)
}
