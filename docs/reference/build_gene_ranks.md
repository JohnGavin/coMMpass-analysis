# Build ranked gene vector from DE results

Extracts a named numeric vector of gene ranks suitable for fgsea. Uses
the DESeq2 Wald statistic if available, otherwise computes
`-log10(pvalue) * sign(log2FoldChange)`.

## Usage

``` r
build_gene_ranks(de_table, gene_id_type = "ensembl_gene")
```

## Arguments

- de_table:

  Data frame of DE results with gene identifiers as rownames (or in a
  'gene'/'gene_id' column) and test statistics.

- gene_id_type:

  Gene ID type in the DE results: `"ensembl_gene"`, `"gene_symbol"`, or
  `"entrez_gene"`.

## Value

Named numeric vector (names = gene IDs, values = ranking statistic),
sorted in decreasing order.
