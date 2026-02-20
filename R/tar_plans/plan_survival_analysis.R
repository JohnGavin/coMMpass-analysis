# R/tar_plans/plan_survival_analysis.R
# Survival analysis targets using real clinical + cytogenetic data

plan_survival_analysis <- list(

  # Prepare survival data from cleaned clinical + cytogenetic data
  tar_target(
    survival_data,
    {
      # clinical_data_clean is a data frame; cytogenetic_data is a file path
      cyto_path <- NULL
      if (is.character(cytogenetic_data) && file.exists(cytogenetic_data)) {
        cyto_path <- cytogenetic_data
      }
      prepare_survival_data(clinical_data_clean, cyto_file = cyto_path)
    },
    packages = c("survival")
  ),

  # Overall Kaplan-Meier (no stratification)
  tar_target(
    km_overall,
    run_kaplan_meier(survival_data, strata = NULL),
    packages = c("survival")
  ),

  # KM by cytogenetic risk group (high vs standard)
  tar_target(
    km_by_risk,
    {
      if ("risk_group" %in% names(survival_data) &&
          sum(!is.na(survival_data$risk_group)) >= 5) {
        run_kaplan_meier(survival_data, strata = "risk_group")
      } else {
        list(fit = NULL, logrank_p = NA_real_,
             note = "Cytogenetic risk data not available or too few patients")
      }
    },
    packages = c("survival")
  ),

  # KM by ISS stage
  tar_target(
    km_by_iss,
    {
      if ("iss_stage" %in% names(survival_data) &&
          sum(!is.na(survival_data$iss_stage)) >= 5) {
        run_kaplan_meier(survival_data, strata = "iss_stage")
      } else {
        list(fit = NULL, logrank_p = NA_real_,
             note = "ISS stage data not available or too few patients")
      }
    },
    packages = c("survival")
  ),

  # Cox regression: age + gender
  tar_target(
    cox_basic,
    run_cox_regression(
      survival_data,
      covariates = c("age_years", "gender")
    ),
    packages = c("survival")
  ),

  # Cox regression: age + gender + ISS + cytogenetic risk
  tar_target(
    cox_full,
    {
      covs <- c("age_years", "gender")
      if ("iss_stage" %in% names(survival_data) &&
          sum(!is.na(survival_data$iss_stage)) >= 10) {
        covs <- c(covs, "iss_stage")
      }
      if ("risk_group" %in% names(survival_data) &&
          sum(!is.na(survival_data$risk_group)) >= 10) {
        covs <- c(covs, "risk_group")
      }
      run_cox_regression(survival_data, covariates = covs)
    },
    packages = c("survival")
  )
)
