# Get gene set collections from MSigDB

Retrieves gene sets from the Molecular Signatures Database (MSigDB) via
the msigdbr package. Returns a named list suitable for fgsea.

## Usage

``` r
get_msigdb_gene_sets(
  collection = "hallmark",
  gene_id_type = "ensembl_gene",
  organism = "Homo sapiens"
)
```

## Arguments

- collection:

  Character string specifying the collection: `"hallmark"`, `"kegg"`,
  `"reactome"`, `"go_bp"`, `"go_mf"`, `"go_cc"`, `"c2"` (all curated),
  or `"c7"` (immunologic).

- gene_id_type:

  Gene ID column to use: `"ensembl_gene"`, `"gene_symbol"`, or
  `"entrez_gene"`.

- organism:

  Species name (default: `"Homo sapiens"`).

## Value

Named list of character vectors (pathway name -\> gene IDs).
