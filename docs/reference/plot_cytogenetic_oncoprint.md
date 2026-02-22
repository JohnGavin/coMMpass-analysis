# Plot cytogenetic oncoprint

Creates an oncoprint-style heatmap showing cytogenetic alterations
across patients. Rows are alterations, columns are patients. Uses
ggplot2 for portability (no ComplexHeatmap dependency).

## Usage

``` r
plot_cytogenetic_oncoprint(
  cyto_data,
  markers = NULL,
  sort_by = c("frequency", "risk"),
  title = "Cytogenetic Landscape"
)
```

## Arguments

- cyto_data:

  Data frame from extract_cytogenetic_data() with columns: patient_id,
  iss_stage, t_4_14, t_11_14, t_14_16, del_17p, gain_1q, etc.

- markers:

  Character vector of marker columns to include. Default uses all
  available markers.

- sort_by:

  How to sort patients. One of "frequency" (default) or "risk".

- title:

  Plot title.

## Value

A ggplot object

## Examples

``` r
if (FALSE) { # \dontrun{
cyto <- arrow::read_parquet("data/raw/clinical/cytogenetic_data.parquet")
plot_cytogenetic_oncoprint(cyto)
} # }
```
