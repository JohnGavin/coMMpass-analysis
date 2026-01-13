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
  # Use system aws cli as it was verified to work in nix shell
  cmd <- sprintf("aws s3 ls --no-sign-request s3://gdc-mmrf-commpass-phs000748-2-open/%s --recursive", prefix)
  system(cmd, intern = TRUE)
}

#' Download a sample of RNA-seq files from S3
#' @param s3_paths Character vector of S3 paths
#' @param dest_dir Destination directory
#' @param n Number of files to download
#' @export
download_s3_subset <- function(s3_paths, dest_dir = "data/raw/rna_seq", n = 5) {
  if (!dir.exists(dest_dir)) dir.create(dest_dir, recursive = TRUE)
  
  # Parse paths from 'ls' output (usually format: date time size path)
  paths <- grep("\\.tsv$", s3_paths, value = TRUE)
  # Extract the actual path part (last element in space-separated string)
  clean_paths <- sapply(strsplit(paths, "\\s+"), function(x) tail(x, 1))
  
  sample_paths <- head(clean_paths, n)
  
  downloaded_files <- c()
  for (p in sample_paths) {
    local_file <- file.path(dest_dir, basename(p))
    cmd <- sprintf("aws s3 cp --no-sign-request s3://gdc-mmrf-commpass-phs000748-2-open/%s %s", p, local_file)
    message(paste("Downloading", p, "..."))
    system(cmd)
    downloaded_files <- c(downloaded_files, local_file)
  }
  return(downloaded_files)
}

