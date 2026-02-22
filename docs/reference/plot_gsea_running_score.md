# GSEA running enrichment score plot

Shows the running enrichment score for a specific gene set from fgsea
results, along with the ranked gene positions.

## Usage

``` r
plot_gsea_running_score(
  gsea_result,
  gene_set_name,
  gene_sets = NULL,
  title = NULL
)
```

## Arguments

- gsea_result:

  List from run_gsea() containing results and ranked_genes

- gene_set_name:

  Name of the gene set to plot

- gene_sets:

  Named list of gene sets (required for tick marks). If NULL, attempts
  to retrieve from msigdbr using the collection.

- title:

  Plot title (default: gene set name)

## Value

A ggplot2 object
