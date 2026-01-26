# _targets.R
# Main orchestrator for CoMMpass analysis pipeline
# Sources modular plans from R/tar_plans/
library(targets)
library(tarchetypes)
library(crew)

# Set global options
tar_option_set(
  packages = c(
    "TCGAbiolinks", "GenomicDataCommons", "SummarizedExperiment",
    "DESeq2", "edgeR", "limma",
    "survival",  # survminer removed - not available in nixpkgs
    "tidyverse", "logger"
  ),
  format = "rds",  # Fast serialization
  memory = "transient",  # Free memory after use
  garbage_collection = TRUE,
  controller = crew_controller_local(
    workers = 4,  # Parallel workers
    seconds_idle = 60
  )
)

# Source analysis functions (excluding R/dev/ and R/tar_plans/)
for (file in list.files("R", pattern = "\\.(R|r)$", full.names = TRUE)) {
  if (!grepl("R/(dev|tar_plans)/", file)) {
    source(file)
  }
}

# Source modular target plans from R/tar_plans/
plan_files <- list.files("R/tar_plans", pattern = "^plan_.*\\.R$", full.names = TRUE)
for (plan_file in plan_files) {
  source(plan_file)
}

# Combine all plans into main pipeline
c(
  plan_data_acquisition,
  plan_data_cleaning,  # New: Clean and integrate data
  plan_quality_control,
  plan_differential_expression,
  plan_survival_analysis,
  plan_pathway_analysis
)