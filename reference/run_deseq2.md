# Run DESeq2 differential expression analysis

Runs DESeq2 with optional apeglm log-fold-change shrinkage and optional
paired longitudinal design for within-patient comparisons.

## Usage

``` r
run_deseq2(
  se_data,
  clinical_data,
  design_formula = ~condition,
  shrink_lfc = TRUE,
  paired = FALSE
)
```

## Arguments

- se_data:

  A SummarizedExperiment object

- clinical_data:

  Clinical data frame

- design_formula:

  Design formula for the model

- shrink_lfc:

  If TRUE, apply apeglm LFC shrinkage (default TRUE)

- paired:

  If TRUE, use paired longitudinal design with patient as blocking
  factor. Requires 'patient_id' and 'visit' columns in clinical_data.
  Only patients with \>=2 timepoints are included.

## Value

List with DE results including raw and shrunken (if requested)
