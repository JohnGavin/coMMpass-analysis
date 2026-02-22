# Build paired sample metadata

Identifies patients with \>=2 timepoints and creates a colData frame
suitable for DESeq2's paired design (~ patient_id + visit).

## Usage

``` r
build_paired_coldata(sample_ids, clinical_data)
```

## Arguments

- sample_ids:

  Character vector of sample IDs from expression data

- clinical_data:

  Clinical data frame

## Value

Data frame with patient_id and visit columns, rownames = sample_ids
