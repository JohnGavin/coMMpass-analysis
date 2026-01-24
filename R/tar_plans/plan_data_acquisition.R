# R/tar_plans/plan_data_acquisition.R
# Data acquisition targets for CoMMpass pipeline

plan_data_acquisition <- list(
  # Configuration
  tar_target(
    config,
    list(
      project_id = "MMRF-COMMPASS",
      sample_limit = 10,  # Start small for testing
      data_dir = "data",
      results_dir = "results",
      seed = 42,
      use_example = TRUE  # Set to TRUE to use example data, FALSE for real data
    )
  ),

  # RNA-seq data - either from example or GDC
  tar_target(
    raw_rnaseq,
    {
      if (config$use_example) {
        # Load example data
        example_data <- load_example_data()
        # Convert to format expected by pipeline
        list(
          assays = example_data$assays,
          metadata = example_data$metadata
        )
      } else {
        download_gdc_rnaseq(
          project_id = config$project_id,
          data_dir = file.path(config$data_dir, "raw", "gdc"),
          sample_limit = config$sample_limit
        )
      }
    },
    cue = tar_cue(mode = "never")  # Don't re-download
  ),

  # Clinical data - either from example or GDC
  tar_target(
    clinical_data,
    {
      if (config$use_example) {
        # Load example clinical data
        example_data <- load_example_data()
        list(
          clinical = example_data$colData,
          biospecimen = data.frame()  # Empty for example
        )
      } else {
        download_clinical_data(
          project_id = config$project_id,
          data_dir = file.path(config$data_dir, "raw", "clinical")
        )
      }
    },
    cue = tar_cue(mode = "never")
  )
)