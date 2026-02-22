# Save SummarizedExperiment as parquet files

Extracts counts matrix, sample metadata, and gene metadata from a
SummarizedExperiment and saves each as a parquet file.

## Usage

``` r
save_rnaseq_parquet(se, data_dir)
```

## Arguments

- se:

  SummarizedExperiment object

- data_dir:

  Directory to save parquet files

## Value

Invisible list of output file paths
