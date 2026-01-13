# Session Log: 01_data_acquisition.R
# Focus: Open Access data from GDC and AWS S3
# Date: 2026-01-13

library(logger)
library(dplyr)

log_threshold(INFO)
log_info("Starting Data Acquisition session (Open Access only)")

# 1. Verify AWS S3 Connectivity (R Package)
log_info("Testing aws.s3 package connectivity...")
tryCatch({
  library(aws.s3)
  s3_list <- get_bucket_df(
    bucket = "gdc-mmrf-commpass-phs000748-2-open",
    region = "us-east-1",
    max = 10,
    use_https = TRUE
  )
  log_info("aws.s3 Successful. Found {nrow(s3_list)} objects in sample.")
}, error = function(e) {
  log_error("aws.s3 Failed: {e$message}")
})

# 2. Verify GDC Connectivity (TCGAbiolinks)
log_info("Testing TCGAbiolinks package (CAUTION: possible segfault)...")
tryCatch({
  # We use a separate process or very careful load if it segfaults
  library(TCGAbiolinks)
  query_gdc <- GDCquery(
    project = "MMRF-COMMPASS",
    data.category = "Transcriptome Profiling",
    data.type = "Gene Expression Quantification",
    workflow.type = "STAR - Counts"
  )
  log_info("TCGAbiolinks Successful. Found {nrow(getResults(query_gdc))} files.")
}, error = function(e) {
  log_error("TCGAbiolinks Failed: {e$message}")
})