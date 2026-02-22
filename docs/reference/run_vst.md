# Run variance stabilizing transformation

Wrapper around DESeq2::vst() for use in visualization. VST is
appropriate for PCA, heatmaps, and clustering – not for DE testing
(which uses raw counts).

## Usage

``` r
run_vst(se_data, blind = TRUE)
```

## Arguments

- se_data:

  SummarizedExperiment with "counts" assay

- blind:

  Logical, whether VST should be blind to the design (default TRUE for
  exploratory analysis)

## Value

SummarizedExperiment with "vst" assay added, or NULL if DESeq2 is not
available
