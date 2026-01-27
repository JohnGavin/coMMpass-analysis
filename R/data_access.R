#' Query GDC for CoMMpass RNA-seq Metadata
#'
#' Queries the Genomic Data Commons (GDC) API for Multiple Myeloma Research
#' Foundation (MMRF) CoMMpass study RNA-seq data. This function returns a
#' query object that can be used with other TCGAbiolinks functions to download
#' and prepare the data.
#'
#' @return A GDCquery object containing metadata for RNA-seq samples
#' @export
#' @examples
#' \dontrun{
#' # Query for RNA-seq data
#' query <- query_commpass_rna()
#'
#' # Use the query to download data
#' # GDCdownload(query)
#' # data <- GDCprepare(query)
#' }
query_commpass_rna <- function() {
  TCGAbiolinks::GDCquery(
    project = "MMRF-COMMPASS",
    data.category = "Transcriptome Profiling",
    data.type = "Gene Expression Quantification",
    workflow.type = "STAR - Counts"
  )
}

#' Query GDC for CoMMpass Clinical Data
#'
#' Retrieves clinical data for the MMRF CoMMpass study from the Genomic Data
#' Commons (GDC). This includes patient demographics, disease characteristics,
#' treatment information, and outcomes data.
#'
#' @return A data frame containing clinical data for CoMMpass patients
#' @export
#' @examples
#' \dontrun{
#' # Get clinical data
#' clinical <- get_commpass_clinical()
#'
#' # View first few rows
#' head(clinical)
#'
#' # Check available columns
#' names(clinical)
#' }
get_commpass_clinical <- function() {
  TCGAbiolinks::GDCquery_clinic(project = "MMRF-COMMPASS", type = "clinical")
}

#' List AWS S3 CoMMpass Bucket Contents
#'
#' Lists files available in the public AWS S3 bucket containing MMRF CoMMpass
#' data. The bucket contains RNA-seq, genomic, and clinical data files. This
#' function uses anonymous access to the public bucket.
#'
#' @param prefix Optional prefix to filter files (e.g., "RNA-seq/", "clinical/")
#' @return Character vector of S3 object keys (file paths)
#' @export
#' @examples
#' \dontrun{
#' # List all available files (limited to first 100)
#' files <- list_s3_commpass()
#'
#' # List only RNA-seq files
#' rna_files <- list_s3_commpass(prefix = "RNA-seq/")
#'
#' # Count available files
#' length(files)
#' }
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

#' Download a Sample of RNA-seq Files from S3
#'
#' Downloads a subset of RNA-seq files from the public MMRF CoMMpass S3 bucket.
#' This function is useful for testing and development with a small sample of
#' data before downloading the full dataset. Files are downloaded using
#' anonymous access to the public bucket.
#'
#' @param s3_paths Character vector of S3 object keys (file paths) to download from
#' @param dest_dir Destination directory for downloaded files (default: "data/raw/rna_seq")
#' @param n Number of files to download (default: 3)
#' @return Character vector of successfully downloaded file paths
#' @export
#' @examples
#' \dontrun{
#' # List available files
#' s3_files <- list_s3_commpass()
#'
#' # Download first 3 RNA-seq files
#' downloaded <- download_s3_subset(s3_files, n = 3)
#'
#' # Check what was downloaded
#' basename(downloaded)
#' }
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