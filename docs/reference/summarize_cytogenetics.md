# Summarize cytogenetic alteration frequencies

Computes frequency and percentage for each marker and risk group.

## Usage

``` r
summarize_cytogenetics(cyto_data)
```

## Arguments

- cyto_data:

  Data frame from extract_cytogenetic_data()

## Value

Data frame with marker, n_positive, n_tested, pct columns

## Examples

``` r
if (FALSE) { # \dontrun{
cyto <- arrow::read_parquet("data/raw/clinical/cytogenetic_data.parquet")
summarize_cytogenetics(cyto)
} # }
```
