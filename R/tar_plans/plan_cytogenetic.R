# R/tar_plans/plan_cytogenetic.R
# Cytogenetic data extraction and integration targets

plan_cytogenetic <- list(
  # Extract cytogenetic markers from clinical data
  tar_target(
    cytogenetic_data,
    extract_cytogenetic_data(
      clinical_dir = file.path(config$data_dir, "raw", "clinical")
    ),
    format = "file"
  )
)
