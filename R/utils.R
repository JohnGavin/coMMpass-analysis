# R/utils.R
# Utility functions for CoMMpass analysis

#' Setup logging
setup_logging <- function(log_file = NULL) {
  library(logger)
  
  if (!is.null(log_file)) {
    log_appender(appender_file(log_file))
  }
  
  log_threshold(INFO)
  log_info("Logging initialized")
}

#' Create project directories
create_project_dirs <- function(base_dir = ".") {
  dirs <- c(
    "data/raw/gdc",
    "data/raw/aws",
    "data/raw/clinical",
    "data/processed",
    "results/figures",
    "results/tables",
    "results/reports",
    "logs"
  )
  
  for (dir in dirs) {
    dir_path <- file.path(base_dir, dir)
    dir.create(dir_path, recursive = TRUE, showWarnings = FALSE)
  }
  
  logger::log_info("Project directories created")
}

#' Save results with timestamp
save_timestamped <- function(object, base_name, dir = "results") {
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  filename <- paste0(base_name, "_", timestamp, ".rds")
  filepath <- file.path(dir, filename)
  
  saveRDS(object, filepath)
  logger::log_info("Saved {base_name} to {filepath}")
  
  return(filepath)
}

#' Generate summary statistics
summarize_data <- function(se_data) {
  library(SummarizedExperiment)
  
  counts <- assay(se_data, "counts")
  
  summary_stats <- list(
    n_samples = ncol(counts),
    n_genes = nrow(counts),
    total_counts = sum(counts),
    median_counts_per_sample = median(colSums(counts)),
    median_genes_detected = median(colSums(counts > 0)),
    sparsity = mean(counts == 0)
  )
  
  return(summary_stats)
}

#' Check package dependencies
check_dependencies <- function() {
  required_pkgs <- c(
    "TCGAbiolinks", "GenomicDataCommons", "SummarizedExperiment",
    "DESeq2", "edgeR", "limma",
    "survival", "survminer",
    "targets", "crew",
    "tidyverse", "logger"
  )
  
  missing_pkgs <- required_pkgs[!required_pkgs %in% installed.packages()[, "Package"]]
  
  if (length(missing_pkgs) > 0) {
    warning("Missing packages: ", paste(missing_pkgs, collapse = ", "))
    return(FALSE)
  }
  
  message("All required packages are installed")
  return(TRUE)
}
