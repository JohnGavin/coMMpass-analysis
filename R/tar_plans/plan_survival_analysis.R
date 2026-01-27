# R/tar_plans/plan_survival_analysis.R
# Survival analysis targets

plan_survival_analysis <- list(
  # Prepare survival data
  tar_target(
    survival_data,
    {
      # Load clinical data from file
      clinical_df <- if (!is.null(clinical_data) && is.character(clinical_data)) {
        clinical_file <- file.path(clinical_data, "clinical_data.rds")
        if (file.exists(clinical_file)) {
          readRDS(clinical_file)
        } else {
          clinical_csv <- file.path(clinical_data, "clinical_data.csv")
          if (file.exists(clinical_csv)) {
            read.csv(clinical_csv, stringsAsFactors = FALSE)
          } else {
            NULL
          }
        }
      } else {
        NULL
      }

      # Use normalized_data directly as it's already processed
      prepare_survival_data(clinical_df, normalized_data)
    }
  ),

  # Kaplan-Meier analysis
  tar_target(
    km_analysis,
    run_kaplan_meier(
      survival_data,
      group_by = "risk_group"
    )
  ),

  # Cox regression
  tar_target(
    cox_model,
    run_cox_regression(
      survival_data,
      covariates = c("age", "stage", "gene_signature")
    )
  ),

  # Survival report
  tar_target(
    survival_report,
    render_survival_report(
      km_analysis,
      cox_model,
      output_dir = config$results_dir
    ),
    format = "file"
  )
)