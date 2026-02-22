# Download clinical data from GDC

Downloads clinical and biospecimen data from the Genomic Data Commons
(GDC) for the specified project. Data is saved in parquet and RDS
formats.

## Usage

``` r
download_clinical_data(
  project_id = "MMRF-COMMPASS",
  data_dir = "data/raw/clinical",
  use_parquet = TRUE
)
```

## Arguments

- project_id:

  Project identifier (default: "MMRF-COMMPASS")

- data_dir:

  Directory to save data

- use_parquet:

  If TRUE, also save parquet files (default TRUE)

## Value

Path to the directory containing the saved data files

## Examples

``` r
if (FALSE) { # \dontrun{
# Download clinical data
clinical_dir <- download_clinical_data()

# Load from parquet
clinical <- arrow::read_parquet(file.path(clinical_dir, "clinical_data.parquet"))
} # }
```
