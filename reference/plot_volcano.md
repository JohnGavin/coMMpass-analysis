# Volcano plot of DE results

Creates a ggplot2 volcano plot with significance thresholds and optional
gene labels.

## Usage

``` r
plot_volcano(
  de_results,
  lfc_threshold = 1,
  padj_threshold = 0.05,
  n_label = 10L,
  title = "Volcano Plot"
)
```

## Arguments

- de_results:

  Data frame with DE results (must have padj and log2FC columns –
  auto-detected from DESeq2/edgeR/limma conventions)

- lfc_threshold:

  Log2 fold-change threshold for significance (default 1)

- padj_threshold:

  Adjusted p-value threshold (default 0.05)

- n_label:

  Number of top genes to label (default 10)

- title:

  Plot title

## Value

A ggplot2 object
