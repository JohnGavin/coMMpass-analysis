# R/tar_plans/plan_quality_control.R
# Quality control and normalization targets

plan_quality_control <- list(
  # QC metrics
  tar_target(
    qc_metrics,
    calculate_qc_metrics(raw_rnaseq)
  ),

  # Filter low quality samples and genes
  tar_target(
    filtered_data,
    filter_low_quality(
      raw_rnaseq,
      min_counts = 10,
      min_samples = 3
    )
  ),

  # Normalize data
  tar_target(
    normalized_data,
    normalize_rnaseq(filtered_data)
  )
)