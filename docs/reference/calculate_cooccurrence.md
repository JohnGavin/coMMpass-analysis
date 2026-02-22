# Calculate pairwise co-occurrence of cytogenetic alterations

Computes Fisher's exact test for each pair of cytogenetic markers to
identify significant co-occurrence or mutual exclusivity patterns.

## Usage

``` r
calculate_cooccurrence(cyto_data, markers = NULL)
```

## Arguments

- cyto_data:

  Data frame from extract_cytogenetic_data()

- markers:

  Character vector of marker columns. Default auto-detects.

## Value

Data frame with columns: marker1, marker2, odds_ratio, pvalue, padj
(BH-corrected), n_both, n_either, tendency
(co-occurrence/exclusive/none)

## Examples

``` r
if (FALSE) { # \dontrun{
cyto <- arrow::read_parquet("data/raw/clinical/cytogenetic_data.parquet")
cooc <- calculate_cooccurrence(cyto)
} # }
```
