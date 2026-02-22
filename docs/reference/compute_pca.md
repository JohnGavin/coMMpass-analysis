# Compute PCA from transformed expression data

Compute PCA from transformed expression data

## Usage

``` r
compute_pca(expr_matrix, n_top = 500L, metadata = NULL)
```

## Arguments

- expr_matrix:

  Numeric matrix (genes x samples) of transformed expression values
  (e.g., VST or logCPM)

- n_top:

  Number of most variable genes to use (default 500)

- metadata:

  Optional data frame of sample annotations to merge with PCA
  coordinates

## Value

List with components: coords (data frame with PC1, PC2, ...),
var_explained (numeric vector of variance proportions), n_genes_used
