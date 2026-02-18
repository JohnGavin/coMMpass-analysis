# Run DESeq2 differential expression analysis

Run DESeq2 differential expression analysis

## Usage

``` r
run_deseq2(se_data, clinical_data, design_formula = ~condition)
```

## Arguments

- se_data:

  A SummarizedExperiment object

- clinical_data:

  Clinical data frame

- design_formula:

  Design formula for the model

## Value

List with DE results
