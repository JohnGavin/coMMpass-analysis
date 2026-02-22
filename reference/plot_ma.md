# MA plot of DE results

Plots mean expression (x-axis) vs log2 fold change (y-axis), a standard
diagnostic for RNA-seq DE analysis.

## Usage

``` r
plot_ma(
  de_results,
  lfc_threshold = 1,
  padj_threshold = 0.05,
  title = "MA Plot"
)
```

## Arguments

- de_results:

  Data frame with DE results

- lfc_threshold:

  Log2 fold-change threshold for coloring (default 1)

- padj_threshold:

  Adjusted p-value threshold (default 0.05)

- title:

  Plot title

## Value

A ggplot2 object
