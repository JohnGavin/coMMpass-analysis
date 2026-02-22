# Prepare colData for DESeq2

Prepare colData for DESeq2

## Usage

``` r
prepare_coldata(se_data, clinical_data, design_formula)
```

## Arguments

- se_data:

  SummarizedExperiment object

- clinical_data:

  Clinical data frame

- design_formula:

  Design formula

## Value

Data frame suitable for DESeq2 colData
