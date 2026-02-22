# Run Over-Representation Analysis (ORA)

Tests whether a set of significant genes is over-represented in gene set
collections using Fisher's exact test (hypergeometric distribution).
Gene sets come from MSigDB via msigdbr.

## Usage

``` r
run_ora(
  sig_genes,
  universe,
  gene_sets = "hallmark",
  gene_id_type = "ensembl_gene",
  min_size = 10L,
  max_size = 500L
)
```

## Arguments

- sig_genes:

  Character vector of significant gene identifiers.

- universe:

  Character vector of all tested gene identifiers (background).

- gene_sets:

  Character string specifying the MSigDB collection (same options as
  \[run_gsea()\]), or a named list of character vectors.

- gene_id_type:

  Type of gene identifiers: `"ensembl_gene"` (default), `"gene_symbol"`,
  or `"entrez_gene"`.

- min_size:

  Minimum gene set size (default: 10).

- max_size:

  Maximum gene set size (default: 500).

## Value

List with components:

- results:

  Data frame with pathway, overlap, gene_set_size, universe_size,
  p_value, padj, odds_ratio, overlapping_genes.

- n_pathways_tested:

  Number of pathways tested.

- n_pathways_enriched:

  Number significant at padj \< 0.05.

- n_sig_genes:

  Number of input significant genes.

- top_pathways:

  Top 20 enriched pathways as a data frame.
