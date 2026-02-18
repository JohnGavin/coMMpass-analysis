# Run Cox proportional hazards regression

Run Cox proportional hazards regression

## Usage

``` r
run_cox_regression(surv_data, covariates = c("age", "stage"))
```

## Arguments

- surv_data:

  Survival data frame with time and status columns

- covariates:

  Character vector of covariate column names

## Value

List with Cox regression results
