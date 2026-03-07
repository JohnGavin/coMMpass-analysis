# R/tar_plans/plan_treatment.R
# Treatment/regimen data cleaning pipeline plan
# Function definitions are in R/treatment_data.R

plan_treatment <- list(
  # Clean and standardize treatment data
  tar_target(
    treatment_data_clean,
    {
      trt_file <- file.path(clinical_data, "treatment_data.parquet")
      if (file.exists(trt_file)) {
        clean_treatment_data(arrow::read_parquet(trt_file))
      } else {
        NULL
      }
    },
    packages = c("arrow")
  ),

  # One-row-per-patient treatment summary
  tar_target(
    treatment_summary,
    summarize_treatment(treatment_data_clean)
  )
)
