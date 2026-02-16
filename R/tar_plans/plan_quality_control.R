# R/tar_plans/plan_quality_control.R
# Quality control and normalization targets

plan_quality_control <- list(
  # QC metrics (raw_rnaseq is the file path to rnaseq_se.rds)
  tar_target(
    qc_metrics,
    {
      se_data <- readRDS(raw_rnaseq)
      calculate_qc_metrics(se_data)
    },
    packages = c("SummarizedExperiment")
  ),

  # Filter low quality samples and genes
  tar_target(
    filtered_data,
    {
      se_data <- readRDS(raw_rnaseq)
      filter_low_quality(
        se_data,
        min_counts = 10,
        min_samples = 3
      )
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