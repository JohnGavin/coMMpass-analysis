# Generate summary report

Generate summary report

## Usage

``` r
generate_summary_report(
  qc_metrics,
  de_genes,
  survival,
  pathways,
  output_dir = "results/reports"
)
```

## Arguments

- qc_metrics:

  QC metrics data frame

- de_genes:

  DE results with consensus gene information

- survival:

  Survival analysis results

- pathways:

  Pathway analysis results

- output_dir:

  Directory for output report

## Value

Path to generated report
