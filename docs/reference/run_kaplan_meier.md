# Run Kaplan-Meier analysis

Fits a Kaplan-Meier survival curve, optionally stratified by a grouping
variable. Returns the survfit object, log-rank test, and summary
statistics.

## Usage

``` r
run_kaplan_meier(surv_data, strata = NULL)
```

## Arguments

- surv_data:

  Data frame from \[prepare_survival_data()\] with columns \`time_days\`
  and \`status\`

- strata:

  Column name to stratify by (e.g. "risk_group", "iss_stage", "gender"),
  or NULL for overall curve

## Value

List with components: - \`fit\`: survfit object - \`logrank\`: survdiff
result (NULL if no strata) - \`logrank_p\`: log-rank p-value (NA if no
strata) - \`median_survival\`: named vector of median survival times -
\`n_per_group\`: sample sizes per stratum - \`strata\`: the
stratification variable used
