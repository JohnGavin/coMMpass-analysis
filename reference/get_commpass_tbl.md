# Get Lazy DuckDB Table for CoMMpass Data

Returns a lazy \`dplyr::tbl()\` backed by DuckDB, reading from parquet
files. The connection is managed by the caller and must be disconnected
when done.

## Usage

``` r
get_commpass_tbl(
  data_type = c("clinical", "biospecimen", "rnaseq_counts", "rnaseq_sample_metadata",
    "rnaseq_gene_metadata"),
  data_dir = "data/raw",
  con = NULL
)
```

## Arguments

- data_type:

  One of "clinical", "biospecimen", "rnaseq_counts",
  "rnaseq_sample_metadata", "rnaseq_gene_metadata"

- data_dir:

  Base directory containing parquet files

- con:

  An existing DuckDB connection. If NULL, a new in-memory connection is
  created and returned as an attribute of the result.

## Value

A lazy dbplyr tbl. If con was NULL, the DuckDB connection is stored as
attr(result, "connection") - caller must disconnect it.

## Examples

``` r
if (FALSE) { # \dontrun{
# Create connection and query
con <- DBI::dbConnect(duckdb::duckdb())
clinical_tbl <- get_commpass_tbl("clinical", con = con)

# Chain dplyr operations (lazy - not executed until collect)
result <- clinical_tbl |>
  dplyr::filter(gender == "female") |>
  dplyr::select(submitter_id, age_at_diagnosis, vital_status) |>
  dplyr::collect()

# Clean up
DBI::dbDisconnect(con, shutdown = TRUE)
} # }
```
