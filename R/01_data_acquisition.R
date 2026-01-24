# R/01_data_acquisition.R
# Data acquisition functions for CoMMpass analysis
# Downloads RNA-seq and clinical data from GDC/AWS

#' Download RNA-seq data from GDC
#' @param project_id Project identifier (default: "MMRF-COMMPASS")
#' @param data_dir Directory to save data
#' @param sample_limit Maximum number of samples (NULL for all)
download_gdc_rnaseq <- function(
  project_id = "MMRF-COMMPASS",
  data_dir = "data/raw/gdc",
  sample_limit = NULL
) {
  library(TCGAbiolinks)
  library(SummarizedExperiment)
  library(logger)
  
  # Create directory if needed
  dir.create(data_dir, recursive = TRUE, showWarnings = FALSE)
  
  log_info("Querying GDC for {project_id} RNA-seq data...")
  
  # Query GDC
  query <- GDCquery(
    project = project_id,
    data.category = "Transcriptome Profiling",
    data.type = "Gene Expression Quantification",
    workflow.type = "STAR - Counts"
  )
  
  # Limit samples if specified
  if (!is.null(sample_limit)) {
    query <- query[1:min(sample_limit, nrow(query)), ]
    log_info("Limited to {sample_limit} samples")
  }
  
  # Download data
  log_info("Downloading data to {data_dir}...")
  GDCdownload(query, directory = data_dir)
  
  # Prepare SummarizedExperiment
  log_info("Preparing SummarizedExperiment object...")
  data <- GDCprepare(query, directory = data_dir)
  
  # Save as RDS for quick loading
  output_file <- file.path(data_dir, "rnaseq_se.rds")
  saveRDS(data, output_file)
  log_info("Saved SummarizedExperiment to {output_file}")
  
  return(data)
}

#' Download data from AWS S3 open access bucket
#' @param bucket_name S3 bucket name
#' @param prefix File prefix to filter
#' @param data_dir Local directory for downloads
download_aws_data <- function(
  bucket_name = "gdc-mmrf-commpass-phs000748-2-open",
  prefix = NULL,
  data_dir = "data/raw/aws",
  region = "us-east-1"
) {
  library(aws.s3)
  library(logger)
  
  # Create directory if needed
  dir.create(data_dir, recursive = TRUE, showWarnings = FALSE)
  
  log_info("Listing S3 bucket contents...")
  
  # List bucket contents
  bucket_contents <- get_bucket_df(
    bucket = bucket_name,
    region = region,
    use_https = TRUE,
    prefix = prefix
  )
  
  log_info("Found {nrow(bucket_contents)} files in bucket")
  
  # Download files
  downloaded_files <- list()
  for (i in seq_len(min(10, nrow(bucket_contents)))) {  # Limit for demo
    file_key <- bucket_contents$Key[i]
    local_file <- file.path(data_dir, basename(file_key))
    
    log_info("Downloading {file_key}...")
    
    save_object(
      object = file_key,
      bucket = bucket_name,
      file = local_file,
      region = region
    )
    
    downloaded_files[[i]] <- local_file
  }
  
  log_info("Downloaded {length(downloaded_files)} files to {data_dir}")
  return(downloaded_files)
}

#' Download clinical data from GDC
#' @param project_id Project identifier
#' @param data_dir Directory to save data
download_clinical_data <- function(
  project_id = "MMRF-COMMPASS",
  data_dir = "data/raw/clinical"
) {
  library(TCGAbiolinks)
  library(logger)
  
  # Create directory if needed
  dir.create(data_dir, recursive = TRUE, showWarnings = FALSE)
  
  log_info("Downloading clinical data for {project_id}...")
  
  # Get clinical data
  clinical <- GDCquery_clinic(project = project_id, type = "clinical")
  biospecimen <- GDCquery_clinic(project = project_id, type = "biospecimen")
  
  # Save as CSV and RDS
  output_clinical <- file.path(data_dir, "clinical_data.csv")
  output_biospec <- file.path(data_dir, "biospecimen_data.csv")
  
  write.csv(clinical, output_clinical, row.names = FALSE)
  write.csv(biospecimen, output_biospec, row.names = FALSE)
  
  # Also save as RDS for faster loading
  saveRDS(clinical, file.path(data_dir, "clinical_data.rds"))
  saveRDS(biospecimen, file.path(data_dir, "biospecimen_data.rds"))
  
  log_info("Clinical data saved to {data_dir}")
  
  return(list(
    clinical = clinical,
    biospecimen = biospecimen
  ))
}

#' Load example data for testing
#' @param example_dir Directory containing example data
load_example_data <- function(example_dir = "data/example") {
  library(logger)

  log_info("Loading example data from {example_dir}...")

  # Check if example data exists
  if (!dir.exists(example_dir)) {
    stop("Example data directory not found. Run generate_example_data() first.")
  }

  # Load the combined data object
  example_data_file <- file.path(example_dir, "example_data.rds")
  if (file.exists(example_data_file)) {
    data <- readRDS(example_data_file)
    log_info("Loaded example data with {data$metadata$n_samples} samples and {data$metadata$n_genes} genes")
    return(data)
  }

  # Fallback to loading individual components
  counts <- readRDS(file.path(example_dir, "counts_matrix.rds"))
  clinical <- readRDS(file.path(example_dir, "clinical_data.rds"))
  metadata <- readRDS(file.path(example_dir, "metadata.rds"))

  # Create mock SummarizedExperiment structure
  data <- list(
    assays = list(counts = counts),
    colData = cbind(clinical, metadata[, -1]),
    metadata = list(
      n_samples = ncol(counts),
      n_genes = nrow(counts)
    )
  )

  log_info("Loaded example data components")
  return(data)
}

#' Main data acquisition function
#' @param download_rnaseq Whether to download RNA-seq data
#' @param download_clinical Whether to download clinical data
#' @param download_aws Whether to download from AWS
#' @param sample_limit Limit number of samples (NULL for all)
#' @param use_example Use example data instead of downloading
acquire_commpass_data <- function(
  download_rnaseq = TRUE,
  download_clinical = TRUE,
  download_aws = FALSE,
  sample_limit = 10,  # Default to 10 for testing
  use_example = FALSE  # New parameter for example mode
) {
  library(logger)

  # Use example data if requested
  if (use_example) {
    log_info("Using example data for testing...")
    return(load_example_data())
  }

  log_info("Starting CoMMpass data acquisition...")

  results <- list()

  # Download RNA-seq data
  if (download_rnaseq) {
    results$rnaseq <- download_gdc_rnaseq(sample_limit = sample_limit)
  }

  # Download clinical data
  if (download_clinical) {
    results$clinical <- download_clinical_data()
  }

  # Download from AWS (optional)
  if (download_aws) {
    results$aws_files <- download_aws_data()
  }

  log_info("Data acquisition complete")
  return(results)
}
