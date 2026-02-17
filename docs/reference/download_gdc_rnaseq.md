# Download RNA-seq data from GDC

Downloads RNA-seq gene expression data from the Genomic Data Commons
(GDC) for the specified project. Data is saved as a SummarizedExperiment
RDS and as parquet files (counts, sample metadata, gene metadata).

## Usage

``` r
download_gdc_rnaseq(
  project_id = "MMRF-COMMPASS",
  data_dir = "data/raw/gdc",
  sample_limit = 200,
  random_sample = TRUE,
  seed = 42,
  use_parquet = TRUE
)
```

## Arguments

- project_id:

  Project identifier (default: "MMRF-COMMPASS")

- data_dir:

  Directory to save data

- sample_limit:

  Maximum number of samples (NULL for all, default 200)

- random_sample:

  If TRUE and sample_limit is set, randomly sample patients using seed
  for reproducibility (default TRUE)

- seed:

  Random seed for reproducible sampling (default 42)

- use_parquet:

  If TRUE, also save parquet files alongside RDS (default TRUE)

## Value

Path to the saved RDS file containing the SummarizedExperiment

## Examples

``` r
if (FALSE) { # \dontrun{
# Download 200 random samples with parquet output
rnaseq_file <- download_gdc_rnaseq(sample_limit = 200)

# Load the SummarizedExperiment
se_data <- readRDS(rnaseq_file)

# Or load parquet directly
counts <- arrow::read_parquet("data/raw/gdc/rnaseq_counts.parquet")
} # }
```
