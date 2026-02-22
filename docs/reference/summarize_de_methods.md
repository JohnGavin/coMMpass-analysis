# Summarize DE results across methods

Creates a summary table showing the number of significant genes per DE
method.

## Usage

``` r
summarize_de_methods(de_list, padj_threshold = 0.05, lfc_threshold = 1)
```

## Arguments

- de_list:

  Named list of DE result lists (each with results_table)

- padj_threshold:

  Adjusted p-value threshold (default 0.05)

- lfc_threshold:

  Log2 fold-change threshold (default 1)

## Value

Data frame with method, n_tested, n_sig, n_up, n_down
