# Run Gene Set Enrichment Analysis (GSEA)

Performs pre-ranked GSEA using fgsea on differential expression results.
Genes are ranked by their test statistic (DESeq2 Wald stat or
`-log10(pvalue) * sign(log2FC)`). Gene sets come from MSigDB via
msigdbr.

## Usage

``` r
run_gsea(
  de_results,
  gene_sets = "hallmark",
  gene_id_type = "ensembl_gene",
  min_size = 15L,
  max_size = 500L
)
```

## Arguments

- de_results:

  Data frame of DE results. Must contain gene identifiers (as rownames
  or in a `gene`/`gene_id` column) and at least one of: `stat` (DESeq2
  Wald statistic), or `log2FoldChange`/`logFC` + `pvalue`/`PValue`.

- gene_sets:

  Character string specifying the MSigDB collection: `"hallmark"`
  (default), `"kegg"`, `"reactome"`, `"go_bp"`, `"go_mf"`, `"go_cc"`,
  `"c2"`, `"c7"`. Alternatively, a named list of character vectors
  (custom gene sets).

- gene_id_type:

  Type of gene identifiers: `"ensembl_gene"` (default), `"gene_symbol"`,
  or `"entrez_gene"`.

- min_size:

  Minimum gene set size (default: 15).

- max_size:

  Maximum gene set size (default: 500).

## Value

List with components:

- results:

  Data frame with pathway, NES, pval, padj, size, leadingEdge columns.

- n_gene_sets:

  Number of gene sets tested.

- n_significant:

  Number significant at padj \< 0.05.

- top_gene_sets:

  Top 20 enriched gene sets as a data frame.

- ranked_genes:

  Named numeric vector of gene ranks used.

- collection:

  Gene set collection used.
