# Normalize RNA-seq data

Normalize RNA-seq data

## Usage

``` r
normalize_rnaseq(se_data, method = "TMM")
```

## Arguments

- se_data:

  A SummarizedExperiment object with a "counts" assay

- method:

  Normalization method (default: "TMM")

## Value

SummarizedExperiment with added "logCPM" assay
