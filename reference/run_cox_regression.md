# Run Cox proportional hazards regression

Fits a Cox PH model with specified covariates. Returns the model object,
hazard ratios with confidence intervals, and concordance index.

## Usage

``` r
run_cox_regression(surv_data, covariates = c("age_years", "gender"))
```

## Arguments

- surv_data:

  Data frame from \[prepare_survival_data()\]

- covariates:

  Character vector of covariate column names

## Value

List with components: - \`model\`: coxph object - \`hazard_ratios\`:
data frame with HR, CI, p-values - \`concordance\`: C-index - \`n\`:
number of patients in model - \`n_events\`: number of events -
\`ph_test\`: cox.zph result for PH assumption
