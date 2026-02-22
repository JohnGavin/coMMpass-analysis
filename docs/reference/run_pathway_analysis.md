# Run pathway enrichment analysis

Wrapper that runs ORA on consensus DE genes. Uses MSigDB Hallmark gene
sets by default.

## Usage

``` r
run_pathway_analysis(de_genes, method = "hallmark")
```

## Arguments

- de_genes:

  Consensus DE result from \[find_consensus_genes()\] with
  `consensus_genes` character vector and `by_method` list.

- method:

  Gene set collection: `"hallmark"` (default), `"kegg"`, `"reactome"`,
  `"go_bp"`.

## Value

List with ORA results (see \[run_ora()\]).
