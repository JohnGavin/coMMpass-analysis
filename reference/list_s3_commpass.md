# List AWS S3 CoMMpass Bucket Contents

Lists files available in the public AWS S3 bucket containing MMRF
CoMMpass data. The bucket contains RNA-seq, genomic, and clinical data
files. This function uses anonymous access to the public bucket.

## Usage

``` r
list_s3_commpass(prefix = "")
```

## Arguments

- prefix:

  Optional prefix to filter files (e.g., "RNA-seq/", "clinical/")

## Value

Character vector of S3 object keys (file paths)

## Examples

``` r
if (FALSE) { # \dontrun{
# List all available files (limited to first 100)
files <- list_s3_commpass()

# List only RNA-seq files
rna_files <- list_s3_commpass(prefix = "RNA-seq/")

# Count available files
length(files)
} # }
```
