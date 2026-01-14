#' Query GDC for CoMMpass RNA-seq Metadata
#' @return A GDC query object
#' @export
query_commpass_rna <- function() {
  TCGAbiolinks::GDCquery(
    project = "MMRF-COMMPASS",
    data.category = "Transcriptome Profiling",
    data.type = "Gene Expression Quantification",
    workflow.type = "STAR - Counts"
  )
}

#' Query GDC for CoMMpass Clinical Data
#' @return A data frame of clinical data
#' @export
get_commpass_clinical <- function() {
  TCGAbiolinks::GDCquery_clinic(project = "MMRF-COMMPASS", type = "clinical")
}

#' List AWS S3 CoMMpass Bucket
#' @param prefix Optional prefix to filter
#' @return Character vector of file paths
#' @export
list_s3_commpass <- function(prefix = "") {
  bucket <- "gdc-mmrf-commpass-phs000748-2-open"
  region <- "us-east-1"
  
  res <- aws.s3::get_bucket_df(
    bucket = bucket, 
    region = region, 
    prefix = prefix, 
    max = 100,
    key = "", 
    secret = ""
  )
  
  if (nrow(res) > 0) return(res$Key)
  return(character(0))
}

#' Download a sample of RNA-seq files from S3
#' @param s3_paths Character vector of S3 keys (files)
#' @param dest_dir Destination directory
#' @param n Number of files to download
#' @export
download_s3_subset <- function(s3_paths, dest_dir = "data/raw/rna_seq", n = 3) {
  if (!dir.exists(dest_dir)) dir.create(dest_dir, recursive = TRUE)
  
  # Filter for RNA-seq files using character class to avoid backslashes
  paths <- grep("[.]tsv$", s3_paths, value = TRUE)
  sample_paths <- head(paths, n)
  
  bucket <- "gdc-mmrf-commpass-phs000748-2-open"
  region <- "us-east-1"
  
  downloaded_files <- c()
  for (p in sample_paths) {
    local_file <- file.path(dest_dir, basename(p))
    message(paste("Downloading", p, "..."))
    
    tryCatch({
      aws.s3::save_object(
        object = p,
        bucket = bucket,
        file = local_file,
        region = region,
        key = "",
        secret = ""
      )
      downloaded_files <- c(downloaded_files, local_file)
    }, error = function(e) {
      warning(paste("Failed to download", p, ":", e$message))
    })
  }
  return(downloaded_files)
}