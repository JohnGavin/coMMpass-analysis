# Run KM analysis for each individual cytogenetic marker

Iterates over cytogenetic markers and runs stratified KM analysis for
each. Markers with fewer than \`min_positive\` positive cases are
skipped.

## Usage

``` r
run_km_by_markers(surv_data, markers = NULL, min_positive = 3L)
```

## Arguments

- surv_data:

  Data frame from \[prepare_survival_data()\]

- markers:

  Character vector of marker column names. Default auto-detects.

- min_positive:

  Minimum number of positive cases to run analysis (default 3)

## Value

Named list of KM results, one per marker
