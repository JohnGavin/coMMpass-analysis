# Heatmap of top DE genes

Creates a heatmap of the top differentially expressed genes using
z-score scaled expression values.

## Usage

``` r
plot_heatmap_de(
  expr_matrix,
  de_results,
  n_genes = 50L,
  annotation_df = NULL,
  title = "Top DE Genes"
)
```

## Arguments

- expr_matrix:

  Numeric matrix of transformed expression (genes x samples)

- de_results:

  Data frame with DE results (rownames = gene IDs)

- n_genes:

  Number of top DE genes to show (default 50)

- annotation_df:

  Optional data frame of sample annotations for column annotation

- title:

  Plot title

## Value

A ggplot2 object (tile-based heatmap)
