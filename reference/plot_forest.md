# Plot forest plot of Cox hazard ratios

Creates a forest plot from Cox regression results, showing hazard ratios
with 95

## Usage

``` r
plot_forest(cox_result, title = "Cox Regression Forest Plot")
```

## Arguments

- cox_result:

  List from \[run_cox_regression()\] with \`hazard_ratios\`,
  \`concordance\`, \`n\`, \`n_events\`

- title:

  Plot title

## Value

A ggplot object
