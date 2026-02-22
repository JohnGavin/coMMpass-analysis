# Run paired longitudinal DESeq2 analysis

Within-patient comparison controlling for inter-patient variability.
Uses design \`~ patient_id + visit\` where patient_id is a blocking
factor and visit captures the treatment/relapse effect. Only patients
with \>=2 timepoints are included.

## Usage

``` r
run_deseq2_paired(se_data, clinical_data, shrink_lfc = TRUE)
```

## Arguments

- se_data:

  A SummarizedExperiment object

- clinical_data:

  Clinical data frame with patient_id and visit columns

- shrink_lfc:

  If TRUE, apply apeglm LFC shrinkage (default TRUE)

## Value

List with paired DE results
