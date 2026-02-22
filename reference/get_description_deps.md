# Extract Package Dependencies from DESCRIPTION

Parses Imports and Suggests fields from a DESCRIPTION file, removing
version constraints and base R packages.

## Usage

``` r
get_description_deps(desc_path = "DESCRIPTION")
```

## Arguments

- desc_path:

  Path to DESCRIPTION file.

## Value

Character vector of package names (no base packages).
