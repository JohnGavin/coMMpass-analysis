# Download a Sample of RNA-seq Files from S3

Downloads a subset of RNA-seq files from the public MMRF CoMMpass S3
bucket. This function is useful for testing and development with a small
sample of data before downloading the full dataset. Files are downloaded
using anonymous access to the public bucket.

## Usage

``` r
download_s3_subset(s3_paths, dest_dir = "data/raw/rna_seq", n = 3)
```

## Arguments

- s3_paths:

  Character vector of S3 object keys (file paths) to download from

- dest_dir:

  Destination directory for downloaded files (default:
  "data/raw/rna_seq")

- n:

  Number of files to download (default: 3)

## Value

Character vector of successfully downloaded file paths

## Examples

``` r
if (FALSE) { # \dontrun{
# List available files
s3_files <- list_s3_commpass()

# Download first 3 RNA-seq files
downloaded <- download_s3_subset(s3_files, n = 3)

# Check what was downloaded
basename(downloaded)
} # }
```
