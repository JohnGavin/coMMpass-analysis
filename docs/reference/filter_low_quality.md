# Filter low-quality samples and genes

Filter low-quality samples and genes

## Usage

``` r
filter_low_quality(se_data, min_counts = 10, min_samples = 3)
```

## Arguments

- se_data:

  A SummarizedExperiment object

- min_counts:

  Minimum count threshold per gene

- min_samples:

  Minimum samples with counts above threshold

## Value

Filtered SummarizedExperiment
