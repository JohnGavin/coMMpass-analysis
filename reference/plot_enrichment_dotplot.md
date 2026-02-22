# Dot plot of enrichment results

Creates a dot plot of the top N enriched pathways. Dot size represents
gene set size, color represents significance (adjusted p-value or NES).

## Usage

``` r
plot_enrichment_dotplot(
  enrich_result,
  n = 15L,
  color_by = "padj",
  title = "Enrichment Dot Plot"
)
```

## Arguments

- enrich_result:

  Data frame with pathway enrichment results. Must contain columns:
  pathway, padj, and one of: NES (GSEA), overlap (ORA).

- n:

  Number of top pathways to show (default 15)

- color_by:

  Which metric to color by: "padj" (default) or "NES"

- title:

  Plot title

## Value

A ggplot2 object
