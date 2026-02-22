# PCA plot

Creates a PCA scatter plot from pre-computed PCA data.

## Usage

``` r
plot_pca(pca_data, color_by = NULL, shape_by = NULL, title = "PCA")
```

## Arguments

- pca_data:

  List from compute_pca() with coords and var_explained

- color_by:

  Column name in coords to color by (default NULL)

- shape_by:

  Column name in coords to use for shape (default NULL)

- title:

  Plot title

## Value

A ggplot2 object
