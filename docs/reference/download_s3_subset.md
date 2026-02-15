# Download a sample of RNA-seq files from S3

Download a sample of RNA-seq files from S3

## Usage

``` r
download_s3_subset(s3_paths, dest_dir = "data/raw/rna_seq", n = 3)
```

## Arguments

- s3_paths:

  Character vector of S3 keys (files)

- dest_dir:

  Destination directory

- n:

  Number of files to download
