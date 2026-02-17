# Format File Size in Human-Readable Format

Converts file sizes from bytes to human-readable format with appropriate
units

## Usage

``` r
format_file_size(size_bytes, digits = 1)
```

## Arguments

- size_bytes:

  Numeric vector of file sizes in bytes

- digits:

  Number of decimal places to show (default: 1)

## Value

Character vector with formatted file sizes

## Examples

``` r
format_file_size(c(1024, 1048576, 5000877192))
#> [1] "1.0 KB" "1.0 MB" "4.7 GB"
# Returns: "1.0 KB", "1.0 MB", "4.7 GB"
```
