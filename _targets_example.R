# _targets_example.R
# Test version of pipeline for example data (minimal dependencies)
# Use this file to test the pipeline without all packages installed
library(targets)
library(tarchetypes)

# Set global options - minimal packages for testing
tar_option_set(
  packages = c(
    "tidyverse", "logger"
  ),
  format = "rds",
  memory = "transient",
  garbage_collection = TRUE
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

# For testing, only use data acquisition and QC plans
c(
  plan_data_acquisition,
  plan_quality_control
)