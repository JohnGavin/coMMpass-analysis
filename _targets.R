library(targets)
library(tarchetypes)

# Source only package R files (not R/dev/ scripts)
tar_source(files = "R/data_access.R")

# Pipeline Configuration
tar_option_set(
  packages = c("TCGAbiolinks", "dplyr", "readr", "logger"),
  format = "rds"
)

# Pipeline Definition
list(
  # 1. Metadata from GDC
  tar_target(
    gdc_rna_query,
    query_commpass_rna()
  ),
  
  tar_target(
    gdc_rna_metadata,
    TCGAbiolinks::getResults(gdc_rna_query)
  ),
  
  tar_target(
    clinical_data,
    get_commpass_clinical()
  ),
  
  # 2. S3 File Manifest & Sample Download
  tar_target(
    s3_manifest,
    list_s3_commpass()
  ),
  
  tar_target(
    rna_sample_files,
    download_s3_subset(s3_manifest, n = 3),
    format = "file"
  )
)