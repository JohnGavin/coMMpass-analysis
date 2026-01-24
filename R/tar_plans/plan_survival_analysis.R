# R/tar_plans/plan_survival_analysis.R
# Survival analysis targets

plan_survival_analysis <- list(
  # Prepare survival data
  tar_target(
    survival_data,
    prepare_survival_data(
      clinical_data,
      normalized_data
    )
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