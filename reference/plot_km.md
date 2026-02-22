# Plot Kaplan-Meier curve

Creates a ggplot2-based KM survival curve from a survfit object.
Supports stratified and unstratified curves with optional log-rank
p-value.

## Usage

``` r
plot_km(
  km_result,
  title = "Kaplan-Meier Survival Curve",
  xlab = "Time (days)",
  time_breaks = NULL
)
```

## Arguments

- km_result:

  List from \[run_kaplan_meier()\] with \`fit\`, \`logrank_p\`,
  \`median_survival\`, \`n_per_group\`, \`strata\`

- title:

  Plot title

- xlab:

  X-axis label

- time_breaks:

  Sequence of time breaks for x-axis (in days). Default marks every 365
  days.

## Value

A ggplot object
