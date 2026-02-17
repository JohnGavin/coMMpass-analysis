# Download data from AWS S3 open access bucket

Download data from AWS S3 open access bucket

## Usage

``` r
download_aws_data(
  bucket_name = "gdc-mmrf-commpass-phs000748-2-open",
  prefix = NULL,
  data_dir = "data/raw/aws",
  region = "us-east-1"
)
```

## Arguments

- bucket_name:

  S3 bucket name

- prefix:

  File prefix to filter

- data_dir:

  Local directory for downloads

- region:

  AWS region

## Value

Directory path as character string
