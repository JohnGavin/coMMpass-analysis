# Add gene symbol column to DE results table

Add gene symbol column to DE results table

## Usage

``` r
annotate_de_results(de_results, annotation)
```

## Arguments

- de_results:

  Data frame with Ensembl IDs as rownames

- annotation:

  Data frame from annotate_genes()

## Value

DE results with gene_symbol column prepended
