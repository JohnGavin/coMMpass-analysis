# R/tar_plans/plan_quality_control.R
# Quality control and normalization targets

plan_quality_control <- list(
  # QC metrics
  tar_target(
    qc_metrics,
    {
      # Load the RNA-seq data from file
      rnaseq_file <- "data/raw/gdc/rnaseq_se.rds"
      if (file.exists(rnaseq_file)) {
        se_data <- readRDS(rnaseq_file)
        calculate_qc_metrics(se_data)
      } else {
        warning("RNA-seq data file not found")
        NULL
      }
    },
    packages = c("SummarizedExperiment")
  ),

  # Filter low quality samples and genes
  tar_target(
    filtered_data,
    {
      # Load the RNA-seq data from file
      rnaseq_file <- "data/raw/gdc/rnaseq_se.rds"
      if (file.exists(rnaseq_file)) {
        se_data <- readRDS(rnaseq_file)
        filter_low_quality(
          se_data,
          min_counts = 10,
          min_samples = 3
        )
      } else {
        warning("RNA-seq data file not found")
        NULL
      }
    },
    packages = c("SummarizedExperiment")
  ),

  # Normalize data
  tar_target(
    normalized_data,
    {
      # Use filtered data if available
      if (!is.null(filtered_data)) {
        normalize_rnaseq(filtered_data)
      } else {
        warning("No filtered data available for normalization")
        NULL
      }
    },
    packages = c("DESeq2", "edgeR")
  )
)