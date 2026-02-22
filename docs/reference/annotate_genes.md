# Annotate Ensembl gene IDs with symbols and descriptions

Maps Ensembl gene IDs to HGNC symbols and Entrez IDs. Uses msigdbr gene
mapping as the primary source (always available with msigdbr). Falls
back to org.Hs.eg.db + AnnotationDbi if msigdbr is not installed.

## Usage

``` r
annotate_genes(ensembl_ids)
```

## Arguments

- ensembl_ids:

  Character vector of Ensembl gene IDs (versions stripped)

## Value

Data frame with columns: ensembl_gene, gene_symbol, entrez_gene.
Unmappable IDs have NA for symbol/entrez.
