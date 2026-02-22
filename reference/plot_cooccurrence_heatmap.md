# Plot co-occurrence heatmap of cytogenetic alterations

Displays pairwise co-occurrence patterns as a heatmap. Color indicates
-log10(p-value) direction: red for co-occurrence, blue for mutual
exclusivity.

## Usage

``` r
plot_cooccurrence_heatmap(cooccurrence, title = "Cytogenetic Co-occurrence")
```

## Arguments

- cooccurrence:

  Data frame from calculate_cooccurrence()

- title:

  Plot title

## Value

A ggplot object

## Examples

``` r
if (FALSE) { # \dontrun{
cooc <- calculate_cooccurrence(cyto)
plot_cooccurrence_heatmap(cooc)
} # }
```
