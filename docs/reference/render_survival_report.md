# Render survival analysis report

Render survival analysis report

## Usage

``` r
render_survival_report(km_results, cox_results, output_dir = "results/reports")
```

## Arguments

- km_results:

  Kaplan-Meier results from run_kaplan_meier

- cox_results:

  Cox regression results from run_cox_regression

- output_dir:

  Directory for output report

## Value

Path to generated report
