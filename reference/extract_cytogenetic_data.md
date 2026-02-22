# Extract cytogenetic markers from clinical data

Parses clinical data from GDC to extract translocation and copy number
alteration status. GDC clinical data includes FISH results for standard
myeloma cytogenetic markers.

## Usage

``` r
extract_cytogenetic_data(clinical_dir)
```

## Arguments

- clinical_dir:

  Path to clinical data directory (from download_clinical_data)

## Value

Path to saved cytogenetic parquet file

## Examples

``` r
if (FALSE) { # \dontrun{
cyto_file <- extract_cytogenetic_data("data/raw/clinical")
cyto <- arrow::read_parquet(cyto_file)
} # }
```
