# Prepare survival data from clinical and cytogenetic data

Constructs a data frame suitable for survival analysis from GDC clinical
data. Uses \`days_to_death\` for deceased patients and
\`days_to_last_follow_up\` for censored (alive) patients. Merges with
cytogenetic risk groups when available.

## Usage

``` r
prepare_survival_data(clinical_data, cyto_file = NULL)
```

## Arguments

- clinical_data:

  Cleaned clinical data frame (from clean_clinical_data)

- cyto_file:

  Path to cytogenetic parquet file (from extract_cytogenetic_data), or
  NULL to skip cytogenetic integration

## Value

Data frame with columns: patient_id, time_days, status (0=censored,
1=dead), age_years, gender, iss_stage, risk_group, plus individual
cytogenetic markers
