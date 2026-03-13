# R/tar_plans/plan_data_acquisition.R
# Data acquisition targets for CoMMpass pipeline

plan_data_acquisition <- list(
  # Configuration
  tar_target(
    config,
    list(
      project_id = "MMRF-COMMPASS",
      sample_limit = 200,  # 200 patients for robust DE/survival analysis
      data_dir = "data",
      results_dir = "results",
      seed = 42
    )
  ),

  # RNA-seq data from GDC
  tar_target(
    raw_rnaseq,
    download_gdc_rnaseq(
      project_id = config$project_id,
      data_dir = file.path(config$data_dir, "raw", "gdc"),
      sample_limit = config$sample_limit
    ),
    packages = c("TCGAbiolinks", "SummarizedExperiment"),
    cue = tar_cue(mode = "never")  # Don't re-download
  ),

  # Clinical data
  tar_target(
    clinical_data,
    download_clinical_data(
      project_id = config$project_id,
      data_dir = file.path(config$data_dir, "raw", "clinical")
    ),
    packages = c("TCGAbiolinks"),
    cue = tar_cue(mode = "never")
  )
)