# Bar plot of enrichment results

Creates a horizontal bar plot of the top N enriched pathways, colored by
direction (GSEA) or significance (ORA).

## Usage

``` r
plot_enrichment_barplot(enrich_result, n = 15L, title = "Enrichment Bar Plot")
```

## Arguments

- enrich_result:

  Data frame with pathway enrichment results

- n:

  Number of top pathways to show (default 15)

- title:

  Plot title

## Value

A ggplot2 object
