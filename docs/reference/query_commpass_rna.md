# Query GDC for CoMMpass RNA-seq Metadata

Queries the Genomic Data Commons (GDC) API for Multiple Myeloma Research
Foundation (MMRF) CoMMpass study RNA-seq data. This function returns a
query object that can be used with other TCGAbiolinks functions to
download and prepare the data.

## Usage

``` r
query_commpass_rna()
```

## Value

A GDCquery object containing metadata for RNA-seq samples

## Examples

``` r
if (FALSE) { # \dontrun{
# Query for RNA-seq data
query <- query_commpass_rna()

# Use the query to download data
# GDCdownload(query)
# data <- GDCprepare(query)
} # }
```
