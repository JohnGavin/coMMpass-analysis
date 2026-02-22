# Main data acquisition function

Orchestrates the download of CoMMpass data from various sources
including RNA-seq data from GDC, clinical data, and optionally AWS data.

## Usage

``` r
acquire_commpass_data(
  download_rnaseq = TRUE,
  download_clinical = TRUE,
  download_aws = FALSE,
  sample_limit = 200,
  random_sample = TRUE,
  seed = 42,
  use_parquet = TRUE
)
```

## Arguments

- download_rnaseq:

  Whether to download RNA-seq data

- download_clinical:

  Whether to download clinical data

- download_aws:

  Whether to download from AWS

- sample_limit:

  Limit number of samples (NULL for all)

- random_sample:

  If TRUE, randomly sample patients

- seed:

  Random seed for sampling

- use_parquet:

  If TRUE, save parquet files

## Value

List of file paths to the downloaded data

## Examples

``` r
if (FALSE) { # \dontrun{
# Download only clinical data
results <- acquire_commpass_data(
  download_rnaseq = FALSE,
  download_clinical = TRUE,
  download_aws = FALSE
)
} # }
```
