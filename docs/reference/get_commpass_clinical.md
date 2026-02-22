# Query GDC for CoMMpass Clinical Data

Retrieves clinical data for the MMRF CoMMpass study from the Genomic
Data Commons (GDC). This includes patient demographics, disease
characteristics, treatment information, and outcomes data.

## Usage

``` r
get_commpass_clinical()
```

## Value

A data frame containing clinical data for CoMMpass patients

## Examples

``` r
if (FALSE) { # \dontrun{
# Get clinical data
clinical <- get_commpass_clinical()

# View first few rows
head(clinical)

# Check available columns
names(clinical)
} # }
```
