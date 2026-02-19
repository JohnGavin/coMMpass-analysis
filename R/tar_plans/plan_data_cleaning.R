# R/tar_plans/plan_data_cleaning.R
# Data cleaning and preprocessing pipeline plan
# Function definitions are in R/data_cleaning.R

plan_data_cleaning <- list(
  # Clean clinical data (clinical_data is a data frame from arrow::read_parquet)
  tar_target(
    clinical_data_clean,
    clean_clinical_data(arrow::read_parquet(file.path(clinical_data, "clinical_data.parquet"))),
    packages = c("arrow", "dplyr")
  ),

  # Clean expression data (raw_rnaseq is the file path to rnaseq_se.rds)
  tar_target(
    expression_data_clean,
    {
      se_data <- readRDS(raw_rnaseq)
      if (inherits(se_data, "SummarizedExperiment")) {
        # Try "unstranded" (GDC STAR-Counts), then "counts", then first assay
        assay_names <- SummarizedExperiment::assayNames(se_data)
        if ("unstranded" %in% assay_names) {
          expr_matrix <- SummarizedExperiment::assay(se_data, "unstranded")
        } else if ("counts" %in% assay_names) {
          expr_matrix <- SummarizedExperiment::assay(se_data, "counts")
        } else {
          expr_matrix <- SummarizedExperiment::assay(se_data, 1)
        }
        clean_expression_data(expr_matrix)
      } else {
        NULL
      }
    },
    packages = c("SummarizedExperiment")
  ),

  # Create integrated dataset
  tar_target(
    integrated_data,
    integrate_clinical_expression(clinical_data_clean, expression_data_clean)
  ),

  # Generate data quality report
  tar_target(
    data_quality_report,
    {
      report <- list(
        clinical = if (!is.null(clinical_data_clean)) {
          list(
            n_patients = nrow(clinical_data_clean),
            n_variables = ncol(clinical_data_clean),
            completeness = mean(!is.na(clinical_data_clean)),
            key_variables = intersect(
              c("submitter_id", "gender", "age_at_diagnosis_years", "vital_status"),
              names(clinical_data_clean)
            )
          )
        } else NULL,
        expression = if (!is.null(expression_data_clean)) {
          list(
            n_genes = attr(expression_data_clean, "n_genes"),
            n_samples = attr(expression_data_clean, "n_samples"),
            percent_zeros = attr(expression_data_clean, "percent_zeros")
          )
        } else NULL,
        integration = if (!is.null(integrated_data)) {
          list(
            n_matched = integrated_data$n_matched,
            n_clinical_only = integrated_data$n_clinical_only,
            n_expression_only = integrated_data$n_expression_only
          )
        } else NULL
      )
      report
    }
  )
)
