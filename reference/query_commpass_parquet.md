# Query CoMMpass Parquet Files

Opens an in-memory DuckDB connection, creates a VIEW on the specified
parquet file, optionally applies filters, and returns a data frame.

## Usage

``` r
query_commpass_parquet(
  data_type = c("clinical", "biospecimen", "rnaseq_counts", "rnaseq_sample_metadata",
    "rnaseq_gene_metadata"),
  data_dir = "data/raw",
  filters = NULL,
  collect = TRUE
)
```

## Arguments

- data_type:

  One of "clinical", "biospecimen", "rnaseq_counts",
  "rnaseq_sample_metadata", "rnaseq_gene_metadata"

- data_dir:

  Base directory containing parquet files

- filters:

  Optional named list of filters. Names are column names, values are
  vectors of allowed values (used in WHERE ... IN (...))

- collect:

  If TRUE (default), collect results into a data frame. If FALSE, return
  a lazy tbl for further dplyr operations.

## Value

A data frame (if collect=TRUE) or lazy dbplyr tbl

## Examples

``` r
if (FALSE) { # \dontrun{
# Read all clinical data
clinical <- query_commpass_parquet("clinical")

# Filter to specific patients
subset <- query_commpass_parquet(
  "clinical",
  filters = list(gender = "female", vital_status = "Alive")
)

# Get lazy tbl for chaining
tbl <- query_commpass_parquet("clinical", collect = FALSE)
result <- tbl |> dplyr::filter(gender == "female") |> dplyr::collect()
} # }
```
