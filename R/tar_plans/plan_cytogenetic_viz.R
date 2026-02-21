# R/tar_plans/plan_cytogenetic_viz.R
# Targets for cytogenetic landscape visualization

plan_cytogenetic_viz <- list(
  # Read cytogenetic parquet into data frame for visualization
  targets::tar_target(
    cyto_viz_data,
    {
      cyto_file <- cytogenetic_data
      if (!file.exists(cyto_file)) return(NULL)
      arrow::read_parquet(cyto_file)
    }
  ),

  # Alteration frequency summary
  targets::tar_target(
    cyto_frequency_summary,
    summarize_cytogenetics(cyto_viz_data)
  ),

  # Pairwise co-occurrence statistics
  targets::tar_target(
    cyto_cooccurrence,
    calculate_cooccurrence(cyto_viz_data)
  )
)
