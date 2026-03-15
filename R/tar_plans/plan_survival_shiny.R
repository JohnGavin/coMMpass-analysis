# R/tar_plans/plan_survival_shiny.R
# Pre-compute survival analysis results for Shiny module.
# Input space is bounded: 2 endpoints (OS/PFS) x 4 stratifications x
# 3 output types = 24 combos, plus 6 common Cox models.
# This avoids repeated survfit()/coxph() calls per Shiny session.

plan_survival_shiny <- list(

  # ==============================================================
  # OS Risk Tables (from existing KM targets)
  # ==============================================================

  tar_target(
    shiny_risk_os_overall,
    {
      if (is.null(km_overall$fit)) return(NULL)
      extract_risk_table(km_overall)
    },
    packages = c("survival")
  ),

  tar_target(
    shiny_risk_os_by_risk,
    {
      if (is.null(km_by_risk$fit)) return(NULL)
      extract_risk_table(km_by_risk)
    },
    packages = c("survival")
  ),

  tar_target(
    shiny_risk_os_by_iss,
    {
      if (is.null(km_by_iss$fit)) return(NULL)
      extract_risk_table(km_by_iss)
    },
    packages = c("survival")
  ),

  # KM + risk table by response (if column exists)
  tar_target(
    shiny_km_os_by_response,
    {
      if (!"response" %in% names(survival_data) ||
          sum(!is.na(survival_data$response)) < 5) {
        return(NULL)
      }
      run_kaplan_meier(survival_data, strata = "response")
    },
    packages = c("survival")
  ),

  tar_target(
    shiny_risk_os_by_response,
    {
      if (is.null(shiny_km_os_by_response) ||
          is.null(shiny_km_os_by_response$fit)) {
        return(NULL)
      }
      extract_risk_table(shiny_km_os_by_response)
    },
    packages = c("survival")
  ),

  # ==============================================================
  # PFS KM curves + risk tables (if PFS columns exist)
  # ==============================================================

  # Prepare PFS-specific survival data
  tar_target(
    shiny_pfs_data,
    {
      # PFS columns may come from clinical data merge
      # Check if pfs_time/pfs_status exist in survival_data or
      # we can construct from clinical data
      if (all(c("pfs_time", "pfs_status") %in% names(survival_data))) {
        # Rename for compatibility with run_kaplan_meier
        pfs <- survival_data
        pfs$time_days <- pfs$pfs_time
        pfs$status <- pfs$pfs_status
        pfs <- pfs[!is.na(pfs$time_days) & pfs$time_days > 0, ]
        if (nrow(pfs) >= 5) return(pfs)
      }
      NULL
    }
  ),

  tar_target(
    shiny_km_pfs_overall,
    {
      if (is.null(shiny_pfs_data)) return(NULL)
      run_kaplan_meier(shiny_pfs_data, strata = NULL)
    },
    packages = c("survival")
  ),

  tar_target(
    shiny_risk_pfs_overall,
    {
      if (is.null(shiny_km_pfs_overall) ||
          is.null(shiny_km_pfs_overall$fit)) {
        return(NULL)
      }
      extract_risk_table(shiny_km_pfs_overall)
    },
    packages = c("survival")
  ),

  tar_target(
    shiny_km_pfs_by_risk,
    {
      if (is.null(shiny_pfs_data)) return(NULL)
      if (!"risk_group" %in% names(shiny_pfs_data) ||
          sum(!is.na(shiny_pfs_data$risk_group)) < 5) {
        return(NULL)
      }
      run_kaplan_meier(shiny_pfs_data, strata = "risk_group")
    },
    packages = c("survival")
  ),

  tar_target(
    shiny_risk_pfs_by_risk,
    {
      if (is.null(shiny_km_pfs_by_risk) ||
          is.null(shiny_km_pfs_by_risk$fit)) {
        return(NULL)
      }
      extract_risk_table(shiny_km_pfs_by_risk)
    },
    packages = c("survival")
  ),

  tar_target(
    shiny_km_pfs_by_iss,
    {
      if (is.null(shiny_pfs_data)) return(NULL)
      if (!"iss_stage" %in% names(shiny_pfs_data) ||
          sum(!is.na(shiny_pfs_data$iss_stage)) < 5) {
        return(NULL)
      }
      run_kaplan_meier(shiny_pfs_data, strata = "iss_stage")
    },
    packages = c("survival")
  ),

  tar_target(
    shiny_risk_pfs_by_iss,
    {
      if (is.null(shiny_km_pfs_by_iss) ||
          is.null(shiny_km_pfs_by_iss$fit)) {
        return(NULL)
      }
      extract_risk_table(shiny_km_pfs_by_iss)
    },
    packages = c("survival")
  ),

  # ==============================================================
  # Pre-computed Cox models for Shiny
  # ==============================================================

  tar_target(
    shiny_cox_os_age_stage,
    {
      covs <- intersect(c("age_years", "iss_stage"), names(survival_data))
      if (length(covs) < 2) return(NULL)
      tryCatch(
        run_cox_regression(survival_data, covariates = covs),
        error = function(e) NULL
      )
    },
    packages = c("survival")
  ),

  tar_target(
    shiny_cox_os_age_risk,
    {
      # Use age + ISS/risk_group — drop covariates that are all NA
      covs <- intersect(c("age_years", "iss_stage", "risk_group"), names(survival_data))
      covs <- covs[sapply(covs, function(c) sum(!is.na(survival_data[[c]])) >= 10)]
      if (length(covs) < 2) return(NULL)
      tryCatch(
        run_cox_regression(survival_data, covariates = covs),
        error = function(e) NULL
      )
    },
    packages = c("survival")
  ),

  tar_target(
    shiny_cox_os_full,
    {
      # Use all available covariates — drop those with insufficient non-NA values
      covs <- intersect(
        c("age_years", "gender", "iss_stage", "risk_group"),
        names(survival_data)
      )
      covs <- covs[sapply(covs, function(c) sum(!is.na(survival_data[[c]])) >= 10)]
      if (length(covs) < 2) return(NULL)
      tryCatch(
        run_cox_regression(survival_data, covariates = covs),
        error = function(e) NULL
      )
    },
    packages = c("survival")
  ),

  # ==============================================================
  # Shiny lookup index: maps UI choices to target names
  # ==============================================================

  tar_target(
    shiny_survival_index,
    {
      list(
        km = list(
          os_overall    = "km_overall",
          os_risk_group = "km_by_risk",
          os_iss_stage  = "km_by_iss",
          os_response   = "shiny_km_os_by_response",
          pfs_overall   = "shiny_km_pfs_overall",
          pfs_risk_group = "shiny_km_pfs_by_risk",
          pfs_iss_stage = "shiny_km_pfs_by_iss"
        ),
        risk_table = list(
          os_overall    = "shiny_risk_os_overall",
          os_risk_group = "shiny_risk_os_by_risk",
          os_iss_stage  = "shiny_risk_os_by_iss",
          os_response   = "shiny_risk_os_by_response",
          pfs_overall   = "shiny_risk_pfs_overall",
          pfs_risk_group = "shiny_risk_pfs_by_risk",
          pfs_iss_stage = "shiny_risk_pfs_by_iss"
        ),
        cox = list(
          os_age_stage  = "shiny_cox_os_age_stage",
          os_age_risk   = "shiny_cox_os_age_risk",
          os_full       = "shiny_cox_os_full",
          basic         = "cox_basic",
          full          = "cox_full"
        )
      )
    }
  )
)
