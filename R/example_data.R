#' Load example coMMpass datasets
#'
#' Returns small synthetic datasets for interactive exploration and testing.
#' The data exercises the full pipeline: QC, cleaning, survival analysis, and
#' cytogenetic classification.
#'
#' The SummarizedExperiment is reconstructed at load time from stored plain-R
#' components (matrix + data.frames), so the RDS files have no S4 class
#' dependency.
#'
#' @return A named list with three elements:
#' \describe{
#'   \item{rnaseq_se}{A [SummarizedExperiment::SummarizedExperiment] with
#'     50 genes x 20 samples. Assay named `"unstranded"` (matches GDC format).
#'     rowData contains `gene_id` (Ensembl-format with version suffix) and
#'     `gene_type`. colData contains `submitter_id` and `sample_type`.}
#'   \item{clinical}{A data.frame (20 patients) with columns `submitter_id`,
#'     `vital_status`, `days_to_death`, `days_to_last_follow_up`,
#'     `age_at_diagnosis` (in days), `gender`, `iss_stage`,
#'     `heavy_chain` (myeloma isotype), `light_chain` (Kappa/Lambda),
#'     `ecog_status` (0-4), `ldh` (U/L), `b2m` (beta-2 microglobulin, mg/L),
#'     `albumin` (g/dL), `flc_kappa` (free kappa light chain, mg/L),
#'     `flc_lambda` (free lambda light chain, mg/L), `hemoglobin` (g/dL),
#'     `creatinine` (mg/dL), `calcium` (corrected, mg/dL),
#'     `platelets` (10^9/L).}
#'   \item{cytogenetic}{A data.frame (20 patients) with columns `patient_id`,
#'     `t_4_14`, `t_11_14`, `t_14_16`, `del_17p`, `gain_1q`, `risk_group`.}
#'   \item{treatment}{A data.frame of treatment lines (1-3 per patient) with
#'     columns `patient_id`, `treatment_line`, `regimen_name`, `regimen_class`,
#'     `best_response` (ordered factor), `stem_cell_transplant` (logical),
#'     `treatment_start_days` (integer).}
#' }
#'
#' @family utilities
#' @export
#' @examples
#' d <- example_data()
#' # QC metrics
#' qc <- calculate_qc_metrics(d$rnaseq_se)
#' head(qc)
#'
#' # Clinical cleaning
#' clin <- clean_clinical_data(d$clinical)
#'
#' # Survival data with cytogenetic markers
#' surv <- prepare_survival_data(d$clinical, cyto_file = d$cytogenetic)
example_data <- function() {
  load_example <- function(filename) {
    path <- system.file("extdata", "example", filename, package = "coMMpass")
    if (!nzchar(path)) {
      cli::cli_abort(c(
        "x" = "Example file {.file {filename}} not found",
        "i" = "Reinstall the coMMpass package to restore example data"
      ))
    }
    readRDS(path)
  }

  # SE stored as plain-R components to avoid S4 serialisation issues
  se_parts <- load_example("rnaseq_se.rds")
  rnaseq_se <- SummarizedExperiment::SummarizedExperiment(
    assays = list(unstranded = se_parts$counts),
    rowData = S4Vectors::DataFrame(se_parts$rowData),
    colData = S4Vectors::DataFrame(se_parts$colData)
  )

  # Treatment data (cleaned from raw example)
  trt_raw <- load_example("treatment.rds")
  treatment <- clean_treatment_data(trt_raw)

  list(
    rnaseq_se = rnaseq_se,
    clinical = load_example("clinical.rds"),
    cytogenetic = load_example("cytogenetic.rds"),
    treatment = treatment
  )
}
