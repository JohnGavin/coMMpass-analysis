# Find consensus DE genes across methods

Find consensus DE genes across methods

## Usage

``` r
find_consensus_genes(de_results_list, padj_threshold = 0.05, lfc_threshold = 1)
```

## Arguments

- de_results_list:

  List of DE result objects from different methods

- padj_threshold:

  Adjusted p-value threshold (default: 0.05)

- lfc_threshold:

  Log2 fold change threshold (default: 1)

## Value

List with consensus gene information
